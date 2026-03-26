# CI Prompt Regression Testing

## How It Works

The `Prompt Eval` GitHub Actions workflow runs automatically on PRs that modify:

- `backend/config/prompts/**` — prompt templates
- `backend/app/services/llm/**` — LLM service code
- `backend/app/services/onboarding/orchestrator.rb` — orchestrator logic
- `backend/test/eval/**` — eval test cases

The workflow:
1. Sets up Postgres + Redis
2. Runs `rails eval:ci` which executes all eval test cases against the live LLM
3. Checks the pass rate against the threshold (default: 85%)
4. Posts a comment on the PR with results
5. Fails the build if pass rate is below threshold

## Configuration

### Threshold

Set `EVAL_PASS_THRESHOLD` as a GitHub Actions variable (Settings > Variables):

```
EVAL_PASS_THRESHOLD=85
```

Or override in `backend/config/ci/eval_config.yml`:

```yaml
threshold: 85
```

### Required Secrets

| Secret | Purpose |
|--------|---------|
| `OPENAI_API_KEY` | LLM calls during eval |
| `LANGSMITH_API_KEY` | Trace eval runs (optional) |

## Adding Test Cases

1. Create a new YAML file in `backend/test/eval/cases/`
2. Follow the existing format:

```yaml
- name: "descriptive test name"
  category: "your_category"
  input: "user message to test"
  strategy: "contains"     # contains, not_contains, regex, tool_called, step_changed
  expected: "expected text"
```

3. Run locally first: `cd backend && bundle exec rails eval:run`
4. Push — the workflow will pick up the new cases

## Debugging Failures

### Run locally

```bash
cd backend
bundle exec rails eval:run      # full report with details
bundle exec rails eval:ci        # CI mode with threshold check
```

### Check the JSON report

After running, inspect `backend/tmp/eval_report.json` for detailed results including:
- Per-case pass/fail with reasons
- Category breakdowns
- Timestamps

### Common failure patterns

1. **Prompt wording change** — update eval cases to match new expected output
2. **Tool call regression** — check `tool_called` strategy cases against router changes
3. **Step flow change** — update `step_changed` strategy expectations

### LangSmith traces

CI eval runs are tagged with `is_eval: true` and posted to the `credal-onboarding-ci` LangSmith project. Filter by this tag to inspect LLM responses for failing cases.

## Local Testing with `act`

You can test the workflow locally using [act](https://github.com/nektos/act):

```bash
# Install act
brew install act

# Run with secrets
act pull_request \
  -s OPENAI_API_KEY=$OPENAI_API_KEY \
  -s LANGSMITH_API_KEY=$LANGSMITH_API_KEY \
  -W .github/workflows/eval.yml
```

Note: `act` requires Docker. The PR comment step will be skipped locally.
