---
name: setup-avo-skills
description: First-time setup for avo skills. Checks the Obsidian CLI is installed, discovers available vaults, and saves a preferred vault to ~/.config/avo-skills/config.json so that /avo-obsidian-note skips the vault question on every run. Run once per machine after installing avo skills.
allowed-tools: Bash Read Write
---

# Setup Avo Skills

You are setting up avo skills for first use on this machine. Work through each step once. Do not skip ahead.

---

## PHASE 1 — Silent scan

Before saying anything, run the following silently. Do not output anything.

1. Check if the Obsidian CLI is installed:
   ```bash
   which obsidian 2>/dev/null || ls /usr/local/bin/obsidian 2>/dev/null
   ```
2. Check if a config already exists:
   ```bash
   cat ~/.config/avo-skills/config.json 2>/dev/null
   ```
3. If the CLI is found, run: `obsidian vaults verbose`
   - Collect vault names and paths
   - If exactly one vault: **single-vault mode** — default vault preference is not needed
   - If multiple vaults: **multi-vault mode** — need to ask

Do not output anything during Phase 1.

---

## PHASE 2 — Report and configure

### If Obsidian CLI is not installed

Tell the user:

"The Obsidian CLI (`obsidian`) was not found. The `/avo-obsidian-note` skill requires it to create notes. Install it first, then re-run `/setup-avo-skills`."

Stop here.

### If a config already exists

Show the current config and ask:

"A config already exists at `~/.config/avo-skills/config.json`:

```
[show contents]
```

Want to update it?"

- **Yes** → continue to configure
- **No** → confirm existing setup is active and stop

### If single-vault mode (no existing config)

Tell the user:

"Found one Obsidian vault: **[vault name]** at `[path]`. No vault preference needs to be set — `/avo-obsidian-note` will use it automatically.

Setup is complete. You can run `/avo-obsidian-note` to create notes."

Stop here.

### If multi-vault mode

Ask: "Found [N] Obsidian vaults:

[list each: name → path]

Which one should `/avo-obsidian-note` use by default?"

Wait for answer. Do not proceed until answered.

---

## PHASE 3 — Write config

Create `~/.config/avo-skills/` if it does not exist:
```bash
mkdir -p ~/.config/avo-skills
```

Write `~/.config/avo-skills/config.json`:
```json
{
  "obsidian": {
    "default_vault": "<chosen vault name>"
  }
}
```

Then confirm:

"Config saved to `~/.config/avo-skills/config.json`. `/avo-obsidian-note` will now use **[vault name]** as the default vault — it won't ask which vault each time.

To change this later, re-run `/setup-avo-skills` or edit the file directly."
