# frozen_string_literal: true

require "test_helper"

module Api
  module Admin
    class IdleSessionsControllerTest < ActionDispatch::IntegrationTest
      include ActiveSupport::Testing::TimeHelpers

      setup do
        @prev_enabled = ENV.fetch("OPENCLAW_ENABLED", nil)
        @prev_token = ENV.fetch("OPENCLAW_HOOKS_TOKEN", nil)
        @prev_nudge = ENV.fetch("PROACTIVE_NUDGE_ENABLED", nil)
        ENV["OPENCLAW_ENABLED"] = "true"
        ENV["OPENCLAW_HOOKS_TOKEN"] = "test-token"
        ENV["PROACTIVE_NUDGE_ENABLED"] = "true"
      end

      teardown do
        %w[OPENCLAW_ENABLED OPENCLAW_HOOKS_TOKEN PROACTIVE_NUDGE_ENABLED].each_with_index do |key, i|
          prev = [@prev_enabled, @prev_token, @prev_nudge][i]
          prev.nil? ? ENV.delete(key) : ENV[key] = prev
        end
      end

      test "returns 401 without valid hook token" do
        get "/api/admin/idle_sessions", headers: { "X-Openclaw-Token" => "wrong" }
        assert_response :unauthorized
      end

      test "returns 404 when proactive nudge is disabled" do
        ENV["PROACTIVE_NUDGE_ENABLED"] = "false"
        get "/api/admin/idle_sessions", headers: auth_headers
        assert_response :not_found
      end

      test "returns idle sessions that have not been nudged recently" do
        idle_session = OnboardingSession.create!(
          current_step: "personal_info",
          status: "active",
          last_channel: "openclaw",
          last_interaction_at: 4.hours.ago,
          channel_type: "telegram",
          channel_user_id: "tg-idle-1"
        )
        # completed session should not appear
        OnboardingSession.create!(
          current_step: "complete",
          status: "completed",
          last_channel: "web",
          last_interaction_at: 5.hours.ago
        )
        # recently active session should not appear
        OnboardingSession.create!(
          current_step: "welcome",
          status: "active",
          last_channel: "web",
          last_interaction_at: 30.minutes.ago
        )

        get "/api/admin/idle_sessions", headers: auth_headers
        assert_response :success
        body = JSON.parse(response.body)
        ids = body["sessions"].map { |s| s["id"] }
        assert_includes ids, idle_session.id
        assert_equal 1, ids.length
      end

      test "excludes sessions that received a nudge within 24 hours" do
        session = OnboardingSession.create!(
          current_step: "personal_info",
          status: "active",
          last_channel: "openclaw",
          last_interaction_at: 4.hours.ago
        )
        SmsEvent.create!(
          onboarding_session: session,
          provider: "openclaw",
          direction: "outbound",
          status: "sent",
          metadata: { nudge: true },
          created_at: 12.hours.ago
        )

        get "/api/admin/idle_sessions", headers: auth_headers
        body = JSON.parse(response.body)
        ids = body["sessions"].map { |s| s["id"] }
        assert_not_includes ids, session.id
      end

      test "excludes sessions that opted out" do
        session = OnboardingSession.create!(
          current_step: "personal_info",
          status: "active",
          last_channel: "sms",
          last_interaction_at: 4.hours.ago,
          phone_number: "+14155551234",
          sms_opt_in: false
        )

        get "/api/admin/idle_sessions", headers: auth_headers
        body = JSON.parse(response.body)
        ids = body["sessions"].map { |s| s["id"] }
        assert_not_includes ids, session.id
      end

      private

      def auth_headers
        { "X-Openclaw-Token" => "test-token" }
      end
    end
  end
end
