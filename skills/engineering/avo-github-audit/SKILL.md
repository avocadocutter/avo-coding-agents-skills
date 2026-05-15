---
name: avo-github-audit
description: Full security and hygiene audit for any GitHub repository. Covers branch protection, GitHub Actions security, secret scanning, dependency alerts, access control, repository settings, and community health files. Uses only gh CLI and local file inspection — no external tools required. Language-agnostic. Requires an existing GitHub remote.
allowed-tools: Bash Read Write Edit WebSearch
---

# GitHub Audit

You are a senior security engineer auditing a GitHub repository's security posture and hygiene.
Work in strict phases. Do not skip ahead. Do not batch steps.

---

## PHASE 0 — Silent fingerprint

Before saying anything, establish repo context. Do not output anything.

**Verify a GitHub remote exists:**
- Run `git remote -v`
- If no remote exists: stop and tell the user: "avo-github-audit requires an existing GitHub remote. For local or pre-publish repos, use `/avo-github-ready` instead." Do not continue.
- Extract `{owner}` and `{repo}` from the remote URL (handle both HTTPS and SSH formats)

**Verify gh CLI auth:**
- Run `gh auth status`
- If auth fails: stop and tell the user to run `gh auth login` first. Do not continue.

**Collect repo profile (run silently):**
```
gh repo view {owner}/{repo} --json name,visibility,defaultBranchRef,isPrivate,isFork,hasWikiEnabled,hasIssuesEnabled,hasDiscussionsEnabled,hasPages,allowForking,isArchived
```

**Check local file presence (no output):**
- Does `.github/` exist?
- Does `.github/workflows/` exist and contain `.yml` or `.yaml` files?
- Does `.github/CODEOWNERS` or `CODEOWNERS` exist?
- Does `SECURITY.md` or `.github/SECURITY.md` exist?
- Does `.github/dependabot.yml` exist?
- Does `.github/ISSUE_TEMPLATE/` exist?
- Does `.github/pull_request_template.md` exist?
- Does `CONTRIBUTING.md` or `.github/CONTRIBUTING.md` exist?

Record all of this as the **repo profile**. It drives what to scan in Phase 1, what to ask in Phase 2, and what to skip in Phase 4.

---

## PHASE 1 — Silent API scan

Run all checks silently. Record findings for Phase 4. Do not re-run checks in Phase 4 — report Phase 1 results.

**Do not output anything during Phase 1.**

### Branch protection and rulesets

```bash
gh api repos/{owner}/{repo}/branches/{default_branch}/protection 2>/dev/null
gh api repos/{owner}/{repo}/rulesets 2>/dev/null
```

Record for each: required PR reviews (count), dismiss_stale_reviews, require_code_owner_reviews, required_status_checks, enforce_admins, allow_force_pushes, required_signatures, allow_deletions. Note if no protection exists at all.

### GitHub Actions security

For each `.github/workflows/*.yml` file, read it locally. Detect:

1. **Dangerous pattern** — any workflow using `on: pull_request_target` combined with `actions/checkout` that checks out PR head code (missing `ref:` pointing to base, or explicitly using `github.event.pull_request.head.sha` or `head.ref`)
2. **Unpinned actions** — any `uses:` line referencing a mutable tag (`@v1`, `@v2`, `@main`, `@master`, `@latest`, `@develop`) instead of a full 40-character commit SHA
3. **Missing permissions block** — any workflow or job with no `permissions:` key, or with `permissions: write-all`
4. **Script injection** — any `run:` step that directly interpolates `${{ github.event.` variables without assigning to an env var first
5. **Secrets passed to third-party actions** — any step using `secrets: inherit` or passing `secrets.*` as input to an action not owned by `actions/`, `github/`, or the repo owner

Count totals per category.

### Secret scanning and push protection

```bash
gh api repos/{owner}/{repo} --jq '.security_and_analysis' 2>/dev/null
gh api repos/{owner}/{repo}/secret-scanning/alerts --jq '[.[] | select(.state=="open")] | length' 2>/dev/null
```

Record: secret_scanning status, secret_scanning_push_protection status, advanced_security status, open alert count.

### Dependabot and dependency security

```bash
gh api repos/{owner}/{repo}/vulnerability-alerts 2>/dev/null  # 204 = enabled, 404 = disabled
gh api repos/{owner}/{repo}/dependabot/alerts --jq '[.[] | select(.state=="open")] | {total: length, critical: [.[] | select(.security_advisory.severity=="critical")] | length, high: [.[] | select(.security_advisory.severity=="high")] | length}' 2>/dev/null
```

Record: alerts enabled (yes/no), open alert count by severity, dependabot.yml present (from Phase 0).

### Access control

```bash
gh api repos/{owner}/{repo}/collaborators --jq '[.[] | select(.permissions.admin == true) | .login]' 2>/dev/null
gh api repos/{owner}/{repo}/collaborators?affiliation=outside --jq '[.[] | {login, permissions}]' 2>/dev/null
gh api repos/{owner}/{repo}/keys --jq '[.[] | {id, title, read_only, verified, created_at}]' 2>/dev/null
gh api repos/{owner}/{repo}/hooks --jq '[.[] | {id, active, events, url: .config.url, insecure_ssl: .config.insecure_ssl, has_secret: (.config.secret != null and .config.secret != "")}]' 2>/dev/null
```

Record: admin count, outside collaborators with write or admin, deploy keys (especially `read_only: false`), webhooks without secrets or using `insecure_ssl: "1"`.

### Code scanning

```bash
gh api repos/{owner}/{repo}/code-scanning/alerts --jq '[.[] | select(.state=="open")] | length' 2>/dev/null
```

Also check locally whether any CodeQL, Semgrep, Snyk, or SonarCloud action exists in workflow files.

### Private vulnerability reporting

```bash
gh api repos/{owner}/{repo} --jq '.private_vulnerability_reporting_enabled' 2>/dev/null
```

### Release hygiene (quick scan)

```bash
gh release list 2>/dev/null | head -5
find . -maxdepth 2 -iname "*changelog*" -o -iname "*history*" 2>/dev/null | head -3
```

Record: has any releases, has CHANGELOG.

---

## PHASE 2 — Interview

Ask questions one at a time using AskUserQuestion. Wait for each answer before asking the next. Do not batch.

**Do not use Write or Edit tools during Phase 2.**

### Question 1 — Audit driver

Ask: "I've finished scanning the repo. What's driving this audit?"

Options:
- Going public / open sourcing this repo
- Security incident or specific concern
- Team onboarding / new process
- Routine health check
- CI/CD pipeline hardening

### Question 2 — Scope

Ask: "How do you want to work through this — full audit top to bottom, or focus on a specific area first?"

Options:
- Full audit (all findings by priority)
- Security-first (branch protection, secrets, Actions, access control)
- CI/CD hygiene (Actions security, workflow health, Dependabot)
- Quick wins (fixes under 5 minutes, skip architectural changes)

### Question 3 — Research

Ask: "Want me to do a live web search for recent GitHub security incidents, latest CVE advisories for the Actions you're using, and current best practices? Takes a moment but surfaces things a static checklist misses."

Options:
- Yes, run the research
- No, use the baseline checks

### Question 4 — Contextual follow-up

Ask one follow-up based on the audit driver from Question 1:
- "Going public": "Has this repo ever had real credentials or API keys committed — even briefly, even in a branch?"
- "Security incident": "Do you have a sense of which surface was the likely vector — CI/CD, repository access, or committed code?"
- "Team onboarding": "Is this the first time this repo has been audited, or are there known gaps you want to close?"
- "Routine health check": "Any area you've been putting off or that's felt risky lately?"
- "CI/CD hardening": "Are you running any self-hosted runners, or all GitHub-hosted?"

Do not proceed to Phase 3 until all questions are answered.

---

## PHASE 3 — Research (conditional)

**Only run if the user opted in during Question 3.**

Run targeted WebSearch queries based on Phase 1 findings and the repo profile:

1. If unpinned third-party actions were found: `"{action-name} github action security advisory CVE 2024 2025"` for each unique non-GitHub-owned action
2. `"github actions supply chain attack 2024 2025"` — recent incidents that reveal new attack patterns
3. `"github repository security best practices {current_year}"` — extract anything not covered by the baseline checklist
4. If the repo is public: `"open source github repository security hardening"` — community-specific risks

Extract only confirmed issues and concrete new checks. Discard generic advice already in Phase 4's checklist.
Record findings as **research flags** to inject into Phase 4 after the relevant tier items.

Do not output research findings — use them to augment Phase 4.

---

## PHASE 4 — Interactive loop

Work through findings one at a time in priority order. Follow this loop strictly for every finding.

### For each finding:

1. **Announce** — one sentence: what the gap is and the specific risk it creates. Name the exact file, setting, or API field.
2. **Ask** — "Want me to fix this now, or skip to the next finding?" Wait for confirmation. Full stop.
3. **Do** — exactly one fix. Show the exact command or diff before executing.
4. **Show** — display the result. Explain in plain language what changed and what it now prevents.
5. **Verify** — ask: "Does this look right? Anything to adjust before we move on?"
6. **Wait** — do not move on until confirmed. Full stop.
7. **Repeat** from step 1.

If a fix requires GitHub org admin scope or the GitHub UI (some settings can't be changed via API without elevated access): state what the setting does, give the exact UI path or URL, and move on — do not block.

If an API call returns a permission error: note it, explain what scope is needed (`gh auth refresh -s repo` or org admin), and continue.

Do not batch. If 6 workflows have unpinned actions, fix one, verify, then ask to continue to the next.

---

### Priority order

#### Tier 1 — Critical

**1. Dangerous workflow pattern (pull_request_target + checkout)**
Any workflow combining `on: pull_request_target` with `actions/checkout` that checks out PR head code. This is the most exploited GitHub Actions vulnerability — an external contributor can exfiltrate all repo secrets or run arbitrary code in your CI runner.
Fix: see fix patterns in [references/github-audit-checks.md](references/github-audit-checks.md).

**2. Unpinned third-party Actions**
Any `uses:` line using a mutable tag. A compromised action maintainer can push malicious code to `@v3` and it silently runs in your pipeline the next build.
Fix: replace each tag with its resolved 40-char commit SHA. Use `gh api repos/{action-owner}/{action-repo}/git/ref/tags/{tag}` to resolve. See [references/github-audit-checks.md](references/github-audit-checks.md) for the exact command.
Work through unpinned actions one workflow file at a time.

**3. No branch protection on default branch**
If Phase 1 found no protection rules or rulesets at all, direct commits to main are unrestricted — no review, no CI gate, no history audit trail.
Fix: create a baseline ruleset using the template in [references/github-audit-checks.md](references/github-audit-checks.md).

**4. Secret scanning disabled**
If `secret_scanning.status` is not `"enabled"`, hardcoded credentials pushed to this repo are not detected.
Fix: `gh api repos/{owner}/{repo} --method PATCH -f 'security_and_analysis[secret_scanning][status]=enabled'`

**5. Open secret scanning alerts**
If any open alerts exist from Phase 1: report type and count. Do not minimize. A found secret is an active exposure — the credential must be rotated before anything else. Do not move past this item until the user confirms the credential has been or will be rotated.

---

#### Tier 2 — High

**6. GITHUB_TOKEN over-permissioned**
Workflows without an explicit `permissions:` block inherit the organization default, which may be `write-all` for orgs created before Feb 2023. A compromised action has full write access to the repo.
Fix: add a minimal `permissions:` block to each affected workflow. See templates in [references/github-audit-checks.md](references/github-audit-checks.md). One workflow file per loop iteration.

**7. Branch protection gaps**
For each missing rule found in Phase 1 — surface one gap at a time:
- Dismiss stale reviews not enabled: an attacker approves a PR, then the author pushes malicious code — approval stays.
- Force push allowed: history can be rewritten on main without trace.
- Required status checks missing: CI can be bypassed entirely.
- Admin enforcement off: admins can bypass all rules.
Fix each gap via `gh api repos/{owner}/{repo}/branches/{branch}/protection --method PUT` with corrected payload, or update the ruleset.

**8. Push protection disabled**
If secret scanning is on but push protection is off, secrets are detected after the fact — not blocked at push time.
Fix: `gh api repos/{owner}/{repo} --method PATCH -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'`

**9. Dependabot alerts not enabled**
Known CVEs in dependencies go undetected.
Fix: `gh api repos/{owner}/{repo}/vulnerability-alerts --method PUT`

**10. Open Dependabot alerts (critical/high severity)**
Report count by severity. For critical-severity alerts: name the package and CVE. User must decide whether to take action before continuing.

**11. Missing Dependabot config**
If no `.github/dependabot.yml` exists, Dependabot alerts fire but no automated PRs are opened to fix them.
Fix: create `.github/dependabot.yml` using the starter template in [references/github-audit-checks.md](references/github-audit-checks.md), including `github-actions` ecosystem and any package manager files found in the repo.

**12. Outside collaborators with write or admin access**
Report names and access levels. Each outside collaborator with write+ access is a potential insider threat surface.
Fix: guide downgrade to read-only or removal. For org repos this requires the GitHub UI: `github.com/orgs/{org}/people/outside_collaborators`.

**13. Deploy keys with write access**
Any `read_only: false` deploy key. Write deploy keys are rarely needed and frequently forgotten.
Fix: `gh api repos/{owner}/{repo}/keys/{id} --method DELETE` — confirm the key isn't actively used in CI before deleting.

**14. Webhooks without secrets or using HTTP**
Webhooks without a secret can be spoofed by any third party. HTTP webhooks expose payloads in transit.
Fix: for each affected webhook, walk through adding a secret and switching `url` to HTTPS. GitHub UI path: Settings → Webhooks → Edit.

**15. No code scanning**
If no CodeQL or equivalent SAST tool is running, vulnerabilities in the codebase go undetected.
Fix: offer to create `.github/workflows/codeql.yml`. Use the pinned-SHA template from [references/github-audit-checks.md](references/github-audit-checks.md). Resolve current action SHAs before writing.

---

#### Tier 3 — Medium

**16. Script injection risk**
Any `run:` step directly interpolating `${{ github.event.` variables is injectable via a malicious PR title, body, or branch name.
Fix: move the interpolation to an `env:` block and reference the env var in shell. See fix pattern in [references/github-audit-checks.md](references/github-audit-checks.md).

**17. Missing SECURITY.md**
Security researchers have no clear path for responsible disclosure. GitHub won't show the "Report a vulnerability" button without this file.
Fix: create `.github/SECURITY.md` using the template in [references/github-audit-checks.md](references/github-audit-checks.md).

**18. Private vulnerability reporting not enabled**
Researchers cannot submit confidential reports via GitHub's built-in advisory system.
Fix: `gh api repos/{owner}/{repo} --method PATCH -f 'private_vulnerability_reporting_enabled=true'`

**19. CODEOWNERS missing or not covering critical paths**
Without CODEOWNERS, workflow files and security config can be changed without routing to a specific reviewer.
Fix: create or update `.github/CODEOWNERS`. At minimum: own `.github/workflows/`, `.github/CODEOWNERS` itself, and root config files. See template in [references/github-audit-checks.md](references/github-audit-checks.md).

**20. Secrets passed to untrusted third-party actions**
Any step passing `secrets.*` or using `secrets: inherit` to an action not owned by `actions/`, `github/`, or the repo owner.
Fix: remove the secret injection or replace the third-party action with a safer alternative.

---

#### Tier 4 — Polish (only if user chose "full audit" or "quick wins" scope)

**21. Missing community health files**
Check for: `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`. Missing files reduce contribution quality and issue signal.
Fix: create one at a time, starting with whatever the user considers most valuable.

**22. Release hygiene**
If releases exist but no CHANGELOG is present: maintainers can't communicate what changed to users.
Surface the gap, discuss whether a CHANGELOG or GitHub release notes are the right format, and offer to create a starter `CHANGELOG.md`.

**23. CI/CD workflow hygiene**
Surface any of: workflows with no `timeout-minutes` (can hang for 6 hours), duplicate workflows with overlapping triggers, workflows with no concurrency controls (parallel runs can clobber deployments). One workflow issue per loop iteration.

---

### Adjusting priority order from Phase 2:

- **Security-first**: stop after Tier 2 item 15. Skip Tiers 3–4.
- **CI/CD hygiene**: start at item 6 (GITHUB_TOKEN), skip items 12–15, include Tier 3 item 16, skip Tier 4 item 21–22.
- **Quick wins**: skip items that require git history rewrite, org admin access, or architectural decisions. Note them as "requires elevated access" and move on.
- **Going public** (from Question 1): after Tier 1 item 5, run: `git log --all --oneline -S 'password\|secret\|api_key\|token\|credential' 2>/dev/null | wc -l` — if non-zero, surface count and discuss before proceeding.

---

## Rules for every fix

- One file or one API call per loop iteration — never batch
- Show the exact command or diff before executing
- For API calls that change security settings: state the before and after values explicitly
- Never rewrite git history without explicit user confirmation and a full explanation of consequences
- For org-admin-only settings: explain what the setting does, give the exact UI path, and move on
- If a secret is found: do not minimize. State clearly what was found and that the credential must be rotated immediately, regardless of whether the repo is public or private
- Do not apply Tier 4 fixes unless the user explicitly chose "full audit" or asks for them
