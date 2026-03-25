# P2-005 — Document type extensibility (config-driven)

**Priority:** P2
**Estimate:** 2 hours
**Phase:** 2 — Document Processing
**Status:** Not started

---

## Goal

Make document types fully config-driven so that adding a new document type (e.g., birth certificate, utility bill) requires only adding a YAML entry — no code changes. Each document type definition includes its display name, expected fields with types and validation rules, extraction prompt hints, and required/optional classification. This ticket refactors the hardcoded field lists and validation rules from P2-002 and P2-003 into a single configuration source.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P2-005 |
|--------|----------------------|
| **P2-002** | OCR extraction pipeline — provides the hardcoded field lists to refactor |
| **P2-003** | Field validation — provides the hardcoded validation rules to refactor |

---

## Deliverables Checklist

- [ ] `config/document_types.yml` — YAML file defining all document types with fields, validation rules, and display metadata
- [ ] `Documents::TypeRegistry` service — loads and caches document type definitions from YAML, provides lookup by type key
- [ ] Refactor `Documents::ExtractionService` (P2-002) to read expected fields from `TypeRegistry` instead of hardcoded lists
- [ ] Refactor `Documents::FieldValidator` (P2-003) to read validation rules from `TypeRegistry` instead of hardcoded rules
- [ ] Refactor extraction prompt templates to dynamically inject field lists from the config
- [ ] Validation: `TypeRegistry` raises clear errors on boot if YAML is malformed or missing required keys
- [ ] Add at least 4 document types: `drivers_license`, `w4`, `passport`, `i9`
- [ ] Unit tests for `Documents::TypeRegistry` (load config, lookup by key, unknown type error)
- [ ] Unit tests verifying extraction and validation use config-driven fields (swap YAML, assert different behavior)
- [ ] Integration test: add a new document type to YAML → extraction and validation work without code changes

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | All document types are defined in `config/document_types.yml` | Read file → contains all 4 types with fields and rules |
| 2 | `TypeRegistry.find("drivers_license")` returns the full definition | Call in console → returns hash with display_name, fields, validation_rules |
| 3 | Adding a new document type requires only a YAML entry | Add `birth_certificate` to YAML → upload + extract + validate works |
| 4 | Extraction prompts dynamically use field lists from config | Extract a `w4` → prompt includes W-4 specific fields from YAML |
| 5 | Validation rules are driven by config | Add a custom regex rule in YAML → FieldValidator enforces it |
| 6 | Unknown document type returns a clear error | `TypeRegistry.find("unknown")` → raises `Documents::UnknownTypeError` |
| 7 | Malformed YAML is caught at boot time | Break YAML syntax → Rails boot logs a clear error message |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `config/document_types.yml` | Canonical document type definitions |
| `app/services/documents/type_registry.rb` | Loads, validates, caches, and looks up document types |

### Modified files

| File | Changes |
|------|---------|
| `app/services/documents/extraction_service.rb` | Replace hardcoded field lists with `TypeRegistry.find(type).fields` |
| `app/services/documents/field_validator.rb` | Replace hardcoded rules with `TypeRegistry.find(type).validation_rules` |
| `config/prompts/extraction_prompts.yml` | Simplify to a generic template that accepts dynamic field lists |
| `config/initializers/document_types.rb` | Optional: eager-load and validate the YAML at boot |

### YAML schema

```yaml
# config/document_types.yml

drivers_license:
  display_name: "Driver's License"
  description: "State-issued driver's license or ID card"
  fields:
    full_name:
      type: string
      required: true
      label: "Full Name"
    date_of_birth:
      type: date
      required: true
      label: "Date of Birth"
      validation:
        format: "\\d{4}-\\d{2}-\\d{2}"
        min_date: "1920-01-01"
    address:
      type: string
      required: true
      label: "Street Address"
    license_number:
      type: string
      required: true
      label: "License Number"
      validation:
        pattern: "^[A-Z0-9]{5,15}$"
    expiration_date:
      type: date
      required: true
      label: "Expiration Date"
      validation:
        format: "\\d{4}-\\d{2}-\\d{2}"
    state:
      type: string
      required: false
      label: "Issuing State"

w4:
  display_name: "W-4 Tax Form"
  description: "Federal tax withholding form"
  fields:
    full_name:
      type: string
      required: true
      label: "Full Name"
    ssn_last_4:
      type: string
      required: true
      label: "SSN (last 4 digits)"
      validation:
        pattern: "^\\d{4}$"
    address:
      type: string
      required: true
      label: "Home Address"
    filing_status:
      type: string
      required: true
      label: "Filing Status"
      validation:
        enum: ["single", "married_filing_jointly", "head_of_household"]
    dependents:
      type: string
      required: false
      label: "Number of Dependents"

passport:
  display_name: "Passport"
  description: "National passport document"
  fields:
    full_name:
      type: string
      required: true
      label: "Full Name"
    date_of_birth:
      type: date
      required: true
      label: "Date of Birth"
      validation:
        format: "\\d{4}-\\d{2}-\\d{2}"
    passport_number:
      type: string
      required: true
      label: "Passport Number"
      validation:
        pattern: "^[A-Z0-9]{6,12}$"
    expiration_date:
      type: date
      required: true
      label: "Expiration Date"
    nationality:
      type: string
      required: true
      label: "Nationality"

i9:
  display_name: "I-9 Employment Verification"
  description: "Employment eligibility verification form"
  fields:
    full_name:
      type: string
      required: true
      label: "Full Name"
    date_of_birth:
      type: date
      required: true
      label: "Date of Birth"
      validation:
        format: "\\d{4}-\\d{2}-\\d{2}"
    ssn_last_4:
      type: string
      required: false
      label: "SSN (last 4 digits)"
      validation:
        pattern: "^\\d{4}$"
    citizenship_status:
      type: string
      required: true
      label: "Citizenship Status"
      validation:
        enum: ["us_citizen", "noncitizen_national", "permanent_resident", "work_authorized_alien"]
```

### TypeRegistry API

```ruby
# Load all types
Documents::TypeRegistry.all
# => { "drivers_license" => { display_name: "Driver's License", fields: { ... } }, ... }

# Lookup single type
config = Documents::TypeRegistry.find("drivers_license")
config.display_name    # => "Driver's License"
config.fields          # => { "full_name" => { type: "string", required: true, ... }, ... }
config.required_fields # => ["full_name", "date_of_birth", "address", "license_number", "expiration_date"]
config.field_names     # => ["full_name", "date_of_birth", "address", "license_number", "expiration_date", "state"]

# Unknown type
Documents::TypeRegistry.find("unknown")
# => raises Documents::UnknownTypeError, "Unknown document type: unknown"
```

### How extraction uses the config

```ruby
# Before (P2-002 hardcoded):
fields = ["full_name", "date_of_birth", "address"]

# After (config-driven):
doc_type = Documents::TypeRegistry.find(document_type)
fields = doc_type.field_names
prompt = build_extraction_prompt(fields, doc_type.display_name)
```

### How validation uses the config

```ruby
# Before (P2-003 hardcoded):
if field_name == "ssn_last_4" && value !~ /^\d{4}$/
  errors << "Invalid SSN"
end

# After (config-driven):
doc_type = Documents::TypeRegistry.find(document_type)
field_config = doc_type.fields[field_name]
if field_config[:validation]&.dig(:pattern)
  regex = Regexp.new(field_config[:validation][:pattern])
  errors << "Invalid #{field_config[:label]}" unless value.match?(regex)
end
```

---

## Files You Should READ Before Coding

1. `app/services/documents/extraction_service.rb` — hardcoded field lists to refactor (P2-002)
2. `app/services/documents/field_validator.rb` — hardcoded validation rules to refactor (P2-003)
3. `config/prompts/extraction_prompts.yml` — extraction prompts that reference field lists (P2-002)
4. `config/prompts/tool_definitions.yml` — `extractDocumentData` and `validateExtractedData` schemas
5. `db/schema.rb` — `documents.document_type` column

---

## Technical Notes

- **Caching:** `TypeRegistry` should load and parse the YAML once, then cache in a class-level variable. Use `Rails.application.config_for` or a simple `YAML.safe_load` with `freeze`. Reload in development via `Rails.application.reloader`.
- **Validation at boot:** Add a `config/initializers/document_types.rb` that calls `Documents::TypeRegistry.validate!` to catch YAML errors early. Log which types are loaded.
- **OpenStruct vs hash:** Use a simple data class or frozen hash for type definitions. Avoid OpenStruct in production (slow). A small `Documents::TypeDefinition` value object is ideal.
- **Enum validation:** For fields with `validation.enum`, the FieldValidator checks that the value is in the allowed list. The extraction prompt should include the enum values as hints.
- **Adding a new type:** The README or inline YAML comments should document the schema so a developer can add a new type without reading Ruby code.

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P2-005 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P2-005-document-type-config
```

---

## Out of Scope for P2-005

- Admin UI for managing document types (would be a future enhancement)
- Versioning of document type definitions (not needed for MVP)
- Per-tenant or per-organization document type overrides
- Multi-language labels or i18n for field labels
- Dynamic loading of document types from a database (YAML is sufficient)
