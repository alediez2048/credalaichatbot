# DEVLOG — Credal.ai Onboarding Assistant

Single place to record what landed per ticket, decisions, and follow-ups.

---

## Template (copy for each ticket)

```markdown
### P?-??? — Title
**Date:** YYYY-MM-DD  
**Branch:** feature/P?-???-short-name  

**What shipped:**
- ...

**Decisions:**
- ...

**Follow-ups / debt:**
- ...
```

---

## Log

### P0-001 — Rails project scaffolding & database setup
**Date:** 2026-03-08  
**Branch:** _main / feature branch as preferred_

**What shipped:**
- `backend/` Rails 7.2 app: PostgreSQL, Redis (Cable + Sidekiq), Devise, core migrations and models
- `Procfile.dev` + `bin/dev` (foreman)
- `PingChannel` for Action Cable smoke test
- `backend/README.md` setup instructions (Ruby 3.2 + Docker fallback)

**Decisions:**
- App in `backend/` to avoid clobbering repo-root docs
- Active Storage omitted until P2 uploads; `config/application.rb` loads a minimal railtie set
- `SECRET_KEY_BASE` auto-generated in development if credentials missing

**Follow-ups:**
- Run `bundle install` + `db:migrate` on machine with Ruby 3+
- Optional: `rails importmap:install` if turbo asset missing after bundle

---

### P1-000 — Landing page & routing
**Date:** _pending_
**Branch:** feature/P1-000-landing-page

**Status:** Primer created. Blocked on P0-001 completion (done) — ready to implement.

**What shipped:**
- `docs/tickets/P1-000-primer.md` — scope, acceptance criteria, content spec

**Decisions:**
- Form factor defined: landing page (`/`) + full-screen chat (`/onboarding`)
- Landing page is server-rendered ERB (no React); chat mount point at `/onboarding`
- Anonymous users can access `/onboarding` — auth deferred to document upload (P1-005)

**Follow-ups / debt:**
- Styling approach TBD (Tailwind vs scoped CSS)

---

### P1-001 — Chat interface with streaming LLM responses
**Date:** _pending_
**Branch:** feature/P1-001-chat-streaming

**Status:** Primer created; blocked until P0-002 and P1-000 complete.

**What shipped:**
- `docs/tickets/P1-001-primer.md` — scope, prerequisites, acceptance criteria, file hints

**Decisions:**
- Streaming via Action Cable from server-side LLM service (no client-direct OpenAI for stream)
- Messages persisted on `Message` model tied to session
- Chat component mounts in `/onboarding` view created by P1-000

**Follow-ups / debt:**
- Run P0-002, then P1-000, before first commit on P1-001

---

*(Append new tickets above this line, oldest at bottom.)*
