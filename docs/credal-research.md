# Credal.ai Research — Product Analysis & Onboarding Use Case Mapping

**Purpose:** Understand Credal's business, product, and customers to ground the AI-Powered Onboarding Assistant in real-world use cases that directly align with Credal's platform.

**Date:** March 9, 2026

---

## 1. What Is Credal?

Credal.ai is a **secure enterprise AI agent platform**. It enables organizations to build, deploy, and govern AI agents that connect to internal data sources and tools — all while enforcing enterprise-grade security, access controls, and compliance policies.

**Founded:** 2022, New York, NY
**Founders:** Jack Fischer, Ravin Thambapillai
**Backed by:** Y Combinator
**Contact:** sales@credal.ai | support@credal.ai

### Core Value Proposition

Credal solves the trust gap between powerful AI capabilities and enterprise security requirements. Organizations want to use LLMs across their data, but can't risk exposing sensitive information, violating permissions, or failing compliance audits. Credal lets them do both — deploy intelligent AI agents *and* maintain full governance.

---

## 2. Core Product Suite

### AI Agent Platform

- Purpose-built AI agents created by selecting a model, attaching data sources, and writing a custom prompt
- Agents use **agentic reasoning** — they can autonomously call other agents for assistance in multi-step workflows
- Deployed via chat UI, Slack, or embedded in other applications
- Subject matter experts (non-developers) can build and configure agents
- No-code/low-code frameworks alongside a modern REST API for developers

### RAG (Retrieval Augmented Generation)

- Fastest way to build secure, access-controlled RAG applications
- Supports semantic, keyword, or hybrid search over enterprise data
- Automatic, near-real-time data refreshing with permissions built in

### Enterprise Search

- Natural language search across all connected data sources
- Permission-aware — users only see results they're authorized to access

### Developer Tools

- Drop-in support for text/chat completions, images, and popular libraries (LangChain)
- Credal handles performance, cost, and security logging automatically
- Modern REST API for building custom integrations

---

## 3. Integrations & Data Connectivity

Credal offers **point-and-click integrations** to enterprise systems, with automatic permission syncing:

| Category | Systems |
|---|---|
| Collaboration | Slack, Microsoft Teams |
| Documents | Google Drive, SharePoint, Confluence |
| CRM | Salesforce |
| Support | Zendesk |
| Data | Snowflake |
| Identity | Okta (SAML), SCIM-based group sync |
| Cloud AI | AWS Bedrock, GCP Vertex, Azure OpenAI |
| Microsoft | Microsoft 365 |

---

## 4. Enterprise Security Features

This is Credal's primary differentiator. Every feature is security-first.

### Data Permissions & Access Control

- Synchronizes permissions across **all** source systems automatically
- No data leakage — users only see data they're authorized to access
- RBAC is orthogonal to data permissions (data permissions inherit from source systems)
- Full SAML integration with identity providers (Okta)

### Compliance & Certifications

- **SOC 2 Type II** compliant
- **HIPAA** compliant
- First AI company to actively participate in the **EU-US Data Privacy Framework**, UK Extension, and Swiss-U.S. Data Privacy Framework
- Regular third-party penetration testing

### Audit Logging & Monitoring

- All AI interactions with providers (OpenAI, Anthropic) are logged
- Full traceability: know exactly what data was sent, by which users/tools, at all times
- Trace AI answers back to exact source systems that informed them

### Data Protection

- **Zero-data-retention** agreements with AI providers (OpenAI, Anthropic, Cohere)
- Credal was reportedly the first organization to negotiate a ZDR with OpenAI (early 2023)
- Automatic detection, redaction, and blocking of sensitive data leaving the platform
- Supports in-VPC deployment via AWS Bedrock, GCP Vertex, and Azure OpenAI

---

## 5. Customer Success Stories

### Wise (TransferWise)

**Industry:** Financial services / payments
**Scale:** Nearly half of Wise employees reported saving 20-40% of daily work time

**Use Case 1 — Compliance Automation (SAR Reports):**
Credal agents automate the conversion of internal reports into structured **Suspicious Activity Reports (SARs)**. Financial operators saved hours per report, with improved consistency and accuracy of submissions.

**Use Case 2 — Customer Support Quality Assurance:**
A Credal agent performs QA on customer support interactions across **14 evaluation criteria**, identifying correct/incorrect responses, assessing customer impact, and providing specific improvement suggestions. Results: dramatically reduced quality review time, higher customer satisfaction scores, improved first-contact resolution.

### Checkr

**Industry:** Background checks / HR tech
**Scale:** 85% adoption rate across the entire organization

**Use Case — Enterprise-Wide AI Adoption:**
Credal agents integrated with Checkr's key data sources to boost productivity across engineering, IT, HR, sales, finance, and operations. Specific example: agents auto-generate first drafts of **employee performance reviews** using the company template, enabling teams to focus on meaningful feedback rather than formatting.

### Other Notable Customers

- MongoDB
- IFRS Foundation
- Comcast
- US Federal Government

---

## 6. Credal's Own Onboarding Use Cases

### The "Onboarding Buddy"

Credal built and documented an internal **Onboarding Buddy** — an AI agent deployed to a Slack channel (#onboarding-buddy) that:

- Supports new employees during their first weeks/months
- Answers basic questions faster than asking other employees
- Uses internal company data (RAG) for contextualized answers
- Has a "friendly, supportive, and honest" personality
- Demonstrates how non-technical people can build agents from start to finish

### The "Benefits Buddy"

A common first use case Credal recommends to new customers:

- RAG-powered AI tool for HR teams
- Answers employee questions about company HR policies
- Speeds up employee onboarding
- Dramatically improves perception of HR service delivery
- Simple to build: connect data sources, write a prompt, deploy

### Key Insight

**Onboarding is a first-class workflow in Credal's product vision.** It's the use case they recommend customers start with, and it's the one they built internally to demonstrate their platform. This is not a coincidence — it's their go-to proof of value.

---

## 7. Use Cases for the AI-Powered Onboarding Assistant

Based on Credal's product, customers, and workflows, here are six concrete use cases that directly align with their business:

### Use Case 1: HR Employee Onboarding (Primary — Recommended for Demo)

**Scenario:** New hires at a company need to complete onboarding: submit ID documents, tax forms (W-4), direct deposit info, select benefits, and schedule orientation.

**How the AI helps:**
- Chatbot guides new hire through each step conversationally
- OCR extracts data from uploaded ID and tax documents, auto-fills HR system fields
- Intelligent scheduler books orientation sessions and IT setup meetings
- Emotional support detects first-day anxiety, adjusts tone, celebrates progress

**Credal alignment:** Maps directly to Credal's own Onboarding Buddy and Benefits Buddy patterns. This is the use case Credal recommends as a starting point for new enterprise customers.

### Use Case 2: Compliance Document Collection (KYC/AML)

**Scenario:** Financial services firms need to collect and verify identity documents from new customers for Know Your Customer regulations.

**How the AI helps:**
- Chatbot collects government ID, proof of address, and financial documents
- OCR extracts name, DOB, address, ID numbers from uploaded documents
- Validation engine cross-references extracted data against compliance rules
- Auto-populates regulatory forms (SARs, KYC checklists)
- Scheduling for compliance review meetings if manual review is needed

**Credal alignment:** Wise uses Credal to automate Suspicious Activity Reports. This use case extends that pattern to the intake/collection side of compliance workflows.

### Use Case 3: Enterprise Customer Onboarding (B2B SaaS)

**Scenario:** When a new enterprise customer signs up for a platform (like Credal itself), they need to connect data sources, configure SSO/SAML, set up permissions, and understand security policies.

**How the AI helps:**
- Chatbot walks IT admins through multi-step platform setup
- OCR processes uploaded compliance certifications (SOC 2 reports, insurance docs)
- Scheduler coordinates implementation calls with the customer success team
- Emotional support detects frustration during complex OAuth/SAML configuration

**Credal alignment:** This is literally Credal's own customer onboarding problem. Their platform requires connecting data sources and configuring permissions — an AI assistant that guides this process demonstrates deep product understanding.

### Use Case 4: Customer Support Agent Onboarding

**Scenario:** New customer support agents need to learn the product, complete certification, connect their tools, and start handling tickets.

**How the AI helps:**
- Chatbot guides agents through product knowledge modules
- OCR processes certification documents or previous employment verification
- Scheduler books shadowing sessions and team introductions
- Sentiment engine detects when agents feel overwhelmed with information overload

**Credal alignment:** Checkr achieved 85% adoption across their org. Wise uses Credal for support QA. Both imply a need for agent onboarding and training workflows.

### Use Case 5: Vendor/Partner Onboarding for Regulated Industries

**Scenario:** Healthcare and financial organizations need vendors to submit compliance documentation before granting system access.

**How the AI helps:**
- Chatbot collects insurance certificates, SOC 2 reports, HIPAA attestations
- OCR extracts policy numbers, coverage dates, certification details
- Validation verifies documents aren't expired and meet minimum requirements
- Scheduler coordinates compliance review meetings
- Progress tracking across multi-week approval pipeline

**Credal alignment:** Credal's platform is HIPAA and SOC 2 compliant. Their customers in healthcare and finance face this exact vendor onboarding problem.

### Use Case 6: Data Source Connection Wizard

**Scenario:** A Credal customer wants to connect a new data source (Google Drive, Salesforce, Confluence) to the platform.

**How the AI helps:**
- Chatbot guides through authentication and OAuth flows conversationally
- OCR is not needed, but document processing handles config file uploads
- Scheduler not needed, but notification system confirms successful connections
- Emotional support helps when users hit OAuth errors or permission misconfigurations

**Credal alignment:** This is a direct product feature that Credal could build on their own platform — an AI agent that helps users configure the platform itself.

---

## 8. Strategic Recommendations

### Primary Demo Path: HR Employee Onboarding (Use Case 1)

**Why this one:**
- Maps directly to Credal's own documented patterns (Onboarding Buddy, Benefits Buddy)
- Hits all four functional requirements cleanly (chatbot, OCR, scheduling, emotional support)
- Most relatable and demonstrable in a 3-5 minute video
- Universal — every company onboards employees

### Architecture for Multi-Tenancy

Design the system so switching between use cases is a **configuration change**, not a code rewrite:

| Component | What Changes Per Use Case |
|---|---|
| System prompt | Persona, domain language, workflow steps |
| Document types | Expected fields, validation rules, OCR config |
| Scheduling rules | Slot types, availability sources, booking logic |
| Emotional support | Context-specific encouragement messages |
| Compliance rules | Field requirements, regulatory checks |

This means your `OnboardingTemplate` (or equivalent config model) should define: the workflow steps, required documents per step, prompt templates per step, scheduling rules, and emotional support triggers. Swapping from HR onboarding to KYC compliance should be as simple as changing the template.

### Security-First Framing

Since Credal's entire identity is security-first, your onboarding assistant should demonstrate:

- **PII handling:** Encrypt documents at rest, auto-delete after extraction, never log raw PII
- **Permission awareness:** Users only see their own onboarding data
- **Audit trail:** Every AI interaction logged with full traceability
- **Data minimization:** Only collect what's needed, only keep it as long as required

Even in the MVP, showing an audit log of AI interactions and document processing events demonstrates alignment with Credal's core values.

### The Meta-Narrative

Your project demonstrates: **"This is the kind of agent someone could build on Credal's platform."**

The onboarding assistant is a multi-step, tool-calling AI workflow with document processing, scheduling integration, sentiment analysis, and security awareness — exactly what Credal enables enterprises to deploy. Framing it this way shows you understand Credal's product vision, not just how to build a chatbot.

---

## 9. Sources

- [Credal | The Secure AI Agent Platform](https://www.credal.ai/)
- [Credal.ai | Y Combinator](https://www.ycombinator.com/companies/credal-ai)
- [How Wise automated 40% of daily tasks with Credal](https://www.credal.ai/case-studies/wise)
- [With Credal, Checkr scaled AI to thousands of employees](https://www.credal.ai/case-studies/checkr)
- [Building an Onboarding Buddy](https://www.credal.ai/blog/onboarding-buddy)
- [AI Tools for HR: RAG to answer Benefits questions](https://www.credal.ai/blog/ai-tools-for-hr)
- [How to embed AI Agents into daily workflows](https://www.credal.ai/blog/how-to-embed-ai-agents-into-daily-workflows-at-enterprises)
- [Credal Use Cases](https://www.credal.ai/use-cases)
- [Credal Agent Platform](https://www.credal.ai/products/agent-platform)
- [Credal Security](https://www.credal.ai/security)
- [Credal Integrations](https://www.credal.ai/integrations)
- [Credal Case Studies](https://www.credal.ai/case-studies)
