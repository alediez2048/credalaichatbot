# frozen_string_literal: true

module Onboarding
  # Single entry point for web + SMS turns: lock session, persist messages with channel metadata, format output.
  class TurnProcessor
    # @param channel [Symbol] :web | :sms | :openclaw
    # @param provider_message_id [String, nil] external id from SMS provider (e.g. Twilio MessageSid)
    # @param inbound_event_id [Integer, nil] SmsEvent id when applicable
    # @return [Hash] success: { content:, assistant_message:, step_changed:, error: nil } or error: { content:, error:, assistant_message: }
    def self.process(session:, body:, channel:, provider_message_id: nil, inbound_event_id: nil)
      new(session: session, body: body, channel: channel, provider_message_id: provider_message_id, inbound_event_id: inbound_event_id).process
    end

    def initialize(session:, body:, channel:, provider_message_id:, inbound_event_id:)
      @session = session
      @body = body.to_s.strip
      @channel = channel.to_sym
      @provider_message_id = provider_message_id
      @inbound_event_id = inbound_event_id
    end

    def process
      raise ArgumentError, "body is blank" if @body.blank?

      @session.with_lock do
        @session.reload
        previous_channel = @session.last_channel.to_s
        resume_from_web = previous_channel == "web" && [:sms, :openclaw].include?(@channel)
        resume_from_sms = %w[sms openclaw].include?(previous_channel) && @channel == :web

        user_meta = {
          channel: @channel.to_s,
          last_channel_before: previous_channel
        }
        user_meta[:provider_message_id] = @provider_message_id if @provider_message_id.present?
        user_meta[:inbound_event_id] = @inbound_event_id if @inbound_event_id.present?

        @session.messages.create!(role: "user", content: @body, metadata: user_meta)

        step_at_turn_start = @session.current_step
        result = Onboarding::Orchestrator.new(@session).process(@body)

        if result[:error]
          text = Onboarding::ChannelFormatter.format_error(result[:content], channel: @channel)
          assistant = @session.messages.create!(
            role: "assistant",
            content: text,
            metadata: { channel: @channel.to_s, error: true, category: result[:error][:category].to_s }
          )
          touch_session_channel!
          {
            error: result[:error],
            content: text,
            assistant_message: assistant,
            step_changed: false
          }
        else
          raw = result[:content].to_s
          text = Onboarding::ChannelFormatter.format_assistant(
            raw,
            channel: @channel,
            session: @session.reload,
            resume_from_web: resume_from_web,
            resume_from_sms: resume_from_sms,
            resume_step: step_at_turn_start
          )
          assistant = @session.messages.create!(
            role: "assistant",
            content: text,
            metadata: {
              channel: @channel.to_s,
              orchestrator_raw_chars: raw.length
            }
          )
          touch_session_channel!
          {
            error: nil,
            content: text,
            assistant_message: assistant,
            step_changed: result[:step_changed]
          }
        end
      end
    end

    private

    def touch_session_channel!
      @session.update!(last_channel: @channel.to_s, last_interaction_at: Time.current)
    end
  end
end
