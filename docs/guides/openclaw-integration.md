# OpenClaw Integration Guide

How the Credal onboarding assistant integrates with [OpenClaw](https://docs.openclaw.ai/) as the omnichannel agent gateway.

---

## What OpenClaw Does (and Doesn't Do)

OpenClaw is a **self-hosted AI agent gateway** that connects 20+ chat channels (WhatsApp, Telegram, Discord, Slack, iMessage, WebChat, SMS via plugins, and more) to an AI agent runtime. It runs as a daemon process.

**OpenClaw handles:**
- Receiving messages from users on any connected channel
- Per-sender session isolation and routing
- Persistent memory across conversations
- Proactive outreach via heartbeats (periodic agent turns)
- Message delivery back to the originating channel

**Rails handles:**
- Onboarding state machine and step progression (`Orchestrator`)
- Tool execution (save progress, extract documents, book appointments)
- Data persistence (sessions, messages, documents, bookings, audit)
- LLM calls (GPT-4o via `ChatService`)
- Admin dashboard and analytics

**OpenClaw is NOT a messaging API you call.** It's the reverse: OpenClaw receives messages and calls your Rails app via webhooks.

---

## Architecture

```
User (WhatsApp / Telegram / Discord / WebChat / SMS / ...)
    │
    ▼
OpenClaw Gateway (daemon on your machine or server)
    │  per-sender sessions, memory, heartbeat
    │
    │  POST /api/openclaw/turn  ──►  Rails App
    │  (webhook with signed token)    │
    │                                 Api::OpenclawTurnsController
    │                                 │
    │                                 IdentityResolver
    │                                 (channel + sender → OnboardingSession)
    │                                 │
    │                                 TurnProcessor.process(...)
    │                                 (session lock → Orchestrator → LLM → tools)
    │                                 │
    │  ◄── JSON response ───────────┘
    │
    ▼
OpenClaw delivers reply on originating channel


Parallel path (unchanged):
    Browser → /onboarding → Action Cable → TurnProcessor → stream response
```

---

## Setup Steps

### 1. Install OpenClaw

```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

Requires Node 22+ (24 recommended). See [Getting Started](https://docs.openclaw.ai/start/getting-started).

### 2. Create the Onboarding Agent Workspace

```bash
openclaw agents add credal-onboarding
```

This creates `~/.openclaw/workspace-credal-onboarding/`. Populate the workspace files:

**`AGENTS.md`** — Operating instructions:
```markdown
# Credal Onboarding Assistant

You are an onboarding assistant for Credal.ai. Guide new employees through:
1. Welcome and introduction
2. Personal information collection
3. Document upload and verification
4. Orientation scheduling
5. Review and completion

Rules:
- Stay on-topic. Do not answer questions outside onboarding.
- When the user provides information, call the Rails turn endpoint to persist it.
- Keep messages concise for mobile channels (under 500 chars).
- Include "Reply STOP to opt out" in first message to new users.
```

**`SOUL.md`** — Persona:
```markdown
# Persona

Name: Credal Onboarding Bot
Tone: Warm, professional, concise. Credal brand voice.
Boundaries: Never discuss salary, internal politics, or non-onboarding topics.
Compliance: Reference SOC 2, HIPAA where relevant. Never include PII in logs.
```

**`HEARTBEAT.md`** — Proactive behavior (see P7-005):
```markdown
# Heartbeat checklist

- Check Rails API for idle onboarding sessions (GET /api/admin/idle_sessions)
- For each idle user: send a gentle nudge on their last-used channel
- Max 1 nudge per user per 24 hours
- If nothing needs attention, reply HEARTBEAT_OK
```

### 3. Configure the Gateway

Edit `~/.openclaw/openclaw.json`:

```json5
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
    dmScope: "per-channel-peer",
  },

  hooks: {
    enabled: true,
    token: "${OPENCLAW_HOOKS_TOKEN}",  // must match Rails OPENCLAW_HOOKS_TOKEN
    path: "/hooks",
    defaultSessionKey: "hook:onboarding",
  },

  agents: {
    defaults: {
      heartbeat: {
        every: "1h",
        target: "last",
        activeHours: { start: "09:00", end: "21:00" },
        lightContext: true,
        isolatedSession: true,
      },
    },
  },

  channels: {
    // Connect at least one channel for demo
    telegram: {
      accounts: {
        default: { botToken: "${TELEGRAM_BOT_TOKEN}" },
      },
      dmPolicy: "pairing",
    },
    // WhatsApp requires QR pairing:
    // whatsapp: { dmPolicy: "pairing" },
  },
}
```

### 4. Connect a Channel

**Telegram (fastest setup):**
1. Create a bot via [@BotFather](https://t.me/botfather)
2. Copy the token into `openclaw.json` (or `TELEGRAM_BOT_TOKEN` env var)
3. Restart gateway: `openclaw gateway restart`

**WhatsApp:**
```bash
openclaw channels login --channel whatsapp
# Scan the QR code with your phone
```

See [Channels docs](https://docs.openclaw.ai/channels) for all options.

### 5. Configure Rails

Add to `backend/.env`:
```
# OpenClaw integration (P7-004+)
OPENCLAW_HOOKS_TOKEN=your-shared-secret-here
OPENCLAW_GATEWAY_URL=http://127.0.0.1:18789
OPENCLAW_ENABLED=true
PROACTIVE_NUDGE_ENABLED=true
```

The Rails endpoint (`POST /api/openclaw/turn`) will:
1. Verify the hook token
2. Resolve channel identity → `OnboardingSession`
3. Call `TurnProcessor.process(session:, body:, channel:)`
4. Return the response as JSON for OpenClaw to deliver

#### Hook request and response (Rails contract)

**URL:** `POST /api/openclaw/turn`  
**Content-Type:** `application/json`

**Authentication** (use one of):

- `X-Openclaw-Token: <OPENCLAW_HOOKS_TOKEN>`
- `Authorization: Bearer <OPENCLAW_HOOKS_TOKEN>`
- JSON field `token` (acceptable for local curl; prefer headers in production)

**JSON body:**

| Field | Required | Description |
|-------|----------|-------------|
| `text` | Yes | User message body |
| `channel` | Yes | Channel type (e.g. `telegram`, `whatsapp`); stored as `OnboardingSession#channel_type` |
| `sender_id` | Yes | Stable sender id from the gateway |
| `message_id` or `external_id` | No | Idempotency key; duplicate inbound is detected via `SmsEvent` (`provider: openclaw`, unique `external_id`) |
| `phone_number` | No | Optional; if present, may link to the latest opted-in SMS session with the same normalized number |

**Success (200):**

```json
{ "reply": "…", "step_changed": false, "error": null }
```

When the orchestrator returns an error category, `error` is set to that category string; `reply` is the user-facing (possibly truncated) message.

**Duplicate delivery (200):** Same `message_id` / `external_id` as a prior inbound event:

```json
{ "reply": "…", "duplicate": true }
```

The `reply` is the first assistant message recorded after the original inbound event (best-effort replay).

**Other responses:** `401` invalid token, `404` when `OPENCLAW_ENABLED` is false, `422` missing/invalid body, `503` when OpenClaw is enabled but `OPENCLAW_HOOKS_TOKEN` is blank.

### 6. Start the Gateway

```bash
openclaw gateway        # foreground with logs
# or
openclaw dashboard      # open the web control UI
```

Default dashboard: http://127.0.0.1:18789/

### 7. Verify

```bash
openclaw status         # gateway health
openclaw channels status --probe  # channel connectivity
```

Send a message on the connected channel. You should see:
1. Message appears in OpenClaw dashboard
2. OpenClaw calls your Rails endpoint
3. Rails processes via `TurnProcessor`
4. Response delivered back on the channel

---

## Multiple projects on one machine (avoid collisions)

OpenClaw keeps **one default** state tree under `~/.openclaw/`. If you onboard or change `agents.defaults.workspace` without isolating profiles, **the last change wins** and you can point the default agent at the wrong repo.

### Use a named profile per project

The CLI documents:

- **`openclaw --profile <name> …`** — isolates `OPENCLAW_STATE_DIR` / `OPENCLAW_CONFIG_PATH` under **`~/.openclaw-<name>/`** (separate `openclaw.json`, agents, sessions, channels).
- **`openclaw --dev …`** — second isolated tree under `~/.openclaw-dev/` with default gateway port **19001** (handy for two setups, not three).

**Suggested layout**

| Project | Profile name | Config dir | Gateway port (example) | Workspace |
|---------|--------------|------------|-------------------------|-----------|
| Credal | `credal` | `~/.openclaw-credal/` | `18790` | e.g. repo path or `~/…/Credal.ai/openclaw-workspace` |
| Opendoor | `opendoor` | `~/.openclaw-opendoor/` | `18789` | Opendoor’s `openclaw` folder |
| Other | `myapp` | `~/.openclaw-myapp/` | `18791` | That app’s workspace |

Give each profile a **different `gateway.port`** so two gateways can run at once if you ever need that.

### Credal-specific

1. Prefer **`openclaw --profile credal onboard`** (or `setup` / `configure`) so Credal never touches `~/.openclaw/` default.
2. Set **`OPENCLAW_GATEWAY_URL`** in `backend/.env` to the **Credal** gateway, e.g. `http://127.0.0.1:18790` if Credal uses port 18790.
3. **`OPENCLAW_HOOKS_TOKEN`** is **per Rails app**, not global: Credal’s `.env` token only needs to match whatever outbound hook config you use **for the Credal agent** in that profile’s config (and any automation that POSTs to `/api/openclaw/turn`). Other projects use their own Rails URLs and tokens.

### macOS LaunchAgent / one daemon

`openclaw doctor` / `gateway install` typically installs **one** gateway service (e.g. `ai.openclaw.gateway`). That service usually reflects **one** profile/config. For multiple projects:

- **Simplest:** Run only one gateway at a time — `openclaw gateway stop`, then `openclaw --profile credal gateway start` (foreground or install for that profile when you’re working on Credal).
- **Parallel:** Run a second gateway on another port in another terminal with **`openclaw --profile <other> gateway start --port <port>`** (confirm no port clash with the first).

Always know **which profile** is active when you run `channels`, `onboard`, or `dashboard`.

---

## Environment Variables

### Rails (`backend/.env`)

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENCLAW_HOOKS_TOKEN` | Yes (P7-004) | Shared secret for hook auth |
| `OPENCLAW_GATEWAY_URL` | Optional | Gateway URL for Rails → OpenClaw calls (default: `http://127.0.0.1:18789`) |
| `OPENCLAW_ENABLED` | Optional | Feature flag (default: `false`) |
| `PROACTIVE_NUDGE_ENABLED` | Optional | Enable heartbeat nudges (default: `false`) |
| `SMS_PROVIDER` | Existing | Keep `mock` for tests. Twilio path is independent fallback. |

### OpenClaw (`~/.openclaw/openclaw.json` or env)

| Variable | Description |
|----------|-------------|
| `OPENCLAW_HOOKS_TOKEN` | Must match Rails token |
| `TELEGRAM_BOT_TOKEN` | Telegram channel (if used) |

---

## Testing Strategy

OpenClaw is **not** in the Rails test suite. Tests remain deterministic:

| Layer | How to test |
|-------|-------------|
| `TurnProcessor` | Existing unit/integration tests (no OpenClaw dependency) |
| `Api::OpenclawTurnsController` | Controller test: POST with valid/invalid token, verify `TurnProcessor` called |
| `IdentityResolver` | Unit test: channel+sender → session lookup/creation |
| OpenClaw → Rails end-to-end | Manual: send message on channel, verify response |
| Heartbeat / proactive | Manual: let session idle, verify nudge delivered |

The `SMS_PROVIDER=mock` path and all existing tests are unaffected.

---

## Relationship to Existing P7 Code

| Existing code | Role with OpenClaw |
|---------------|-------------------|
| `Messaging::Provider` / `TwilioAdapter` / `MockAdapter` | **Fallback path** for direct SMS. Independent of OpenClaw. |
| `Webhooks::SmsController` | Twilio-specific webhook. OpenClaw uses a separate endpoint. |
| `InboundProcessor` | Twilio inbound processing. OpenClaw uses `Api::OpenclawTurnsController`. |
| `TurnProcessor` | **Shared entry point.** Both Action Cable (web) and OpenClaw hook call this. |
| `ChannelFormatter` | Still used for formatting (truncation for non-web channels). |
| `SmsEvent` | Extended to log OpenClaw channel events (with `provider: "openclaw"`). |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Gateway won't start | `openclaw doctor` for diagnostics |
| Channel disconnected | `openclaw channels status --probe`, reconnect with `openclaw channels login` |
| Hook auth failing | Verify `OPENCLAW_HOOKS_TOKEN` matches in both OpenClaw config and Rails `.env` |
| No response from Rails | Check Rails server logs, verify endpoint is reachable from gateway host |
| WhatsApp QR expired | Re-pair: `openclaw channels login --channel whatsapp` |

See also: [OpenClaw Troubleshooting](https://docs.openclaw.ai/help/troubleshooting)
