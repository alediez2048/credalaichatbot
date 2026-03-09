# AI-Powered Onboarding Assistant

*Building an AI-Driven User Onboarding Experience with Intelligent Data Entry and Emotional Support*

---

## Before You Start: Pre-Search (2 Hours)

After you review this document but before writing any code, complete the **Pre-Search methodology at the end of this document**. This structured process uses AI to explore stack options, surface tradeoffs, and document architecture decisions. **Your Pre-Search output becomes part of your final submission.**

This week emphasizes AI-first development workflows. Pre-Search is the first step in that methodology.

## Background

Users seeking specialized services often face complex onboarding processes that lead to high drop-off rates and emotional friction. Data entry is tedious, appointment scheduling is confusing, and the overall experience fails to account for the emotional state of users who may already be under stress. Current systems treat onboarding as a purely transactional process.

This project requires you to build an AI-powered onboarding assistant that leverages LLM-based conversational interfaces, image-to-text document processing, intelligent scheduling, and emotional support content to create a streamlined, empathetic onboarding experience. The focus is on AI-first development methodology—using coding agents, MCPs, and structured AI workflows throughout the build process.

**Gate:** Project completion is required for Austin admission.

## Project Overview

One-week sprint with three deadlines:

| Checkpoint | Deadline | Focus |
|---|---|---|
| Pre-Search | Monday (two hours in) | Architecture, Planning |
| MVP | Tuesday (24 hours) | Core chatbot + data entry |
| Early Submission | Friday (4 days) | Full feature set |
| Final | Sunday (7 days) | Polish, documentation, deployment |

## MVP Requirements (24 Hours)

**Hard gate.** All items required to pass:

- [ ] AI chatbot interface that guides users through onboarding steps
- [ ] At least one document upload with image-to-text extraction (OCR)
- [ ] Extracted data auto-populates onboarding form fields
- [ ] Basic appointment/scheduling selection flow
- [ ] Emotional support content displayed contextually during onboarding
- [ ] Conversation history maintained across turns
- [ ] Basic error handling (graceful failure, not crashes)
- [ ] User authentication (login/signup)
- [ ] Deployed and publicly accessible

*A simple onboarding flow with reliable AI assistance beats a feature-rich system with broken data extraction.*

## Core Onboarding System

### AI Assessment Module

| Feature | Requirements |
|---|---|
| Chatbot Interface | LLM-powered conversational UI that guides onboarding |
| Context Awareness | Chatbot understands user progress and adapts prompts accordingly |
| Multi-Step Flow | Guides users through data collection, document upload, and scheduling |
| Fallback Handling | Graceful fallback when AI cannot parse user intent |
| Session Persistence | Onboarding progress saved and resumable across sessions |

### Image-to-Text Data Entry

| Feature | Requirements |
|---|---|
| Document Upload | Accept common formats: JPG, PNG, PDF |
| OCR Processing | Extract text from uploaded documents accurately |
| Field Mapping | Map extracted text to appropriate onboarding form fields |
| Validation | Verify extracted data and flag low-confidence fields for user review |
| Manual Override | Allow users to correct any auto-filled data |

### Intelligent Scheduling

| Feature | Requirements |
|---|---|
| Availability Display | Show available appointment slots in a clear interface |
| Smart Suggestions | AI recommends optimal times based on user preferences |
| Confirmation Flow | Confirm booking with summary and next steps |
| Calendar Integration | Generate calendar events (ICS or API-based) |
| Rescheduling | Allow modification of booked appointments |

### Emotional Support Content

| Feature | Requirements |
|---|---|
| Contextual Messages | Display supportive content based on onboarding stage |
| Tone Detection | Detect user frustration or confusion from chat inputs |
| Adaptive Responses | Adjust chatbot tone and pacing when stress is detected |
| Resource Links | Provide relevant support resources when appropriate |
| Progress Encouragement | Celebrate milestones and provide positive reinforcement |

## Testing Scenarios

We will test:

1. Complete onboarding flow from start to finish with AI chatbot guidance
2. Document upload with OCR extraction and form auto-fill accuracy
3. Scheduling flow with slot selection, confirmation, and rescheduling
4. Emotional support triggers when user shows signs of frustration
5. Session persistence: user refreshes mid-onboarding and resumes
6. Error recovery: invalid document upload, network interruption
7. Concurrent users completing onboarding simultaneously

## Performance Targets

| Metric | Target |
|---|---|
| Chatbot response latency | <3 seconds for single-turn responses |
| OCR processing time | <10 seconds per document page |
| Field extraction accuracy | >85% correct field mapping |
| Scheduling load time | <2 seconds to display available slots |
| Concurrent users | 10+ without degradation |
| Onboarding completion rate | >70% of users who start finish the flow |

## AI Onboarding Agent

### Required Capabilities

Your AI agent must support at least 6 distinct interaction types across these categories:

#### Data Collection Commands

- "What is your full name and date of birth?"
- "Please upload a photo of your ID document"
- "What is your preferred contact method?"

#### Document Processing Commands

- "I've extracted the following from your document—please verify"
- "The name on your ID appears to be [name]. Is this correct?"
- "I couldn't read the expiration date clearly. Can you enter it manually?"

#### Scheduling Commands

- "Here are the available appointment slots for next week"
- "Based on your preferences, I recommend Tuesday at 2 PM"
- "Your appointment has been confirmed. Here's a summary"

#### Emotional Support Commands

- "I understand this process can feel overwhelming. Take your time"
- "You're making great progress—just two more steps to go!"
- "Here are some resources that might be helpful during this process"

### Tool Schema (Minimum)

```
startOnboarding(userId, sessionId)
extractDocumentData(imageFile, documentType) -> extractedFields
validateExtractedData(fields, formSchema) -> validationResult
getAvailableSlots(dateRange, serviceType) -> slots
bookAppointment(userId, slotId, serviceType) -> confirmation
detectUserSentiment(messageHistory) -> sentimentScore
getSupportContent(context, sentimentLevel) -> supportMessage
saveOnboardingProgress(userId, currentStep, formData)
getOnboardingState(userId) -> savedProgress
```

### Evaluation Criteria

| Command | Expected Result |
|---|---|
| "Start my onboarding" | Initiates guided flow, asks for first piece of information |
| "Here is my ID" (with image) | Extracts name, DOB, ID number; auto-fills form fields |
| "Schedule an appointment" | Displays available slots, recommends optimal time |
| "I'm feeling overwhelmed" | Responds with empathy, offers to slow down or provide resources |
| Multi-step completion | AI tracks progress and guides through remaining steps sequentially |

### AI Agent Performance

| Metric | Target |
|---|---|
| Response latency | <3 seconds for single-step interactions |
| OCR accuracy | >85% correct field extraction |
| Sentiment detection | Correctly identifies frustration/confusion >80% of the time |
| Flow completion | AI guides user through full onboarding without dead ends |
| Reliability | Consistent, accurate execution across repeated runs |

## AI-First Development Requirements

This week emphasizes learning AI-first development workflows. You must document your process.

### Required Tools

Use at least two of:

- Claude Code
- Cursor
- Codex
- MCP integrations

### AI Development Log (Required)

Submit a 1-page document covering:

| Section | Content |
|---|---|
| Tools & Workflow | Which AI coding tools you used, how you integrated them |
| MCP Usage | Which MCPs you used (if any), what they enabled |
| Effective Prompts | 3-5 prompts that worked well (include the actual prompts) |
| Code Analysis | Rough % of AI-generated vs hand-written code |
| Strengths & Limitations | Where AI excelled, where it struggled |
| Key Learnings | Insights about working with coding agents |

## AI Cost Analysis (Required)

Understanding AI costs is critical for production applications. Submit a cost analysis covering:

### Development & Testing Costs

Track and report your actual spend during development:

- LLM API costs (OpenAI, Anthropic, etc.)
- OCR/Vision API costs (document processing)
- Total tokens consumed (input/output breakdown)
- Number of API calls made
- Any other AI-related costs (embeddings, hosting, etc.)

### Production Cost Projections

Estimate monthly costs at different user scales:

| 100 Users | 1,000 Users | 10,000 Users | 100,000 Users |
|---|---|---|---|
| $___/month | $___/month | $___/month | $___/month |

Include assumptions: average AI interactions per user per session, average sessions per user per month, token counts per interaction type, OCR calls per onboarding.

## Technical Stack

### Possible Paths

| Layer | Technology |
|---|---|
| Backend | Ruby on Rails (primary), Node.js/Express, or Python/FastAPI |
| Frontend | JavaScript/TypeScript with React, Vue, or Stimulus (Hotwire) |
| AI/LLM Integration | OpenAI GPT-4 or Anthropic Claude with function calling |
| OCR/Vision | Tesseract, Google Cloud Vision, AWS Textract, or OpenAI Vision |
| Scheduling | Custom calendar logic, Calendly API, or Cal.com integration |
| Database | PostgreSQL, Redis for sessions/caching |
| Deployment | Heroku, Render, Railway, or Vercel |

Use whatever stack helps you ship. **Complete the Pre-Search process to make informed decisions.**

## Build Strategy

### Priority Order

1. AI chatbot core — Get a basic conversational onboarding flow working end-to-end
2. Document upload + OCR — Extract text from one document type reliably
3. Form auto-fill — Map extracted fields to onboarding form
4. Scheduling integration — Display slots and book appointments
5. Emotional support layer — Add contextual supportive messaging
6. Session persistence — Save and resume onboarding progress
7. Polish & error handling — Edge cases, validation, UX improvements

### Critical Guidance

- The AI chatbot is the core experience. Start here and make it solid.
- Build vertically: finish one module before starting the next.
- Test OCR with multiple document types and image qualities.
- Emotional support should feel natural, not forced or robotic.
- Test the full onboarding flow end-to-end frequently.

## Submission Requirements

**Deadline: Sunday 10:59 PM CT**

| Deliverable | Requirements |
|---|---|
| GitHub Repository | Setup guide, architecture overview, deployed link |
| Demo Video (3-5 min) | Full onboarding flow, AI chatbot, OCR demo, scheduling |
| Pre-Search Document | Completed checklist from Phase 1-3 |
| AI Development Log | 1-page breakdown using template above |
| AI Cost Analysis | Dev spend + projections for 100/1K/10K/100K users |
| Deployed Application | Publicly accessible, supports 5+ concurrent users |
| Social Post | Share on X or LinkedIn: description, features, demo/screenshots, tag @GauntletAI |

## Final Note

A simple, empathetic onboarding flow with reliable AI assistance beats a feature-rich system with broken data extraction and confusing UX.

**Project completion is required for Austin admission.**

---

## Appendix: Pre-Search Checklist

Complete this before writing code. Save your AI conversation as a reference document. The goal is to make an informed decision about all relevant aspects of your project. Understand tradeoffs, strengths and weaknesses, and make a decision that you can defend. You don't have to be right, but you do have to show your thought process.

### Phase 1: Define Your Constraints

**1. Scale & Load Profile**

- Users at launch? In 6 months?
- Traffic pattern: steady, spiky, or unpredictable?
- Real-time requirements (websockets, live updates)?
- Cold start tolerance?

**2. Budget & Cost Ceiling**

- Monthly spend limit?
- Pay-per-use acceptable or need fixed costs?
- Where will you trade money for time?

**3. Time to Ship**

- MVP timeline?
- Speed-to-market vs. long-term maintainability priority?
- Iteration cadence after launch?

**4. Compliance & Regulatory Needs**

- Health data (HIPAA)?
- EU users (GDPR)?
- Enterprise clients (SOC 2)?
- Data residency requirements?

**5. Team & Skill Constraints**

- Solo or team?
- Languages/frameworks you know well?
- Learning appetite vs. shipping speed preference?

### Phase 2: Architecture Discovery

**6. Hosting & Deployment**

- Serverless vs. containers vs. edge vs. VPS?
- CI/CD requirements?
- Scaling characteristics?

**7. Authentication & Authorization**

- Auth approach: social login, magic links, email/password, SSO?
- RBAC needed?
- Multi-tenancy considerations?

**8. Database & Data Layer**

- Database type: relational, document, key-value?
- Real-time sync, full-text search, vector storage, caching needs?
- Read/write ratio?

**9. Backend/API Architecture**

- Monolith or microservices?
- REST vs. GraphQL vs. tRPC vs. gRPC?
- Background job and queue requirements?

**10. Frontend Framework & Rendering**

- SEO requirements (SSR/static)?
- Offline support/PWA?
- SPA vs. SSR vs. static vs. hybrid?

**11. AI/LLM Integration**

- Which LLM provider and model?
- Function calling vs. prompt-based tool use?
- Context window needs for conversation history?
- Cost per interaction acceptable?

**12. OCR/Vision Strategy**

- Cloud OCR vs. local (Tesseract)?
- Document types to support (IDs, forms, receipts)?
- Accuracy requirements and fallback strategy?
- Privacy implications of sending documents to external APIs?

**13. Third-Party Integrations**

- External services needed (payments, email, analytics, AI APIs)?
- Pricing cliffs and rate limits?
- Vendor lock-in risk?

### Phase 3: Post-Stack Refinement

**14. Security Vulnerabilities**

- Known pitfalls for your stack?
- Common misconfigurations?
- Dependency risks?
- Document upload security (file type validation, size limits)?

**15. File Structure & Project Organization**

- Standard folder structure for your framework?
- Monorepo vs. polyrepo?
- Feature/module organization?

**16. Naming Conventions & Code Style**

- Naming patterns for your language/framework?
- Linter and formatter configs?

**17. Testing Strategy**

- Unit, integration, e2e tools?
- Coverage target for MVP?
- Mocking patterns?

**18. Recommended Tooling & DX**

- VS Code extensions?
- CLI tools?
- Debugging setup?
