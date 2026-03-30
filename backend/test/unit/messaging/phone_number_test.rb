# frozen_string_literal: true

require "test_helper"

module Messaging
  class PhoneNumberTest < ActiveSupport::TestCase
    test "normalizes standard 10-digit US numbers" do
      assert_equal "+14155551234", PhoneNumber.normalize("(415) 555-1234")
    end

    test "keeps explicit country code when provided" do
      assert_equal "+14155551234", PhoneNumber.normalize("+1 (415) 555-1234")
    end

    test "returns nil for blank input" do
      assert_nil PhoneNumber.normalize(nil)
      assert_nil PhoneNumber.normalize(" ")
    end
  end
end
