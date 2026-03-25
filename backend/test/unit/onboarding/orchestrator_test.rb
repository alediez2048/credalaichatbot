# frozen_string_literal: true

require "test_helper"

module Onboarding
  class OrchestratorTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(status: "active", current_step: nil, metadata: {})
    end

    # --- Step definitions ---

    test "loads step definitions from YAML" do
      steps = Onboarding::Orchestrator::STEPS
      assert_equal 6, steps.size
      assert_equal "welcome", steps.first["name"]
      assert_equal "complete", steps.last["name"]
    end

    test "each step has required keys" do
      Onboarding::Orchestrator::STEPS.each do |step|
        assert step["name"].present?, "Step missing name"
        assert step.key?("required_fields"), "Step #{step['name']} missing required_fields"
        assert step.key?("prompt_instructions"), "Step #{step['name']} missing prompt_instructions"
        assert step.key?("next_step"), "Step #{step['name']} missing next_step"
      end
    end

    test "personal_info step has required fields" do
      step = Onboarding::Orchestrator::STEPS.find { |s| s["name"] == "personal_info" }
      assert_includes step["required_fields"], "full_name"
      assert_includes step["required_fields"], "email"
      assert_includes step["required_fields"], "phone"
      assert_includes step["required_fields"], "date_of_birth"
    end

    # --- Initialization ---

    test "sets current_step to welcome when nil" do
      mock = MockChatService.new(text_response("Hello! Welcome to onboarding."))
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      orchestrator.process("Hi")
      @session.reload
      # Welcome has no required fields — advancement is deferred to next turn
      assert_equal "welcome", @session.current_step
      assert_equal "personal_info", @session.metadata["_pending_advance"]
    end

    # --- Process returns content ---

    test "process returns assistant content from LLM" do
      @session.update!(current_step: "welcome")
      mock = MockChatService.new(text_response("Welcome! Let me guide you."))
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      result = orchestrator.process("Hello")
      assert_equal "Welcome! Let me guide you.", result[:content]
    end

    # --- Step advancement ---

    test "deferred advancement: welcome advances to personal_info on next turn" do
      @session.update!(current_step: "welcome")
      mock = MockChatService.new(text_response("Great!"), text_response("What's your name?"))
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      # First turn: welcome response, deferred advance
      orchestrator.process("Yes, I'm ready")
      @session.reload
      assert_equal "welcome", @session.current_step
      assert_equal "personal_info", @session.metadata["_pending_advance"]

      # Second turn: advance happens, now on personal_info
      orchestrator.process("Let's go")
      @session.reload
      assert_equal "personal_info", @session.current_step
      assert_nil @session.metadata["_pending_advance"]
    end

    test "does not advance personal_info until all fields collected" do
      @session.update!(current_step: "personal_info", metadata: { "full_name" => "Jane Doe" })
      mock = MockChatService.new(text_response("Great, what's your email?"))
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      orchestrator.process("My name is Jane Doe")
      @session.reload
      assert_equal "personal_info", @session.current_step
    end

    test "advances personal_info when all required fields present" do
      @session.update!(
        current_step: "personal_info",
        metadata: {
          "full_name" => "Jane Doe",
          "email" => "jane@example.com",
          "phone" => "555-1234",
          "date_of_birth" => "1990-01-15"
        }
      )
      mock = MockChatService.new(text_response("All set! Let's move on."))
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      orchestrator.process("That's everything")
      @session.reload
      assert_equal "document_upload", @session.current_step
    end

    test "deferred advancement through stub steps (document_upload → scheduling)" do
      @session.update!(current_step: "document_upload")
      mock = MockChatService.new(text_response("Document upload is coming soon!"), text_response("Scheduling is coming soon!"))
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      # First turn: deferred advance
      orchestrator.process("ok")
      @session.reload
      assert_equal "document_upload", @session.current_step
      assert_equal "scheduling", @session.metadata["_pending_advance"]

      # Second turn: advances to scheduling
      orchestrator.process("ok")
      @session.reload
      assert_equal "scheduling", @session.current_step
    end

    test "does not advance past complete" do
      @session.update!(current_step: "complete", metadata: {})
      mock = MockChatService.new(text_response("You're all done!"))
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      orchestrator.process("thanks")
      @session.reload
      assert_equal "complete", @session.current_step
      assert_nil @session.metadata["_pending_advance"]
    end

    # --- Progress tracking ---

    test "updates progress_percent correctly" do
      # personal_info is index 1 out of 5 max = 20%
      @session.update!(current_step: "personal_info", progress_percent: 0, metadata: {})
      mock = MockChatService.new(text_response("What's your name?"))
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      orchestrator.process("hi")
      @session.reload
      assert_equal 20, @session.progress_percent
    end

    test "progress is 0 at welcome and 100 at complete" do
      assert_equal 0, calc_progress("welcome")
      assert_equal 100, calc_progress("complete")
    end

    # --- Tool call handling ---

    test "executes tool calls and re-calls LLM" do
      @session.update!(current_step: "personal_info", metadata: {})

      tool_resp = tool_call_response("saveOnboardingProgress", {
        "userId" => @session.id.to_s,
        "step" => "personal_info",
        "data" => { "full_name" => "Jane Doe" }
      })
      final_resp = text_response("Got it, Jane! What's your email?")
      mock = MockChatService.new(tool_resp, final_resp)
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      result = orchestrator.process("My name is Jane Doe")
      assert_equal "Got it, Jane! What's your email?", result[:content]

      @session.reload
      assert_equal "Jane Doe", @session.metadata["full_name"]
    end

    test "respects max tool call iterations" do
      @session.update!(current_step: "personal_info", metadata: {})

      # Always returns tool calls — infinite loop scenario
      looping = tool_call_response("getOnboardingState", { "userId" => "1" })
      mock = MockChatService.new(*Array.new(5, looping))
      orchestrator = Onboarding::Orchestrator.new(@session, chat_service: mock)

      result = orchestrator.process("hello")
      assert result[:content].present?
    end

    private

    def calc_progress(step_name)
      steps = Onboarding::Orchestrator::STEP_NAMES
      idx = steps.index(step_name) || 0
      max = steps.size - 1
      max > 0 ? (idx.to_f / max * 100).round : 0
    end

    def text_response(content)
      {
        "choices" => [
          { "message" => { "role" => "assistant", "content" => content, "tool_calls" => nil } }
        ]
      }
    end

    def tool_call_response(tool_name, arguments)
      {
        "choices" => [
          {
            "message" => {
              "role" => "assistant",
              "content" => nil,
              "tool_calls" => [
                {
                  "id" => "call_#{SecureRandom.hex(4)}",
                  "type" => "function",
                  "function" => {
                    "name" => tool_name,
                    "arguments" => arguments.to_json
                  }
                }
              ]
            }
          }
        ]
      }
    end

    # Simple mock that returns responses in sequence
    class MockChatService
      def initialize(*responses)
        @responses = responses.flatten
        @call_index = 0
      end

      def chat(**_args)
        resp = @responses[@call_index] || @responses.last
        @call_index += 1
        resp
      end

      def tool_definitions
        Tools::SchemaValidator.new.definitions_for_openai
      end
    end
  end
end
