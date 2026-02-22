---
name: cpr
description: "Commit, push, and create PR. Full git workflow in one command."
argument-hint: "[PR title or commit message]"
user-invocable: true
context: fork
model: haiku
allowed-tools:
  - Bash
  - Read
tool-annotations:
  Bash: { readOnlyHint: false, idempotentHint: false }
inject:
  - bash: git diff --stat HEAD 2>/dev/null || git diff --stat
  - bash: git log --oneline -5 2>/dev/null
  - bash: git branch --show-current 2>/dev/null
  - bash: git log --oneline main..HEAD 2>/dev/null || git log --oneline master..HEAD 2>/dev/null
---

# CPR - Commit, Push, PR

Full git workflow: commit all changes, push to remote, and create a pull request.

## Process

1. Review the injected git diff stats and branch info (already precomputed above)
2. If there are uncommitted changes:
   a. Stage all changes (`git add -A`)
   b. Generate a commit message following conventional commits format: `type(scope): description`
   c. If user provided an argument, use it as the commit message
   d. Commit the changes
3. Push to remote (`git push -u origin <current-branch>`)
4. Create PR using `gh pr create`:
   a. Generate a concise PR title (under 70 chars)
   b. Generate PR body with summary bullets and test plan
   c. Use the base branch (main or master)

## PR Body Format

```
gh pr create --title "the title" --body "$(cat <<'EOF'
## Summary
- <bullet points summarizing changes>

## Test plan
- [ ] <verification steps>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## Rules

- If already on main/master, create a feature branch first from the diff context
- If no changes to commit, just push existing commits and create PR
- If a PR already exists for this branch, just push (no duplicate PR)
- Use `gh pr create` not the GitHub API directly
- Always set upstream with `-u` flag on push
- Keep PR title short, use body for details
