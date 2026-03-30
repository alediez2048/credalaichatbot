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
