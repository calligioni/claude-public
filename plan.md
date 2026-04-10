# Plan: Mac <-> Mac Mini Parity

**Date:** 2026-04-10
**Based on:** research.md
**Estimated files to change:** 7
**Scope:** Mac Mini only. No VPS. No GBrain.

## Approach

Bring the Mac Mini to functional parity with the MacBook Air for Claude Code by installing missing runtimes (Node.js via nvm), building the shared memory-turso MCP server, installing missing binary tools (browse, qmd), fixing the one hardcoded `/Users/ps/` path in settings.json, and correcting the iCloud Keychain sync claims in setup scripts. All work is done via SSH to Mini (`ssh mini`, user `psm2`). After this, Claude Code on Mini will have working MCP memory (shared Turso cloud DB), working binary tools, and accurate setup documentation.

## Trade-offs Considered

| Option               | Pros                                          | Cons                                      | Verdict      |
| -------------------- | --------------------------------------------- | ----------------------------------------- | ------------ |
| nvm for Node.js      | Version management, no sudo, widely supported | Adds `.nvm` directory, needs shell config | **Selected** |
| Homebrew for Node.js | Consistent with Mac primary                   | Homebrew not installed on Mini, heavier   | Rejected     |
| Direct node tarball  | No extra tooling                              | Manual updates, no version switching      | Rejected     |

| Option                              | Pros                            | Cons                             | Verdict                          |
| ----------------------------------- | ------------------------------- | -------------------------------- | -------------------------------- |
| Copy browse binary from Mac to Mini | Both are arm64 macOS, same arch | Binary may have dylib deps       | **Selected** (verify deps first) |
| Build browse from source on Mini    | Guaranteed clean build          | Needs full build toolchain, slow | Fallback if copy fails           |

| Option                        | Pros                  | Cons                                   | Verdict                                       |
| ----------------------------- | --------------------- | -------------------------------------- | --------------------------------------------- |
| Use `$HOME` in officecli path | Portable across users | `$HOME` may not expand in all contexts | **Selected** (works in settings.json for MCP) |
| Use `~` in officecli path     | Shorter               | `~` does NOT expand in JSON values     | Rejected                                      |
| Detect user at runtime        | Most robust           | Overengineered for 1 path              | Rejected                                      |

## Implementation Steps

### Step 1: Install nvm + Node.js on Mac Mini

**Target:** Mac Mini via `ssh mini`
**What:** Install nvm, then install Node.js LTS (v22). This unblocks all npx-based MCP servers.
**Why:** Mini has zero Node.js tooling. The memory-turso MCP server, and any npx-based MCP servers in settings.json, all require `node`.

**Commands to run via SSH:**

```bash
# SSH to Mini
ssh mini

# Install nvm (latest from GitHub)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Source nvm immediately (it modifies .zshrc)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install Node.js LTS (v22)
nvm install 22

# Verify
node --version   # expect v22.x.x
npm --version    # expect 10.x.x
npx --version    # expect 10.x.x
```

**Verification:** `ssh mini 'source ~/.nvm/nvm.sh && node --version'` returns `v22.x.x`

---

### Step 2: Build memory-turso MCP server on Mini

**Target:** Mac Mini via `ssh mini`
**What:** Run `npm install && npm run build` in `~/.claude-setup/mcp-servers/memory-turso/`. This builds the TypeScript MCP server that connects to the shared Turso cloud DB.
**Why:** settings.json already has the memory-turso config with Turso URL + auth token (via symlink from git). The only blocker was missing Node.js (fixed in Step 1). After this, Claude Code on Mini will share the same knowledge graph as Mac.

**Commands to run via SSH:**

```bash
ssh mini

# Source nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Build memory-turso
cd ~/.claude-setup/mcp-servers/memory-turso
npm install
npm run build

# Verify the built artifact exists
ls -la dist/index.js
# Expected: dist/index.js exists

# Quick smoke test - server should start and exit cleanly when no stdio connected
timeout 3 node dist/index.js 2>&1 || true
# (It will error or hang since it expects MCP stdio protocol - that's fine,
#  we just want to confirm it doesn't crash on missing deps)
```

**Verification:** `ls ~/.claude-setup/mcp-servers/memory-turso/dist/index.js` exists on Mini.

---

### Step 3: Install missing binary tools on Mini (browse, qmd)

**Target:** Mac Mini via `ssh mini`
**What:** Install `browse` CLI and `qmd` CLI on Mini.
**Why:** Multiple skills depend on these binaries. Mini currently has neither.

#### 3a: Install browse CLI

The `browse` binary on Mac is a Mach-O arm64 executable at `~/.local/lib/browse/dist/browse`, symlinked from `~/.local/bin/browse`. Since Mini is also arm64 macOS, we can try copying the binary. If it has dynamic library dependencies that are missing on Mini, we fall back to building from source.

```bash
# From Mac (local), copy the browse directory to Mini
scp -r ~/.local/lib/browse mini:~/.local/lib/browse

# SSH to Mini and set up the symlink
ssh mini 'mkdir -p ~/.local/bin && ln -sf ~/.local/lib/browse/dist/browse ~/.local/bin/browse'

# Verify it runs
ssh mini '~/.local/bin/browse --version 2>&1 || ~/.local/bin/browse --help 2>&1 | head -3'

# If it fails with dylib errors, build from source instead:
# ssh mini 'cd ~/.local/lib/browse && npm install && npm run build'
```

**Verification:** `ssh mini '~/.local/bin/browse --help'` produces output (not "command not found" or dylib error).

#### 3b: Install qmd CLI

On Mac, `qmd` is installed via npm globally at `/opt/homebrew/bin/qmd` -> `/opt/homebrew/lib/node_modules/@tobilu/qmd/bin/qmd`. Now that Mini has Node.js (Step 1), we can install it via npm.

```bash
ssh mini

# Source nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install qmd globally
npm install -g @tobilu/qmd

# Verify
qmd --version 2>&1 || qmd --help 2>&1 | head -3
```

**Verification:** `ssh mini 'source ~/.nvm/nvm.sh && qmd --help'` produces output.

---

### Step 4: Fix hardcoded `/Users/ps/` path in settings.json

**File:** `/Users/ps/code/claude-setup/settings.json`
**What:** Replace the hardcoded `/Users/ps/.local/bin/officecli` with `$HOME/.local/bin/officecli` in the `mcpServers.officecli.command` field.
**Why:** Mini's user is `psm2`, not `ps`. The path `/Users/ps/.local/bin/officecli` does not exist on Mini. Since settings.json is symlinked to the same file on both machines, the path must be portable. Claude Code expands `$HOME` in settings.json command fields (confirmed by the memory-turso config which already uses `$HOME`).

**Current (line 465):**

```json
"command": "/Users/ps/.local/bin/officecli",
```

**New:**

```json
"command": "$HOME/.local/bin/officecli",
```

**Verification:** After edit, grep settings.json for `/Users/ps/` should return zero results. The memory-turso entry already uses `$HOME` successfully, confirming this pattern works.

---

### Step 5: Fix iCloud Keychain sync claims in setup scripts

**Files to edit:**

- `setup-new-machine.sh` (11 iCloud references)
- `setup-mac.sh` (7 iCloud references)
- `setup-claude.sh` (6 iCloud references)
- `hooks/load-secrets.sh` (1 iCloud reference)
- `hooks/setup-keychain.sh` (2 iCloud references)
- `install.sh` (2 iCloud references)

**What:** Replace all incorrect claims that secrets/configs "sync via iCloud" or "sync via iCloud Keychain" with accurate descriptions. The reality is:

1. Config syncs via **git** (GitHub repo + LaunchAgent auto-pull), not iCloud
2. macOS Keychain generic passwords do **NOT** sync via iCloud Keychain (only Safari passwords and passkeys sync)
3. API keys are actually provided via `settings.json` env block (hardcoded in the git-synced file), not Keychain

**Changes per file:**

#### `setup-new-machine.sh`

- Header comment: "iCloud-synced configs" -> "git-synced configs"
- "iCloud Keychain" prereqs -> remove, replace with "git repo must be cloned"
- "iCloud claude-setup folder" -> "claude-setup git repo"
- "Creating symlinks to iCloud configs" -> "Creating symlinks to git-synced configs"
- "Secrets sync automatically via iCloud Keychain" -> "Secrets are provided via settings.json env block"
- "iCloud Keychain is enabled" -> remove iCloud claim, note that Keychain is local-only
- "synced via iCloud" final message -> "synced via git"
- "Secrets via iCloud Keychain" -> "Secrets (via settings.json env block)"

#### `setup-mac.sh`

- Title: "iCloud Setup" -> "Git-Synced Setup"
- "iCloud folder" check -> "git repo" check
- "Found iCloud setup" -> "Found claude-setup repo"
- "synced via iCloud" -> "synced via git"
- "iCloud Drive is enabled" -> "git repo is cloned"
- "Copying settings.json from iCloud" -> "Copying settings.json from repo"

#### `setup-claude.sh`

- Title: "iCloud Setup" -> "Git-Synced Setup"
- "macOS only (requires iCloud)" -> "macOS setup"
- "iCloud claude-setup directory" -> "claude-setup git repo"
- "iCloud Drive is enabled and synced" -> "git repo is cloned at ~/.claude-setup"
- "synced via iCloud" -> "synced via git"

#### `hooks/load-secrets.sh`

- Comment line 3: "sync across Macs via iCloud Keychain" -> "stored locally per machine (do NOT sync via iCloud)"

#### `hooks/setup-keychain.sh`

- Comment line 3: "secrets will sync via iCloud Keychain" -> "secrets are stored locally in this machine's Keychain (they do NOT sync via iCloud)"
- Line 68: "sync to your other Macs via iCloud Keychain" -> "stored securely in this machine's Keychain"
- Line 131: "sync to your other Macs via iCloud Keychain" -> "stored in this machine's Keychain only"

#### `install.sh`

- Line 167: "syncs via iCloud Keychain" -> "stored locally in macOS Keychain"
- Line 203: "Secrets sync to other Macs via iCloud Keychain automatically." -> "Secrets are stored locally. For other machines, add keys to settings.json env block or run setup-keychain.sh on each machine."

**Verification:** `grep -ri "icloud" setup-new-machine.sh setup-mac.sh setup-claude.sh hooks/load-secrets.sh hooks/setup-keychain.sh install.sh` returns zero results after all edits.

---

### Step 6: Rebuild mem-search index on Mini

**Target:** Mac Mini via `ssh mini`
**What:** Run `mem-search --reindex` to rebuild the FTS5 search index from current `.md` files.
**Why:** Mini's index is slightly stale (217,088 bytes vs Mac's 229,376 bytes). After git pull brings the latest `.md` files, reindexing ensures parity.

```bash
ssh mini '~/.claude-setup/tools/mem-search --reindex'
```

**Verification:** `ssh mini 'ls -la ~/.claude-setup/tools/mem-search.db'` shows updated timestamp and size closer to Mac's.

---

## Files to Create

| File   | Purpose                           |
| ------ | --------------------------------- |
| (none) | All changes are to existing files |

## Files to Modify

| File                      | Change                                                  | Lines |
| ------------------------- | ------------------------------------------------------- | ----- |
| `settings.json`           | Replace `/Users/ps/` with `$HOME/` in officecli command | ~1    |
| `setup-new-machine.sh`    | Replace iCloud references with git-based descriptions   | ~15   |
| `setup-mac.sh`            | Replace iCloud references with git-based descriptions   | ~8    |
| `setup-claude.sh`         | Replace iCloud references with git-based descriptions   | ~7    |
| `hooks/load-secrets.sh`   | Fix iCloud Keychain claim in comment                    | ~1    |
| `hooks/setup-keychain.sh` | Fix iCloud Keychain claims                              | ~3    |
| `install.sh`              | Fix iCloud Keychain claims                              | ~2    |

## Files to Delete

| File            | Reason |
| --------------- | ------ |
| (none expected) |        |

## Testing Strategy

- [ ] `ssh mini 'source ~/.nvm/nvm.sh && node --version'` returns v22.x.x
- [ ] `ssh mini 'ls ~/.claude-setup/mcp-servers/memory-turso/dist/index.js'` exists
- [ ] `ssh mini '~/.local/bin/browse --help 2>&1 | head -1'` produces output
- [ ] `ssh mini 'source ~/.nvm/nvm.sh && qmd --help 2>&1 | head -1'` produces output
- [ ] `grep '/Users/ps/' settings.json` returns nothing
- [ ] `grep -ri 'icloud' setup-new-machine.sh setup-mac.sh setup-claude.sh hooks/load-secrets.sh hooks/setup-keychain.sh install.sh` returns nothing
- [ ] `ssh mini '~/.claude-setup/tools/mem-search "test query"'` returns results

## Rollback Plan

1. **nvm + Node.js:** `ssh mini 'rm -rf ~/.nvm'` and remove nvm lines from `~/.zshrc`
2. **memory-turso build:** `ssh mini 'cd ~/.claude-setup/mcp-servers/memory-turso && npm run clean'` (removes dist/)
3. **browse binary:** `ssh mini 'rm -rf ~/.local/lib/browse ~/.local/bin/browse'`
4. **qmd:** `ssh mini 'source ~/.nvm/nvm.sh && npm uninstall -g @tobilu/qmd'`
5. **settings.json path fix:** `git checkout settings.json`
6. **iCloud script fixes:** `git checkout setup-new-machine.sh setup-mac.sh setup-claude.sh hooks/load-secrets.sh hooks/setup-keychain.sh install.sh`

## Anti-Patterns to Avoid

- Do not install Homebrew on Mini (adds maintenance burden, Mini is an inference server)
- Do not modify settings.json with machine-specific conditionals (keep it portable)
- Do not add new secrets to git-committed files
- Do not touch VPS configuration (out of scope)
