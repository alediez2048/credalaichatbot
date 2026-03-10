# Onboarding Assistant — Rails backend (P0-001)

## If `bundle install` fails with "ruby (>= 3.1.0)"

You're on an older Ruby. Switch to Ruby 3.2, then run `bundle install` again:

**macOS (Homebrew):**
```bash
brew install ruby@3.2
export PATH="/opt/homebrew/opt/ruby@3.2/bin:$PATH"
ruby -v   # should show 3.2.x
# From repo root: cd backend && bundle install
# If you're already in backend/: just bundle install
bundle install
```

**Or use rbenv / asdf:** install Ruby 3.2, then `cd backend && bundle install`.

---

## Prerequisites

- **Ruby 3.1+** (3.2 recommended)
- **PostgreSQL** running locally
- **Redis** running locally (Action Cable adapter + Sidekiq)

### Install Ruby (macOS)

```bash
brew install ruby@3.2
export PATH="/opt/homebrew/opt/ruby@3.2/bin:$PATH"
```

### Or use Docker (when daemon is running)

```bash
docker run --rm -it -v "$PWD":/app -w /app -p 3000:3000 ruby:3.2 bash
gem install rails bundler
bundle install
bin/rails db:create db:migrate
bin/rails server -b 0.0.0.0
```

## Setup

```bash
cd backend
bundle install
cp .env.example .env   # edit DATABASE_* (see below)
bin/rails db:create db:migrate
```

### If `db:create` fails with "no password supplied"

Your PostgreSQL expects a username/password. Create a `.env` file (from `.env.example`) and set:

```bash
cp .env.example .env
# Edit .env and set at least:
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_postgres_password
```

If your Postgres user is your macOS username (e.g. Homebrew default), try:

```bash
DATABASE_USERNAME=your_mac_username
DATABASE_PASSWORD=
```

Then run `bin/rails db:create db:migrate` again.

## Run

**Option A — Foreman (web + redis + worker)**

```bash
# Terminal 1
redis-server

# Terminal 2
cd backend && bin/rails server
# Terminal 3
cd backend && bundle exec sidekiq
```

**Option B — `bin/dev`** (starts all via Procfile.dev; requires `redis-server` on PATH or run Redis separately)

```bash
bin/dev
```

Open http://localhost:3000 — homepage with Devise sign up / sign in.

## Action Cable

- Adapter: **Redis** in development (`config/cable.yml`).
- Ping channel: subscribe to `PingChannel` after Action Cable is wired in JS (post–`rails importmap:install` if needed).
- Verify WebSocket: browser devtools → Network → WS → `/cable`.

## Core tables

| Table | Purpose |
|-------|--------|
| `users` | Devise authentication |
| `onboarding_sessions` | Per-user or anonymous session, `current_step`, progress |
| `messages` | Chat turns (`role`: user/assistant/system/tool) |
| `documents` | Upload metadata (storage in Phase 2) |
| `extracted_fields` | OCR output + confidence |
| `bookings` | Scheduled appointments |
| `audit_logs` | Trace-linked audit events |

## Next tickets

- **P0-002** — LLM::ChatService + Tools::Router
- **P1-001** — React chat + streaming via Action Cable
