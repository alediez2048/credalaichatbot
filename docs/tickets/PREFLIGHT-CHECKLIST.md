# Pre-flight checklist — before moving forward

Run these checks **from the `backend/` directory** (unless noted). Fix any failures before starting the next ticket or pushing to production.

---

## 1. Environment & runtime

| Check | Command / action | Pass? |
|-------|-------------------|-------|
| Ruby 3.1+ | `ruby -v` → 3.2.x or 3.1.x | ☐ |
| PostgreSQL running | `psql -d postgres -c "SELECT 1"` (or `brew services list \| grep postgresql` → started) | ☐ |
| Redis running | `redis-cli ping` → `PONG` | ☐ |
| `.env` exists | `test -f .env && echo ok` | ☐ |
| DB username lowercase | Open `.env` → `DATABASE_USERNAME` is lowercase (e.g. `jad` not `JAD`) | ☐ |

---

## 2. Dependencies

| Check | Command / action | Pass? |
|-------|-------------------|-------|
| Gems installed | `bundle install` → "Bundle complete!" | ☐ |
| Node deps installed | `npm install` → no errors | ☐ |
| JS build exists | `test -f app/assets/builds/application.js && echo ok` | ☐ |
| CSS build exists | `test -f app/assets/builds/application.css && echo ok` | ☐ |

If either build is missing: `npm run build` and `npm run build:css`.

---

## 3. Database

| Check | Command / action | Pass? |
|-------|-------------------|-------|
| DB created | `bin/rails db:migrate:status` → all migrations `up` | ☐ |
| No pending migrations | Same output; no `down` entries | ☐ |

---

## 4. App boots & routes

| Check | Command / action | Pass? |
|-------|-------------------|-------|
| Server starts | `bin/rails server` → "Listening on..." (then Ctrl+C) | ☐ |
| Root loads | Open http://localhost:3000 → landing page, no 500 | ☐ |
| `/onboarding` loads | Open http://localhost:3000/onboarding → chat container / "Chat loading..." | ☐ |
| Sign in/up work | Click Sign in → form; Sign up → form; submit → no crash | ☐ |

---

## 5. Config sanity

| Check | Where to look | Pass? |
|-------|----------------|-------|
| No `importmap` in layout | `app/views/layouts/application.html.erb` → uses `javascript_include_tag "application"` (not `javascript_importmap_tags`) | ☐ |
| Manifest has builds | `app/assets/config/manifest.js` → has `//= link application.js` and `//= link application.css` | ☐ |
| Asset path includes builds | `config/initializers/assets.rb` → `app/assets/builds` in paths | ☐ |
| Procfile has js + css | `Procfile.dev` → lines for `js` and `css` (esbuild + tailwind watch) | ☐ |

---

## 6. Optional (for full P0-001 / P0-002 sign-off)

| Check | Command / action | Pass? |
|-------|-------------------|-------|
| Sidekiq starts | `bundle exec sidekiq` → "Listening..." (no Redis error) | ☐ |
| Tailwind applies | On landing page, inspect an element → has Tailwind classes (e.g. `text-indigo-600`) | ☐ |
| React mounts on /onboarding | Page shows "Chat loading..." from `ChatApp.jsx` | ☐ |
| 375px layout | DevTools → 375px width → no horizontal scroll, nav and CTA usable | ☐ |

---

## Quick one-liner (from `backend/`)

```bash
ruby -v && bundle exec rails db:migrate:status 2>/dev/null | tail -1 && test -f app/assets/builds/application.js && test -f app/assets/builds/application.css && echo "Pre-flight OK"
```

If that prints "Pre-flight OK", environment, DB, and built assets are in place. Still do a quick manual check of `/`, `/onboarding`, and Sign in/up in the browser.

---

## Before starting a new ticket

1. Run the checks above (or the one-liner).
2. Read that ticket’s **primer** (`docs/tickets/P?-???-primer.md`).
3. Read **DEVLOG.md** for recent decisions and blockers.
4. Create a feature branch: `git switch -c feature/P?-???-short-name`.
