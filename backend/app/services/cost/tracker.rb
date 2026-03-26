# frozen_string_literal: true

module Cost
  class Tracker
    # Record token usage from an LLM response. Gracefully no-ops on missing data.
    # @param session_id [Integer, String, nil] OnboardingSession ID
    # @param model [String] Model name
    # @param usage [Hash, nil] { "prompt_tokens" => N, "completion_tokens" => N, "total_tokens" => N }
    def self.record(session_id:, model:, usage:)
      return unless session_id.present? && usage.is_a?(Hash)

      prompt_tokens     = usage["prompt_tokens"] || usage[:prompt_tokens] || 0
      completion_tokens = usage["completion_tokens"] || usage[:completion_tokens] || 0
      total_tokens      = usage["total_tokens"] || usage[:total_tokens] || (prompt_tokens + completion_tokens)
      cost_usd          = Calculator.calculate(model: model, prompt_tokens: prompt_tokens, completion_tokens: completion_tokens)

      LLMUsage.create!(
        onboarding_session_id: session_id,
        model: model,
        prompt_tokens: prompt_tokens,
        completion_tokens: completion_tokens,
        total_tokens: total_tokens,
        cost_usd: cost_usd
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[Cost::Tracker] Failed to record usage: #{e.message}")
    end
  end
end
