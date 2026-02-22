---
name: maketree
description: Create and manage git worktrees via native Claude CLI flag or config-driven bulk setups.
user-invocable: true
context: fork
model: haiku
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - AskUserQuestion
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: false }
---

# Maketree - Worktree Manager

Create git worktrees for parallel development. Use the native `claude --worktree` flag for most cases, or this skill for batch/config-driven setups.

## Quick Start (Recommended)

Use the native Claude CLI flag for single worktrees:

```bash
claude --worktree                 # Auto-named worktree
claude --worktree feature-name    # Named worktree
claude --worktree feature-name --tmux  # With terminal isolation
```

## Skill Commands (Config-Driven)

- `/maketree` - Detect local config or run discovery, then create worktrees
- `/maketree list` - List all active worktrees
- `/maketree clean` - Remove all feature worktrees (keeps main repo)
- `/maketree discover` - Force re-discovery even if config exists

## When to Use This Skill

Use `/maketree` commands for:

- **Bulk setup**: Creating multiple worktrees at once from config
- **Repeated workflows**: Saving branch discovery preferences for your team
- **Complex projects**: Managing many feature branches with a single command

For single worktrees or quick exploration, prefer the native `claude --worktree` flag above.

## Config-Driven Workflow

This skill automatically:

1. Checks for local `.worktree-scaffold.json` configuration
2. If no config exists, discovers feature branches and recommends worktrees
3. Presents a numbered table for user selection
4. Saves preferences to `.worktree-scaffold.json`
5. Creates worktrees for selected branches

### Discovery Flow

When run in a project without configuration:

```
Discovered Feature Branches:
| #  | Name              | Branch                  | Path                    |
|----|-------------------|-------------------------|-------------------------|
| 1  | user-auth         | feature/user-auth       | ../user-auth            |
| 2  | payment-flow      | feature/payment-flow    | ../payment-flow         |
| 3  | dark-mode         | fix/dark-mode           | ../dark-mode            |

Enter selection: all, numbers (1,2,3), or skip
```

## Configuration

The skill uses `.worktree-scaffold.json` in the project root:

```json
{
  "worktreeDir": "../",
  "branchPrefix": "feature/",
  "worktrees": [
    { "name": "user-auth", "branch": "feature/user-auth" },
    { "name": "payment-flow", "branch": "feature/payment-flow" }
  ]
}
```

### Config Fields

| Field          | Type   | Default      | Description                              |
| -------------- | ------ | ------------ | ---------------------------------------- |
| `worktreeDir`  | string | `"../"`      | Directory for worktrees relative to repo |
| `branchPrefix` | string | `"feature/"` | Default prefix for new branches          |
| `worktrees`    | array  | `[]`         | Saved worktree selections from discovery |

## Directory Structure

After running `/maketree`:

```
/path/to/projects/
├── my-project/           # Main repository (main branch)
├── user-auth/            # feature/user-auth worktree
├── payment-flow/         # feature/payment-flow worktree
└── dark-mode/            # fix/dark-mode worktree
```

## Requirements

- Git 2.20+ with worktree support
- Must be run from within a git repository
- Write access to parent directory for worktree creation

## Benefits

- **Parallel Development**: Work on multiple features simultaneously
- **Branch Isolation**: Each feature has its own clean workspace
- **Fast Switching**: No need to stash/commit when switching features
- **Project Agnostic**: Works with any git repository
- **Persistent Config**: Saves preferences for quick re-creation

## Example Output

```
Existing config found. Creating worktrees...

Created Worktrees:
✓ user-auth               /path/to/projects/user-auth
✓ payment-flow            /path/to/projects/payment-flow

Already Existed:
• dark-mode               /path/to/projects/dark-mode

Terminal Commands:
cd /path/to/projects/user-auth
cd /path/to/projects/payment-flow
cd /path/to/projects/dark-mode
```

## Notes

- Each worktree is a full working directory with its own checkout
- `.git` directory is shared (repository data shared, working trees are not)
- Changes, commits, and branches are visible across all worktrees
- Deleting a worktree doesn't delete the branch
- Run `/maketree discover` to re-scan branches and update config
