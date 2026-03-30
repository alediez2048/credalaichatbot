# frozen_string_literal: true

module Api
  # Receives OpenClaw gateway HTTP hooks; authenticates via OPENCLAW_HOOKS_TOKEN; runs TurnProcessor.
  class OpenclawTurnsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :ensure_openclaw_enabled
    before_action :authenticate_hook_token

    def create
      text = hook_params[:text].to_s.strip
      if text.blank?
        render json: { error: "text is required" }, status: :unprocessable_entity
        return
      end

      channel_type = hook_params[:channel].to_s.strip
      sender_id = hook_params[:sender_id].to_s.strip
      if channel_type.blank? || sender_id.blank?
        render json: { error: "channel and sender_id are required" }, status: :unprocessable_entity
        return
      end

      message_id = hook_params[:message_id].presence || hook_params[:external_id].presence

      if message_id.present? && duplicate_inbound?(message_id)
        render json: duplicate_response(message_id), status: :ok
        return
      end

      session = Messaging::IdentityResolver.find_or_create_session!(
        channel_type: channel_type,
        sender_id: sender_id,
        phone_number: hook_params[:phone_number]
      )

      inbound = nil
      if message_id.present?
        inbound = SmsEvent.create!(
          onboarding_session: session,
          provider: "openclaw",
          direction: "inbound",
          external_id: message_id,
          phone_number: session.phone_number,
          body: text,
          status: "received",
          metadata: { channel_type: channel_type, sender_id: sender_id }
        )
      end

      result = Onboarding::TurnProcessor.process(
        session: session,
        body: text,
        channel: :openclaw,
        provider_message_id: message_id,
        inbound_event_id: inbound&.id
      )

      reply = result[:content].to_s
      render json: {
        reply: reply,
        step_changed: result[:step_changed],
        error: result[:error]&.dig(:category)
      }, status: :ok
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotUnique
      render json: duplicate_response(message_id), status: :ok
    end

    private

    def hook_params
      @hook_params ||= begin
        p = params.permit(:text, :channel, :sender_id, :message_id, :external_id, :phone_number, :token)
        p.to_h.symbolize_keys
      end
    end

    def ensure_openclaw_enabled
      return if ActiveModel::Type::Boolean.new.cast(ENV.fetch("OPENCLAW_ENABLED", "false"))

      render json: { error: "openclaw disabled" }, status: :not_found
    end

    def authenticate_hook_token
      return if performed?

      expected = ENV["OPENCLAW_HOOKS_TOKEN"].to_s
      if expected.blank?
        render json: { error: "openclaw hooks not configured" }, status: :service_unavailable
        return
      end

      supplied = request.headers["X-Openclaw-Token"].presence
      if supplied.blank?
        auth = request.headers["Authorization"].to_s
        supplied = auth.sub(/\ABearer\s+/i, "").strip if auth.match?(/\ABearer\s+/i)
      end
      supplied ||= hook_params[:token].to_s.presence

      unless supplied.present? && secure_token_match?(supplied, expected)
        render json: { error: "unauthorized" }, status: :unauthorized
      end
    end

    def secure_token_match?(supplied, expected)
      return false unless supplied.bytesize == expected.bytesize

      ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
    end

    def duplicate_inbound?(message_id)
      SmsEvent.exists?(provider: "openclaw", direction: "inbound", external_id: message_id)
    end

    def duplicate_response(message_id)
      event = SmsEvent.find_by(provider: "openclaw", direction: "inbound", external_id: message_id)
      return { reply: "", duplicate: true } unless event&.onboarding_session

      session = event.onboarding_session
      reply = session.messages.where(role: "assistant").where("created_at > ?", event.created_at).order(:id).pick(:content).to_s
      { reply: reply, duplicate: true }
    end
  end
end
