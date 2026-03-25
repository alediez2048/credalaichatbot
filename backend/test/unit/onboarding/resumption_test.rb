# frozen_string_literal: true

require "test_helper"

module Onboarding
  class ResumptionTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(
        status: "active",
        current_step: "personal_info",
        progress_percent: 20,
        metadata: { "full_name" => "Jane Doe" }
      )
    end

    # --- Resumption detection ---

    test "session is resuming when it has messages" do
      @session.messages.create!(role: "user", content: "Hello")
      @session.messages.create!(role: "assistant", content: "Hi there!")

      assert Onboarding::Resumption.resuming?(@session)
    end

    test "session is not resuming when it has no messages" do
      assert_not Onboarding::Resumption.resuming?(@session)
    end

    test "completed session is detected" do
      @session.update!(status: "completed", current_step: "complete")
      assert Onboarding::Resumption.completed?(@session)
    end

    # --- Welcome back message ---

    test "welcome_back_summary includes current step and collected data" do
      @session.messages.create!(role: "user", content: "Hello")
      summary = Onboarding::Resumption.welcome_back_summary(@session)

      assert_includes summary, "personal_info"
      assert_includes summary, "full_name"
    end

    test "welcome_back_summary for completed session" do
      @session.update!(status: "completed", current_step: "complete")
      summary = Onboarding::Resumption.welcome_back_summary(@session)

      assert_includes summary.downcase, "complete"
    end

    # --- Context summarization ---

    test "summarize_history returns all messages when under threshold" do
      5.times do |i|
        @session.messages.create!(role: "user", content: "Message #{i}")
        @session.messages.create!(role: "assistant", content: "Reply #{i}")
      end

      history = Onboarding::Resumption.build_history(@session)
      assert_equal 10, history.size
    end

    test "summarize_history truncates old messages when over threshold" do
      25.times do |i|
        @session.messages.create!(role: "user", content: "Message #{i}")
        @session.messages.create!(role: "assistant", content: "Reply #{i}")
      end

      history = Onboarding::Resumption.build_history(@session, max_messages: 20)
      # Should have a summary message + recent messages, not all 50
      assert history.size <= 22 # summary + up to 20 recent + buffer
      assert history.first[:role] == "system" || history.size <= 20
    end

    # --- Session reset ---

    test "reset clears session state" do
      @session.messages.create!(role: "user", content: "Hello")
      @session.messages.create!(role: "assistant", content: "Hi!")

      Onboarding::Resumption.reset!(@session)
      @session.reload

      assert_equal "welcome", @session.current_step
      assert_equal 0, @session.progress_percent
      assert_equal({}, @session.metadata)
      assert_equal 0, @session.messages.count
    end
  end
end
