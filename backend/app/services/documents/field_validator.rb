# frozen_string_literal: true

module Documents
  class FieldValidator
    HIGH_THRESHOLD = 0.90
    MEDIUM_THRESHOLD = 0.70

    # Fallback format rules for fields not defined in TypeRegistry
    FALLBACK_FORMAT_RULES = {
      "date_of_birth" => /\A\d{4}-\d{2}-\d{2}\z/,
      "expiry_date" => /\A\d{4}-\d{2}-\d{2}\z/,
      "ssn_last4" => /\A\d{4}\z/,
      "email" => /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/,
      "phone" => /\A[\d\s\-\(\)\+]{7,}\z/,
      "license_number" => /\A[A-Za-z0-9\-]{4,}\z/,
      "passport_number" => /\A[A-Za-z0-9]{6,}\z/
    }.freeze

    class << self
      # Classify a single field by confidence and update its status
      def classify_and_update!(field)
        confidence = field.confidence.to_f
        new_status = if confidence >= HIGH_THRESHOLD
          "auto_accepted"
        elsif confidence >= MEDIUM_THRESHOLD
          "needs_review"
        else
          "needs_correction"
        end

        field.update!(status: new_status)
        new_status
      end

      # Classify all pending fields for a document
      # @return [Hash] { auto_accepted: [], needs_review: [], needs_correction: [] }
      def classify_document(document)
        result = { auto_accepted: [], needs_review: [], needs_correction: [] }

        document.extracted_fields.where(status: "pending").find_each do |field|
          status = classify_and_update!(field)
          result[status.to_sym] << field
        end

        result
      end

      # Validate format of a specific field
      # @return [Hash] { valid: Boolean, error: String|nil }
      def validate_format(field_name, value, document_type: nil)
        pattern = resolve_format_pattern(field_name, document_type)
        return { valid: true, error: nil } unless pattern

        if value.to_s.match?(pattern)
          { valid: true, error: nil }
        else
          { valid: false, error: "Invalid format for #{field_name.humanize}" }
        end
      end

      # Build a summary for the LLM about field validation results
      def build_review_summary(document)
        result = classify_document(document)

        summary = []
        if result[:auto_accepted].any?
          summary << "Auto-accepted (high confidence): #{result[:auto_accepted].map { |f| "#{f.field_name}: #{f.value}" }.join(', ')}"
        end
        if result[:needs_review].any?
          summary << "Needs your confirmation: #{result[:needs_review].map { |f| "#{f.field_name}: #{f.value} (#{(f.confidence * 100).round}% confident)" }.join(', ')}"
        end
        if result[:needs_correction].any?
          summary << "Needs correction (low confidence): #{result[:needs_correction].map { |f| "#{f.field_name}: #{f.value || 'unreadable'}" }.join(', ')}"
        end

        summary.join("\n")
      end

      private

      def resolve_format_pattern(field_name, document_type)
        # Try TypeRegistry first, fall back to hardcoded rules
        if document_type
          begin
            rules = Documents::TypeRegistry.validation_rules_for(document_type)
            return Regexp.new("\\A#{rules[field_name]}\\z") if rules[field_name]
          rescue Documents::TypeRegistry::UnknownTypeError
            # Fall through to fallback
          end
        end
        FALLBACK_FORMAT_RULES[field_name]
      end
    end
  end
end
