# P5-002 — End-to-end tracing dashboard

**Priority:** P5
**Estimate:** 3 hours
**Phase:** 5 — Evals & Ops
**Status:** Not started

---

## Goal

Configure a LangSmith project dashboard that provides full visibility into every LLM call, tool execution, and session flow. Set up session-level tracing so all runs within a single onboarding session are grouped. Add custom metadata (step, user_id, tool calls) to each trace. Document how to use the dashboard for debugging and performance analysis.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P5-002 |
|--------|----------------------|
| **P0-005** | `Observability::Tracer` must be wired and posting runs to LangSmith |
| **P5-001** | Eval framework generates runs that should appear in the dashboard |

---

## Deliverables Checklist

- [ ] LangSmith project configured with meaningful name (e.g., `credal-onboarding-prod`, `credal-onboarding-dev`)
- [ ] Session-level tracing: all LLM calls within one `OnboardingSession` share a `session_id` tag in LangSmith
- [ ] `Observability::Tracer` enhanced to include: `onboarding_step`, `tool_calls` (list of tool names), `user_id`, `session_id`, `message_count`, `is_eval` (boolean)
- [ ] Parent/child run hierarchy: orchestrator call is parent run, individual LLM calls and tool executions are child runs
- [ ] LangSmith filter presets documented: by session, by step, by error, by eval
- [ ] `docs/ops/langsmith-dashboard.md` — guide for team on navigating the dashboard, common queries, alert setup
- [ ] Verify traces appear correctly with a real API key (screenshot or description in DEVLOG)

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Each onboarding session groups all its LLM calls under one session_id | Filter by session_id in LangSmith, see all related runs |
| 2 | Traces include onboarding step metadata | Click a run, see `onboarding_step` in metadata |
| 3 | Parent/child hierarchy visible | Orchestrator run shows child LLM and tool runs |
| 4 | Eval runs are tagged and filterable | Filter by `is_eval: true` in LangSmith |
| 5 | Dashboard guide exists and is accurate | Read `docs/ops/langsmith-dashboard.md`, follow instructions |

---

## Architecture

### Enhanced Tracer metadata

```ruby
# Current: session_id, user_id, model
# Enhanced:
Observability::Tracer.trace_llm_call(
  session_id: session.id,
  user_id: session.user_id,
  model: "gpt-4o",
  metadata: {
    onboarding_step: session.current_step,
    message_count: session.messages.count,
    is_eval: false
  }
) do |run_context|
  # LLM call here
  # run_context.add_child_run(name: "tool:saveOnboardingProgress", ...)
end
```

### Parent/child run structure

```
Orchestrator.process (parent run)
  -> LLM::ChatService#chat (child run: "llm-call")
  -> Tools::Router#call (child run: "tool:saveOnboardingProgress")
  -> LLM::ChatService#chat (child run: "llm-call-followup")
```

### Modified files

| File | Changes |
|------|---------|
| `app/services/observability/tracer.rb` | Add metadata hash param, parent/child run support, `is_eval` tag |
| `app/services/onboarding/orchestrator.rb` | Pass step metadata to Tracer |
| `app/services/eval/runner.rb` | Tag eval runs with `is_eval: true` |

### New files

| File | Purpose |
|------|---------|
| `docs/ops/langsmith-dashboard.md` | Team guide for using the LangSmith dashboard |

---

## Files You Should READ Before Coding

1. `app/services/observability/tracer.rb` — current implementation
2. `test/unit/observability/tracer_test.rb` — existing tests to extend
3. `app/services/onboarding/orchestrator.rb` — where metadata originates
4. `app/services/eval/runner.rb` — eval run tagging

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P5-002 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P5-002-tracing-dashboard
```

---

## Out of Scope for P5-002

- Cost tracking per trace (P5-003)
- Admin dashboard in Rails (P5-004)
- Alerting/PagerDuty integration
- Custom LangSmith evaluators (beyond what P5-001 provides)
