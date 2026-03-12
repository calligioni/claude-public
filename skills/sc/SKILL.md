---
name: sc
description: "Ship commit: verify → review → commit → push → PR. Full pipeline from changes to PR in one command."
argument-hint: "[PR title or commit message]"
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
tool-annotations:
  Bash: { readOnlyHint: false, idempotentHint: false }
  Read: { readOnlyHint: true, idempotentHint: true }
  Grep: { readOnlyHint: true, idempotentHint: true }
inject:
  - bash: git diff --cached --stat 2>/dev/null
  - bash: git diff --stat 2>/dev/null
  - bash: git status --short 2>/dev/null
  - bash: git branch --show-current 2>/dev/null
  - bash: git log --oneline -5 2>/dev/null
  - bash: ls package.json pyproject.toml go.mod Cargo.toml Makefile 2>/dev/null
invocation-contexts:
  user-direct:
    verbosity: high
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    outputFormat: structured
---

# SC — Ship Commit

Full pipeline: verify project health → review changes → commit → push → create PR.

Auto-proceeds through all stages. Critical review findings are reported but do NOT block — the user chose speed.

## Pipeline

### Stage 1: Verify

Run project health checks based on detected project type:

**Node.js/TypeScript** (package.json):

- Type-check: `npx tsc --noEmit` (if tsconfig.json exists)
- Tests: `pnpm test` or `npm test` (if test script exists)
- Build: `pnpm build` or `npm run build` (if build script exists)
- Lint: `pnpm lint` or `npm run lint` (if lint script exists)

**Python** (pyproject.toml / setup.py):

- Type-check: `mypy .` (if installed)
- Tests: `pytest` (if installed)
- Lint: `ruff check .` or `flake8` (if installed)

**Go** (go.mod):

- Build: `go build ./...`
- Tests: `go test ./...`
- Lint: `golangci-lint run` (if installed)

**Rust** (Cargo.toml):

- Build: `cargo build`
- Tests: `cargo test`
- Lint: `cargo clippy` (if installed)

**If verify fails:** Report failures but continue to Stage 2. Include verify failures in the PR body under a "Verify Warnings" section so the author knows.

**If no project config found:** Skip to Stage 2.

### Stage 2: Review

Run the full two-pass review on all uncommitted changes:

1. `git diff --cached` for staged, `git diff` for unstaged, `git status` for untracked
2. Risk-tier every changed file (Critical/High/Medium/Low)
3. **Pass 1 — CRITICAL:** Security & injection, race conditions & concurrency, LLM output trust boundary
4. **Pass 2 — INFORMATIONAL:** Bugs, conditional side effects, crypto/entropy, type coercion, time window safety, test gaps, code quality, git hygiene
5. Apply suppressions (do not flag redundancy-for-readability, threshold tuning, already-addressed-in-diff, etc.)
6. Check escalation triggers (net-negative security controls, removed permission checks, exposed secrets, weakened RLS)

**Report all findings** in the output. Do NOT block — auto-proceed to Stage 3.

If critical findings exist, include them in the PR body under a "Review Findings" section.

### Stage 3: Commit + Push + PR

1. If on main/master, create a feature branch first (derive name from changes)
2. Stage all changes: `git add -A`
3. Generate conventional commit message: `type(scope): description`
   - If user provided an argument, use it as the commit message
4. Commit the changes
5. Push to remote: `git push -u origin <branch>`
6. Create PR using `gh pr create`:

```
gh pr create --title "the title" --body "$(cat <<'EOF'
## Summary
- <bullet points summarizing changes>

## Verify Results
<types/tests/build/lint pass/fail summary — omit section if all passed>

## Review Findings
<critical and informational findings — omit section if clean>

## Test plan
- [ ] <verification steps>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

7. If a PR already exists for this branch, just push (no duplicate PR)

## Output

Show a pipeline progress summary:

```
/sc Pipeline
─────────────
Verify:  PASS (types ✓, tests ✓, build ✓)
Review:  CLEAN — no issues in 5 files
Commit:  feat(auth): add JWT refresh token rotation
Push:    → origin/feature/jwt-refresh
PR:      https://github.com/org/repo/pull/42
```

Or with issues:

```
/sc Pipeline
─────────────
Verify:  WARN — 2 type errors (continued)
Review:  2 issues (1 critical, 1 informational) (continued)
Commit:  feat(auth): add JWT refresh token rotation
Push:    → origin/feature/jwt-refresh
PR:      https://github.com/org/repo/pull/42 (includes verify + review notes)
```

## Rules

- Never stop the pipeline — auto-proceed through all stages
- Include verify/review issues in PR body so they're visible to reviewers
- Use `gh pr create`, not the GitHub API directly
- Always set upstream with `-u` flag on push
- Keep PR title under 70 chars, use body for details
- If no changes exist, say so and exit
