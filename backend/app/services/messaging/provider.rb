# frozen_string_literal: true

module Messaging
  class Provider
    def send_message(to:, text:)
      raise NotImplementedError, "Implement in provider adapter"
    end

    def parse_inbound(params)
      raise NotImplementedError, "Implement in provider adapter"
    end

    def verify_signature(url:, params:, signature:)
      raise NotImplementedError, "Implement in provider adapter"
    end
  end
end
