# frozen_string_literal: true

require "test_helper"

module Api
  class OpenclawTurnsControllerTest < ActionDispatch::IntegrationTest
    include ActiveSupport::Testing::TimeHelpers

    setup do
      @prev_enabled = ENV.fetch("OPENCLAW_ENABLED", nil)
      @prev_token = ENV.fetch("OPENCLAW_HOOKS_TOKEN", nil)
      ENV["OPENCLAW_ENABLED"] = "true"
      ENV["OPENCLAW_HOOKS_TOKEN"] = "secret-test-token"
    end

    teardown do
      if @prev_enabled.nil?
        ENV.delete("OPENCLAW_ENABLED")
      else
        ENV["OPENCLAW_ENABLED"] = @prev_enabled
      end
      if @prev_token.nil?
        ENV.delete("OPENCLAW_HOOKS_TOKEN")
      else
        ENV["OPENCLAW_HOOKS_TOKEN"] = @prev_token
      end
    end

    test "returns not found when openclaw is disabled" do
      ENV["OPENCLAW_ENABLED"] = "false"
      post_json token: "secret-test-token", text: "hi", channel: "telegram", sender_id: "u1"
      assert_response :not_found
    end

    test "returns service unavailable when hooks token is not configured" do
      ENV.delete("OPENCLAW_HOOKS_TOKEN")
      post_json token: "x", text: "hi", channel: "telegram", sender_id: "u1"
      assert_response :service_unavailable
    end

    test "returns unauthorized when token does not match" do
      post_json token: "wrong", text: "hi", channel: "telegram", sender_id: "u1"
      assert_response :unauthorized
    end

    test "accepts bearer token in authorization header" do
      Onboarding::TurnProcessor.stub :process, { content: "ok", step_changed: false, error: nil } do
        post "/api/openclaw/turn",
          params: { text: "hi", channel: "telegram", sender_id: "u1" }.to_json,
          headers: {
            "CONTENT_TYPE" => "application/json",
            "Authorization" => "Bearer secret-test-token"
          }
      end
      assert_response :success
      body = JSON.parse(response.body)
      assert_equal "ok", body["reply"]
    end

    test "accepts x-openclaw-token header" do
      Onboarding::TurnProcessor.stub :process, { content: "ok", step_changed: false, error: nil } do
        post "/api/openclaw/turn",
          params: { text: "hi", channel: "telegram", sender_id: "u1" }.to_json,
          headers: {
            "CONTENT_TYPE" => "application/json",
            "X-Openclaw-Token" => "secret-test-token"
          }
      end
      assert_response :success
    end

    test "returns unprocessable when text is blank" do
      post_json token: "secret-test-token", text: "  ", channel: "telegram", sender_id: "u1"
      assert_response :unprocessable_entity
    end

    test "returns unprocessable when channel or sender_id is blank" do
      post_json token: "secret-test-token", text: "hi", channel: "", sender_id: "u1"
      assert_response :unprocessable_entity
      post_json token: "secret-test-token", text: "hi", channel: "telegram", sender_id: ""
      assert_response :unprocessable_entity
    end

    test "processes turn and returns reply" do
      Onboarding::TurnProcessor.stub :process, { content: "Assistant says hi", step_changed: true, error: nil } do
        post_json token: "secret-test-token", text: "hello", channel: "telegram", sender_id: "tg-99"
      end
      assert_response :success
      body = JSON.parse(response.body)
      assert_equal "Assistant says hi", body["reply"]
      assert_equal true, body["step_changed"]
      assert_nil body["error"]
    end

    test "duplicate message_id returns same reply without reprocessing" do
      session = OnboardingSession.create!(
        current_step: "welcome",
        status: "active",
        channel_type: "telegram",
        channel_user_id: "tg-dup",
        last_channel: "openclaw"
      )
      inbound_time = Time.zone.parse("2026-03-30 12:00:00")
      travel_to inbound_time do
        SmsEvent.create!(
          onboarding_session: session,
          provider: "openclaw",
          direction: "inbound",
          external_id: "ext-dup-1",
          body: "first",
          status: "received"
        )
      end
      travel_to inbound_time + 1.second do
        session.messages.create!(role: "assistant", content: "cached reply", metadata: {})
      end

      calls = 0
      Onboarding::TurnProcessor.stub :process, proc { calls += 1; { content: "should not run", step_changed: false, error: nil } } do
        post_json token: "secret-test-token", text: "first", channel: "telegram", sender_id: "tg-dup", message_id: "ext-dup-1"
      end
      assert_response :success
      body = JSON.parse(response.body)
      assert_equal 0, calls
      assert_equal "cached reply", body["reply"]
      assert_equal true, body["duplicate"]
    end

    private

    def post_json(**payload)
      post "/api/openclaw/turn",
        params: payload.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }
    end
  end
end
