---
description: Parallel feature development using git worktrees and specialized agents
argument-hint: [--from-cpo | --config <file> | status | merge | clean | resume]
allowed-tools: "*"
---

# Parallel Feature Development

Orchestrates parallel feature development using git worktrees and specialized agents. Can work standalone or integrate with CPO-AI-Skill as the planning brain.

## Commands

- `/parallel-dev` - Start with inline feature definitions
- `/parallel-dev --from-cpo` - Read stages from master-project.json
- `/parallel-dev --config <file>` - Read from config file
- `/parallel-dev status` - Show progress dashboard
- `/parallel-dev merge` - Merge completed features to main
- `/parallel-dev clean` - Remove worktrees and feature branches
- `/parallel-dev resume` - Resume from saved state

## Inline Feature Format

```markdown
/parallel-dev

## Feature: Authentication
type: backend
dependsOn: []
- Add OAuth2 login with Google/GitHub
- Session management with Redis
- JWT token refresh

## Feature: Dashboard UI
type: frontend
dependsOn: [api-endpoints]
- Stats cards with real-time data
- Charts using Recharts
- Dark mode support

## Feature: API Endpoints
type: api
dependsOn: []
- User CRUD endpoints
- Rate limiting middleware
- OpenAPI documentation
```

## How It Works

1. **Pre-flight Verification** - Checks if features already exist before spawning agents
2. **Dependency Graph** - Builds graph, detects cycles, finds parallelizable work
3. **Worktree Creation** - Each feature gets isolated git worktree
4. **Agent Dispatch** - Spawns specialized agents (frontend, backend, api, database, testing, devops)
5. **Progress Monitoring** - Dashboard with status, polls for completion
6. **Progressive Merge** - Merges to integration branch with conflict handling
7. **State Persistence** - Saves to `.parallel-dev-state.json` for resume

## Agent Selection

| Feature Type | Agent |
|--------------|-------|
| frontend, ui | frontend-agent |
| backend | backend-agent |
| api | api-agent |
| database, schema | database-agent |
| testing, e2e | testing-agent |
| devops, deploy | devops-agent |
| unspecified | general-purpose |

## Reference

See full skill documentation at:
`~/.claude-setup/skills/parallel-dev/SKILL.md`
