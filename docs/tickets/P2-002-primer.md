# P2-002 — OCR extraction pipeline (OpenAI Vision)

**Priority:** P2
**Estimate:** 4 hours
**Phase:** 2 — Document Processing
**Status:** Not started

---

## Goal

Build the OCR extraction pipeline that sends uploaded documents to the OpenAI Vision API (GPT-4o) to extract structured fields (name, address, DOB, SSN last 4, etc.). Store results in the `ExtractedField` model (already in schema). Processing happens asynchronously via a background job so the user is not blocked. This ticket replaces the `extractDocumentData` tool stub from P0-003 with a real implementation.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P2-002 |
|--------|----------------------|
| **P0-003** | `LLM::ChatService`, `Tools::Router`, `extractDocumentData` tool definition |
| **P2-001** | Active Storage file upload, `Document` model with attached file |

---

## Deliverables Checklist

- [ ] `Documents::ExtractionJob` — Active Job that fetches the document, sends to OpenAI Vision, parses the response, creates `ExtractedField` records
- [ ] `Documents::ExtractionService` — orchestrates the Vision API call: builds the prompt, sends image/PDF, parses structured JSON response
- [ ] `extractDocumentData` tool handler — replaces stub: triggers `ExtractionJob`, returns `{ status: "processing", document_id: }` immediately
- [ ] Vision API prompt template — instructs GPT-4o to extract specific fields based on `document_type`, return JSON with field names, values, and confidence scores
- [ ] `Document` status transitions: `uploaded` → `processing` → `extracted` (or `extraction_failed`)
- [ ] `ExtractedField` records created: one row per field (field_name, value, confidence, status: "pending")
- [ ] PDF handling: convert first page to image (using `image_processing` / `vips`) before sending to Vision API, or send as base64
- [ ] Action Cable notification when extraction completes — push results to the chat so the assistant can continue
- [ ] Unit tests for `Documents::ExtractionService` (mock Vision API response, verify field parsing)
- [ ] Unit tests for `Documents::ExtractionJob` (verify status transitions, error handling)
- [ ] Integration test: upload → job enqueued → extraction complete → fields stored

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Uploading a document triggers an extraction job | Upload file → check Sidekiq/Solid Queue for enqueued `ExtractionJob` |
| 2 | Vision API receives the image and returns structured fields | Mock or real API call → response contains expected field names |
| 3 | ExtractedField records are created for each field | After job completes → `ExtractedField.where(document_id:)` returns rows |
| 4 | Each ExtractedField has a confidence score (0.0–1.0) | Check `extracted_field.confidence` is a decimal in range |
| 5 | Document status transitions correctly | `uploaded` → `processing` → `extracted` visible in DB |
| 6 | Failed extraction sets status to `extraction_failed` | Force API error → document status is `extraction_failed` |
| 7 | Chat is notified when extraction completes | Action Cable broadcast after job → assistant acknowledges results |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/jobs/documents/extraction_job.rb` | Background job: calls ExtractionService, handles errors |
| `app/services/documents/extraction_service.rb` | Vision API call, response parsing, ExtractedField creation |
| `config/prompts/extraction_prompts.yml` | Per-document-type extraction prompts with expected field lists |

### Modified files

| File | Changes |
|------|---------|
| `app/services/tools/router.rb` | Replace `extractDocumentData` stub with real handler that enqueues job |
| `app/models/document.rb` | Add status transition methods, `has_many :extracted_fields` |
| `app/models/extracted_field.rb` | Ensure model exists with validations |
| `app/channels/onboarding_chat_channel.rb` | Receive extraction-complete broadcast, feed results to orchestrator |

### Extraction flow

1. `extractDocumentData` tool called by LLM with `{ imageFile: document_id, documentType: "drivers_license" }`
2. Tool handler sets `document.status = "processing"`, enqueues `Documents::ExtractionJob`
3. Returns immediately: `{ status: "processing", document_id: 42 }`
4. Job runs asynchronously:
   a. Fetches document file from Active Storage
   b. If PDF, converts first page to image
   c. Encodes image as base64
   d. Builds Vision API request with extraction prompt for the document_type
   e. Sends to OpenAI Vision (GPT-4o with `image_url` content type)
   f. Parses structured JSON response
   g. Creates `ExtractedField` records (one per field)
   h. Sets `document.status = "extracted"`
5. Job broadcasts via Action Cable: `{ event: "extraction_complete", document_id: 42 }`
6. Chat picks up the event; orchestrator calls `validateExtractedData` or presents fields to user

### Vision API prompt structure

```
Analyze this {document_type} document image. Extract the following fields and return a JSON object.

Expected fields: {field_list_from_config}

Return format:
{
  "fields": [
    { "field_name": "full_name", "value": "Jane Doe", "confidence": 0.95 },
    { "field_name": "date_of_birth", "value": "1990-05-15", "confidence": 0.88 }
  ]
}

If a field is not visible or unreadable, set value to null and confidence to 0.0.
```

### Expected fields by document type

| Document type | Fields |
|---------------|--------|
| `drivers_license` | full_name, date_of_birth, address, license_number, expiration_date, state |
| `w4` | full_name, ssn_last_4, address, filing_status, dependents |
| `passport` | full_name, date_of_birth, passport_number, expiration_date, nationality |
| `i9` | full_name, date_of_birth, ssn_last_4, citizenship_status |

---

## Files You Should READ Before Coding

1. `db/schema.rb` — `extracted_fields` table (document_id, field_name, value, confidence, status)
2. `app/services/llm/chat_service.rb` — OpenAI client pattern to reuse for Vision API
3. `app/services/tools/router.rb` — current `extractDocumentData` stub to replace
4. `config/prompts/tool_definitions.yml` — `extractDocumentData` schema (imageFile, documentType)
5. `app/models/document.rb` — existing model associations
6. `app/models/extracted_field.rb` — existing model

---

## Technical Notes

- **OpenAI Vision API:** Use the same `openai` gem. Send a `chat/completions` request with `model: "gpt-4o"` and a message containing `type: "image_url"` content. The image can be a base64 data URL or a presigned URL.
- **PDF to image:** Use `vips` (via `image_processing` gem) or `MiniMagick` to render the first page of a PDF as a PNG. If this adds too much complexity, start with image-only support and add PDF conversion as a follow-up.
- **Job queue:** Use Solid Queue (Rails 7.2 default) or Sidekiq if already configured. Ensure `config/queue.yml` has a `:documents` queue.
- **Retry policy:** `ExtractionJob` should retry up to 3 times with exponential backoff on API errors. After max retries, set `document.status = "extraction_failed"`.
- **Cost awareness:** Each Vision API call costs ~$0.01–0.05 depending on image size. Log token usage for P5-003 cost tracking.

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P2-002 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P2-002-ocr-extraction
```

---

## Out of Scope for P2-002

- Field validation or confidence-tiered review (P2-003)
- PII encryption of extracted values (P2-004)
- Config-driven document type definitions (P2-005) — for now, field lists can be hardcoded in the prompt YAML
- Multi-page PDF extraction (extract first page only for MVP)
- Real `validateExtractedData` implementation (P2-003)
