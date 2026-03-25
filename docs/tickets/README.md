# Tickets

**Canonical location:** `docs/tickets/` — all ticket docs live here.

## Index (one primer per ticket)

| File | Ticket |
|------|--------|
| **DEVLOG.md** | What shipped per ticket, decisions, follow-ups. Update when you finish a ticket. |
| | |
| **P0-001-primer.md** | Rails scaffold + DB setup |
| **P0-002-primer.md** | Frontend toolchain: esbuild + Tailwind + React |
| **P0-003-primer.md** | AI service layer & tool calling infrastructure |
| **P0-004-primer.md** | Prompt management system |
| **P0-005-primer.md** | Observability & tracing (LangSmith) |
| | |
| **P1-000-primer.md** | Landing page & routing |
| **P1-001-primer.md** | Chat interface with streaming LLM responses |
| **P1-002-primer.md** | Conversational onboarding flow with state management |
| **P1-003-primer.md** | Session persistence & resumption |
| **P1-004-primer.md** | Error handling & graceful fallbacks |
| **P1-005-primer.md** | Anonymous-to-authenticated session merge |
| **P1-006-primer.md** | Rate limiting & abuse prevention |
| | |
| **P2-001-primer.md** | Document upload with file validation |
| **P2-002-primer.md** | OCR extraction pipeline (OpenAI Vision) |
| **P2-003-primer.md** | Field validation & confidence-tiered review |
| **P2-004-primer.md** | PII handling & document lifecycle |
| **P2-005-primer.md** | Document type extensibility (config-driven) |
| | |
| **P3-001-primer.md** | Appointment slot management |
| **P3-002-primer.md** | AI-powered slot recommendation |
| **P3-003-primer.md** | Booking confirmation & calendar event |
| **P3-004-primer.md** | Rescheduling flow |
| | |
| **P4-001-primer.md** | Sentiment analysis integration |
| **P4-002-primer.md** | Adaptive chatbot behavior |
| **P4-003-primer.md** | Progress milestones & encouragement |
| **P4-004-primer.md** | Escalation tiers & human handoff |
| | |
| **P5-001-primer.md** | Eval framework & test suite (50+ cases) |
| **P5-002-primer.md** | End-to-end tracing dashboard |
| **P5-003-primer.md** | Cost tracking & projection model |
| **P5-004-primer.md** | Admin analytics dashboard |
| **P5-005-primer.md** | Prompt regression testing in CI |
| | |
| **P6-001-primer.md** | Production deployment |
| **P6-002-primer.md** | Demo video recording (3-5 min) |
| **P6-003-primer.md** | GitHub repository documentation |
| **P6-004-primer.md** | AI cost analysis report |
| **P6-005-primer.md** | Social post & launch |

Before coding any ticket:

1. Read the **primer** for that ticket (`P?-???-primer.md`).
2. Read **DEVLOG.md** for prior decisions and blockers.
3. Follow `.cursor/rules/context-loading.mdc` and `scope-control.mdc`.

## Form factor

**Landing page** (`/`) → **Full-screen chatbot** (`/onboarding`). The chat IS the onboarding.

## Frontend stack

**Tailwind CSS** for all styling. **Hotwire/ERB** for server-rendered pages (landing, admin, Devise). **React** for the chat component only. **esbuild** for JS bundling (JSX support).

## Phase order

| Phase | Focus |
|-------|--------|
| **P0** | Rails scaffold, frontend toolchain (esbuild + Tailwind + React), LLM service + tools, prompts, observability |
| **P1** | Landing page, chat UI, streaming, orchestration, persistence, errors, anonymous merge, rate limits |
| **P2** | Document upload, OCR, field validation, PII, extensibility |
| **P3** | Scheduling: slots, recommendations, booking, rescheduling |
| **P4** | Emotional support: sentiment, adaptive behavior, escalation |
| **P5** | Evals, tracing dashboard, cost tracking, admin analytics |
| **P6** | Deploy, demo video, repo docs, cost report, launch |

## Dependency chain

```
P0-001 (scaffold) ✅
├── P0-002 (esbuild + Tailwind + React) ✅
│   └── P1-000 (landing page + routing) ✅
├── P0-003 (LLM service + tools) ✅
│   ├── P0-004 (prompts) ✅
│   ├── P0-005 (observability — LangSmith) ✅
│   └── P1-001 (chat UI + streaming) ← NEXT
│       └── P1-002 (onboarding orchestration)
│           └── P1-003 (session persistence)
├── P1-004 (error handling)
├── P1-005 (anonymous merge)
├── P1-006 (rate limiting)
├── P2-001 → P2-002 → P2-003 → P2-004 → P2-005 (documents)
├── P3-001 → P3-002 → P3-003 → P3-004 (scheduling)
├── P4-001 → P4-002 → P4-003 → P4-004 (emotional support)
├── P5-001 → P5-002 → P5-003 → P5-004 → P5-005 (evals & ops)
└── P6-001 → P6-002 → P6-003 → P6-004 → P6-005 (launch)
```

**P0-001** is scaffolded under **`backend/`** — run `bundle install` and `db:migrate` there.
