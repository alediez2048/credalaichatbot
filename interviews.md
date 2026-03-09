# AI-Powered Onboarding Assistant — Architecture Interview

**Role:** Senior AI Product Architect and Full-Stack UX Engineer specializing in Conversational Design, Multimodal LLM Integration, and Human-Centric AI.

**Context:** Building an AI-driven onboarding system that connects a Conversational LLM, a Vision-based OCR pipeline, a Sentiment Analysis engine, and an Intelligent Scheduler into a seamless, empathetic user experience.

**Task:** Deep-dive technical and architectural interview to define the AI stack, state management for multi-step flows, and the AI-first development workflow.

---

## Round 1: Core Architecture & AI Systems

### Question 1 — Conversational State Machine

**How should the onboarding flow manage state transitions between the chatbot, OCR pipeline, and scheduler — and what happens when a user deviates from the expected path?**

This is the backbone of the entire system. You need to decide whether the LLM itself owns the flow state (via function calling and context window) or whether you build an explicit state machine (like a LangGraph graph or a Rails state machine gem) that the LLM merely advises. The requirements call for session persistence and resumability, which means this state needs to survive server restarts. Consider: if a user uploads a document mid-conversation, does the chatbot pause, hand off to the OCR tool, then resume — or does it run in parallel? How do you handle a user who asks to reschedule while still in the middle of document verification? Your tool calling schema (`startOnboarding`, `saveOnboardingProgress`, `getOnboardingState`) implies an orchestrator pattern, but the question is whether the LLM *is* the orchestrator or whether it's a participant in a larger pipeline.

---

### Question 2 — Tool Calling Strategy

**Should the LLM use native function calling with strict schemas, or should you implement a ReAct-style agent loop — and how do you verify tool calls are correct before executing them?**

The requirements specify a minimum tool schema of 9 functions. With native function calling (OpenAI or Claude), you get structured JSON outputs, but the LLM might hallucinate parameters or call the wrong tool. With a ReAct loop, you get reasoning traces but higher latency. The AgentForge doc's verification systems section is relevant here — you need at least a validation layer between the LLM's tool call decision and actual execution. For example, if the LLM calls `bookAppointment(userId, slotId, serviceType)` with a slotId that doesn't exist, what catches that? Do you implement schema validation, domain constraint checking, or a confirmation step with the user? This directly impacts your <3 second latency target.

---

### Question 3 — OCR Pipeline Architecture

**Should document processing happen synchronously within the chat flow, or asynchronously with a webhook/polling pattern — and how do you handle the confidence threshold between auto-fill and manual review?**

The requirements demand >85% field extraction accuracy with <10 second processing time. You're choosing between cloud OCR (Google Cloud Vision, AWS Textract, OpenAI Vision) and local Tesseract, each with very different latency and accuracy profiles. But the deeper architectural question is about the handoff: when a user uploads an ID photo, does the chatbot block and wait for OCR results, or does it say "processing your document, let me ask you a few more questions while we wait"? The `validateExtractedData` tool implies a verification step — but who does the verification? If confidence is below 85%, does the LLM ask the user to confirm each field individually, or present all extracted data at once? This decision cascades into your eval dataset design — you need test cases for high-confidence, low-confidence, and failed extraction scenarios.

---

### Question 4 — Sentiment Detection

**Should emotional analysis happen per-message in real-time, or should you analyze conversation windows — and how do you eval the accuracy of sentiment scoring without ground truth labels?**

The requirements target >80% accuracy for frustration/confusion detection, but this is notoriously hard to measure. A single message like "ok" could be neutral or passive-aggressive depending on context. You need to decide: does `detectUserSentiment(messageHistory)` analyze the last message, the last 5 messages, or the entire session? Do you use the same LLM that's running the conversation (cheaper, lower latency, but the model might not flag its own failures), or a separate classification model? The eval dataset requirement from the AgentForge doc (50+ test cases with 10+ adversarial inputs) is directly applicable — you need annotated conversation transcripts with sentiment labels, including edge cases like sarcasm, cultural differences in expression, and users who mask frustration with politeness.

---

### Question 5 — Tracing and Observability

**What does a single onboarding session trace look like end-to-end, and what metrics do you need to capture to debug a failed or abandoned session?**

The AgentForge doc's observability requirements (trace logging, latency tracking, error tracking, token usage) need to be adapted for a multi-tool, multi-step flow. A single onboarding session might involve 15-20 LLM calls, 1-3 OCR calls, a scheduling API call, and multiple sentiment checks. Your trace needs to capture: which tool was called at each step, what the LLM's reasoning was, how long each step took, what the token cost was, and crucially — where the user dropped off if they abandoned. With Ruby on Rails as the primary backend, are you using OpenTelemetry, a dedicated tool like LangSmith/Langfuse, or building custom structured logging? The cost analysis requirement (projections for 100 to 100K users) depends entirely on having accurate per-session token and API call counts from your traces.

---

### Question 6 — Eval Framework

**How do you build a test suite that covers the full onboarding flow when the "correct" response is highly context-dependent and emotionally nuanced?**

Standard agent evals test tool selection and output correctness, but your system has an emotional dimension that's harder to evaluate. You need test cases for: does the chatbot correctly extract data from 10 different ID formats (correctness), does it choose OCR vs. manual entry appropriately (tool selection), does it respond empathetically when a user says "this is really stressful" (safety/tone), and does it maintain coherent state across a 15-turn conversation (consistency). The AgentForge doc calls for 20+ happy path, 10+ edge cases, 10+ adversarial, and 10+ multi-step scenarios. For the emotional support component specifically, how do you define "pass" and "fail"? Is it keyword-based, LLM-as-judge, or human annotation? This decision affects whether you can run evals in CI or need human review cycles.

---

### Question 7 — Multi-tenancy and Personalization

**Is this a single-domain onboarding assistant or a platform that adapts to different service types — and how does that affect your prompt architecture and tool registry?**

The problem statement says "users seeking specialized services" without specifying what those services are. If this needs to support onboarding for healthcare, legal, financial, or other domains, your prompt templates, required documents, scheduling rules, and emotional support content all change per domain. Do you build a single monolithic prompt with conditional logic, or a configurable system where each service type has its own prompt template, tool configuration, and validation rules? This is the difference between a 2-week project and a 2-month platform. It also directly impacts your compliance considerations (HIPAA for healthcare documents, PII handling for financial onboarding) and your cost projections (different domains might require different LLM models or OCR services).

---

### Question 8 — Failure Recovery and Human Escalation

**When the AI gets stuck, confused, or the user becomes genuinely distressed, what's the escalation path — and how do you prevent the AI from making emotional situations worse?**

The requirements list "graceful fallback when AI cannot parse user intent" and "adaptive responses when stress is detected," but these are in tension. If a user is already frustrated and the AI says "I'm sorry, I didn't understand that" three times in a row, you've made things worse. You need a concrete escalation strategy: after N failed parses, do you switch to a structured form fallback? After sentiment drops below a threshold, do you offer to connect with a human? Does the system ever proactively pause the onboarding and suggest the user come back later? The verification systems from the AgentForge doc (human-in-the-loop, escalation triggers) apply directly here. Define your escalation tiers: AI handles it, AI suggests alternatives, AI offers human handoff, system pauses automatically.

---

### Question 9 — Cost Optimization

**Given that each onboarding session could involve 15-20 LLM calls plus OCR, how do you keep per-session costs under a viable threshold at scale — and where can you use caching, smaller models, or pre-computed responses?**

The cost analysis requirement asks for projections at 100K users. If each session uses 20 GPT-4 calls (averaging 1K tokens each at $0.03/1K input), that's roughly $0.60 per session in LLM costs alone, plus OCR costs. At 100K users with 2 sessions each, that's $120K/month just in AI API costs. Where can you optimize? Can sentiment detection use a smaller, fine-tuned model instead of GPT-4? Can common onboarding questions use cached responses? Can you pre-extract document templates so OCR only needs to fill in variable fields? Should the emotional support content be retrieved from a database rather than generated on the fly? Your technical stack choice (Ruby on Rails) also matters — are you calling LLM APIs directly from Rails controllers, using background jobs (Sidekiq) for OCR, or implementing a separate AI service layer?

---

### Question 10 — AI-First Development Workflow

**How do you structure your development process so that the AI coding tools (Claude Code, Cursor) are maximally effective for a Ruby on Rails + LLM integration project — and what does your iteration loop look like between writing code, running evals, and improving prompts?**

The requirements mandate using at least two AI coding tools and documenting the workflow. But the meta-question is: in an AI-first workflow for building an AI product, what's the feedback loop? You're writing prompts that an LLM will execute, using an LLM to help you write those prompts, and then evaluating the output with another LLM. Your development cycle is likely: write prompt template, run against eval dataset, check traces in observability tool, adjust prompt, repeat. But when do you write code vs. when do you write prompts? The tool schema functions need traditional code (Rails controllers, service objects, database queries), but the conversation flow and emotional responses are prompt-engineered. How do you version control prompts alongside code? How do you prevent prompt regressions when you change the tool schema? Define your CI pipeline: code tests, prompt evals, integration tests with mock LLM responses, and end-to-end tests with real API calls.

---

## Round 2: Implementation Specifics & Gap Analysis

### Question 11 — PII Handling and Data Lifecycle

**When a user uploads an ID document containing their name, date of birth, address, and ID number, what happens to that image and extracted data at each stage — and where does PII live, for how long, and who can access it?**

The first round touched on compliance at a high level (HIPAA, GDPR), but we didn't address the concrete data flow. The OCR pipeline creates a chain: raw image → cloud API (if using Google Vision / Textract) → extracted JSON → database fields. At each step, PII exists in a different location with different access controls. Does the raw image get deleted after extraction, or stored for audit/dispute resolution? If you're sending documents to a third-party OCR API, that data leaves your infrastructure — how does that affect your privacy policy and user consent flow? With Ruby on Rails, are you using Active Storage for document uploads, and if so, where are files stored (local disk, S3, GCS)? Do you encrypt extracted fields at rest in PostgreSQL (using `attr_encrypted` or Rails 7's built-in encryption)? The onboarding context makes this especially sensitive — users are submitting personal documents in a moment of vulnerability, and a data breach would be catastrophic for trust.

---

### Question 12 — Conversational UX Architecture

**Should the chat interface be a full SPA with WebSocket streaming, a server-rendered Hotwire/Turbo setup native to Rails, or a hybrid — and how do you render partial LLM responses, typing indicators, and document upload previews within the conversation thread?**

The first round focused on backend orchestration but skipped the frontend interaction model entirely. The requirements specify Ruby on Rails with JavaScript/TypeScript, which opens two very different paths: a React/Vue SPA that communicates with a Rails API, or a Hotwire (Turbo Streams + Stimulus) approach that keeps rendering server-side. For a chatbot interface, the UX expectations are high — users expect streaming responses (tokens appearing word-by-word), typing indicators, inline document previews, and smooth transitions between conversation and form elements. With Hotwire, you can use Turbo Streams over WebSockets via Action Cable, but streaming individual LLM tokens requires careful frame management. With a React SPA, you get more control over real-time rendering but lose Rails' integrated view layer. How do you handle the moment when a user uploads a document mid-chat — does an inline preview appear, does a progress bar show OCR processing, and does the chatbot's next message appear only after extraction completes? This directly impacts your <3 second perceived latency target.

---

### Question 13 — Prompt Versioning and Regression Testing

**How do you manage the system prompts, tool descriptions, and few-shot examples that define the chatbot's behavior — and how do you prevent a prompt change from breaking previously passing eval cases?**

The first round covered evals but not prompt management. Your system likely has multiple prompt components: a master system prompt defining the assistant's personality and onboarding role, tool descriptions for each of the 9 functions, few-shot examples for emotional support responses, and possibly per-step instructions (e.g., "when collecting personal info, ask one field at a time"). These prompts are effectively code — they determine system behavior — but they don't live in your Ruby codebase the same way models and controllers do. Do you store prompts in the database (editable at runtime), in YAML/JSON config files (version-controlled with git), or hardcoded in service objects? When you tweak the emotional support prompt to be warmer, how do you know it didn't accidentally make the data collection prompts less precise? The AgentForge doc's emphasis on eval datasets applies here: you need a prompt CI pipeline where every prompt change triggers the full eval suite, with clear pass/fail criteria and regression alerts.

---

### Question 14 — Multi-Step Form State vs. Conversation State

**When the chatbot collects 15+ fields across document extraction, manual input, and scheduling — where is the canonical source of truth for onboarding progress, and how do you reconcile what the LLM "thinks" it has collected versus what's actually persisted?**

The first round addressed state machines conceptually but not the specific divergence problem. The LLM maintains state in its context window — it "remembers" that the user's name is Alex because it was mentioned 8 messages ago. But if the context window gets truncated, or the user resumes a session with a new LLM call, that memory is gone. Meanwhile, your Rails database has a `saveOnboardingProgress` record with partially filled fields. These two states can drift: the user corrects their name in chat, but the tool call to update it fails silently. Or the LLM hallucinates a field value from an earlier OCR extraction. You need a reconciliation strategy. Does every LLM response that touches user data trigger a `saveOnboardingProgress` call? Does the system prompt include a serialized version of the current form state at the start of each turn? How large does that context injection get after 15 fields, and does it eat into your token budget? With Rails, do you use a dedicated `OnboardingSession` model with JSONB columns for flexible field storage, or strongly typed columns for each field?

---

### Question 15 — OCR Confidence Scoring and the Human-AI Verification Loop

**When the system extracts "John" from an ID but the confidence is 72%, how does the verification flow work in the chat — and what's the UX for correcting 1 field vs. correcting 8 fields?**

The first round asked about the confidence threshold but not the granular UX. The `validateExtractedData` tool returns a validation result, but what does that look like in the conversation? If 8 out of 10 fields extracted perfectly and 2 are low-confidence, do you show all 10 for review (safe but tedious), only the 2 flagged ones (faster but the user might miss an error in a "confident" field), or a summary with the option to edit any field? The interaction pattern matters enormously for completion rate — the requirements target >70% completion, and a wall of "please confirm" fields will kill that. Consider a tiered approach: fields above 95% confidence are auto-filled and shown as a summary card, fields between 80-95% are shown with a yellow highlight for quick confirmation, and fields below 80% are presented as direct questions in the chat. But how do you eval this? You need test documents with known ground truth, run them through your OCR pipeline, and measure not just extraction accuracy but the end-to-end user experience — how many extra interactions does a low-quality document add?

---

### Question 16 — Scheduling System Integration Depth

**Is the intelligent scheduler a thin UI layer over hardcoded availability slots, a real calendar integration (Google Calendar, Calendly, Cal.com API), or an AI-driven optimization engine — and how "intelligent" do the smart suggestions actually need to be?**

The requirements list "AI recommends optimal times based on user preferences" and "calendar integration," but these span a huge complexity range. The simplest implementation: store available slots in a PostgreSQL table, display them in the chat, and let the user pick one. The most complex: integrate with the service provider's actual calendar via API, factor in the user's timezone and stated preferences ("mornings work best for me"), predict no-show probability, and recommend slots with the lowest likelihood of cancellation. For the MVP (24-hour deadline), you almost certainly want the simple version. But the "smart suggestions" requirement implies the LLM should do more than list slots — it should reason about which slot is best. Does that mean passing all available slots to the LLM and asking it to recommend one based on conversation context, or building a separate recommendation algorithm? What happens when the user says "sometime next week, I'm flexible" — does the LLM pick for them, or narrow down options? And critically: how do you prevent double-booking in a concurrent user scenario (the performance target is 10+ simultaneous users)?

---

### Question 17 — Error Taxonomy and Recovery Strategies

**What are all the ways this system can fail, and for each failure mode, what does the user experience — a retry, a fallback to manual input, an apology message, or a dead end?**

The first round discussed escalation for emotional situations but not the full error landscape. Map out every failure point: LLM API timeout (OpenAI goes down for 30 seconds), OCR returns garbage (blurry photo), tool call returns unexpected schema (scheduling API changed), database write fails (connection pool exhausted), user uploads wrong file type (a .docx instead of a photo), context window overflow (conversation exceeded token limit), sentiment detection false positive (user is joking, not frustrated). For each, define: does the system retry automatically? How many times? With what backoff? Does it fall back to an alternative (e.g., if cloud OCR fails, try local Tesseract)? Does it tell the user what happened, or silently recover? The requirements say "graceful failure, not crashes" — but graceful means different things for different errors. An LLM timeout might warrant "Let me think about that for a moment..." while an OCR failure needs "I had trouble reading that photo. Could you try again with better lighting?" Your tracing system needs to categorize these errors so you can measure mean time to recovery and identify the most common failure modes.

---

### Question 18 — Rails-Specific Architecture

**How do you structure the AI service layer within a Rails application — as skinny controllers calling fat service objects, as an Action Cable real-time layer, as background Sidekiq jobs, or as a separate microservice that Rails calls via HTTP?**

This is the Ruby on Rails implementation question the first round didn't address. Rails has strong conventions, and fighting them creates maintenance nightmares. The natural Rails pattern would be: a `ConversationsController` that handles chat messages, a `DocumentsController` for uploads, and a `BookingsController` for scheduling. But the AI orchestration doesn't fit neatly into MVC. You likely need a service layer: `OnboardingOrchestrator` that coordinates between `LlmService` (API calls to OpenAI/Claude), `OcrService` (document processing), `SentimentService` (emotion analysis), and `SchedulingService` (availability and booking). Should LLM calls happen synchronously in the request cycle (simpler but blocks the Rails thread) or asynchronously via Sidekiq with Action Cable pushing results back (more complex but better for the <3 second target)? For streaming LLM responses, you'll likely need Action Cable with Turbo Streams or a Server-Sent Events endpoint. How do you handle the database layer — does each conversation turn get its own `Message` record, or do you store the full conversation as JSONB on the `OnboardingSession`? Active Record callbacks vs. explicit service object calls for side effects like saving progress?

---

### Question 19 — Token Budget Management

**With a 15-20 turn conversation that includes OCR results, form state, emotional context, and tool call history, how do you keep the LLM context window under control — and what gets summarized, truncated, or dropped when you approach the limit?**

The first round covered cost optimization but not context window management, which is a prerequisite. A typical onboarding session might include: a system prompt (500-800 tokens), 15 user messages (150 tokens each = 2,250), 15 assistant messages (200 tokens each = 3,000), 5 tool call/response pairs (300 tokens each = 1,500), OCR extracted data injected as context (500-1,000 tokens), current form state (200-400 tokens), and emotional support guidelines (200 tokens). That's roughly 8,000-9,000 tokens before you hit the meat of the conversation. With GPT-4's 128K context or Claude's 200K, you have headroom — but token costs scale linearly, and at 100K users, every unnecessary token matters. Do you implement a sliding window that drops messages older than N turns? Do you summarize the conversation history periodically (costs an extra LLM call but compresses context)? Do you separate the concerns — use the full context for the main conversation but a truncated version for sentiment detection? Rails-side, this means your `LlmService` needs a `ContextBuilder` that assembles the prompt, tracks token count, and applies truncation rules before each API call.

---

### Question 20 — Day-One Demo Path

**What is the exact 3-minute user journey you'll show in the demo video, and how does working backwards from that demo inform which features you build first and which you fake?**

This is the pragmatic question that ties everything together. The requirements include a 3-5 minute demo video showing "full onboarding flow, AI chatbot, OCR demo, scheduling." Working backwards from a compelling demo: you need a user to sign up, start chatting with the AI, upload a document (probably a driver's license), see fields auto-populated, select an appointment, receive an encouraging message, and complete onboarding. That's your golden path. Every architectural decision should optimize for this path working flawlessly by the demo deadline. What can you fake? The scheduling "intelligence" can be a curated list of slots with a hardcoded recommendation. The sentiment detection can be keyword-based ("frustrated," "confused," "stressed") rather than a real classifier. The OCR can be optimized for one specific document type (US driver's license) rather than generalizing. The emotional support content can be 10 pre-written messages selected by the LLM rather than generated on the fly. What can't you fake? The LLM conversation needs to feel natural — this is the core experience. The OCR needs to actually work on a real document — this is the wow factor. The state persistence needs to survive a page refresh — this proves production readiness. Build the golden path first, instrument it with tracing, write evals for it, then expand.

---

## Round 3: Remaining Gaps & Production Readiness

### Question 21 — Authentication Flow vs. Onboarding Flow

**Does the user authenticate before the AI conversation starts, or does the chatbot itself handle signup/login as part of the onboarding — and how do you avoid losing anonymous progress if a user starts chatting before creating an account?**

Both previous rounds assumed authentication exists but never asked when it happens. This is a critical UX decision. If you require login upfront, you add friction before the user even sees the AI — and you lose the "wow factor" of immediately talking to a helpful assistant. If you allow anonymous onboarding and ask for credentials later, you need to handle the merge problem: a user chats for 5 minutes, uploads a document, then signs up — how do you attach that anonymous `OnboardingSession` to their new `User` record? In Rails, this typically means generating a session token or guest user on first visit, then merging on account creation via `Devise` or a custom auth solution. But there's a deeper tension with the OCR pipeline: if an unauthenticated user uploads a government ID, you're storing highly sensitive PII linked to nothing but a session cookie. What's the liability if that session expires and the data is orphaned? Do you enforce authentication before document upload specifically, even if you allow anonymous chatting?

---

### Question 22 — Accessibility and Inclusive Design

**How does the onboarding assistant work for users with visual impairments, motor disabilities, low digital literacy, or who are using the system on a low-end mobile device with a poor camera?**

Neither round addressed accessibility, which is a significant gap given that the problem statement focuses on reducing emotional friction for users "under stress." Many onboarding systems serve populations with above-average accessibility needs — think healthcare patients, elderly users, or people dealing with legal situations. Concretely: is the chatbot interface screen-reader compatible (ARIA labels on dynamic chat messages, focus management when new messages appear)? Can users navigate the entire flow with keyboard only? If the OCR requires a document photo, what's the alternative for someone who can't take a clear photo — is there a manual entry fallback that's equally supported, not buried as a secondary option? Does the emotional support content account for neurodivergent users who may interact differently with sentiment detection? On the technical side, dynamic chat interfaces are notoriously bad for screen readers unless you use ARIA live regions correctly. With Hotwire/Turbo, you get some accessibility for free since it's server-rendered HTML, but streaming LLM responses into a chat bubble requires explicit ARIA announcements.

---

### Question 23 — Internationalization and Multilingual Support

**If a user uploads a document in Spanish but chats in English, or vice versa — how does each component of the pipeline (chatbot, OCR, sentiment, scheduling) handle language mismatch?**

The requirements don't specify language support, but real-world onboarding systems frequently serve multilingual populations. Even if MVP is English-only, the architecture needs to be language-aware. OCR accuracy varies dramatically by language and script — Tesseract supports 100+ languages but needs language-specific models loaded, while cloud APIs auto-detect but may charge more. The LLM can likely handle multilingual conversation natively, but your system prompt and tool descriptions are in English. Sentiment detection is highly language-dependent — sarcasm, formality, and expressions of frustration vary across cultures. Do you detect the user's language from their first message and route accordingly? Do you store the detected language in the `OnboardingSession` and pass it to each service? If you're using Rails' `I18n` framework, are your chatbot response templates (the non-LLM-generated parts like confirmation emails, success messages, error states) localized? Even for an English-only MVP, building the architecture with `I18n` awareness from day one saves enormous refactoring later.

---

### Question 24 — Rate Limiting and Abuse Prevention

**How do you prevent a malicious user (or bot) from flooding your system with LLM calls, fake document uploads, or appointment bookings — and what does rate limiting look like when the "user" is an AI chatbot making tool calls?**

Neither round addressed security from the abuse angle. Each onboarding session could trigger 15-20 LLM API calls — if someone scripts 1,000 fake sessions, that's 20,000 API calls hitting your OpenAI/Claude bill. Document uploads go to your cloud OCR service — a flood of high-resolution images could spike processing costs and hit rate limits. Appointment booking without verification enables reservation attacks (booking all available slots to block legitimate users). In Rails, you have `Rack::Attack` for request-level rate limiting, but the interesting question is *where* to apply limits in the AI pipeline. Do you rate-limit per user (authenticated), per session (anonymous), per IP, or per API key? Do you cap the number of LLM turns per session (say, 30 maximum)? Do you limit document uploads to 3 per session? Do you require CAPTCHA before document upload to prevent automated abuse? And critically — how do you distinguish between a legitimate user who's struggling (and needs more turns because the AI keeps misunderstanding them) versus an abuser? Your tracing system needs to flag anomalous session patterns: sessions with >25 turns, sessions uploading >5 documents, sessions that start and abandon repeatedly from the same IP.

---

### Question 25 — The Handoff Contract Between LLM Output and Rails Action

**When the LLM decides to call `bookAppointment(userId, slotId, serviceType)`, what exactly happens in your Rails backend — and how do you guarantee that the LLM's function call parameters map cleanly to your ActiveRecord models and business logic?**

The first two rounds discussed tool calling at the schema level but never drilled into the implementation seam between the LLM's output and your application code. The LLM returns a JSON function call; your Rails app needs to parse it, validate it, execute the corresponding business logic, and return a result that the LLM can interpret. This is the most fragile part of the entire system. Concretely: do you build a `ToolRouter` service that maps function names to Rails service objects (`BookAppointmentService.call(user_id:, slot_id:, service_type:)`)? How do you handle type mismatches — the LLM sends `slotId: "abc123"` but your model expects an integer? What if the LLM calls a function that doesn't exist (hallucinated tool name)? Do you wrap every tool execution in a `begin/rescue` with structured error responses the LLM can understand ("that slot is no longer available, please suggest alternatives")? How do you handle tools that have side effects (booking an appointment) versus tools that are read-only (getting available slots) — do you require user confirmation before executing write operations? This contract needs explicit schema validation (JSON Schema or dry-validation in Ruby) and comprehensive error typing so the LLM gets actionable feedback, not a generic 500 error.

---

### Question 26 — Deployment Pipeline and Zero-Downtime Updates

**How do you deploy a Rails app with LLM integrations such that prompt changes, model version upgrades, and feature flags can be rolled out independently of code deployments — and how do you rollback a bad prompt change at 2 AM?**

The first two rounds covered deployment briefly (Heroku, Render, Railway) but not the operational reality. Your system has three independent change vectors: Ruby code (controllers, models, services), prompt templates (system prompts, tool descriptions), and AI model versions (GPT-4 to GPT-4-turbo, or switching to Claude). Each needs its own deployment and rollback mechanism. Code goes through git and your CI pipeline. But prompts? If they're in your codebase, every prompt tweak requires a full deploy. If they're in the database, you can change them instantly but lose git history and review. A common pattern is storing prompts in a versioned config service (database table with version numbers, or a tool like Braintrust/LangSmith) with a feature flag system (LaunchDarkly, Flipper gem for Rails) that controls which prompt version is active. Model version changes are especially risky — switching from GPT-4 to GPT-4-turbo might change how function calls are formatted. You need canary deployments: route 5% of sessions to the new prompt/model, monitor eval metrics and error rates via your tracing system, then gradually increase. How does your eval suite run in production? Do you have synthetic test sessions that run hourly to catch regressions?

---

### Question 27 — The Social Post Deliverable

**What metrics, screenshots, and narrative make a compelling public demo of this project — and how do you instrument the system during development to capture those artifacts automatically?**

Both docs require a social post tagging @GauntletAI with description, features, demo, and screenshots. This is a deliverable, not an afterthought, and it should influence your development process. The most compelling demos show real numbers: "Our AI onboarding assistant reduced form completion time from 12 minutes to 3 minutes" or "OCR extracted 94% of fields correctly across 50 test documents." To make these claims, you need benchmarking infrastructure from day one. Instrument your tracing to capture: average session duration, number of turns per completed onboarding, OCR accuracy per document type, sentiment detection trigger rate, and completion rate. Set up a small user test (even 5 people) and record their sessions. The demo video requirement (3-5 min) should showcase the golden path plus one recovery scenario (bad photo → retry → success). Screenshots should show: the chat interface with a natural conversation, a document being processed with extracted fields highlighted, the scheduling flow, and your observability dashboard with real traces. Plan to capture these during development, not scramble for them on Sunday night.

---

### Question 28 — Conversation Memory and Context Summarization

**When a user returns to a paused session 24 hours later, what does the chatbot "remember" — and how do you reconstruct enough context for the LLM to resume naturally without replaying the entire conversation history?**

The first round's question 4 covered state divergence but not the cold-resume scenario. Session persistence is an MVP requirement, meaning a user can close the browser and come back tomorrow. When they return, you have their `OnboardingSession` record with saved form fields, but the LLM has no memory — it's a new API call. You need to reconstruct context. Option A: replay the entire message history (expensive in tokens, may exceed context window for long sessions). Option B: generate a structured summary when the session pauses ("User Alex has completed steps 1-3. Name: Alex Diez. DOB: extracted from document. Pending: scheduling appointment. Last emotional state: slightly frustrated after OCR error."). Option C: inject only the current form state and the last 3 messages. Each option trades off naturalness versus cost. The summary approach is most elegant but requires an extra LLM call at pause time. The form-state-only approach is cheapest but loses conversational nuance ("last time you mentioned you prefer morning appointments" — lost). For your eval suite, you need test cases specifically for session resumption: start a session, save progress, create a new LLM context, resume, and verify the chatbot references previous context accurately.

---

### Question 29 — Document Type Extensibility

**The MVP needs OCR for one document type, but how do you design the extraction pipeline so adding a new document type (passport, utility bill, insurance card) doesn't require rewriting the OCR logic each time?**

Neither round addressed the extraction architecture's extensibility. If you hardcode extraction for US driver's licenses, adding passports later means new field mappings, new validation rules, and new eval datasets. A more sustainable pattern: define document types as configuration. Each `DocumentType` (Rails model or YAML config) specifies: expected fields and their types (name: string, dob: date, id_number: alphanumeric), extraction hints for the OCR engine (region of interest, expected format patterns), validation rules (regex for ID numbers, date format), and confidence thresholds per field. The `extractDocumentData` tool takes a `documentType` parameter and loads the corresponding config. The LLM can also help — instead of pure OCR, you can send the document image to a vision model (GPT-4V, Claude Vision) with a structured prompt: "Extract the following fields from this [document type]: name, date of birth, ID number. Return as JSON." This approach is slower and more expensive but far more flexible than traditional OCR and handles documents that Tesseract struggles with (handwritten forms, damaged IDs, non-standard layouts). How do you choose between traditional OCR and vision-LLM extraction per document type?

---

### Question 30 — Post-Sprint Evolution

**After the 7-day sprint, what are the first three features you'd add, what technical debt would you address, and how does the architecture you build this week either enable or constrain that future work?**

This is the question that separates a throwaway prototype from a foundation you can build on. The requirements focus on a one-week sprint, but architectural decisions made now have long tails. Three likely post-sprint priorities: multi-language support (question 23 above — is your architecture I18n-ready?), analytics dashboard for administrators (how many users completed onboarding, where do they drop off, average sentiment — does your tracing system capture enough data?), and integration with actual backend systems (submitting the completed onboarding to a CRM, EHR, or case management system — do you have a clean `OnboardingComplete` event that downstream systems can subscribe to?). Technical debt to watch for: monolithic prompt that's grown to 2,000 tokens and is impossible to reason about (split it during the sprint), conversation history stored as unindexed JSONB (fine for 100 users, painful at 10K), synchronous LLM calls blocking Rails threads (works on Heroku's 30-second timeout but will break under load), and hard-coded document type extractors (see question 29). The litmus test: if a new developer joins the project on day 8, can they add a new document type, a new scheduling provider, or a new language without understanding the entire codebase? If yes, your architecture is extensible. If no, you've built a prototype that only its creator can maintain.

---

## Summary

| Round | Focus | Questions |
|---|---|---|
| Round 1 | Core Architecture & AI Systems | State machines, tool calling, OCR pipeline, sentiment detection, tracing, evals, multi-tenancy, escalation, cost optimization, dev workflow |
| Round 2 | Implementation Specifics & Gap Analysis | PII handling, frontend UX, prompt versioning, form state, OCR confidence UX, scheduling depth, error taxonomy, Rails patterns, token budgets, demo planning |
| Round 3 | Remaining Gaps & Production Readiness | Auth timing, accessibility, i18n, abuse prevention, tool execution contracts, deployment ops, social deliverables, session resumption, document extensibility, post-sprint evolution |

These 30 questions map directly to every section of the Pre-Search checklist in the requirements document and cover the complete architecture surface for the AI-Powered Onboarding Assistant.
