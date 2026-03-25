# P6-001 — Production deployment

**Priority:** P6
**Estimate:** 4 hours
**Phase:** 6 — Launch
**Status:** Not started

---

## Goal

Deploy the Credal onboarding assistant to a production hosting platform (Render, Fly.io, or Heroku) with PostgreSQL, Redis (Action Cable + Sidekiq), SSL, and all environment variables configured. The app should be accessible via a public URL with zero-downtime deploys from the `main` branch.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P6-001 |
|--------|----------------------|
| **P1-002** | Core onboarding flow must work end-to-end |
| **P5-001** | Eval suite should pass before deploying |

---

## Deliverables Checklist

- [ ] Platform selected and account created (Render recommended for simplicity; Fly.io for WebSocket performance)
- [ ] Production PostgreSQL database provisioned
- [ ] Production Redis instance provisioned (for Action Cable and Sidekiq)
- [ ] `config/environments/production.rb` reviewed and hardened (force_ssl, log level, asset host)
- [ ] `config/cable.yml` production adapter set to `redis` with `REDIS_URL`
- [ ] `Procfile` for production: `web`, `worker` (Sidekiq), `release` (db:migrate)
- [ ] All environment variables configured on platform: `SECRET_KEY_BASE`, `DATABASE_URL`, `REDIS_URL`, `OPENAI_API_KEY`, `OPENAI_MODEL`, `LANGSMITH_API_KEY`, `LANGSMITH_PROJECT`
- [ ] SSL/TLS enabled (platform-managed or Let's Encrypt)
- [ ] Custom domain configured (optional, but document the process)
- [ ] `bin/render-build.sh` or equivalent build script: `bundle install`, `rails assets:precompile`, `rails db:migrate`
- [ ] Health check endpoint: `GET /health` returns 200 with `{ status: "ok" }`
- [ ] Smoke test after deploy: landing page loads, chat connects via WebSocket, LLM responds
- [ ] `docs/ops/deployment.md` — deployment guide with platform setup, env vars, troubleshooting

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | App accessible via public HTTPS URL | Visit URL in browser |
| 2 | Landing page renders correctly | Check `/` loads with styles and CTA |
| 3 | Chat WebSocket connects and LLM responds | Go to `/onboarding`, send a message, receive streaming response |
| 4 | Database persists across deploys | Create a session, redeploy, session still exists |
| 5 | Health check returns 200 | `curl https://app-url/health` |
| 6 | Logs accessible via platform dashboard | Check platform log viewer |
| 7 | Zero-downtime deploy from `main` | Push to main, verify app stays up during deploy |

---

## Architecture

### Platform comparison

| Feature | Render | Fly.io | Heroku |
|---------|--------|--------|--------|
| Free tier | Yes (with limits) | Yes (with limits) | Eco dynos ($5/mo) |
| WebSocket support | Yes | Yes (native) | Yes |
| Managed Postgres | Yes | Yes | Yes |
| Managed Redis | Yes | Yes (Upstash) | Yes (add-on) |
| Auto-deploy from GitHub | Yes | Yes (via Actions) | Yes |
| SSL | Auto | Auto | Auto |

### Environment variables

```bash
# Required
SECRET_KEY_BASE=<generate with `rails secret`>
DATABASE_URL=<provided by platform>
REDIS_URL=<provided by platform>
OPENAI_API_KEY=<your key>
OPENAI_MODEL=gpt-4o
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true

# Optional
LANGSMITH_API_KEY=<your key>
LANGSMITH_PROJECT=credal-onboarding-prod
EVAL_PASS_THRESHOLD=85
```

### Health check endpoint

```ruby
# config/routes.rb
get '/health', to: proc { [200, { 'Content-Type' => 'application/json' }, ['{"status":"ok"}']] }
```

### Production Procfile

```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq
release: bundle exec rails db:migrate
```

### New files

| File | Purpose |
|------|---------|
| `Procfile` | Production process definitions |
| `bin/render-build.sh` | Build script for Render (or equivalent) |
| `docs/ops/deployment.md` | Deployment guide |

### Modified files

| File | Changes |
|------|---------|
| `config/environments/production.rb` | Force SSL, log to STDOUT, asset host |
| `config/cable.yml` | Redis adapter for production |
| `config/routes.rb` | Health check endpoint |
| `config/puma.rb` | Production worker/thread config |

---

## Files You Should READ Before Coding

1. `config/environments/production.rb` — current production config
2. `config/cable.yml` — Action Cable adapter config
3. `config/puma.rb` — Puma server config
4. `Gemfile` — ensure `pg` and `redis` gems are present
5. `config/database.yml` — database URL config

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P6-001 entry
- [ ] Production URL documented in DEVLOG and README

---

## Suggested Branch

```bash
git switch -c feature/P6-001-production-deploy
```

---

## Out of Scope for P6-001

- CI/CD pipeline beyond auto-deploy from main (GitHub Actions is P5-005)
- Monitoring/alerting (Sentry, Datadog)
- Auto-scaling configuration
- CDN setup for assets
