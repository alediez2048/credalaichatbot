# frozen_string_literal: true

module Messaging
  class PhoneNumber
    class << self
      # Normalize to a conservative E.164-like format for US numbers.
      # For non-US formats we keep a leading + and digits as provided.
      def normalize(raw)
        return nil if raw.blank?

        cleaned = raw.to_s.strip
        has_plus = cleaned.start_with?("+")
        digits = cleaned.gsub(/\D/, "")
        return nil if digits.blank?

        if has_plus
          "+#{digits}"
        elsif digits.length == 10
          "+1#{digits}"
        elsif digits.length == 11 && digits.start_with?("1")
          "+#{digits}"
        else
          "+#{digits}"
        end
      end
    end
  end
end
