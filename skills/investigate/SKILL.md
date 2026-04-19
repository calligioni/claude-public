---
name: investigate
description: "Systematic debugging with root-cause investigation. Iron Law: no fixes without root cause. Four phases — investigate, hypothesize, fix, verify. 3-strike rule forces escalation. Triggers on: debug this, fix this bug, why is this broken, investigate this error, root cause analysis."
user-invocable: true
context: inline
model: opus
effort: high
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - WebSearch
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

# /investigate — Systematic Root-Cause Debugging

## Iron Law

**NO FIXES WITHOUT ROOT-CAUSE INVESTIGATION FIRST.**

Fixing symptoms creates whack-a-mole debugging. Every fix that does not address root cause makes the next bug harder to find. Find the root cause, then fix it.

---

## Phase 1: Root-Cause Investigation

Gather context before forming any hypothesis.

1. **Collect symptoms** — Read error messages, stack traces, reproduction steps. If the user did not provide enough context, ask ONE question via AskUserQuestion.

2. **Read the code** — Trace the code path from symptom back to potential causes. Use Grep to find all references, Read to understand the logic.

3. **Check recent changes**:
   ```bash
   git log --oneline -20 -- <affected-files>
   ```
   Was this working before? What changed? A regression means the root cause is in the diff.

4. **Reproduce** — Can you trigger the bug deterministically? If not, gather more evidence before proceeding.

5. **Check memory** — `~/.claude-setup/tools/mem-search "<keywords from symptom>"` for prior investigations on the same files or pattern. Recurring bugs in the same area are an architectural smell.

Output: **"Root-cause hypothesis: ..."** — a specific, testable claim about what is wrong and why.

---

## Phase 2: Scope Lock (optional)

If `/freeze` is available, lock edits to the narrowest directory containing the affected files to prevent scope creep. Tell the user which directory you locked and why. Skip if the bug genuinely spans the repo.

---

## Phase 3: Hypothesis Testing

Before writing ANY fix, verify your hypothesis.

1. **Confirm the hypothesis** — Add a temporary log statement, assertion, or debug output at the suspected root cause. Run the reproduction. Does the evidence match?

2. **If the hypothesis is wrong** — Sanitize the error (strip hostnames, IPs, paths, SQL fragments, customer data) and WebSearch the generic error type and framework context. Then return to Phase 1. Gather more evidence. Do not guess.

3. **3-strike rule** — If 3 hypotheses fail, **STOP**. Use AskUserQuestion:
   ```
   3 hypotheses tested, none match. This may be an architectural issue
   rather than a simple bug.

   A) Continue investigating — new hypothesis: [describe]
   B) Escalate for human review — this needs someone who knows the system
   C) Add logging and wait — instrument the area and catch it next time
   ```

**Red flags** — if you see any of these, slow down:
- "Quick fix for now" — there is no "for now." Fix it right or escalate.
- Proposing a fix before tracing data flow — you are guessing.
- Each fix reveals a new problem elsewhere — wrong layer, not wrong code.

### Pattern reference

| Pattern             | Signature                              | Where to look                          |
| ------------------- | -------------------------------------- | -------------------------------------- |
| Race condition      | Intermittent, timing-dependent         | Concurrent access to shared state      |
| Nil/null propagation | NoMethodError, TypeError              | Missing guards on optional values      |
| State corruption    | Inconsistent data, partial updates     | Transactions, callbacks, hooks         |
| Integration failure | Timeout, unexpected response           | External API calls, service boundaries |
| Configuration drift | Works locally, fails in staging/prod   | Env vars, feature flags, DB state      |
| Stale cache         | Shows old data, fixes on cache clear   | Redis, CDN, browser cache              |

---

## Phase 4: Implementation

Once root cause is confirmed:

1. **Fix the root cause, not the symptom.** The smallest change that eliminates the actual problem.

2. **Minimal diff** — Fewest files touched, fewest lines changed. Resist the urge to refactor adjacent code.

3. **Write a regression test** that:
   - **Fails** without the fix (proves the test is meaningful)
   - **Passes** with the fix (proves the fix works)

4. **Run the full test suite.** Paste the output. No regressions allowed.

5. **If the fix touches >5 files** — Use AskUserQuestion to flag the blast radius:
   ```
   This fix touches N files. Large blast radius for a bug fix.
   A) Proceed — root cause genuinely spans these files
   B) Split — fix the critical path now, defer the rest
   C) Rethink — maybe there is a more targeted approach
   ```

---

## Phase 5: Verification & Report

**Fresh verification** — Reproduce the original bug scenario and confirm it is fixed. Not optional.

Output a structured debug report:

```
DEBUG REPORT
════════════════════════════════════════
Symptom:         [what the user observed]
Root cause:      [what was actually wrong]
Fix:             [what was changed, with file:line references]
Evidence:        [test output, reproduction attempt showing fix works]
Regression test: [file:line of the new test]
Related:         [prior bugs in same area, architectural notes]
Status:          DONE | DONE_WITH_CONCERNS | BLOCKED
════════════════════════════════════════
```

If the root cause is architectural (not a local bug), save a memory entry so future investigations find it: write a `mistake:` or `architecture:` file under `~/.claude-setup/memory/auto/` and add a line to `MEMORY.md`. See `~/.claude-setup/rules/memory-strategy.md`.

---

## Completion Status

- **DONE** — root cause found, fix applied, regression test written, all tests pass
- **DONE_WITH_CONCERNS** — fixed but cannot fully verify (intermittent bug, requires staging)
- **BLOCKED** — root cause unclear after investigation, escalated

---

## Rules

- **3+ failed fix attempts → STOP and question the architecture.** Wrong architecture, not failed hypothesis.
- **Never apply a fix you cannot verify.** If you cannot reproduce and confirm, do not ship it.
- **Never say "this should fix it."** Verify and prove it. Run the tests.
- **Fix touches >5 files → AskUserQuestion** about blast radius before proceeding.
