# P4-002 — Adaptive chatbot behavior

**Priority:** P4
**Estimate:** 3 hours
**Phase:** 4 — Emotional Support
**Status:** Not started

---

## Goal

Adjust the chatbot's tone, pacing, and verbosity based on the user's detected sentiment (from P4-001). When the user is frustrated, the assistant becomes more patient, acknowledges difficulty, simplifies language, and offers to slow down. When the user is confused, it provides more detailed explanations and examples. When the user is positive, it maintains momentum. This is achieved by dynamically modifying the system prompt with sentiment-aware instructions and wiring the `getSupportContent` tool to return contextual encouragement content.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P4-002 |
|--------|----------------------|
| **P4-001** | `Sentiment::Analyzer`, `Sentiment::Tracker`, `SentimentReading` model |
| **P1-002** | Orchestrator with step-aware system prompt construction |
| **P0-003** | `getSupportContent` tool definition |

---

## Deliverables Checklist

- [ ] `Sentiment::PromptAdapter` — reads latest SentimentReading for session and returns tone/pacing instructions to inject into the system prompt
- [ ] `Tools::Handlers::GetSupportContent` — real handler replacing stub; returns context-appropriate support text based on current step + sentiment level
- [ ] `config/prompts/sentiment_adaptations.yml` — tone instructions per sentiment label (frustrated, confused, anxious, positive, neutral)
- [ ] `config/prompts/support_content.yml` — support messages keyed by (sentiment_label, onboarding_step) pairs
- [ ] Update `Onboarding::Orchestrator` (or `LLM::ContextBuilder`) to inject sentiment adaptation instructions into system prompt before each LLM call
- [ ] Update `Tools::Router` to map `getSupportContent` to real handler
- [ ] Sentiment adaptation is transparent to the user (no "I detect you are frustrated" — just behavior change)
- [ ] Unit tests for PromptAdapter (each sentiment label produces correct instructions)
- [ ] Unit tests for GetSupportContent handler (returns appropriate content for step + sentiment combos)
- [ ] Integration test: frustrated user gets more patient, explanatory responses

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | System prompt includes sentiment adaptation instructions when a reading exists | Unit test: create SentimentReading(frustrated), build prompt, assert frustrated-tone instructions present |
| 2 | No adaptation injected when sentiment is neutral | Unit test: neutral reading, assert no extra instructions (or minimal default) |
| 3 | `getSupportContent` returns step-appropriate support text | Unit test: call handler with context="document_upload" + sentimentLevel="anxious", assert relevant content |
| 4 | Frustrated users receive more patient, simplified responses | Integration test: set frustrated sentiment, send message, observe response tone (manual or LLM-as-judge eval) |
| 5 | Confused users receive more detailed explanations | Integration test: set confused sentiment, send ambiguous question, observe added detail |
| 6 | Adaptation is invisible: assistant never says "I detect you are frustrated" | Review prompt instructions, assert no meta-commentary directive |
| 7 | Adaptation changes dynamically as sentiment shifts | Unit test: update reading from frustrated to positive, assert prompt instructions change accordingly |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/services/sentiment/prompt_adapter.rb` | Reads sentiment, returns prompt modifiers |
| `app/services/tools/handlers/get_support_content.rb` | Real handler for `getSupportContent` |
| `config/prompts/sentiment_adaptations.yml` | Tone instructions per label |
| `config/prompts/support_content.yml` | Support messages by (label, step) |
| `test/unit/sentiment/prompt_adapter_test.rb` | Adapter tests |
| `test/unit/tools/handlers/get_support_content_test.rb` | Handler tests |

### Modified files

| File | Changes |
|------|---------|
| `app/services/onboarding/orchestrator.rb` | Inject sentiment adaptation into system prompt |
| `app/services/llm/context_builder.rb` | Accept optional `sentiment_instructions` parameter |
| `app/services/tools/router.rb` | Map `getSupportContent` to real handler |

### Sentiment adaptations config

```yaml
# config/prompts/sentiment_adaptations.yml

frustrated:
  tone: empathetic and patient
  pacing: slower, one topic at a time
  instructions: |
    The user may be feeling frustrated. Adjust your communication:
    - Acknowledge that the process can be tedious, without being condescending.
    - Use shorter sentences and simpler language.
    - Ask only one question at a time.
    - Offer to explain any step in more detail if they want.
    - Be extra encouraging when they complete something.
    - If they seem stuck, proactively offer alternatives or help.

confused:
  tone: clear and supportive
  pacing: detailed with examples
  instructions: |
    The user may be having trouble understanding. Adjust your communication:
    - Provide brief examples when explaining what's needed.
    - Rephrase your question if they seem unsure how to answer.
    - Break complex steps into smaller sub-steps.
    - Use concrete language instead of abstract terms.
    - Confirm understanding before moving forward.

anxious:
  tone: reassuring and calm
  pacing: measured, with reassurance
  instructions: |
    The user may be feeling anxious about the process. Adjust your communication:
    - Reassure them that there are no wrong answers.
    - Mention that they can always go back and change things.
    - Emphasize that the process is straightforward and they're doing great.
    - Provide context for why each step matters (reduces uncertainty).
    - Be explicit about what comes next so there are no surprises.

positive:
  tone: warm and efficient
  pacing: maintain momentum
  instructions: |
    The user is engaged and positive. Keep the momentum:
    - Be warm but efficient — don't over-explain.
    - Match their energy and pace.
    - Move through steps smoothly.

neutral:
  tone: friendly and professional
  pacing: standard
  instructions: ""
```

### PromptAdapter

```ruby
module Sentiment
  class PromptAdapter
    def initialize(session)
      @session = session
    end

    def adaptation_instructions
      reading = @session.sentiment_readings.order(created_at: :desc).first
      return "" if reading.nil? || reading.label == "neutral"

      config = load_adaptations
      config.dig(reading.label, "instructions") || ""
    end

    private

    def load_adaptations
      @adaptations ||= YAML.load_file(
        Rails.root.join("config/prompts/sentiment_adaptations.yml")
      )
    end
  end
end
```

### Orchestrator integration point

```ruby
# In Onboarding::Orchestrator#build_system_prompt
def build_system_prompt(session, step)
  base_prompt = load_step_prompt(step)
  sentiment_instructions = Sentiment::PromptAdapter.new(session).adaptation_instructions

  [base_prompt, sentiment_instructions].reject(&:blank?).join("\n\n")
end
```

### Support content structure

```yaml
# config/prompts/support_content.yml
# Keyed by sentiment label, then onboarding step

frustrated:
  personal_info: "Collecting your info helps us set up your accounts and get you started faster. We're almost through this part!"
  document_upload: "Document uploads can be tricky — if you're having trouble, you can always come back to this step later."
  scheduling: "Finding the right time is important. Take your time picking what works best for you."

confused:
  personal_info: "We just need a few basics — your full name, email, and phone number. This is used to set up your employee profile."
  document_upload: "Common documents include a driver's license or passport for ID verification, and a W-4 for tax setup."
  scheduling: "You'll be meeting with an HR representative to finalize your onboarding. The meeting usually takes about 30 minutes."

anxious:
  personal_info: "Don't worry — you can always update this information later if anything changes."
  document_upload: "Your documents are encrypted and only visible to HR. They're automatically deleted after processing."
  scheduling: "This is a friendly welcome meeting — no preparation needed. Just pick a time that works for you."
```

---

## Files You Should READ Before Coding

1. `app/services/sentiment/analyzer.rb` — P4-001 analyzer output format
2. `app/services/sentiment/tracker.rb` — how to query latest reading
3. `app/services/onboarding/orchestrator.rb` — system prompt construction
4. `app/services/llm/context_builder.rb` — message array assembly
5. `config/prompts/tool_definitions.yml` — `getSupportContent` schema
6. `config/prompts/onboarding_steps.yml` — step definitions

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P4-002 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P4-002-adaptive-chatbot-behavior
```

---

## Out of Scope for P4-002

- Progress milestones and celebration messages (P4-003)
- Escalation to human agents (P4-004)
- Admin visibility into sentiment trends (P5-004)
- A/B testing different adaptation strategies (future)
