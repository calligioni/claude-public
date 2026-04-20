# Autonomous Agent Examples

## Story Splitting Patterns

### Too Big -> Split Into
| Original | Split Into |
|----------|-----------|
| Build entire dashboard | 1. Create layout, 2. Add nav, 3. Build each widget |
| Add authentication | 1. User model, 2. Login endpoint, 3. Session handling, 4. UI |
| Refactor API | 1. Extract types, 2. Update endpoint X, 3. Update endpoint Y |

## Acceptance Criteria Templates

### API Endpoint
```markdown
- [ ] Endpoint responds with correct status codes
- [ ] Request validation works
- [ ] Response matches schema
- [ ] Typecheck passes
- [ ] Tests pass
```

### UI Component
```markdown
- [ ] Component renders correctly
- [ ] Props are typed
- [ ] Responsive on mobile/desktop
- [ ] Accessibility: keyboard nav, ARIA
- [ ] Typecheck passes
```

### Database Migration
```markdown
- [ ] Migration runs successfully
- [ ] Rollback works
- [ ] Existing data preserved
- [ ] Indexes added for query patterns
```

## Complete prd.json Example

```json
{
  "project": "Task Management App",
  "branchName": "feature/task-filtering",
  "description": "Add ability to filter tasks by status, date, and assignee",
  "createdAt": "2025-01-10T10:00:00Z",
  "verification": {
    "typecheck": "npm run typecheck",
    "test": "npm run test",
    "lint": "npm run lint"
  },
  "userStories": [
    {
      "id": "US-001",
      "title": "Add filter dropdown component",
      "description": "As a user, I want a filter dropdown so I can select filter criteria",
      "acceptanceCriteria": [
        "Dropdown opens on click",
        "Shows status, date, assignee options",
        "Typecheck passes"
      ],
      "priority": 1,
      "dependsOn": [],
      "passes": false,
      "attempts": 0,
      "notes": ""
    }
  ]
}
```

## progress.md Format

```markdown
# Progress Log: Task Filtering

Branch: `feature/task-filtering`
Started: 2025-01-10

---

## 2025-01-10 10:30 - US-001: Add filter dropdown component

**Implementation:**
- Created FilterDropdown component in src/components/
- Used Radix UI Popover for dropdown
- Added filter icon button to toolbar

**Learnings:**
- Existing Button component accepts icon prop
- Toolbar has specific spacing requirements (gap-2)

**Files Changed:**
- src/components/FilterDropdown.tsx (new)
- src/components/Toolbar.tsx (modified)

---
```
