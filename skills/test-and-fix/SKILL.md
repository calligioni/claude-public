---
name: test-and-fix
description: "Run tests and auto-fix failures in a loop. Use when tests are failing and you want them fixed."
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
inject:
  - bash: ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
---

# Test and Fix

Run the project's test suite and automatically fix failures, iterating until all tests pass.

## Process

1. Detect test runner from project config (package.json, pyproject.toml, go.mod, Cargo.toml)
2. Run the test suite and capture output
3. If all tests pass, report success and exit
4. If failures exist:
   a. Parse error output to identify failing tests and error messages
   b. Read the failing test file and the source code it tests
   c. Determine if the bug is in the source code or the test
   d. Fix the issue (prefer fixing source code over changing tests, unless the test is wrong)
   e. Re-run tests
5. Repeat up to 3 iterations
6. If tests still fail after 3 iterations, report remaining failures and stop

## Rules

- Never change test assertions to make tests pass unless the assertion is genuinely wrong
- Fix the root cause, not symptoms
- Make minimal changes — don't refactor surrounding code
- If a test failure requires architectural changes, report it and stop
- Show what was changed after each fix iteration

## Output Format

```
Iteration 1:
  Tests: 40 passed, 2 failed
  Failures:
    - test_user_auth: Expected 200, got 401
    - test_data_export: TypeError: undefined is not a function
  Fix: Updated auth middleware to handle expired tokens
  Files changed: src/middleware/auth.ts

Iteration 2:
  Tests: 41 passed, 1 failed
  Fix: Added null check in export service
  Files changed: src/services/export.ts

Iteration 3:
  Tests: 42 passed, 0 failed
  All tests passing.
```
