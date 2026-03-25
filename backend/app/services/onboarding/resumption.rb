# frozen_string_literal: true

module Onboarding
  class Resumption
    MAX_RECENT_MESSAGES = 20

    class << self
      def resuming?(session)
        session.messages.exists?
      end

      def completed?(session)
        session.status == "completed" || session.current_step == "complete"
      end

      # Build a human-readable summary for the welcome-back context
      def welcome_back_summary(session)
        if completed?(session)
          "Your onboarding is complete. If you need to update any information, please contact HR."
        else
          step = session.current_step || "welcome"
          collected = session.metadata || {}
          fields = collected.except("_pending_advance")

          parts = ["You're resuming onboarding at the '#{step}' step."]
          if fields.any?
            parts << "Information collected so far: #{fields.map { |k, v| "#{k}: #{v}" }.join(', ')}."
          end
          parts.join(" ")
        end
      end

      # Build message history for the LLM, with summarization for long sessions
      def build_history(session, max_messages: MAX_RECENT_MESSAGES)
        messages = session.messages.order(:created_at)
        total = messages.count

        if total <= max_messages
          messages.map { |m| { role: m.role, content: m.content.to_s } }
        else
          # Take the most recent messages and prepend a summary
          recent = messages.offset(total - max_messages).limit(max_messages)
          older_count = total - max_messages

          summary = {
            role: "system",
            content: "[Context: #{older_count} earlier messages were exchanged. The user has been providing onboarding information. Current progress is summarized in the system prompt.]"
          }

          [summary] + recent.map { |m| { role: m.role, content: m.content.to_s } }
        end
      end

      # Reset session to start over
      def reset!(session)
        session.messages.destroy_all
        session.update!(
          current_step: "welcome",
          progress_percent: 0,
          metadata: {},
          status: "active"
        )
      end
    end
  end
end
