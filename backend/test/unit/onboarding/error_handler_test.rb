# frozen_string_literal: true

require "test_helper"

module Onboarding
  class ErrorHandlerTest < ActiveSupport::TestCase
    test "categorizes timeout errors" do
      error = Timeout::Error.new("execution expired")
      result = Onboarding::ErrorHandler.handle(error)

      assert_equal :timeout, result[:category]
      assert result[:user_message].present?
      assert result[:retryable]
    end

    test "categorizes network errors" do
      error = Errno::ECONNREFUSED.new("Connection refused")
      result = Onboarding::ErrorHandler.handle(error)

      assert_equal :network, result[:category]
      assert result[:retryable]
    end

    test "categorizes API key errors" do
      error = RuntimeError.new("OPENAI_API_KEY not set")
      result = Onboarding::ErrorHandler.handle(error)

      assert_equal :configuration, result[:category]
      assert_not result[:retryable]
    end

    test "categorizes unknown errors as internal" do
      error = StandardError.new("something weird happened")
      result = Onboarding::ErrorHandler.handle(error)

      assert_equal :internal, result[:category]
      assert result[:retryable]
      assert_not_includes result[:user_message], "something weird"
    end

    test "user messages are friendly and do not expose internals" do
      errors = [
        Timeout::Error.new,
        Errno::ECONNREFUSED.new,
        RuntimeError.new("API rate limit"),
        StandardError.new("NilClass undefined method")
      ]

      errors.each do |e|
        result = Onboarding::ErrorHandler.handle(e)
        assert result[:user_message].present?, "No user message for #{e.class}"
        assert_not_includes result[:user_message], "NilClass"
        assert_not_includes result[:user_message], "undefined method"
      end
    end

    test "categorizes rate limit errors" do
      error = RuntimeError.new("Rate limit exceeded")
      result = Onboarding::ErrorHandler.handle(error)

      assert_equal :rate_limit, result[:category]
      assert result[:retryable]
    end
  end
end
