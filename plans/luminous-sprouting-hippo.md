# Parallel Feature Development Skill

## Overview

Create a `parallel-dev` skill that orchestrates parallel feature development using git worktrees and specialized agents. Integrates with CPO-AI-Skill as the planning brain.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Input Sources                             │
├─────────────────────────────────────────────────────────────┤
│  Option A: Inline prompt      Option B: master-project.json │
│  /parallel-dev                /parallel-dev --from-cpo      │
│  ## Feature: Auth             (reads stages from CPO plan)  │
│  - OAuth login                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Parallel-Dev Orchestrator                  │
│  1. Parse features/stages                                    │
│  2. Build dependency graph                                   │
│  3. Create worktrees (via maketree integration)             │
│  4. Spawn agents per worktree (run_in_background: true)     │
│  5. Monitor progress dashboard                               │
│  6. Progressive merge with integration tests                 │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
    ┌──────────┐        ┌──────────┐        ┌──────────┐
    │ Worktree │        │ Worktree │        │ Worktree │
    │ feature/ │        │ feature/ │        │ feature/ │
    │ auth     │        │ api      │        │ dashboard│
    │          │        │          │        │          │
    │ Agent:   │        │ Agent:   │        │ Agent:   │
    │ backend  │        │ api-agent│        │ frontend │
    └──────────┘        └──────────┘        └──────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              ▼
                    Integration Branch
                    (progressive merge)
```

## Input Formats

### Option A: Inline Prompt
```
/parallel-dev

## Feature: Authentication
type: backend
- Add OAuth2 login with Google/GitHub
- Session management with Redis
- JWT token refresh

## Feature: Dashboard UI
type: frontend
dependsOn: api-endpoints
- Stats cards with real-time data
- Charts using Recharts
- Dark mode support

## Feature: API Endpoints
type: api
- User CRUD endpoints
- Rate limiting middleware
- OpenAPI documentation
```

### Option B: From CPO-AI-Skill
```
/parallel-dev --from-cpo
```
Reads `master-project.json` and parallelizes stages based on `dependsOn` graph.

### Option C: Config File
```
/parallel-dev --config features.json
```

## Agent Assignment Logic

| Feature Type | Primary Agent | Fallback |
|--------------|---------------|----------|
| `frontend`, `ui` | frontend-agent | general-purpose |
| `backend`, `api` | backend-agent or api-agent | general-purpose |
| `database`, `schema` | database-agent | general-purpose |
| `testing`, `e2e` | testing-agent | general-purpose |
| `devops`, `deploy` | devops-agent | general-purpose |
| unspecified | general-purpose | - |

## Merge Strategy: Progressive with Integration

```
Feature completes
       │
       ▼
┌──────────────┐
│ Run tests in │
│ worktree     │
└──────┬───────┘
       │ Pass?
       ├─── No ──► Agent fixes, re-tests (max 3 iterations)
       │
       ▼ Yes
┌──────────────┐
│ Merge to     │
│ integration  │
│ branch       │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Run          │
│ integration  │
│ tests        │
└──────┬───────┘
       │ Conflict?
       ├─── Yes ──► Pause, notify user, don't auto-resolve
       │
       ▼ No
   Continue
```

## Progress Dashboard

The orchestrator maintains a live progress view:

```
╔══════════════════════════════════════════════════════════════╗
║ PARALLEL-DEV: myproject                                       ║
╠══════════════════════════════════════════════════════════════╣
║ Feature          │ Agent      │ Status      │ Progress       ║
╠──────────────────┼────────────┼─────────────┼────────────────╣
║ auth             │ backend    │ ████████░░  │ 80% - testing  ║
║ api-endpoints    │ api-agent  │ ██████████  │ ✓ merged       ║
║ dashboard        │ frontend   │ ██████░░░░  │ 60% - building ║
║ payment          │ backend    │ ░░░░░░░░░░  │ ⏸ waiting on auth║
╠══════════════════════════════════════════════════════════════╣
║ Integration: 1/4 merged │ Conflicts: 0 │ Elapsed: 12m        ║
╚══════════════════════════════════════════════════════════════╝
```

## File Structure

```
~/.claude-setup/
└── skills/
    └── parallel-dev/
        ├── SKILL.md              # Main skill definition
        ├── command.md            # Command interface
        └── references/
            ├── orchestration.md  # Orchestration logic
            ├── worktree-setup.md # Worktree creation patterns
            ├── agent-dispatch.md # Agent selection & spawning
            └── merge-strategy.md # Progressive merge logic
```

## Implementation Plan

### Phase 1: Skill Foundation
1. Create skill directory structure
2. Write SKILL.md with:
   - Input parsing (inline, CPO, config file)
   - Feature type detection
   - Dependency graph builder

### Phase 2: Worktree Integration
3. Integrate with existing `maketree` skill
4. Add batch worktree creation from features
5. Handle branch naming: `feature/{feature-name}`

### Phase 3: Agent Orchestration
6. Implement agent dispatch logic:
   - Parse feature type → select agent
   - Spawn with `run_in_background: true`
   - Track agent IDs for monitoring
7. Create progress monitoring loop
8. Handle agent completion events

### Phase 4: Merge & Integration
9. Implement progressive merge:
   - Per-worktree test validation
   - Merge to integration branch
   - Run integration tests
   - Conflict detection & notification
10. Add final merge to main (with user confirmation)

### Phase 5: CPO Integration
11. Add `--from-cpo` flag support
12. Parse `master-project.json` stages
13. Map stages to features
14. Respect `dependsOn` for parallelization

## Critical Files to Create

| File | Purpose |
|------|---------|
| `skills/parallel-dev/SKILL.md` | Main orchestrator logic |
| `skills/parallel-dev/command.md` | CLI command definition |
| `skills/parallel-dev/references/orchestration.md` | Detailed orchestration patterns |

## Verification

1. **Unit test**: Create a test project with 3 independent features, verify parallel worktree creation
2. **Integration test**: Run full cycle from inline prompt → worktrees → agents → merge
3. **CPO integration test**: Create a CPO plan, then run `/parallel-dev --from-cpo`
4. **Conflict test**: Introduce deliberate conflict, verify pause & notification

## Open Questions Resolved

- **Agent selection**: Adaptive based on feature `type` field
- **Merge strategy**: Progressive with integration branch
- **Input format**: Both inline and CPO integration supported
- **Worktree management**: Leverages existing `maketree` skill
