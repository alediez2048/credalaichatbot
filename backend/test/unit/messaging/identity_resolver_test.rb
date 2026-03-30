# frozen_string_literal: true

require "test_helper"

module Messaging
  class IdentityResolverTest < ActiveSupport::TestCase
    test "returns existing session by channel_type and channel_user_id" do
      existing = OnboardingSession.create!(
        current_step: "welcome",
        status: "active",
        channel_type: "telegram",
        channel_user_id: "u1",
        last_channel: "openclaw"
      )
      found = IdentityResolver.find_or_create_session!(channel_type: "telegram", sender_id: "u1")
      assert_equal existing.id, found.id
    end

    test "creates new session when no match" do
      assert_difference -> { OnboardingSession.count }, 1 do
        s = IdentityResolver.find_or_create_session!(channel_type: "discord", sender_id: "d-42")
        assert_equal "welcome", s.current_step
        assert_equal "discord", s.channel_type
        assert_equal "d-42", s.channel_user_id
        assert_equal "openclaw", s.last_channel
      end
    end

    test "links opted-in phone session when phone_number matches" do
      phone_session = OnboardingSession.create!(
        current_step: "personal_info",
        status: "active",
        phone_number: "+14155551234",
        sms_opt_in: true,
        last_channel: "sms"
      )
      linked = IdentityResolver.find_or_create_session!(
        channel_type: "telegram",
        sender_id: "tg-link",
        phone_number: "(415) 555-1234"
      )
      assert_equal phone_session.id, linked.id
      assert_equal "telegram", linked.reload.channel_type
      assert_equal "tg-link", linked.channel_user_id
      assert_equal "openclaw", linked.last_channel
    end

    test "does not link when another session already owns channel identity" do
      OnboardingSession.create!(
        current_step: "welcome",
        status: "active",
        channel_type: "telegram",
        channel_user_id: "tg-taken",
        last_channel: "openclaw"
      )
      phone_session = OnboardingSession.create!(
        current_step: "welcome",
        status: "active",
        phone_number: "+14155551234",
        sms_opt_in: true,
        last_channel: "sms"
      )
      created = IdentityResolver.find_or_create_session!(
        channel_type: "telegram",
        sender_id: "tg-taken",
        phone_number: "+14155551234"
      )
      assert_not_equal phone_session.id, created.id
      assert_equal "tg-taken", created.channel_user_id
    end

    test "raises when channel_type is blank" do
      assert_raises(ArgumentError) { IdentityResolver.find_or_create_session!(channel_type: "", sender_id: "x") }
    end

    test "raises when sender_id is blank" do
      assert_raises(ArgumentError) { IdentityResolver.find_or_create_session!(channel_type: "telegram", sender_id: " ") }
    end
  end
end
