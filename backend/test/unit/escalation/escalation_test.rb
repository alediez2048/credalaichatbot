# frozen_string_literal: true

require "test_helper"

module Escalation
  class EscalationTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(status: "active", current_step: "personal_info")
    end

    test "tier 1: extra-supportive prompt when mildly negative" do
      @session.sentiment_readings.create!(label: "confused", confidence: 0.7, signals: [])

      result = Escalation::Engine.evaluate(@session)
      assert_equal 1, result[:tier]
      assert result[:prompt_injection].present?
    end

    test "tier 2: offer human help when persistently negative" do
      @session.sentiment_readings.create!(label: "frustrated", confidence: 0.85, signals: [], created_at: 2.minutes.ago)
      @session.sentiment_readings.create!(label: "frustrated", confidence: 0.9, signals: [])

      result = Escalation::Engine.evaluate(@session)
      assert_equal 2, result[:tier]
      assert_includes result[:prompt_injection].downcase, "human"
    end

    test "tier 3: handoff when severely escalated" do
      3.times do |i|
        @session.sentiment_readings.create!(label: "frustrated", confidence: 0.95, signals: ["angry"], created_at: (3 - i).minutes.ago)
      end

      result = Escalation::Engine.evaluate(@session)
      assert_equal 3, result[:tier]
    end

    test "no escalation for positive sentiment" do
      @session.sentiment_readings.create!(label: "positive", confidence: 0.9, signals: [])

      result = Escalation::Engine.evaluate(@session)
      assert_equal 0, result[:tier]
    end

    test "detects explicit help request" do
      assert Escalation::Engine.explicit_help_request?("I need to talk to a real person")
      assert Escalation::Engine.explicit_help_request?("Can I speak to a human?")
      assert_not Escalation::Engine.explicit_help_request?("What's next?")
    end
  end
end
