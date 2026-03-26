# frozen_string_literal: true

require "test_helper"

module Eval
  class EvalTest < ActiveSupport::TestCase
    # --- Scorer ---

    test "contains strategy passes when response includes expected text" do
      result = Eval::Scorer.score(
        response: "Hello! Welcome to Credal onboarding.",
        strategy: "contains",
        expected: "welcome"
      )
      assert result[:pass]
    end

    test "contains strategy fails when response lacks expected text" do
      result = Eval::Scorer.score(
        response: "I can help with scheduling.",
        strategy: "contains",
        expected: "welcome"
      )
      assert_not result[:pass]
    end

    test "regex strategy matches pattern" do
      result = Eval::Scorer.score(
        response: "Your name is Jane Doe, correct?",
        strategy: "regex",
        expected: "Jane\\s+Doe"
      )
      assert result[:pass]
    end

    test "not_contains strategy passes when text is absent" do
      result = Eval::Scorer.score(
        response: "How can I help you?",
        strategy: "not_contains",
        expected: "error"
      )
      assert result[:pass]
    end

    test "tool_called strategy checks tool name in metadata" do
      result = Eval::Scorer.score(
        response: "Saved your info.",
        strategy: "tool_called",
        expected: "saveOnboardingProgress",
        metadata: { tool_calls: ["saveOnboardingProgress"] }
      )
      assert result[:pass]
    end

    # --- Case loading ---

    test "loads cases from YAML files" do
      cases = Eval::CaseLoader.load_all
      assert cases.is_a?(Array)
      assert cases.size >= 10 # we'll have at least some cases
    end

    test "each case has required keys" do
      cases = Eval::CaseLoader.load_all
      cases.first(5).each do |c|
        assert c["name"].present?, "Case missing name"
        assert c.key?("input"), "Case '#{c['name']}' missing input key"
        assert c["strategy"].present?, "Case '#{c['name']}' missing strategy"
        assert c["expected"].present?, "Case '#{c['name']}' missing expected"
      end
    end

    # --- Report ---

    test "report aggregates pass/fail counts" do
      results = [
        { name: "test1", pass: true, category: "welcome" },
        { name: "test2", pass: false, category: "welcome" },
        { name: "test3", pass: true, category: "edge_cases" }
      ]

      report = Eval::Report.generate(results)
      assert_equal 3, report[:total]
      assert_equal 2, report[:passed]
      assert_equal 1, report[:failed]
      assert_in_delta 66.67, report[:pass_rate], 1.0
    end
  end
end
