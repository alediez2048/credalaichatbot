# frozen_string_literal: true

require "openai"

module LLM
  class ChatService
    def initialize(openai_client: nil, tool_definitions: nil)
      @client = openai_client || build_client
      @tool_definitions = tool_definitions || load_tool_definitions
    end

    # @param messages [Array<Hash>] OpenAI format [{ role:, content: }, ...]
    # @param session_id [String, Integer, nil] OnboardingSession ID for tracing (P0-005)
    # @param user_id [String, Integer, nil] User ID for tracing when available
    # @return [Hash] raw API response; check response.dig("choices", 0, "message", "tool_calls") for tool calls
    def chat(messages:, session_id: nil, user_id: nil)
      if @client.nil?
        return { "choices" => [], "error" => "OPENAI_API_KEY not set" }
      end

      model = ENV.fetch("OPENAI_MODEL", "gpt-4o")
      params = {
        model: model,
        messages: messages,
        tools: @tool_definitions
      }

      Observability::Tracer.trace_llm_call(
        session_id: session_id,
        user_id: user_id,
        model: model,
        messages: messages
      ) do
        response = @client.chat.completions.create(params)
        to_response_hash(response)
      end
    end

    def tool_definitions
      @tool_definitions
    end

    private

    def build_client
      api_key = ENV["OPENAI_API_KEY"].presence
      return nil if api_key.blank?

      OpenAI::Client.new(api_key: api_key)
    end

    def load_tool_definitions
      validator = Tools::SchemaValidator.new
      validator.definitions_for_openai
    end

    def to_response_hash(response)
      return response if response.is_a?(Hash) && response.key?("choices")
      h = response.respond_to?(:to_h) ? response.to_h : response
      h.deep_transform_keys(&:to_s)
    end
  end
end
