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
3. For each changed file, assign a **risk tier** before reviewing (see Risk Classification below)
4. Review all changes for the checks below
5. For any removed code, run `git log --follow -p -- <file>` to understand original intent before flagging the deletion

### Risk Classification (Trail of Bits Differential Review)

Assign every changed file a risk tier before reviewing its content:

| Tier | Label        | Criteria                                                                                  |
| ---- | ------------ | ----------------------------------------------------------------------------------------- |
| 1    | **CRITICAL** | Auth/authz logic, crypto, payment flows, RLS policies, privilege checks, secrets handling |
| 2    | **HIGH**     | API routes, data validation, DB queries, session management, permission gates             |
| 3    | **MEDIUM**   | Business logic, data transformation, configuration changes                                |
| 4    | **LOW**      | UI components, formatting, tests, documentation                                           |

**Blast radius assessment:** For Tier 1-2 files, note how many callers/consumers depend on the changed function or module. A one-line change in a shared auth helper has higher blast radius than a 200-line change in an isolated UI component.

**Removed-code audit:** When lines are deleted (especially in Tier 1-2 files), use `git log --follow --diff-filter=D -p -- <file>` or `git log -S '<removed_snippet>'` to determine:

- Was this a security check that was intentionally relaxed?
- Was this a guard clause (null check, permission check, rate limit)?
- If a guard was removed, is there an equivalent check added elsewhere?

Flag any removed guard clause as at minimum HIGH severity unless a replacement is visible in the same diff.

### Checks

**Security**

- Hardcoded secrets, API keys, tokens, passwords
- SQL injection risks (string concatenation in queries)
- XSS vectors (unsanitized user input in HTML)
- Exposed sensitive data in error messages
- **Insecure defaults / fail-open:** Check whether error paths, missing config, or exception handlers default to permissive behavior. Secure code fails closed (denies access on error); insecure code fails open (grants access or skips the check). Flag any pattern where: an exception is caught and execution continues past an auth/permission check; a missing config value causes a feature to be enabled rather than disabled; a null/undefined user or role is treated as a valid state rather than rejected.
- **Deep scan hint:** If the diff touches auth, authorization, RLS policies, or complex data flow paths, flag that the changes are candidates for deeper analysis via Claude Code Security (AI-assisted SAST that catches business logic flaws and context-dependent vulns that pattern-matching misses)

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

### Rationalizations Table

For any finding where the code change has an apparent justification (a comment, PR description, or surrounding context that explains why a risky pattern was chosen), include a **Rationalizations** column in the output. This prevents false positives while surfacing cases where the rationalization is insufficient.

| Finding            | Location     | Rationalization found              | Verdict                              |
| ------------------ | ------------ | ---------------------------------- | ------------------------------------ |
| Removed null check | auth.ts:45   | "caller always validates first"    | INSUFFICIENT — caller not in diff    |
| Hardcoded timeout  | config.ts:12 | "temporary until env var wired up" | ACCEPTABLE — low risk, track as TODO |

### Escalation Triggers

Immediately escalate to the user (do not just log) if any of the following are detected:

- A Tier 1 file has net-negative security controls (more checks removed than added)
- A permission/role check is removed without a replacement visible in the diff
- An exception handler catches and silences an auth-related error (fail-open pattern)
- A secret or token appears in the diff (even if it looks like a placeholder)
- A previously-restricted API endpoint becomes unrestricted
- RLS policy is dropped, weakened, or bypassed with a `security definer` function added without a clear justification

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
