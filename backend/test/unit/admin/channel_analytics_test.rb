# frozen_string_literal: true

require "test_helper"

module Admin
  class ChannelAnalyticsTest < ActiveSupport::TestCase
    test "call returns expected keys" do
      result = ChannelAnalytics.call
      assert result.key?(:web_only_count)
      assert result.key?(:multichannel_count)
      assert result.key?(:sms_summary)
      assert result[:sms_summary].key?(:delivery_success_rate)
    end

    test "classifies web only vs multichannel" do
      web = OnboardingSession.create!(current_step: "welcome", status: "active")
      web.messages.create!(role: "user", content: "x", metadata: { channel: "web" })

      multi = OnboardingSession.create!(current_step: "welcome", status: "active")
      multi.messages.create!(role: "user", content: "a", metadata: { channel: "web" })
      multi.messages.create!(role: "user", content: "b", metadata: { channel: "sms" })

      assert ChannelAnalytics.web_only?(web)
      assert_not ChannelAnalytics.web_only?(multi)
      assert ChannelAnalytics.multichannel?(multi)
      assert_not ChannelAnalytics.multichannel?(web)
    end
  end
end
