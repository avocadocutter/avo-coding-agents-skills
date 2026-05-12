# Skill Design Philosophy

How to design interactive AI skills that guide rather than just execute. Everything here was distilled from building `test-audit`. Apply it when creating any new skill in this repo.

---

## The core idea: guide, don't dump

A skill is not a prompt that produces output. It is a structured conversation that produces understanding. The AI should behave like a senior developer pairing with you — reading the code first, asking before acting, verifying each step.

The failure mode of most AI prompts is: the AI reads the request, makes assumptions, produces a wall of output. The user gets something plausible-looking that doesn't match what they actually needed.

The fix: phases, gate conditions, and forced verification.

---

## Structure every skill in three phases

### Phase 1 — Silent scan

The AI reads the relevant code before saying anything. No output, no greeting, no explanation. Just reading.

Why silence? Because if the AI speaks before reading, it will make assumptions. The scan results change what questions to ask in Phase 2 and what to prioritize in Phase 3. The scan must happen first.

What to scan: the files most relevant to the skill's domain. For test-audit, that's auth, access control, input parsing, and config — the security-sensitive, highest-risk areas. For a different skill, it would be different files. Describe what to look for and how to prioritize — but don't hardcode file paths. The AI knows how to explore a project; tell it what matters, not which files to open.

Also use Phase 1 to detect the mode the skill is running in. test-audit detects Zero mode (no tests exist) vs Audit mode (tests exist). Different modes trigger different question sets in Phase 2. Design your mode detection to be binary and unambiguous.

### Phase 2 — Interview

Ask the user questions before doing any work. One question at a time. Wait for the answer before asking the next. Never batch.

The constraint that makes this work: **forbid Write and Edit tools during Phase 2.** State it explicitly in the skill file. If the AI can write code during the interview, it will — because it already "knows" what to do from Phase 1. Removing the tools forces it to ask instead.

Use `AskUserQuestion` when the tool is available. It enforces one question at a time mechanically.

Design questions that reveal assumptions, not just preferences. Weak question: "Which area do you want to test first?" Strong question: "The `in` operator splits on commas — do you expect `in.(a,b)` and `in.(a, b)` (with a space) to behave identically, or is the space significant?" The second question surfaces a decision the developer may not have thought about. That's the point.

Two to four questions is usually right. More than four and the user loses patience. Fewer than two and you haven't learned enough.

End Phase 2 with an explicit gate: "Do not proceed to Phase 3 until all questions are answered."

### Phase 3 — Interactive loop

This is where the work happens — one unit at a time. The loop:

1. **Announce** what you're about to do and why it matters — one sentence
2. **Ask** for confirmation before doing it
3. **Do** exactly one thing
4. **Run** it immediately
5. **Show** the output with a plain-language explanation
6. **Verify** — ask if it matched expectations
7. **Wait** for confirmation before moving on
8. **Repeat**

The key constraint: one unit per loop iteration. One test. One improvement. One file. Not a batch. Not "here are five tests." The verification step after each unit is what makes the skill actually useful — it catches misaligned assumptions before they compound.

State the loop steps explicitly and number them. Add "Full stop." or "Wait for confirmation before continuing." — the AI will skip the wait if you don't anchor it.

---

## Tool restrictions as behavioral guardrails

Restricting which tools are available in each phase changes how the AI behaves, not just what it can do.

If Write and Edit are available in Phase 2, the AI interprets every question as a preamble to writing code. Removing them in Phase 2 forces the AI into interview mode — it has no choice but to ask.

State tool restrictions in the phase itself, not just in the frontmatter. "Do not use Write or Edit tools during Phase 2." The frontmatter `allowed-tools` controls what's available at all; the phase-level instruction controls intent.

---

## Progressive disclosure for reference material

Keep the main skill file lean. Move quality checklists, examples, and reference tables into a `references/` subdirectory. Load them on-demand — the skill file links to them and the AI reads them when needed.

Why: a 400-line skill file gets skimmed. A 100-line skill file with clear phases gets followed. The reference material is there when the AI needs it, but it doesn't crowd the main instructions.

---

## Priority ordering is part of the skill

Every skill should have a stated priority order for Phase 3. Without it, the AI picks whatever is easiest or most prominent — not what's most important.

Design the priority order around risk, not coverage. For test-audit: cross-tenant isolation first, then filterless deletes, then query parser edge cases. The highest-stakes failure modes come first.

Let the user override the order in Phase 2 (that's what question 2 is for), but have a sensible default so Phase 3 can start without needing more input.

---

## Mode detection pattern

Most skills benefit from detecting two or more modes based on project state. test-audit uses Zero mode vs Audit mode. A migration skill might detect Empty vs Populated. A setup skill might detect Fresh vs Partially configured.

The detection happens in Phase 1 (silent). The detected mode drives different question sets in Phase 2 and different priority orders in Phase 3. This is what makes a skill feel contextually aware rather than generic.

Make mode detection explicit in the skill file: state what you're looking for, what each result means, and what changes as a result.

---

## What not to do

**Don't write a skill that just produces output.** If the skill can run to completion without asking the user anything, it's a prompt, not a skill. Add verification points.

**Don't batch.** "Here are three tests" is worse than one test with a verification step. The user can't engage with a batch. They can engage with one thing.

**Don't make the phases implicit.** Name them. Number the steps. Tell the AI to not skip ahead. It will skip ahead if you leave room for it.

**Don't front-load all context.** Inject only what Phase 1 needs. Load reference material in Phase 3 when it's actually used. Keep the skill file scannable.

**Don't write generic questions.** "What do you want to do?" teaches the AI nothing. "Have there been any recent bugs that tests didn't catch?" surfaces real history and sets the right starting point.

---

## Checklist for new skills

Before publishing a new skill to this repo:

- [ ] Phase 1 describes what to look for and how to prioritize — no hardcoded file paths or commands
- [ ] Phase 1 detects mode from real project state
- [ ] Phase 2 forbids Write/Edit tools
- [ ] Phase 2 questions reveal assumptions, not just preferences
- [ ] Phase 2 has an explicit gate before Phase 3
- [ ] Phase 3 is a numbered loop with a wait step
- [ ] Phase 3 has a stated priority order
- [ ] Reference material is in `references/`, not inline
- [ ] `install.sh` handles tool-specific placement (claude, cursor, etc.)
