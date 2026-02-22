---
name: review-changes
description: "Review uncommitted changes for bugs, security issues, and code quality before committing."
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
tool-annotations:
  Bash: { readOnlyHint: true, idempotentHint: true }
  Read: { readOnlyHint: true, idempotentHint: true }
  Grep: { readOnlyHint: true, idempotentHint: true }
inject:
  - bash: git diff --cached --stat
  - bash: git diff --stat
  - bash: git status --short
invocation-contexts:
  user-direct:
    verbosity: high
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    outputFormat: structured
---

# Review Changes

Pre-commit quality review of staged or unstaged changes.

## Process

1. Run `git diff --cached` for staged changes, or `git diff` if nothing is staged
2. Also check `git status` for new untracked files
3. Review all changes for:

### Checks

**Security**

- Hardcoded secrets, API keys, tokens, passwords
- SQL injection risks (string concatenation in queries)
- XSS vectors (unsanitized user input in HTML)
- Exposed sensitive data in error messages

**Bugs**

- Null/undefined access without checks
- Off-by-one errors
- Race conditions
- Missing error handling
- Unreachable code

**Code Quality**

- Leftover debug code (console.log, debugger, print statements)
- TODO/FIXME/HACK comments that should be addressed
- Commented-out code that should be deleted
- Inconsistent naming
- Overly complex logic that could be simplified

**Git Hygiene**

- Files that shouldn't be committed (.env, node_modules, build artifacts)
- Merge conflict markers
- Excessively large files

4. Report findings

## Output Format

If clean:

```
Review: CLEAN
No issues found in 5 changed files (42 lines added, 12 removed).
Ready to commit.
```

If issues found:

```
Review: 2 issues found

CRITICAL:
  src/api/auth.ts:45 - Hardcoded API key: const key = "sk-..."

WARNING:
  src/utils/parse.ts:12 - console.log left in production code

Recommendation: Fix critical issues before committing.
```

## Rules

- Never modify files — this is read-only review
- Prioritize security issues above all else
- Be concise — only flag real issues, not style preferences
- If no changes exist, say so and exit
