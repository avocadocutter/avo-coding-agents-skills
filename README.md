# coding-agents-skills

Installable skills for Claude Code and Cursor. Each skill guides an AI through a structured task — reading first, asking before acting, verifying each step.

## Why this exists

Most AI coding prompts fail the same way: the model makes assumptions, produces a wall of output, and looks plausible while missing the point. These skills fix that with three phases — silent scan, interview, interactive loop — so the AI reads first, asks before acting, and handles one thing at a time with your confirmation at each step. See `SKILL-DESIGN.md` for the full design guide.

> **Early days.** This is a first iteration — more skills are planned. Contributions welcome: new skills, fixes, feedback.

## Install

```bash
npx skills@latest add avocadocutter/coding-agents-skills
```

Pick the skills you want and which agent to install them on. **Make sure you select `/setup-avo-skills`** — run it once after installing to configure your Obsidian vault preference.

## After installing

Run `/setup-avo-skills` in Claude Code. It will:
- Check the Obsidian CLI is installed
- If you have multiple Obsidian vaults, ask which one `/avo-obsidian-note` should use by default
- Save the preference to `~/.config/avo-skills/config.json`

## Available skills

### Engineering

#### `setup-avo-skills`
First-time setup. Configures the Obsidian vault preference used by `/avo-obsidian-note`. Run once per machine after installing.

#### `avo-test-audit`
Guides writing and improving tests interactively. Scans the project, interviews you about priorities, then walks through one test at a time — write, run, verify, repeat. Works from zero tests or audits an existing suite.

#### `avo-github-ready`
Guides making a repo safe and ready to publish on GitHub. Detects the tech stack, scans for secrets, audits `.gitignore`, checks standard files, and walks through each fix one at a time with verification.

#### `avo-github-audit`
Full security and hygiene audit for any GitHub repository. Covers branch protection, Actions security, secret scanning, dependency alerts, access control, and community health files.

### Productivity

#### `avo-obsidian-note`
Creates an Obsidian note interactively. Scans available vaults and folders, interviews you about where and what to capture, then creates the note and confirms it landed. Use when you want to capture something directly into Obsidian without switching apps.

## Local development

To link all skills to `~/.claude/skills/` so edits take effect immediately without reinstalling:

```bash
./scripts/link-skills.sh
```

## License

MIT — see [LICENSE](LICENSE).
