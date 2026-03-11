# frozen_string_literal: true

require "test_helper"

module Tools
  class SchemaValidatorTest < ActiveSupport::TestCase
    def setup
      @validator = SchemaValidator.new
    end

    test "validates known tool with required params" do
      result = @validator.validate("getOnboardingState", { "userId" => "user-1" })
      assert result[:valid], result[:errors].inspect
    end

    test "rejects unknown tool" do
      result = @validator.validate("unknown_tool", {})
      assert_not result[:valid]
      assert_includes result[:errors].join, "Unknown tool"
    end

    test "rejects getOnboardingState with missing required userId" do
      result = @validator.validate("getOnboardingState", {})
      assert_not result[:valid]
      assert_includes result[:errors].join, "Missing required"
      assert_includes result[:errors].join, "userId"
    end

    test "validate! raises ValidationError when invalid" do
      error = assert_raises(SchemaValidator::ValidationError) do
        @validator.validate!("getOnboardingState", {})
      end
      assert_match /userId|required/i, error.errors.to_s
    end

    test "tool_names returns all 9 tools" do
      names = @validator.tool_names
      assert_equal 9, names.size
      assert_includes names, "getOnboardingState"
      assert_includes names, "saveOnboardingProgress"
    end

    test "definitions_for_openai returns array of function tools" do
      defs = @validator.definitions_for_openai
      assert_equal 9, defs.size
      assert_equal "function", defs.first[:type]
      assert defs.first[:function][:name].present?
      assert defs.first[:function][:parameters].is_a?(Hash)
    end
  end
end
