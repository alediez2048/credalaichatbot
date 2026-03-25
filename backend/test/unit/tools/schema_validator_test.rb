# frozen_string_literal: true

require "test_helper"

module Tools
  class SchemaValidatorTest < ActiveSupport::TestCase
    def setup
      @validator = SchemaValidator.new
    end

    test "validates known tool with no required params" do
      result = @validator.validate("getOnboardingState", {})
      assert result[:valid], result[:errors].inspect
    end

    test "rejects unknown tool" do
      result = @validator.validate("unknown_tool", {})
      assert_not result[:valid]
      assert_includes result[:errors].join, "Unknown tool"
    end

    test "rejects tool with missing required params" do
      # extractDocumentData requires imageFile and documentType
      result = @validator.validate("extractDocumentData", {})
      assert_not result[:valid]
      assert_includes result[:errors].join, "Missing required"
    end

    test "validate! raises ValidationError when invalid" do
      error = assert_raises(SchemaValidator::ValidationError) do
        @validator.validate!("extractDocumentData", {})
      end
      assert_match /imageFile|required/i, error.errors.to_s
    end

    test "tool_names returns all 11 tools" do
      names = @validator.tool_names
      assert_equal 11, names.size
      assert_includes names, "getOnboardingState"
      assert_includes names, "saveOnboardingProgress"
    end

    test "definitions_for_openai returns array of function tools" do
      defs = @validator.definitions_for_openai
      assert_equal 11, defs.size
      assert_equal "function", defs.first[:type]
      assert defs.first[:function][:name].present?
      assert defs.first[:function][:parameters].is_a?(Hash)
    end

    test "saveOnboardingProgress requires data" do
      result = @validator.validate("saveOnboardingProgress", {})
      assert_not result[:valid]
      assert_includes result[:errors].join, "data"
    end

    test "saveOnboardingProgress valid with data" do
      result = @validator.validate("saveOnboardingProgress", { "data" => { "name" => "Jane" } })
      assert result[:valid], result[:errors].inspect
    end
  end
end
