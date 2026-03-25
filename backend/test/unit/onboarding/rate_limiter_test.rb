# frozen_string_literal: true

require "test_helper"

module Onboarding
  class RateLimiterTest < ActiveSupport::TestCase
    def setup
      Onboarding::RateLimiter.reset!
    end

    test "allows messages under the limit" do
      5.times do
        result = Onboarding::RateLimiter.check!(42)
        assert result[:allowed]
      end
    end

    test "blocks messages over the limit" do
      10.times { Onboarding::RateLimiter.check!(42) }
      result = Onboarding::RateLimiter.check!(42)
      assert_not result[:allowed]
      assert result[:message].present?
      assert result[:retry_after].present?
    end

    test "returns friendly error message when rate limited" do
      11.times { Onboarding::RateLimiter.check!(42) }
      result = Onboarding::RateLimiter.check!(42)
      assert_includes result[:message].downcase, "wait"
    end

    test "different sessions have independent limits" do
      10.times { Onboarding::RateLimiter.check!(1) }
      result1 = Onboarding::RateLimiter.check!(1)
      result2 = Onboarding::RateLimiter.check!(2)

      assert_not result1[:allowed]
      assert result2[:allowed]
    end

    test "limit resets after clearing store" do
      10.times { Onboarding::RateLimiter.check!(42) }
      assert_not Onboarding::RateLimiter.check!(42)[:allowed]

      Onboarding::RateLimiter.reset!
      assert Onboarding::RateLimiter.check!(42)[:allowed]
    end
  end
end
