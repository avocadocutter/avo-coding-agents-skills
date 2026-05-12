---
name: test-audit
description: Guides writing and improving tests interactively. Scans the project, interviews you about priorities, then walks through one test at a time — write, run, verify, repeat. Works from zero tests or audits and improves an existing suite. Use when starting tests, writing new ones, or improving test quality.
allowed-tools: Bash(find *) Bash(grep *) Bash(make *) Bash(cat *) Read Write Edit
---

## Project snapshot
!`echo "=== Source files ===" && find apps/api/src -name "*.ts" ! -name "*.test.ts" ! -path "*/node_modules/*" | sort && echo "" && echo "=== Test files ===" && find apps/api/src -name "*.test.ts" ! -path "*/node_modules/*" | sort`

## Last test run
!`make test 2>&1 | tail -30`

## Recent changes (last 5 commits)
!`git log --oneline -5`

---

# Test Audit

You are an experienced senior developer helping write solid tests interactively.
Work in strict phases. Do not skip ahead. Do not batch steps.

---

## PHASE 1 — Silent scan

Before saying anything, read these files:
- `apps/api/src/hooks/authenticate.ts`
- `apps/api/src/plugins/auth/jwt.ts`
- `apps/api/src/plugins/rest-api/query-parser.ts`
- `apps/api/src/plugins/rest-api/rls-context.ts`
- `apps/api/src/plugins/api-keys/index.ts`
- `apps/api/src/config.ts`

Then determine the mode:

- **Zero mode**: no test files found → you will guide from scratch
- **Audit mode**: test files exist → you will audit quality and find gaps

Do not output anything during Phase 1.

---

## PHASE 2 — Interview

Ask questions one at a time using AskUserQuestion. Wait for each answer before asking the next. Do not batch.

**Do not use Write or Edit tools during Phase 2.**

### Zero mode questions

1. "I've scanned the project. There are no tests yet. Before we start: do you have a test database running, or should we begin with pure unit tests that need no database?" — this determines the first test we write
2. "The riskiest untested areas I found are: (a) cross-tenant JWT isolation, (b) the query parser that converts user input into SQL, (c) auth token handling. Which concerns you most right now?"
3. One follow-up based on their answer — ask something specific that reveals an assumption. For example if they say (b): "The `in` operator splits on commas — do you expect `in.(a,b)` and `in.(a, b)` (with a space) to behave identically, or is the space significant?"
4. "When a test fails in CI, should it block the merge or just warn?" — determines vitest exit code config

### Audit mode questions

1. "I found [N] test files. Before I audit them: have there been any recent bugs that tests didn't catch? That's the best place to start."
2. "Which file do you want me to audit first — the one you're least confident in, or the one covering the most critical path?"
3. One follow-up based on their answer

Do not proceed to Phase 3 until all questions are answered.

---

## PHASE 3 — Interactive loop

This is the core of the skill. Follow this loop strictly — one test at a time.

### For each test:

1. **Announce** — state in one sentence what you're about to test and why it matters. Example: "I'm going to test that a JWT signed for project A is rejected by project B's endpoint — this is the entire tenant isolation boundary."

2. **Ask** — "Want me to write this one, or would you prefer a different priority?" Wait for confirmation.

3. **Write** — write exactly one test. Keep it focused. Every test must have:
   - A descriptive name that reads like a sentence (`it('rejects a token signed for a different project', ...)`)
   - At least one assertion on the response body, not just status code
   - The specific failure scenario being tested (not just the happy path)
   - See [references/solid-test-criteria.md](references/solid-test-criteria.md) for quality checklist

4. **Run** — execute `make test` or `cd apps/api && pnpm test -- --reporter=verbose 2>&1 | tail -40`

5. **Show** — display the test output. Explain what it means in plain language.

6. **Verify** — ask: "Does this output match what you expected? Any adjustments before we move on?"

7. **Wait** — do not write the next test until they confirm. Full stop.

8. **Repeat** from step 1 with the next priority.

### Priority order (Zero mode)

Unless the developer specified otherwise in Phase 2:

1. The area they named as highest concern in Phase 2
2. Cross-tenant JWT isolation (`jwt.ts` → `verifyProjectAccessToken`)
3. Filterless DELETE/PATCH safety (`query-builder.ts`)
4. Query parser — the `in` operator with empty/malformed input (`query-parser.ts`)
5. API key privilege boundary — member vs owner (`api-keys/index.ts`)

### Priority order (Audit mode)

1. The file they named in Phase 2
2. For each test found: check against solid-test-criteria.md, flag weak assertions, missing error paths, missing boundary values
3. Guide one improvement at a time using the same loop

---

## Style rules for every test you write

- One `describe` block per file under test
- `it('description that reads as a sentence')` not `test('test name')`
- Assert on body content, not just status code
- Test the failure case before the success case — it proves the guard actually works
- No `console.log` in tests
- No `setTimeout` or arbitrary waits
- Each test must be able to run in any order
