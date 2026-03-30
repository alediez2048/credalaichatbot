# frozen_string_literal: true

module Api
  class OnboardingSmsSettingsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def update
      session_record = OnboardingSession.find_by(id: params[:onboarding_session_id])
      unless session_record && authorized_session?(session_record)
        render json: { error: "Not found" }, status: :not_found
        return
      end

      phone = Messaging::PhoneNumber.normalize(params[:phone_number])
      opt_in = ActiveModel::Type::Boolean.new.cast(params[:sms_opt_in])

      session_record.phone_number = phone if params.key?(:phone_number)
      session_record.sms_opt_in = opt_in if params.key?(:sms_opt_in)

      if session_record.save
        render json: {
          phone_number: session_record.phone_number,
          sms_opt_in: session_record.sms_opt_in,
          sms_ready: session_record.sms_opted_in?
        }, status: :ok
      else
        render json: { errors: session_record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def handoff
      session_record = OnboardingSession.find_by(id: params[:onboarding_session_id])
      unless session_record && authorized_session?(session_record)
        render json: { error: "Not found" }, status: :not_found
        return
      end

      unless session_record.sms_opted_in?
        render json: { error: "Add a phone number and opt in to SMS to continue via text." }, status: :unprocessable_entity
        return
      end

      if Onboarding::Resumption.completed?(session_record)
        render json: { error: "Onboarding is already complete." }, status: :unprocessable_entity
        return
      end

      default_url = Rails.application.routes.url_helpers.onboarding_url(
        host: request.host_with_port,
        protocol: request.scheme
      )
      body = params[:message].presence || <<~TEXT.squish
        Credal onboarding: pick up where you left off. Open: #{default_url}
        Reply here to continue by text. Reply STOP to opt out.
      TEXT

      adapter = Messaging::Factory.build
      send_result = adapter.send_message(to: session_record.phone_number, text: body)

      SmsEvent.create!(
        onboarding_session: session_record,
        provider: send_result[:provider] || ENV.fetch("SMS_PROVIDER", "mock"),
        direction: "outbound",
        external_id: send_result[:external_id],
        phone_number: session_record.phone_number,
        body: body,
        status: send_result[:success] ? "sent" : "failed",
        error_message: send_result[:error],
        metadata: send_result.except(:success, :error, :external_id, :provider)
      )

      if send_result[:success]
        session_record.update!(last_channel: "web", last_interaction_at: Time.current)
        render json: { ok: true, external_id: send_result[:external_id] }, status: :created
      else
        render json: { ok: false, error: send_result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def authorized_session?(session_record)
      if current_user
        session_record.user_id == current_user.id
      else
        session_record.id == session[:onboarding_session_id].to_i
      end
    end
  end
end
