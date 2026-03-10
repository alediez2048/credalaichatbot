# P0-001 — Step-by-step setup guide

Follow these steps **in order** from your **project root** (the folder that contains both `backend/` and `Docs/`). When a step says “in `backend/`”, run those commands from the `backend` directory.

---

## What you’re building

By the end you will have:

- Rails 7 app in `backend/` that boots and shows a homepage
- PostgreSQL with all P0-001 tables (users, onboarding_sessions, messages, documents, extracted_fields, bookings, audit_logs)
- Devise sign up / sign in / sign out working
- Redis and Sidekiq ready (and optionally running)
- Action Cable available for WebSockets

---

## Step 1 — Ruby 3.2

You need Ruby 3.1 or newer (3.2 recommended).

**1.1** Open a terminal. Go to the **project root** (not inside `backend`):

```bash
cd "/Users/jad/Desktop/Week 4/Credal.ai"
```

**1.2** Check Ruby:

```bash
ruby -v
```

- If you see **3.2.x** (or 3.1.x), go to Step 2.
- If you see **2.6** or **2.7**, switch to Ruby 3.2:

```bash
# macOS with Homebrew
brew install ruby@3.2
export PATH="/opt/homebrew/opt/ruby@3.2/bin:$PATH"
ruby -v
```

You should see something like `ruby 3.2.10`.

---

## Step 2 — PostgreSQL

**2.1** Check that PostgreSQL is installed and running:

```bash
# Option A: try connecting (might ask for password)
psql -U postgres -d postgres -c "SELECT 1"

# Option B: if you use Homebrew Postgres
brew services list | grep postgresql
```

- If `psql` works: note the **username** you used and whether you needed a **password** → go to 2.2.
- If you see **`psql: command not found`** or **`postgresql@16 none`**, use the **Homebrew** steps below.

---

### If you use Homebrew PostgreSQL (e.g. postgresql@16)

Homebrew puts `psql` in a versioned path, and **`none`** means the server isn’t running. Do this:

**A. Add PostgreSQL to your PATH** (for this terminal, or add to `~/.zshrc` to keep it):

```bash
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
```

**B. Start the PostgreSQL server:**

```bash
brew services start postgresql@16
```

Wait a few seconds, then check:

```bash
brew services list | grep postgresql
```

You should see **started** (or **running**) instead of **none**.

**C. Connect (Homebrew often uses your Mac username, no password):**

```bash
psql -d postgres -c "SELECT 1"
```

- If that works: for Step 4 you’ll use **`DATABASE_USERNAME=` your Mac username** (e.g. `jad`) and **`DATABASE_PASSWORD=`** (empty).
- If you get “role postgres does not exist”, try: `psql -U $(whoami) -d postgres -c "SELECT 1"`. Use that username (your Mac user) and empty password in `.env`.

**2.2** You need one of these to be true:

- You can run `psql -U postgres -d postgres` (with or without a password), **or**
- You can run `psql -d postgres` (no `-U`) and it connects (typical with Homebrew).

Remember: **username** and **password** (if any) for Step 4.

---

## Step 3 — Redis (for Action Cable and Sidekiq)

**3.1** Check Redis:

```bash
redis-cli ping
```

You should see `PONG`.

- If `redis-cli` not found: `brew install redis`
- If not running: `brew services start redis` or run `redis-server` in a separate terminal and leave it running.

---

## Step 4 — Backend environment and gems

**4.1** Go into the Rails app directory:

```bash
cd "/Users/jad/Desktop/Week 4/Credal.ai/backend"
```

From here on, all commands are run from **inside `backend/`** unless the step says otherwise.

**4.2** Copy the example env file and edit it:

```bash
cp .env.example .env
```

Open `backend/.env` in your editor and set the database connection to match **your** Postgres (from Step 2):

- **If you use user `postgres` with a password:**
  ```bash
  DATABASE_USERNAME=postgres
  DATABASE_PASSWORD=your_postgres_password_here
  DATABASE_HOST=localhost
  ```

- **If you use your Mac username and no password (common with Homebrew):**
  ```bash
  DATABASE_USERNAME=your_mac_username
  DATABASE_PASSWORD=
  DATABASE_HOST=localhost
  ```

Save the file. Don’t commit `.env` (it’s in `.gitignore`).

**4.3** Install gems:

```bash
bundle install
```

You should see “Bundle complete!”. If you get a “ruby (>= 3.1.0)” error, go back to Step 1 and fix Ruby.

---

## Step 5 — Database create and migrate

Still in `backend/`:

**5.1** Create the development and test databases and run migrations:

```bash
bin/rails db:create db:migrate
```

- **Success:** you see “Created database”, then migration messages, and no error.
- **“no password supplied”:** your Postgres user needs a password. Set `DATABASE_PASSWORD` in `.env` to that password and run the same command again.
- **“connection refused”:** Postgres isn’t running or host/port is wrong; fix Step 2.

**5.2** Confirm tables exist:

```bash
bin/rails db:migrate:status
```

All migrations should show `up`. You can also run `bin/rails dbconsole` and `\dt` to list tables (users, onboarding_sessions, messages, documents, extracted_fields, bookings, audit_logs).

---

## Step 6 — Run the Rails app

**6.1** Start the server (still in `backend/`):

```bash
bin/rails server
```

Or, if you prefer one command that starts web + Redis + Sidekiq (requires Redis on PATH):

```bash
bin/dev
```

**6.2** In the browser open:

**http://localhost:3000**

You should see the “AI-Powered Onboarding Assistant” homepage with links for **Sign up** and **Sign in**. That means Rails is booting and serving the homepage.

---

## Step 7 — Verify P0-001 acceptance criteria

Do these checks so P0-001 is “done”.

### ✓ Rails app boots and serves homepage

- You already did this in Step 6: http://localhost:3000 shows the onboarding title and Devise links.

### ✓ Database migrations run with all core tables

- You did this in Step 5. Double-check:

```bash
cd backend
bin/rails db:migrate:status
```

All entries should be `up`. Optional: `bin/rails dbconsole` → `\dt` → you should see users, onboarding_sessions, messages, documents, extracted_fields, bookings, audit_logs.

### ✓ Devise authentication works (signup, login, logout)

1. On http://localhost:3000 click **Sign up**.
2. Enter an email and password, submit. You should be signed in and see “Signed in as …” and a **Sign out** button.
3. Click **Sign out**. You should see **Sign up** and **Sign in** again.
4. Click **Sign in**, use the same email/password. You should be signed in again.

### ✓ Sidekiq processes jobs from Redis queue

1. In a **new terminal**, start Redis if it’s not already running: `redis-server` (or `brew services start redis`).
2. Go to `backend/` and run:

```bash
cd "/Users/jad/Desktop/Week 4/Credal.ai/backend"
bundle exec sidekiq
```

You should see Sidekiq start and “Listening…” (no error about Redis). That’s enough for P0-001: Sidekiq is configured and can process jobs. You don’t have to enqueue a job for this ticket.

### ✓ Action Cable WebSocket connection establishes in browser

- The app is configured to use Redis for Action Cable (`config/cable.yml`). The WebSocket endpoint is at `/cable`. For P0-001 you only need to confirm the app doesn’t error when loading; full chat streaming is P1-001.
- Optional check: open http://localhost:3000, open DevTools → Network → filter “WS”. Reload; you may see a request to `/cable` when the page uses Action Cable. No error on page load = Cable is available.

---

## Quick reference — “I’m stuck”

| Problem | Fix |
|--------|-----|
| `ruby` is 2.6 / 2.7 | Step 1: install/use Ruby 3.2 (e.g. `brew install ruby@3.2` and set PATH). |
| `bundle install` says “ruby (>= 3.1.0)” | Same: use Ruby 3.2 in this terminal. |
| `db:create` — “no password supplied” | Step 4: set `DATABASE_PASSWORD` (and correct `DATABASE_USERNAME`) in `backend/.env`. |
| `db:create` — “connection refused” | Step 2: start Postgres; confirm host/port match `.env`. |
| `redis-cli ping` fails | Step 3: install/start Redis. |
| I’m in the wrong directory | “Project root” = folder that contains `backend/` and `Docs/`. For Rails commands, use `backend/`. |

---

## You’re done with P0-001 when

- [ ] `bin/rails server` runs and http://localhost:3000 shows the homepage
- [ ] `bin/rails db:migrate:status` shows all migrations `up`
- [ ] You can Sign up, Sign in, and Sign out with Devise
- [ ] `bundle exec sidekiq` starts without Redis errors
- [ ] No need to prove Action Cable in the UI yet; next is P0-002 (LLM service + tools), then P1-001 (chat UI + streaming)

Next ticket: **P0-002** — AI service layer & tool calling infrastructure.
