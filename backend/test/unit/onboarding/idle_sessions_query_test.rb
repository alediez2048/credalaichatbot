# frozen_string_literal: true

require "test_helper"

module Onboarding
  class IdleSessionsQueryTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::TimeHelpers

    test "returns sessions idle longer than threshold" do
      idle = OnboardingSession.create!(current_step: "personal_info", status: "active", last_channel: "web", last_interaction_at: 4.hours.ago, phone_number: "+14155550001", sms_opt_in: true)
      recent = OnboardingSession.create!(current_step: "welcome", status: "active", last_channel: "web", last_interaction_at: 30.minutes.ago, phone_number: "+14155550002", sms_opt_in: true)

      result = Onboarding::IdleSessionsQuery.call(idle_threshold: 2.hours)
      ids = result.map(&:id)
      assert_includes ids, idle.id
      assert_not_includes ids, recent.id
    end

    test "excludes completed sessions" do
      OnboardingSession.create!(current_step: "complete", status: "completed", last_channel: "web", last_interaction_at: 5.hours.ago)

      result = Onboarding::IdleSessionsQuery.call(idle_threshold: 2.hours)
      assert_empty result
    end

    test "excludes sessions nudged within cooldown" do
      session = OnboardingSession.create!(current_step: "personal_info", status: "active", last_channel: "openclaw", last_interaction_at: 4.hours.ago)
      SmsEvent.create!(
        onboarding_session: session,
        provider: "openclaw",
        direction: "outbound",
        status: "sent",
        metadata: { nudge: true },
        created_at: 12.hours.ago
      )

      result = Onboarding::IdleSessionsQuery.call(idle_threshold: 2.hours, nudge_cooldown: 24.hours)
      assert_not_includes result.map(&:id), session.id
    end

    test "excludes sessions with sms_opt_in false when they have a phone" do
      OnboardingSession.create!(
        current_step: "personal_info", status: "active", last_channel: "sms",
        last_interaction_at: 4.hours.ago, phone_number: "+14155551234", sms_opt_in: false
      )

      result = Onboarding::IdleSessionsQuery.call(idle_threshold: 2.hours)
      assert_empty result
    end

    test "includes openclaw channel sessions without phone even if sms_opt_in is false" do
      session = OnboardingSession.create!(
        current_step: "personal_info", status: "active", last_channel: "openclaw",
        last_interaction_at: 4.hours.ago, channel_type: "telegram", channel_user_id: "tg-1"
      )

      result = Onboarding::IdleSessionsQuery.call(idle_threshold: 2.hours)
      assert_includes result.map(&:id), session.id
    end
  end
end
