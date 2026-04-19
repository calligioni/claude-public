# /orchestrate — Version History

## v1.1.0 — 2026-04-17 (same day)

**Skill-authoring loop** wired via `/meditate` Phase 6a.

- Phase 9 now passes `run-id` + `phase-plan.md` to `/meditate`.
- `/meditate` Phase 6a detects: (a) novel chains not in `patterns.json`, (b) chains repeated ≥3× in last 30 days.
- Novel repeat → proposes new canonical chain (updates `patterns.json`).
- Novel repeat + ≥4 skills + distinctive intent → proposes new composite skill.
- **Never auto-commits.** User must reply `go` to save. Consistent with orchestrate's gate model.

## v1.0.0 — 2026-04-17

**Shipped.** Supersedes `/project-orchestrator` (deleted same day).

### Locked Decisions (from Pierre, 2026-04-17)
1. Budget: $10 warn / $50 cap per run
2. Approval password: literal word `go` (case-insensitive, whole-word match)
3. v1 scope: ExampleProject single-repo only
4. Location: `~/.claude-setup/skills/` (private origin: escotilha/claude) — also published to the public sibling `escotilha/claude-public` via `/cs`
5. `/project-orchestrator` removed immediately
6. Fan-out: sequential in `--gated`, parallel in `--autonomous`
7. Routines: first-class via `--as-routine <cron>`
8. Catalog: all 83 user-invocable skills, regenerated per invocation

### What ships
- `SKILL.md` — main skill definition
- `build-catalog.sh` — catalog generator
- `router.md` — router prompt + schema
- `patterns.json` — 7 canonical chains
- `pricing.json` — budget estimator inputs
- `VERSION.md` — this file

### Known gaps (fix in v1.x)
- `skill-catalog.json` is generated on first invocation (bootstrap).
- Router LLM call is specified but needs integration test against a real intent.
- Routine approval bridge (Discord/Slack `go` reply) depends on `/schedule` + `discord:*` skills — wiring in v1.1.
