# frozen_string_literal: true

module Webhooks
  class SmsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def twilio
      adapter = Messaging::Factory.build(provider: "twilio")
      unless adapter.verify_signature(
        url: request.original_url,
        params: signature_params,
        signature: request.headers["X-Twilio-Signature"]
      )
        render plain: "unauthorized", status: :unauthorized
        return
      end

      payload = adapter.parse_inbound(params.to_unsafe_h)
      result = Messaging::InboundProcessor.new(adapter: adapter).process(payload)

      if result[:ok]
        render plain: "ok", status: :ok
      else
        Rails.logger.warn("[SMS webhook] #{result[:error]}")
        render plain: "accepted", status: :ok
      end
    end

    private

    def signature_params
      params.to_unsafe_h.except("controller", "action")
    end
  end
end
