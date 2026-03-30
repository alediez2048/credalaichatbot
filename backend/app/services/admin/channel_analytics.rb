# frozen_string_literal: true

module Admin
  # Channel usage breakdown for admin dashboard (P7-006).
  class ChannelAnalytics
    def self.call
      sessions = OnboardingSession.includes(:messages).to_a
      {
        web_only_count: sessions.count { |s| web_only?(s) },
        sms_opted_in_count: sessions.count(&:sms_opt_in?),
        multichannel_count: sessions.count { |s| multichannel?(s) },
        completion_rate_web_only: completion_rate(sessions.select { |s| web_only?(s) }),
        completion_rate_multichannel: completion_rate(sessions.select { |s| multichannel?(s) }),
        channel_switches_by_day: channel_switches_by_day,
        sms_summary: sms_summary
      }
    end

    def self.web_only?(session)
      chans = distinct_message_channels(session)
      chans.size <= 1 && (chans.empty? || chans == ["web"])
    end

    def self.multichannel?(session)
      distinct_message_channels(session).size > 1
    end

    def self.distinct_message_channels(session)
      session.messages.map { |m| m.metadata["channel"].presence || "web" }.uniq
    end

    def self.completion_rate(subset)
      return 0.0 if subset.empty?

      done = subset.count { |s| s.current_step == "complete" }
      (done * 100.0 / subset.size).round(1)
    end

    def self.channel_switches_by_day
      Message
        .where(role: "user")
        .where("metadata ? 'last_channel_before'")
        .where("COALESCE(metadata->>'last_channel_before', '') != COALESCE(metadata->>'channel', 'web')")
        .order(:created_at)
        .limit(500)
        .group_by { |m| m.created_at.to_date }
        .transform_values(&:size)
        .sort_by { |d, _| d }
        .to_h
    end

    def self.sms_summary
      inbound = SmsEvent.where(direction: "inbound").count
      outbound = SmsEvent.where(direction: "outbound").count
      failed = SmsEvent.where(direction: "outbound", status: "failed").count
      ok = outbound - failed
      success_rate = outbound.positive? ? (ok * 100.0 / outbound).round(1) : 0.0
      {
        inbound: inbound,
        outbound: outbound,
        failed: failed,
        delivery_success_rate: success_rate
      }
    end
  end
end
