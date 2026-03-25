# P5-003 — Cost tracking & projection model

**Priority:** P5
**Estimate:** 4 hours
**Phase:** 5 — Evals & Ops
**Status:** Not started

---

## Goal

Track OpenAI token usage per session, calculate real dollar costs, and build a projection model that estimates monthly spend at various user volumes. Store usage data in the database so the admin dashboard (P5-004) can display it. Provide a rake task for generating cost reports.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P5-003 |
|--------|----------------------|
| **P0-005** | Tracer already captures `prompt_tokens`, `completion_tokens`, `total_tokens` per LLM call |
| **P1-002** | Orchestrator must exist so sessions have real multi-turn token usage |

---

## Deliverables Checklist

- [ ] `LlmUsage` model and migration: `session_id`, `message_id`, `model`, `prompt_tokens`, `completion_tokens`, `total_tokens`, `cost_usd` (decimal), `created_at`
- [ ] `app/services/cost/calculator.rb` — calculates USD cost from token counts and model pricing table
- [ ] `app/services/cost/projector.rb` — given historical usage data, projects monthly cost at N users/month
- [ ] `app/services/cost/tracker.rb` — called from `LLM::ChatService` after each call; persists `LlmUsage` record
- [ ] Pricing config in `config/ai_pricing.yml` — per-model input/output token rates (gpt-4o, gpt-4o-mini, etc.)
- [ ] `lib/tasks/cost.rake` — `rails cost:report` outputs per-session and aggregate cost summary; `rails cost:project[users_per_month]` outputs projection
- [ ] Unit tests for Calculator (known token counts produce expected USD), Projector (linear and weighted projections), Tracker (creates LlmUsage record)
- [ ] Seed data or factory for testing with realistic token counts

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Every LLM call creates an `LlmUsage` record | Run a chat, check `LlmUsage.count` increased |
| 2 | Cost calculation matches OpenAI published rates | Compare `cost_usd` against manual calculation for known token counts |
| 3 | `rails cost:report` shows per-session breakdown | Run task, verify output includes session IDs and costs |
| 4 | `rails cost:project[1000]` outputs monthly projection | Run task with argument, verify output |
| 5 | Pricing config supports multiple models | Add gpt-4o-mini rate, verify Calculator uses correct rate |
| 6 | Zero tokens / missing usage gracefully handled | LLM call with no usage data does not crash tracker |

---

## Architecture

### Pricing config

```yaml
# config/ai_pricing.yml
models:
  gpt-4o:
    input_per_1k: 0.0025
    output_per_1k: 0.01
  gpt-4o-mini:
    input_per_1k: 0.00015
    output_per_1k: 0.0006
```

### Cost calculation

```ruby
# app/services/cost/calculator.rb
class Cost::Calculator
  def self.calculate(model:, prompt_tokens:, completion_tokens:)
    rates = YAML.load_file("config/ai_pricing.yml")["models"][model]
    input_cost  = (prompt_tokens / 1000.0) * rates["input_per_1k"]
    output_cost = (completion_tokens / 1000.0) * rates["output_per_1k"]
    (input_cost + output_cost).round(6)
  end
end
```

### Projection model

```ruby
# app/services/cost/projector.rb
class Cost::Projector
  def self.project(users_per_month:)
    avg_sessions_per_user = 1.2
    avg_cost_per_session  = LlmUsage.group(:session_id).sum(:cost_usd).values.then { |costs|
      costs.empty? ? 0 : costs.sum / costs.size
    }
    monthly_cost = users_per_month * avg_sessions_per_user * avg_cost_per_session
    {
      users_per_month: users_per_month,
      avg_cost_per_session: avg_cost_per_session,
      projected_monthly_cost: monthly_cost.round(2),
      projected_annual_cost: (monthly_cost * 12).round(2)
    }
  end
end
```

### Integration with ChatService

```ruby
# In LLM::ChatService#chat, after OpenAI response:
Cost::Tracker.record(
  session_id: options[:session_id],
  message_id: options[:message_id],
  model: model,
  usage: response.dig("usage")  # { prompt_tokens:, completion_tokens:, total_tokens: }
)
```

### New files

| File | Purpose |
|------|---------|
| `db/migrate/xxx_create_llm_usages.rb` | Migration for LlmUsage table |
| `app/models/llm_usage.rb` | ActiveRecord model |
| `app/services/cost/calculator.rb` | Token-to-USD conversion |
| `app/services/cost/tracker.rb` | Persists usage after each LLM call |
| `app/services/cost/projector.rb` | Monthly cost projection |
| `config/ai_pricing.yml` | Model pricing rates |
| `lib/tasks/cost.rake` | Rake tasks for reporting and projection |

### Modified files

| File | Changes |
|------|---------|
| `app/services/llm/chat_service.rb` | Call `Cost::Tracker.record` after each LLM response |

---

## Files You Should READ Before Coding

1. `app/services/llm/chat_service.rb` — where to hook token tracking
2. `app/services/observability/tracer.rb` — already captures token counts (avoid duplication)
3. `db/schema.rb` — existing models for foreign key references
4. `app/models/onboarding_session.rb` — session association

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P5-003 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P5-003-cost-tracking
```

---

## Out of Scope for P5-003

- Admin UI for viewing costs (P5-004)
- Cost optimization / model switching logic
- Billing integration or user-facing cost display
- Cost analysis report document (P6-004)
