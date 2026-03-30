# P7 Architecture Impact — OpenClaw Omnichannel Gateway

## Context

P7 extends the onboarding assistant beyond web-only chat by integrating [OpenClaw](https://docs.openclaw.ai/) — a self-hosted AI agent gateway that connects 20+ messaging channels (WhatsApp, Telegram, Discord, Slack, iMessage, SMS, WebChat) to the existing Rails backend.

**Key insight:** OpenClaw is not an SMS API. It is an autonomous agent gateway that receives user messages on any channel, maintains per-sender sessions and memory, supports proactive outreach via heartbeats, and calls into external systems via webhooks. Rails remains the source of truth for onboarding state, tools, and persistence.

---

## What Changes in the Current System

## 1) Channel Model: Web-only → Web + Any Channel via OpenClaw

### Current
- Primary turn ingestion is web chat (Action Cable + HTTP page lifecycle).
- Session continuity scoped to browser/session + authenticated user merge.
- Twilio/mock SMS as a direct fallback path (P7-001 through P7-003).

### P7-004+ Change
- OpenClaw Gateway sits in front of all non-web channels.
- Users can message on WhatsApp, Telegram, Discord, WebChat, SMS (via OpenClaw plugins), and more.
- Each channel message routes through OpenClaw to a Rails webhook endpoint.
- Web chat path (`/onboarding` → Action Cable → `TurnProcessor`) is **unchanged**.

**Impact:** Channel connectivity moves out of Rails into OpenClaw. Rails becomes a turn-processing API.

---

## 2) Orchestration Boundary

### Current
- `Onboarding::Orchestrator` processes user turns, manages step transitions.
- `TurnProcessor` is the single entry point (from Action Cable or `InboundProcessor`).

### P7-004+ Change
- `TurnProcessor` gains a third caller: `Api::OpenclawTurnsController` (webhook from OpenClaw).
- OpenClaw's agent runtime (`AGENTS.md`, `SOUL.md`) defines the assistant's persona and conversational boundaries.
- The LLM call still happens in Rails (`Orchestrator` → `ChatService`); OpenClaw does NOT make its own LLM calls for onboarding turns.

**Design rule:** OpenClaw is the channel gateway; Rails is the domain brain. Do not duplicate onboarding logic in OpenClaw's workspace files.

---

## 3) Session and Identity Model

### Current persisted fields (from P7-001)
- `phone_number` (E.164), `sms_opt_in`, `last_channel`, `last_interaction_at`

### P7-004 additions
- `channel_user_id` — the sender's identifier on the originating channel (WhatsApp number, Telegram ID, Discord user ID, etc.)
- `channel_type` — which channel (`whatsapp`, `telegram`, `discord`, `webchat`, `sms`, `web`)
- Identity linking: multiple channel identities can map to one `OnboardingSession`

### Session isolation
- OpenClaw config: `session.dmScope: "per-channel-peer"` ensures each sender gets their own isolated conversation.
- Rails: `IdentityResolver` maps `(channel_type, channel_user_id)` → `OnboardingSession`.

**Impact:** Schema expands for channel identity. Session lookup adds a new resolution path (by channel identity, not just phone number).

---

## 4) Integration Layer (OpenClaw → Rails)

### Webhook-based (primary)
- OpenClaw fires `POST /api/openclaw/turn` with signed token, sender identity, message body.
- Rails verifies token (`OPENCLAW_HOOKS_TOKEN`), resolves identity, calls `TurnProcessor`, returns response.
- OpenClaw delivers the response on the originating channel.

### Rails → OpenClaw (optional)
- For proactive sends from Rails (e.g. admin-triggered nudge), Rails can call OpenClaw's `POST /hooks/agent` endpoint.
- Primary proactive behavior lives in OpenClaw's heartbeat (P7-005).

### Idempotency
- OpenClaw provides `sessionKey` and message IDs.
- `SmsEvent` unique index pattern extends to OpenClaw events.

### Failure handling
- OpenClaw retries on hook timeout (configurable).
- If Rails is unavailable, OpenClaw can return a fallback message from `AGENTS.md` instructions.
- Gateway health exposed via `openclaw status` and `openclaw doctor`.

**Impact:** New external dependency (OpenClaw daemon), but failure is isolated to non-web channels. Web chat path is unaffected.

---

## 5) Existing Twilio/Mock Path

The `Messaging::Provider` / `TwilioAdapter` / `MockAdapter` layer from P7-002 is **retained** as:
- **Test infrastructure:** `SMS_PROVIDER=mock` keeps all tests deterministic with zero OpenClaw dependency.
- **Direct SMS fallback:** If needed, the Twilio path can send SMS independently of OpenClaw.
- **`InboundProcessor` + `Webhooks::SmsController`:** Still functional for Twilio-specific webhooks.

OpenClaw and Twilio are not mutually exclusive. OpenClaw can use Twilio as a channel plugin, or the Rails Twilio path can operate independently.

---

## 6) Proactive Capabilities (P7-005)

### Heartbeat
- OpenClaw runs periodic agent turns (configurable cadence, active hours).
- Heartbeat reads `HEARTBEAT.md`, queries Rails for idle sessions, sends nudges.
- Frequency caps and quiet hours prevent spam.

### Standing orders
- OpenClaw can maintain ongoing instructions (e.g. "check for incomplete onboardings every morning").

### Hooks from external systems
- External events (e.g. HR system triggers) can wake OpenClaw via `POST /hooks/wake`.

**Impact:** Onboarding becomes proactive, not just reactive. This is a behavioral shift, not an architectural one.

---

## 7) Compliance and Safety

### Retained from P7-001/003
- Explicit opt-in before any outbound messaging.
- STOP/HELP/START keyword handling.
- Audit trail via `SmsEvent` / message metadata.

### OpenClaw-specific
- `channels.*.allowFrom` / pairing restricts who can message the bot.
- `session.dmScope: "per-channel-peer"` prevents cross-user context leakage.
- `AGENTS.md` boundaries prevent off-topic responses.
- Hook token auth prevents unauthorized callers.

---

## 8) Concurrency and Consistency

### Retained
- `TurnProcessor` session lock (`session.with_lock`) prevents interleaved turns regardless of source.
- Idempotent inbound processing via unique event IDs.

### New consideration
- Web chat and OpenClaw can both target the same session. The lock ensures serialization.
- OpenClaw's `queue` mode (steer/followup/collect) handles its own message ordering.

---

## 9) Observability

### Add tracing dimensions
- `channel_type` (whatsapp, telegram, discord, webchat, sms, web)
- `source` (action_cable, openclaw_hook, twilio_webhook)
- `delivery_status`, `provider_latency`

### Product metrics
- Channel distribution (% of sessions by channel)
- Completion rate by channel
- Proactive nudge success rate (nudge → resumed)
- Reactivation rate (idle → completed after nudge)

---

## 10) Rollout Plan (Revised)

1. **P7-001 through P7-003** ✅ — Foundation (phone/consent, adapters, `TurnProcessor`, formatter).
2. **P7-004** — OpenClaw gateway setup, channel config, hook integration, identity resolution.
3. **P7-005** — Heartbeat, proactive nudges, compliance controls, feature flags, runbook.
4. **P7-006** — Admin dashboard: journey drill-down, channel analytics, completion outcomes.

Feature flags (`OPENCLAW_ENABLED`, `PROACTIVE_NUDGE_ENABLED`) allow staged rollout.

---

## Net Architectural Assessment

OpenClaw integration is a **gateway-layer addition** that:
- Preserves the **existing web chat path** unchanged.
- Preserves the **existing Twilio/mock path** as fallback and test infrastructure.
- Adds **multi-channel ingress** via OpenClaw webhook → `TurnProcessor`.
- Adds **proactive behavior** via heartbeat — a net-new capability.
- Keeps **all onboarding logic in Rails** — OpenClaw is transport + persona, not business logic.

The architecture stays layered: OpenClaw → Rails API → `TurnProcessor` → `Orchestrator` → LLM/Tools → response → OpenClaw → user's channel.
