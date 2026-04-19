# Iteration Support

Post-launch iteration and sprint support for ongoing product development.

## Overview

The CPO workflow doesn't end at v1.0. Products evolve through iterations, adding features, fixing bugs, and responding to user feedback. This reference covers post-launch development workflows.

## Iteration Philosophy

### MVP First, Iterate Based on Feedback

- Launch with core features (MVP)
- Gather real user feedback
- Prioritize next features based on data
- Avoid feature bloat - say no to low-value requests

### Feature Flags for Gradual Rollout

- Deploy code with features disabled
- Enable for internal testing first
- Gradual rollout to user segments
- Quick rollback if issues arise

### Semantic Versioning

Follow semver (MAJOR.MINOR.PATCH):

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Bug fixes, patches | PATCH | 1.0.0 → 1.0.1 |
| New features (backward compatible) | MINOR | 1.0.0 → 1.1.0 |
| Breaking changes | MAJOR | 1.0.0 → 2.0.0 |

## The `/cpo-iterate` Command

### Syntax

```bash
/cpo-iterate <project-path> <feature-description>
```

### Examples

```bash
/cpo-iterate ./taskflow "add team collaboration features"
/cpo-iterate ./ecommerce "implement payment processing"
/cpo-iterate ./blog "add comment moderation"
```

### What It Does

1. Loads existing `master-project.json`
2. Creates iteration branch (e.g., `iteration/v1.1-collaboration`)
3. Adds new epic(s) to the project
4. Runs mini-discovery for the new feature
5. Generates stages for the new epic
6. Implements stages incrementally
7. Tests new + existing features (regression testing)
8. Updates version number
9. Updates changelog
10. Ready for deployment

## Iteration Workflow

```
Existing Product (v1.0.0)
        │
        ▼
/cpo-iterate "new feature"
        │
        ├── Load master-project.json
        ├── Create branch: iteration/v1.1-feature-name
        ├── Add Epic to existing project
        ├── Run mini-discovery for feature
        ├── Generate stages for new epic
        ├── Implement stages
        ├── Test new + existing features
        ├── Update version to 1.1.0
        ├── Deploy
        └── Update changelog
```

### Discovery for Iterations

Iteration discovery is faster and more focused:

**Questions:**
1. How does this feature integrate with existing functionality?
2. Are there breaking changes to existing APIs or UIs?
3. What database migrations are needed?
4. Will this require new environment variables?
5. Is this a major, minor, or patch release?
6. Should this be behind a feature flag?

## Feature Flags Integration

### When to Use Feature Flags

The CTO Advisor recommends feature flags for:

- Significant new features (not small bug fixes)
- Enterprise scope products
- Features requiring gradual rollout
- Experimental features that might be removed
- A/B testing scenarios

### Implementation

```typescript
// lib/feature-flags.ts
export const FEATURES = {
  TEAM_COLLABORATION: process.env.NEXT_PUBLIC_FEATURE_TEAM_COLLABORATION === 'true',
  DARK_MODE: process.env.NEXT_PUBLIC_FEATURE_DARK_MODE === 'true',
  AI_SUGGESTIONS: process.env.NEXT_PUBLIC_FEATURE_AI_SUGGESTIONS === 'true',
  ADVANCED_ANALYTICS: process.env.NEXT_PUBLIC_FEATURE_ANALYTICS === 'true',
} as const;

export type FeatureFlag = keyof typeof FEATURES;

export function isFeatureEnabled(flag: FeatureFlag): boolean {
  return FEATURES[flag] ?? false;
}
```

### Usage in Components

```typescript
import { FEATURES } from '@/lib/feature-flags';

export function TaskList() {
  return (
    <div>
      <Tasks />
      {FEATURES.TEAM_COLLABORATION && (
        <TeamPanel />
      )}
      {FEATURES.ADVANCED_ANALYTICS && (
        <AnalyticsDashboard />
      )}
    </div>
  );
}
```

### Usage in API Routes

```typescript
import { isFeatureEnabled } from '@/lib/feature-flags';

export async function POST(req: Request) {
  if (isFeatureEnabled('TEAM_COLLABORATION')) {
    // New team collaboration logic
  } else {
    // Fallback to single-user mode
  }
}
```

### Environment Variables

```bash
# .env.local
NEXT_PUBLIC_FEATURE_TEAM_COLLABORATION=true
NEXT_PUBLIC_FEATURE_DARK_MODE=false
NEXT_PUBLIC_FEATURE_AI_SUGGESTIONS=true
```

For production gradual rollout:
- Start with `false` for all users
- Enable for internal users first
- Enable for 10% of users, then 50%, then 100%
- Use feature flag service (LaunchDarkly, Flagsmith) for advanced rollouts

## Version Management

### Auto-Bump Version

Add to master-project.json:

```typescript
function bumpVersion(current: string, type: 'major' | 'minor' | 'patch'): string {
  const [major, minor, patch] = current.split('.').map(Number);

  switch (type) {
    case 'major':
      return `${major + 1}.0.0`;
    case 'minor':
      return `${major}.${minor + 1}.0`;
    case 'patch':
      return `${major}.${minor}.${patch + 1}`;
  }
}
```

### Determining Version Bump Type

CPO analyzes changes:

- **Major (2.0.0)**: Breaking API changes, major UI overhaul, removed features
- **Minor (1.1.0)**: New features, new endpoints, new UI sections (backward compatible)
- **Patch (1.0.1)**: Bug fixes, performance improvements, typo fixes

## Changelog Generation

Auto-generate `CHANGELOG.md` based on epics and stages:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-02-10

### Added
- Dark mode support across all pages (Epic E6)
- User preference persistence for theme
- Theme toggle in navigation

### Changed
- Updated color palette for better contrast
- Improved accessibility scores to AAA standard

## [1.1.0] - 2025-01-26

### Added
- Team collaboration features (Epic E5)
- Real-time task updates via WebSocket
- Team member mentions in task comments
- Team dashboard with activity feed

### Changed
- Task list now shows assignee avatars
- Dashboard redesigned for multi-user view

### Fixed
- Task ordering bug on mobile devices
- Race condition in task update handler

## [1.0.1] - 2025-01-22

### Fixed
- Login redirect loop on expired sessions
- Missing error handling in task creation

## [1.0.0] - 2025-01-20

### Added
- Initial release
- User authentication with NextAuth.js
- Task CRUD operations
- Personal dashboard
- Task filtering and sorting
```

### Changelog Template per Epic

```markdown
## [VERSION] - DATE

### Added
- [Feature description] (Epic E#)
  - Specific capability 1
  - Specific capability 2

### Changed
- [What was modified]

### Fixed
- [Bug that was resolved]

### Deprecated
- [Features marked for removal]

### Removed
- [Features removed]

### Security
- [Security improvements]
```

## Iteration Planning Template

When starting a new iteration, CPO generates:

```markdown
## Iteration Plan: v1.1.0 - Team Collaboration

**Base Version:** 1.0.0
**Target Version:** 1.1.0
**Branch:** iteration/v1.1-team-collaboration
**Estimated Duration:** 2-3 weeks

### New Epic

| Epic | Description | Stages | Priority |
|------|-------------|--------|----------|
| E5: Team Collaboration | Enable multiple users to collaborate on tasks | 4 | P1 |

**Stages:**
1. Multi-user auth and team model
2. Real-time updates (WebSocket)
3. Team dashboard
4. Testing and polish

### Impact on Existing Features

- **Authentication**: Modified - now supports team invites
- **Task model**: Modified - added assignee field
- **Dashboard**: Modified - team view vs personal view
- **Task creation**: No change

### Migration Required

- [x] Database migration needed
  - Add `teamId` to users table
  - Add `teams` table
  - Add `assigneeId` to tasks table
- [x] Environment variable changes
  - Add `PUSHER_APP_ID`, `PUSHER_KEY`, `PUSHER_SECRET` for real-time
- [ ] Breaking API changes

### Testing Strategy

- [x] New feature tests
  - Team creation/invitation flow
  - Real-time update synchronization
  - Team dashboard rendering
- [x] Regression tests for existing features
  - Single-user mode still works
  - Task CRUD unaffected
  - Auth flow still secure
- [x] E2E tests updated
  - Add team collaboration scenarios

### Rollout Plan

1. Deploy with `FEATURE_TEAM_COLLABORATION=false`
2. Enable for internal testing (3 days)
3. Enable for beta users (1 week)
4. Full rollout to all users
```

## Integration with master-project.json

Add iteration tracking to master-project.json:

```json
{
  "project": {
    "name": "TaskFlow",
    "version": "1.1.0",
    "description": "Team task management application",
    "iterations": [
      {
        "version": "1.0.0",
        "releasedAt": "2025-01-20T00:00:00Z",
        "epics": ["E1", "E2", "E3", "E4"],
        "changelogUrl": "/CHANGELOG.md#100"
      },
      {
        "version": "1.1.0",
        "startedAt": "2025-01-25T00:00:00Z",
        "epics": ["E5"],
        "status": "in_progress",
        "estimatedCompletion": "2025-02-03T00:00:00Z"
      }
    ]
  },
  "epics": [
    {
      "id": "E1",
      "title": "User Authentication",
      "status": "completed",
      "iteration": "1.0.0"
    },
    {
      "id": "E5",
      "title": "Team Collaboration",
      "status": "in_progress",
      "iteration": "1.1.0"
    }
  ]
}
```

## Sprint Support (Optional)

For teams using Agile sprints, CPO can track sprint metadata:

```json
{
  "sprints": {
    "enabled": true,
    "duration": 14,
    "current": {
      "number": 3,
      "startDate": "2025-01-27",
      "endDate": "2025-02-10",
      "goals": [
        "Complete E5: Team Collaboration",
        "Fix critical bugs from v1.0"
      ],
      "plannedStories": ["S5.1", "S5.2", "S5.3", "S5.4"],
      "velocity": null
    },
    "history": [
      {
        "number": 1,
        "startDate": "2025-01-01",
        "endDate": "2025-01-14",
        "completedStories": ["S1.1", "S1.2", "S2.1"],
        "velocity": 13
      },
      {
        "number": 2,
        "startDate": "2025-01-15",
        "endDate": "2025-01-28",
        "completedStories": ["S3.1", "S3.2", "S4.1"],
        "velocity": 15
      }
    ]
  }
}
```

### Sprint Velocity Tracking

CPO calculates velocity automatically:
- Sum story points completed per sprint
- Track average velocity over last 3 sprints
- Use for capacity planning

## Best Practices

### Iteration Sizing

- **Small iterations**: 1-2 weeks, 1 epic, faster feedback
- **Medium iterations**: 2-4 weeks, 2-3 epics, more substantial
- **Large iterations**: 4+ weeks, multiple epics (avoid - too risky)

Recommendation: 2-week iterations with 1-2 focused epics.

### Backward Compatibility

- Maintain API backward compatibility in minor versions
- Use feature flags to hide incomplete features
- Database migrations should be reversible
- Document breaking changes clearly

### Testing During Iterations

1. **Unit tests**: Test new code
2. **Integration tests**: Test new + existing integrations
3. **Regression tests**: Ensure old features still work
4. **E2E tests**: Critical user flows unaffected

CPO runs full test suite before version bump.

### Communication

After each iteration:
- Update changelog
- Write release notes for users
- Notify team of new features
- Document any migration steps

## Example: Full Iteration Flow

```bash
# Current state: TaskFlow v1.0.0 deployed

# Product owner requests new feature
/cpo-iterate ./taskflow "add team collaboration"

# CPO workflow:
# 1. Load master-project.json (v1.0.0)
# 2. Create branch: iteration/v1.1-team-collaboration
# 3. Run discovery:
#    - Integration with existing features? Yes, auth and tasks
#    - Breaking changes? No
#    - Database migration? Yes (team tables)
#    - Feature flag? Yes (gradual rollout)
#    - Version bump? Minor (1.1.0)
# 4. Add Epic E5: Team Collaboration
# 5. Generate 4 stages
# 6. Implement each stage with testing
# 7. Update version to 1.1.0
# 8. Generate changelog entry
# 9. Ready to deploy

# Result:
# - New feature implemented
# - Tests passing (new + regression)
# - Changelog updated
# - Feature flag in place
# - Ready for gradual rollout
```

## Summary

Iterations keep products evolving without chaos:

- **Structured**: Same workflow as initial build
- **Safe**: Feature flags and regression testing
- **Versioned**: Clear semantic versioning
- **Documented**: Auto-generated changelogs
- **Tested**: Full test coverage maintained

Use `/cpo-iterate` to add features systematically while maintaining production stability.
