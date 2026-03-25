# P2-003 — Field validation & confidence-tiered review

**Priority:** P2
**Estimate:** 3 hours
**Phase:** 2 — Document Processing
**Status:** Not started

---

## Goal

Validate extracted fields against expected schemas and implement a confidence-tiered review flow. High-confidence fields (>= 0.90) are auto-accepted. Medium-confidence fields (0.70–0.89) are presented to the user for confirmation. Low-confidence fields (< 0.70) require the user to manually correct or re-enter the value. This ticket replaces the `validateExtractedData` tool stub from P0-003 with a real implementation.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P2-003 |
|--------|----------------------|
| **P0-003** | `Tools::Router`, `validateExtractedData` tool definition |
| **P2-002** | `ExtractedField` records with confidence scores from OCR pipeline |

---

## Deliverables Checklist

- [ ] `Documents::FieldValidator` service — validates extracted fields against expected schemas (type checks, format validation, required field presence)
- [ ] Confidence tier classification: high (>= 0.90), medium (0.70–0.89), low (< 0.70)
- [ ] `ExtractedField` status transitions: `pending` → `auto_accepted` (high) | `needs_review` (medium) | `needs_correction` (low) | `confirmed` (user-approved) | `corrected` (user-edited)
- [ ] `validateExtractedData` tool handler — replaces stub: runs FieldValidator, classifies fields by tier, returns structured result for the LLM
- [ ] Field validation rules: format patterns (date, SSN last 4, email), required fields per document type, value range checks
- [ ] Conversational review flow: LLM presents medium/low fields to user, asks for confirmation or correction, updates `ExtractedField` records
- [ ] `Api::ExtractedFieldsController` — `PATCH /api/extracted_fields/:id` for user corrections from the chat UI
- [ ] React `FieldReview` component — renders extracted fields grouped by confidence tier, allows inline editing and confirmation
- [ ] Unit tests for `Documents::FieldValidator` (valid fields, format mismatches, missing required fields)
- [ ] Unit tests for confidence tier classification logic
- [ ] Integration test: extraction complete → validation → tiered review → user confirms → fields finalized

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | High-confidence fields are auto-accepted without user interaction | Extract with confidence >= 0.90 → status set to `auto_accepted` |
| 2 | Medium-confidence fields are presented for user confirmation | Extract with confidence 0.75 → assistant shows field and asks "Is this correct?" |
| 3 | Low-confidence fields prompt user to re-enter the value | Extract with confidence 0.50 → assistant says "I couldn't read this clearly, please type the value" |
| 4 | Format validation catches invalid values | Date field with value "abc" → flagged as invalid regardless of confidence |
| 5 | User can confirm a medium-confidence field | User replies "yes" or clicks confirm → field status becomes `confirmed` |
| 6 | User can correct a field value | User provides new value → field status becomes `corrected`, value updated |
| 7 | `validateExtractedData` returns structured tier breakdown | Tool returns `{ high: [...], medium: [...], low: [...], invalid: [...] }` |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/services/documents/field_validator.rb` | Validates field values against format rules and required-field lists |
| `app/controllers/api/extracted_fields_controller.rb` | PATCH endpoint for user corrections |
| `app/javascript/components/FieldReview.jsx` | UI for reviewing and correcting extracted fields |

### Modified files

| File | Changes |
|------|---------|
| `app/services/tools/router.rb` | Replace `validateExtractedData` stub with real handler |
| `app/models/extracted_field.rb` | Add status constants, scope methods (`.needs_review`, `.auto_accepted`) |
| `app/javascript/components/ChatApp.jsx` | Render `FieldReview` component when fields need review |
| `config/routes.rb` | Add `resources :extracted_fields, only: [:update]` under api namespace |

### Confidence tiers

| Tier | Confidence range | Behavior | ExtractedField status |
|------|-----------------|----------|----------------------|
| High | >= 0.90 | Auto-accept, no user interaction | `auto_accepted` |
| Medium | 0.70 – 0.89 | Show to user, ask for confirmation | `needs_review` → `confirmed` |
| Low | < 0.70 | Ask user to re-enter value | `needs_correction` → `corrected` |

### Validation rules

| Field pattern | Validation | Example |
|---------------|-----------|---------|
| `date_of_birth`, `expiration_date` | ISO date format (YYYY-MM-DD), reasonable range | `1990-05-15` |
| `ssn_last_4` | Exactly 4 digits | `1234` |
| `email` | RFC-compliant email format | `jane@example.com` |
| `license_number` | Non-empty string, alphanumeric | `D1234567` |
| `full_name` | Non-empty, at least 2 characters | `Jane Doe` |
| `address` | Non-empty string | `123 Main St, Springfield, IL` |

### Validation + review flow

1. P2-002 extraction completes → `ExtractedField` records exist with `status: "pending"`
2. LLM calls `validateExtractedData` with `{ fields: extracted_data, formSchema: "drivers_license" }`
3. `Documents::FieldValidator` runs:
   a. Checks each field against format rules for the document type
   b. Classifies by confidence tier
   c. Auto-accepts high-confidence valid fields (sets `status: "auto_accepted"`)
   d. Marks medium/low fields for review
   e. Flags format-invalid fields regardless of confidence
4. Tool returns structured result to LLM: `{ auto_accepted: [...], needs_review: [...], needs_correction: [...], invalid: [...] }`
5. LLM presents medium-confidence fields: "I extracted your date of birth as 1990-05-15. Is that correct?"
6. User confirms → `PATCH /api/extracted_fields/:id` with `{ status: "confirmed" }`
7. LLM presents low-confidence fields: "I had trouble reading your address. Could you type it in?"
8. User provides value → `PATCH /api/extracted_fields/:id` with `{ value: "...", status: "corrected" }`
9. Once all fields are `auto_accepted`, `confirmed`, or `corrected` → document is fully validated

### `validateExtractedData` response shape

```json
{
  "document_id": 42,
  "document_type": "drivers_license",
  "summary": "4 fields auto-accepted, 1 needs confirmation, 1 needs correction",
  "auto_accepted": [
    { "field_name": "full_name", "value": "Jane Doe", "confidence": 0.97 }
  ],
  "needs_review": [
    { "field_name": "expiration_date", "value": "2028-03-15", "confidence": 0.82 }
  ],
  "needs_correction": [
    { "field_name": "address", "value": "123 M??n St", "confidence": 0.45 }
  ],
  "invalid": []
}
```

---

## Files You Should READ Before Coding

1. `db/schema.rb` — `extracted_fields` table (field_name, value, confidence, status)
2. `app/models/extracted_field.rb` — existing model
3. `app/services/documents/extraction_service.rb` — how fields are created (P2-002)
4. `app/services/tools/router.rb` — current `validateExtractedData` stub
5. `config/prompts/tool_definitions.yml` — `validateExtractedData` schema (fields, formSchema)
6. `config/prompts/extraction_prompts.yml` — expected fields per document type (P2-002)

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P2-003 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P2-003-field-validation
```

---

## Out of Scope for P2-003

- PII encryption of field values (P2-004)
- Document retention or auto-deletion (P2-004)
- Config-driven document type definitions (P2-005) — validation rules can be hardcoded for now
- Cross-document validation (e.g., name on W-4 matches name on driver's license)
- Re-triggering OCR for failed fields (user manually corrects instead)
