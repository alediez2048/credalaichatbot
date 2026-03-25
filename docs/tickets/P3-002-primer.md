# P3-002 — AI-powered slot recommendation

**Priority:** P3
**Estimate:** 3 hours
**Phase:** 3 — Scheduling
**Status:** Not started

---

## Goal

Wire the `getAvailableSlots` tool to real data from P3-001 and build an AI-powered recommendation layer. When the user asks to schedule an appointment, the LLM calls `getAvailableSlots`, receives available slots, and recommends the best options based on user preferences (time of day, day of week, proximity to other commitments). The LLM presents a short list of 3-5 recommended slots in a conversational format and lets the user pick. Wire `bookAppointment` to actually create the booking via `SlotManager#book!`.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P3-002 |
|--------|----------------------|
| **P3-001** | `AppointmentSlot` model, `Scheduling::SlotManager`, seed data |
| **P0-003** | `Tools::Router`, tool definitions for `getAvailableSlots` and `bookAppointment` |
| **P1-002** | Orchestrator handles tool calls in the scheduling step |

---

## Deliverables Checklist

- [ ] `Tools::Handlers::GetAvailableSlots` — real handler replacing stub; calls `SlotManager#list_available`, returns structured slot data
- [ ] `Tools::Handlers::BookAppointment` — real handler replacing stub; calls `SlotManager#book!`, returns confirmation
- [ ] `Scheduling::SlotRecommender` — takes available slots + user preferences (from session metadata) and scores/ranks them
- [ ] Update `Tools::Router` to map `getAvailableSlots` and `bookAppointment` to real handlers
- [ ] Update `config/prompts/tool_definitions.yml` if parameter refinements are needed (e.g., add `preferredTimeOfDay`, `preferredDayOfWeek` to `getAvailableSlots`)
- [ ] Prompt instructions for the scheduling step: tell LLM to ask about preferences before fetching slots, present top 3-5 options, confirm choice before booking
- [ ] Unit tests for GetAvailableSlots handler (returns formatted slot data)
- [ ] Unit tests for BookAppointment handler (success + slot-full error)
- [ ] Unit tests for SlotRecommender (scoring logic)
- [ ] Integration test: user asks to schedule → LLM calls getAvailableSlots → results returned → user picks → bookAppointment called → booking confirmed

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | `getAvailableSlots` tool returns real slot data from the database | Unit test: create slots, call handler, assert slots in response |
| 2 | Slots are filtered by date range and service type when provided | Unit test: pass filters, assert correct subset returned |
| 3 | `bookAppointment` creates a real Booking and increments slot count | Unit test: call handler, assert Booking created, booked_count incremented |
| 4 | `bookAppointment` returns error when slot is full | Unit test: fill slot, attempt book, assert error response |
| 5 | SlotRecommender ranks slots based on user preferences | Unit test: pass preferences + slots, assert ordering |
| 6 | LLM presents top 3-5 slots conversationally in chat | Manual test: go through scheduling step, observe slot presentation |
| 7 | End-to-end: user can book an appointment through chat | Integration test: multi-turn scheduling conversation completes with Booking record |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/services/tools/handlers/get_available_slots.rb` | Real tool handler for `getAvailableSlots` |
| `app/services/tools/handlers/book_appointment.rb` | Real tool handler for `bookAppointment` |
| `app/services/scheduling/slot_recommender.rb` | Preference-based scoring and ranking |
| `test/unit/tools/handlers/get_available_slots_test.rb` | Handler tests |
| `test/unit/tools/handlers/book_appointment_test.rb` | Handler tests |
| `test/unit/scheduling/slot_recommender_test.rb` | Recommender tests |

### Modified files

| File | Changes |
|------|---------|
| `app/services/tools/router.rb` | Map `getAvailableSlots` and `bookAppointment` to real handlers |
| `config/prompts/onboarding_steps.yml` | Scheduling step prompt instructions (preference gathering, slot presentation) |

### Tool handler: GetAvailableSlots

```ruby
module Tools
  module Handlers
    class GetAvailableSlots
      def call(params, context:)
        date_range = parse_date_range(params["dateRange"])
        service_type = params["serviceType"]

        slots = Scheduling::SlotManager.new.list_available(
          date_range: date_range,
          service_type: service_type
        )

        # Score and rank if user preferences available
        if context[:session]&.metadata&.dig("scheduling_preferences")
          prefs = context[:session].metadata["scheduling_preferences"]
          slots = Scheduling::SlotRecommender.new(prefs).rank(slots)
        end

        {
          success: true,
          data: {
            slots: slots.first(10).map { |s| format_slot(s) },
            total_available: slots.count
          }
        }
      end
    end
  end
end
```

### SlotRecommender scoring

```ruby
module Scheduling
  class SlotRecommender
    WEIGHTS = {
      time_of_day: 3,    # morning/afternoon/evening preference
      day_of_week: 2,    # specific day preference
      soonest: 1         # prefer sooner dates by default
    }.freeze

    def initialize(preferences)
      @preferences = preferences
    end

    def rank(slots)
      slots.sort_by { |slot| -score(slot) }
    end

    private

    def score(slot)
      total = 0
      total += WEIGHTS[:time_of_day] * time_match(slot)
      total += WEIGHTS[:day_of_week] * day_match(slot)
      total += WEIGHTS[:soonest] * recency_score(slot)
      total
    end
  end
end
```

### Prompt additions for scheduling step

```yaml
scheduling:
  prompt_instructions: |
    You are helping the user schedule an onboarding appointment.
    1. Ask what type of appointment they need (orientation, HR review, IT setup).
    2. Ask about their preferred time of day (morning, afternoon, or no preference).
    3. Ask about preferred days (or "any day this/next week").
    4. Call getAvailableSlots with their preferences.
    5. Present the top 3-5 options in a friendly numbered list with day, date, and time.
    6. When the user picks one, confirm the choice and call bookAppointment.
    7. After booking, confirm with the details and mention they'll receive a calendar invite.
```

---

## Files You Should READ Before Coding

1. `app/services/scheduling/slot_manager.rb` — P3-001 service (list_available, book!)
2. `app/services/tools/router.rb` — current stub handler pattern
3. `config/prompts/tool_definitions.yml` — `getAvailableSlots` and `bookAppointment` schemas
4. `config/prompts/onboarding_steps.yml` — step definitions (if P1-002 is complete)
5. `app/services/onboarding/orchestrator.rb` — how tool calls are executed in the flow

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P3-002 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P3-002-ai-slot-recommendation
```

---

## Out of Scope for P3-002

- Calendar event generation / email (P3-003)
- Rescheduling (P3-004)
- Admin UI for slot management (future)
- Multi-participant bookings (future)
