# frozen_string_literal: true

require "test_helper"

module LLM
  class ContextBuilderTest < ActiveSupport::TestCase
    test "build includes system prompt" do
      messages = ContextBuilder.build(
        system_prompt: "You are a helper.",
        history: [],
        current_message: "Hi"
      )
      assert_equal "system", messages.first[:role]
      assert_equal "You are a helper.", messages.first[:content]
    end

    test "build includes history and current message" do
      messages = ContextBuilder.build(
        system_prompt: "",
        history: [{ role: "user", content: "Hello" }, { role: "assistant", content: "Hi there!" }],
        current_message: "Thanks"
      )
      assert_equal 3, messages.size
      assert_equal "user", messages[0][:role]
      assert_equal "Hello", messages[0][:content]
      assert_equal "assistant", messages[1][:role]
      assert_equal "Thanks", messages[2][:content]
    end

    test "build with empty current_message still adds user message if blank string" do
      messages = ContextBuilder.build(system_prompt: "Sys", history: [], current_message: "")
      assert_equal 1, messages.size
      assert_equal "system", messages.first[:role]
    end
  end
end
