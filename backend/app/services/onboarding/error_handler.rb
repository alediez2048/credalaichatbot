# frozen_string_literal: true

module Onboarding
  class ErrorHandler
    TIMEOUT_CLASSES = [Timeout::Error, Net::OpenTimeout, Net::ReadTimeout].freeze
    NETWORK_CLASSES = [Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, SocketError].freeze

    MESSAGES = {
      timeout: "I'm taking a bit longer than expected to respond. Please try again in a moment.",
      network: "I'm having trouble connecting right now. Please try again in a few seconds.",
      rate_limit: "I'm handling a lot of requests right now. Please wait a moment and try again.",
      configuration: "The assistant is not fully configured yet. Please contact support.",
      internal: "Something went wrong on my end. Please try sending your message again."
    }.freeze

    class << self
      # @param error [Exception]
      # @return [Hash] { category:, user_message:, retryable:, logged_message: }
      def handle(error)
        category = categorize(error)
        {
          category: category,
          user_message: MESSAGES[category],
          retryable: category != :configuration,
          logged_message: "#{error.class}: #{error.message}"
        }
      end

      private

      def categorize(error)
        return :timeout if TIMEOUT_CLASSES.any? { |klass| error.is_a?(klass) }
        return :network if NETWORK_CLASSES.any? { |klass| error.is_a?(klass) }

        message = error.message.to_s.downcase
        return :rate_limit if message.include?("rate limit")
        return :configuration if message.include?("api_key") || message.include?("not set") || message.include?("not configured")

        :internal
      end
    end
  end
end
