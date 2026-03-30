# frozen_string_literal: true

module Messaging
  class Factory
    class << self
      def build(provider: ENV.fetch("SMS_PROVIDER", "mock"))
        case provider.to_s
        when "twilio"
          TwilioAdapter.new
        else
          MockAdapter.new
        end
      end
    end
  end
end
