# frozen_string_literal: true

module Tools
  class SchemaValidator
    class ValidationError < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(errors.to_json)
      end
    end

    def initialize(definitions_path: nil)
      @definitions_path = definitions_path || Rails.root.join("config/prompts/tool_definitions.yml")
      @definitions = load_definitions
    end

    # @param tool_name [String]
    # @param params [Hash] string or symbol keys
    # @return [Hash] { valid: true } or { valid: false, errors: [...] }
    def validate(tool_name, params)
      definition = find_definition(tool_name)
      unless definition
        return { valid: false, errors: ["Unknown tool: #{tool_name}"] }
      end

      required = definition.dig("parameters", "required") || []
      param_keys = params.keys.map(&:to_s)
      missing = required.reject { |r| param_keys.include?(r.to_s) }

      if missing.any?
        return { valid: false, errors: ["Missing required parameters: #{missing.join(', ')}"] }
      end

      { valid: true }
    end

    # @raise [ValidationError] when invalid
    def validate!(tool_name, params)
      result = validate(tool_name, params)
      raise ValidationError, result[:errors] unless result[:valid]
      result
    end

    def tool_names
      @definitions.map { |d| d["name"] }
    end

    def definitions_for_openai
      @definitions.map do |d|
        {
          type: "function",
          function: {
            name: d["name"],
            description: d["description"].to_s,
            parameters: (d["parameters"] || {}).deep_stringify_keys
          }
        }
      end
    end

    private

    def load_definitions
      return [] unless File.file?(@definitions_path)
      YAML.load_file(@definitions_path) || []
    end

    def find_definition(tool_name)
      @definitions.find { |d| d["name"] == tool_name.to_s }
    end
  end
end
