# frozen_string_literal: true

require "test_helper"

module Documents
  class ExtractionServiceTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(status: "active", current_step: "document_upload")
      @document = @session.documents.create!(document_type: "drivers_license", status: "uploaded", content_type: "image/png", byte_size: 1024)
    end

    test "parses Vision API response into ExtractedField records" do
      vision_response = {
        "choices" => [{
          "message" => {
            "content" => {
              "fields" => [
                { "name" => "full_name", "value" => "Jane Doe", "confidence" => 0.95 },
                { "name" => "date_of_birth", "value" => "1990-01-15", "confidence" => 0.88 },
                { "name" => "address", "value" => "123 Main St", "confidence" => 0.72 }
              ]
            }.to_json
          }
        }]
      }

      service = Documents::ExtractionService.new(@document)
      fields = service.parse_extraction_response(vision_response)

      assert_equal 3, fields.size
      assert_equal "full_name", fields[0][:field_name]
      assert_equal "Jane Doe", fields[0][:value]
      assert_in_delta 0.95, fields[0][:confidence], 0.001
    end

    test "creates ExtractedField records from parsed fields" do
      parsed = [
        { field_name: "full_name", value: "Jane Doe", confidence: 0.95 },
        { field_name: "date_of_birth", value: "1990-01-15", confidence: 0.88 }
      ]

      service = Documents::ExtractionService.new(@document)
      service.save_fields(parsed)

      assert_equal 2, @document.extracted_fields.count
      field = @document.extracted_fields.find_by(field_name: "full_name")
      assert_equal "Jane Doe", field.value
      assert_in_delta 0.95, field.confidence.to_f, 0.001
      assert_equal "pending", field.status
    end

    test "updates document status to extracted on success" do
      service = Documents::ExtractionService.new(@document)
      service.save_fields([{ field_name: "name", value: "Test", confidence: 0.9 }])
      service.mark_extracted!

      @document.reload
      assert_equal "extracted", @document.status
    end

    test "marks document as extraction_failed on error" do
      service = Documents::ExtractionService.new(@document)
      service.mark_failed!("API timeout")

      @document.reload
      assert_equal "extraction_failed", @document.status
    end

    test "handles malformed Vision API response gracefully" do
      bad_response = { "choices" => [{ "message" => { "content" => "not json" } }] }

      service = Documents::ExtractionService.new(@document)
      fields = service.parse_extraction_response(bad_response)

      assert_equal [], fields
    end

    test "builds correct prompt for document type" do
      service = Documents::ExtractionService.new(@document)
      prompt = service.build_extraction_prompt

      assert_includes prompt, "drivers_license"
      assert_includes prompt.downcase, "extract"
      assert_includes prompt.downcase, "json"
    end
  end
end
