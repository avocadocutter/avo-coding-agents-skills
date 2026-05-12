# GitHub Repo Checklist

Reference for the github-ready skill. Loaded on-demand during Phase 3.

---

## Secret scan patterns

Run these against the full git history:

```bash
# Credential assignments in any committed file
git grep -i -E "(password|secret|api_key|apikey|token|private_key|access_key|auth_token)\s*=" --all HEAD

# High-entropy strings that look like keys (rough heuristic)
git grep -E "['\"][A-Za-z0-9+/]{40,}['\"]" --all HEAD

# AWS-style keys
git grep -E "AKIA[0-9A-Z]{16}" --all HEAD

# Private key headers
git grep "BEGIN RSA PRIVATE KEY\|BEGIN EC PRIVATE KEY\|BEGIN OPENSSH PRIVATE KEY" --all HEAD

# Deleted env files (may have contained secrets before deletion)
git log --all --diff-filter=D --name-only --pretty=format: | grep -i "\.env" | sort -u

# Show content of a deleted file from a specific commit
git show <commit>:<path>
```

**How to interpret results:**

Filter out safe matches before alarming the user:
- `process.env.SECRET` — referencing an env var, not a value
- `os.environ.get("KEY")` — same
- `config.secret` — same
- Lines in `.example` files — example values, not real
- Comments (`//`, `#`) — documentation, not credentials
- Variable declarations with no value (`const API_KEY = ""`)

Only flag lines where a real value appears after the `=`.

---

## If a real secret is found in history

Do not minimize. Tell the user exactly:

1. What was found (credential type, approximate value if safe to show)
2. Where it was found (file path, commit hash, commit date)
3. What they must do immediately: **rotate the credential** — invalidate it at the provider before anything else. Publishing history rewrite comes second.
4. Options for history cleanup:
   - `git filter-repo --path <file> --invert-paths` — removes the file from all history (requires `git filter-repo` installed)
   - BFG Repo Cleaner — alternative tool, faster on large repos
   - Force-push the rewritten history — will break all existing clones

Never proceed with GitHub publishing until the credential is rotated.

---

## .gitignore — common gaps by project type

### Universal (add to every repo)
```
.DS_Store
Thumbs.db
*.log
*.pem
*.key
*.p12
*.pfx
.env
.env.local
.env.*.local
```

### Node.js / JavaScript
```
node_modules/
dist/
.turbo/
.next/
.vite/
coverage/
```

### Python
```
__pycache__/
*.pyc
.venv/
venv/
.pytest_cache/
```

### AI tool configs (keep local, don't commit)
```
.claude/
.cursor/
.mcp.json
```

### dotenvx encrypted files
```
# Only ignore if you're not committing encrypted env files intentionally
.env.keys
```

---

## LICENSE templates

### MIT (recommended for most open source)
```
MIT License

Copyright (c) [year] [author name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Apache 2.0
Use when you want explicit patent protection. Retrieve from https://www.apache.org/licenses/LICENSE-2.0.txt

### No license / private
Do not create a LICENSE file. Add a note in the README: "This source is available for reference. No license is granted for reuse."

---

## SECURITY.md minimal template

```markdown
# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability, please do not open a public issue.

Email [your contact] with:
- A description of the vulnerability
- Steps to reproduce
- The potential impact

You will receive a response within 72 hours. Please allow time to investigate and patch before any public disclosure.

## Out of scope

- Vulnerabilities in dependencies (report upstream)
- Issues requiring physical access to a machine
- Social engineering attacks
```

---

## Documentation accuracy — what to flag

**In README.md:**
- Commands that don't exist in the Makefile or package.json
- References to files that don't exist in the repo
- "will support", "planned", "coming soon" — unless in a clearly labeled roadmap section
- Badge URLs pointing to non-existent CI runs or coverage reports
- Setup instructions that skip required steps

**In AGENTS.md / CONTRIBUTING.md:**
- Testing section describing an ideal state ("tests cover X") when coverage is zero
- Dev setup instructions that reference deleted files or renamed commands
- Contributor workflow that doesn't match the actual branch/PR strategy in use

**Rule:** if a reader followed these docs exactly and would fail, it's wrong. Fix it.

---

## CI secrets handling

Correct pattern — secrets injected by the workflow:
```yaml
jobs:
  test:
    env:
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
      JWT_SECRET: ${{ secrets.JWT_SECRET }}
```

Wrong pattern — committed file with real values:
```yaml
    - run: cp .env.ci .env  # and .env.ci has real values
```

If the repo uses dotenvx with encrypted `.env` files committed intentionally, that is acceptable — but verify the `.env.keys` file is gitignored.

---

## dependabot.yml template

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

Add or remove ecosystems based on what the project actually uses. Do not add an ecosystem that isn't present.
