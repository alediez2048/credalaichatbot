# frozen_string_literal: true

namespace :eval do
  desc "Run the eval suite against the Orchestrator and produce a JSON report"
  task run: :environment do
    puts "Loading eval cases..."
    cases = Eval::CaseLoader.load_all
    puts "Found #{cases.size} test cases"

    puts "Running evals..."
    results = Eval::Runner.run(cases: cases)

    report = Eval::Report.generate(results)

    # Output report
    puts "\n=== EVAL REPORT ==="
    puts "Total: #{report[:total]}"
    puts "Passed: #{report[:passed]} (#{report[:pass_rate]}%)"
    puts "Failed: #{report[:failed]}"

    if report[:failures].any?
      puts "\nFailing cases:"
      report[:failures].each do |f|
        puts "  ❌ #{f[:name]} (#{f[:category]}): #{f[:reason]}"
      end
    end

    # Write JSON report
    report_path = Rails.root.join("tmp/eval_report.json")
    File.write(report_path, JSON.pretty_generate(report))
    puts "\nJSON report saved to #{report_path}"
  end

  desc "Run eval suite for CI — exits with code 1 if pass rate below threshold"
  task ci: :environment do
    config = load_ci_config
    threshold = ENV.fetch("EVAL_PASS_THRESHOLD", config["threshold"].to_s).to_f

    puts "Loading eval cases..."
    cases = Eval::CaseLoader.load_all
    puts "Running #{cases.size} eval cases (threshold: #{threshold}%)..."

    results = Eval::Runner.run(cases: cases)
    report = Eval::Report.generate(results)

    # Write JSON report for GitHub Actions PR comment
    report_path = Rails.root.join("tmp/eval_report.json")
    File.write(report_path, JSON.pretty_generate(report))

    puts "Pass rate: #{report[:pass_rate]}% (threshold: #{threshold}%)"

    if report[:pass_rate] < threshold
      puts "FAIL: Pass rate #{report[:pass_rate]}% < threshold #{threshold}%"
      report[:failures].each { |f| puts "  FAIL #{f[:name]}: #{f[:reason]}" }
      exit 1
    else
      puts "PASS: Pass rate #{report[:pass_rate]}% >= threshold #{threshold}%"
    end
  end
end

def load_ci_config
  path = Rails.root.join("config/ci/eval_config.yml")
  return { "threshold" => 85, "max_cost_per_run" => 5.0, "timeout_per_case" => 30 } unless File.exist?(path)
  YAML.load_file(path)
rescue => e
  Rails.logger.warn("[eval:ci] Failed to load CI config: #{e.message}")
  { "threshold" => 85 }
end
