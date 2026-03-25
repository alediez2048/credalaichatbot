# frozen_string_literal: true

require "test_helper"

module Documents
  class FieldValidatorTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(status: "active", current_step: "document_upload")
      @document = @session.documents.create!(document_type: "drivers_license", status: "extracted", content_type: "image/png", byte_size: 1024)
    end

    # --- Confidence tiers ---

    test "classifies high confidence fields as auto_accepted" do
      field = @document.extracted_fields.create!(field_name: "full_name", value: "Jane Doe", confidence: 0.95, status: "pending")
      Documents::FieldValidator.classify_and_update!(field)
      assert_equal "auto_accepted", field.reload.status
    end

    test "classifies medium confidence fields as needs_review" do
      field = @document.extracted_fields.create!(field_name: "full_name", value: "Jane Doe", confidence: 0.80, status: "pending")
      Documents::FieldValidator.classify_and_update!(field)
      assert_equal "needs_review", field.reload.status
    end

    test "classifies low confidence fields as needs_correction" do
      field = @document.extracted_fields.create!(field_name: "full_name", value: "J??? D??", confidence: 0.40, status: "pending")
      Documents::FieldValidator.classify_and_update!(field)
      assert_equal "needs_correction", field.reload.status
    end

    test "boundary: 0.90 is high confidence" do
      field = @document.extracted_fields.create!(field_name: "name", value: "Test", confidence: 0.90, status: "pending")
      Documents::FieldValidator.classify_and_update!(field)
      assert_equal "auto_accepted", field.reload.status
    end

    test "boundary: 0.70 is medium confidence" do
      field = @document.extracted_fields.create!(field_name: "name", value: "Test", confidence: 0.70, status: "pending")
      Documents::FieldValidator.classify_and_update!(field)
      assert_equal "needs_review", field.reload.status
    end

    # --- Format validation ---

    test "validates date format" do
      result = Documents::FieldValidator.validate_format("date_of_birth", "1990-01-15")
      assert result[:valid]
    end

    test "rejects invalid date format" do
      result = Documents::FieldValidator.validate_format("date_of_birth", "abc")
      assert_not result[:valid]
      assert result[:error].present?
    end

    test "validates SSN last 4 format" do
      result = Documents::FieldValidator.validate_format("ssn_last4", "1234")
      assert result[:valid]
    end

    test "rejects invalid SSN last 4" do
      result = Documents::FieldValidator.validate_format("ssn_last4", "12345")
      assert_not result[:valid]
    end

    # --- Classify all fields for a document ---

    test "classify_document processes all pending fields" do
      @document.extracted_fields.create!(field_name: "name", value: "Jane", confidence: 0.95, status: "pending")
      @document.extracted_fields.create!(field_name: "dob", value: "1990-01-01", confidence: 0.75, status: "pending")
      @document.extracted_fields.create!(field_name: "addr", value: "???", confidence: 0.30, status: "pending")

      result = Documents::FieldValidator.classify_document(@document)

      assert_equal 1, result[:auto_accepted].size
      assert_equal 1, result[:needs_review].size
      assert_equal 1, result[:needs_correction].size
    end
  end
end
