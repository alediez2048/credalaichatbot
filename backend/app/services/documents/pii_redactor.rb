# frozen_string_literal: true

module Documents
  class PiiRedactor
    PATTERNS = [
      [/\b\d{3}-\d{2}-\d{4}\b/, "***-**-****"],           # SSN
      [/\b\d{4}-\d{2}-\d{2}\b/, "[DATE REDACTED]"],        # Date (YYYY-MM-DD)
      [/\b\d{2}\/\d{2}\/\d{4}\b/, "[DATE REDACTED]"],      # Date (MM/DD/YYYY)
      [/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/, "[EMAIL REDACTED]"], # Email
      [/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/, "[PHONE REDACTED]"] # Phone
    ].freeze

    class << self
      def redact(text)
        return "" if text.nil?

        result = text.dup
        PATTERNS.each do |pattern, replacement|
          result.gsub!(pattern, replacement)
        end
        result
      end
    end
  end
end
