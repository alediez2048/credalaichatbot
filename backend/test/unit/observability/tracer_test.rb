# frozen_string_literal: true

require "test_helper"

module Observability
  class TracerTest < ActiveSupport::TestCase
    test "enabled? is false when LANGSMITH_API_KEY is blank" do
      with_env "LANGSMITH_API_KEY" => nil do
        assert_not Tracer.enabled?
      end
    end

    test "enabled? is true when LANGSMITH_API_KEY is set" do
      with_env "LANGSMITH_API_KEY" => "lsv2_pt_test123" do
        assert Tracer.enabled?
      end
    end

    test "trace_llm_call yields and returns block result when tracing disabled" do
      with_env "LANGSMITH_API_KEY" => nil do
        result = Tracer.trace_llm_call(model: "gpt-4o", messages: []) { { "choices" => [] } }
        assert_equal({ "choices" => [] }, result)
      end
    end

    test "trace_llm_call accepts session_id and user_id" do
      with_env "LANGSMITH_API_KEY" => nil do
        result = Tracer.trace_llm_call(
          session_id: "sess-1",
          user_id: "user-1",
          model: "gpt-4o",
          messages: [{ role: "user", content: "Hi" }]
        ) { { "choices" => [] } }
        assert_equal({ "choices" => [] }, result)
      end
    end

    # --- P5-002: Enhanced metadata ---

    test "trace_llm_call accepts metadata hash with step and is_eval" do
      with_env "LANGSMITH_API_KEY" => nil do
        result = Tracer.trace_llm_call(
          session_id: "sess-1",
          user_id: "user-1",
          model: "gpt-4o",
          messages: [],
          metadata: { onboarding_step: "personal_info", is_eval: true, message_count: 5 }
        ) { { "choices" => [] } }
        assert_equal({ "choices" => [] }, result)
      end
    end

    test "trace_llm_call accepts parent_run_id for child runs" do
      with_env "LANGSMITH_API_KEY" => nil do
        result = Tracer.trace_llm_call(
          session_id: "sess-1",
          model: "gpt-4o",
          messages: [],
          parent_run_id: "parent-uuid-123"
        ) { { "choices" => [] } }
        assert_equal({ "choices" => [] }, result)
      end
    end

    test "trace_orchestrator_call creates parent run and yields run context" do
      with_env "LANGSMITH_API_KEY" => nil do
        ctx = nil
        result = Tracer.trace_orchestrator_call(
          session_id: "sess-1",
          user_id: "user-1",
          metadata: { onboarding_step: "welcome" }
        ) do |run_context|
          ctx = run_context
          "orchestrated"
        end
        assert_equal "orchestrated", result
        assert_not_nil ctx
        assert_respond_to ctx, :run_id
        assert_respond_to ctx, :add_child_run
      end
    end

    test "trace_orchestrator_call run_context tracks child runs" do
      with_env "LANGSMITH_API_KEY" => nil do
        Tracer.trace_orchestrator_call(
          session_id: "sess-1",
          user_id: "user-1",
          metadata: {}
        ) do |ctx|
          ctx.add_child_run(name: "tool:saveOnboardingProgress", run_type: "tool", duration_ms: 12)
          ctx.add_child_run(name: "llm-call", run_type: "llm", duration_ms: 450)
          assert_equal 2, ctx.child_runs.size
          assert_equal "tool:saveOnboardingProgress", ctx.child_runs.first[:name]
        end
      end
    end

    test "trace_llm_call with all enhanced params when tracing enabled posts without error" do
      with_env "LANGSMITH_API_KEY" => "lsv2_pt_test123", "LANGSMITH_PROJECT" => "test-project" do
        result = Tracer.trace_llm_call(
          session_id: "sess-1",
          user_id: "user-1",
          model: "gpt-4o",
          messages: [{ role: "user", content: "hello" }],
          metadata: { onboarding_step: "welcome", is_eval: false, message_count: 3 },
          parent_run_id: "parent-uuid-456"
        ) { { "choices" => [{ "message" => { "content" => "Hi!" } }], "usage" => { "total_tokens" => 10 } } }

        # Tracing posts asynchronously; the call should return the response unchanged
        assert_equal "Hi!", result.dig("choices", 0, "message", "content")
      end
    end

    test "trace_llm_call passes through with all new params when disabled" do
      with_env "LANGSMITH_API_KEY" => nil do
        result = Tracer.trace_llm_call(
          session_id: "sess-42",
          user_id: "user-1",
          model: "gpt-4o",
          messages: [],
          metadata: { onboarding_step: "welcome", is_eval: true },
          parent_run_id: "parent-uuid"
        ) { { "choices" => [{ "message" => { "content" => "ok" } }] } }

        assert_equal "ok", result.dig("choices", 0, "message", "content")
      end
    end

    private

    def with_env(env_vars)
      old = env_vars.keys.to_h { |k| [k, ENV[k]] }
      env_vars.each { |k, v| ENV[k] = v&.to_s }
      yield
    ensure
      old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    end
  end
end
