---
name: cs
description: Sync Claude setup to all remotes (origin, public, nuvini) + VPS sync via git pull
user-invocable: true
context: fork
model: haiku
effort: low
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: false }
invocation-contexts:
  user-direct:
    verbosity: high
  agent-spawned:
    verbosity: minimal
---

# Claude Setup Sync — All Remotes + VPS

Syncs the local Claude setup repo (`~/.claude-setup`) to all configured remotes and the VPS:

| Target     | Destination                      | Method | Type                                     |
| ---------- | -------------------------------- | ------ | ---------------------------------------- |
| **origin** | escotilha/claude (private)       | git    | Full push (all content)                  |
| **public** | escotilha/claude-public (public) | git    | Filtered push (excluded content removed) |
| **nuvini** | Nuvinigroup/claude (public)      | git    | Filtered push (excluded content removed) |
| **VPS**    | root@vmi3065960:~/.claude-setup/ | git    | `git pull` (symlinked into ~/.claude/)   |

## Process

### Phase 1: Commit local changes (on master)

1. Check for uncommitted changes on master
2. If changes exist: `git add -A && git commit -m "auto: sync claude-setup"`
3. Fetch from origin to check sync status

### Phase 2: Push to origin (private — full content)

1. Compare local HEAD with `origin/master`
2. If ahead: `git push origin master`
3. If behind: report only (manual pull recommended)
4. If diverged: report only

### Phase 3: Push to nuvini (public — filtered)

1. Delete and recreate `nuvini-public` branch from current master HEAD
2. On `nuvini-public`, remove all excluded content per sync rules:

**Excluded skills** (project-specific or internal):

```
qa-conta qa-sourcerank qa-stonegeo virtual-user-testing
oci-health proposal-source chief-geo health-report
cs cpr sc slack agentmail tweet gws
claude-setup-optimizer memory-consolidation meditate test-memory
deploy-conta-staging deploy-conta-production deploy-sourcerank
contably-guardian sourcerank-guardian
pr-impact rex mini-remote nanoclaw computer-use
office-hours primer vibc paperclip paperclip-create-agent
discord loop schedule
```

**Excluded directories**: `memory/ tools/ hooks/ rules/ backups/ config/ launchd/ plans/ guides/ bin/ commands/ mcp-servers/`

**Excluded files**: `settings.json .deep-plan-state.json .gstack/ settings.json.backup* plan.md research.md memory/core-memory.json`

3. Commit removals: `chore: sync nuvini-public with master`
4. Force-push to both public remotes:
   - `git push public nuvini-public:main --force`
   - `git push nuvini nuvini-public:master --force`
5. Switch back to master

### Phase 4: Sync to VPS via git pull

The VPS has a clone of `escotilha/claude` at `~/.claude-setup/`. The synced directories (`skills/`, `agents/`, `rules/`, `tools/`, `hooks/`, `memory/auto/`) are symlinked from `~/.claude/` into this git checkout.

**Connection**: `ssh root@100.77.51.51` (Tailscale IP)

**Pre-flight**: Check VPS is reachable with a quick SSH test. If unreachable, skip this phase and report "VPS offline".

**Sync command**:

```bash
ssh root@100.77.51.51 "cd ~/.claude-setup && git pull origin master"
```

That's it. The symlinks mean the pulled content is immediately live in `~/.claude/`.

**Symlink layout** (VPS `~/.claude/` → `~/.claude-setup/`):

| Symlink                 | Target                        |
| ----------------------- | ----------------------------- |
| `~/.claude/skills`      | `~/.claude-setup/skills`      |
| `~/.claude/agents`      | `~/.claude-setup/agents`      |
| `~/.claude/rules`       | `~/.claude-setup/rules`       |
| `~/.claude/tools`       | `~/.claude-setup/tools`       |
| `~/.claude/hooks`       | `~/.claude-setup/hooks`       |
| `~/.claude/memory/auto` | `~/.claude-setup/memory/auto` |

**Important**: `~/.claude/settings.json` is NOT symlinked — the VPS keeps its own settings with VPS-specific MCP servers and hooks.

### Phase 5: Report

Present results:

- origin status (pushed N commits / up to date / behind)
- public status (force-pushed / up to date)
- nuvini status (force-pushed / up to date)
- VPS status (git pull result / skipped — offline / error)
- Any errors or warnings

## Important Notes

- Always switch back to `master` at the end, even if an error occurs
- The nuvini-public branch is ephemeral — recreated fresh each sync
- Never push rules/, memory/, hooks/, tools/, settings.json, or project-specific skills to public repos
- Both public and nuvini get the same filtered content from the nuvini-public branch
- Note: public uses `main` branch, nuvini uses `master` branch
- Use `git rm -rf --ignore-unmatch` to handle files that may not exist
- Check the exclude list in `rules/nuvini-sync-rules.md` for the authoritative list if available
- VPS sync depends on Phase 2 (origin must be pushed first, since VPS pulls from origin)
- VPS directories (skills, agents, rules, tools, hooks, memory/auto) are symlinks into ~/.claude-setup/ git checkout
- VPS settings.json is NOT symlinked — it has VPS-specific config
- Old rsync'd directories are backed up at ~/.claude/\*.bak-rsync on the VPS
