# P7-006 — Admin dashboard: user interactions, analytics, and journey visualization

**Priority:** P7  
**Estimate:** 6 hours  
**Phase:** 7 — Omnichannel Continuity  
**Status:** In progress (Rails dashboard + drill-down + services + tests landed; optional funnel drill-down / full-row click / JS sorting deferred)

---

## Goal

Extend the existing `/admin/dashboard` (P5-004) into a comprehensive operations view where Credal staff can visualize individual user journeys, track onboarding completion outcomes, monitor channel usage (web vs SMS vs OpenClaw channels), and identify friction points — without needing database access or log diving.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P7-006 |
|--------|----------------------|
| **P5-004** | Base admin dashboard with session stats, funnel, cost, and eval panels (already scaffolded) |
| **P7-001** | Channel metadata (`last_channel`, `phone_number`, `sms_opt_in`) on sessions |
| **P7-003** | Per-message `channel` metadata and `SmsEvent` table |

---

## Deliverables Checklist

### 1. Session detail / drill-down page
- [x] Route: `GET /admin/sessions/:id`
- [x] Full message timeline with role, content (truncated), channel badge (web/sms/whatsapp/etc.), timestamp
- [x] Step transitions highlighted in the timeline (step changed markers)
- [x] Channel switch moments flagged visually (e.g. "switched from web to sms")
- [x] Session metadata sidebar: user info, phone, consent status, current step, progress %, time in flow, total cost, last channel, last interaction

### 2. User journey funnel (enhanced)
- [x] Replace the current step-count table with a true funnel visualization showing drop-off between each step (how many entered step N vs advanced to step N+1)
- [x] Time-in-step distribution: average time spent at each step (identifies friction points)
- [ ] Optional: hover/click on a funnel stage to see the sessions stuck there

### 3. Channel analytics panel
- [x] Breakdown of sessions by channel: web-only, SMS-opted-in, multi-channel (used both)
- [x] Completion rate by channel type (web-only vs multi-channel)
- [x] Channel switch events over time (web→sms, sms→web)
- [x] SMS event summary: total inbound, total outbound, delivery success rate

### 4. User interaction analytics
- [x] Average messages per session (user vs assistant breakdown)
- [x] Average session duration (first message to last message)
- [x] Sessions with errors / fallbacks count
- [x] Sentiment distribution across sessions (if P4-001 data available): % frustrated, neutral, positive
- [x] Tool usage frequency: which tools are called most (from message metadata or LLM usage) — **LLM usage by model** (proxy; not per-tool from message metadata)

### 5. Completion outcomes table
- [x] Filterable/sortable table of all sessions (not just recent 20) — **filterable**; sort via column headers deferred
- [x] Columns: ID, user email (or "anon"), current step, progress %, channel(s) used, message count, duration, cost, outcome (completed / abandoned / active), created, last activity
- [x] Filters: status (completed/active/abandoned), channel, date range
- [x] "Abandoned" = inactive > 24 hours and not completed
- [x] Click row → session detail page — **link on session ID** (full-row link optional follow-up)

### 6. Service layer
- [x] `Admin::SessionDetailStats.call(session_id)` — all data for a single session drill-down
- [x] `Admin::ChannelAnalytics.call` — channel breakdown metrics
- [x] `Admin::InteractionAnalytics.call` — message/duration/error/sentiment aggregates
- [x] Extend `Admin::DashboardStats` with enhanced funnel (time-in-step, drop-off rates)

### 7. Tests
- [x] Unit tests for each new service (with factory data)
- [x] Controller test: admin sees new pages, non-admin rejected
- [x] Session detail page renders with channel metadata

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Admin can click a session row and see full message timeline | Manual: navigate dashboard → click session → see messages with channel badges |
| 2 | Channel switch moments are visually flagged in timeline | Create session with web+sms messages, verify switch markers |
| 3 | Funnel shows drop-off rates between steps | Create sessions at various steps, verify percentages |
| 4 | Channel analytics panel shows web-only vs multi-channel split | Create mixed sessions, verify counts |
| 5 | Completion outcomes table filters by status and channel | Apply filters, verify correct results |
| 6 | Abandoned sessions correctly identified (>24h inactive, not completed) | Create old inactive session, verify it shows as abandoned |
| 7 | Dashboard renders responsively on mobile (375px) | Resize browser, verify layout |

---

## Architecture

### New routes

```ruby
namespace :admin do
  get "dashboard", to: "dashboard#index"
  get "sessions/:id", to: "sessions#show", as: :session_detail
end
```

### New files

| File | Purpose |
|------|---------|
| `app/controllers/admin/sessions_controller.rb` | Session detail page |
| `app/views/admin/sessions/show.html.erb` | Message timeline + metadata sidebar |
| `app/services/admin/session_detail_stats.rb` | Single-session data aggregation |
| `app/services/admin/channel_analytics.rb` | Channel breakdown metrics |
| `app/services/admin/interaction_analytics.rb` | Message/duration/sentiment aggregates |
| `test/unit/admin/channel_analytics_test.rb` | Channel metrics tests |
| `test/unit/admin/interaction_analytics_test.rb` | Interaction metrics tests |
| `test/controllers/admin/sessions_controller_test.rb` | Auth + rendering tests |

### Modified files

| File | Changes |
|------|---------|
| `app/views/admin/dashboard/index.html.erb` | Add channel analytics panel, enhanced funnel, link session rows to detail page |
| `app/services/admin/dashboard_stats.rb` | Add time-in-step, drop-off rates, channel stats to existing methods |
| `config/routes.rb` | Add session detail route |

### Data sources

| Metric | Source |
|--------|--------|
| Channel per message | `messages.metadata->>'channel'` |
| Channel switches | Adjacent messages with different `metadata->>'channel'` |
| SMS events | `sms_events` table (provider, direction, status) |
| Session duration | `messages.first.created_at` → `messages.last.created_at` |
| Step transitions | Messages where `metadata->>'step_changed'` or sequential step changes on session |
| Sentiment | `sentiment_readings` table (label, confidence) |
| Tool usage | `llm_usages` or message metadata |
| Abandonment | `OnboardingSession` where `updated_at < 24.hours.ago` and `current_step != 'complete'` |

---

## UI Layout (Session Detail)

```
+--------------------------------------------------+
|  ← Back to Dashboard                             |
|  Session #142 — jane@example.com                 |
+---------------------------+----------------------+
|  Message Timeline         |  Session Info        |
|                           |  Step: scheduling    |
|  [web] 10:01 USER         |  Progress: 60%       |
|  "Hi, starting today"     |  Duration: 12 min    |
|                           |  Messages: 18        |
|  [web] 10:01 ASSISTANT    |  Cost: $0.08         |
|  "Welcome! Let's begin.." |  Phone: +1415...     |
|                           |  SMS Opt-in: Yes     |
|  [web] 10:05 USER         |  Last Channel: sms   |
|  "Here's my ID"           |  Last Active: 2m ago |
|                           |                      |
|  ── step: document_upload ──                     |
|                           |  Channel Summary     |
|  [web] 10:06 ASSISTANT    |  Web msgs: 12        |
|  "I can see your ID..."   |  SMS msgs: 6         |
|                           |  Switches: 2         |
|  ⚡ CHANNEL SWITCH web→sms                       |
|                           |  SMS Events          |
|  [sms] 14:30 USER         |  Inbound: 3          |
|  "Can I schedule now?"    |  Outbound: 3         |
|                           |  Failed: 0           |
|  [sms] 14:30 ASSISTANT    |                      |
|  "Picking up where you.." |                      |
+---------------------------+----------------------+
```

---

## Files You Should READ Before Coding

1. `app/services/admin/dashboard_stats.rb` — existing stats service to extend
2. `app/views/admin/dashboard/index.html.erb` — existing dashboard view
3. `app/controllers/admin/dashboard_controller.rb` — existing admin auth pattern
4. `app/models/onboarding_session.rb` — session fields, associations
5. `app/models/message.rb` — message schema, metadata JSON
6. `app/models/sms_event.rb` — SMS event tracking
7. `db/schema.rb` — full schema for query planning

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P7-006 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P7-006-admin-analytics
```

---

## Out of Scope for P7-006

- Real-time WebSocket updates on the dashboard (server-rendered refresh is fine)
- JavaScript charting libraries (use Tailwind-styled HTML bars/tables; follow P5-004 pattern)
- User management / CRUD admin users
- CSV/PDF export (follow-up ticket)
- OpenClaw gateway health monitoring (belongs in P7-005)
