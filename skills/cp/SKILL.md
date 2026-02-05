---
name: cp
description: Quick commit and push. Use when asked to commit and push, or just "cp".
argument-hint: "[commit message]"
user-invocable: true
context: fork
model: haiku
allowed-tools:
  - Bash
disable-model-invocation: true
inject:
  - bash: git diff --stat
  - bash: git status --short
  - bash: git branch --show-current
---

# CP - Commit and Push

Quick command to commit all staged changes and push to remote.

## Usage

- `/cp` - Commit staged changes with auto-generated message, then push
- `/cp fix typo` - Commit with custom message "fix typo", then push

## What It Does

1. Checks for staged or unstaged changes
2. If unstaged changes exist, stages all changes (`git add -A`)
3. Generates a concise commit message based on the diff (or uses provided message)
4. Commits the changes
5. Pushes to the current branch's remote

## Example

```
/cp

Staged 3 files:
  M src/api/auth.ts
  M src/components/Login.tsx
  A src/utils/validation.ts

Commit: feat(auth): add input validation to login flow

Pushed to origin/main
```

## PR Status Tracking

Claude Code v2.1.20+ shows PR review status indicators in the prompt footer. After pushing, check the status bar for PR review state.
