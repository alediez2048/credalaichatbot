# frozen_string_literal: true

module Eval
  class Runner
    def self.run(cases: nil, chat_service: nil)
      test_cases = cases || CaseLoader.load_all
      results = []

      test_cases.each do |tc|
        result = run_case(tc, chat_service: chat_service)
        results << result
      end

      results
    end

    def self.run_case(tc, chat_service: nil)
      session = OnboardingSession.create!(
        status: "active",
        current_step: tc["step"] || "welcome",
        metadata: tc["metadata"] || {}
      )

      orchestrator = Onboarding::Orchestrator.new(session, chat_service: chat_service)
      response = orchestrator.process(tc["input"])

      score = Scorer.score(
        response: response[:content],
        strategy: tc["strategy"],
        expected: tc["expected"],
        metadata: { step_changed: response[:step_changed] }
      )

      {
        name: tc["name"],
        category: tc["category"],
        input: tc["input"],
        response: response[:content],
        pass: score[:pass],
        reason: score[:reason]
      }
    ensure
      session&.destroy
    end
  end
end
