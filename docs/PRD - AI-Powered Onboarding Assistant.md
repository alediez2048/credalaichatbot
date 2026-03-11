# PRODUCT REQUIREMENTS DOCUMENT
# AI-Powered Onboarding Assistant

*Empathetic AI-Driven User Onboarding with Intelligent Data Entry*

---

| Field | Value |
|---|---|
| **Version** | 1.1 |
| **Date** | March 10, 2026 |
| **Author** | Alex Diez |
| **Status** | ACTIVE |
| **Category** | AI-SOLUTION |
| **Stack** | Ruby on Rails, JavaScript, TypeScript |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement & Market Context](#2-problem-statement--market-context)
3. [Product Vision & Success Metrics](#3-product-vision--success-metrics)
4. [User Personas](#4-user-personas)
5. [Architecture Overview](#5-architecture-overview)
6. [Form Factor & User Journey](#6-form-factor--user-journey)
7. [Phase 0 — Foundation & Setup (Day 1, Hours 0-4)](#7-phase-0--foundation--setup)
8. [Phase 1 — AI Chatbot Core (Day 1, Hours 4-24)](#8-phase-1--ai-chatbot-core)
9. [Phase 2 — Document Processing & OCR (Days 2-3)](#9-phase-2--document-processing--ocr)
10. [Phase 3 — Intelligent Scheduling (Day 3-4)](#10-phase-3--intelligent-scheduling)
11. [Phase 4 — Emotional Support Layer (Day 4-5)](#11-phase-4--emotional-support-layer)
12. [Phase 5 — Observability & Evals (Day 5-6)](#12-phase-5--observability--evals)
13. [Phase 6 — Polish, Deploy & Ship (Day 6-7)](#13-phase-6--polish-deploy--ship)
14. [Risk Register](#14-risk-register)
15. [Appendices](#15-appendices)

---

## 1. Executive Summary

This PRD defines the requirements, architecture, and delivery plan for an AI-Powered Onboarding Assistant — a standalone web application with a landing page and full-screen chatbot experience that guides users through multi-step onboarding workflows using LLM-based chat, OCR document processing, intelligent scheduling, and emotional support content.

The product is architected to align with Credal.ai's secure enterprise AI agent platform. It demonstrates the type of domain-specific, tool-calling AI agent that enterprises build on Credal: multi-step orchestration, document processing, compliance awareness, and security-first data handling.

The primary demo use case is HR Employee Onboarding — new hires land on a welcoming page, click "Start Onboarding," and enter a chat-first experience where they upload ID documents, have data auto-extracted via OCR, schedule orientation sessions, and receive empathetic guidance throughout — mapping directly to Credal's own Onboarding Buddy and Benefits Buddy patterns.

**Form factor: Landing page → full-screen chatbot. The chat IS the onboarding experience.**

**Delivery: 7-day sprint. Solo developer. MVP at 24 hours, full feature set at Day 4, final polish and deployment by Day 7.**

---

## 2. Problem Statement & Market Context

### 2.1 The Problem

Users seeking specialized services face onboarding processes that are transactional, tedious, and emotionally tone-deaf. Current systems suffer from:

- Complex multi-step data entry with no intelligent assistance
- Manual document processing requiring users to re-type information from physical documents
- Confusing scheduling interfaces disconnected from the onboarding flow
- Zero emotional awareness — users under stress receive no support or pacing adjustment
- High drop-off rates (industry average: 40-60% abandonment on multi-step forms)

### 2.2 Market Context: Credal.ai Alignment

Credal.ai is the secure enterprise AI agent platform. Their customers (Wise, Checkr, MongoDB) use Credal to build domain-specific AI agents that automate complex workflows while enforcing enterprise-grade security, permissions, and compliance.

Credal's own documented patterns include the Onboarding Buddy (internal new-hire assistant) and the Benefits Buddy (HR policy Q&A). This project extends those patterns into a full-featured onboarding system with document processing and scheduling — demonstrating the kind of agent Credal's platform enables at scale.

### 2.3 Key Credal Principles to Embody

| Principle | How We Implement It |
|---|---|
| Security-first data handling | PII encrypted at rest, auto-deleted after extraction, audit trail on all AI interactions |
| Permission-aware access | Users only see their own onboarding data; admin role for oversight |
| Full traceability | Every LLM call, tool execution, and document processing event is logged with trace IDs |
| Zero-data-retention mindset | Uploaded documents deleted after OCR extraction; no raw PII in logs |
| Agent orchestration | Multi-step tool-calling workflow with 9 defined functions and validation layers |

---

## 3. Product Vision & Success Metrics

### 3.1 Vision Statement

Transform onboarding from a transactional form-filling exercise into a guided, empathetic conversation that feels human — where AI handles the tedious work (data extraction, scheduling, validation) so users can focus on the decisions that matter.

### 3.2 Success Metrics

| Metric | Target | Measurement |
|---|---|---|
| Onboarding completion rate | >70% | Users who start / users who finish |
| Chatbot response latency | <3 seconds | P95 time from user message to first token |
| OCR field extraction accuracy | >85% | Correctly mapped fields / total fields |
| OCR processing time | <10 seconds | Upload to extracted data available |
| Sentiment detection accuracy | >80% | Correct frustration/confusion flags vs ground truth |
| Concurrent user support | 10+ | Load test without degradation |
| Per-session AI cost | <$0.50 | Total LLM + OCR API costs per completed session |
| Eval pass rate | >80% | Passing test cases / total test cases (50+ suite) |

---

## 4. User Personas

### 4.1 Primary: New Employee (HR Onboarding)

Sarah, 28, just accepted a software engineering role. It's her first day and she's juggling excitement with anxiety. She needs to submit her ID, tax forms, banking info, and schedule orientation — but she's on her phone between meetings. She wants the process to be quick, guided, and forgiving of mistakes.

### 4.2 Secondary: Compliance Officer

Marcus, 42, manages KYC document collection for a financial services firm. He needs to verify that new customers have submitted valid identity documents, that extracted data matches across sources, and that the audit trail is complete. He cares about accuracy, compliance, and the ability to review AI decisions.

### 4.3 Tertiary: HR Administrator

Priya, 35, runs onboarding for a 500-person company. She wants to see which new hires have completed onboarding, where people get stuck, and what the AI is doing with their data. She needs a dashboard, not a chatbot.

---

## 5. Architecture Overview

### 5.1 System Architecture

| Layer | Technology | Purpose |
|---|---|---|
| Backend | Ruby on Rails 7 (monolith) | API, business logic, orchestration |
| Frontend | Hotwire + React (chat component) | Server-rendered pages + rich chat UX |
| Database | PostgreSQL + Redis | Persistent storage + caching/sessions/queues |
| LLM (primary) | OpenAI GPT-4o | Chatbot, function calling, OCR augmentation |
| LLM (lightweight) | OpenAI GPT-4o-mini | Sentiment detection, summarization |
| LLM (fallback) | Anthropic Claude Sonnet 4.6 | Resilience, emotional tone |
| OCR (primary) | OpenAI Vision (GPT-4o) | Document text extraction |
| OCR (fallback) | Google Cloud Vision | Structured OCR with confidence scores |
| Background jobs | Sidekiq + Redis | Async OCR, summaries, audit logs |
| Real-time | Action Cable (WebSockets) | LLM token streaming, status updates |
| Auth | Devise + OmniAuth | Email/password + Google OAuth |
| Observability | LangSmith or Langfuse | Tracing, evals, cost tracking |
| Hosting | Render or Heroku | Managed PaaS with WebSocket support |
| CI/CD | GitHub Actions | Tests, evals, linting, auto-deploy |

### 5.2 Service Layer Architecture

The Rails monolith uses a service object pattern to separate concerns. All AI interactions flow through an OnboardingOrchestrator that coordinates between specialized services:

| Service | Responsibility |
|---|---|
| OnboardingOrchestrator | Coordinates the full onboarding flow, manages state transitions |
| LLM::ChatService | Handles LLM API calls (OpenAI, Anthropic) |
| LLM::ContextBuilder | Assembles prompts with form state, history, tool definitions |
| LLM::StreamingService | Streams tokens via Action Cable to the chat UI |
| OCR::ExtractionService | Processes document images, returns extracted fields |
| OCR::ValidationService | Validates extracted data against document type schemas |
| Scheduling::AvailabilityService | Manages available appointment slots |
| Scheduling::BookingService | Creates and modifies bookings |
| Sentiment::AnalysisService | Detects user emotional state from conversation |
| Tools::Router | Maps LLM function calls to service objects |
| Tools::SchemaValidator | Validates tool call parameters before execution |

### 5.3 Tool Calling Schema

The LLM has access to 9 defined tools via native function calling:

| Tool | Type | Purpose |
|---|---|---|
| startOnboarding(userId, sessionId) | Write | Initialize a new onboarding session |
| extractDocumentData(imageFile, documentType) | Write | Process uploaded document via OCR |
| validateExtractedData(fields, formSchema) | Read | Check extracted fields against schema |
| getAvailableSlots(dateRange, serviceType) | Read | Fetch available appointment slots |
| bookAppointment(userId, slotId, serviceType) | Write | Book an appointment |
| detectUserSentiment(messageHistory) | Read | Analyze emotional state |
| getSupportContent(context, sentimentLevel) | Read | Retrieve emotional support content |
| saveOnboardingProgress(userId, step, data) | Write | Persist current form state |
| getOnboardingState(userId) | Read | Load saved progress for session resumption |

Write operations require user confirmation before execution. All tool calls pass through schema validation and domain constraint checking before reaching the service layer.

---

## 6. Form Factor & User Journey

### 6.1 Product Form Factor

The application is a **standalone web app** with two screens:

1. **Landing page** (`/`) — A brief, polished hero section that explains what the assistant does and provides a clear call-to-action to begin onboarding. Includes sign up / sign in links. This is the first thing demo viewers and evaluators see.
2. **Chat interface** (`/onboarding`) — A full-screen, chat-first experience where the AI assistant guides the user through the entire onboarding flow. This is the core product. All data collection, document upload, scheduling, and emotional support happen inside the chat.

This is **not**:
- A Credal.ai marketing clone or brand replica
- A multi-page form wizard with a chatbot sidebar
- An embeddable chat widget

The chat IS the onboarding. The landing page provides context and a professional entry point for the demo.

### 6.2 Screen-by-Screen User Journey

```
Landing Page (/)
├── Hero: "AI-Powered Onboarding Assistant"
├── Subtext: "Complete your onboarding in minutes with AI guidance"
├── CTA: [Start Onboarding] → redirects to /onboarding
├── Secondary: [Sign In] → Devise login → redirects to /onboarding
└── Footer: Built for Credal.ai · Powered by GPT-4o

Chat Interface (/onboarding)
├── Full-screen chat layout (messages + input bar)
├── Anonymous users can chat immediately
├── Auth required before document upload (inline prompt)
├── Streaming AI responses with typing indicator
├── Inline document upload + OCR preview
├── Inline scheduling slot selection
├── Progress indicator (steps completed)
└── Completion screen with summary + calendar download
```

### 6.3 Navigation & Layout

- **Landing page**: Minimal nav — logo, sign in/sign up links. No sidebar, no complex navigation.
- **Chat interface**: No nav bar in the chat view — full-screen immersive experience. A small back/exit link in the header. Progress indicator (e.g., "Step 2 of 5") visible but unobtrusive.
- **Admin dashboard** (P1, post-MVP): Separate `/admin` route behind role check. Not part of the user-facing product.

### 6.4 Golden Path Demo Flow (3-5 minutes)

This is the exact sequence shown in the demo video:

1. **Landing page** → viewer sees a clean, professional page explaining the product
2. **Click "Start Onboarding"** → transition to the chat interface
3. **AI greets the user** → "Welcome! I'll help you complete your onboarding. Let's start with some basic information."
4. **Conversational data collection** → name, email, department (2-3 turns)
5. **AI prompts document upload** → "Could you upload a photo of your driver's license?"
6. **User uploads ID** → OCR processes in background, progress shown inline
7. **AI presents extracted data** → "I found the following — please confirm or correct"
8. **Emotional support moment** → "You're doing great — just two more steps!"
9. **AI initiates scheduling** → "Let's book your orientation. Here are available slots."
10. **User selects slot** → AI confirms booking with summary
11. **Completion** → celebratory message, next steps, calendar download link

---

## 7. Phase 0 — Foundation & Setup

**Day 1, Hours 0-4 | 4 tickets | Estimated: 4 hours**

---

### `P0-001` — Rails project scaffolding & database setup
**Priority: P0** | **Estimate: 1.5 hours**

Initialize Rails 7 app with PostgreSQL, Redis, Sidekiq, Action Cable, Devise. Create core data models: User, OnboardingSession, Message, Document, ExtractedField, Booking, AuditLog.

**Acceptance Criteria:**
- ✓ Rails app boots with `bin/dev` and serves a homepage
- ✓ Database migrations run successfully with all core tables
- ✓ Devise authentication works (signup, login, logout)
- ✓ Sidekiq processes jobs from Redis queue
- ✓ Action Cable WebSocket connection establishes in browser

---

### `P0-002` — AI service layer & tool calling infrastructure
**Priority: P0** | **Estimate: 1.5 hours**

Build the Tools::Router, Tools::SchemaValidator, LLM::ChatService, and LLM::ContextBuilder. Define all 9 tool schemas as YAML configs. Wire up OpenAI API with function calling.

**Acceptance Criteria:**
- ✓ Tools::Router maps function names to service objects
- ✓ SchemaValidator rejects invalid tool call parameters with structured errors
- ✓ LLM::ChatService sends a message and receives a function call response
- ✓ Tool definitions load from config/prompts/tool_definitions.yml
- ✓ Integration test: send a chat message, receive a tool call, execute it, return result

---

### `P0-003` — Prompt management system
**Priority: P0** | **Estimate: 0.5 hours**

Create config/prompts/ directory with YAML files for system prompt, tool definitions, emotional support templates, and document type schemas. Build a PromptLoader service that version-tracks which prompts are active.

**Acceptance Criteria:**
- ✓ System prompt loads from YAML and is injected into every LLM call
- ✓ Prompts are version-controlled in git (not hardcoded in Ruby)
- ✓ Changing a prompt file does not require a code change

---

### `P0-004` — Observability & tracing setup
**Priority: P0** | **Estimate: 0.5 hours**

Integrate LangSmith or Langfuse. Instrument LLM::ChatService to log every API call with: input tokens, output tokens, latency, tool calls, model version, session ID, and trace ID.

**Acceptance Criteria:**
- ✓ Every LLM call appears in the observability dashboard with full trace
- ✓ Token counts and latency are captured per request
- ✓ Traces are linked to OnboardingSession IDs for debugging

---

## 8. Phase 1 — AI Chatbot Core

**Day 1, Hours 4-24 | 7 tickets | Estimated: 14-18 hours | MVP GATE**

---

### `P1-000` — Landing page & routing
**Priority: P0** | **Estimate: 2 hours**

Build the landing page at `/` with hero section, product description, and "Start Onboarding" CTA. Add `/onboarding` route that renders the chat view. Landing page uses Hotwire/server-rendered HTML (no React needed). Tailwind CSS or minimal custom styling for a clean, professional look. Mobile-responsive.

**Acceptance Criteria:**
- ✓ `/` shows a polished landing page with product title, description, and CTA button
- ✓ "Start Onboarding" links to `/onboarding` (chat view)
- ✓ Sign in / Sign up links visible on landing page
- ✓ Authenticated users clicking CTA go directly to `/onboarding`
- ✓ `/onboarding` renders the chat container (content filled by P1-001)
- ✓ Works on mobile viewport (375px width)

---

### `P1-001` — Chat interface with streaming LLM responses
**Priority: P0** | **Estimate: 4 hours**

Build the React chat component mounted in the `/onboarding` Rails view. Messages stream token-by-token via Action Cable. Includes typing indicator, message bubbles (user vs assistant), and auto-scroll. Full-screen chat layout with minimal chrome. Mobile-responsive.

**Acceptance Criteria:**
- ✓ User types a message and sees it appear immediately
- ✓ AI response streams token-by-token with a typing indicator
- ✓ Chat scrolls to latest message automatically
- ✓ Works on mobile viewport (375px width)
- ✓ Messages persist in the database (Message model)

---

### `P1-002` — Conversational onboarding flow with state management
**Priority: P0** | **Estimate: 3 hours**

Implement OnboardingOrchestrator that manages the multi-step flow: greeting → data collection → document upload prompt → scheduling → completion. LLM::ContextBuilder injects current form state into every prompt.

**Acceptance Criteria:**
- ✓ Chatbot greets user and begins collecting basic info (name, email, department)
- ✓ Each collected field is saved via saveOnboardingProgress tool call
- ✓ System prompt includes current form state (which fields are filled, which remain)
- ✓ LLM transitions between onboarding stages naturally via conversation
- ✓ OnboardingSession tracks current_step and progress percentage

---

### `P1-003` — Session persistence & resumption
**Priority: P0** | **Estimate: 2 hours**

Save full conversation history and form state to the database. When a user returns to a paused session, reconstruct context for the LLM: load last 10 messages + structured summary of earlier context + current form state.

**Acceptance Criteria:**
- ✓ User can close browser and return to continue onboarding
- ✓ Chatbot resumes with awareness of what was already collected
- ✓ Context reconstruction stays under 15,000 tokens
- ✓ Summary generation runs as a Sidekiq job when session pauses

---

### `P1-004` — Error handling & graceful fallbacks
**Priority: P0** | **Estimate: 1.5 hours**

Handle: LLM API timeout (retry with exponential backoff), malformed tool calls (return structured error to LLM), context window overflow (trigger summarization), and unrecognized user intent (ask clarifying question).

**Acceptance Criteria:**
- ✓ LLM timeout shows 'Let me think about that...' then retries (max 3 attempts)
- ✓ Invalid tool call returns a helpful error the LLM can reason about
- ✓ After 3 consecutive misunderstandings, chatbot offers structured form fallback
- ✓ All errors are logged in the tracing system with error category

---

### `P1-005` — Anonymous-to-authenticated session merge
**Priority: P0** | **Estimate: 1 hour**

Allow users to chat anonymously, then require authentication before document upload. Merge the anonymous OnboardingSession and Messages into the authenticated User record on signup/login.

**Acceptance Criteria:**
- ✓ New visitor can immediately start chatting without login
- ✓ Document upload endpoint requires authentication
- ✓ On signup, anonymous session data transfers to the new User
- ✓ No data is lost during the merge

---

### `P1-006` — Rate limiting & abuse prevention
**Priority: P1** | **Estimate: 1 hour**

Implement Rack::Attack to rate-limit: 30 LLM turns per session, 5 document uploads per session, 100 requests per IP per minute. Log anomalous patterns for review.

**Acceptance Criteria:**
- ✓ Users exceeding rate limits see a friendly message, not a crash
- ✓ Rate limit counters are stored in Redis (fast, per-session)
- ✓ Anomalous sessions (>25 turns, >5 uploads) are flagged in traces

---

## 9. Phase 2 — Document Processing & OCR

**Days 2-3 | 5 tickets | Estimated: 10-12 hours**

---

### `P2-001` — Document upload with file validation
**Priority: P0** | **Estimate: 1.5 hours**

Build document upload endpoint (Active Storage → S3/GCS). Validate: MIME type (JPG, PNG, PDF only), file size (<10MB), and file integrity (MiniMagick verification). Show inline preview in chat after upload.

**Acceptance Criteria:**
- ✓ User uploads a photo from the chat interface
- ✓ Invalid files are rejected with a clear message (wrong type, too large)
- ✓ Upload preview appears inline in the conversation thread
- ✓ Files stored with private ACLs (signed URLs for access)

---

### `P2-002` — OCR extraction pipeline (OpenAI Vision)
**Priority: P0** | **Estimate: 3 hours**

Implement OCR::ExtractionService using GPT-4o Vision. Send document image with a structured prompt per document type (from YAML config). Extract fields as JSON. Run as Sidekiq background job with Action Cable progress updates.

**Acceptance Criteria:**
- ✓ Driver's license extraction returns: full_name, date_of_birth, license_number, expiration_date, address
- ✓ Processing runs in background with real-time progress shown in chat
- ✓ Extracted data is stored in ExtractedField model with confidence scores
- ✓ Processing completes in <10 seconds for standard documents

---

### `P2-003` — Field validation & confidence-tiered review
**Priority: P0** | **Estimate: 2 hours**

Implement OCR::ValidationService with tiered confidence handling. Fields >95% auto-fill silently. Fields 80-95% highlight for quick confirmation. Fields <80% prompt manual entry via chat. All extracted data presented as an editable summary card.

**Acceptance Criteria:**
- ✓ High-confidence fields appear pre-filled in a summary message
- ✓ Low-confidence fields are presented as direct chat questions
- ✓ User can edit any field, including high-confidence ones
- ✓ Validation rules per document type loaded from YAML config

---

### `P2-004` — PII handling & document lifecycle
**Priority: P0** | **Estimate: 1.5 hours**

Encrypt extracted PII at rest (Rails 7 encrypted attributes). Auto-delete uploaded document images after successful extraction. Never log raw PII in traces — only field names and confidence scores. Implement user consent flow before first upload.

**Acceptance Criteria:**
- ✓ Uploaded images are deleted from storage after OCR completes
- ✓ PII fields in the database are encrypted at rest
- ✓ Traces show 'full_name: extracted (confidence: 0.94)' not actual values
- ✓ User sees consent prompt before first document upload

---

### `P2-005` — Document type extensibility (config-driven)
**Priority: P1** | **Estimate: 2 hours**

Design document types as YAML configuration files. Each config defines: expected fields, types, validation rules, confidence thresholds, and extraction prompts. Adding a new document type = adding a YAML file, no code changes.

**Acceptance Criteria:**
- ✓ Driver's license config exists in config/prompts/document_types/
- ✓ W-4 tax form config can be added by copying and modifying the template
- ✓ ExtractionService loads the correct config based on documentType parameter
- ✓ New document type works end-to-end with only YAML changes

---

## 10. Phase 3 — Intelligent Scheduling

**Days 3-4 | 4 tickets | Estimated: 6-8 hours**

---

### `P3-001` — Appointment slot management
**Priority: P0** | **Estimate: 1.5 hours**

Build AvailabilityService with a PostgreSQL-backed slot system. Slots have: datetime, duration, service_type, capacity, and booked_count. Admin can seed slots. Slots are cached in Redis (5-minute TTL).

**Acceptance Criteria:**
- ✓ Available slots are queryable by date range and service type
- ✓ Booked slots are excluded from availability results
- ✓ Redis cache prevents database hammering on repeated checks
- ✓ Concurrent booking protected by database-level optimistic locking

---

### `P3-002` — AI-powered slot recommendation
**Priority: P0** | **Estimate: 2 hours**

Pass available slots and user preferences to the LLM via the getAvailableSlots tool. LLM recommends the best slot based on conversation context (user mentioned 'mornings work best'). Present top 3 recommendations in chat.

**Acceptance Criteria:**
- ✓ LLM reasons about user preferences expressed during conversation
- ✓ Top 3 slots are presented with the AI's recommendation highlighted
- ✓ User can pick a recommended slot or ask to see more options
- ✓ Slot selection happens within the chat flow (no page navigation)

---

### `P3-003` — Booking confirmation & calendar event
**Priority: P0** | **Estimate: 1.5 hours**

Implement BookingService: create booking record, send confirmation message in chat with summary (date, time, location, what to bring), and generate an ICS calendar file for download.

**Acceptance Criteria:**
- ✓ Booking is created with optimistic locking (prevents double-booking)
- ✓ Confirmation message includes all booking details
- ✓ ICS file is generated and downloadable from the chat
- ✓ User can reschedule by asking the chatbot

---

### `P3-004` — Rescheduling flow
**Priority: P1** | **Estimate: 1 hour**

Handle rescheduling requests in the chat. Cancel existing booking (release the slot), show new availability, and re-book. LLM detects rescheduling intent from natural language.

**Acceptance Criteria:**
- ✓ User says 'can I change my appointment' and the AI initiates rescheduling
- ✓ Previous slot is released back to availability
- ✓ New booking follows the same confirmation flow
- ✓ Both the original and new booking appear in the audit log

---

## 11. Phase 4 — Emotional Support Layer

**Days 4-5 | 4 tickets | Estimated: 6-8 hours**

---

### `P4-001` — Sentiment analysis integration
**Priority: P0** | **Estimate: 2 hours**

Implement Sentiment::AnalysisService using GPT-4o-mini. Analyze the last 5 messages as a sliding window. Return a sentiment score (positive/neutral/frustrated/confused) with confidence. Run on every 3rd user message to control costs.

**Acceptance Criteria:**
- ✓ Sentiment is detected on every 3rd user message (configurable)
- ✓ GPT-4o-mini classifies into 4 categories with confidence score
- ✓ Results are stored on the OnboardingSession for analytics
- ✓ Sentiment detection adds <500ms to response time (parallel call)

---

### `P4-002` — Adaptive chatbot behavior
**Priority: P0** | **Estimate: 2 hours**

Modify LLM::ContextBuilder to inject current sentiment state into the system prompt. When frustration is detected: slow pacing, offer encouragement, simplify language. When confusion is detected: offer to explain, provide examples.

**Acceptance Criteria:**
- ✓ System prompt includes current emotional state as context
- ✓ Frustrated user receives simpler, more encouraging messages
- ✓ Confused user gets step-by-step explanations with examples
- ✓ Adaptation feels natural, not robotic or patronizing

---

### `P4-003` — Progress milestones & encouragement
**Priority: P1** | **Estimate: 1 hour**

Track onboarding progress percentage. At 25%, 50%, 75%, and 100% milestones, inject celebration messages. Use the getSupportContent tool to retrieve contextually appropriate encouragement.

**Acceptance Criteria:**
- ✓ Progress bar appears in the chat UI showing completion percentage
- ✓ Milestone messages feel warm and specific to what was just completed
- ✓ Completion triggers a congratulatory message with next steps

---

### `P4-004` — Escalation tiers & human handoff
**Priority: P1** | **Estimate: 1 hour**

Define escalation logic: after 3 failed parses → offer structured form fallback. After sentiment drops below threshold for 3 consecutive checks → offer to connect with a human. After 5 consecutive low-sentiment checks → suggest pausing and returning later.

**Acceptance Criteria:**
- ✓ Structured form fallback is available as a 'just fill out the form' option
- ✓ Human handoff option shows contact information (email, phone)
- ✓ System never gets stuck in a loop of 'I don't understand' messages
- ✓ Escalation events are logged in traces for quality analysis

---

## 12. Phase 5 — Observability & Evals

**Days 5-6 | 5 tickets | Estimated: 8-10 hours**

---

### `P5-001` — Eval framework & test suite (50+ cases)
**Priority: P0** | **Estimate: 4 hours**

Build a custom eval runner that executes test cases against the AI system. Each test case specifies: input message(s), expected tool call(s), expected output pattern, and pass/fail criteria. Categories: 20+ happy path, 10+ edge cases, 10+ adversarial, 10+ multi-step.

**Acceptance Criteria:**
- ✓ 50+ test cases exist across all 4 categories
- ✓ Eval runner executes in <5 minutes with mocked LLM responses
- ✓ Live eval mode (real API calls) can run against actual models
- ✓ Results show pass rate, failure reasons, and regression detection
- ✓ CI pipeline runs eval suite on every prompt change

---

### `P5-002` — End-to-end tracing dashboard
**Priority: P1** | **Estimate: 2 hours**

Ensure every onboarding session has a complete trace: user message → context assembly → LLM call → tool selection → tool execution → response generation. Include token counts, latencies, costs, and error rates.

**Acceptance Criteria:**
- ✓ Any session can be debugged by its trace ID
- ✓ Token usage and cost are visible per session and per tool call
- ✓ Latency breakdown shows where time is spent (LLM vs OCR vs DB)
- ✓ Failed sessions show exactly where and why they failed

---

### `P5-003` — Cost tracking & projection model
**Priority: P1** | **Estimate: 1.5 hours**

Build a cost tracking module that aggregates: LLM token costs (by model), OCR processing costs, total per-session cost, and running monthly total. Project costs at 100, 1K, 10K, and 100K user scales.

**Acceptance Criteria:**
- ✓ Per-session cost is visible in the admin dashboard
- ✓ Monthly cost projection table is generated from actual usage data
- ✓ Cost breakdown by component (chatbot vs OCR vs sentiment) is available
- ✓ Alerts fire if per-session cost exceeds $0.50 threshold

---

### `P5-004` — Admin analytics dashboard
**Priority: P1** | **Estimate: 1.5 hours**

Build a simple Rails admin view showing: total sessions, completion rate, average session duration, OCR accuracy, sentiment distribution, drop-off funnel (which step users abandon), and cost metrics.

**Acceptance Criteria:**
- ✓ Dashboard loads in <2 seconds
- ✓ Key metrics are visible at a glance (no scrolling for critical stats)
- ✓ Drop-off funnel shows exactly where users abandon onboarding
- ✓ Data refreshes on page load (no real-time requirement)

---

### `P5-005` — Prompt regression testing in CI
**Priority: P1** | **Estimate: 1 hour**

Add a GitHub Actions workflow that detects changes to config/prompts/ files and automatically runs the eval suite. Fail the PR if pass rate drops below 80%.

**Acceptance Criteria:**
- ✓ PRs changing prompt files trigger the eval suite automatically
- ✓ Eval results are posted as a PR comment with pass/fail summary
- ✓ PRs that drop eval pass rate below 80% are blocked from merging

---

## 13. Phase 6 — Polish, Deploy & Ship

**Days 6-7 | 5 tickets | Estimated: 8-10 hours**

---

### `P6-001` — Production deployment
**Priority: P0** | **Estimate: 2 hours**

Deploy to Render or Heroku with: PostgreSQL, Redis, Sidekiq worker, Action Cable support, SSL, and environment variables for all API keys. Verify WebSocket streaming works in production.

**Acceptance Criteria:**
- ✓ App is publicly accessible at a custom URL
- ✓ WebSocket streaming works (tokens appear incrementally)
- ✓ Background jobs process OCR uploads in production
- ✓ All API keys are in environment variables, not in code

---

### `P6-002` — Demo video recording (3-5 min)
**Priority: P0** | **Estimate: 2 hours**

Record the golden path demo: landing page → "Start Onboarding" CTA → chat greeting → data collection → document upload + OCR → field verification → scheduling → emotional support moment → completion. Include one error recovery scenario (bad photo → retry). Show observability dashboard briefly.

**Acceptance Criteria:**
- ✓ Video shows the complete onboarding flow in under 5 minutes
- ✓ OCR extraction is visibly demonstrated with a real document
- ✓ Emotional support response is naturally triggered
- ✓ Observability dashboard shows real traces from the demo

---

### `P6-003` — GitHub repository documentation
**Priority: P0** | **Estimate: 1.5 hours**

Write README.md with: project overview, architecture diagram (Mermaid), setup guide (local dev + production), environment variables, and deployed link. Include AI Development Log and Pre-Search document.

**Acceptance Criteria:**
- ✓ New developer can set up the project following only the README
- ✓ Architecture diagram shows all major components and data flow
- ✓ Deployed link is clickable and working
- ✓ Pre-Search and AI Development Log are linked from the README

---

### `P6-004` — AI cost analysis report
**Priority: P1** | **Estimate: 1 hour**

Generate the cost analysis deliverable: actual development spend, per-session cost breakdown, and projections for 100/1K/10K/100K users. Include assumptions about session length, tool call frequency, and OCR usage.

**Acceptance Criteria:**
- ✓ Development spend is documented with actual API costs
- ✓ Per-session cost is broken down by component
- ✓ Projection table covers 4 user scales with stated assumptions
- ✓ Document is submission-ready

---

### `P6-005` — Social post & launch
**Priority: P1** | **Estimate: 1 hour**

Create a social media post for X or LinkedIn: project description, key features, real metrics from evals (pass rate, OCR accuracy, response latency), demo screenshot or GIF, and tag @GauntletAI.

**Acceptance Criteria:**
- ✓ Post includes real metrics, not estimates
- ✓ Screenshot or GIF shows the chat interface with OCR in action
- ✓ Post tags @GauntletAI
- ✓ Deployed link is included for people to try

---

## 14. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| OpenAI API outage during demo | Medium | Critical | Anthropic Claude fallback; pre-record backup demo video |
| OCR accuracy below 85% target | Medium | High | Fallback to Google Cloud Vision; optimize prompts per document type; limit to driver's license for MVP |
| Token costs exceed budget at scale | Medium | Medium | GPT-4o-mini for sentiment; cached responses for common questions; context window management |
| Prompt injection via chat input | Low | High | Server-side validation of all tool calls; never trust LLM output for authorization; input sanitization |
| Session state drift (LLM vs DB) | Medium | Medium | DB is canonical source of truth; inject form state into every prompt; validate on every tool call |
| Action Cable streaming fails in production | Low | High | SSE fallback endpoint; test WebSockets on target platform before final deployment |
| Solo developer burnout on 7-day sprint | High | High | Strict priority order; cut P2 tickets before compromising P0/P1; demo golden path first |

---

## 15. Appendices

### 15.1 Ticket Summary by Phase

| Phase | Tickets | P0 Count | Estimated Hours |
|---|---|---|---|
| Phase 0: Foundation & Setup | 4 | 4 | 4 hours |
| Phase 1: AI Chatbot Core | 7 | 6 | 14-18 hours |
| Phase 2: Document Processing & OCR | 5 | 4 | 10-12 hours |
| Phase 3: Intelligent Scheduling | 4 | 3 | 6-8 hours |
| Phase 4: Emotional Support Layer | 4 | 2 | 6-8 hours |
| Phase 5: Observability & Evals | 5 | 1 | 8-10 hours |
| Phase 6: Polish, Deploy & Ship | 5 | 3 | 8-10 hours |
| **TOTAL** | **34** | **23** | **56-70 hours** |

### 15.2 Priority Legend

| Priority | Definition | Count |
|---|---|---|
| P0 — Must Have | Required for MVP and project submission. Cannot ship without these. | 23 |
| P1 — Should Have | Required for full feature set. Included in early submission (Day 4). | 11 |
| P2 — Nice to Have | Polish items. Only if time permits after P0 and P1 are complete. | 0 |

### 15.3 Related Documents

- Pre-Search Appendix (presearch-appendix.md) — All 18 architecture decisions with rationale
- Architecture Interview (interviews.md) — 30 deep-dive questions across 3 rounds
- Credal Research (credal-research.md) — Product analysis and use case mapping
- Requirements Document (credalrequirements.md) — Original project requirements and pre-search checklist

---

> *A simple, empathetic onboarding flow with reliable AI assistance beats a feature-rich system with broken data extraction and confusing UX.*

**Project completion is required for Austin admission.**
