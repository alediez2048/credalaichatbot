# frozen_string_literal: true

module Onboarding
  # Formats assistant output per channel (length, resume context when switching channels).
  class ChannelFormatter
    SMS_MAX_CHARS = 1600

    class << self
      # @param resume_step [String, nil] step at start of turn (before orchestrator advances); falls back to session.current_step
      def format_assistant(text, channel:, session:, resume_from_web: false, resume_from_sms: false, resume_step: nil)
        out = text.to_s

        if resume_from_web && sms_like?(channel)
          step = human_step(resume_step || session.current_step)
          out = "Picking up where you left off (#{step}).\n\n#{out}"
        end

        if resume_from_sms && channel.to_s == "web"
          out = "Welcome back in the app — continuing your onboarding.\n\n#{out}"
        end

        if sms_like?(channel)
          truncate_sms(out)
        else
          out
        end
      end

      def format_error(user_message, channel:)
        msg = user_message.to_s
        return truncate_sms(msg) if sms_like?(channel)

        msg
      end

      private

      def sms_like?(channel)
        %w[sms openclaw].include?(channel.to_s)
      end

      def human_step(step)
        step.to_s.tr("_", " ").strip.titleize.presence || "Onboarding"
      end

      def truncate_sms(text, max: SMS_MAX_CHARS)
        t = text.to_s
        return t if t.length <= max

        "#{t[0, max - 1]}…"
      end
    end
  end
end
