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
    threshold = ENV.fetch("EVAL_THRESHOLD", "80").to_f
    results = Eval::Runner.run
    report = Eval::Report.generate(results)

    puts "Pass rate: #{report[:pass_rate]}% (threshold: #{threshold}%)"

    if report[:pass_rate] < threshold
      puts "❌ BELOW THRESHOLD"
      report[:failures].each { |f| puts "  ❌ #{f[:name]}: #{f[:reason]}" }
      exit 1
    else
      puts "✅ PASSED"
    end
  end
end
