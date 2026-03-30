# Credal.ai Onboarding Assistant — Slide Deck Outline (10 Slides)

---

## Slide 1: Title

**AI-Powered Employee Onboarding Assistant for Credal.ai**

- Your name / role
- Built for: Credal.ai (YC-backed, enterprise AI agent platform)
- Tagline: "Complete your employee onboarding in minutes — not hours."
- Visual: Credal logo + screenshot of chat interface

---

## Slide 2: The Problem

**Employee onboarding is broken.**

- Current onboarding systems have **40–60% abandonment rates**
- Fragmented experience: separate portals for documents, scheduling, compliance, IT setup
- No real-time guidance — users get stuck, confused, or frustrated with no help
- HR teams buried in manual follow-ups for incomplete onboardings
- Enterprise compliance requirements (SOC 2, HIPAA) make the process even heavier

**The question:** What if onboarding felt like a conversation, not a checklist?

---

## Slide 3: The Solution

**A conversational AI agent that IS the onboarding.**

- One chat interface replaces 5+ separate portals
- AI guides new employees step by step: personal info → document upload → scheduling → review → complete
- Real-time streaming responses (token-by-token, not waiting for full response)
- Emotionally aware — detects frustration, adapts tone, escalates to humans when needed
- Enterprise-grade: PII encryption, audit trails, compliance messaging baked in

**Form factor:** Landing page → Full-screen chat. The chat IS the onboarding.

**Omnichannel continuation (P7):** Users can continue the same onboarding session on **WhatsApp, Telegram, Discord, or SMS** via [OpenClaw](https://docs.openclaw.ai/) — a self-hosted agent gateway. **Proactive heartbeats** follow up with idle users automatically.

**Target metrics:**
- <3s response latency
- \>85% OCR accuracy on documents
- \>70% completion rate (vs. 40-60% industry average)
- <$0.50 per session

---

## Slide 4: Tech Stack

**Backend**
- Rails 7.2 monolith (fast scaffolding, mature auth, built-in WebSockets)
- PostgreSQL (ACID compliance, JSON columns, audit trail)
- Redis (Action Cable pub/sub + Sidekiq job queue)
- Devise (authentication with anonymous → authenticated session merge)

**Frontend**
- Hybrid approach: ERB + Tailwind for server-rendered pages, React 18 for chat only
- esbuild (fast JS bundling with JSX support)
- Tailwind CSS (Credal brand design tokens)

**AI / LLM**
- OpenAI GPT-4o with native function calling (9 tools defined)
- LangSmith for observability and tracing (every LLM call tracked)
- YAML-driven prompt management (no code changes for prompt edits)

**Infrastructure**
- Render (managed Postgres, Redis, auto-deploy from GitHub)
- Sidekiq workers for async OCR, summaries, audit logs

**Omnichannel / OpenClaw Gateway (P7)**
- [OpenClaw](https://docs.openclaw.ai/) — self-hosted AI agent gateway connecting WhatsApp, Telegram, Discord, WebChat, SMS, and more to the Rails backend via webhooks
- OpenClaw handles **channel connectivity, per-sender sessions, memory, and proactive follow-ups** (heartbeat)
- Rails handles **onboarding logic, tools, persistence, and LLM calls** — OpenClaw calls in, not the other way around
- Twilio/mock adapters retained as **direct SMS fallback + deterministic test path** (`SMS_PROVIDER=mock`)

---

## Slide 5: System Architecture

**Visual: Architecture diagram showing data flow**

```
User (WhatsApp / Telegram /           User Browser
 Discord / WebChat / SMS)                 │
        │                       ├── Landing Page (ERB + Tailwind)
        ▼                       └── Chat UI (React + Action Cable)
OpenClaw Gateway (daemon)                 │
  • per-sender sessions                   │
  • memory + heartbeat                    │
  • 20+ channel connectors               │
        │                                 │
   POST /api/openclaw/turn        OnboardingChatChannel
   (signed webhook)                       │
        │                                 │
        └────────────────┬────────────────┘
                         ▼
          Onboarding::TurnProcessor (single entry)
          • session lock (one turn at a time)
          • channel metadata on each Message
                         ▼
          Onboarding::Orchestrator (state machine)
              ├── ContextBuilder → prompt + history + step
              ├── LLM::ChatService → OpenAI GPT-4o
              ├── Tools::Router → 9 tool handlers
              ├── Sentiment::Analyzer
              └── Observability::Tracer → LangSmith
                         ▼
          ChannelFormatter (channel-safe output)
                         │
       ┌─────────────────┼──────────────────┐
   web: stream    OpenClaw: JSON reply   SMS fallback:
   via Cable      → delivered on          Twilio/Mock
                    originating channel
                         ▼
    PostgreSQL (sessions, messages, sms_events, documents, bookings, audit)
    Redis (Action Cable, Sidekiq, rate limiting)
```

**Key pattern:** Every turn — web, WhatsApp, Telegram, or any channel — hits the **same** `TurnProcessor` → **same** `Orchestrator` → channel-appropriate response. OpenClaw is the **channel gateway**; Rails is the **domain brain**. No onboarding logic is duplicated in OpenClaw.

**OpenClaw role:** Self-hosted agent gateway ([docs.openclaw.ai](https://docs.openclaw.ai/)) that connects messaging channels to our Rails API. It handles session isolation, persistent memory, and **proactive heartbeat** (follows up with idle users). The existing Twilio/mock adapters remain as a direct SMS fallback and deterministic test path.

---

## Slide 6: The Orchestration Engine (What Makes It Smart)

**Not just a chatbot — a state machine with tool calling.**

- **6-step flow:** Welcome → Personal Info → Document Upload → Scheduling → Review → Complete
- **Tool calling loop:** LLM requests tools → Router validates + executes → Results fed back → LLM generates context-aware response (max 3 iterations per turn)
- **Auto-advancement:** Each step defines required fields; Orchestrator advances only when complete
- **Session persistence:** Users can leave and resume. Anonymous users keep progress after sign-in (session merge)
- **Adaptive behavior:** Sentiment detection adjusts tone. Frustrated user → slower pace, empathy, escalation option

**Cross-channel guardrails:** Session-level locking prevents interleaved turns from corrupting state; formatter ensures channel-appropriate output (truncation for SMS, resume copy on channel switches).

**9 tools available to the LLM:**
| Tool | Purpose |
|------|---------|
| startOnboarding | Initialize session and flow |
| saveOnboardingProgress | Persist collected data |
| getOnboardingState | Check current step + progress |
| extractDocumentData | OCR via OpenAI Vision |
| validateExtractedData | Confidence scoring on fields |
| getAvailableSlots | Query appointment availability |
| bookAppointment | Create booking + calendar event |
| detectUserSentiment | Classify emotional state |
| getSupportContent | Retrieve help resources |

---

## Slide 7: Our Unique Approach

**Research-driven, phased delivery, enterprise-first.**

1. **Pre-search methodology** — Every architectural decision documented with trade-offs before writing code (stack selection, hosting, auth, LLM provider)

2. **7-phase ticket system** (41 tickets, dependency-chained):
   - P0: Foundation → P1: Chat MVP → P2: Documents → P3: Scheduling → P4: Emotional Support → P5: Evals & Ops → P6: Launch → **P7: OpenClaw omnichannel gateway + proactive onboarding + admin analytics**

3. **OpenClaw integration** — Not just "add SMS." [OpenClaw](https://docs.openclaw.ai/) is a self-hosted agent gateway connecting WhatsApp, Telegram, Discord, WebChat, and more. It calls our Rails `TurnProcessor` via webhooks — same orchestration path as web chat. **Proactive heartbeats** follow up with idle users automatically. Twilio/mock adapters stay for direct SMS fallback and **deterministic CI** (`SMS_PROVIDER=mock`).

4. **Hybrid frontend** — React only where needed (chat). ERB everywhere else. Avoids SPA complexity where it doesn't add value.

5. **YAML-driven everything** — Prompts, tool schemas, step definitions, document types all in config files. No code deploy for content changes.

6. **Observability from Day 1** — LangSmith tracing built in P0, not bolted on later. Every LLM call traced with tokens, latency, tool calls, session linkage.

7. **Enterprise compliance baked in** — PII encryption, audit trails, data lifecycle, SOC 2 messaging — not afterthoughts. OpenClaw adds per-sender isolation (`dmScope`), channel allowlists, and pairing controls. Rails enforces opt-in consent, STOP/HELP keywords, quiet hours, and message frequency caps.

---

## Slide 8: Implementation Flow & Development Velocity

**Built in a 7-day sprint with clear gates.**

| Day | Phase | What Shipped |
|-----|-------|-------------|
| 0–1 | **P0** | Rails scaffold, esbuild + Tailwind + React toolchain, LLM service with 9 tool definitions, YAML prompt system, LangSmith tracing |
| 1–2 | **P1** | Landing page, real-time chat with streaming, Action Cable WebSocket, orchestration state machine, session persistence, error handling, rate limiting |
| 2–3 | **P2** | Document upload (Active Storage), OCR extraction (OpenAI Vision), field validation with confidence scoring, PII handling |
| 3–4 | **P3** | Appointment slot management, AI-powered slot recommendations, booking with ICS calendar export, rescheduling |
| 4–5 | **P4** | Sentiment analysis, adaptive chatbot behavior, progress milestones, escalation tiers |
| 5–6 | **P5** | Eval framework (50+ test cases), tracing dashboard, cost tracking, admin analytics |
| 6–7 | **P6** | Production deploy (Render), demo video, GitHub docs, cost analysis, launch |
| Post-MVP | **P7** | Phone/consent capture, Twilio/mock adapters, `TurnProcessor`, **OpenClaw gateway** (WhatsApp, Telegram, Discord, WebChat), proactive heartbeats, admin analytics dashboard |

**Key velocity enablers:**
- Foundation-first: P0 unblocks all parallel streams
- Service-layer pattern: each service testable in isolation
- YAML config: prompt/tool changes without touching code
- Primer-driven tickets: every ticket has requirements, acceptance criteria, and definition of done before coding starts
- **Deterministic tests:** mock adapter + webhook/controller tests — no OpenClaw, Twilio, or external APIs in CI
- **OpenClaw is additive:** web chat path untouched; gateway adds 20+ channels with zero Rails code duplication

---

## Slide 9: Credal Alignment & Brand Integration

**This isn't a generic chatbot — it's a Credal product.**

- **System prompt embeds Credal's mission:** "You're joining a team building the future of enterprise AI. Our customers include Wise, Checkr, MongoDB, and Comcast."
- **Visual design matches Credal brand:** Purple (#6D46DE) CTAs, Green (#00C14E) accents, DM Sans typography, pill-shaped buttons, flat/borderless design
- **Demonstrates Credal's own patterns:** The onboarding assistant IS the kind of AI agent Credal helps enterprises build — multi-step orchestration, tool calling, compliance-aware, auditable
- **Aligns with existing products:** Credal already has "Onboarding Buddy" and "Benefits Buddy" agents — this is a working reference implementation

**Compliance messaging at every step:**
- SOC 2 Type II, HIPAA references in system prompt
- PII encrypted at rest, auto-deleted after extraction
- Full audit trail: who accessed what, when, linked to LangSmith traces

---

## Slide 10: Results, Cost Model & What's Next

**Metrics & Cost Analysis**

| Metric | Target | Approach |
|--------|--------|----------|
| Response latency | <3s | Streaming (perceived instant) |
| OCR accuracy | >85% | OpenAI Vision + confidence scoring |
| Completion rate | >70% | Step-by-step guidance + emotional support |
| Cost per session | <$0.50 | GPT-4o-mini for sentiment, GPT-4o for orchestration |

**Cost projection (GPT-4o at current pricing):**
| Scale | Monthly Cost |
|-------|-------------|
| 100 sessions | ~$50 |
| 1,000 sessions | ~$500 |
| 10,000 sessions | ~$4,500 |

**What's next:**
- **OpenClaw gateway live:** Connect WhatsApp + Telegram channels, enable proactive heartbeat for idle-user follow-ups, admin analytics dashboard for user journey visualization
- Eval regression testing in CI (catch prompt breaks before deploy)
- Google Calendar integration (real booking)
- Multi-language support
- Credal platform integration (use Credal's own API for governance layer)

**Live demo:** [production URL]

---

## Speaker Notes / Appendix

### Key talking points per slide:
- **Slide 2 (Problem):** Anchor with real stats. "Every enterprise has this problem."
- **Slide 5 (Architecture):** Two ingress paths (web + OpenClaw), one `TurnProcessor`. OpenClaw is a gateway, not an API — it calls us. Web chat unchanged.
- **Slide 6 (Orchestration):** This is the "wow" slide. Show the tool calling loop + cross-channel locks. Mention heartbeat as proactive capability.
- **Slide 7 (Unique approach):** Differentiate from "I just called the OpenAI API" — OpenClaw gives 20+ channels without duplicating logic. Deterministic tests with mock adapter.
- **Slide 9 (Credal alignment):** Shows you understand the company, not just the tech
- **Slide 10 (Results):** End on cost efficiency + scalability; OpenClaw gateway + proactive heartbeat + admin analytics as near-term.

### Demo flow (if live):
1. Landing page → click "Start Onboarding"
2. Chat: "Hi, I'm starting today" → watch streaming response
3. Provide name + email → tool calls save progress
4. Upload a document → OCR extracts fields
5. Ask to schedule orientation → AI recommends slots
6. **Optional (P7):** Enter phone + SMS consent → trigger handoff. Or: show OpenClaw dashboard with WhatsApp/Telegram connected → send message from phone → same orchestrator, same step, response delivered on channel.
7. Show LangSmith traces dashboard
8. **Optional:** Show admin dashboard — session drill-down with channel badges, funnel, completion outcomes

### Test / CI story (soundbite):
- **LLM:** Mocked or recorded in unit tests — no live OpenAI in the default suite.
- **Channels:** `SMS_PROVIDER=mock` exercises `TurnProcessor` without Twilio. OpenClaw is not in the test suite — integration tested manually via connected channels.

---

## Expanded Context By Slide (Presenter Narrative)

### Slide 1 — Title
- **Narrative goal:** Establish relevance in the first 20 seconds: this is a practical, production-minded AI system, not a toy chatbot.
- **What to emphasize:** Credal fit (enterprise AI + governance), and that the onboarding assistant is a concrete example of Credal-style agent orchestration.
- **Transition line:** "Let me show the business pain this solves and why a chat-native onboarding flow matters."

### Slide 2 — The Problem
- **Narrative goal:** Make the pain feel operational and measurable (abandonment, HR overhead, compliance risk), not just UX inconvenience.
- **What to emphasize:** Fragmentation is the root issue: each portal handoff creates drop-off and support burden.
- **Transition line:** "So we asked: can one guided conversation replace this fragmented workflow?"

### Slide 3 — The Solution
- **Narrative goal:** Reframe onboarding as an orchestrated workflow in conversational form.
- **What to emphasize:** The assistant does real work (state tracking, tools, persistence, escalation), not just Q&A generation. **OpenClaw gateway** means users can continue on WhatsApp, Telegram, or SMS without starting over. **Proactive heartbeat** follows up with idle users automatically.
- **Transition line:** "To make this credible in production, the architecture choices are critical."

### Slide 4 — Tech Stack
- **Narrative goal:** Show intentional tradeoffs instead of trend-chasing.
- **What to emphasize:** Rails monolith for speed and reliability, React only where interactivity is needed, OpenAI function-calling for deterministic actions, LangSmith for traceability. **OpenClaw** as the multi-channel gateway that calls Rails — not a second orchestration stack, not an SMS API.
- **Transition line:** "Now let's walk through the runtime data path from browser event to persisted state."

### Slide 5 — System Architecture
- **Narrative goal:** Explain a single turn lifecycle clearly **across all channels**.
- **What to emphasize:** Two ingress paths (Action Cable for web, OpenClaw webhook for everything else) → **same `TurnProcessor`** → orchestrator → formatter → response delivered on originating channel. OpenClaw is a **gateway that calls us**, not an API we call. Mock adapter keeps CI deterministic.
- **Transition line:** "The core differentiator is the orchestration engine that controls every turn — no matter which channel the user is on."

### Slide 6 — Orchestration Engine
- **Narrative goal:** Prove this is a governed agent, not free-form prompting.
- **What to emphasize:** Step machine, validation gates, capped tool loop iterations, controlled progression, fallback behavior, cross-channel session locks, and **proactive heartbeat** (OpenClaw follows up with idle users automatically).
- **Transition line:** "This implementation approach came from a deliberate delivery strategy."

### Slide 7 — Unique Approach
- **Narrative goal:** Differentiate execution discipline from typical hackathon builds.
- **What to emphasize:** Ticketized dependency graph, YAML-driven configs, observability-first, compliance controls early. **OpenClaw integration** gives 20+ channels without duplicating logic. **Admin analytics dashboard** for journey visualization. Mock adapter for deterministic CI.
- **Transition line:** "That discipline is why we were able to ship quickly across phases."

### Slide 8 — Implementation Flow
- **Narrative goal:** Demonstrate consistent forward progress and risk management.
- **What to emphasize:** Each phase unlocked the next; P0/P1 enabled faster delivery in P2–P5; **P7** adds OpenClaw gateway + proactive heartbeat + admin analytics without touching core orchestration.
- **Transition line:** "Beyond shipping features, we aligned the experience tightly with Credal's brand and enterprise posture."

### Slide 9 — Credal Alignment
- **Narrative goal:** Show company-context understanding, not just technical execution.
- **What to emphasize:** Product voice, brand-consistent UI, governance/compliance language, and direct alignment with Credal's agent value proposition. OpenClaw aligns with Credal's "AI agents for enterprise" positioning.
- **Transition line:** "Finally, here's the measurable impact and how this scales."

### Slide 10 — Results & What's Next
- **Narrative goal:** End with credibility: measurable outcomes, economics, and realistic next milestones.
- **What to emphasize:** KPI targets, per-session cost model, and roadmap: OpenClaw gateway live with WhatsApp + Telegram, proactive heartbeat, admin analytics, eval CI, calendar integration.
- **Close line:** "The orchestrator doesn't care which channel the user is on. OpenClaw gives us 20+ channels with zero logic duplication — and proactive follow-ups that no form-based onboarding can match."
