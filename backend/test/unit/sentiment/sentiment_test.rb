# frozen_string_literal: true

require "test_helper"

module Sentiment
  class SentimentTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(status: "active", current_step: "personal_info")
    end

    # --- Analyzer ---

    test "parses structured LLM sentiment response" do
      llm_response = {
        "choices" => [{
          "message" => {
            "content" => {
              "label" => "frustrated",
              "confidence" => 0.85,
              "signals" => ["repeated questions", "short responses", "use of exclamation marks"]
            }.to_json
          }
        }]
      }

      result = Sentiment::Analyzer.parse_response(llm_response)
      assert_equal "frustrated", result[:label]
      assert_in_delta 0.85, result[:confidence], 0.01
      assert_equal 3, result[:signals].size
    end

    test "handles malformed LLM response gracefully" do
      bad_response = { "choices" => [{ "message" => { "content" => "not json" } }] }
      result = Sentiment::Analyzer.parse_response(bad_response)
      assert_equal "neutral", result[:label]
      assert_equal 0.5, result[:confidence]
    end

    test "builds sentiment prompt from messages" do
      messages = [
        { role: "user", content: "This is so confusing" },
        { role: "assistant", content: "I understand, let me help" },
        { role: "user", content: "I keep getting errors!" }
      ]
      prompt = Sentiment::Analyzer.build_prompt(messages)
      assert_includes prompt, "confusing"
      assert_includes prompt, "errors"
      assert_includes prompt.downcase, "sentiment"
    end

    # --- Tracker ---

    test "persists a sentiment reading" do
      Sentiment::Tracker.record(@session, label: "frustrated", confidence: 0.85, signals: ["short answers"])
      assert_equal 1, @session.reload.sentiment_readings.count
      assert_equal "frustrated", @session.sentiment_readings.last.label
    end

    test "recent_trend returns last N readings" do
      Sentiment::Tracker.record(@session, label: "neutral", confidence: 0.7, signals: [])
      Sentiment::Tracker.record(@session, label: "confused", confidence: 0.8, signals: [])
      Sentiment::Tracker.record(@session, label: "frustrated", confidence: 0.9, signals: [])

      trend = Sentiment::Tracker.recent_trend(@session, 3)
      assert_equal 3, trend.size
      assert_equal "frustrated", trend.first.label # most recent first
    end

    test "is_escalating? detects worsening sentiment" do
      Sentiment::Tracker.record(@session, label: "neutral", confidence: 0.7, signals: [])
      Sentiment::Tracker.record(@session, label: "confused", confidence: 0.8, signals: [])
      Sentiment::Tracker.record(@session, label: "frustrated", confidence: 0.9, signals: [])

      assert Sentiment::Tracker.escalating?(@session)
    end

    test "is_escalating? returns false for stable/positive trend" do
      Sentiment::Tracker.record(@session, label: "neutral", confidence: 0.7, signals: [])
      Sentiment::Tracker.record(@session, label: "positive", confidence: 0.8, signals: [])

      assert_not Sentiment::Tracker.escalating?(@session)
    end

    test "current_sentiment returns the most recent reading" do
      Sentiment::Tracker.record(@session, label: "neutral", confidence: 0.7, signals: [])
      Sentiment::Tracker.record(@session, label: "frustrated", confidence: 0.9, signals: [])

      current = Sentiment::Tracker.current_sentiment(@session)
      assert_equal "frustrated", current.label
    end
  end
end
