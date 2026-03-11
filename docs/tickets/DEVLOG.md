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

### P0-002 — Frontend toolchain: esbuild + Tailwind CSS + React
**Date:** 2026-03-10  
**Branch:** feature/P0-002-frontend-toolchain

**What shipped:**
- Replaced `importmap-rails` with `jsbundling-rails`; removed `config/importmap.rb`
- `package.json`: esbuild, Tailwind, React, ReactDOM, @hotwired/turbo; build + build:css + build:css:watch scripts
- `tailwind.config.js` + `application.tailwind.css`; built output to `app/assets/builds/`
- Layout, landing (`home#index`), and onboarding chat view restyled with Tailwind; nav with Sign in/up or user + Sign out
- `OnboardingController#chat` + route `get '/onboarding'`; view with `#chat-root` for React
- `app/javascript/components/ChatApp.jsx` — React placeholder rendering "Chat loading..." on `/onboarding`
- `application.js` imports Turbo + ChatApp; esbuild build with `--loader:.jsx=jsx`
- Procfile.dev: added `js` (esbuild --watch) and `css` (tailwind --watch)
- Devise views: `sessions/new`, `registrations/new`, shared `_links`, `_error_messages` with Tailwind form styling

**Decisions:**
- Replace Importmap with esbuild for JSX; Tailwind replaces vanilla CSS
- React only for chat mount; landing and layout are ERB + Tailwind
- Asset pipeline serves from `app/assets/builds/` (application.js + application.css)
- React only for chat mount; landing and layout are ERB + Tailwind
- Asset pipeline serves from `app/assets/builds/` (application.js + application.css)

---

### P0-003 — AI service layer & tool calling infrastructure
**Date:** 2026-03-10  
**Branch:** feature/P0-003-llm-tool-calling

**What shipped:**
- `config/prompts/tool_definitions.yml` — all 9 tools (OpenAI function-call schema)
- `Tools::SchemaValidator` — validates tool name + params against YAML; returns structured errors; `definitions_for_openai` for API
- `Tools::Router` — maps tool name to stub handler; validates via SchemaValidator; parses JSON arguments; returns `{ success:, data: }` or `{ success: false, error: }`
- `LLM::ContextBuilder.build` — system_prompt + history + current_message → messages array for OpenAI
- `LLM::ChatService` — loads tool definitions from SchemaValidator; OpenAI client (when OPENAI_API_KEY set); `chat(messages:)` returns raw response with `choices`; nil client when no key
- Gemfile: `openai` gem; `.env.example`: OPENAI_API_KEY, OPENAI_MODEL
- Unit tests: SchemaValidator (unknown tool, missing required, tool_names, definitions_for_openai), Router (call stub, invalid params, JSON args), ContextBuilder (system, history, current)
- Integration test: YAML load 9 tools; full path (ContextBuilder → ChatService → optional tool_calls → Router); works without API key (empty choices)

**Decisions:**
- Tool handlers are stubs returning `{ success: true, data: { tool:, message: } }`; full logic in P1-002, P2, etc.
- Services under `app/services/` (tools/, llm/) for autoload

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
- Used scoped custom CSS initially — **will be replaced by Tailwind in P0-002**

---

### P1-001 — Chat interface with streaming LLM responses
**Date:** _pending_
**Branch:** feature/P1-001-chat-streaming

**Status:** Primer created; blocked until P0-003 and P1-000 complete.

**What shipped:**
- `docs/tickets/P1-001-primer.md` — scope, prerequisites, acceptance criteria, file hints

**Decisions:**
- Streaming via Action Cable from server-side LLM service (no client-direct OpenAI for stream)
- Messages persisted on `Message` model tied to session
- Chat component mounts in `/onboarding` view created by P1-000

**Follow-ups / debt:**
- Run P0-002 (frontend), P0-003 (LLM), then P1-000, before first commit on P1-001

---

*(Append new tickets above this line, oldest at bottom.)*
