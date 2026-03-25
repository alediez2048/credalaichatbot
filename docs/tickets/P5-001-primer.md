# P5-001 — Eval framework & test suite (50+ cases)

**Priority:** P5
**Estimate:** 6 hours
**Phase:** 5 — Evals & Ops
**Status:** Not started

---

## Goal

Build an automated evaluation framework that tests the chatbot's responses against a suite of 50+ test cases covering every onboarding step. Each case defines a user input (or multi-turn conversation), an expected behavior (tool call, step transition, or response content), and a pass/fail scoring rubric. The framework runs locally via `rails eval:run` and produces a JSON report with aggregate scores.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P5-001 |
|--------|----------------------|
| **P1-002** | Orchestrator must exist so eval cases can exercise the full onboarding flow |
| **P0-005** | LangSmith tracing must be wired so eval runs are observable |

---

## Test Case Categories

| Category | Example cases | Count |
|----------|--------------|-------|
| Welcome & greeting | First message triggers welcome, assistant introduces itself | 5 |
| Personal info collection | Name extraction, email validation, phone parsing, DOB format | 10 |
| Document upload step | Correct instructions given, stub handled gracefully | 5 |
| Scheduling step | Slot explanation, booking stub handled gracefully | 5 |
| Review & confirmation | Summary includes collected data, confirmation flow | 5 |
| Completion | Congrats message, next steps mentioned | 3 |
| Edge cases | Empty input, very long input, off-topic questions, profanity | 7 |
| Multi-turn coherence | 3+ turn conversations maintaining context | 5 |
| Tool call accuracy | Correct tool called with correct params for given input | 5 |
| Step transitions | Automatic advancement when required fields complete | 5 |

**Total: 55+ cases**

---

## Deliverables Checklist

- [ ] `lib/tasks/eval.rake` — `rails eval:run` task that loads cases, runs them against the Orchestrator, scores results, outputs JSON report
- [ ] `test/eval/cases/` directory with YAML files organized by category (e.g., `welcome.yml`, `personal_info.yml`, `edge_cases.yml`)
- [ ] `app/services/eval/runner.rb` — loads cases, executes each against `Onboarding::Orchestrator`, collects results
- [ ] `app/services/eval/scorer.rb` — scores each result against expected behavior (exact match, contains, regex, tool_called, step_changed)
- [ ] `app/services/eval/report.rb` — aggregates scores into JSON report with pass/fail counts, category breakdown, failing case details
- [ ] Test case YAML schema documented in `test/eval/cases/README.md`
- [ ] At least 50 test cases across all categories
- [ ] Unit tests for Scorer (each scoring strategy) and Report (aggregation)
- [ ] Sample report output committed as `test/eval/sample_report.json`

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | `rails eval:run` executes all cases and produces JSON report | Run task, check output file |
| 2 | Report includes per-case pass/fail with reason | Inspect JSON for failing cases |
| 3 | Report includes category-level and overall scores | Check aggregate fields in JSON |
| 4 | Cases cover all 6 onboarding steps | Count cases per step in YAML files |
| 5 | Edge cases include adversarial inputs | Review edge_cases.yml |
| 6 | Eval runs are traced in LangSmith with `eval` tag | Check LangSmith dashboard for eval project |

---

## Architecture

### Test case YAML format

```yaml
# test/eval/cases/personal_info.yml
- id: "pi-001"
  description: "Extracts user name from natural sentence"
  step: "personal_info"
  setup:
    session_metadata: { current_step: "personal_info" }
    prior_messages:
      - role: assistant
        content: "What's your full name?"
  input: "My name is Jordan Smith"
  expect:
    type: "tool_called"
    tool_name: "saveOnboardingProgress"
    params_include:
      name: "Jordan Smith"

- id: "pi-002"
  description: "Validates email format"
  step: "personal_info"
  setup:
    session_metadata: { current_step: "personal_info", name: "Jordan Smith" }
  input: "my email is jordan@example.com"
  expect:
    type: "tool_called"
    tool_name: "saveOnboardingProgress"
    params_include:
      email: "jordan@example.com"
```

### Scoring strategies

| Strategy | Description |
|----------|-------------|
| `contains` | Response text includes expected substring |
| `regex` | Response text matches regex pattern |
| `tool_called` | Specific tool was invoked with expected params |
| `step_changed` | Session step advanced to expected value |
| `no_tool` | No tool was called (for conversational responses) |
| `llm_judge` | (Future) Use a second LLM call to grade response quality |

### New files

| File | Purpose |
|------|---------|
| `lib/tasks/eval.rake` | Rake task entry point |
| `app/services/eval/runner.rb` | Loads and executes test cases |
| `app/services/eval/scorer.rb` | Scores individual results |
| `app/services/eval/report.rb` | Aggregates into JSON report |
| `test/eval/cases/*.yml` | Test case definitions |

---

## Files You Should READ Before Coding

1. `app/services/onboarding/orchestrator.rb` — the system under test
2. `app/services/llm/chat_service.rb` — how LLM calls are made
3. `app/services/tools/router.rb` — tool execution
4. `app/services/observability/tracer.rb` — tagging eval runs
5. `config/prompts/onboarding_steps.yml` — step definitions to ensure coverage

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P5-001 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P5-001-eval-framework
```

---

## Out of Scope for P5-001

- CI integration (P5-005)
- LLM-as-judge scoring (future enhancement)
- Dashboard visualization of eval results (P5-004 admin dashboard may show these)
- Cost tracking of eval runs (P5-003)
