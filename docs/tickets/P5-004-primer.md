# P5-004 — Admin analytics dashboard

**Priority:** P5
**Estimate:** 5 hours
**Phase:** 5 — Evals & Ops
**Status:** Not started

---

## Goal

Build a Rails admin page at `/admin/dashboard` that shows session statistics, completion rates, drop-off points, cost summaries, and eval scores. The dashboard is server-rendered (ERB + Tailwind) and protected by admin authentication. It gives operators a single view into how the onboarding assistant is performing.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P5-004 |
|--------|----------------------|
| **P1-002** | Sessions with step data must exist for metrics |
| **P5-001** | Eval scores to display |
| **P5-003** | Cost data (`LlmUsage`) to summarize |

---

## Deliverables Checklist

- [ ] `Admin::DashboardController` with `index` action, restricted to admin users
- [ ] Admin role on `User` model: `admin` boolean column (migration)
- [ ] Route `get '/admin/dashboard'` with admin authentication guard
- [ ] Dashboard view (`app/views/admin/dashboard/index.html.erb`) with Tailwind styling
- [ ] **Session stats panel:** total sessions, active sessions, completed sessions, avg completion time
- [ ] **Completion funnel panel:** bar chart or table showing count of sessions at each onboarding step (drop-off visualization)
- [ ] **Cost summary panel:** total spend, avg cost per session, cost trend (last 7 days)
- [ ] **Eval scores panel:** latest eval run results, pass rate, failing categories
- [ ] **Recent sessions table:** last 20 sessions with user, step, progress %, message count, cost, created_at
- [ ] `app/services/admin/dashboard_stats.rb` — service that queries all metrics (keeps controller thin)
- [ ] Unit tests for `DashboardStats` (with factory data)
- [ ] Basic authorization test: non-admin redirected, admin sees dashboard

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | `/admin/dashboard` loads for admin user | Sign in as admin, visit page |
| 2 | Non-admin user is redirected with flash message | Sign in as regular user, visit page, verify redirect |
| 3 | Session stats show correct counts | Create known sessions, verify numbers match |
| 4 | Completion funnel shows drop-off by step | Create sessions at various steps, verify funnel |
| 5 | Cost panel shows data from `LlmUsage` | Verify totals match `LlmUsage.sum(:cost_usd)` |
| 6 | Recent sessions table is paginated or limited | Verify only last 20 shown |
| 7 | Dashboard renders on mobile (375px) | Resize browser, verify responsive layout |

---

## Architecture

### Dashboard layout

```
+--------------------------------------------------+
|  Credal Admin Dashboard                          |
+--------------------------------------------------+
|  [Sessions: 142] [Completed: 89] [Active: 12]   |
|  [Avg Completion: 8.3 min] [Completion Rate: 63%]|
+--------------------------------------------------+
|  Completion Funnel          |  Cost Summary       |
|  welcome:     142           |  Total: $14.23      |
|  personal:    128 (▼10%)    |  Avg/session: $0.10 |
|  documents:    95 (▼26%)    |  Last 7d: $4.82     |
|  scheduling:   91 (▼4%)    |                     |
|  review:       89 (▼2%)    |  Eval Pass Rate     |
|  complete:     89 (▼0%)    |  Overall: 92%       |
+--------------------------------------------------+
|  Recent Sessions                                 |
|  ID | User  | Step      | Progress | Cost | Time |
|  …  | …     | …         | …        | …    | …    |
+--------------------------------------------------+
```

### New files

| File | Purpose |
|------|---------|
| `app/controllers/admin/dashboard_controller.rb` | Admin dashboard controller |
| `app/views/admin/dashboard/index.html.erb` | Dashboard view with Tailwind |
| `app/services/admin/dashboard_stats.rb` | Aggregation queries |
| `db/migrate/xxx_add_admin_to_users.rb` | Add `admin` boolean to users |
| `test/controllers/admin/dashboard_controller_test.rb` | Auth and rendering tests |
| `test/unit/admin/dashboard_stats_test.rb` | Stats calculation tests |

### Modified files

| File | Changes |
|------|---------|
| `app/models/user.rb` | `admin?` convenience method |
| `config/routes.rb` | Admin namespace and dashboard route |

### DashboardStats service

```ruby
# app/services/admin/dashboard_stats.rb
class Admin::DashboardStats
  def self.call
    {
      total_sessions: OnboardingSession.count,
      completed_sessions: OnboardingSession.where(current_step: "complete").count,
      active_sessions: OnboardingSession.where("updated_at > ?", 30.minutes.ago).count,
      completion_rate: completion_rate,
      step_funnel: step_funnel,
      cost_summary: cost_summary,
      recent_sessions: recent_sessions,
      eval_summary: eval_summary
    }
  end

  def self.step_funnel
    steps = %w[welcome personal_info document_upload scheduling review complete]
    steps.map { |s| [s, OnboardingSession.where("progress_percent >= ?", step_threshold(s)).count] }
  end

  # ... other methods
end
```

---

## Files You Should READ Before Coding

1. `app/models/onboarding_session.rb` — session fields (current_step, progress_percent, metadata)
2. `app/models/llm_usage.rb` — cost data (from P5-003)
3. `app/views/layouts/application.html.erb` — layout for nav integration
4. `config/routes.rb` — existing route structure
5. `db/schema.rb` — current schema for query planning

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P5-004 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P5-004-admin-dashboard
```

---

## Out of Scope for P5-004

- Real-time WebSocket updates on the dashboard
- Charts with JavaScript libraries (use Tailwind-styled HTML tables/bars for now)
- User management (CRUD admin users)
- Export to CSV/PDF
