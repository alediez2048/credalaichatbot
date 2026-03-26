# frozen_string_literal: true

require "net/http"
require "json"
require "securerandom"

module Observability
  # P0-005: Wraps LLM calls and sends trace runs to LangSmith when configured.
  # P5-002: Enhanced with metadata, parent/child run hierarchy, and orchestrator tracing.
  # No-op when LANGSMITH_API_KEY is blank (no exception, no network).
  class Tracer
    LANGSMITH_ENDPOINT = "https://api.smith.langchain.com"

    # Lightweight context object yielded by trace_orchestrator_call to track child runs.
    RunContext = Struct.new(:run_id, :child_runs, keyword_init: true) do
      def add_child_run(name:, run_type: "chain", duration_ms: nil, metadata: {})
        child_runs << { name: name, run_type: run_type, duration_ms: duration_ms, metadata: metadata }
      end
    end

    class << self
      def enabled?
        ENV["LANGSMITH_API_KEY"].to_s.strip.present?
      end

      # Wraps an orchestrator turn as a parent run. Yields a RunContext for tracking child runs.
      # @param session_id [String, Integer, nil]
      # @param user_id [String, Integer, nil]
      # @param metadata [Hash] onboarding_step, message_count, is_eval, etc.
      # @return whatever the block returns
      def trace_orchestrator_call(session_id: nil, user_id: nil, metadata: {})
        run_id = SecureRandom.uuid
        ctx = RunContext.new(run_id: run_id, child_runs: [])

        unless enabled?
          return yield(ctx)
        end

        start_time = Time.now.utc.iso8601(6)
        start_mono = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          result = yield(ctx)
          end_time = Time.now.utc.iso8601(6)
          duration_sec = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_mono

          post_run(
            run_id: run_id,
            name: "orchestrator.process",
            run_type: "chain",
            start_time: start_time,
            end_time: end_time,
            session_id: session_id,
            user_id: user_id,
            metadata: metadata,
            parent_run_id: nil,
            latency_seconds: duration_sec.round(3),
            inputs: { session_id: session_id&.to_s, step: metadata[:onboarding_step] },
            outputs: { child_runs: ctx.child_runs.map { |c| c[:name] } },
            error: nil
          )

          # Post child runs
          ctx.child_runs.each do |child|
            post_run(
              run_id: SecureRandom.uuid,
              name: child[:name],
              run_type: child[:run_type],
              start_time: start_time,
              end_time: end_time,
              session_id: session_id,
              user_id: user_id,
              metadata: metadata.merge(child[:metadata] || {}),
              parent_run_id: run_id,
              latency_seconds: child[:duration_ms] ? (child[:duration_ms] / 1000.0).round(3) : nil,
              inputs: {},
              outputs: {},
              error: nil
            )
          end

          result
        rescue StandardError => e
          end_time = Time.now.utc.iso8601(6)
          post_run(
            run_id: run_id,
            name: "orchestrator.process",
            run_type: "chain",
            start_time: start_time,
            end_time: end_time,
            session_id: session_id,
            user_id: user_id,
            metadata: metadata,
            parent_run_id: nil,
            latency_seconds: nil,
            inputs: { session_id: session_id&.to_s },
            outputs: nil,
            error: "#{e.class}: #{e.message}"
          )
          raise
        end
      end

      # Wraps an LLM call. When tracing is enabled, posts a run to LangSmith.
      # @param session_id [String, Integer, nil] OnboardingSession ID
      # @param user_id [String, Integer, nil] User ID
      # @param model [String] Model name (e.g. gpt-4o)
      # @param messages [Array] Input messages
      # @param metadata [Hash] Additional metadata (onboarding_step, is_eval, message_count, etc.)
      # @param parent_run_id [String, nil] Parent run UUID for hierarchy
      # @return [Hash] whatever the block returns (OpenAI response hash)
      def trace_llm_call(session_id: nil, user_id: nil, model:, messages:, metadata: {}, parent_run_id: nil)
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
            name: "openai-chat-completion",
            run_type: "llm",
            start_time: start_time,
            end_time: end_time,
            session_id: session_id,
            user_id: user_id,
            metadata: metadata.merge(
              model: model,
              latency_seconds: duration_sec.round(3),
              token_usage: extract_usage(response)
            ),
            parent_run_id: parent_run_id,
            latency_seconds: duration_sec.round(3),
            inputs: { messages: messages, model: model },
            outputs: { output: extract_message_output(response), tool_calls: extract_tool_calls(response) },
            error: nil
          )

          response
        rescue StandardError => e
          end_time = Time.now.utc.iso8601(6)

          post_run(
            run_id: run_id,
            name: "openai-chat-completion",
            run_type: "llm",
            start_time: start_time,
            end_time: end_time,
            session_id: session_id,
            user_id: user_id,
            metadata: metadata.merge(model: model),
            parent_run_id: parent_run_id,
            latency_seconds: nil,
            inputs: { messages: messages, model: model },
            outputs: nil,
            error: "#{e.class}: #{e.message}"
          )

          raise
        end
      end

      private

      def post_run(run_id:, name:, run_type:, start_time:, end_time:, session_id:, user_id:, metadata:, parent_run_id:, latency_seconds:, inputs:, outputs:, error:)
        project = ENV.fetch("LANGSMITH_PROJECT", "default")
        endpoint = ENV.fetch("LANGSMITH_ENDPOINT", LANGSMITH_ENDPOINT)

        body = {
          id: run_id,
          name: name,
          run_type: run_type,
          start_time: start_time,
          end_time: end_time,
          inputs: inputs,
          outputs: outputs,
          extra: {
            metadata: {
              session_id: session_id&.to_s,
              user_id: user_id&.to_s,
              latency_seconds: latency_seconds
            }.merge(metadata || {})
          },
          session_name: session_id&.to_s,
          parent_run_id: parent_run_id,
          error: error
        }

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
