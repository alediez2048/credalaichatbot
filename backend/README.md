# Onboarding Assistant — Rails backend (P0-001)

## Use the correct Ruby (3.2)

The project needs **Ruby 3.2**. If `ruby -v` shows 2.6 or 3.0, your shell is using the wrong Ruby.

**1. Install Ruby 3.2 (if needed)**  
```bash
brew install ruby@3.2
```

**2. Use it in this terminal**  
```bash
export PATH="/opt/homebrew/opt/ruby@3.2/bin:$PATH"
ruby -v   # should show 3.2.x
```

**3. Make it default in every new terminal**  
Add this line to your `~/.zshrc` (then run `source ~/.zshrc` or open a new tab):
```bash
export PATH="/opt/homebrew/opt/ruby@3.2/bin:$PATH"
```

Then from `backend/` run `bundle install` and `bundle exec rails test`.

---

## If `bundle install` fails with "ruby (>= 3.1.0)"

You're still on an older Ruby. Do step 2 above in this terminal, then run `bundle install` again.

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
npm install
npm run build
npm run build:css
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

**Option B — `bin/dev`** (starts web, esbuild watch, Tailwind watch, Redis, Sidekiq)

```bash
bin/dev
```

Requires Node.js (for `npm run build` and Tailwind). First time: run `npm install && npm run build && npm run build:css` so built assets exist; then `bin/dev` keeps JS and CSS rebuilding on change.

Open http://localhost:3000 — landing page, Sign in/up, and `/onboarding` chat placeholder.

## Action Cable

- Adapter: **Redis** in development (`config/cable.yml`).
- Ping channel: subscribe to `PingChannel`; chat UI uses React (P1-001).
- Verify WebSocket: browser devtools → Network → WS → `/cable`.

## Frontend (P0-002)

- **JS:** esbuild bundles `app/javascript/application.js` (Turbo + React ChatApp) to `app/assets/builds/application.js`.
- **CSS:** Tailwind builds `application.tailwind.css` to `app/assets/builds/application.css`. Run `npm run build` and `npm run build:css` (or use `bin/dev` which runs watchers).

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
