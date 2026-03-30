# frozen_string_literal: true

module Messaging
  class InboundProcessor
    def initialize(adapter:)
      @adapter = adapter
    end

    def process(payload)
      from = Messaging::PhoneNumber.normalize(payload[:from] || payload["from"])
      body = (payload[:body] || payload["body"]).to_s
      external_id = payload[:external_id] || payload["external_id"]
      provider = (payload[:provider] || payload["provider"] || "unknown").to_s

      return { ok: false, error: "Missing sender phone number" } if from.blank?

      if duplicate_event?(provider: provider, external_id: external_id)
        return { ok: true, duplicate: true }
      end

      session = OnboardingSession.sms_opted_in.where(phone_number: from).order(updated_at: :desc).first
      inbound_event = SmsEvent.create!(
        onboarding_session: session,
        provider: provider,
        direction: "inbound",
        external_id: external_id,
        phone_number: from,
        body: body,
        status: "received"
      )

      unless session
        return { ok: false, event_id: inbound_event.id, error: "No opted-in session for phone number" }
      end

      result = Onboarding::TurnProcessor.process(
        session: session,
        body: body,
        channel: :sms,
        provider_message_id: external_id,
        inbound_event_id: inbound_event.id
      )

      assistant_text = if result[:error]
        result[:content].to_s
      else
        result[:content].to_s
      end

      send_result = @adapter.send_message(to: from, text: assistant_text)
      SmsEvent.create!(
        onboarding_session: session,
        provider: provider,
        direction: "outbound",
        external_id: send_result[:external_id],
        phone_number: from,
        body: assistant_text,
        status: send_result[:success] ? "sent" : "failed",
        error_message: send_result[:error],
        metadata: send_result.except(:success, :error, :external_id)
      )

      { ok: true, content: assistant_text }
    rescue => e
      { ok: false, error: "#{e.class}: #{e.message}" }
    end

    private

    def duplicate_event?(provider:, external_id:)
      return false if external_id.blank?

      SmsEvent.exists?(provider: provider, direction: "inbound", external_id: external_id)
    end
  end
end
