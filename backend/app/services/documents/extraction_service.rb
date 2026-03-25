# frozen_string_literal: true

module Documents
  class ExtractionService
    DEFAULT_FIELDS = %w[full_name date_of_birth address].freeze

    def initialize(document, chat_service: nil)
      @document = document
      @chat_service = chat_service || LLM::ChatService.new
    end

    # Call OpenAI Vision API to extract fields from the document image
    # @return [Array<Hash>] parsed fields
    def extract!
      @document.update!(status: "processing")

      response = call_vision_api
      fields = parse_extraction_response(response)
      save_fields(fields)
      mark_extracted!

      fields
    rescue StandardError => e
      mark_failed!(e.message)
      Rails.logger.error "[ExtractionService] #{e.class}: #{e.message}"
      []
    end

    def build_extraction_prompt
      expected_fields = begin
        Documents::TypeRegistry.fields_for(@document.document_type)
      rescue Documents::TypeRegistry::UnknownTypeError
        DEFAULT_FIELDS
      end

      hints = begin
        Documents::TypeRegistry.extraction_hints_for(@document.document_type)
      rescue Documents::TypeRegistry::UnknownTypeError
        ""
      end

      <<~PROMPT
        You are a document data extraction system. Analyze the provided #{@document.document_type} document image and extract structured data.
        #{"Context: #{hints}" if hints.present?}

        Extract the following fields: #{expected_fields.join(', ')}

        Return your response as a JSON object with this exact structure:
        {
          "fields": [
            { "name": "field_name", "value": "extracted value", "confidence": 0.95 }
          ]
        }

        Rules:
        - confidence is a number between 0.0 and 1.0 indicating how certain you are of the extracted value
        - If a field is not visible or readable, include it with value: null and confidence: 0.0
        - Do not invent or guess values — only extract what you can see
        - Return ONLY the JSON object, no other text
      PROMPT
    end

    def parse_extraction_response(response)
      content = response.dig("choices", 0, "message", "content").to_s
      # Try parsing the content as JSON
      parsed = JSON.parse(content)
      fields_array = parsed["fields"] || []

      fields_array.map do |f|
        {
          field_name: f["name"].to_s,
          value: f["value"],
          confidence: f["confidence"].to_f
        }
      end
    rescue JSON::ParserError
      []
    end

    def save_fields(fields)
      fields.each do |f|
        @document.extracted_fields.create!(
          field_name: f[:field_name],
          value: f[:value].to_s,
          confidence: f[:confidence],
          status: "pending"
        )
      end
    end

    def mark_extracted!
      @document.update!(status: "extracted")
    end

    def mark_failed!(reason = nil)
      @document.update!(status: "extraction_failed")
    end

    private

    def call_vision_api
      # Build a Vision API request with the document image
      messages = [
        {
          role: "user",
          content: [
            { type: "text", text: build_extraction_prompt },
            { type: "image_url", image_url: { url: image_data_url } }
          ]
        }
      ]

      @chat_service.chat(messages: messages, tools: [])
    end

    def image_data_url
      if @document.file.attached?
        blob = @document.file.blob
        data = blob.download
        base64 = Base64.strict_encode64(data)
        "data:#{blob.content_type};base64,#{base64}"
      else
        # Fallback: no file attached (shouldn't happen in normal flow)
        "data:image/png;base64,"
      end
    end
  end
end
