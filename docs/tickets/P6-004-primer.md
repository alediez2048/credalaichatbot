# P6-004 — AI cost analysis report

**Priority:** P6
**Estimate:** 2 hours
**Phase:** 6 — Launch
**Status:** Not started

---

## Goal

Produce a written report documenting actual AI costs from development and testing, per-session cost breakdown, cost drivers, and optimization recommendations. This artifact demonstrates cost-awareness and responsible AI engineering. The report is a markdown document suitable for inclusion in the portfolio.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P6-004 |
|--------|----------------------|
| **P5-003** | Cost tracking data (`LlmUsage` records) must exist |
| **P5-001** | Eval run costs should be included in the analysis |

---

## Deliverables Checklist

- [ ] `docs/cost-analysis.md` — full cost analysis report (see structure below)
- [ ] Summary of total tokens consumed and total USD spent during development
- [ ] Per-session cost breakdown: avg, median, min, max, P95
- [ ] Per-step cost breakdown: which onboarding steps consume the most tokens
- [ ] Eval cost breakdown: total cost of running the eval suite
- [ ] Cost projection at 100, 1,000, and 10,000 users/month
- [ ] Optimization recommendations with estimated savings
- [ ] Comparison table: gpt-4o vs gpt-4o-mini for this use case
- [ ] `rails cost:report` output included as appendix or linked

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Report contains actual cost data (not hypothetical) | Verify numbers match `LlmUsage` records |
| 2 | Per-session and per-step breakdowns present | Read report sections |
| 3 | Projection model included with multiple user volumes | Check projection table |
| 4 | At least 3 optimization recommendations with estimated savings | Count recommendations |
| 5 | Model comparison included | Check comparison table |
| 6 | Report is well-formatted markdown | Render on GitHub, verify readability |

---

## Report Structure

```markdown
# AI Cost Analysis Report — Credal Onboarding Assistant

## Executive Summary
- Total development cost: $X.XX over Y sessions
- Average cost per onboarding session: $X.XX
- Projected monthly cost at 1,000 users: $XX.XX

## Methodology
- Token usage tracked via LlmUsage model (P5-003)
- Costs calculated using OpenAI published pricing as of [date]
- Data collected from [date range] across [N] sessions

## Cost Breakdown

### By Session
| Metric | Value |
|--------|-------|
| Total sessions | N |
| Avg tokens/session | X |
| Avg cost/session | $X.XX |
| Median cost/session | $X.XX |
| P95 cost/session | $X.XX |
| Max cost/session | $X.XX |

### By Onboarding Step
| Step | Avg tokens | Avg cost | % of total |
|------|-----------|----------|-----------|
| welcome | X | $X.XX | X% |
| personal_info | X | $X.XX | X% |
| ... | ... | ... | ... |

### Eval Suite Costs
| Metric | Value |
|--------|-------|
| Cases per run | 55 |
| Tokens per run | X |
| Cost per run | $X.XX |
| Estimated monthly CI cost (4 runs/day) | $X.XX |

## Cost Projections
| Users/month | Sessions/month | Monthly cost | Annual cost |
|-------------|---------------|-------------|------------|
| 100 | 120 | $X.XX | $X.XX |
| 1,000 | 1,200 | $XX.XX | $XXX.XX |
| 10,000 | 12,000 | $XXX.XX | $X,XXX.XX |

## Optimization Recommendations

### 1. Model downgrade for simple steps
- Use gpt-4o-mini for welcome and completion steps
- Estimated savings: X%

### 2. Context window management
- Summarize conversation history after N messages instead of sending full history
- Estimated savings: X%

### 3. Prompt optimization
- Reduce system prompt token count by removing redundant instructions
- Estimated savings: X%

### 4. Caching
- Cache common responses (welcome message, step instructions)
- Estimated savings: X%

## Model Comparison
| Model | Avg tokens/session | Cost/session | Quality score | Recommendation |
|-------|-------------------|-------------|--------------|----------------|
| gpt-4o | X | $X.XX | X% | Use for complex steps |
| gpt-4o-mini | X | $X.XX | X% | Use for simple steps |

## Appendix
- Raw data: `rails cost:report` output
- Pricing source: OpenAI pricing page ([link])
```

---

## New files

| File | Purpose |
|------|---------|
| `docs/cost-analysis.md` | The cost analysis report |

---

## Files You Should READ Before Coding

1. `app/services/cost/calculator.rb` — pricing rates used
2. `app/services/cost/projector.rb` — projection methodology
3. `config/ai_pricing.yml` — model pricing config
4. `app/models/llm_usage.rb` — data source for actual costs
5. Run `rails cost:report` and `rails cost:project[1000]` for raw data

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P6-004 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P6-004-cost-report
```

---

## Out of Scope for P6-004

- Automated report generation (this is a one-time written document)
- Billing system implementation
- Negotiating OpenAI enterprise pricing
