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

    # Persist user message
    @onboarding_session.messages.create!(role: "user", content: body)

    broadcast_to @onboarding_session, { type: "start" }

    # Use orchestrator for step-aware, tool-calling responses
    orchestrator = Onboarding::Orchestrator.new(@onboarding_session)
    result = orchestrator.process(body)

    content = result[:content]
    assistant_message = @onboarding_session.messages.create!(role: "assistant", content: content)

    broadcast_to @onboarding_session, {
      type: "done",
      id: assistant_message.id,
      content: content,
      current_step: @onboarding_session.reload.current_step,
      progress_percent: @onboarding_session.progress_percent
    }
  rescue StandardError => e
    Rails.logger.error "[OnboardingChatChannel] #{e.class}: #{e.message}"
    broadcast_to @onboarding_session, { type: "error", message: "Something went wrong. Please try again." }
  end
end
