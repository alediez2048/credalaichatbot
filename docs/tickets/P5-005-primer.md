# P5-005 — Prompt regression testing in CI

**Priority:** P5
**Estimate:** 3 hours
**Phase:** 5 — Evals & Ops
**Status:** Not started

---

## Goal

Add a CI step (GitHub Actions) that runs the eval suite from P5-001 on every pull request that touches prompt files or LLM service code. The step fails the build if the overall pass rate drops below a configurable threshold (default: 85%). This prevents prompt regressions from reaching production.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P5-005 |
|--------|----------------------|
| **P5-001** | Eval framework and test cases must exist |
| **P5-003** | Cost tracking so CI eval costs are recorded |

---

## Deliverables Checklist

- [ ] `.github/workflows/eval.yml` — GitHub Actions workflow triggered on PRs that modify `config/prompts/**`, `app/services/llm/**`, `app/services/onboarding/orchestrator.rb`, or `test/eval/**`
- [ ] Workflow runs `rails eval:run` and parses the JSON report
- [ ] Threshold check: fail the workflow if overall pass rate < `EVAL_PASS_THRESHOLD` (env var, default 85%)
- [ ] `lib/tasks/eval.rake` enhanced with `rails eval:ci` task that exits with non-zero code on threshold failure
- [ ] PR comment posted via GitHub Actions with eval summary (pass rate, failing cases count, cost of eval run)
- [ ] `.env.example` updated with `EVAL_PASS_THRESHOLD`
- [ ] `config/ci/eval_config.yml` — configurable settings: threshold, max cost per run, timeout per case
- [ ] Documentation in `docs/ops/ci-eval.md` explaining how to update thresholds, add cases, debug failures
- [ ] Test the workflow locally with `act` or equivalent (document in ops guide)

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | PR modifying a prompt file triggers eval workflow | Push a branch with prompt change, see workflow start |
| 2 | Workflow passes when eval score >= threshold | Set threshold to 0%, push, see green check |
| 3 | Workflow fails when eval score < threshold | Set threshold to 100%, push, see red X |
| 4 | PR comment shows eval summary | Check PR comments after workflow runs |
| 5 | Non-prompt PRs skip eval workflow | Push a branch with only README change, no eval workflow |
| 6 | Eval cost is tracked | Check `LlmUsage` records tagged with `is_eval: true` after CI run |

---

## Architecture

### GitHub Actions workflow

```yaml
# .github/workflows/eval.yml
name: Prompt Eval
on:
  pull_request:
    paths:
      - 'backend/config/prompts/**'
      - 'backend/app/services/llm/**'
      - 'backend/app/services/onboarding/orchestrator.rb'
      - 'backend/test/eval/**'

jobs:
  eval:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports: ['5432:5432']
      redis:
        image: redis:7
        ports: ['6379:6379']
    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/credal_test
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
      LANGSMITH_API_KEY: ${{ secrets.LANGSMITH_API_KEY }}
      EVAL_PASS_THRESHOLD: ${{ vars.EVAL_PASS_THRESHOLD || '85' }}
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
          working-directory: backend
      - name: Setup DB
        run: cd backend && bundle exec rails db:create db:schema:load
      - name: Run evals
        run: cd backend && bundle exec rails eval:ci
      - name: Comment on PR
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = JSON.parse(fs.readFileSync('backend/tmp/eval_report.json'));
            const body = `## Eval Results\n- Pass rate: ${report.pass_rate}%\n- Passed: ${report.passed}/${report.total}\n- Cost: $${report.total_cost}\n${report.pass_rate < process.env.EVAL_PASS_THRESHOLD ? '**BELOW THRESHOLD**' : 'Threshold met.'}`;
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body
            });
```

### Enhanced rake task

```ruby
# lib/tasks/eval.rake (additions)
namespace :eval do
  desc "Run evals for CI with threshold check"
  task ci: :environment do
    report = Eval::Runner.run_all(tag: "ci")
    File.write("tmp/eval_report.json", report.to_json)

    threshold = (ENV["EVAL_PASS_THRESHOLD"] || 85).to_i
    if report[:pass_rate] < threshold
      $stderr.puts "FAIL: Pass rate #{report[:pass_rate]}% < threshold #{threshold}%"
      exit 1
    else
      puts "PASS: Pass rate #{report[:pass_rate]}% >= threshold #{threshold}%"
    end
  end
end
```

### New files

| File | Purpose |
|------|---------|
| `.github/workflows/eval.yml` | CI workflow for prompt regression testing |
| `config/ci/eval_config.yml` | Configurable thresholds and limits |
| `docs/ops/ci-eval.md` | Documentation for CI eval process |

### Modified files

| File | Changes |
|------|---------|
| `lib/tasks/eval.rake` | Add `eval:ci` task with threshold check and JSON output |
| `.env.example` | Add `EVAL_PASS_THRESHOLD` |

---

## Files You Should READ Before Coding

1. `lib/tasks/eval.rake` — existing eval task (from P5-001)
2. `app/services/eval/runner.rb` — runner interface
3. `app/services/eval/report.rb` — report format (must include `pass_rate`, `passed`, `total`)
4. `.github/workflows/` — any existing CI workflows for consistency
5. `backend/Gemfile` — CI dependencies

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P5-005 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P5-005-ci-eval
```

---

## Out of Scope for P5-005

- Automatic prompt tuning on failure
- Eval result history dashboard (P5-004 may show latest)
- Running evals on every commit (only on prompt/LLM changes)
- Caching eval results across runs
