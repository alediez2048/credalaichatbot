# frozen_string_literal: true

require "test_helper"

module Api
  class OnboardingSmsSettingsControllerTest < ActionDispatch::IntegrationTest
    test "patch sms_settings updates phone and opt-in for anonymous session" do
      get onboarding_path
      assert_response :success
      sid = session[:onboarding_session_id]
      assert sid.present?

      patch "/api/onboarding_sessions/#{sid}/sms_settings",
        params: { phone_number: "4155551234", sms_opt_in: true }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      assert_response :success
      body = JSON.parse(response.body)
      assert_equal "+14155551234", body["phone_number"]
      assert body["sms_opt_in"]
      assert body["sms_ready"]
    end

    test "post sms_handoff sends with mock provider" do
      get onboarding_path
      sid = session[:onboarding_session_id]
      OnboardingSession.find(sid).update!(phone_number: "+14155551234", sms_opt_in: true)

      post "/api/onboarding_sessions/#{sid}/sms_handoff",
        params: {}.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      assert_response :created
      assert JSON.parse(response.body)["ok"]
    end
  end
end
