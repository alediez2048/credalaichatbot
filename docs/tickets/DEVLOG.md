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

### P1-001 — Chat interface with streaming LLM responses
**Date:** _pending_  
**Branch:** feature/P1-001-chat-streaming  

**Status:** Kickstarted — primer created; implementation blocked until P0-001/P0-002 complete.

**What shipped:**
- `Docs/tickets/P1-001-primer.md` — scope, prerequisites, acceptance criteria, file hints

**Decisions:**
- Streaming via Action Cable from server-side LLM service (no client-direct OpenAI for stream)
- Messages persisted on `Message` model tied to session

**Follow-ups / debt:**
- Run P0-001 then P0-002 before first commit on P1-001

---

*(Append new tickets above this line, oldest at bottom.)*
