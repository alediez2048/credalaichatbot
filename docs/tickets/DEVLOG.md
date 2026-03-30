## 2026-03-30 — P7-006 Admin dashboard analytics & session drill-down

- **Session detail:** `GET /admin/sessions/:id` — timeline with channel badges, channel-switch markers, step markers (from `metadata[:step_changed]` / `step_after` on assistant messages).
- **TurnProcessor:** Persists `step_changed` and `step_after` on assistant messages when the orchestrator advances the step (feeds funnel time-in-step and timeline).
- **Dashboard:** Progression funnel (reached / proceeded / retention / drop-off / avg minutes per step), channel analytics panel, interaction analytics (messages, duration, errors, sentiment %, LLM usage by model), filterable session outcomes table (status, channel, date range), links to session detail from outcomes and recent sessions.
- **Services:** `Admin::SessionDetailStats`, `Admin::ChannelAnalytics`, `Admin::InteractionAnalytics`, `Admin::SessionOutcomes`; `Admin::DashboardStats.call` accepts filter kwargs and returns the new aggregates.
- **Tests:** Unit tests for the new services; `Admin::SessionsControllerTest`; extended `DashboardStatsTest` and `DashboardControllerTest`.

## 2026-03-30 — P7-005 Proactive onboarding & hardening

- **Idle sessions API:** `GET /api/admin/idle_sessions` — returns active sessions idle > 2 hours, excluding completed, recently nudged (24h cooldown), and opted-out. Auth via `OPENCLAW_HOOKS_TOKEN`; gated by `PROACTIVE_NUDGE_ENABLED`.
- **Health check:** `GET /api/admin/openclaw_status` — returns feature flag state and gateway URL. Auth via hook token; gated by `OPENCLAW_ENABLED`.
- **STOP/HELP/START keywords:** `InboundProcessor` now intercepts STOP (opts out, replies confirmation), HELP (replies usage), START (re-opts in). Keyword events logged in `SmsEvent` with `metadata: { keyword: … }`.
- **Frequency cap:** `IdleSessionsQuery` excludes sessions that received an outbound nudge event (`metadata: { nudge: true }`) within the cooldown window (default 24h).
- **Admin API base:** `Api::Admin::BaseController` extracts shared hook-token auth for admin endpoints under `/api/admin/`.
- **Runbook:** `docs/ops/openclaw-runbook.md` — gateway start/stop, channel troubleshooting, disabling nudges, diagnostics, emergency kill.
- **Tests:** `idle_sessions_controller_test`, `openclaw_status_controller_test`, `idle_sessions_query_test`, `inbound_processor_stop_keywords_test`.

## 2026-03-29 — P7-003 Cross-channel orchestration

- Added `Onboarding::TurnProcessor` as the single entry for web + SMS turns: `session.with_lock`, user/assistant `Message` rows with channel metadata (`channel`, `last_channel_before`, optional `provider_message_id`, `inbound_event_id`).
- Added `Onboarding::ChannelFormatter` for SMS truncation (1600 chars), resume copy when switching web↔SMS, and shorter SMS error text.
- Wired `OnboardingChatChannel` and `Messaging::InboundProcessor` to `TurnProcessor`; concurrency covered by `turn_processor_concurrency_test`.

## 2026-03-30 — P7-004 OpenClaw hook → Rails (partial)

- **API:** `POST /api/openclaw/turn` → `Api::OpenclawTurnsController#create` — `OPENCLAW_ENABLED`, `OPENCLAW_HOOKS_TOKEN` (header or Bearer or `token` param), JSON `text` / `channel` / `sender_id`, optional `message_id`/`external_id`/`phone_number`.
- **Identity:** Migration `channel_type` + `channel_user_id` on `onboarding_sessions` (partial unique index); `Messaging::IdentityResolver` find-or-create and optional phone link to `sms_opted_in` sessions.
- **Processing:** `TurnProcessor` with `channel: :openclaw`; `ChannelFormatter` treats `openclaw` like SMS for truncation/resume copy; inbound idempotency via `SmsEvent` (`provider: openclaw`).
- **Tests:** `openclaw_turns_controller_test`, `identity_resolver_test`, `channel_formatter` openclaw case. OpenClaw daemon/workspace setup remains manual (primer §1–2).

## 2026-03-30 — P7 plan revision: OpenClaw-first architecture

- **Corrected OpenClaw understanding:** OpenClaw is a self-hosted AI agent gateway (multi-channel: WhatsApp, Telegram, Discord, SMS, WebChat, etc.), not an SMS provider API. It manages sessions, memory, and proactive outreach.
- **P7-001 through P7-003 retained as-is.** Phone/consent capture, Twilio/mock adapters, and `TurnProcessor` are still foundational — they become the Rails-side entry point that OpenClaw calls into via webhooks.
- **P7-004 rewritten:** Now covers OpenClaw gateway setup, agent workspace (`AGENTS.md`, `SOUL.md`), channel config, hook integration (OpenClaw → Rails `TurnProcessor`), channel identity resolution.
- **P7-005 added:** Proactive onboarding via OpenClaw heartbeat, idle-user nudges, STOP/quiet-hours compliance, feature flags, runbook.
- **P7-006 added:** Admin dashboard with user journey drill-down, channel analytics, interaction metrics, completion outcomes table, filterable session list.
