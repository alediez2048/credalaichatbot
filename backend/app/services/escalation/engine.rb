# frozen_string_literal: true

module Escalation
  class Engine
    HELP_PATTERNS = [
      /\b(talk|speak|chat)\b.*\b(human|person|agent|someone|representative)\b/i,
      /\b(need|want)\b.*\b(help|support|assistance)\b.*\b(real|actual|human)\b/i,
      /\bescalat/i,
      /\breal person\b/i
    ].freeze

    TIER_1_THRESHOLD = 1 # any negative reading
    TIER_2_THRESHOLD = 2 # consecutive negative readings
    TIER_3_THRESHOLD = 3 # sustained frustration

    NEGATIVE_LABELS = %w[confused frustrated anxious].freeze

    class << self
      # Evaluate escalation tier for a session
      # @return [Hash] { tier: 0-3, prompt_injection: String }
      def evaluate(session)
        readings = session.sentiment_readings.recent(TIER_3_THRESHOLD + 1)
        return { tier: 0, prompt_injection: "" } if readings.empty?

        negative_streak = count_negative_streak(readings)

        if negative_streak >= TIER_3_THRESHOLD
          { tier: 3, prompt_injection: tier_3_prompt }
        elsif negative_streak >= TIER_2_THRESHOLD
          { tier: 2, prompt_injection: tier_2_prompt }
        elsif negative_streak >= TIER_1_THRESHOLD
          { tier: 1, prompt_injection: tier_1_prompt }
        else
          { tier: 0, prompt_injection: "" }
        end
      end

      def explicit_help_request?(message)
        HELP_PATTERNS.any? { |pattern| message.match?(pattern) }
      end

      private

      def count_negative_streak(readings)
        streak = 0
        readings.each do |r|
          break unless NEGATIVE_LABELS.include?(r.label)
          streak += 1
        end
        streak
      end

      def tier_1_prompt
        "The user seems to be having difficulty. Be extra supportive, patient, and offer additional guidance."
      end

      def tier_2_prompt
        "The user has been struggling for a while. Gently offer the option to speak with a human representative. Say something like: 'If you'd prefer, I can connect you with a member of our HR team who can help directly.'"
      end

      def tier_3_prompt
        "The user is very frustrated and may need human assistance. Prioritize offering a human handoff. Apologize for the difficulty and provide clear next steps for reaching a support agent."
      end
    end
  end
end
