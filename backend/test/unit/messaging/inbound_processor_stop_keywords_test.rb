# frozen_string_literal: true

require "test_helper"

module Messaging
  class InboundProcessorStopKeywordsTest < ActiveSupport::TestCase
    setup do
      @adapter = Messaging::MockAdapter.new
      @processor = Messaging::InboundProcessor.new(adapter: @adapter)
      @session = OnboardingSession.create!(
        current_step: "personal_info",
        status: "active",
        phone_number: "+14155551234",
        sms_opt_in: true,
        last_channel: "sms"
      )
    end

    test "STOP keyword disables sms_opt_in and returns confirmation" do
      result = @processor.process(from: "+14155551234", body: "STOP", provider: "twilio", external_id: "stop-1")
      assert result[:ok]
      assert_equal true, result[:opted_out]
      @session.reload
      assert_equal false, @session.sms_opt_in
    end

    test "stop is case-insensitive" do
      result = @processor.process(from: "+14155551234", body: "  stop  ", provider: "twilio", external_id: "stop-2")
      assert result[:ok]
      assert_equal true, result[:opted_out]
    end

    test "HELP keyword returns help text without changing opt-in" do
      result = @processor.process(from: "+14155551234", body: "HELP", provider: "twilio", external_id: "help-1")
      assert result[:ok]
      assert_equal true, result[:help]
      @session.reload
      assert_equal true, @session.sms_opt_in
    end

    test "START keyword re-enables sms_opt_in" do
      @session.update!(sms_opt_in: false)
      result = @processor.process(from: "+14155551234", body: "START", provider: "twilio", external_id: "start-1")
      assert result[:ok]
      assert_equal true, result[:opted_in]
      @session.reload
      assert_equal true, @session.sms_opt_in
    end
  end
end
