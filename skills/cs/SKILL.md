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

| Target     | Destination                              | Method | Type                                     |
| ---------- | ---------------------------------------- | ------ | ---------------------------------------- |
| **origin** | escotilha/claude (private)               | git    | Full push (all content)                  |
| **public** | escotilha/claude-public (public)         | git    | Filtered push (excluded content removed) |
| **nuvini** | Nuvinigroup/claude (public)              | git    | Filtered push (excluded content removed) |
| **VPS**    | VPS ~/.claude-setup/ (via Tailscale SSH) | git    | `git pull` (symlinked into ~/.claude/)   |

## Process

### Phase 1: Commit local changes (on master)

1. Check for uncommitted changes on master
2. If changes exist: `git add -A && git commit -m "auto: sync claude-setup"`
3. Fetch from origin to check sync status

### Phase 2: Push to origin (private — full content)

1. Compare local HEAD with `origin/master`
2. If ahead, push using the SSH/HTTPS fallback pattern:
   - Test SSH first: `ssh -T git@github.com 2>&1`
   - If SSH succeeds (output contains "Hi "): `git push origin master`
   - If SSH fails: unset `GITHUB_TOKEN` env var (known invalid token that overrides valid keyring), temporarily rewrite the `origin` remote URL from SSH to HTTPS (`https://github.com/escotilha/claude.git`), push, then restore the original SSH URL
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
4. Force-push to both public remotes using the SSH/HTTPS fallback pattern:
   - Test SSH first: `ssh -T git@github.com 2>&1`
   - If SSH succeeds: push directly
     - `git push public nuvini-public:main --force`
     - `git push nuvini nuvini-public:master --force`
   - If SSH fails: unset `GITHUB_TOKEN`, temporarily rewrite each remote URL to HTTPS, push, then restore SSH URLs:
     - `public` → `https://github.com/escotilha/claude-public.git`
     - `nuvini` → `https://github.com/Nuvinigroup/claude.git`
5. Switch back to master

### Phase 4: Sync to VPS via git pull

The VPS has a clone of `escotilha/claude` at `~/.claude-setup/`. The synced directories (`skills/`, `agents/`, `rules/`, `tools/`, `hooks/`, `memory/auto/`) are symlinked from `~/.claude/` into this git checkout.

**Connection**: SSH to VPS via Tailscale (see `reference_vps_connection` memory for current IP/hostname)

**Pre-flight**: Check VPS is reachable with a quick SSH test. If unreachable, skip this phase and report "VPS offline".

**Sync command**:

```bash
ssh <VPS_TAILSCALE_IP> "cd ~/.claude-setup && git pull origin master"
```

> Note: Resolve the actual VPS Tailscale IP from the `reference_vps_connection` memory at runtime. Never hardcode IPs in this file.

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

## Git Auth Fallback

The remotes `public` and `nuvini` (and `origin`) use SSH URLs (`git@github.com:...`). If the local SSH key is not registered on GitHub, pushes will fail silently or with a "Permission denied" error.

The `gh` CLI has a valid HTTPS keyring token (account `escotilha`), but the `GITHUB_TOKEN` env var may be set to an **invalid value** that overrides the keyring credential — causing HTTPS pushes to also fail.

**Fallback procedure (applied in Phase 2 and Phase 3):**

```bash
# 1. Test SSH
ssh_result=$(ssh -T git@github.com 2>&1)

if echo "$ssh_result" | grep -q "Hi "; then
  # SSH works — push normally
  git push <remote> <refspec>
else
  # SSH broken — fall back to HTTPS with keyring token
  unset GITHUB_TOKEN                          # remove invalid token override
  original_url=$(git remote get-url <remote>) # save SSH URL
  git remote set-url <remote> https://github.com/<owner>/<repo>.git
  git push <remote> <refspec>
  git remote set-url <remote> "$original_url" # restore SSH URL
fi
```

This is transparent — the remote URLs on disk remain SSH after the push completes.

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
