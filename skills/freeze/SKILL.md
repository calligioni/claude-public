---
name: freeze
description: "Restrict Edit/Write operations to a specific directory. Blocks (not just warns) edits outside the allowed path. Use during debugging to prevent scope creep, or to lock changes to one module. Triggers on: freeze, freeze edits, lock editing scope, restrict edits to, only edit this folder."
user-invocable: true
context: inline
model: haiku
effort: low
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
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

# /freeze — Restrict Edits to a Directory

Activates a PreToolUse hook that blocks Edit/Write operations outside a chosen
directory. The hook is always loaded by the harness but no-ops unless a freeze
directory has been set by this skill.

## Activation

1. **Determine the target directory.**
   - If the user supplied a path via `$ARGUMENTS` or conversation, use it.
   - Otherwise use AskUserQuestion: "Which directory should I restrict edits to? Files outside this path will be blocked."

2. **Resolve to absolute and persist:**

```bash
TARGET="<user-provided-path>"
FREEZE_DIR=$(cd "$TARGET" 2>/dev/null && pwd)
if [ -z "$FREEZE_DIR" ]; then
  echo "Error: directory does not exist: $TARGET"
  exit 1
fi
mkdir -p "$HOME/.claude-setup/state"
printf '%s' "$FREEZE_DIR" > "$HOME/.claude-setup/state/freeze-dir.txt"
echo "Freeze boundary set: $FREEZE_DIR"
```

3. **Tell the user:**

> **Freeze active.** Edits are restricted to `<path>/`. Any Edit or Write outside
> this directory will be **blocked**. Run `/unfreeze` to remove the restriction,
> or `/freeze` again to change the boundary.

## Deactivation — /unfreeze

If the user asks to unfreeze ("unfreeze", "turn off freeze", "remove restriction",
"allow edits everywhere"):

```bash
rm -f "$HOME/.claude-setup/state/freeze-dir.txt"
echo "Freeze removed — edits unrestricted."
```

## How it works

The hook at `~/.claude-setup/hooks/check-freeze.sh` reads `file_path` from the
Edit/Write tool input, resolves it to an absolute path, and checks whether it
starts with the freeze directory. If not, it returns
`permissionDecision: "deny"` to block the operation. The hook no-ops when
`~/.claude-setup/state/freeze-dir.txt` does not exist — zero overhead when off.

## Pairs with /investigate

`/investigate` Phase 2 explicitly recommends using `/freeze` to lock edits to the
narrowest directory containing the affected files after forming a root-cause
hypothesis. This prevents the debugger from "fixing" unrelated code while chasing
a bug.

## Notes

- Only blocks Edit and Write. Bash (including `sed`, `awk`) is unaffected —
  this is a scope-discipline tool, not a security boundary.
- State is user-global. Persists across sessions until explicitly removed.
- Can be combined with `/careful` for full destructive + edit-scope guardrails.
