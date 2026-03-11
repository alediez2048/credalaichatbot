# frozen_string_literal: true

module Observability
  # P0-005: Wraps LLM calls and sends trace + generation to Langfuse when configured.
  # No-op when LANGFUSE_SECRET_KEY is blank (no exception, no network).
  class Tracer
    class << self
      def enabled?
        ENV["LANGFUSE_SECRET_KEY"].to_s.strip.present?
      end

      # Yields to the block (which should call OpenAI and return the response hash).
      # When tracing is enabled: creates a trace, a generation, records usage/latency/tool_calls, then returns the block result.
      # @param session_id [String, Integer, nil] OnboardingSession ID when available
      # @param user_id [String, Integer, nil] User ID when available
      # @param model [String] Model name (e.g. gpt-4o)
      # @param messages [Array] Input messages (for trace input)
      # @return [Hash] whatever the block returns (OpenAI response hash)
      def trace_llm_call(session_id: nil, user_id: nil, model:, messages:)
        unless enabled?
          return yield
        end

        require "langfuse" unless defined?(Langfuse)

        trace = Langfuse.trace(
          name: "llm-chat",
          session_id: session_id&.to_s,
          user_id: user_id&.to_s,
          metadata: { model: model }
        )

        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        generation = Langfuse.generation(
          name: "openai-chat-completion",
          trace_id: trace.id,
          model: model,
          input: messages
        )

        begin
          response = yield
          duration_sec = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

          generation.end_time = Time.now.utc
          generation.output = extract_message_output(response)
          generation.metadata = {
            latency_seconds: duration_sec.round(3),
            tool_calls: extract_tool_calls(response)
          }

          if (usage = extract_usage(response))
            prompt_tokens = usage["prompt_tokens"] || usage[:prompt_tokens] || usage["input_tokens"] || usage[:input_tokens]
            completion_tokens = usage["completion_tokens"] || usage[:completion_tokens] || usage["output_tokens"] || usage[:output_tokens]
            total_tokens = usage["total_tokens"] || usage[:total_tokens]
            total_tokens ||= (prompt_tokens.to_i + completion_tokens.to_i) if prompt_tokens || completion_tokens
            generation.usage = Langfuse::Models::Usage.new(
              prompt_tokens: prompt_tokens,
              completion_tokens: completion_tokens,
              total_tokens: total_tokens
            )
          end

          Langfuse.update_generation(generation)
          response
        rescue StandardError => e
          generation.end_time = Time.now.utc
          generation.status_message = e.message
          generation.metadata = (generation.metadata || {}).merge(error: e.class.name)
          Langfuse.update_generation(generation)
          raise
        end
      end

      private

      def extract_usage(response)
        return nil unless response.is_a?(Hash)
        usage = response["usage"] || response[:usage]
        return usage if usage.is_a?(Hash)
        nil
      end

      def extract_message_output(response)
        return nil unless response.is_a?(Hash)
        choices = response["choices"] || response[:choices]
        msg = choices.is_a?(Array) && choices.first ? choices.first["message"] || choices.first[:message] : nil
        return nil unless msg.is_a?(Hash)
        msg["content"] || msg[:content] || (msg["tool_calls"] || msg[:tool_calls]) && "tool_calls"
      end

      def extract_tool_calls(response)
        return nil unless response.is_a?(Hash)
        choices = response["choices"] || response[:choices]
        msg = choices.is_a?(Array) && choices.first ? choices.first["message"] || choices.first[:message] : nil
        return nil unless msg.is_a?(Hash)
        raw = msg["tool_calls"] || msg[:tool_calls]
        return nil unless raw.is_a?(Array)
        raw.map { |tc| (tc["function"] || tc[:function])&.dig("name") || (tc["function"] || tc[:function])&.dig(:name) }.compact
      end
    end
  end
end
