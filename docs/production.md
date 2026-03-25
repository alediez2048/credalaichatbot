# Production & Deployment Plan

## Platform Recommendation: Render

**Why Render over alternatives:**

| Platform | Pros | Cons | Verdict |
|----------|------|------|---------|
| **Render** | Native Rails support, managed Postgres + Redis, free tier, auto-deploy from GitHub, WebSocket support, zero Dockerfile needed | Cold starts on free tier | **Best fit** |
| Fly.io | Fast deploys, global edge, Docker-native | More config overhead, CLI-heavy, Redis requires separate setup | Good but more work |
| Railway | Simple UI, quick deploys | Smaller community, less Rails-specific docs | Decent alternative |
| Heroku | Classic Rails home | Expensive since free tier removal, slow deploys | Overpriced for demos |
| AWS/GCP | Full control | Massive overkill for a demo app | No |

**Render wins because:**
- One-click Rails deploys with `render.yaml` (infrastructure-as-code)
- Managed PostgreSQL and Redis included (both required by this app)
- Native WebSocket support (critical for Action Cable streaming)
- Free tier sufficient for demo — paid starter ($7/mo) eliminates cold starts
- Auto-deploy on push to `main`
- Build command + start command = no Dockerfile required

---

## Architecture in Production

```
                    ┌─────────────────────────────────┐
                    │          Render Platform         │
                    │                                  │
  Browser ────────► │  ┌──────────────────────────┐   │
                    │  │  Web Service (Puma)       │   │
                    │  │  - Rails 7.2              │   │
                    │  │  - Serves HTML/JS/CSS     │   │
                    │  │  - REST API               │   │
  WebSocket ──────► │  │  - Action Cable (WS)      │   │
                    │  └──────────┬───────┬────────┘   │
                    │             │       │            │
                    │  ┌──────────▼──┐ ┌──▼─────────┐ │
                    │  │ PostgreSQL  │ │   Redis     │ │
                    │  │ (managed)   │ │  (managed)  │ │
                    │  └─────────────┘ └──────┬──────┘ │
                    │                         │        │
                    │  ┌──────────────────────▼──────┐ │
                    │  │  Background Worker (Sidekiq)│ │
                    │  └─────────────────────────────┘ │
                    └─────────────────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │     External Services      │
                    │  - OpenAI API (GPT-4o)     │
                    │  - LangSmith (tracing)     │
                    └───────────────────────────┘
```

---

## Services Required

| Service | Render Type | Plan | Monthly Cost |
|---------|------------|------|-------------|
| Rails + Puma + Action Cable | Web Service | Starter ($7) or Free | $0–$7 |
| PostgreSQL | Managed Database | Free (90 days) or Starter ($7) | $0–$7 |
| Redis | Managed Redis | Free (25MB) or Starter ($10) | $0–$10 |
| Sidekiq | Background Worker | Starter ($7) or Free | $0–$7 |
| **Total** | | | **$0–$31/mo** |

> For a demo, the free tier works. For a reliable demo without cold starts, the Starter tiers (~$31/mo) are worth it.

---

## render.yaml (Infrastructure as Code)

This file goes in the repo root and Render reads it to provision everything:

```yaml
databases:
  - name: onboarding-db
    plan: free
    databaseName: onboarding_assistant_production
    user: onboarding

services:
  - type: redis
    name: onboarding-redis
    plan: free
    maxmemoryPolicy: allkeys-lru
    ipAllowList: []

  - type: web
    name: onboarding-assistant
    runtime: ruby
    plan: free
    rootDir: backend
    buildCommand: |
      bundle install &&
      npm install &&
      npm run build &&
      npm run build:css &&
      bundle exec rails assets:precompile &&
      bundle exec rails db:migrate
    startCommand: bundle exec puma -C config/puma.rb
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: onboarding-db
          property: connectionString
      - key: REDIS_URL
        fromService:
          name: onboarding-redis
          type: redis
          property: connectionString
      - key: RAILS_ENV
        value: production
      - key: RAILS_SERVE_STATIC_FILES
        value: "true"
      - key: RAILS_LOG_TO_STDOUT
        value: "true"
      - key: SECRET_KEY_BASE
        generateValue: true
      - key: OPENAI_API_KEY
        sync: false  # set manually in dashboard
      - key: OPENAI_MODEL
        value: gpt-4o
      - key: LANGSMITH_API_KEY
        sync: false  # set manually in dashboard
      - key: LANGSMITH_PROJECT
        value: credal-onboarding-prod
      - key: LANGSMITH_ENDPOINT
        value: https://api.smith.langchain.com

  - type: worker
    name: onboarding-worker
    runtime: ruby
    plan: free
    rootDir: backend
    buildCommand: bundle install
    startCommand: bundle exec sidekiq
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: onboarding-db
          property: connectionString
      - key: REDIS_URL
        fromService:
          name: onboarding-redis
          type: redis
          property: connectionString
      - key: RAILS_ENV
        value: production
      - key: SECRET_KEY_BASE
        generateValue: true
      - key: OPENAI_API_KEY
        sync: false
      - key: LANGSMITH_API_KEY
        sync: false
```

---

## Deployment Steps

### First-Time Setup

1. **Push code to GitHub** (if not already)
   ```bash
   git remote add origin https://github.com/<you>/credal-onboarding.git
   git push -u origin main
   ```

2. **Create Render account** at [render.com](https://render.com)

3. **Connect GitHub repo** — Render auto-detects `render.yaml`

4. **Set secret env vars** in Render dashboard:
   - `OPENAI_API_KEY` — your OpenAI key
   - `LANGSMITH_API_KEY` — your LangSmith key (optional, tracing works without it)

5. **Deploy** — Render runs the build command, migrates DB, starts Puma

6. **Verify:**
   - Hit `https://onboarding-assistant.onrender.com/` — landing page loads
   - Navigate to `/onboarding` — chat renders, WebSocket connects
   - Send a message — streaming response arrives via Action Cable

### Subsequent Deploys

Push to `main` → Render auto-deploys. Zero config.

```bash
git push origin main  # triggers deploy
```

---

## Production Checklist

### Before First Deploy

- [ ] Add `render.yaml` to repo root
- [ ] Ensure `config/environments/production.rb` has:
  - `config.force_ssl = true`
  - `config.action_cable.allowed_request_origins = ["https://onboarding-assistant.onrender.com"]`
- [ ] Set `config.action_cable.url` in production to use `wss://` protocol
- [ ] Verify `SECRET_KEY_BASE` is set (Render auto-generates it)
- [ ] Add `RAILS_SERVE_STATIC_FILES=true` (no nginx in front of Puma on Render)
- [ ] Confirm `database.yml` production block uses `DATABASE_URL`
- [ ] Run `rails assets:precompile` in build step (included in render.yaml above)

### Security

- [ ] `force_ssl` enabled in production
- [ ] CORS / Action Cable origins locked to production domain
- [ ] API keys stored as Render env vars (never in repo)
- [ ] Rate limiting active (P1-006)
- [ ] PII handling compliant (P2-004)

### Performance

- [ ] Puma workers: set `WEB_CONCURRENCY=2` for Render Starter (512MB RAM)
- [ ] Sidekiq concurrency: `SIDEKIQ_CONCURRENCY=5` (default, fine for demo)
- [ ] Redis maxmemory-policy: `allkeys-lru` (set in render.yaml)
- [ ] Enable gzip: `config.middleware.use Rack::Deflater`

---

## Demo Strategy

### Shareable URL

Once deployed, the app is live at:
```
https://onboarding-assistant.onrender.com
```

> Rename via Render dashboard or add a custom domain.

### Demo Flow (for P6-002 video)

1. **Landing page** — show the value prop, click "Start Onboarding"
2. **Chat interaction** — demonstrate:
   - Natural conversation flow
   - Real-time streaming responses
   - Tool calls (state management, document handling)
   - Graceful error handling
3. **Document upload** (P2) — show OCR + field extraction
4. **Scheduling** (P3) — book an appointment through chat
5. **Observability** — switch to LangSmith dashboard, show traces
6. **Cost report** — reference P6-004 analysis

### Cold Start Mitigation (Free Tier)

Free Render services spin down after 15 min of inactivity. Options:
- **Upgrade to Starter** ($7/mo) — always on
- **Ping before demo** — hit the URL 30 seconds before presenting
- **Use a cron ping** — free services like UptimeRobot can keep it warm

---

## Environment Variable Reference

| Variable | Required | Where to Set | Notes |
|----------|----------|-------------|-------|
| `DATABASE_URL` | Yes | Auto (render.yaml) | Managed Postgres connection string |
| `REDIS_URL` | Yes | Auto (render.yaml) | Managed Redis connection string |
| `SECRET_KEY_BASE` | Yes | Auto (render.yaml) | Auto-generated |
| `RAILS_ENV` | Yes | render.yaml | `production` |
| `RAILS_SERVE_STATIC_FILES` | Yes | render.yaml | `true` (no nginx) |
| `OPENAI_API_KEY` | Yes | Dashboard (secret) | OpenAI API key |
| `OPENAI_MODEL` | No | render.yaml | Default: `gpt-4o` |
| `LANGSMITH_API_KEY` | No | Dashboard (secret) | Tracing works without it (no-op) |
| `LANGSMITH_PROJECT` | No | render.yaml | Project name in LangSmith |
| `WEB_CONCURRENCY` | No | Dashboard | Puma workers (2 for 512MB) |
| `RAILS_MAX_THREADS` | No | Dashboard | Puma threads per worker (default 5) |

---

## Timeline

| When | What |
|------|------|
| **After P5 complete** | Create `render.yaml`, test deploy |
| **P6-001** | Production deploy, verify all features work |
| **P6-002** | Record 3-5 min demo video using production URL |
| **P6-003** | Polish README, add screenshots |
| **P6-004** | AI cost analysis from LangSmith + OpenAI usage |
| **P6-005** | Share launch post with live link |

---

## Rollback & Monitoring

- **Render auto-rollback:** if health check fails, Render keeps the previous deploy running
- **Manual rollback:** Render dashboard → Deploys → click "Rollback" on any previous deploy
- **Logs:** `render logs` CLI or dashboard log viewer (real-time)
- **Health check:** Add `GET /up` endpoint (Rails 7.2 includes this by default)
- **LangSmith:** All LLM calls traced — latency, tokens, errors visible in dashboard
