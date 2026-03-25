# frozen_string_literal: true

module Onboarding
  class Orchestrator
    STEPS_PATH = Rails.root.join("config/prompts/onboarding_steps.yml")
    STEPS = YAML.load_file(STEPS_PATH)["steps"].freeze
    STEP_NAMES = STEPS.map { |s| s["name"] }.freeze
    MAX_TOOL_ITERATIONS = 3

    def initialize(session, chat_service: nil)
      @session = session
      @chat_service = chat_service || LLM::ChatService.new
      @router = Tools::Router.new
      ensure_current_step
    end

    # @param user_message [String]
    # @return [Hash] { content: String, step_changed: Boolean }
    def process(user_message)
      step_before = @session.current_step
      step_def = current_step_definition

      messages = build_messages(step_def, user_message)
      tools = tools_for_step(step_def)

      # LLM call + tool call loop
      response = call_llm(messages, tools)
      iterations = 0

      while has_tool_calls?(response) && iterations < MAX_TOOL_ITERATIONS
        tool_results = execute_tool_calls(response)
        messages += assistant_message_from(response) + tool_results
        response = call_llm(messages, tools)
        iterations += 1
      end

      content = extract_content(response)
      content = "I'm here to help with your onboarding. What can I assist you with?" if content.blank?

      maybe_advance_step(step_def)
      update_progress

      { content: content, step_changed: @session.current_step != step_before }
    end

    private

    def ensure_current_step
      return if @session.current_step.present?
      @session.update!(current_step: "welcome")
    end

    def current_step_definition
      STEPS.find { |s| s["name"] == @session.current_step } || STEPS.first
    end

    def build_messages(step_def, user_message)
      system_prompt = build_system_prompt(step_def)
      history = @session.messages.order(:created_at).map { |m| { role: m.role, content: m.content.to_s } }
      LLM::ContextBuilder.build(system_prompt: system_prompt, history: history, current_message: user_message)
    end

    def build_system_prompt(step_def)
      collected = @session.metadata.presence || {}
      collected_text = collected.any? ? collected.map { |k, v| "- #{k}: #{v}" }.join("\n") : "No data collected yet."

      <<~PROMPT
        You are Credal's AI onboarding assistant. You guide new employees through the onboarding process step by step.

        ## Current Step: #{step_def['name']}
        #{step_def['prompt_instructions']}

        ## Data Collected So Far
        #{collected_text}

        ## Rules
        - Stay focused on the current step. Do not skip ahead or go back.
        - Be conversational, warm, and professional.
        - Collect information one piece at a time — don't overwhelm the user.
        - When you have the information needed, use the appropriate tool to save it.
        - If a feature is coming soon, acknowledge it gracefully and move forward.
        - Keep responses concise — 2-3 sentences unless more detail is needed.
      PROMPT
    end

    def tools_for_step(step_def)
      tool_names = step_def["tools"] || []
      return nil if tool_names.empty?

      all_defs = @chat_service.tool_definitions
      all_defs.select { |t| tool_names.include?(t.dig(:function, :name) || t.dig("function", "name")) }
    end

    def call_llm(messages, tools)
      params = { messages: messages, session_id: @session.id, user_id: @session.user_id }
      params[:tools] = tools if tools.present?
      @chat_service.chat(**params)
    end

    def has_tool_calls?(response)
      tool_calls = response.dig("choices", 0, "message", "tool_calls")
      tool_calls.is_a?(Array) && tool_calls.any?
    end

    def execute_tool_calls(response)
      tool_calls = response.dig("choices", 0, "message", "tool_calls") || []
      tool_calls.map do |tc|
        function = tc["function"] || tc[:function] || {}
        name = function["name"] || function[:name]
        args = function["arguments"] || function[:arguments] || "{}"
        args = JSON.parse(args) if args.is_a?(String)

        result = @router.call(name, args, context: { session: @session })
        {
          role: "tool",
          tool_call_id: tc["id"] || tc[:id],
          content: result.to_json
        }
      end
    end

    def assistant_message_from(response)
      msg = response.dig("choices", 0, "message")
      return [] unless msg
      [{ role: "assistant", content: msg["content"], tool_calls: msg["tool_calls"] }.compact]
    end

    def extract_content(response)
      response.dig("choices", 0, "message", "content").to_s.strip
    end

    def maybe_advance_step(step_def)
      return if step_def["next_step"].blank?

      if step_def["required_fields"].nil? || step_def["required_fields"].empty?
        advance_to(step_def["next_step"])
      elsif all_required_fields_collected?(step_def)
        advance_to(step_def["next_step"])
      end
    end

    def all_required_fields_collected?(step_def)
      required = step_def["required_fields"] || []
      collected = @session.reload.metadata || {}
      required.all? { |field| collected[field].present? }
    end

    def advance_to(next_step)
      @session.update!(current_step: next_step)
    end

    def update_progress
      idx = STEP_NAMES.index(@session.current_step) || 0
      progress = ((idx + 1).to_f / STEP_NAMES.size * 100).round
      @session.update!(progress_percent: progress)
    end
  end
end
