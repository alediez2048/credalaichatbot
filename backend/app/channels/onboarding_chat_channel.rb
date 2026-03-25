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

    # Persist user message (client shows it optimistically)
    user_message = @onboarding_session.messages.create!(role: "user", content: body)

    # Build context and stream assistant reply
    history = @onboarding_session.messages.where.not(id: user_message.id).order(:created_at).map { |m| { role: m.role, content: m.content.to_s } }
    system_prompt = "You are a helpful onboarding assistant. Guide the user through the process conversationally."
    messages = LLM::ContextBuilder.build(system_prompt: system_prompt, history: history, current_message: body)

    broadcast_to @onboarding_session, { type: "start" }

    full_content = +""
    chat_service = LLM::ChatService.new
    chat_service.stream_chat(
      messages: messages,
      session_id: @onboarding_session.id,
      user_id: @onboarding_session.user_id
    ) do |token|
      full_content << token
      broadcast_to @onboarding_session, { type: "token", content: token }
    end

    assistant_message = @onboarding_session.messages.create!(role: "assistant", content: full_content)
    broadcast_to @onboarding_session, { type: "done", id: assistant_message.id, content: full_content }
  rescue StandardError => e
    Rails.logger.error "[OnboardingChatChannel] #{e.class}: #{e.message}"
    broadcast_to @onboarding_session, { type: "error", message: "Something went wrong. Please try again." }
  end
end
