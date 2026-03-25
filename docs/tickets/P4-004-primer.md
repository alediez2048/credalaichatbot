# P4-004 — Escalation tiers & human handoff

**Priority:** P4
**Estimate:** 3.5 hours
**Phase:** 4 — Emotional Support
**Status:** Not started

---

## Goal

Detect when the chatbot cannot adequately help a user and escalate to a human agent. Implement a tiered escalation system: Tier 1 (proactive support — more context, slower pace), Tier 2 (offer human help — explicit "would you like to talk to someone?"), Tier 3 (automatic handoff — connect to human agent). Triggers include sustained frustration, repeated failures on the same step, explicit help requests, and sentiment escalation patterns. The handoff mechanism creates an escalation record, notifies available agents, and transitions the chat to a "waiting for human" state.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P4-004 |
|--------|----------------------|
| **P4-001** | `Sentiment::Tracker` with `is_escalating?` and trend queries |
| **P4-002** | Sentiment-aware prompting (Tier 1 uses adaptive behavior) |
| **P1-002** | Orchestrator with step tracking and session state |
| **P1-001** | Action Cable for real-time notifications |

---

## Deliverables Checklist

- [ ] `Escalation::Engine` — evaluates escalation triggers, determines current tier, decides whether to escalate
- [ ] `Escalation::TriggerEvaluator` — checks all trigger conditions (sentiment, repeated failures, explicit request, time-on-step)
- [ ] `Escalation::HandoffService` — creates escalation record, notifies agents, transitions session state
- [ ] Migration: `create_escalations` table (onboarding_session_id, tier, trigger_reason, status, assigned_agent_id, resolved_at, notes, timestamps)
- [ ] `Escalation` model with state machine: `pending` → `assigned` → `in_progress` → `resolved`
- [ ] Tier definitions in `config/prompts/escalation_tiers.yml` (trigger thresholds, actions, prompt overrides)
- [ ] Update `Onboarding::Orchestrator` to run escalation check after each turn
- [ ] Tier 1: automatic — inject extra-supportive prompt instructions (delegates to P4-002 adaptation)
- [ ] Tier 2: semi-automatic — LLM offers human help; if user accepts, proceed to Tier 3
- [ ] Tier 3: handoff — create Escalation record, set session status to "escalated", broadcast notification to agent channel
- [ ] `EscalationChannel` (Action Cable) — agents subscribe to receive escalation notifications in real time
- [ ] Agent notification: broadcast escalation to `EscalationChannel` with session summary (step, sentiment history, recent messages)
- [ ] Session state: when escalated, chatbot informs user that a human will be in touch and continues to answer basic questions
- [ ] Explicit trigger: user says "let me talk to a person" / "I need help from a human" → skip to Tier 3
- [ ] Unit tests for TriggerEvaluator (each trigger type: sentiment, failures, explicit, time)
- [ ] Unit tests for Engine (tier determination, escalation decisions)
- [ ] Unit tests for HandoffService (record creation, state transition, notification)
- [ ] Integration test: sustained frustration → Tier 1 → Tier 2 offer → user accepts → Tier 3 handoff

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Sustained frustrated sentiment (3+ readings) triggers Tier 1 | Unit test: create 3 frustrated readings, run Engine, assert Tier 1 activated |
| 2 | Tier 1 injects extra-supportive instructions without user-visible escalation | Unit test: Tier 1 active, assert prompt includes Tier 1 instructions, no "escalated" message to user |
| 3 | Continued frustration after Tier 1 triggers Tier 2 (offer human help) | Unit test: Tier 1 already active + 2 more frustrated readings, assert Tier 2 |
| 4 | User accepting human help in Tier 2 triggers Tier 3 handoff | Integration test: simulate Tier 2 offer, user says "yes", assert Escalation record created |
| 5 | Explicit "talk to a human" request triggers immediate Tier 3 | Unit test: message contains human-help phrase, assert Tier 3 regardless of sentiment |
| 6 | Tier 3 creates Escalation record with session summary | Unit test: handoff, assert Escalation record with correct trigger_reason and session data |
| 7 | Agent receives real-time notification via EscalationChannel | Integration test: Tier 3 triggered, assert broadcast on EscalationChannel |
| 8 | Session status set to "escalated" during handoff | Unit test: handoff, assert session.status == "escalated" |
| 9 | Chatbot informs user that help is on the way | Unit test: Tier 3, assert assistant message includes handoff acknowledgment |
| 10 | Repeated failures on same step (3+ attempts) triggers Tier 2 | Unit test: 3 failed attempts on document_upload, assert Tier 2 |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/services/escalation/engine.rb` | Core escalation logic, tier management |
| `app/services/escalation/trigger_evaluator.rb` | Evaluate all trigger conditions |
| `app/services/escalation/handoff_service.rb` | Create record, notify agents, transition state |
| `app/models/escalation.rb` | ActiveRecord model with state machine |
| `app/channels/escalation_channel.rb` | Action Cable channel for agent notifications |
| `db/migrate/XXXX_create_escalations.rb` | Escalations table |
| `config/prompts/escalation_tiers.yml` | Tier definitions and thresholds |
| `test/unit/escalation/engine_test.rb` | Engine tests |
| `test/unit/escalation/trigger_evaluator_test.rb` | Evaluator tests |
| `test/unit/escalation/handoff_service_test.rb` | Service tests |
| `test/models/escalation_test.rb` | Model tests |

### Modified files

| File | Changes |
|------|---------|
| `app/services/onboarding/orchestrator.rb` | Run escalation check after each turn |
| `app/models/onboarding_session.rb` | Add `has_many :escalations`, status "escalated" |
| `config/routes.rb` | Mount EscalationChannel (if needed) |

### Schema: `escalations`

```ruby
create_table :escalations do |t|
  t.references :onboarding_session, null: false, foreign_key: true
  t.integer    :tier,               null: false  # 1, 2, or 3
  t.string     :trigger_reason,     null: false  # sentiment_escalation, repeated_failure, explicit_request, time_on_step
  t.string     :status,             null: false, default: "pending"  # pending, assigned, in_progress, resolved
  t.bigint     :assigned_agent_id
  t.datetime   :resolved_at
  t.text       :notes
  t.jsonb      :context,            default: {}  # snapshot of session state at escalation time
  t.timestamps
end

add_index :escalations, [:onboarding_session_id, :status]
add_index :escalations, [:assigned_agent_id, :status]
```

### Escalation tiers config

```yaml
# config/prompts/escalation_tiers.yml

tiers:
  1:
    name: "Proactive Support"
    description: "Enhanced AI support with extra patience and guidance"
    triggers:
      - type: sentiment_escalation
        condition: "3+ frustrated or anxious readings in current session"
      - type: time_on_step
        condition: "User stuck on same step for 5+ minutes with no progress"
    actions:
      - inject_supportive_prompt
    prompt_override: |
      IMPORTANT: This user needs extra support. Be exceptionally patient and helpful.
      Break every instruction into small, clear steps. Offer examples proactively.
      Check in after each sub-step to make sure they're comfortable.

  2:
    name: "Offer Human Help"
    description: "Explicitly offer to connect user with a human agent"
    triggers:
      - type: sentiment_escalation
        condition: "Tier 1 active AND 2+ additional frustrated readings"
      - type: repeated_failure
        condition: "3+ failed attempts on the same step"
    actions:
      - offer_human_help
    prompt_override: |
      The user may benefit from human assistance. At a natural pause, warmly offer:
      "I want to make sure you get the best help possible. Would you like me to
      connect you with a member of our HR team who can walk you through this?"
      If they say yes, call the escalation tool. If they decline, continue helping.

  3:
    name: "Human Handoff"
    description: "Transfer to human agent"
    triggers:
      - type: user_accepted_handoff
        condition: "User accepted Tier 2 offer"
      - type: explicit_request
        condition: "User explicitly asks for human help"
        patterns:
          - "talk to a person"
          - "speak to someone"
          - "human agent"
          - "need help from a real person"
          - "let me talk to someone"
          - "connect me with"
    actions:
      - create_escalation_record
      - notify_agents
      - set_session_escalated

escalation_settings:
  sentiment_window: 10          # look at last N sentiment readings
  frustrated_threshold: 3       # N frustrated readings to trigger Tier 1
  tier2_additional_threshold: 2 # additional frustrated readings after Tier 1
  step_failure_threshold: 3     # failed attempts before Tier 2
  time_on_step_minutes: 5       # minutes stuck to trigger Tier 1
```

### TriggerEvaluator

```ruby
module Escalation
  class TriggerEvaluator
    def initialize(session)
      @session = session
      @config = load_config
    end

    def evaluate
      triggers = []
      triggers << :sentiment_escalation if sentiment_escalating?
      triggers << :repeated_failure if repeated_failures?
      triggers << :explicit_request if explicit_help_request?
      triggers << :time_on_step if stuck_on_step?
      triggers
    end

    private

    def sentiment_escalating?
      recent = @session.sentiment_readings
        .order(created_at: :desc)
        .limit(@config["escalation_settings"]["sentiment_window"])

      frustrated_count = recent.where(label: %w[frustrated anxious]).count
      frustrated_count >= @config["escalation_settings"]["frustrated_threshold"]
    end

    def repeated_failures?
      step_attempts = @session.metadata.dig("step_attempts", @session.current_step) || 0
      step_attempts >= @config["escalation_settings"]["step_failure_threshold"]
    end

    def explicit_help_request?
      last_message = @session.messages.where(role: "user").order(created_at: :desc).first
      return false unless last_message

      patterns = @config.dig("tiers", 3, "triggers")
        &.find { |t| t["type"] == "explicit_request" }
        &.dig("patterns") || []

      patterns.any? { |p| last_message.content.downcase.include?(p.downcase) }
    end

    def stuck_on_step?
      step_entered_at = @session.metadata["step_entered_at"]
      return false unless step_entered_at

      minutes_on_step = (Time.current - Time.parse(step_entered_at)) / 60
      minutes_on_step >= @config["escalation_settings"]["time_on_step_minutes"]
    end
  end
end
```

### Engine

```ruby
module Escalation
  class Engine
    def initialize(session)
      @session = session
      @evaluator = TriggerEvaluator.new(session)
    end

    def check!
      triggers = @evaluator.evaluate
      return nil if triggers.empty?

      current_tier = current_escalation_tier
      new_tier = determine_tier(triggers, current_tier)

      return nil if new_tier <= current_tier

      case new_tier
      when 1 then activate_tier_1(triggers)
      when 2 then activate_tier_2(triggers)
      when 3 then activate_tier_3(triggers)
      end
    end

    private

    def current_escalation_tier
      @session.escalations.where.not(status: "resolved").maximum(:tier) || 0
    end

    def determine_tier(triggers, current_tier)
      return 3 if triggers.include?(:explicit_request)
      return 2 if triggers.include?(:repeated_failure) && current_tier < 2
      return 2 if current_tier == 1 && triggers.include?(:sentiment_escalation)
      return 1 if triggers.include?(:sentiment_escalation) && current_tier < 1
      current_tier
    end

    def activate_tier_3(triggers)
      HandoffService.new(@session).execute!(
        tier: 3,
        trigger_reason: triggers.first.to_s
      )
    end
  end
end
```

### HandoffService

```ruby
module Escalation
  class HandoffService
    def initialize(session)
      @session = session
    end

    def execute!(tier:, trigger_reason:)
      escalation = Escalation.create!(
        onboarding_session: @session,
        tier: tier,
        trigger_reason: trigger_reason,
        status: "pending",
        context: build_context_snapshot
      )

      @session.update!(status: "escalated") if tier == 3

      if tier == 3
        ActionCable.server.broadcast("escalation_channel", {
          type: "new_escalation",
          escalation_id: escalation.id,
          session_id: @session.id,
          tier: tier,
          trigger: trigger_reason,
          summary: build_context_snapshot
        })
      end

      escalation
    end

    private

    def build_context_snapshot
      {
        current_step: @session.current_step,
        progress_percent: @session.progress_percent,
        recent_messages: @session.messages.order(created_at: :desc).limit(10).map { |m|
          { role: m.role, content: m.content.truncate(200) }
        },
        sentiment_trend: @session.sentiment_readings.order(created_at: :desc).limit(5).map { |r|
          { label: r.label, confidence: r.confidence, at: r.created_at }
        }
      }
    end
  end
end
```

---

## Files You Should READ Before Coding

1. `app/services/sentiment/tracker.rb` — `is_escalating?` and trend queries
2. `app/services/onboarding/orchestrator.rb` — where to hook escalation checks
3. `app/channels/onboarding_chat_channel.rb` — Action Cable pattern for new channel
4. `app/models/onboarding_session.rb` — session state and associations
5. `config/prompts/sentiment_adaptations.yml` — P4-002 config pattern
6. `db/schema.rb` — existing table patterns

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P4-004 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P4-004-escalation-handoff
```

---

## Out of Scope for P4-004

- Agent-side UI for managing escalations (future — agents receive Action Cable notifications only)
- Live co-browsing or screen sharing (future)
- Automated agent assignment / load balancing (future)
- SLA tracking or response time metrics (P5-004)
- Email/Slack notifications for agents (future — Action Cable only for now)
