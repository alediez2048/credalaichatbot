# frozen_string_literal: true

module Onboarding
  class RateLimiter
    MAX_MESSAGES_PER_MINUTE = 10
    WINDOW_SECONDS = 60

    # Use a dedicated MemoryStore so rate limiting works even when Rails.cache is null_store.
    # In production with multiple processes, swap to RedisCacheStore.
    STORE = ActiveSupport::Cache::MemoryStore.new

    class << self
      # @param session_id [Integer, String]
      # @return [Hash] { allowed: Boolean, message: String|nil, retry_after: Integer|nil }
      def check!(session_id)
        key = "rate_limit:chat:session:#{session_id}"
        count = STORE.read(key) || 0
        count += 1
        STORE.write(key, count, expires_in: WINDOW_SECONDS.seconds)

        if count > MAX_MESSAGES_PER_MINUTE
          {
            allowed: false,
            message: "You're sending messages too quickly. Please wait a moment and try again.",
            retry_after: WINDOW_SECONDS
          }
        else
          { allowed: true, message: nil, retry_after: nil }
        end
      end

      # For testing: clear all rate limit state
      def reset!
        STORE.clear
      end
    end
  end
end
