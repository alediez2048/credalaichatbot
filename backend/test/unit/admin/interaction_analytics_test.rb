# frozen_string_literal: true

require "test_helper"

module Admin
  class InteractionAnalyticsTest < ActiveSupport::TestCase
    test "call returns aggregates" do
      s = OnboardingSession.create!(current_step: "welcome", status: "active")
      s.messages.create!(role: "user", content: "u", metadata: { channel: "web" })
      s.messages.create!(role: "assistant", content: "a", metadata: { channel: "web" })

      result = InteractionAnalytics.call
      assert result[:avg_user_messages_per_session] >= 0
      assert result[:avg_session_duration_minutes] >= 0
      assert result.key?(:sentiment_distribution)
      assert result.key?(:llm_usage_by_model)
    end

    test "counts sessions with error messages" do
      s = OnboardingSession.create!(current_step: "welcome", status: "active")
      s.messages.create!(role: "assistant", content: "err", metadata: { channel: "web", error: true })

      result = InteractionAnalytics.call
      assert result[:sessions_with_error_messages] >= 1
    end
  end
end
