# frozen_string_literal: true

require "test_helper"

module Tools
  class RouterTest < ActiveSupport::TestCase
    def setup
      @router = Router.new
    end

    test "call delegates to real handler for getOnboardingState" do
      result = @router.call("getOnboardingState", {})
      assert result[:success]
      # Without session context, returns "Session not available."
      assert_equal "Session not available.", result.dig(:data, :message)
    end

    test "call with session context returns session data" do
      session = OnboardingSession.create!(status: "active", current_step: "welcome", metadata: { "name" => "Jane" })
      result = @router.call("getOnboardingState", {}, context: { session: session })
      assert result[:success]
      assert_equal "welcome", result.dig(:data, :current_step)
      assert_equal({ "name" => "Jane" }, result.dig(:data, :collected_data))
    end

    test "call with invalid params returns error" do
      # extractDocumentData requires imageFile and documentType
      result = @router.call("extractDocumentData", {})
      assert_not result[:success]
      assert result[:error].present?
    end

    test "call with unknown tool returns error" do
      result = @router.call("nonexistent_tool", {})
      assert_not result[:success]
      assert_match /No handler|Unknown/i, result[:error]
    end

    test "call with JSON string arguments parses and executes" do
      result = @router.call("getOnboardingState", '{"userId":"u2"}')
      assert result[:success]
    end

    test "stub tools return coming soon message" do
      result = @router.call("detectUserSentiment", {})
      assert result[:success]
      assert_match /coming soon/i, result.dig(:data, :message).to_s
    end

    test "saveOnboardingProgress persists data to session" do
      session = OnboardingSession.create!(status: "active", current_step: "personal_info", metadata: {})
      result = @router.call("saveOnboardingProgress", {
        "data" => { "full_name" => "Test User" }
      }, context: { session: session })
      assert result[:success]
      session.reload
      assert_equal "Test User", session.metadata["full_name"]
    end

    test "startOnboarding sets current_step" do
      session = OnboardingSession.create!(status: "active", current_step: nil, metadata: {})
      result = @router.call("startOnboarding", {}, context: { session: session })
      assert result[:success]
      session.reload
      assert_equal "welcome", session.current_step
    end

    test "tool_names returns 11 tools" do
      assert_equal 11, @router.tool_names.size
    end
  end
end
