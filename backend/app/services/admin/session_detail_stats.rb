# frozen_string_literal: true

module Admin
  # Aggregates session + message timeline for admin drill-down (P7-006).
  class SessionDetailStats
    TRUNCATE = 200

    def self.call(session_id)
      session = OnboardingSession.includes(:user, :messages, :sms_events, :llm_usages).find_by(id: session_id)
      return nil unless session

      new(session).to_h
    end

    def initialize(session)
      @session = session
    end

    def to_h
      {
        session: @session,
        title: title_label,
        sidebar: build_sidebar,
        timeline: build_timeline
      }
    end

    private

    def title_label
      email = @session.user&.email
      "Session ##{@session.id} — #{email || 'anonymous'}"
    end

    def build_sidebar
      msgs = @session.messages.order(:created_at).to_a
      first_m = msgs.first
      last_m = msgs.last
      duration_mins = if first_m && last_m && first_m != last_m
        ((last_m.created_at - first_m.created_at) / 60.0).round(1)
      else
        0.0
      end

      chans = msgs.each_with_object(Hash.new(0)) do |m, h|
        ch = m.metadata["channel"].presence || "web"
        h[ch] += 1
      end

      {
        step: @session.current_step,
        progress_percent: @session.progress_percent,
        status: @session.status,
        duration_minutes: duration_mins,
        message_count: msgs.size,
        user_messages: msgs.count { |m| m.role == "user" },
        assistant_messages: msgs.count { |m| m.role == "assistant" },
        cost: @session.llm_usages.sum(:cost_usd).to_f.round(4),
        phone: @session.phone_number,
        sms_opt_in: @session.sms_opt_in,
        last_channel: @session.last_channel,
        last_interaction_at: @session.last_interaction_at,
        user_email: @session.user&.email,
        channel_tally: chans,
        channel_switch_count: count_channel_switches(msgs),
        sms_inbound: @session.sms_events.where(direction: "inbound").count,
        sms_outbound: @session.sms_events.where(direction: "outbound").count,
        sms_failed: @session.sms_events.where(direction: "outbound", status: "failed").count,
        channel_type: @session.channel_type,
        channel_user_id: @session.channel_user_id
      }
    end

    def count_channel_switches(msgs)
      prev = nil
      n = 0
      msgs.each do |m|
        ch = m.metadata["channel"].presence || "web"
        n += 1 if prev && prev != ch
        prev = ch
      end
      n
    end

    def build_timeline
      items = []
      prev_channel = nil
      @session.messages.order(:created_at).each do |m|
        ch = m.metadata["channel"].presence || "web"
        if prev_channel && prev_channel != ch
          items << { kind: :channel_switch, from: prev_channel, to: ch, at: m.created_at }
        end
        if m.role == "assistant" && ActiveModel::Type::Boolean.new.cast(m.metadata["step_changed"])
          items << { kind: :step, step: m.metadata["step_after"], at: m.created_at }
        end
        items << {
          kind: :message,
          id: m.id,
          role: m.role,
          content: m.content.to_s.truncate(TRUNCATE),
          channel: ch,
          at: m.created_at,
          error: m.metadata["error"],
          category: m.metadata["category"]
        }
        prev_channel = ch
      end
      items
    end
  end
end
