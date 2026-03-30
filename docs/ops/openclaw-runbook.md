# OpenClaw Operations Runbook

Quick reference for operating the OpenClaw gateway alongside the Credal onboarding Rails app.

---

## Gateway Startup / Restart

```bash
# Start (foreground, with logs)
openclaw --profile credal gateway --port 18790

# Start as background service (macOS LaunchAgent)
openclaw --profile credal gateway install --port 18790
# Restart
openclaw --profile credal gateway restart
# Stop
openclaw --profile credal gateway stop
```

Adjust `--profile` and `--port` per your multi-project setup (see `docs/guides/openclaw-integration.md`).

---

## Health Check

```bash
# Gateway self-check
openclaw --profile credal status

# From Rails (requires OPENCLAW_ENABLED=true + valid hook token)
curl -s http://127.0.0.1:3000/api/admin/openclaw_status \
  -H "X-Openclaw-Token: $OPENCLAW_HOOKS_TOKEN" | jq .
```

---

## Channel Disconnection

| Channel | Symptom | Fix |
|---------|---------|-----|
| Telegram | Bot stops receiving messages | Check token: `openclaw --profile credal channels status --probe`. Regenerate bot token in @BotFather if revoked, update `openclaw.json`. |
| WhatsApp | QR expired / session dropped | Re-pair: `openclaw --profile credal channels login --channel whatsapp` |
| Any | "plugin path not found" | Run `openclaw --profile credal doctor --fix` (stale extension paths after upgrade) |

After fixing, restart the gateway.

---

## Rails Endpoint Unavailable

If Rails is down or unreachable from the gateway host:

- OpenClaw will receive the user message but get a connection error when calling `POST /api/openclaw/turn`.
- The user sees no reply (or an OpenClaw-level error if configured).
- **Fix:** Restart or redeploy Rails, verify reachability (`curl http://127.0.0.1:3000/up`).
- OpenClaw does **not** retry failed hooks automatically; the user can resend their message.

---

## Disable Proactive Nudges (Without Stopping Gateway)

In `backend/.env`:

```
PROACTIVE_NUDGE_ENABLED=false
```

Restart Rails. The `GET /api/admin/idle_sessions` endpoint returns 404 when disabled, so the heartbeat gets no sessions to nudge.

To disable **all** OpenClaw integration (including inbound hooks):

```
OPENCLAW_ENABLED=false
```

---

## Add a New Channel

1. Configure the channel in `~/.openclaw-credal/openclaw.json` under `channels`.
2. If needed, pair or authenticate: `openclaw --profile credal channels login --channel <name>`.
3. Restart the gateway.
4. No Rails changes needed — `IdentityResolver` handles any `(channel_type, sender_id)` pair.

---

## Log Locations

| Log | Location |
|-----|----------|
| OpenClaw gateway | `~/.openclaw-credal/logs/gateway.log` (or `~/.openclaw/logs/` if using default profile) |
| Rails | `backend/log/development.log` / `production.log` |
| OpenClaw diagnostics | `openclaw --profile credal doctor` |

---

## Diagnostic Commands

```bash
openclaw --profile credal status           # gateway health + channel status
openclaw --profile credal channels status --probe  # live channel connectivity
openclaw --profile credal doctor           # full health check
openclaw --profile credal sessions list    # active sessions
openclaw --profile credal logs             # tail gateway logs
```

---

## Frequency Cap / Nudge Cooldown

- Nudge events are logged as `SmsEvent` with `direction: "outbound"` and `metadata: { nudge: true }`.
- `IdleSessionsQuery` excludes sessions that received a nudge within the cooldown window (default 24 hours).
- To change the cooldown, modify `Onboarding::IdleSessionsQuery::DEFAULT_NUDGE_COOLDOWN`.

---

## Emergency: Kill Everything

```bash
openclaw --profile credal gateway stop     # stop the service
# If that fails:
launchctl bootout gui/$(id -u) ai.openclaw.gateway 2>/dev/null
pkill -f "openclaw.*gateway" 2>/dev/null
```

Rails continues to work normally for web chat; only omnichannel inbound stops.
