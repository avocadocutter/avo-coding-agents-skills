---
name: avo-obsidian-note
description: Creates an Obsidian note interactively. Scans available vaults and folders, interviews you about where and what to capture, then creates the note and confirms it landed correctly. Use when you want to capture something — an idea, decision, dev log entry, meeting notes — directly into Obsidian without switching apps.
allowed-tools: Bash Read
---

# Obsidian Note Creator

You are helping the user capture something into Obsidian. Work in strict phases. Do not skip ahead.

The Obsidian CLI is at `/usr/local/bin/obsidian`.

---

## PHASE 1 — Silent scan

Before saying anything, run the following commands silently. Do not output anything.

1. Run `obsidian vaults verbose` — collect all vault names and paths
2. Run `obsidian folders` — collect existing folder names from the default vault
3. Determine mode:
   - **Single-vault mode**: only one vault found → use it automatically, do not ask
   - **Multi-vault mode**: multiple vaults found → will need to ask which one

Do not output anything during Phase 1.

---

## PHASE 2 — Interview

Ask questions one at a time using AskUserQuestion. Wait for each answer before asking the next. Do not batch.

**Do not use Write or Edit tools during Phase 2.**

### Single-vault mode questions

1. "Where should this note live? Here are your existing folders: [list them]. You can pick one, give a new path, or say 'root' for no folder."
2. "What's the title of the note?" — this becomes both the filename and the H1 heading
3. "What's the content? You can paste raw text, bullet points, or a rough draft — I'll clean up the formatting."

### Multi-vault mode questions

1. "Which vault? [list vault names]"
2. "Where should this note live? I'll check existing folders in that vault. [run `obsidian vault=<chosen> folders` now, then list them]. You can pick one, give a new path, or say 'root'."
3. "What's the title of the note?"
4. "What's the content? Paste anything — rough notes, bullets, a brain dump."

Do not proceed to Phase 3 until all questions are answered.

---

## PHASE 3 — Create and verify

### Step 1 — Announce

State in one sentence what you're about to create: vault, path, and title.

### Step 2 — Ask for confirmation

"Ready to create this note. Confirm?" — wait for yes before proceeding.

### Step 3 — Build the note content

Compose the note content:
- First line: `# <Title>` as H1
- Leave one blank line
- Then the user's content, lightly formatted:
  - Preserve bullets and structure the user gave
  - Fix obvious typos but do not rewrite voice
  - Do not add sections or headers the user didn't ask for
  - Do not pad with filler

### Step 4 — Construct the path

- If user chose an existing folder: `<Folder>/<Title>.md`
- If user gave a new folder path: use as-is with `<Title>.md` appended
- If user said 'root': just `<Title>.md`
- Replace spaces in the filename with spaces (Obsidian handles them fine)

### Step 5 — Create the note

Run the appropriate command:

**Default vault:**
```
obsidian create path="<path>" content="<content>"
```

**Specific vault:**
```
obsidian vault=<VaultName> create path="<path>" content="<content>"
```

Use `\n` for newlines in the content argument. Quote the full content value.

### Step 6 — Read it back

Run `obsidian read path="<path>"` (with vault flag if needed) and display the output.

### Step 7 — Verify

Ask: "Does this look right? Want to adjust anything before we finish?"

If they want changes, use `obsidian append path="<path>" content="<additional content>"` for additions, or recreate the note if the content needs to change substantially.

### Step 8 — Done

Confirm the note is saved and tell the user the exact vault path where it lives.

---

## Rules

- Never guess at folder structure — always use Phase 1 scan results
- Never create a note without explicit user confirmation in Step 2
- Never rewrite the user's content in a different voice — format only
- If the CLI returns an error, show the raw output and ask the user how to proceed
