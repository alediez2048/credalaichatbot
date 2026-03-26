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
    # @return [Hash] { content: String, step_changed: Boolean, error: Hash|nil }
    # @param user_message [String]
    # @param is_eval [Boolean] tag trace as eval run (P5-002)
    # @return [Hash] { content: String, step_changed: Boolean, error: Hash|nil }
    def process(user_message, is_eval: false)
      # Advance pending step transitions from the previous turn before processing
      maybe_advance_pending_step

      step_before = @session.current_step
      step_def = current_step_definition

      trace_metadata = {
        onboarding_step: @session.current_step,
        message_count: @session.messages.count,
        is_eval: is_eval
      }

      Observability::Tracer.trace_orchestrator_call(
        session_id: @session.id,
        user_id: @session.user_id,
        metadata: trace_metadata
      ) do |run_context|
        messages = build_messages(step_def, user_message)
        tools = tools_for_step(step_def)

        # LLM call + tool call loop with error handling
        response = call_llm_with_retry(messages, tools, parent_run_id: run_context.run_id)
        iterations = 0

        while has_tool_calls?(response) && iterations < MAX_TOOL_ITERATIONS
          tool_results = execute_tool_calls_safe(response, run_context: run_context)
          messages += assistant_message_from(response) + tool_results
          response = call_llm_with_retry(messages, tools, parent_run_id: run_context.run_id)
          iterations += 1
        end

        content = extract_content(response)
        content = "I'm here to help with your onboarding. What can I assist you with?" if content.blank?

        mark_step_ready_to_advance(step_def)
        update_progress

        { content: content, step_changed: @session.current_step != step_before }
      end
    rescue => e
      error_info = Onboarding::ErrorHandler.handle(e)
      Rails.logger.error "[Orchestrator] #{error_info[:logged_message]}"
      { content: error_info[:user_message], step_changed: false, error: error_info }
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
      history = Onboarding::Resumption.build_history(@session)
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

        #{Sentiment::PromptAdapter.adapt_prompt(@session)}
      PROMPT
    end

    def tools_for_step(step_def)
      tool_names = step_def["tools"] || []
      return nil if tool_names.empty?

      all_defs = @chat_service.tool_definitions
      all_defs.select { |t| tool_names.include?(t.dig(:function, :name) || t.dig("function", "name")) }
    end

    def call_llm(messages, tools, parent_run_id: nil)
      params = { messages: messages, session_id: @session.id, user_id: @session.user_id }
      params[:tools] = tools if tools.present?
      params[:metadata] = { onboarding_step: @session.current_step }
      params[:parent_run_id] = parent_run_id
      Timeout.timeout(30) { @chat_service.chat(**params) }
    end

    def call_llm_with_retry(messages, tools, parent_run_id: nil, retries: 1)
      call_llm(messages, tools, parent_run_id: parent_run_id)
    rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
      if retries > 0
        Rails.logger.warn "[Orchestrator] LLM timeout, retrying (#{retries} left)"
        call_llm_with_retry(messages, tools, parent_run_id: parent_run_id, retries: retries - 1)
      else
        raise
      end
    end

    def has_tool_calls?(response)
      tool_calls = response.dig("choices", 0, "message", "tool_calls")
      tool_calls.is_a?(Array) && tool_calls.any?
    end

    def execute_tool_calls_safe(response, run_context: nil)
      execute_tool_calls(response, run_context: run_context)
    rescue => e
      Rails.logger.error "[Orchestrator] Tool call failed: #{e.class}: #{e.message}"
      [{ role: "tool", tool_call_id: "error", content: { success: false, error: "Tool execution failed. Please try again." }.to_json }]
    end

    def execute_tool_calls(response, run_context: nil)
      tool_calls = response.dig("choices", 0, "message", "tool_calls") || []
      tool_calls.map do |tc|
        function = tc["function"] || tc[:function] || {}
        name = function["name"] || function[:name]
        args = function["arguments"] || function[:arguments] || "{}"
        args = JSON.parse(args) if args.is_a?(String)

        start_mono = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = @router.call(name, args, context: { session: @session })
        duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_mono) * 1000).round

        run_context&.add_child_run(name: "tool:#{name}", run_type: "tool", duration_ms: duration_ms)

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

    # Check if a previous turn marked the step as ready to advance
    def maybe_advance_pending_step
      pending = @session.metadata&.dig("_pending_advance")
      return unless pending.present?

      meta = @session.metadata.except("_pending_advance")
      @session.update!(current_step: pending, metadata: meta)
    end

    # Mark the step as ready to advance — actual advancement happens at the start of the next turn
    # so the user sees the current step's response before moving on.
    # Exception: steps with required fields advance immediately when fields are complete
    # (the LLM has been collecting data and the user expects to move on).
    def mark_step_ready_to_advance(step_def)
      return if step_def["next_step"].blank?

      has_required = step_def["required_fields"].present? && step_def["required_fields"].any?

      if has_required && all_required_fields_collected?(step_def)
        # Immediate advance — user has been actively providing data
        advance_to(step_def["next_step"])
      elsif !has_required
        # Deferred advance — user should see this step's message first
        meta = (@session.metadata || {}).merge("_pending_advance" => step_def["next_step"])
        @session.update!(metadata: meta)
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
      max_idx = STEP_NAMES.size - 1
      progress = max_idx > 0 ? (idx.to_f / max_idx * 100).round : 0
      @session.update!(progress_percent: progress)
    end
  end
end
