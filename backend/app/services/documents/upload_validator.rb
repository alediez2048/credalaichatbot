# frozen_string_literal: true

module Documents
  class UploadValidator
    ALLOWED_CONTENT_TYPES = Document::ALLOWED_CONTENT_TYPES
    MAX_FILE_SIZE = Document::MAX_FILE_SIZE

    # @param file [ActionDispatch::Http::UploadedFile]
    # @return [Hash] { valid: Boolean, errors: Array<String> }
    def self.validate(file)
      errors = []

      if file.nil?
        return { valid: false, errors: ["No file provided"] }
      end

      content_type = file.content_type
      unless ALLOWED_CONTENT_TYPES.include?(content_type)
        errors << "Unsupported file type '#{content_type}'. Allowed: PNG, JPEG, PDF."
      end

      if file.size > MAX_FILE_SIZE
        errors << "File too large (#{(file.size / 1.megabyte.to_f).round(1)} MB). Maximum is 10 MB."
      end

      { valid: errors.empty?, errors: errors }
    end
  end
end
