# frozen_string_literal: true

require "test_helper"

module Api
  module Admin
    class OpenclawStatusControllerTest < ActionDispatch::IntegrationTest
      setup do
        @prev_enabled = ENV.fetch("OPENCLAW_ENABLED", nil)
        @prev_token = ENV.fetch("OPENCLAW_HOOKS_TOKEN", nil)
        ENV["OPENCLAW_ENABLED"] = "true"
        ENV["OPENCLAW_HOOKS_TOKEN"] = "test-token"
      end

      teardown do
        @prev_enabled.nil? ? ENV.delete("OPENCLAW_ENABLED") : ENV["OPENCLAW_ENABLED"] = @prev_enabled
        @prev_token.nil? ? ENV.delete("OPENCLAW_HOOKS_TOKEN") : ENV["OPENCLAW_HOOKS_TOKEN"] = @prev_token
      end

      test "returns 401 without valid hook token" do
        get "/api/admin/openclaw_status", headers: { "X-Openclaw-Token" => "wrong" }
        assert_response :unauthorized
      end

      test "returns gateway status when openclaw is enabled" do
        get "/api/admin/openclaw_status", headers: { "X-Openclaw-Token" => "test-token" }
        assert_response :success
        body = JSON.parse(response.body)
        assert body.key?("openclaw_enabled")
        assert body.key?("proactive_nudge_enabled")
        assert body.key?("gateway_url")
      end

      test "returns not found when openclaw is disabled" do
        ENV["OPENCLAW_ENABLED"] = "false"
        get "/api/admin/openclaw_status", headers: { "X-Openclaw-Token" => "test-token" }
        assert_response :not_found
      end
    end
  end
end
