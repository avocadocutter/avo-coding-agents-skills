# coding-agents-skills

[![skills.sh](https://skills.sh/b/avocadocutter/avo-coding-agents-skills)](https://skills.sh/avocadocutter/avo-coding-agents-skills)

Installable skills for Claude Code and Cursor. Each skill guides an AI through a structured task — reading first, asking before acting, verifying each step.

## Why this exists

Most AI coding prompts fail the same way: the model makes assumptions, produces a wall of output, and looks plausible while missing the point. These skills fix that with three phases — silent scan, interview, interactive loop — so the AI reads first, asks before acting, and handles one thing at a time with your confirmation at each step. See `SKILL-DESIGN.md` for the full design guide.

> **Early days.** More skills are planned. Contributions welcome: new skills, fixes, feedback.

## Install

```bash
npx skills@latest add avocadocutter/avo-coding-agents-skills
```

Select the skills you want and which agent to install them on. Run this from a project directory, not the skills repo itself.

> **Heads up:** The CLI always writes a copy to `.agents/skills/` in the current directory (universal agent support). Add `.agents/` to your `.gitignore` if you don't want it committed.

After installing, run `/setup-avo-skills` in Claude Code once to finish setup.

## Available skills

### Engineering

#### `setup-avo-skills`
First-time setup. Checks the Obsidian CLI is installed and saves your preferred vault to `~/.config/avo-skills/config.json` so `/avo-obsidian-note` skips the vault question on every run. Run once per machine.

#### `avo-test-audit`
Guides writing and improving tests interactively. Scans the project, interviews you about priorities, then walks through one test at a time — write, run, verify, repeat. Works from zero tests or audits an existing suite.

#### `avo-github-ready`
Guides making a repo safe and ready to publish on GitHub. Detects the tech stack, scans for secrets, audits `.gitignore`, checks standard files, and walks through each fix one at a time with verification.

#### `avo-github-audit`
Full security and hygiene audit for any GitHub repository. Covers branch protection, Actions security, secret scanning, dependency alerts, access control, and community health files. Requires an existing GitHub remote.

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
