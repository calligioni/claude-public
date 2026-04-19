---
name: review-changes
description: "Review uncommitted changes for bugs, security issues, and code quality before committing."
user-invocable: true
context: fork
model: sonnet
effort: medium
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

### Two-Pass Review

Run Pass 1 first. If any CRITICAL findings exist, report them immediately — these block commits. Then run Pass 2 for informational findings.

#### Pass 1 — CRITICAL (blocks commit)

**Security & Injection**

- Hardcoded secrets, API keys, tokens, passwords
- SQL injection risks (string interpolation in queries — even if values are `.to_i`/`.to_f`, use parameterized queries)
- XSS vectors (unsanitized user input in HTML, `.html_safe`/`raw()` on user-controlled data)
- Exposed sensitive data in error messages
- **Insecure defaults / fail-open:** Check whether error paths, missing config, or exception handlers default to permissive behavior. Secure code fails closed (denies access on error); insecure code fails open (grants access or skips the check). Flag any pattern where: an exception is caught and execution continues past an auth/permission check; a missing config value causes a feature to be enabled rather than disabled; a null/undefined user or role is treated as a valid state rather than rejected.
- **Deep scan hint:** If the diff touches auth, authorization, RLS policies, or complex data flow paths, flag that the changes are candidates for deeper analysis via Claude Code Security (AI-assisted SAST that catches business logic flaws and context-dependent vulns that pattern-matching misses)

**Race Conditions & Concurrency**

- TOCTOU: check-then-set patterns that should be atomic (e.g., read-check-write without uniqueness constraint or conflict handling)
- `findOrCreate` / `upsert` on columns without unique DB index — concurrent calls can create duplicates
- Status transitions that don't use atomic `WHERE old_status = ? UPDATE SET new_status` — concurrent updates can skip or double-apply
- N+1 queries: missing `.includes()` / eager loading for associations used in loops

**LLM Output Trust Boundary**

- LLM-generated values (emails, URLs, names) written to DB or passed to external systems without format validation — add lightweight guards (regex, `URL.parse`, `.trim()`) before persisting
- Structured tool output (arrays, objects) accepted without type/shape checks before database writes
- Prompt text listing available tools/capabilities that don't match what's actually wired up

#### Pass 2 — INFORMATIONAL (non-blocking)

**Bugs**

- Null/undefined access without checks
- Off-by-one errors
- Missing error handling
- Unreachable code

**Conditional Side Effects**

- Code paths that branch on a condition but forget to apply a side effect on one branch (e.g., record promoted but URL only attached on one path)
- Log messages that claim an action happened but the action was conditionally skipped

**Crypto & Entropy**

- Truncation of data instead of hashing (last N chars vs SHA-256) — less entropy, easier collisions
- `Math.random()` / non-crypto RNG for security-sensitive values — use `crypto.randomUUID()` / `crypto.getRandomValues()`
- Non-constant-time comparisons (`===`) on secrets or tokens — vulnerable to timing attacks

**Type Coercion at Boundaries**

- Values crossing server→JSON→client boundaries where type could change (numeric vs string)
- Hash/digest inputs that don't normalize types before serialization

**Time Window Safety**

- Date-key lookups that assume "today" covers 24h — timezone-dependent
- Mismatched time windows between related features (one uses hourly, another daily for the same data)

**Test Gaps**

- Negative-path tests that assert type/status but not side effects
- Security enforcement features without integration tests verifying the enforcement path end-to-end

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

### Suppressions — DO NOT flag these

- Redundancy that aids readability (e.g., `!= null` redundant with optional chaining but clearer)
- "Add a comment explaining why this threshold/constant was chosen" — thresholds change during tuning, comments rot
- "This assertion could be tighter" when the assertion already covers the behavior
- Consistency-only changes (wrapping a value in a conditional to match how another is guarded)
- Eval threshold changes that are tuned empirically
- Harmless no-ops (e.g., `.filter()` on an array that never contains the filtered value)
- Anything already addressed in the diff — read the FULL diff before commenting

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
Review: 2 issues (1 critical, 1 informational)

CRITICAL (blocks commit):
  [src/api/auth.ts:45] Hardcoded API key: const key = "sk-..."
  Fix: Move to environment variable

INFORMATIONAL:
  [src/utils/parse.ts:12] console.log left in production code
  Fix: Remove debug statement

Recommendation: Fix critical issues before committing.
```

## Rules

- Never modify files — this is read-only review
- Prioritize security issues above all else
- Be concise — only flag real issues, not style preferences
- If no changes exist, say so and exit
