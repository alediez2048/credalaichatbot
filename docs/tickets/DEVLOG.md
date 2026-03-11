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

### P0-005 — Frontend toolchain: esbuild + Tailwind CSS + React
**Date:** _pending_
**Branch:** feature/P0-005-frontend-toolchain

**Status:** Primer created. Ready to implement (only depends on P0-001 ✅).

**What shipped:**
- `docs/tickets/P0-005-primer.md` — full setup guide, step-by-step, acceptance criteria

**Decisions:**
- Replace Importmap with esbuild (jsbundling-rails) for JSX support
- Tailwind CSS replaces all vanilla CSS — utility-first, no Bootstrap
- React only for chat component; landing page stays ERB + Tailwind
- @tailwindcss/forms plugin for clean Devise form styling

**Follow-ups / debt:**
- Execute P0-005 before P1-000 (landing page needs Tailwind)

---

### P1-000 — Landing page & routing
**Date:** 2026-03-10
**Branch:** feature/P1-000-landing-page

**What shipped:**
- Landing page at `/`: hero, tagline, description, "Start Onboarding →" CTA, features list, footer
- Route `get '/onboarding', to: 'onboarding#chat'`; `OnboardingController#chat` (no auth gate)
- `app/views/onboarding/chat.html.erb` with `#chat-root` container (placeholder for P1-001)
- Layout: nav with logo, Sign in | Sign up (or user email + Sign out when signed in)
- Scoped CSS: landing + nav + chat container, mobile-responsive (375px)

**Decisions:**
- Form factor: landing at `/`, chat at `/onboarding`; server-rendered ERB
- No auth required for `/onboarding`; auth deferred to document upload (P1-005)
- Used scoped custom CSS initially — **will be replaced by Tailwind in P0-005**

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
