# LangSmith Dashboard Guide

## Project Setup

| Environment | Project Name | Purpose |
|-------------|-------------|---------|
| Development | `credal-onboarding-dev` | Local development traces |
| Production | `credal-onboarding-prod` | Live user session traces |

Set the project via environment variable:

```bash
export LANGSMITH_PROJECT=credal-onboarding-dev
export LANGSMITH_API_KEY=lsv2_pt_your_key_here
```

Tracing is **disabled** when `LANGSMITH_API_KEY` is blank — no network calls, no errors.

---

## Trace Hierarchy

Each onboarding turn produces a parent/child run structure:

```
orchestrator.process (parent — type: chain)
  ├── openai-chat-completion (child — type: llm)
  ├── tool:saveOnboardingProgress (child — type: tool)
  └── openai-chat-completion (child — type: llm, follow-up)
```

- **Parent run** (`orchestrator.process`): wraps the entire `Orchestrator#process` call
- **LLM child runs**: each `ChatService#chat` call, nested under the parent
- **Tool child runs**: each `Tools::Router#call`, with duration tracked

---

## Metadata Fields

Every trace includes these metadata fields:

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | String | `OnboardingSession` ID — groups all runs in one session |
| `user_id` | String | Authenticated user ID (nil for anonymous) |
| `onboarding_step` | String | Current step (welcome, personal_info, etc.) |
| `message_count` | Integer | Messages in session at time of call |
| `is_eval` | Boolean | `true` for eval framework runs, `false` for real users |
| `model` | String | LLM model used (e.g. `gpt-4o`) |
| `latency_seconds` | Float | Wall-clock duration of the call |
| `token_usage` | Hash | `prompt_tokens`, `completion_tokens`, `total_tokens` |

---

## Common Filters

### By Session

Filter all runs belonging to a single onboarding session:

```
Session Name = "42"
```

Or in metadata: `session_id = "42"`

### By Onboarding Step

See all runs for a specific step:

```
Metadata > onboarding_step = "personal_info"
```

### By Errors

Find failed runs:

```
Error is not empty
```

### Eval Runs Only

Filter to evaluation framework runs (exclude real user traffic):

```
Metadata > is_eval = true
```

### Real User Traffic Only

Exclude eval runs:

```
Metadata > is_eval = false
```

Or: `Metadata > is_eval` does not exist (older traces before P5-002).

---

## Debugging Workflows

### Slow Response Investigation

1. Filter by `latency_seconds > 5`
2. Open the parent `orchestrator.process` run
3. Check child runs — is it the LLM call or tool execution?
4. Check `token_usage` — large prompts cause slow responses

### Tool Call Failures

1. Filter by `Error is not empty` + run type `tool`
2. Check the tool name in the run name (`tool:extractDocumentData`)
3. Look at the parent run's inputs to see what prompted the tool call

### Step Transition Issues

1. Filter by `onboarding_step = "personal_info"` (the step with issues)
2. Look at sequential runs for the same `session_id`
3. Check if `step_changed` appears in outputs

### Eval Regression

1. Filter `is_eval = true`
2. Sort by timestamp descending
3. Compare recent eval runs against older ones for the same test case

---

## Rake Tasks

```bash
# Run eval suite locally and post traces to LangSmith
bundle exec rails eval:run

# CI mode — exits 1 if pass rate below threshold
EVAL_THRESHOLD=85 bundle exec rails eval:ci
```

Eval runs are automatically tagged with `is_eval: true` so they don't pollute production dashboards.

---

## Alert Setup (Optional)

In LangSmith, create monitors for:

1. **Error rate spike**: alert when error runs exceed 5% of total in a 1-hour window
2. **Latency degradation**: alert when p95 latency exceeds 10 seconds
3. **Eval regression**: alert when eval pass rate drops below 85%

Configure alerts in: LangSmith > Project Settings > Monitors.
