# frozen_string_literal: true

require "net/http"
require "json"
require "securerandom"

module Observability
  # P0-005: Wraps LLM calls and sends trace runs to LangSmith when configured.
  # No-op when LANGSMITH_API_KEY is blank (no exception, no network).
  class Tracer
    LANGSMITH_ENDPOINT = "https://api.smith.langchain.com"

    class << self
      def enabled?
        ENV["LANGSMITH_API_KEY"].to_s.strip.present?
      end

      # Yields to the block (which should call OpenAI and return the response hash).
      # When tracing is enabled: creates a LangSmith run with inputs, outputs, usage, and latency.
      # @param session_id [String, Integer, nil] OnboardingSession ID when available
      # @param user_id [String, Integer, nil] User ID when available
      # @param model [String] Model name (e.g. gpt-4o)
      # @param messages [Array] Input messages (for trace input)
      # @return [Hash] whatever the block returns (OpenAI response hash)
      def trace_llm_call(session_id: nil, user_id: nil, model:, messages:)
        unless enabled?
          return yield
        end

        run_id = SecureRandom.uuid
        start_time = Time.now.utc.iso8601(6)
        start_mono = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          response = yield
          end_time = Time.now.utc.iso8601(6)
          duration_sec = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_mono

          post_run(
            run_id: run_id,
            start_time: start_time,
            end_time: end_time,
            model: model,
            messages: messages,
            session_id: session_id,
            user_id: user_id,
            output: extract_message_output(response),
            tool_calls: extract_tool_calls(response),
            usage: extract_usage(response),
            latency_seconds: duration_sec.round(3),
            error: nil
          )

          response
        rescue StandardError => e
          end_time = Time.now.utc.iso8601(6)

          post_run(
            run_id: run_id,
            start_time: start_time,
            end_time: end_time,
            model: model,
            messages: messages,
            session_id: session_id,
            user_id: user_id,
            output: nil,
            tool_calls: nil,
            usage: nil,
            latency_seconds: nil,
            error: "#{e.class}: #{e.message}"
          )

          raise
        end
      end

      private

      def post_run(run_id:, start_time:, end_time:, model:, messages:, session_id:, user_id:, output:, tool_calls:, usage:, latency_seconds:, error:)
        project = ENV.fetch("LANGSMITH_PROJECT", "default")
        endpoint = ENV.fetch("LANGSMITH_ENDPOINT", LANGSMITH_ENDPOINT)

        body = {
          id: run_id,
          name: "openai-chat-completion",
          run_type: "llm",
          start_time: start_time,
          end_time: end_time,
          inputs: { messages: messages, model: model },
          outputs: output ? { output: output, tool_calls: tool_calls } : nil,
          extra: {
            metadata: {
              model: model,
              session_id: session_id&.to_s,
              user_id: user_id&.to_s,
              latency_seconds: latency_seconds
            }
          },
          session_name: session_id&.to_s,
          error: error
        }

        if usage.is_a?(Hash)
          prompt_tokens = usage["prompt_tokens"] || usage[:prompt_tokens] || usage["input_tokens"] || usage[:input_tokens]
          completion_tokens = usage["completion_tokens"] || usage[:completion_tokens] || usage["output_tokens"] || usage[:output_tokens]
          total_tokens = usage["total_tokens"] || usage[:total_tokens]
          total_tokens ||= (prompt_tokens.to_i + completion_tokens.to_i) if prompt_tokens || completion_tokens

          body[:extra][:metadata][:token_usage] = {
            prompt_tokens: prompt_tokens,
            completion_tokens: completion_tokens,
            total_tokens: total_tokens
          }
        end

        Thread.new do
          uri = URI("#{endpoint}/runs")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == "https"
          http.open_timeout = 5
          http.read_timeout = 5

          req = Net::HTTP::Post.new(uri.path, {
            "Content-Type" => "application/json",
            "x-api-key" => ENV["LANGSMITH_API_KEY"].to_s.strip
          })
          req.body = body.compact.to_json

          http.request(req)
        rescue StandardError => e
          Rails.logger.warn("[LangSmith] Failed to post run: #{e.message}") if defined?(Rails)
        end
      end

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
