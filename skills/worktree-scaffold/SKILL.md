---
name: worktree-scaffold
description: Parallel feature development automation using git worktrees with project scaffolding. Use when developers ask to checkout features, create feature workspaces, work on multiple features in parallel, set up worktrees, scaffold new features, list active workspaces, clean up feature branches, or manage parallel development workflows. Triggers on phrases like "checkout feature", "create workspace", "parallel features", "list workspaces", "remove workspace", "init worktree config", or any request involving git worktrees with boilerplate generation.
tools: Bash, Read, Glob, Grep
effort: low
triggers:
  - "checkout feature"
  - "create workspace"
  - "parallel features"
  - "list workspaces"
  - "remove workspace"
  - "init worktree config"
---

# Worktree Scaffold

Automate parallel feature development by combining git worktrees with project scaffolding. Create isolated workspaces with pre-generated boilerplate for each feature.

## Commands

| Pattern | Action |
|---------|--------|
| `checkout feature {name}` | Create single worktree + scaffold |
| `checkout features {a}, {b}, {c}` | Create multiple worktrees + scaffolds |
| `list workspaces` | Show all active worktrees |
| `remove workspace {name}` | Clean up worktree and optionally branch |
| `init worktree config` | Generate `.worktree-scaffold.json` template |

## Workflow

### Creating Feature Workspaces

1. **Validate** feature name (alphanumeric + hyphens only)
2. **Check** if branch exists; create from current HEAD if not
3. **Create worktree** at `{worktreeDir}/{branchPrefix}{name}` (default: `../feature-{name}`)
4. **Run scaffolding** based on `.worktree-scaffold.json` config
5. **Report** success with workspace path and next steps

```bash
# Core git worktree commands used
git worktree add <path> -b <branch>    # Create new branch + worktree
git worktree add <path> <branch>       # Use existing branch
git worktree list                       # List all worktrees
git worktree remove <path>              # Remove worktree
git worktree prune                      # Clean stale entries
```

### Creating a Feature Workspace

```bash
# 1. Validate feature name
if [[ ! "$FEATURE_NAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
  echo "Error: Feature name must be alphanumeric with hyphens only"
  exit 1
fi

# 2. Determine paths from config (or defaults)
WORKTREE_DIR="${CONFIG_WORKTREE_DIR:-../}"
BRANCH_PREFIX="${CONFIG_BRANCH_PREFIX:-feature/}"
BRANCH_NAME="${BRANCH_PREFIX}${FEATURE_NAME}"
WORKTREE_PATH="${WORKTREE_DIR}${FEATURE_NAME}"

# 3. Check if branch exists
if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
  git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
else
  git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
fi

# 4. Run scaffolding in new worktree
cd "$WORKTREE_PATH"
# Apply templates from config...
```

### Scaffold Generation

Read `.worktree-scaffold.json` from project root and generate files:

```bash
# For each scaffold entry:
# 1. Resolve template path with variable substitution
# 2. Get template content
# 3. Apply variable substitution to content
# 4. Write file to worktree
```

**Variable Substitution:**

| Variable | Input Example | Output |
|----------|---------------|--------|
| `{name}` | user-auth | user-auth |
| `{Name}` | user-auth | UserAuth (PascalCase) |
| `{NAME}` | user-auth | USER_AUTH (SCREAMING_SNAKE) |
| `{date}` | — | 2026-01-13 |
| `{author}` | — | `git config user.name` |

### Listing Workspaces

```bash
git worktree list --porcelain | while read -r line; do
  # Parse worktree path, branch, HEAD
  # Show: path | branch | last modified | status
done
```

### Removing Workspaces

```bash
# 1. Check for uncommitted changes
cd "$WORKTREE_PATH" && git status --porcelain
# 2. Warn if dirty, require --force or confirmation
# 3. Remove worktree
git worktree remove "$WORKTREE_PATH"
# 4. Optionally delete branch
git branch -d "$BRANCH_NAME"  # -D if not merged
# 5. Prune stale entries
git worktree prune
```

## Configuration

Create `.worktree-scaffold.json` in project root. Use `assets/worktree-scaffold.template.json` as a starting point:

```json
{
  "worktreeDir": "../",
  "branchPrefix": "feature/",
  "scaffolds": {
    "default": [
      { "path": "src/features/{name}/index.ts", "template": "feature-index" },
      { "path": "src/features/{name}/types.ts", "template": "feature-types" },
      { "path": "src/features/{name}/__tests__/{name}.test.ts", "template": "feature-test" }
    ],
    "component": [
      { "path": "src/components/{Name}/{Name}.tsx", "template": "react-component" },
      { "path": "src/components/{Name}/{Name}.test.tsx", "template": "component-test" },
      { "path": "src/components/{Name}/index.ts", "template": "component-index" }
    ],
    "api": [
      { "path": "src/api/{name}/route.ts", "template": "api-route" },
      { "path": "src/api/{name}/handler.ts", "template": "api-handler" }
    ]
  },
  "templates": {
    "feature-index": "// {Name} Feature\n// Created: {date} by {author}\n\nexport * from './types';\n",
    "feature-types": "export interface {Name}Props {\n  // TODO: Define props\n}\n\nexport interface {Name}State {\n  // TODO: Define state\n}\n",
    "feature-test": "import { describe, it, expect } from 'vitest';\n\ndescribe('{Name}', () => {\n  it('should work', () => {\n    expect(true).toBe(true);\n  });\n});\n"
  },
  "hooks": {
    "postScaffold": "npm install"
  }
}
```

### Config Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `worktreeDir` | string | `"../"` | Directory for worktrees relative to repo |
| `branchPrefix` | string | `"feature/"` | Prefix for branch names |
| `scaffolds` | object | `{}` | Named scaffold sets |
| `scaffolds.default` | array | `[]` | Default scaffold files |
| `templates` | object | `{}` | Template content by name |
| `hooks.postScaffold` | string | — | Command to run after scaffolding |

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| "Worktree already exists" | Path in use | Use different name or remove existing |
| "Branch already exists" | Branch created elsewhere | Will use existing branch |
| "Cannot remove worktree" | Uncommitted changes | Commit/stash changes or use --force |
| "Not a git repository" | Not in git repo | Initialize git or cd to repo |

## Requirements

- Git 2.20+ (worktree improvements)
- Bash 4.0+ or zsh
- jq (JSON processor for config parsing)
- Node.js projects: npm/yarn/pnpm
- Python projects: pip/poetry

## Examples

**Single feature:**
```
User: checkout feature user-auth
→ Creates ../user-auth with feature/user-auth branch + scaffolding
```

**Multiple features:**
```
User: checkout features payment-flow, email-notifications, dark-mode
→ Creates 3 worktrees in parallel, reports summary
```

**List workspaces:**
```
User: list workspaces
→ Shows table of active worktrees with paths and status
```

**Cleanup:**
```
User: remove workspace user-auth
→ Warns if uncommitted changes, removes worktree, optionally deletes branch
```
