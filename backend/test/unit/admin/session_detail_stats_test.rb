# frozen_string_literal: true

require "test_helper"

module Admin
  class SessionDetailStatsTest < ActiveSupport::TestCase
    test "returns nil for missing session" do
      assert_nil SessionDetailStats.call(0)
    end

    test "builds timeline with channel switch" do
      session = OnboardingSession.create!(current_step: "personal_info", status: "active", last_channel: "sms")
      session.messages.create!(role: "user", content: "hi", metadata: { channel: "web" })
      session.messages.create!(role: "assistant", content: "hello", metadata: { channel: "web" })
      session.messages.create!(role: "user", content: "sms hi", metadata: { channel: "sms", last_channel_before: "web" })

      detail = SessionDetailStats.call(session.id)
      kinds = detail[:timeline].map { |i| i[:kind] }
      assert_includes kinds, :channel_switch
      assert_includes kinds, :message
    end

    test "includes step marker when assistant has step_changed" do
      session = OnboardingSession.create!(current_step: "personal_info", status: "active")
      session.messages.create!(role: "assistant", content: "next", metadata: { channel: "web", step_changed: true, step_after: "personal_info" })

      detail = SessionDetailStats.call(session.id)
      assert detail[:timeline].any? { |i| i[:kind] == :step }
    end

    test "sidebar tallies channels" do
      session = OnboardingSession.create!(current_step: "welcome", status: "active")
      session.messages.create!(role: "user", content: "a", metadata: { channel: "web" })
      session.messages.create!(role: "user", content: "b", metadata: { channel: "sms" })

      detail = SessionDetailStats.call(session.id)
      assert_equal 1, detail[:sidebar][:channel_switch_count]
      assert detail[:sidebar][:channel_tally]["web"] >= 1
      assert detail[:sidebar][:channel_tally]["sms"] >= 1
    end
  end
end
