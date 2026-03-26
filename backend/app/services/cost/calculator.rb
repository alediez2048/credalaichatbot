# frozen_string_literal: true

module Cost
  class Calculator
    PRICING_PATH = Rails.root.join("config/ai_pricing.yml")
    PRICING = YAML.load_file(PRICING_PATH)["models"].freeze

    # @param model [String] e.g. "gpt-4o"
    # @param prompt_tokens [Integer]
    # @param completion_tokens [Integer]
    # @return [BigDecimal] cost in USD, rounded to 6 decimal places
    def self.calculate(model:, prompt_tokens:, completion_tokens:)
      rates = PRICING[model]
      return BigDecimal("0") unless rates

      input_cost  = (prompt_tokens / 1000.0) * rates["input_per_1k"]
      output_cost = (completion_tokens / 1000.0) * rates["output_per_1k"]
      BigDecimal((input_cost + output_cost).to_s).round(6)
    end
  end
end
