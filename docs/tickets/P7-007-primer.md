# P7-007 — Render & production config for omnichannel (env, webhooks, blueprint)

**Priority:** P7  
**Estimate:** 2 hours  
**Phase:** 7 — Omnichannel Continuity  
**Status:** Proposed

---

## Goal

Align the **Render** deployment (and `render.yaml` blueprint) with P7: SMS/Twilio, optional OpenClaw hook integration, and feature flags—so production has the right secrets, stable public URLs for inbound webhooks, and documented operator steps. No new application features; this is **ops and configuration** only.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks |
|--------|----------------|
| **P6-001** | App must already be deployed on Render (or equivalent) with base env vars |
| **P7-002** | Twilio inbound route exists (`POST /webhooks/sms/twilio`) before Twilio console can be wired |

**Partial work before P7-004:** You can add env vars and Twilio webhook URL to Render as soon as P7-002 is live. OpenClaw hook URL and `OPENCLAW_*` values apply after **P7-004** implements the Rails endpoint (exact path per that ticket).

---

## Deliverables Checklist

### 1. Render dashboard — environment variables

On the **web service** (e.g. `onboarding-assistant`), set:

- [ ] **SMS / Twilio (when using live SMS)**  
  - `SMS_PROVIDER=twilio`  
  - `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER`  
  - Keep `SMS_PROVIDER=mock` if production should not send real SMS yet.

- [ ] **OpenClaw (after P7-004 ships)**  
  - `OPENCLAW_HOOKS_TOKEN` — strong secret; must match OpenClaw gateway config  
  - `OPENCLAW_GATEWAY_URL` — only if Rails calls OpenClaw (URL of gateway host, often *not* the Render hostname)  
  - `OPENCLAW_ENABLED` — `true` / `false`  
  - `PROACTIVE_NUDGE_ENABLED` — `true` / `false` when P7-005 behavior exists  

- [ ] **Rails host / URLs (if not already set)**  
  - Ensure `config.hosts` / `action_cable.allowed_request_origins` allow your Render URL and any custom domain (see `docs/ops/production.md`).

### 2. External services — webhook URLs

Document the **canonical production base URL** (e.g. `https://<service>.onrender.com`):

- [ ] **Twilio** — Inbound webhook on the Messaging phone number →  
  `https://<host>/webhooks/sms/twilio` (POST; match Twilio signature validation requirements).

- [ ] **OpenClaw** — After P7-004, configure the gateway to call  
  `https://<host><rails_openclaw_path>` (use the path implemented in P7-004).

- [ ] **Stable URL / cold starts** — Note in runbook: free-tier sleep can delay webhooks; recommend Starter instance or custom domain for demos.

### 3. Infrastructure as code

- [ ] Update repo **`render.yaml`**: add P7-related keys with `sync: false` (same pattern as `OPENAI_API_KEY`) so the blueprint lists required vars without committing secrets. Example keys: `SMS_PROVIDER`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER`, `OPENCLAW_HOOKS_TOKEN`, `OPENCLAW_GATEWAY_URL`, `OPENCLAW_ENABLED`, `PROACTIVE_NUDGE_ENABLED`.

- [ ] Redeploy or “Sync” blueprint after `render.yaml` changes so new keys appear in the dashboard.

### 4. Documentation

- [ ] Add or extend **`docs/ops/render-omnichannel.md`** (or a section in `docs/ops/production.md`) with:  
  - Table of env vars and when each is required  
  - Exact webhook paths and who calls them (Twilio vs OpenClaw)  
  - Checklist for new environments (staging vs production)

### 5. Verification

- [ ] `curl -I https://<host>/up` returns success (existing health check).  
- [ ] Twilio: test inbound SMS to production number → request hits Rails (check logs).  
- [ ] OpenClaw: after P7-004, test hook from gateway → Rails returns 2xx (check logs).  
- [ ] With `SMS_PROVIDER=mock`, app boots and tests/CI behavior unchanged.

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | All P7-related secrets exist on Render web service when features are enabled | Dashboard env tab |
| 2 | Twilio webhook URL points at production Rails | Twilio console + inbound test |
| 3 | `render.yaml` documents new vars without embedding secrets | PR review; `sync: false` |
| 4 | Ops doc lists env + webhook checklist | Read `docs/ops/...` |
| 5 | No secrets committed to git | `git grep` for tokens |

---

## Out of Scope

- Hosting the OpenClaw gateway **on** Render (optional future; default is separate host).  
- Implementing P7-004/P7-005 code.  
- Adding Sidekiq worker or Cron on Render unless a separate ticket requires it.

---

## Definition of Done

- [ ] Deliverables checked  
- [ ] Acceptance criteria verified  
- [ ] `DEVLOG.md` updated with P7-007 entry  
- [ ] Feature branch pushed; PR ready (if code/doc changes)

---

## Suggested Branch

```bash
git switch -c feature/P7-007-render-omnichannel-config
```
