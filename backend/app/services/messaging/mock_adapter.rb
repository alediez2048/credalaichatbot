# frozen_string_literal: true

module Messaging
  class MockAdapter < Provider
    PROVIDER = "mock"

    def send_message(to:, text:)
      {
        success: true,
        provider: PROVIDER,
        external_id: "mock-#{SecureRandom.hex(8)}",
        to: Messaging::PhoneNumber.normalize(to),
        body: text.to_s
      }
    end

    def parse_inbound(params)
      {
        provider: PROVIDER,
        from: Messaging::PhoneNumber.normalize(params["from"] || params[:from] || params["From"]),
        body: (params["body"] || params[:body] || params["Body"]).to_s,
        external_id: params["message_id"] || params[:message_id] || params["MessageSid"]
      }
    end

    def verify_signature(url:, params:, signature:)
      true
    end
  end
end
