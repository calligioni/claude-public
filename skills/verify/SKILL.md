---
name: verify
description: "Verify project health - type-check, tests, build. Use after making changes or before committing."
argument-hint: "[check type: types|tests|build|all]"
user-invocable: true
context: fork
model: haiku
allowed-tools:
  - Bash
  - Read
  - Glob
inject:
  - bash: ls package.json pyproject.toml go.mod Cargo.toml Makefile 2>/dev/null
---

# Verify Project Health

Quick verification that the codebase is healthy after changes.

## Process

1. Detect project type from config files in the current working directory
2. Run applicable checks based on what's available:

### Detection & Checks

**Node.js/TypeScript** (package.json):

- Type-check: `npx tsc --noEmit` (if tsconfig.json exists)
- Tests: `pnpm test` or `npm test` (if test script exists)
- Build: `pnpm build` or `npm run build` (if build script exists)
- Lint: `pnpm lint` or `npm run lint` (if lint script exists)

**Python** (pyproject.toml / setup.py / requirements.txt):

- Type-check: `mypy .` (if installed)
- Tests: `pytest` (if installed)
- Lint: `ruff check .` or `flake8` (if installed)

**Go** (go.mod):

- Type-check + build: `go build ./...`
- Tests: `go test ./...`
- Lint: `golangci-lint run` (if installed)

**Rust** (Cargo.toml):

- Build: `cargo build`
- Tests: `cargo test`
- Lint: `cargo clippy` (if installed)

3. Report results as a summary table:

```
Verify Results:
  Types:  PASS
  Tests:  PASS (42 passed, 0 failed)
  Build:  PASS
  Lint:   2 warnings
```

## Arguments

- `/verify` — run all applicable checks
- `/verify types` — only type-checking
- `/verify tests` — only test suite
- `/verify build` — only build

## Rules

- Run checks sequentially (type-check first, it catches most issues)
- If type-check fails, still run other checks (report all issues at once)
- Never modify any files — this is read-only verification
- If no project config is found, say so and exit
- Keep output concise — only show failures in detail, summarize passes
