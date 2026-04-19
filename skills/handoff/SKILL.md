---
name: handoff
description: "Context handoff before /clear or compaction. Writes progress log to plan doc, commits, outputs a resume block that /primer can consume. Triggers on: handoff, checkpoint context, before clear, pre-clear, resume block, save context."
argument-hint: "[plan-doc-path]"
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
  Bash: { destructiveHint: false, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: false }
  Edit: { destructiveHint: false, idempotentHint: false }
inject:
  - bash: pwd
  - bash: git rev-parse --show-toplevel 2>/dev/null || echo "not a git repo"
  - bash: git branch --show-current 2>/dev/null || echo ""
  - bash: git log --oneline -5 2>/dev/null
  - bash: git status --short 2>/dev/null
  - bash: gh pr list --head "$(git branch --show-current 2>/dev/null)" --json number,url,state,isDraft 2>/dev/null || echo "[]"
  - bash: date "+%Y-%m-%d %H:%M"
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: false
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    outputFormat: structured
---

# Handoff — Context Checkpoint Before `/clear`

Produce a durable checkpoint so the next session can resume with one read + three commands. This skill is the **producer**; `/primer` is the consumer.

## When to invoke

- Context is 85%+ full and the task is not complete
- Before a planned `/clear` or `/compact`
- Before closing a long-running agentic session you want to resume tomorrow
- User says "checkpoint this", "save state", "handoff", "before I clear"

## Non-goals

- Do **not** run `/clear` or `/compact` — that is the user's call
- Do **not** write memory entries (that is `/meditate`'s job)
- Do **not** create new documentation files unless the user explicitly asks — reuse the existing plan doc

## Process

### Step 1 — Locate the plan doc

Look for the working document this session has been iterating on, in priority order:

1. If the user passed a path as argument, use it.
2. Grep the current session's recent edits (from context) for a `.md` file that was repeatedly written/read.
3. Check these conventional locations in the repo (from `git rev-parse --show-toplevel`):
   - `docs/*-plan.md` (e.g., `docs/infra-separation-plan.md`)
   - `.deep-plan-state.json` sibling `.md` in `.orchestrate-plan/`
   - `PLAN.md`, `ROADMAP.md` at repo root
   - Any `*-plan.md` modified in the last commit

If **zero** matches: ask the user which doc to append to, or offer to create `docs/<inferred-topic>-plan.md`. Default to asking — never silently create.

If **multiple** matches: ask the user to pick. Show modified times to help disambiguate.

### Step 2 — Gather state

From the injected context and these targeted reads:

- **Branch + commit**: `git branch --show-current`, latest commit SHA, "N ahead of origin"
- **PR**: `gh pr list --head <branch>` — number, URL, state, isDraft
- **Tests/CI**: check the plan doc for last-known status, or run `gh run list --branch <branch> --limit 1` if the user wants fresh data
- **Active session context**: OCI profile, kubectl context, env vars — read from the plan doc's progress log (do not re-authenticate)
- **Git state**: uncommitted files, untracked files

Do NOT run tests, builds, or deploys. This is read-only state gathering.

### Step 3 — Append progress log entry

Open the plan doc. Find or create a `## Progress log` section (or similar: `## Session log`, `## Timeline`). Append a new entry at the top of that section:

```markdown
### YYYY-MM-DD HH:MM — <one-line status>

**Plan:** <done|in-progress|N of M phases complete>
**Code:** <branch> at <short-sha>, PR #<N> <open|merged|draft>, <tests status>
**Execution:** <what ran, what's next>
**Blockers:** <any blockers, or "none">

**Next actions (for resume):**
1. <step>
2. <step>
3. <step>
```

Use `Edit` (not `Write`) to preserve the rest of the document. If the log section does not exist, add it immediately before the last top-level heading, or append at the end if none fits.

### Step 4 — Commit and push

```bash
git add <plan-doc-path>
git commit -m "docs(<scope>): progress log — <one-line status>"
git push
```

Scope: infer from the doc path (`infra`, `auth`, `billing`, etc.). If push fails (upstream not set, auth, network), report it but do not block — the commit is durable locally.

### Step 5 — Emit the resume block

Print this exact format (the user copies it mentally or `/primer` reconstructs it). Replace all `<...>` placeholders.

```
Context checkpoint — where to resume after /clear

Read first on resume: <absolute path to plan doc>

TL;DR of state:
- Plan: <status>
- Code: <branch> at <short-sha>, PR #<N> <state>, <tests status>
- Execution: <N of M steps run>, <any auth/session notes>

Next actions after /clear (in order):
1. <action>
2. <action>
3. <action>
...

State persisted:
- Plan doc: <path> — includes full architecture + progress log + next actions
- PR #<N>: <url> — <open|merged|draft>
- Branch: <branch> at <sha> — pushed
- Background agents: <none|list>
- Dirty git state: <none|list>
- Session auth: <OCI profile / kubectl context / other, or "none active">
- Memory: <any hot memories relevant to resume>

After /clear, invoke /primer — the resume will find this plan doc via git log.
```

### Step 6 — Confirm with the user

End with a single line:

> Ready to `/clear`. Plan is checkpointed at `<path>` at commit `<sha>`.

Do not invoke `/clear` yourself. The user decides.

## Edge cases

- **No git repo**: skip commit/push. Still append to the plan doc. Flag this — the checkpoint will not survive machine changes.
- **Plan doc is in a different repo**: commit in that repo's worktree. Do not force cross-repo commits.
- **User on detached HEAD**: warn, ask before committing. Offer to create a branch.
- **Context is already >95%**: skip re-reading the full plan doc. Use only injected context + one targeted grep for the progress log section. Do not expand exploration.
- **User has uncommitted unrelated changes**: commit ONLY the plan doc (`git add <plan-doc-path>` — never `git add -A`).
- **Push fails**: keep going, note it in the resume block under "State persisted".

## Invocation contexts

### user-direct (typed `/handoff`)

- Full markdown output
- Show the resume block clearly formatted
- Ask before creating a new plan doc
- Confirm the commit message before pushing

### agent-spawned (called from another skill, e.g., `/ship` or `/deep-plan` auto-checkpoint)

- Emit resume block as structured text only — no preamble
- Never ask — fail fast if plan doc is ambiguous
- Skip push if auth is not set up

## Related skills

- `/primer` — consumes this checkpoint on the next session (reads plan doc, shows current status)
- `/meditate` — different goal: extracts session learnings into long-term memory
- `/deep-plan` — owns the plan doc lifecycle; `/handoff` just appends to it
- `/cpr` — commits and pushes a full feature; `/handoff` commits only the checkpoint

## Notes

This skill formalizes the 85%-checkpoint pattern observed in long agentic sessions. Its output is designed to be **parseable by `/primer`** — any change to the resume block format must be reflected in `/primer` too.
