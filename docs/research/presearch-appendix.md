# Pre-Search Appendix — AI-Powered Onboarding Assistant

**Project:** AI-Powered Onboarding Assistant
**Category:** AI-SOLUTION
**Required Languages:** Ruby on Rails, JavaScript, TypeScript
**Date:** March 9, 2026

---

Complete this before writing code. Save your AI conversation as a reference document. The goal is to make an informed decision about all relevant aspects of your project. Understand tradeoffs, strengths and weaknesses, and make a decision that you can defend. You don't have to be right, but you do have to show your thought process.

---

## Phase 1: Define Your Constraints

### 1. Scale & Load Profile

**Users at launch? In 6 months?**

At launch (demo/MVP): 10-50 concurrent users for evaluation and testing. At 6 months: targeting 1,000-5,000 active users if adopted as an internal tool at a company like Credal, or 10,000+ if offered as a B2B SaaS onboarding product for multiple enterprise customers.

**Traffic pattern: steady, spiky, or unpredictable?**

Spiky. Onboarding traffic correlates with business events — new employee cohorts (monthly/quarterly), new customer signups (campaign-driven), or compliance deadlines (regulatory cycles). Expect Monday mornings and start-of-month peaks. The system must handle 3-5x average load during spikes without degradation.

**Real-time requirements (websockets, live updates)?**

Yes. The chatbot requires real-time streaming of LLM responses (token-by-token) for a natural conversational UX. Action Cable (Rails WebSockets) or Server-Sent Events for streaming. OCR processing status updates should push to the client in real-time rather than requiring polling. No multi-user real-time collaboration needed (unlike CollabBoard) — each onboarding session is single-user.

**Cold start tolerance?**

Moderate. Users expect the first chatbot message within 2-3 seconds of starting onboarding. If using serverless (Lambda/Cloud Functions) for OCR processing, cold starts of 5-10 seconds are acceptable since document upload is an explicit user action with expected wait time. The main Rails app should be always-warm on a persistent dyno/container.

---

### 2. Budget & Cost Ceiling

**Monthly spend limit?**

Development phase: $50-100/month (LLM API calls during development and testing). Production at 1,000 users: target $200-500/month total AI costs. Production at 10,000 users: budget ceiling of $2,000-3,000/month. Key constraint: per-session AI cost must stay under $0.15 to be viable at scale.

**Pay-per-use acceptable or need fixed costs?**

Pay-per-use is preferred for AI APIs (OpenAI, Claude, OCR services) since usage scales with actual onboarding volume. Fixed costs are acceptable for infrastructure (database, hosting, Redis). The hybrid model works: fixed base infrastructure + variable AI costs. Avoid services with steep pricing cliffs (e.g., OCR services that charge per-page with minimum commitments).

**Where will you trade money for time?**

- Use managed services over self-hosted: Heroku/Render over raw EC2, managed PostgreSQL over self-administered
- Use cloud OCR (Google Cloud Vision or OpenAI Vision) over self-hosted Tesseract — accuracy matters more than cost savings for MVP
- Use a pre-built auth solution (Devise + OmniAuth) over custom authentication
- Use Action Cable (built into Rails) over a separate WebSocket service
- Pay for LangSmith/Langfuse over building custom observability from scratch

---

### 3. Time to Ship

**MVP timeline?**

24 hours for core MVP (chatbot + one document type OCR + basic scheduling). 4 days for early submission (full feature set including emotional support, session persistence, multiple document types). 7 days for final submission (polish, documentation, deployment, demo video, social post).

**Speed-to-market vs. long-term maintainability priority?**

Speed-to-market for the sprint, but with architectural guardrails for maintainability. Specifically: use Rails conventions (MVC + service objects), keep prompts in version-controlled YAML files (not hardcoded), design document types as configuration (not code), and write evals from day one. Accept technical debt in: UI polish, comprehensive error handling, and multi-language support. Do not accept technical debt in: data model design, AI service layer architecture, or security/PII handling.

**Iteration cadence after launch?**

Weekly iterations post-sprint. First iteration: address eval failures and user feedback from demo testing. Second iteration: add second document type and improve OCR accuracy. Third iteration: analytics dashboard and admin controls. Longer term: multi-tenancy for different onboarding domains.

---

### 4. Compliance & Regulatory Needs

**Health data (HIPAA)?**

Not for MVP, but architecture should not preclude it. If the onboarding assistant is used for healthcare employee onboarding or patient intake, HIPAA applies. Design decision: encrypt PII at rest (Rails 7 encrypted attributes), auto-delete uploaded documents after extraction, never log raw PII in traces. These practices satisfy HIPAA requirements without requiring full compliance certification for the sprint.

**EU users (GDPR)?**

Not a launch requirement, but relevant if serving enterprise customers with EU employees. Design decision: implement data minimization (only collect required fields), provide a clear consent flow before document upload, and ensure the ability to delete all user data on request. Choose AI providers with EU data processing agreements (OpenAI and Anthropic both offer these).

**Enterprise clients (SOC 2)?**

Relevant given Credal's own SOC 2 Type II compliance. The onboarding assistant should demonstrate SOC 2-aligned practices: audit logging of all AI interactions, access controls on user data, encrypted data at rest and in transit, and documented data retention policies. Full SOC 2 certification is out of scope for the sprint, but the architecture should support it.

**Data residency requirements?**

Not for MVP. If required later, the architecture supports it: use cloud providers with regional deployment options (AWS regions, GCP regions), and choose AI providers that offer regional endpoints (Azure OpenAI for in-region, AWS Bedrock for in-VPC). PostgreSQL and Redis can be deployed in any region.

---

### 5. Team & Skill Constraints

**Solo or team?**

Solo developer for the sprint.

**Languages/frameworks you know well?**

Ruby on Rails (primary backend), JavaScript/TypeScript (frontend), React or Stimulus/Hotwire for UI. Familiar with PostgreSQL, Redis, Sidekiq. Experience with OpenAI and Anthropic APIs. OCR is new territory — will rely on cloud APIs rather than building from scratch.

**Learning appetite vs. shipping speed preference?**

Shipping speed for core features (chatbot, OCR, scheduling). Learning appetite for: observability tooling (LangSmith or Langfuse — new but worth the investment), eval frameworks (new but required by the project), and Action Cable streaming patterns for LLM responses. Will not learn: new frontend frameworks (stick with what's known), new databases (PostgreSQL is sufficient), or new deployment platforms (use familiar Heroku/Render).

---

## Phase 2: Architecture Discovery

### 6. Hosting & Deployment

**Serverless vs. containers vs. edge vs. VPS?**

**Decision: Containers (managed PaaS)** — Heroku or Render.

Rails is not well-suited for serverless (cold starts, connection pooling issues). A managed PaaS provides: persistent processes for Action Cable WebSockets, built-in PostgreSQL and Redis add-ons, simple CI/CD via git push, and automatic SSL. Render is preferred over Heroku for cost (free tier for background workers) but Heroku is acceptable for familiarity.

OCR processing can optionally run as a background job (Sidekiq) rather than a separate service, keeping the architecture simple for the sprint.

**CI/CD requirements?**

GitHub Actions for: running RSpec tests on push, running eval suite against prompt changes, linting (RuboCop + ESLint), and auto-deploy to Render/Heroku on merge to main. The eval suite is the critical addition — every PR that changes a prompt file must trigger the eval pipeline.

**Scaling characteristics?**

Horizontal scaling via additional web dynos/instances. Sidekiq workers scale independently for OCR and LLM background jobs. PostgreSQL connection pooling via PgBouncer if needed at scale. Redis handles session storage and Sidekiq queues. At 10,000 users: 2-3 web instances, 2 Sidekiq workers, 1 PostgreSQL instance, 1 Redis instance.

---

### 7. Authentication & Authorization

**Auth approach: social login, magic links, email/password, SSO?**

**Decision: Email/password via Devise, with optional OAuth (Google) for convenience.**

For the MVP, Devise with email/password is fastest to implement and universally supported. Add Google OAuth via OmniAuth for enterprise users who prefer SSO-like convenience. Full SAML/SSO is out of scope for the sprint but the Devise architecture supports adding it later (devise_saml_authenticatable gem).

Critical UX decision: allow anonymous chatbot interaction before requiring authentication. Require login before document upload (PII protection). Merge anonymous session into authenticated user on signup. This maximizes the "wow factor" of immediately talking to the AI while protecting sensitive data.

**RBAC needed?**

Minimal for MVP. Two roles: `user` (completing onboarding) and `admin` (viewing analytics, managing templates). Implement with a simple `role` enum on the User model. Full RBAC (Pundit or CanCanCan) can be added post-sprint if multi-tenancy is needed.

**Multi-tenancy considerations?**

Not for MVP, but the data model should support it. Add an `organization_id` foreign key to `OnboardingSession` and `User` models even if only one organization exists initially. This enables multi-tenancy later without a data migration. Each organization would have its own onboarding templates, document types, and scheduling rules — aligning with Credal's multi-tenant platform architecture.

---

### 8. Database & Data Layer

**Database type: relational, document, key-value?**

**Decision: PostgreSQL (relational) + Redis (key-value for caching/sessions).**

PostgreSQL handles: user accounts, onboarding sessions, conversation history, extracted document data, appointment bookings, and audit logs. JSONB columns for flexible schema where needed (extracted OCR fields, conversation metadata). Redis handles: session storage, Sidekiq job queues, rate limiting counters, and caching (available appointment slots, prompt templates).

**Real-time sync, full-text search, vector storage, caching needs?**

- Real-time sync: Not needed (single-user sessions). Action Cable handles real-time UI updates.
- Full-text search: Not needed for MVP. PostgreSQL's built-in `tsvector` is sufficient if search is added later.
- Vector storage: Not needed for MVP. If RAG is added (e.g., searching company policy documents for the Benefits Buddy pattern), use pgvector extension rather than a separate vector database.
- Caching: Redis for appointment slot availability (cache for 5 minutes), prompt template versions (cache until invalidated), and rate limiting counters.

**Read/write ratio?**

Approximately 60/40 read/write during active onboarding. High write volume during data collection (saving form fields, conversation turns, OCR results). High read volume during context reconstruction (loading conversation history, form state for each LLM call). Post-onboarding is 95/5 read (admin viewing completed sessions, audit logs).

---

### 9. Backend/API Architecture

**Monolith or microservices?**

**Decision: Monolith (Rails).**

A monolith is the correct choice for a solo developer on a 7-day sprint. Rails conventions, shared database, single deployment unit, and simplified debugging. The service object pattern provides internal modularity without the overhead of network boundaries.

Service layer structure within the monolith:
- `app/services/onboarding/orchestrator.rb` — coordinates the onboarding flow
- `app/services/llm/chat_service.rb` — handles LLM API calls
- `app/services/llm/context_builder.rb` — assembles prompts with state
- `app/services/ocr/extraction_service.rb` — document processing
- `app/services/ocr/validation_service.rb` — field validation
- `app/services/scheduling/availability_service.rb` — slot management
- `app/services/scheduling/booking_service.rb` — appointment creation
- `app/services/sentiment/analysis_service.rb` — emotion detection
- `app/services/tools/router.rb` — maps LLM tool calls to service objects

**REST vs. GraphQL vs. tRPC vs. gRPC?**

**Decision: REST (Rails default) + Action Cable for streaming.**

REST for standard CRUD operations (sessions, documents, bookings). Action Cable WebSocket channel for real-time chat streaming. No need for GraphQL complexity — the API surface is small and well-defined. tRPC/gRPC are not relevant for a Rails monolith.

**Background job and queue requirements?**

**Decision: Sidekiq with Redis.**

Background jobs for:
- OCR document processing (5-15 seconds, should not block the request cycle)
- Conversation summary generation (when a session pauses, generate a context summary for resumption)
- Audit log writes (non-blocking, can be slightly delayed)
- Email notifications (appointment confirmations, onboarding completion)
- Eval suite execution (triggered by CI or manually)

Queue priorities: `critical` (tool call execution), `default` (OCR processing, summaries), `low` (audit logs, emails, analytics).

---

### 10. Frontend Framework & Rendering

**SEO requirements (SSR/static)?**

None. The onboarding assistant is an authenticated application, not a public content site. No SEO needed.

**Offline support/PWA?**

Not for MVP. Onboarding requires active LLM and OCR API calls, so offline mode provides no value. A PWA wrapper could be added later for mobile app-like experience.

**SPA vs. SSR vs. static vs. hybrid?**

**Decision: Hybrid — Rails server-rendered views with Hotwire (Turbo + Stimulus) for interactivity, plus a dedicated React component for the chat interface.**

Rationale: Rails views with Hotwire handle the standard pages (login, dashboard, settings, admin). The chat interface is the one area where a React component provides significantly better UX — streaming token rendering, dynamic message bubbles, inline document previews, and smooth animations. Mount the React chat component via `react-rails` gem or a standalone bundle imported into the Rails view.

This avoids a full SPA build while getting React's strengths where they matter most.

---

### 11. AI/LLM Integration

**Which LLM provider and model?**

**Decision: OpenAI GPT-4o (primary) with Anthropic Claude Sonnet 4.6 as fallback.**

GPT-4o provides: excellent function calling support, vision capabilities (for OCR augmentation), fast response times, and well-documented API. Claude Sonnet 4.6 as fallback provides: resilience if OpenAI has outages, potentially better emotional tone for support content, and 200K context window for long conversations.

For sentiment detection specifically: use GPT-4o-mini (cheaper, faster, sufficient accuracy for classification tasks). This saves cost on the highest-frequency AI call in the system.

**Function calling vs. prompt-based tool use?**

**Decision: Native function calling (OpenAI format).**

Native function calling provides: structured JSON output, explicit tool schemas the model can reason about, and cleaner parsing than regex-based prompt extraction. Define all 9 tools as OpenAI function schemas. Implement a `ToolRouter` service that validates the function call JSON, maps it to the corresponding Rails service object, executes it, and returns structured results.

Add a validation layer between the LLM's tool call and execution:
1. Schema validation (does the JSON match the expected shape?)
2. Domain validation (does the slotId exist? is the userId valid?)
3. Permission validation (is this user allowed to perform this action?)
4. Confirmation gate (for write operations like booking, ask user to confirm)

**Context window needs for conversation history?**

A typical onboarding session: ~8,000-12,000 tokens for a 15-20 turn conversation including system prompt, tool calls, OCR results, and form state. GPT-4o's 128K context is more than sufficient. However, cost scales with tokens, so implement:

- Sliding window: keep the last 10 conversation turns in full
- Summarized history: for turns older than 10, inject a structured summary
- Form state injection: always include current form state (200-400 tokens) at the start
- OCR results: include only the most recent extraction, not historical ones

Target: keep total context per request under 15,000 tokens for cost control.

**Cost per interaction acceptable?**

Target: $0.01-0.02 per LLM call (GPT-4o at current pricing). With 15-20 calls per session, that's $0.15-0.40 per complete onboarding session. Sentiment detection on GPT-4o-mini: $0.001 per call. OCR via OpenAI Vision: $0.01-0.03 per document page. Total per-session target: under $0.50 including all AI costs.

---

### 12. OCR/Vision Strategy

**Cloud OCR vs. local (Tesseract)?**

**Decision: OpenAI Vision (GPT-4o with vision) as primary, Google Cloud Vision as fallback.**

OpenAI Vision advantages: single API for both OCR and field extraction (send image + structured prompt, get JSON back), handles diverse document layouts without template configuration, works well with poor image quality, and you're already paying for the OpenAI API.

Google Cloud Vision as fallback: more accurate for specific document types (IDs, forms), provides word-level bounding boxes and confidence scores, and works when you need pure OCR without LLM reasoning.

Tesseract rejected for MVP: lower accuracy on real-world documents, requires image preprocessing, needs language-specific models, and adds deployment complexity.

**Document types to support (IDs, forms, receipts)?**

MVP: **Government-issued photo ID** (driver's license, passport) — this is the primary demo use case for HR employee onboarding.

Early submission: Add **tax forms** (W-4) and **direct deposit forms** — completes the HR onboarding flow.

Final: Add **insurance cards** and **professional certifications** — enables vendor onboarding and healthcare use cases.

Each document type is defined as configuration:
```yaml
# config/document_types/drivers_license.yml
name: "Driver's License"
fields:
  - name: full_name
    type: string
    required: true
    confidence_threshold: 0.85
  - name: date_of_birth
    type: date
    required: true
    confidence_threshold: 0.90
  - name: license_number
    type: alphanumeric
    required: true
    confidence_threshold: 0.90
  - name: expiration_date
    type: date
    required: true
    confidence_threshold: 0.85
  - name: address
    type: string
    required: false
    confidence_threshold: 0.75
```

**Accuracy requirements and fallback strategy?**

Target: >85% correct field mapping (per requirements). Tiered confidence handling:
- Above 95%: auto-fill, show in summary for passive review
- 80-95%: auto-fill with yellow highlight, prompt user to confirm
- Below 80%: don't auto-fill, ask user to enter manually via chat
- Extraction failure: fall back to manual entry with a supportive message ("I had trouble reading that — could you type in your [field]?")

Fallback chain: OpenAI Vision → Google Cloud Vision → manual entry.

**Privacy implications of sending documents to external APIs?**

Critical concern. Government IDs contain highly sensitive PII. Mitigations:
- Obtain explicit user consent before uploading ("I'll need to process your document. Your data is encrypted and deleted after extraction. Do you want to proceed?")
- Use OpenAI's zero-data-retention API agreement (align with Credal's own ZDR approach)
- Delete the uploaded image from storage immediately after extraction completes
- Never log raw document images in traces — only log extracted field names (not values) and confidence scores
- Encrypt extracted PII at rest in PostgreSQL using Rails 7 encrypted attributes

---

### 13. Third-Party Integrations

**External services needed (payments, email, analytics, AI APIs)?**

| Service | Provider | Purpose |
|---|---|---|
| LLM (primary) | OpenAI (GPT-4o) | Chatbot, tool calling, OCR augmentation |
| LLM (fallback) | Anthropic (Claude Sonnet 4.6) | Fallback, emotional support content |
| LLM (lightweight) | OpenAI (GPT-4o-mini) | Sentiment detection, summarization |
| OCR (primary) | OpenAI Vision | Document text extraction |
| OCR (fallback) | Google Cloud Vision | Structured OCR with confidence scores |
| Email | Postmark or SendGrid | Appointment confirmations, onboarding completion |
| Observability | LangSmith or Langfuse | Tracing, eval tracking, cost monitoring |
| Background jobs | Sidekiq (self-hosted with Redis) | Async processing |
| Analytics | PostHog (self-hosted) or Mixpanel | Funnel tracking, drop-off analysis |

**Pricing cliffs and rate limits?**

- OpenAI: 10,000 RPM on Tier 3, sufficient for MVP. Cost scales linearly — no pricing cliffs.
- Google Cloud Vision: 1,000 free units/month, then $1.50/1,000 units. Affordable at scale.
- SendGrid: 100 emails/day free, then $15/month for 50K emails. No cliff concern.
- LangSmith: free tier for 5K traces/month, $39/month for 50K. Sufficient for development.

**Vendor lock-in risk?**

Low. The service object architecture isolates each integration behind an interface:
- `LlmService` wraps OpenAI/Anthropic — swapping providers means changing one service class
- `OcrService` wraps Vision APIs — same pattern
- `ObservabilityService` wraps tracing — can switch from LangSmith to Langfuse or custom logging
- Database is standard PostgreSQL — portable anywhere
- Hosting is standard Rails — deployable to any PaaS or container platform

---

## Phase 3: Post-Stack Refinement

### 14. Security Vulnerabilities

**Known pitfalls for your stack?**

- **Prompt injection:** Users could craft chat messages that manipulate the LLM into calling unintended tools or revealing system prompts. Mitigation: validate all tool call parameters server-side, never trust LLM output for authorization decisions, sanitize user input before including in prompts.
- **File upload attacks:** Malicious files disguised as images. Mitigation: validate MIME types server-side (not just file extension), use ImageMagick/MiniMagick to verify image integrity, enforce file size limits (10MB max), scan with ClamAV if available.
- **Mass assignment:** Rails-specific. Mitigation: strong parameters on all controllers, never expose internal IDs in API responses.
- **SQL injection:** Low risk with ActiveRecord, but raw SQL in search or reporting queries must use parameterized queries.
- **XSS in chat messages:** LLM responses rendered in the UI could contain malicious HTML. Mitigation: sanitize all LLM output before rendering, use Rails' built-in HTML escaping.

**Common misconfigurations?**

- Action Cable open to all origins (set `config.action_cable.allowed_request_origins`)
- Debug mode enabled in production (verify `config.consider_all_requests_local = false`)
- Missing rate limiting on API endpoints (implement Rack::Attack)
- Unencrypted database backups containing PII
- API keys committed to git (use Rails credentials or environment variables)

**Dependency risks?**

- OpenAI API availability (mitigate with Anthropic fallback)
- Ruby gem vulnerabilities (run `bundle audit` in CI)
- JavaScript dependency supply chain attacks (use lockfiles, audit regularly)
- Cloud OCR service deprecation (abstract behind service interface)

**Document upload security (file type validation, size limits)?**

- Allowed types: `image/jpeg`, `image/png`, `application/pdf` only
- Max file size: 10MB per upload
- Max uploads per session: 5 documents
- Server-side MIME validation (not just Content-Type header)
- Store uploads in S3/GCS with private ACLs, signed URLs for access
- Auto-delete after OCR extraction (configurable retention for compliance)

---

### 15. File Structure & Project Organization

**Standard folder structure for your framework?**

```
app/
├── channels/
│   └── onboarding_channel.rb          # Action Cable for chat streaming
├── controllers/
│   ├── conversations_controller.rb     # Chat message handling
│   ├── documents_controller.rb         # Document upload
│   ├── bookings_controller.rb          # Scheduling
│   └── admin/
│       └── dashboard_controller.rb     # Admin analytics
├── models/
│   ├── user.rb
│   ├── onboarding_session.rb
│   ├── message.rb
│   ├── document.rb
│   ├── extracted_field.rb
│   ├── booking.rb
│   └── audit_log.rb
├── services/
│   ├── onboarding/
│   │   └── orchestrator.rb             # Main flow coordinator
│   ├── llm/
│   │   ├── chat_service.rb             # LLM API calls
│   │   ├── context_builder.rb          # Prompt assembly
│   │   └── streaming_service.rb        # Token streaming
│   ├── ocr/
│   │   ├── extraction_service.rb       # Document processing
│   │   └── validation_service.rb       # Field validation
│   ├── scheduling/
│   │   ├── availability_service.rb     # Slot management
│   │   └── booking_service.rb          # Appointment creation
│   ├── sentiment/
│   │   └── analysis_service.rb         # Emotion detection
│   └── tools/
│       ├── router.rb                   # Maps tool calls to services
│       └── schema_validator.rb         # Validates tool call params
├── jobs/
│   ├── ocr_processing_job.rb
│   ├── summary_generation_job.rb
│   └── audit_log_job.rb
└── javascript/
    └── components/
        └── ChatInterface/              # React chat component
config/
├── prompts/                            # Version-controlled prompt templates
│   ├── system_prompt.yml
│   ├── tool_definitions.yml
│   ├── emotional_support.yml
│   └── document_types/
│       ├── drivers_license.yml
│       └── w4_form.yml
├── initializers/
│   ├── openai.rb
│   └── sidekiq.rb
└── routes.rb
spec/
├── services/                           # Unit tests for service objects
├── evals/                              # AI evaluation test cases
│   ├── happy_path/
│   ├── edge_cases/
│   ├── adversarial/
│   └── multi_step/
└── system/                             # End-to-end tests
```

**Monorepo vs. polyrepo?**

**Decision: Monorepo.** Single Rails application with embedded React component. No reason to split for a solo developer on a 7-day sprint. The React chat component lives inside `app/javascript/components/` and is bundled by esbuild (Rails 7 default).

**Feature/module organization?**

Organized by domain within the service layer (`onboarding/`, `llm/`, `ocr/`, `scheduling/`, `sentiment/`, `tools/`). Models are flat (Rails convention). Controllers are thin — they delegate to the orchestrator service. This structure allows any service to be extracted into a microservice later if needed (e.g., OCR processing as a separate service).

---

### 16. Naming Conventions & Code Style

**Naming patterns for your language/framework?**

- Ruby: snake_case for methods and variables, CamelCase for classes/modules
- JavaScript/TypeScript: camelCase for variables and functions, PascalCase for components
- Database: snake_case for tables and columns, plural table names (Rails convention)
- API endpoints: RESTful (`/onboarding_sessions`, `/documents`, `/bookings`)
- Service objects: verb-noun pattern (`ExtractDocumentData`, `BookAppointment`, `AnalyzeSentiment`)
- Prompt files: kebab-case YAML (`system-prompt.yml`, `drivers-license.yml`)

**Linter and formatter configs?**

- Ruby: RuboCop with `rubocop-rails`, `rubocop-rspec`, `rubocop-performance` extensions. Style: follow Rails community standards, 120 char line length.
- JavaScript: ESLint with React plugin, Prettier for formatting.
- CI: Both linters run on every push, block merge if failing.

---

### 17. Testing Strategy

**Unit, integration, e2e tools?**

| Level | Tool | What It Tests |
|---|---|---|
| Unit | RSpec | Service objects, models, validators |
| Integration | RSpec + VCR | Service objects with recorded API responses |
| System/E2E | Capybara + Selenium | Full browser flows |
| AI Evals | Custom eval framework | Prompt quality, tool selection, response tone |
| API Mocking | WebMock + VCR | Record and replay OpenAI/OCR API calls |

**Coverage target for MVP?**

- Service objects: >80% coverage (these are the critical business logic)
- Models: >90% coverage (validations, associations, scopes)
- Controllers: >60% coverage (thin controllers, most logic in services)
- AI evals: 50+ test cases as required (20+ happy path, 10+ edge cases, 10+ adversarial, 10+ multi-step)
- Overall: >70% line coverage

**Mocking patterns?**

- VCR cassettes for all external API calls (OpenAI, OCR, calendar). Record once, replay in CI.
- Factory Bot for test data (users, sessions, documents, bookings)
- WebMock to prevent accidental real API calls in test suite
- Custom LLM mock for eval testing: a deterministic response generator that simulates tool calls without hitting the real API
- Separate test suite for "live evals" that hit real APIs (run manually, not in CI, to measure actual model performance)

---

### 18. Recommended Tooling & DX

**VS Code extensions?**

- Ruby LSP (Shopify) — Ruby language server
- Solargraph — Ruby IntelliSense and documentation
- ESLint + Prettier — JavaScript formatting
- Tailwind CSS IntelliSense — if using Tailwind for styling
- GitLens — Git blame and history
- REST Client — Test API endpoints inline
- Rails DB Schema — Visual database schema

**CLI tools?**

- `rails console` — interactive debugging
- `bundle exec rspec` — run tests
- `bundle exec rubocop -A` — auto-fix lint issues
- `bin/dev` — Procfile-based development server (Rails + esbuild + Sidekiq)
- `gh` — GitHub CLI for PR creation and issue management
- `curl` / `httpie` — manual API testing

**Debugging setup?**

- `debug` gem (Ruby 3.1+ built-in debugger) with VS Code integration
- `better_errors` + `binding_of_caller` for browser-based error pages in development
- `bullet` gem to detect N+1 queries
- `rack-mini-profiler` for request timing
- LangSmith/Langfuse dashboard for tracing LLM interactions
- Rails server logs with structured JSON output (Lograge gem) for production debugging
- Sidekiq Web UI for monitoring background job queues

---

## Architecture Decision Summary

| Decision Area | Choice | Rationale |
|---|---|---|
| Backend | Ruby on Rails 7 (monolith) | Required language, conventions accelerate solo dev |
| Frontend | Hotwire + React (chat only) | Best of both: server-rendered pages + rich chat UX |
| Database | PostgreSQL + Redis | Reliable, Rails-native, JSONB for flexible schema |
| LLM (primary) | OpenAI GPT-4o | Best function calling, vision support, speed |
| LLM (sentiment) | OpenAI GPT-4o-mini | Cost-effective for classification |
| LLM (fallback) | Anthropic Claude Sonnet 4.6 | Resilience, better emotional tone |
| OCR (primary) | OpenAI Vision (GPT-4o) | Single API, flexible, no template config needed |
| OCR (fallback) | Google Cloud Vision | Structured output with confidence scores |
| Tool calling | Native function calling | Structured JSON, explicit schemas |
| Streaming | Action Cable (WebSockets) | Built into Rails, token-by-token LLM streaming |
| Background jobs | Sidekiq | Rails standard, Redis-backed, priority queues |
| Auth | Devise + OmniAuth | Fast to implement, extensible to SSO later |
| Observability | LangSmith or Langfuse | Tracing, evals, cost tracking |
| Hosting | Render or Heroku | Managed PaaS, simple deployment, WebSocket support |
| CI/CD | GitHub Actions | Automated tests, evals, linting, deploy |

---

## Primary Demo Use Case: HR Employee Onboarding

**Golden path for the 3-5 minute demo video:**

1. User lands on the app → sees a welcoming chat interface
2. AI greets them: "Welcome! I'll help you complete your onboarding. Let's start with some basic information."
3. Conversational data collection: name, email, department
4. AI prompts document upload: "Could you upload a photo of your driver's license? I'll extract your details automatically."
5. User uploads ID → OCR extracts name, DOB, address, license number
6. AI presents extracted data: "I found the following — please confirm or correct any fields."
7. AI detects the user has been at it for a while: "You're doing great — just two more steps to go!"
8. AI initiates scheduling: "Let's book your orientation. Here are available slots for next week."
9. User selects a slot → AI confirms booking with summary
10. Onboarding complete → celebratory message, next steps, calendar event

**This maps directly to Credal's Onboarding Buddy pattern** and demonstrates all four functional requirements: AI chatbot, OCR/document processing, intelligent scheduling, and emotional support.
