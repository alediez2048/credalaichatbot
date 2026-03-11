# P0-001 — Rails project scaffolding & database setup

**Priority:** P0  
**Phase:** 0 — Foundation  
**App root:** `backend/` (repo root holds PRD, docs, `.cursor/rules`).  
**Ruby:** 3.1+ required (`.ruby-version` recommends 3.2).

---

## Goal

Rails 7 app with PostgreSQL, Redis, Sidekiq, Action Cable, Devise. Core models: User, OnboardingSession, Message, Document, ExtractedField, Booking, AuditLog.

---

## Acceptance criteria

| Criterion | How to verify |
|-----------|----------------|
| Rails boots and serves homepage | `bin/rails server` → http://localhost:3000 shows landing and Devise links |
| Migrations run | Seven tables: users, onboarding_sessions, messages, documents, extracted_fields, bookings, audit_logs |
| Devise signup/login/logout | Sign up, sign in, sign out from nav |
| Sidekiq processes jobs | `bundle exec sidekiq` starts with Redis (no error) |
| Action Cable available | Config in `config/cable.yml`; `/cable` endpoint; full streaming in P1-001 |

---

## Step-by-step setup

Follow in order. **Project root** = folder containing `backend/` and `docs/`. Commands that say “in `backend/`” are run from the `backend` directory.

### Step 1 — Ruby 3.2

```bash
ruby -v
```

- If **3.2.x** or 3.1.x → Step 2.
- If 2.6/2.7:

```bash
brew install ruby@3.2
export PATH="/opt/homebrew/opt/ruby@3.2/bin:$PATH"
ruby -v
```

### Step 2 — PostgreSQL

```bash
psql -d postgres -c "SELECT 1"
# or: brew services list | grep postgresql
```

- **`psql` not found or `postgresql@16 none`** (Homebrew):
  - `export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"`
  - `brew services start postgresql@16`
  - `psql -d postgres -c "SELECT 1"` (username = Mac user, password often empty)
- Note **username** and **password** (if any) for Step 4.

### Step 3 — Redis

```bash
redis-cli ping
```

Expect `PONG`. If not: `brew install redis` and/or `brew services start redis`.

### Step 4 — Backend env and gems

```bash
cd backend
cp .env.example .env
```

Edit `.env`: set `DATABASE_USERNAME` (e.g. `jad`) and `DATABASE_PASSWORD` (empty if Homebrew default). Use **lowercase** username if Postgres role is lowercase.

```bash
bundle install
```

(Use Ruby 3.2 in this terminal if you get “ruby (>= 3.1.0)” from bundle.)

### Step 5 — Database

```bash
bin/rails db:create db:migrate
```

- “no password supplied” → set `DATABASE_PASSWORD` in `.env` and retry.
- “role X does not exist” → use **lowercase** `DATABASE_USERNAME` in `.env`.

Check: `bin/rails db:migrate:status` (all `up`).

### Step 6 — Run app

```bash
bin/rails server
```

Open **http://localhost:3000**. You should see the landing page and Sign up / Sign in.

### Step 7 — Verify

- [ ] Homepage loads at localhost:3000  
- [ ] Sign up → Sign in → Sign out works  
- [ ] `bundle exec sidekiq` starts (Redis running)  
- [ ] `bin/rails db:migrate:status` all `up`

---

## Quick reference

| Problem | Fix |
|--------|-----|
| Ruby 2.6/2.7 or bundle “ruby >= 3.1” | Use Ruby 3.2 (Step 1). |
| db:create “no password supplied” | Set `DATABASE_PASSWORD` in `backend/.env`. |
| db:create “role X does not exist” | Use lowercase `DATABASE_USERNAME` in `.env`. |
| redis-cli ping fails | Install/start Redis (Step 3). |

---

## Next

**P0-002** — LLM::ChatService, Tools::Router, tool YAML.
