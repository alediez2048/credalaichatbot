# frozen_string_literal: true

require "test_helper"

module Webhooks
  class SmsControllerTest < ActionDispatch::IntegrationTest
    test "twilio webhook accepts payload and returns ok" do
      session = OnboardingSession.create!(
        current_step: "welcome",
        status: "active",
        phone_number: "+14155551234",
        sms_opt_in: true
      )

      post "/webhooks/sms/twilio", params: { From: "+1 (415) 555-1234", Body: "continue", MessageSid: "sid-123" }

      assert_response :success
      assert_equal "sms", session.reload.last_channel
    end
  end
end
