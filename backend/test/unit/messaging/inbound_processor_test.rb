# frozen_string_literal: true

require "test_helper"

module Messaging
  class InboundProcessorTest < ActiveSupport::TestCase
    class StubAdapter
      def send_message(to:, text:)
        { success: true, external_id: "out-1", provider: "twilio", to: to, text: text }
      end
    end

    test "processes inbound sms and writes messages/events" do
      session = OnboardingSession.create!(
        current_step: "welcome",
        status: "active",
        phone_number: "+14155551234",
        sms_opt_in: true
      )
      processor = InboundProcessor.new(adapter: StubAdapter.new)
      result = processor.process(
        provider: "twilio",
        from: "+1 (415) 555-1234",
        body: "resume",
        external_id: "in-1"
      )
      assert result[:ok], result.inspect

      session.reload
      assert_equal "sms", session.last_channel
      assert_equal 2, session.messages.count
      assert_equal 2, session.sms_events.count
      assert_equal %w[inbound outbound], session.sms_events.order(:created_at).pluck(:direction)
    end

    test "ignores duplicate inbound event" do
      session = OnboardingSession.create!(
        current_step: "welcome",
        status: "active",
        phone_number: "+14155551234",
        sms_opt_in: true
      )
      SmsEvent.create!(
        onboarding_session: session,
        provider: "twilio",
        direction: "inbound",
        external_id: "dup-1",
        phone_number: "+14155551234",
        body: "hello",
        status: "received"
      )

      processor = InboundProcessor.new(adapter: StubAdapter.new)
      result = processor.process(provider: "twilio", from: "+14155551234", body: "hello again", external_id: "dup-1")
      assert result[:ok]
      assert result[:duplicate]
      assert_equal 1, session.sms_events.where(direction: "inbound").count
    end
  end
end
