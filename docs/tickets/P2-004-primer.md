# P2-004 — PII handling & document lifecycle

**Priority:** P2
**Estimate:** 3 hours
**Phase:** 2 — Document Processing
**Status:** Not started

---

## Goal

Protect personally identifiable information (PII) throughout the document pipeline. Encrypt sensitive extracted field values at rest, implement a document retention policy that auto-deletes uploaded files after a configurable number of days, add audit logging for every document access, and redact PII from application logs. This ticket hardens the document pipeline built in P2-001 through P2-003.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P2-004 |
|--------|----------------------|
| **P0-001** | `AuditLog` model (already in schema) |
| **P2-001** | Document upload with Active Storage |
| **P2-002** | ExtractedField records with PII values |
| **P2-003** | Field validation flow (must encrypt after validation completes) |

---

## Deliverables Checklist

- [ ] `ExtractedField` model: encrypt `value` column at rest using Active Record Encryption (Rails 7+ built-in)
- [ ] Encryption key configuration in `config/credentials.yml.enc` or `ENV["ACTIVE_RECORD_ENCRYPTION_*"]`
- [ ] `Documents::RetentionJob` — scheduled job that deletes documents (and their Active Storage blobs) older than `N` days (configurable via `ENV["DOCUMENT_RETENTION_DAYS"]`, default 90)
- [ ] `Documents::RetentionService` — finds expired documents, purges files, destroys records, logs deletions
- [ ] Audit logging: create `AuditLog` entries for document upload, document view/download, extraction access, field correction, and document deletion
- [ ] `Auditable` concern — mixin for controllers/services that auto-logs access events to `AuditLog`
- [ ] PII log redaction: Rails log filter parameters updated to redact PII field values (SSN, DOB, address, etc.)
- [ ] `Documents::PiiRedactor` — utility that strips or masks PII from strings before they reach logs or traces
- [ ] Ensure PII is never logged in plain text in Observability traces (LangSmith spans)
- [ ] Unit tests for Active Record Encryption on `ExtractedField` (verify value is encrypted in DB, decrypted in Ruby)
- [ ] Unit tests for `Documents::RetentionService` (expired documents deleted, non-expired preserved)
- [ ] Unit tests for `Documents::PiiRedactor` (SSN, DOB, name patterns masked)
- [ ] Unit test for audit log creation on document access

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | ExtractedField values are encrypted at rest | Query DB directly (psql) → `value` column is ciphertext, not plaintext |
| 2 | Decrypted values are accessible in Ruby | `ExtractedField.find(id).value` → returns readable plaintext |
| 3 | Documents older than retention period are auto-deleted | Create document with old `created_at` → run job → document and blob purged |
| 4 | Active Storage blobs are purged along with documents | After retention job → `ActiveStorage::Blob.count` reduced, files removed from disk |
| 5 | Audit log entry created on document upload | Upload a file → `AuditLog.last` has `action: "document_upload"` |
| 6 | Audit log entry created on extraction access | View extracted fields → `AuditLog` has `action: "extraction_access"` |
| 7 | PII values are redacted from Rails logs | Check `log/development.log` → SSN, DOB values replaced with `[REDACTED]` |
| 8 | PII is not present in observability traces | Check LangSmith spans → no raw SSN or DOB values in trace payloads |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/jobs/documents/retention_job.rb` | Scheduled job to purge expired documents |
| `app/services/documents/retention_service.rb` | Finds and deletes expired documents with audit trail |
| `app/services/documents/pii_redactor.rb` | Masks PII patterns in strings (SSN, DOB, etc.) |
| `app/models/concerns/auditable.rb` | Concern that provides `log_audit_event` helper |

### Modified files

| File | Changes |
|------|---------|
| `app/models/extracted_field.rb` | Add `encrypts :value` declaration |
| `app/models/document.rb` | Add `dependent: :destroy` for extracted_fields, retention scope |
| `app/controllers/api/documents_controller.rb` | Add audit logging on upload |
| `app/controllers/api/extracted_fields_controller.rb` | Add audit logging on access and correction |
| `app/services/observability/tracer.rb` | Integrate PiiRedactor before sending span data |
| `config/application.rb` or `config/initializers/filter_parameter_logging.rb` | Add PII patterns to `filter_parameters` |
| `config/credentials.yml.enc` | Add Active Record Encryption keys |

### Active Record Encryption setup

```ruby
# app/models/extracted_field.rb
class ExtractedField < ApplicationRecord
  encrypts :value

  belongs_to :document
end
```

Requires encryption keys configured via:
```yaml
# config/credentials.yml.enc (or ENV vars)
active_record_encryption:
  primary_key: <32-byte key>
  deterministic_key: <32-byte key>
  key_derivation_salt: <salt>
```

### Document retention flow

1. `Documents::RetentionJob` runs on a schedule (daily via cron or Solid Queue recurring)
2. Calls `Documents::RetentionService.purge_expired`
3. Service queries: `Document.where("created_at < ?", retention_days.days.ago)`
4. For each expired document:
   a. Creates `AuditLog` entry: `action: "document_deleted", resource_type: "Document", resource_id: doc.id`
   b. Purges Active Storage attachment (`doc.file.purge`)
   c. Destroys `ExtractedField` records (via `dependent: :destroy`)
   d. Destroys `Document` record
5. Returns count of purged documents

### Audit log events

| Action | Trigger | Payload |
|--------|---------|---------|
| `document_upload` | `POST /api/documents` | `{ document_type:, byte_size:, content_type: }` |
| `document_view` | Document file accessed/downloaded | `{ document_id: }` |
| `extraction_access` | Extracted fields viewed | `{ document_id:, field_count: }` |
| `field_correction` | User edits an extracted field | `{ field_id:, field_name:, changed: true }` (no PII in payload) |
| `document_deleted` | Retention job purges document | `{ document_id:, age_days: }` |

### PII redaction patterns

| Pattern | Example input | Redacted output |
|---------|--------------|-----------------|
| SSN (full or partial) | `123-45-6789` | `[SSN REDACTED]` |
| Date of birth | `1990-05-15` | `[DOB REDACTED]` |
| Email address | `jane@example.com` | `[EMAIL REDACTED]` |
| Street address | `123 Main St` | (not auto-redacted — too broad; redact by field name) |

---

## Files You Should READ Before Coding

1. `db/schema.rb` — `audit_logs` table, `extracted_fields` table
2. `app/models/extracted_field.rb` — where to add `encrypts`
3. `app/models/audit_log.rb` — existing model
4. `app/services/observability/tracer.rb` — where to add PII filtering
5. `config/initializers/filter_parameter_logging.rb` — existing Rails log filters
6. `app/controllers/api/documents_controller.rb` — where to add audit hooks (P2-001)

---

## Technical Notes

- **Active Record Encryption** is built into Rails 7+. No extra gems needed. Run `bin/rails db:encryption:init` to generate keys, then add to credentials.
- **Deterministic vs non-deterministic encryption:** Use non-deterministic (default) for PII fields since we do not need to query by encrypted value. This is more secure.
- **Retention job scheduling:** Use Solid Queue's recurring schedule or a simple cron. For dev, provide a rake task `rails documents:purge_expired` to run manually.
- **Audit log payload:** Never include raw PII values in audit log payloads. Log field names and IDs, not values.
- **Testing encryption:** In test environment, encryption still works but with test keys. Verify by checking the raw DB value differs from the Ruby attribute value.

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P2-004 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P2-004-pii-lifecycle
```

---

## Out of Scope for P2-004

- HIPAA or SOC 2 full compliance (this is a demo project — encryption and audit are best-effort)
- Encryption of Active Storage blobs themselves (files are deleted by retention; encrypting blob storage is a prod concern)
- User-facing audit trail UI (admin dashboard is P5-004)
- Config-driven document types (P2-005)
- Key rotation (document for prod but do not implement rotation logic)
