---
name: vault-bootstrap
description: "Bootstrap a CLAUDE.md API contract for any local knowledge vault (Obsidian, plain markdown). Generates vault overview, conventions, and agent guardrails from 5 diagnostic questions. Triggers on: vault bootstrap, obsidian setup, second brain, vault claude, bootstrap vault, setup obsidian, knowledge vault."
user-invocable: true
context: inline
model: sonnet
effort: low
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
tool-annotations:
  Write: { destructiveHint: false }
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: true
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
---

# Vault Bootstrap

Generate a `CLAUDE.md` API contract for a local knowledge vault so Claude Code treats the vault as structured, persistent context.

The contract defines: what the vault is, how it's organized, naming conventions, what Claude should and should NOT do, and how to update it.

---

## When to Use

- User has an Obsidian vault, Zettelkasten, or plain markdown knowledge base
- User wants Claude Code to read/write in their vault without breaking conventions
- User wants persistent "second brain" context across sessions
- User is setting up a new vault from scratch

---

## Workflow

### Phase 1: Discover the Vault

If the user provides a vault path, scan it:

```
1. Glob for **/*.md to get file count and folder structure
2. Read any existing CLAUDE.md, README.md, or .obsidian/app.json
3. Sample 3-5 files from different directories to detect patterns:
   - Frontmatter fields used (tags, aliases, date, status, type)
   - Linking style (wikilinks [[]] vs markdown []()),
   - Naming conventions (kebab-case, spaces, dates in filenames)
   - Folder structure depth and purpose
```

If no path given, ask:

> What's the path to your vault or knowledge base directory?

### Phase 2: Five Diagnostic Questions

Ask the user these 5 questions to understand intent. Skip any that were already answered by Phase 1 scanning or user's initial message.

**Q1: Purpose** — "What's this vault for? (personal notes, work projects, research, learning, all of the above)"

**Q2: Structure** — "How is it organized? (PARA folders, Zettelkasten IDs, topic folders, flat, other)" — If Phase 1 detected structure, confirm: "I see you're using [detected pattern]. Is that right?"

**Q3: Conventions** — "Any naming rules? (date prefixes, kebab-case, tags in frontmatter, etc.)" — If Phase 1 detected conventions, confirm.

**Q4: Agent role** — "What should Claude do with this vault? Pick all that apply:

- Read for context (never modify)
- Add new notes when asked
- Update existing notes
- Refactor/reorganize when asked
- Generate daily/weekly summaries"

**Q5: Guardrails** — "What should Claude NEVER do? (e.g., delete notes, restructure folders, add emojis, change frontmatter schema)"

### Phase 3: Generate CLAUDE.md

Using the answers, generate a `CLAUDE.md` file at the vault root with this structure:

```markdown
# [Vault Name]

## Overview

[1-2 sentences: what this vault is and who it's for]

## Structure

[Folder layout with purpose of each top-level directory]

## Conventions

- Naming: [detected/stated convention]
- Links: [wikilinks vs markdown links]
- Frontmatter: [required fields, e.g., date, tags, status]
- New files: [where to create, what template to follow]

## Agent Role

[What Claude should do — from Q4 answers]

## Do NOT

[Explicit list from Q5 + sensible defaults:]

- Do not delete or rename existing files unless explicitly asked
- Do not restructure folder hierarchy
- Do not add emojis to file content
- Do not modify frontmatter schema without asking
- Do not create files outside the vault directory
- Do not remove or modify wikilinks/backlinks

## Session Memory

When working in this vault, track decisions and progress in `_session.md` at the vault root.
Update it at the end of each session with:

- What was changed (files created/modified)
- Decisions made
- Open questions for next session
```

### Phase 4: Optional — Generate memory.md

If the user's agent role includes "read for context", also generate a `memory.md`:

```markdown
# Memory

## Key Context

[Auto-populated from vault scan: main topics, recent files, active projects]

## Decisions

[Empty — filled during sessions]

## In Progress

[Empty — filled during sessions]
```

### Phase 5: Confirm and Write

Show the user a preview of the generated `CLAUDE.md`. Ask:

> Does this look right? I'll write it to `[vault-path]/CLAUDE.md`. Any changes?

Write after confirmation. If the user has an existing `CLAUDE.md`, show a diff and ask before overwriting.

---

## Output

- `CLAUDE.md` at vault root — the API contract
- `memory.md` at vault root (optional) — session continuity log
- `_session.md` at vault root (optional) — per-session change tracker

---

## Notes

- This skill does NOT require Obsidian — it works with any directory of markdown files
- The generated `CLAUDE.md` follows the same pattern as project-level CLAUDE.md files
- For vaults with 1000+ files, Phase 1 sampling is capped at 10 files across 5 directories
- If the vault uses `.obsidian/` config, extract workspace name and plugin list for context
