# frozen_string_literal: true

module Messaging
  class InboundProcessor
    def initialize(adapter:)
      @adapter = adapter
    end

    STOP_KEYWORDS = %w[stop unsubscribe cancel quit end].freeze
    HELP_KEYWORDS = %w[help info].freeze
    START_KEYWORDS = %w[start subscribe unstop].freeze
    STOP_REPLY = "You have been unsubscribed. Reply START to re-subscribe."
    HELP_REPLY = "Reply to continue onboarding. Reply STOP to opt out. Reply START to re-subscribe."
    START_REPLY = "You have been re-subscribed. Reply to continue onboarding."

    def process(payload)
      from = Messaging::PhoneNumber.normalize(payload[:from] || payload["from"])
      body = (payload[:body] || payload["body"]).to_s
      external_id = payload[:external_id] || payload["external_id"]
      provider = (payload[:provider] || payload["provider"] || "unknown").to_s

      return { ok: false, error: "Missing sender phone number" } if from.blank?

      if duplicate_event?(provider: provider, external_id: external_id)
        return { ok: true, duplicate: true }
      end

      keyword_result = handle_keyword(from: from, body: body, provider: provider, external_id: external_id)
      return keyword_result if keyword_result

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

    def handle_keyword(from:, body:, provider:, external_id:)
      word = body.strip.downcase
      session = OnboardingSession.where(phone_number: from).order(updated_at: :desc).first
      return nil unless session

      if STOP_KEYWORDS.include?(word)
        session.update!(sms_opt_in: false)
        log_keyword_event(session: session, provider: provider, external_id: external_id, body: body, keyword: "stop")
        @adapter.send_message(to: from, text: STOP_REPLY)
        return { ok: true, opted_out: true }
      end

      if HELP_KEYWORDS.include?(word)
        log_keyword_event(session: session, provider: provider, external_id: external_id, body: body, keyword: "help")
        @adapter.send_message(to: from, text: HELP_REPLY)
        return { ok: true, help: true }
      end

      if START_KEYWORDS.include?(word)
        session.update!(sms_opt_in: true)
        log_keyword_event(session: session, provider: provider, external_id: external_id, body: body, keyword: "start")
        @adapter.send_message(to: from, text: START_REPLY)
        return { ok: true, opted_in: true }
      end

      nil
    end

    def log_keyword_event(session:, provider:, external_id:, body:, keyword:)
      SmsEvent.create!(
        onboarding_session: session,
        provider: provider,
        direction: "inbound",
        external_id: external_id,
        phone_number: session.phone_number,
        body: body,
        status: "received",
        metadata: { keyword: keyword }
      )
    end
  end
end
