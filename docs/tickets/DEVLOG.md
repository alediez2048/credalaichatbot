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
**Date:** 2026-03-11  
**Branch:** feature/P1-001-chat-streaming

**What shipped:**
- **OnboardingController#chat:** find or create `OnboardingSession` (by current_user or session[:onboarding_session_id]); pass `@onboarding_session` to view; view exposes `data-session-id` and `data-initial-messages` (JSON) on `#chat-root`
- **LLM::ChatService#stream_chat:** streams token-by-token via OpenAI `stream_raw`; yields content deltas to block; no tools (streaming text only); no-op / error message when API key missing
- **OnboardingChatChannel:** subscribe by `session_id`; `send_message(body)` persists user Message, builds context via ContextBuilder, calls ChatService#stream_chat, broadcasts `start` / `token` / `done` (with assistant Message id and content) / `error`; assistant message persisted on done
- **React ChatApp:** subscribes to OnboardingChatChannel with session_id; reads initial messages from data attribute; optimistic user message on send; receives token/done/error; typing indicator (dots) while streaming; auto-scroll to bottom; message bubbles (user right/blue, assistant left/gray); mobile-friendly (max-w 85%, 375px)
- **package.json:** added `@rails/actioncable`; layout meta `action-cable-url` for /cable
- **Unit tests:** ChatService#stream_chat (nil client yields error once; stub client yields content deltas)

**Decisions:**
- Streaming via Action Cable only; no client-direct OpenAI
- Single source of truth: server persists user + assistant messages; client shows optimistic user message
- Streaming omits tools (plain text stream); tool calling remains in non-streaming #chat for P1-002
- Anonymous sessions keyed by session[:onboarding_session_id]; signed-in by user_id (one session per user for now)

**Follow-ups / debt:**
- P1-002: orchestration will use same channel; add tool-call handling in stream or separate non-stream path
- Optional: system prompt from PromptLoader (P0-004) when wired

---

### P5-005 — Prompt regression testing in CI
**Date:** 2026-03-26
**Branch:** feature/P5-005-ci-eval

**What shipped:**
- `.github/workflows/eval.yml` — GitHub Actions workflow triggered on prompt/LLM/orchestrator/eval changes
- Enhanced `eval:ci` rake task with JSON report output and configurable threshold
- `config/ci/eval_config.yml` — threshold, max cost, timeout settings
- PR comment via `actions/github-script` with pass rate, failures, and status
- `docs/ops/ci-eval.md` — guide for adding cases, debugging failures, local testing with `act`
- `.env.example` updated with `EVAL_PASS_THRESHOLD`

**Decisions:**
- Eval runs only on PRs touching prompt/LLM paths (not every commit) to control API costs
- Default threshold 85% — configurable via GitHub Actions variable or env var
- CI eval runs tagged `is_eval: true` and posted to `credal-onboarding-ci` LangSmith project

---

### P5-004 — Admin analytics dashboard
**Date:** 2026-03-26
**Branch:** feature/P5-004-admin-dashboard

**What shipped:**
- `admin` boolean on `User` model with migration (default false)
- `Admin::DashboardController` with admin-only auth guard
- `Admin::DashboardStats` service: session stats, completion funnel, cost summary, eval results, recent sessions
- Server-rendered dashboard view at `/admin/dashboard` with Tailwind — stat cards, funnel with progress bars, cost panel, eval panel, recent sessions table
- 6 unit tests for DashboardStats, 5 controller tests for auth and rendering

**Decisions:**
- Server-rendered ERB + Tailwind (no JS charts) per primer scope — simple, fast, mobile-responsive
- `DashboardStats.eval_summary` reads from `tmp/eval_report.json` (file-based, no DB table for eval results)
- Recent sessions eager-loads messages and llm_usages to avoid N+1

---

### P5-003 — Cost tracking & projection model
**Date:** 2026-03-26
**Branch:** feature/P5-003-cost-tracking

**What shipped:**
- `LLMUsage` model with migration — tracks per-call token usage and USD cost per session
- `Cost::Calculator` — computes USD cost from model + token counts using `config/ai_pricing.yml`
- `Cost::Tracker` — records usage after each `ChatService#chat` call, graceful no-op on missing data
- `Cost::Projector` — projects monthly/annual cost at N users based on historical session averages
- `cost:report` rake task — per-session and aggregate cost summary
- `cost:project[N]` rake task — cost projection for N users/month
- Integration with `ChatService#chat` — usage recorded automatically after every LLM call
- 10 unit tests: calculator accuracy, tracker record/no-op, projector with/without data

**Decisions:**
- Model named `LLMUsage` (not `LlmUsage`) to match Rails inflection of `llm_usages` table
- Pricing in YAML config file for easy updates without code changes
- Projector uses `AVG_SESSIONS_PER_USER = 1.2` constant — adjustable based on real data later

---

### P5-002 — End-to-end tracing dashboard
**Date:** 2026-03-26
**Branch:** feature/P5-002-tracing-dashboard

**What shipped:**
- Enhanced `Observability::Tracer` with metadata hash (`onboarding_step`, `message_count`, `is_eval`), `parent_run_id` for hierarchy, and new `trace_orchestrator_call` method
- Parent/child run structure: `orchestrator.process` (chain) → `openai-chat-completion` (llm) + `tool:*` (tool) child runs
- `RunContext` struct yielded by `trace_orchestrator_call` — tracks child runs with name, type, and duration
- `Orchestrator#process` wraps each turn in `trace_orchestrator_call`, passes step metadata and `is_eval` flag
- `ChatService#chat` accepts `metadata` and `parent_run_id` kwargs, forwarded to tracer
- `Eval::Runner` tags all eval runs with `is_eval: true` for dashboard filtering
- `docs/ops/langsmith-dashboard.md` — team guide with filter presets, debugging workflows, alert setup
- 10 tracer unit tests covering enhanced metadata, parent/child runs, and orchestrator tracing

**Decisions:**
- `RunContext` is a lightweight Struct (not a full class) — keeps overhead minimal for the no-op path
- Tool durations tracked with monotonic clock in orchestrator, reported as `duration_ms` on child runs
- `is_eval` defaults to `false` in orchestrator; only `Eval::Runner` sets it to `true`

**Follow-ups / debt:**
- Verify traces with real LangSmith API key (parent/child hierarchy visible in dashboard)
- P5-003 will add cost tracking per trace using token_usage metadata

---

### P0-005 — Observability & tracing setup
**Date:** 2026-03-11  
**Branch:** feature/P0-005-observability-tracing

**What shipped:**
- **LangSmith** integrated via REST API (no gem dependency); `Observability::Tracer` posts runs to `https://api.smith.langchain.com/runs`
- `Observability::Tracer` — `trace_llm_call(session_id:, user_id:, model:, messages:) { block }`; no-op when env key blank; creates run with usage (prompt/completion/total tokens), latency, tool_calls, model
- `LLM::ChatService#chat` — wraps OpenAI call in `Tracer.trace_llm_call` so every LLM call is traced when LangSmith is configured
- `.env.example`: `LANGSMITH_API_KEY`, optional `LANGSMITH_PROJECT`, `LANGSMITH_ENDPOINT`
- Unit tests: `Observability::Tracer` (enabled? when key set/unset, trace_llm_call yields and returns block result when disabled, accepts session_id/user_id)

**Decisions:**
- LangSmith chosen for observability (better ecosystem integration, hosted dashboard)
- REST API used directly (no Ruby SDK needed); runs posted in background thread to avoid blocking
- Tracing is no-op when `LANGSMITH_API_KEY` is blank (tests and dev without keys pass)
- Session ID and user ID passed from future callers (e.g. controller in P1-001); not required for run to be created

**Follow-ups / debt:**
- With real API key, trigger one chat and confirm run appears in LangSmith dashboard with tokens, latency, session_id
- P1-004 will log errors into tracing (error category)

---

*(Append new tickets above this line, oldest at bottom.)*
