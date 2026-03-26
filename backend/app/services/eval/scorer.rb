# frozen_string_literal: true

module Eval
  class Scorer
    STRATEGIES = %w[contains not_contains regex tool_called step_changed].freeze

    # @param response [String] the assistant's response text
    # @param strategy [String] scoring strategy
    # @param expected [String] expected value/pattern
    # @param metadata [Hash] optional metadata (tool_calls, step changes)
    # @return [Hash] { pass: Boolean, reason: String }
    def self.score(response:, strategy:, expected:, metadata: {})
      case strategy
      when "contains"
        pass = response.to_s.downcase.include?(expected.to_s.downcase)
        { pass: pass, reason: pass ? "Response contains '#{expected}'" : "Response does not contain '#{expected}'" }

      when "not_contains"
        pass = !response.to_s.downcase.include?(expected.to_s.downcase)
        { pass: pass, reason: pass ? "Response correctly omits '#{expected}'" : "Response unexpectedly contains '#{expected}'" }

      when "regex"
        pattern = Regexp.new(expected.to_s, Regexp::IGNORECASE)
        pass = response.to_s.match?(pattern)
        { pass: pass, reason: pass ? "Response matches pattern /#{expected}/" : "Response does not match /#{expected}/" }

      when "tool_called"
        tool_calls = metadata[:tool_calls] || []
        pass = tool_calls.include?(expected.to_s)
        { pass: pass, reason: pass ? "Tool '#{expected}' was called" : "Tool '#{expected}' was not called" }

      when "step_changed"
        new_step = metadata[:new_step].to_s
        pass = new_step == expected.to_s
        { pass: pass, reason: pass ? "Step changed to '#{expected}'" : "Step is '#{new_step}', expected '#{expected}'" }

      else
        { pass: false, reason: "Unknown strategy: #{strategy}" }
      end
    end
  end
end
