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

    # Stream chat completion token-by-token. Yields each content delta; no tool_calls (streaming only).
    # @param messages [Array<Hash>] OpenAI format
    # @param session_id [String, Integer, nil] for tracing
    # @param user_id [String, Integer, nil] for tracing
    # @yield [String] content delta (token or chunk)
    def stream_chat(messages:, session_id: nil, user_id: nil, &block)
      return block.call("OPENAI_API_KEY not set. I can't respond right now.") if @client.nil?

      model = ENV.fetch("OPENAI_MODEL", "gpt-4o")
      params = { model: model, messages: messages }
      # Omit tools for streaming to get plain text stream; tool calling would need separate handling.
      stream = @client.chat.completions.stream_raw(params)

      stream.each do |chunk|
        content = extract_stream_content(chunk)
        block.call(content) if content.present?
      end
    end

    private

    def extract_stream_content(chunk)
      h = chunk.respond_to?(:to_h) ? chunk.to_h.deep_stringify_keys : (chunk.is_a?(Hash) ? chunk.deep_stringify_keys : {})
      h.dig("choices", 0, "delta", "content")
    end

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
