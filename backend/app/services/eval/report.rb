# frozen_string_literal: true

module Eval
  class Report
    def self.generate(results)
      total = results.size
      passed = results.count { |r| r[:pass] }
      failed = total - passed

      by_category = results.group_by { |r| r[:category] }.transform_values do |cat_results|
        {
          total: cat_results.size,
          passed: cat_results.count { |r| r[:pass] },
          failed: cat_results.count { |r| !r[:pass] }
        }
      end

      failures = results.reject { |r| r[:pass] }.map do |r|
        { name: r[:name], category: r[:category], reason: r[:reason] }
      end

      {
        total: total,
        passed: passed,
        failed: failed,
        pass_rate: total > 0 ? (passed.to_f / total * 100).round(2) : 0,
        by_category: by_category,
        failures: failures,
        timestamp: Time.current.iso8601
      }
    end
  end
end
