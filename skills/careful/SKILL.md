---
name: careful
description: "Safety guardrails for destructive bash commands. Warns before rm -rf, DROP TABLE, force-push, git reset --hard, kubectl delete, docker prune, DELETE FROM. Session-scoped — toggle on/off. Triggers on: careful, careful mode, safety mode, prod mode, be careful."
user-invocable: true
context: inline
model: haiku
effort: low
allowed-tools:
  - Bash
  - Read
---

# /careful — Destructive Command Guardrails

Activates a PreToolUse hook that warns before destructive Bash commands. The hook is
always loaded by the harness but no-ops unless this skill has set the activation flag.

## Activation

```bash
mkdir -p "$HOME/.claude-setup/state"
touch "$HOME/.claude-setup/state/careful.on"
echo "careful mode: ON"
```

Tell the user:

> **careful mode is ON.** I'll ask before running destructive commands (rm -rf, DROP, force-push, kubectl delete, docker prune, DELETE FROM, git reset --hard, git branch -D). Run `/uncareful` or end the session to disable.

## Deactivation — /uncareful

If the user asks to turn it off ("uncareful", "turn off careful", "disable safety mode"):

```bash
rm -f "$HOME/.claude-setup/state/careful.on"
echo "careful mode: OFF"
```

## What's protected

| Pattern                                 | Example                        | Risk                |
| --------------------------------------- | ------------------------------ | ------------------- |
| `rm -rf` / `rm -r` / `rm --recursive`   | `rm -rf /var/data`             | Recursive delete    |
| `DROP TABLE` / `DROP DATABASE/SCHEMA`   | `DROP TABLE users;`            | Data loss           |
| `TRUNCATE`                              | `TRUNCATE orders;`             | Data loss           |
| `DELETE FROM`                           | `DELETE FROM users;`           | Data loss           |
| `git push --force` / `-f`               | `git push -f origin main`      | History rewrite     |
| `git reset --hard`                      | `git reset --hard HEAD~3`      | Uncommitted loss    |
| `git checkout .` / `git restore .`      | `git checkout .`               | Uncommitted loss    |
| `git branch -D`                         | `git branch -D feature/x`      | Lost unmerged work  |
| `kubectl delete`                        | `kubectl delete pod`           | Production impact   |
| `docker rm -f` / `docker system prune`  | `docker system prune -a`       | Container/image loss |

## Safe exceptions

These `rm -rf` targets are allowed without warning:
`node_modules`, `.next`, `dist`, `__pycache__`, `.cache`, `build`, `.turbo`, `coverage`, `.venv`, `venv`.

## How it works

The hook at `~/.claude-setup/hooks/check-careful.sh` reads the bash command from the
tool input, checks it against the patterns above, and returns
`permissionDecision: "ask"` with a warning if a match is found. You can override each
warning and proceed. The hook no-ops when `~/.claude-setup/state/careful.on` does not
exist — zero overhead when the skill is off.

## Scope

- State file is user-global (not per-session). Once activated, it persists across
  sessions until explicitly deactivated or the file is removed.
- Only affects Bash tool calls. Does not affect Edit/Write (that's `/freeze`).
- Can be combined with `/freeze` for full destructive + edit-scope guardrails.
