# frozen_string_literal: true

require "test_helper"

module Sentiment
  class PromptAdapterTest < ActiveSupport::TestCase
    test "returns empathetic instructions for frustrated sentiment" do
      instructions = Sentiment::PromptAdapter.instructions_for("frustrated")
      assert instructions.present?
      assert_includes instructions.downcase, "patient"
    end

    test "returns encouraging instructions for anxious sentiment" do
      instructions = Sentiment::PromptAdapter.instructions_for("anxious")
      assert instructions.present?
      assert_includes instructions.downcase, "reassur"
    end

    test "returns neutral instructions for positive sentiment" do
      instructions = Sentiment::PromptAdapter.instructions_for("positive")
      assert instructions.present?
    end

    test "returns default instructions for unknown label" do
      instructions = Sentiment::PromptAdapter.instructions_for("unknown")
      assert instructions.present?
    end

    test "builds adapted system prompt with sentiment context" do
      session = OnboardingSession.create!(status: "active", current_step: "personal_info")
      session.sentiment_readings.create!(label: "frustrated", confidence: 0.85, signals: ["short answers"])

      prompt_addition = Sentiment::PromptAdapter.adapt_prompt(session)
      assert_includes prompt_addition.downcase, "patient"
      assert_includes prompt_addition, "frustrated"
    end

    test "returns empty string when no sentiment readings" do
      session = OnboardingSession.create!(status: "active")
      assert_equal "", Sentiment::PromptAdapter.adapt_prompt(session)
    end
  end
end
