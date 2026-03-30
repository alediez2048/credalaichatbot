# frozen_string_literal: true

require "test_helper"

module Onboarding
  class ChannelFormatterTest < ActiveSupport::TestCase
    test "openclaw truncates long text like sms" do
      long = "a" * 2000
      out = ChannelFormatter.format_assistant(
        long,
        channel: :openclaw,
        session: OnboardingSession.new(current_step: "welcome"),
        resume_from_web: false,
        resume_from_sms: false
      )
      assert_operator out.length, :<=, ChannelFormatter::SMS_MAX_CHARS
      assert out.end_with?("…")
    end

    test "sms truncates long text" do
      long = "a" * 2000
      out = ChannelFormatter.format_assistant(
        long,
        channel: :sms,
        session: OnboardingSession.new(current_step: "welcome"),
        resume_from_web: false,
        resume_from_sms: false
      )
      assert_operator out.length, :<=, ChannelFormatter::SMS_MAX_CHARS
      assert out.end_with?("…")
    end

    test "prepends resume line when switching from web to sms" do
      session = OnboardingSession.new(current_step: "personal_info")
      out = ChannelFormatter.format_assistant(
        "Hello there.",
        channel: :sms,
        session: session,
        resume_from_web: true,
        resume_from_sms: false,
        resume_step: "personal_info"
      )
      assert_match(/Picking up where you left off \(Personal Info\)/, out)
      assert_match(/Hello there\./, out)
    end

    test "prepends welcome back when switching from sms to web" do
      out = ChannelFormatter.format_assistant(
        "Next question.",
        channel: :web,
        session: OnboardingSession.new(current_step: "welcome"),
        resume_from_web: false,
        resume_from_sms: true
      )
      assert_match(/Welcome back in the app/, out)
    end
  end
end
