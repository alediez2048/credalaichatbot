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
        # Just ensure no error when optional args passed
        result = Tracer.trace_llm_call(
          session_id: "sess-1",
          user_id: "user-1",
          model: "gpt-4o",
          messages: [{ role: "user", content: "Hi" }]
        ) { { "choices" => [] } }
        assert_equal({ "choices" => [] }, result)
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
