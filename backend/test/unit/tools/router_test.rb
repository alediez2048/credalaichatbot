# frozen_string_literal: true

require "test_helper"

module Tools
  class RouterTest < ActiveSupport::TestCase
    def setup
      @router = Router.new
    end

    test "call delegates to handler and returns stub result" do
      result = @router.call("getOnboardingState", { "userId" => "user-1" })
      assert result[:success]
      assert_equal "getOnboardingState", result.dig(:data, :tool)
      assert_match /Stub/, result.dig(:data, :message).to_s
    end

    test "call with invalid params returns error" do
      result = @router.call("getOnboardingState", {})
      assert_not result[:success]
      assert result[:error].present?
      assert_match /Missing required|userId/i, result[:error]
    end

    test "call with unknown tool returns error" do
      result = @router.call("nonexistent_tool", {})
      assert_not result[:success]
      assert_match /No handler|Unknown/i, result[:error]
    end

    test "call with JSON string arguments parses and executes" do
      result = @router.call("getOnboardingState", '{"userId":"u2"}')
      assert result[:success]
      assert_equal "getOnboardingState", result.dig(:data, :tool)
    end

    test "tool_names returns 9 tools" do
      assert_equal 9, @router.tool_names.size
    end
  end
end
