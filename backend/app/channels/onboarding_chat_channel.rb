# frozen_string_literal: true

class OnboardingChatChannel < ApplicationCable::Channel
  def subscribed
    session_id = params[:session_id]
    reject && return if session_id.blank?

    @onboarding_session = OnboardingSession.find_by(id: session_id)
    reject && return unless @onboarding_session

    stream_for @onboarding_session
  end

  def unsubscribed
    stop_all_streams
  end

  def send_message(data)
    body = data["body"].to_s.strip
    return if body.blank?

    @onboarding_session.messages.create!(role: "user", content: body)
    broadcast_to @onboarding_session, { type: "start" }

    orchestrator = Onboarding::Orchestrator.new(@onboarding_session)
    result = orchestrator.process(body)

    if result[:error]
      broadcast_to @onboarding_session, {
        type: "error",
        message: result[:content],
        retryable: result[:error][:retryable],
        category: result[:error][:category]
      }
    else
      assistant_message = @onboarding_session.messages.create!(role: "assistant", content: result[:content])
      broadcast_to @onboarding_session, {
        type: "done",
        id: assistant_message.id,
        content: result[:content],
        current_step: @onboarding_session.reload.current_step,
        progress_percent: @onboarding_session.progress_percent
      }
    end
  rescue StandardError => e
    error_info = Onboarding::ErrorHandler.handle(e)
    Rails.logger.error "[OnboardingChatChannel] #{error_info[:logged_message]}"
    broadcast_to @onboarding_session, {
      type: "error",
      message: error_info[:user_message],
      retryable: error_info[:retryable],
      category: error_info[:category]
    }
  end
end
