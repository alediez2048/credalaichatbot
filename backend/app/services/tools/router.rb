# frozen_string_literal: true

module Tools
  class Router
    def initialize(validator: nil)
      @validator = validator || SchemaValidator.new
      @handlers = build_stub_handlers
    end

    # @param tool_name [String]
    # @param arguments [Hash] tool call arguments (string keys from OpenAI)
    # @return [Hash] result to send back to the LLM (e.g. { success: true, data: ... })
    def call(tool_name, arguments)
      args = arguments.is_a?(String) ? parse_arguments(arguments) : (arguments || {}).stringify_keys
      result = @validator.validate(tool_name, args)
      unless result[:valid]
        return { success: false, error: result[:errors].join("; ") }
      end

      handler = @handlers[tool_name.to_s]
      unless handler
        return { success: false, error: "No handler for tool: #{tool_name}" }
      end

      handler.call(args)
    end

    def tool_names
      @validator.tool_names
    end

    private

    def parse_arguments(json_string)
      JSON.parse(json_string.to_s).stringify_keys
    rescue JSON::ParserError
      {}
    end

    def build_stub_handlers
      @validator.tool_names.to_h do |name|
        [name, stub_handler(name)]
      end
    end

    def stub_handler(name)
      ->(_args) { { success: true, data: { tool: name, message: "Stub implementation (P0-003)" } } }
    end
  end
end
