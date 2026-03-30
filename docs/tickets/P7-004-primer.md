# P7-004 — OpenClaw gateway integration (agent, channels, hooks → Rails)

**Priority:** P7  
**Estimate:** 6 hours  
**Phase:** 7 — Omnichannel Continuity  
**Status:** In progress (Rails hook + identity + tests landed; OpenClaw install/channels still manual)

---

## Goal

Integrate OpenClaw as the omnichannel agent gateway so users can interact with the onboarding assistant from WhatsApp, Telegram, Discord, SMS, or WebChat — all routing through OpenClaw's Gateway to the existing Rails `TurnProcessor` and orchestrator. OpenClaw owns channel connectivity, session routing, and message delivery; Rails owns onboarding state, tools, and persistence.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P7-004 |
|--------|----------------------|
| **P7-001** | Phone/channel identity capture and consent |
| **P7-002** | `Messaging::Provider` interface and webhook patterns |
| **P7-003** | `TurnProcessor` as single entry point for all channels |

---

## Context: What is OpenClaw?

OpenClaw is a self-hosted AI agent gateway ([docs.openclaw.ai](https://docs.openclaw.ai/)). It runs as a daemon, connects to 20+ chat channels simultaneously, manages per-sender sessions, provides persistent memory, and supports proactive outreach via heartbeats. It is **not** an SMS API — it is the orchestration/routing layer that sits between users on any channel and our Rails backend.

**Integration model:** OpenClaw receives user messages on any channel → fires a webhook (`POST /hooks/agent`) to our Rails app → Rails processes the turn via `TurnProcessor` → returns the response → OpenClaw delivers it on the originating channel.

---

## Deliverables Checklist

### 1. OpenClaw Gateway setup
- [ ] Install OpenClaw on dev/staging machine (`npm install -g openclaw@latest && openclaw onboard`)
- [ ] Create onboarding agent workspace at `~/.openclaw/workspace-credal-onboarding/`
- [ ] Write `AGENTS.md` — onboarding assistant operating instructions (role, boundaries, step awareness)
- [ ] Write `SOUL.md` — Credal brand persona, tone, compliance language
- [ ] Write `USER.md` — template for per-user context
- [ ] Configure `~/.openclaw/openclaw.json` with channel accounts and bindings

### 2. Channel configuration (at least 2 for demo)
- [ ] WhatsApp or Telegram account connected and bound to onboarding agent
- [ ] WebChat enabled (Gateway built-in, no external account needed)
- [ ] `session.dmScope: "per-channel-peer"` for per-user isolation
- [ ] `channels.*.allowFrom` / pairing configured for safety

### 3. Hook integration (OpenClaw → Rails)
- [ ] Enable `hooks` in OpenClaw config with signed token
- [x] Rails endpoint: `POST /api/openclaw/turn` — accepts hook payload, maps channel identity to `OnboardingSession`, calls `TurnProcessor`, returns response
- [x] `Api::OpenclawTurnsController` with token verification (`OPENCLAW_HOOKS_TOKEN`)
- [x] Channel identity resolution: map OpenClaw's `(channel, senderId)` → `OnboardingSession` (by phone or `channel_type` + `channel_user_id`)
- [x] Auto-create session if new sender (with channel metadata)
- [x] Idempotency: message ID (`message_id` / `external_id`) → `SmsEvent` dedupe (see `docs/guides/openclaw-integration.md`)

### 4. Rails → OpenClaw (optional, for proactive sends)
- [ ] Helper to call OpenClaw's Gateway API (`POST /hooks/agent`) for proactive outreach from Rails (e.g. "You haven't finished onboarding — want to continue?")
- [ ] Or: rely on OpenClaw heartbeat for proactive behavior (see P7-005)

### 5. Channel identity mapping
- [x] Migration: add `channel_user_id` and `channel_type` to `onboarding_sessions` (or a join table `channel_identities`)
- [x] `Messaging::IdentityResolver` service: given `(channel, sender_id)` → find or create session
- [ ] Support identity linking: same user on WhatsApp + web = same onboarding session (phone link implemented; web↔channel merge still product-defined)

### 6. Environment configuration
- [x] `OPENCLAW_HOOKS_TOKEN` in `.env.example` (shared secret for hook auth)
- [x] `OPENCLAW_GATEWAY_URL` in `.env.example` (for optional Rails → OpenClaw calls)
- [x] Document OpenClaw config in `docs/guides/openclaw-integration.md`

### 7. Tests
- [x] Controller test: `POST /api/openclaw/turn` with valid/invalid token
- [x] Identity resolution tests: new sender creates session, returning sender resumes
- [x] Controller stubs `TurnProcessor` (deterministic; full stack hook test optional)
- [ ] Mock adapter still works for CI (no OpenClaw dependency in test suite) — run full `rails test` before merge

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | User messages on WhatsApp/Telegram → response from onboarding assistant | Manual: send message on connected channel, receive onboarding reply |
| 2 | Same user, same onboarding step across channels | Send on WhatsApp, continue on Telegram, verify same `current_step` |
| 3 | New sender auto-creates onboarding session | First message from unknown number → new session created |
| 4 | Hook auth rejects invalid token | Curl with bad token → 401 |
| 5 | Existing Twilio/mock fallback path still works | `SMS_PROVIDER=mock` tests pass unchanged |
| 6 | OpenClaw Gateway dashboard shows session activity | Open `openclaw dashboard`, verify chat history |

---

## OpenClaw Configuration Reference

```json5
// ~/.openclaw/openclaw.json
{
  agents: {
    list: [{
      id: "onboarding",
      default: true,
      name: "Credal Onboarding",
      workspace: "~/.openclaw/workspace-credal-onboarding",
    }],
  },
  session: {
    dmScope: "per-channel-peer",  // isolate by channel + sender
  },
  hooks: {
    enabled: true,
    token: "${OPENCLAW_HOOKS_TOKEN}",
    path: "/hooks",
    defaultSessionKey: "hook:onboarding",
  },
  channels: {
    whatsapp: {
      dmPolicy: "pairing",
      // allowFrom: ["+15551234567"],  // restrict for safety
    },
    telegram: {
      accounts: {
        default: { botToken: "${TELEGRAM_BOT_TOKEN}" },
      },
    },
  },
  // heartbeat config goes in P7-005
}
```

---

## Architecture

```
User (WhatsApp / Telegram / WebChat / Discord / ...)
    │
    ▼
OpenClaw Gateway (daemon)
    │  session routing, per-sender isolation, memory
    │
    POST /hooks/agent  ──────►  Rails API
    │                           │
    │                    Api::OpenclawTurnsController
    │                           │
    │                    IdentityResolver (channel+sender → session)
    │                           │
    │                    TurnProcessor.process(session:, body:, channel:)
    │                           │
    │                    Orchestrator → LLM → Tools → ChannelFormatter
    │                           │
    ◄── response ──────────────┘
    │
    ▼
OpenClaw delivers reply on originating channel
```

The existing **web chat** path (`/onboarding` → Action Cable → `TurnProcessor`) remains unchanged. OpenClaw adds all other channels as a parallel ingress.

---

## Files You Should READ Before Coding

1. `app/services/onboarding/turn_processor.rb` — the entry point OpenClaw will call
2. `app/controllers/webhooks/sms_controller.rb` — existing webhook pattern to follow
3. `app/services/messaging/inbound_processor.rb` — existing inbound processing pattern
4. `app/models/onboarding_session.rb` — session fields, identity resolution
5. OpenClaw docs: [Webhooks](https://docs.openclaw.ai/automation/webhook), [Gateway Architecture](https://docs.openclaw.ai/concepts/architecture), [Multi-Agent](https://docs.openclaw.ai/concepts/multi-agent), [Session Management](https://docs.openclaw.ai/concepts/session)

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated
- [ ] Feature branch pushed; PR ready

---

## Suggested Branch

```bash
git switch -c feature/P7-004-openclaw-gateway
```
