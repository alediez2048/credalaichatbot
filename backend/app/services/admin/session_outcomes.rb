# frozen_string_literal: true

module Admin
  # Filterable session list for completion outcomes table (P7-006).
  class SessionOutcomes
    ABANDONED_AFTER = 24.hours

    # @param status [String] "all", "active", "completed", "abandoned"
    # @param channel [String] "all", "web_only", "multichannel", "sms_opted"
    # @param date_from [Date, nil]
    # @param date_to [Date, nil]
    def self.call(status: "all", channel: "all", date_from: nil, date_to: nil)
      scope = OnboardingSession.includes(:user, :messages, :llm_usages).order(updated_at: :desc)
      if date_from.present?
        scope = scope.where("created_at >= ?", Time.zone.local(date_from.year, date_from.month, date_from.day).beginning_of_day)
      end
      if date_to.present?
        scope = scope.where("created_at <= ?", Time.zone.local(date_to.year, date_to.month, date_to.day).end_of_day)
      end

      rows = scope.map { |s| build_row(s) }
      rows = filter_by_status(rows, status)
      rows = filter_by_channel(rows, channel)
      rows
    end

    def self.build_row(session)
      msgs = session.messages.sort_by(&:created_at)
      first_m = msgs.first
      last_m = msgs.last
      duration_min = if first_m && last_m && first_m != last_m
        ((last_m.created_at - first_m.created_at) / 60.0).round(1)
      else
        0.0
      end

      chans = msgs.map { |m| m.metadata["channel"].presence || "web" }.uniq.sort.join(", ")
      cost = session.llm_usages.sum(:cost_usd).to_f.round(4)

      {
        id: session.id,
        user_email: session.user&.email,
        current_step: session.current_step,
        progress_percent: session.progress_percent,
        channels_label: chans.presence || "—",
        message_count: msgs.size,
        duration_minutes: duration_min,
        cost: cost,
        outcome: outcome_for(session),
        created_at: session.created_at,
        last_activity: session.last_interaction_at || session.updated_at
      }
    end

    def self.outcome_for(session)
      return "completed" if session.current_step == "complete"

      ref = session.last_interaction_at || session.updated_at
      if ref < ABANDONED_AFTER.ago
        "abandoned"
      else
        "active"
      end
    end

    def self.filter_by_status(rows, status)
      return rows if status.blank? || status == "all"

      rows.select { |r| r[:outcome] == status }
    end

    def self.filter_by_channel(rows, channel)
      return rows if channel.blank? || channel == "all"

      session_ids = rows.map { |r| r[:id] }
      sessions = OnboardingSession.includes(:messages).where(id: session_ids).index_by(&:id)

      rows.select do |r|
        s = sessions[r[:id]]
        next false unless s

        case channel
        when "web_only"
          ChannelAnalytics.web_only?(s)
        when "multichannel"
          ChannelAnalytics.multichannel?(s)
        when "sms_opted"
          s.sms_opt_in?
        else
          true
        end
      end
    end
  end
end
