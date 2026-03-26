# frozen_string_literal: true

require "test_helper"

class LLMToolCallingIntegrationTest < ActiveSupport::TestCase
  # Full path: ChatService → optional tool_calls in response → Router → result.
  # Without OPENAI_API_KEY we only test the pipe with a mock or skip.
  test "tool definitions load from YAML and have 11 tools" do
    validator = Tools::SchemaValidator.new
    assert_equal 11, validator.tool_names.size
    assert_includes validator.tool_names, "getOnboardingState"
    defs = validator.definitions_for_openai
    assert_equal 11, defs.size
    assert defs.all? { |d| d[:type] == "function" && d[:function][:name].present? }
  end

  test "send message through ContextBuilder and ChatService returns response shape" do
    messages = LLM::ContextBuilder.build(
      system_prompt: "You are an onboarding assistant. When asked for state, use getOnboardingState.",
      history: [],
      current_message: "What is my current onboarding state? My user id is test-123."
    )
    assert messages.size >= 2
    assert_equal "user", messages.last[:role]

    # Use stub so test never hits the network (OPENAI_API_KEY may be set in .env).
    stub_completions = Object.new
    stub_completions.define_singleton_method(:create) { |_params| { choices: [] } }
    stub_chat = Object.new
    stub_chat.define_singleton_method(:completions) { stub_completions }
    stub_client = Object.new
    stub_client.define_singleton_method(:chat) { stub_chat }
    service = LLM::ChatService.new(openai_client: stub_client)
    response = service.chat(messages: messages)
    assert response.is_a?(Hash)
    assert response.key?("choices")
  end

  test "full path with stub client: tool_call in response → Router → result" do
    messages = LLM::ContextBuilder.build(
      system_prompt: "Use getOnboardingState when asked for state.",
      history: [],
      current_message: "What is my onboarding state? userId is test-456."
    )
    stub_response = {
      choices: [
        {
          message: {
            role: "assistant",
            content: nil,
            tool_calls: [
              {
                id: "call_1",
                type: "function",
                function: {
                  name: "getOnboardingState",
                  arguments: { userId: "test-456" }.to_json
                }
              }
            ]
          }
        }
      ]
    }
    stub_completions = Object.new
    stub_completions.define_singleton_method(:create) { |_params| stub_response }
    stub_chat = Object.new
    stub_chat.define_singleton_method(:completions) { stub_completions }
    stub_client = Object.new
    stub_client.define_singleton_method(:chat) { stub_chat }

    service = LLM::ChatService.new(openai_client: stub_client)
    response = service.chat(messages: messages)
    assert response.is_a?(Hash)
    assert response.key?("choices")
    message = response.dig("choices", 0, "message")
    assert message, "expected message in response"
    assert message["tool_calls"].present?, "expected tool_calls in message"
    tool_call = message["tool_calls"].first
    assert_equal "getOnboardingState", tool_call["function"]["name"]
    args = JSON.parse(tool_call["function"]["arguments"].to_s)
    result = Tools::Router.new.call("getOnboardingState", args)
    assert result[:success], result.inspect
    assert result[:data].present?
  end

  test "full path: router executes getOnboardingState and returns result" do
    router = Tools::Router.new
    result = router.call("getOnboardingState", {})
    assert result[:success]
    assert result[:data].present?
  end
end
