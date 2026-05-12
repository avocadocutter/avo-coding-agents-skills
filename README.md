# coding-agents-skills

Installable skills for Claude Code and Cursor. Each skill guides an AI through a structured task — reading first, asking before acting, verifying each step.

## Why this exists

Most AI coding prompts fail the same way: the model makes assumptions, produces a wall of output, and looks plausible while missing the point. These skills fix that with three phases — silent scan, interview, interactive loop — so the AI reads first, asks before acting, and handles one thing at a time with your confirmation at each step. See `SKILL-DESIGN.md` for the full design guide.

> **Early days.** This is a first iteration — more skills and agents are planned. Contributions very welcome: new skills, fixes, feedback.

## Install

```bash
./install.sh <skill-name> <claude|cursor> [project-path]
```

Defaults to the current directory if no project path is given.

```bash
# Install into a specific project
./install.sh avo-test-audit claude ~/projects/my-app

# Install into the current directory
./install.sh avo-github-ready claude
```

## Uninstall

```bash
./uninstall.sh <skill-name> <claude|cursor> [project-path]
```

Prompts for confirmation before removing.

## Available skills

### `avo-test-audit`
Guides writing and improving tests interactively. Scans the project, interviews you about priorities, then walks through one test at a time — write, run, verify, repeat. Works from zero tests or audits an existing suite.

### `avo-github-ready`
Guides making a repo safe and ready to publish on GitHub. Scans for secrets, audits `.gitignore` gaps, checks standard files (LICENSE, SECURITY.md, README), and walks through each fix one at a time with verification.

## License

MIT — see [LICENSE](LICENSE).
