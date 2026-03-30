# P7-005 — Proactive onboarding, heartbeat strategy, and hardening

**Priority:** P7  
**Estimate:** 4 hours  
**Phase:** 7 — Omnichannel Continuity  
**Status:** In progress (Rails endpoints, keyword handling, query, runbook, tests landed; heartbeat HEARTBEAT.md + openclaw.json config still manual/operator-side)

---

## Goal

Configure OpenClaw's proactive capabilities (heartbeat, standing orders, hooks) so the onboarding assistant automatically follows up with users who go idle, nudges them toward completion, and degrades gracefully when the gateway or a channel is unavailable.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P7-005 |
|--------|----------------------|
| **P7-004** | OpenClaw gateway must be running and connected to Rails |

---

## Deliverables Checklist

### 1. Heartbeat configuration
- [ ] Write `HEARTBEAT.md` in the onboarding agent workspace — checklist for periodic agent turns:
  - Check for idle sessions (no activity in last N hours, not completed)
  - Compose a gentle nudge message for each idle user
  - Respect quiet hours (no messages before 9am or after 9pm user-local)
- [ ] Configure `agents.list[].heartbeat` in `openclaw.json`:
  - `every: "1h"` (or appropriate cadence)
  - `target: "last"` (deliver on the channel the user last used)
  - `activeHours: { start: "09:00", end: "21:00" }`
  - `lightContext: true` (minimize token cost)
  - `isolatedSession: true` (fresh session per heartbeat run)
- [ ] Rails endpoint for heartbeat queries: `GET /api/admin/idle_sessions` — returns sessions idle > configured threshold, not completed, with channel info

### 2. Proactive nudge flow
- [ ] OpenClaw heartbeat reads `HEARTBEAT.md`, calls Rails idle-sessions endpoint
- [ ] For each idle session, OpenClaw sends a contextual follow-up on the user's last channel:
  - "Hey! You were on step [X] of your onboarding. Want to pick up where you left off?"
- [ ] Nudge frequency cap: max 1 nudge per user per 24 hours (tracked in `SmsEvent` or a new `nudge_events` table)
- [ ] Opt-out respected: users who replied STOP or revoked consent are excluded

### 3. Compliance controls (carried from old P7-004)
- [ ] STOP/HELP/START keyword handling in `InboundProcessor` (or OpenClaw-side)
- [ ] Quiet-hours enforcement (heartbeat `activeHours` + Rails-side check)
- [ ] Message frequency limits (no more than N messages per user per day)
- [ ] Audit trail: all proactive sends logged in `SmsEvent` or equivalent

### 4. Observability
- [ ] Channel-level tracing fields on messages: `provider`, `delivery_status`, `provider_latency`
- [ ] OpenClaw health check from Rails: `GET /api/admin/openclaw_status` (calls gateway health endpoint)
- [ ] Dashboard additions (P7-006 scope, but define metrics here):
  - Proactive nudge success rate (sent / reopened)
  - Reactivation rate (idle user → resumed after nudge)
  - Completion uplift for nudged vs non-nudged

### 5. Feature flag
- [ ] `OPENCLAW_ENABLED=true|false` env var — when false, all OpenClaw-specific paths are no-ops
- [ ] `PROACTIVE_NUDGE_ENABLED=true|false` — controls heartbeat nudges independently
- [ ] Feature flags checked in controller + heartbeat logic

### 6. Runbook
- [ ] `docs/ops/openclaw-runbook.md` covering:
  - Gateway startup / restart / health check
  - Channel disconnection (WhatsApp QR expired, Telegram token revoked)
  - Rails endpoint unavailable (OpenClaw retries? fallback?)
  - How to disable proactive nudges without stopping the gateway
  - How to add a new channel
  - Log locations and diagnostic commands (`openclaw status`, `openclaw doctor`)

### 7. Tests
- [ ] Unit test: idle session query returns correct sessions
- [ ] Unit test: frequency cap prevents duplicate nudges
- [ ] Unit test: STOP keyword disables SMS for that session
- [ ] Feature flag test: disabled flag → no proactive sends
- [ ] Controller test: health check endpoint returns gateway status

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Idle user receives a nudge on their last-used channel | Let session idle > threshold, verify nudge delivered |
| 2 | No nudge sent during quiet hours | Set activeHours, verify no sends outside window |
| 3 | STOP keyword immediately disables further messages | Reply STOP, verify no subsequent nudges |
| 4 | Feature flag disables all proactive behavior | Set `PROACTIVE_NUDGE_ENABLED=false`, verify no nudges |
| 5 | Runbook covers all failure modes | Review document for completeness |
| 6 | Max 1 nudge per user per 24h | Trigger multiple heartbeats, verify only 1 nudge sent |

---

## Architecture

```
OpenClaw Gateway
    │
    heartbeat (every 1h, active hours only)
    │
    reads HEARTBEAT.md
    │
    calls GET /api/admin/idle_sessions (Rails)
    │
    for each idle session:
    │   compose nudge → send on last channel
    │   POST /hooks/agent (self) or direct channel send
    │
    Rails logs nudge event
```

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated
- [ ] Runbook reviewed
- [ ] Feature branch pushed; PR ready

---

## Suggested Branch

```bash
git switch -c feature/P7-005-proactive-hardening
```
