# frozen_string_literal: true

module Sentiment
  class PromptAdapter
    ADAPTATIONS = {
      "frustrated" => "The user seems frustrated. Be extra patient, acknowledge their difficulty, slow down, and offer to help step by step. Avoid asking for multiple things at once.",
      "confused" => "The user seems confused. Use simpler language, provide examples, and confirm understanding before moving on. Break complex steps into smaller pieces.",
      "anxious" => "The user seems anxious. Be reassuring, emphasize that there's no rush, validate their feelings, and remind them that help is available at any time.",
      "positive" => "The user is in a good mood. Maintain the positive energy, be friendly and efficient. You can move at a normal pace.",
      "neutral" => "The user is neutral. Proceed normally with a warm, professional tone."
    }.freeze

    DEFAULT_INSTRUCTIONS = "Proceed with a warm, professional tone."

    class << self
      def instructions_for(label)
        ADAPTATIONS[label.to_s] || DEFAULT_INSTRUCTIONS
      end

      # Build a prompt addition based on the session's current sentiment
      def adapt_prompt(session)
        current = Sentiment::Tracker.current_sentiment(session)
        return "" unless current

        <<~PROMPT
          ## Emotional Context
          Current user sentiment: #{current.label} (#{(current.confidence * 100).round}% confidence)
          #{instructions_for(current.label)}
        PROMPT
      end
    end
  end
end
