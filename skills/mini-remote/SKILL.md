---
name: mini-remote
description: "Remote autonomous coding relay via SSH to Mac Mini. Supports single and queued prompts with Slack notifications. Triggers on: /mini, send to mini, queue for mini, run on mini, mini execute, run remotely on mac mini."
user-invocable: true
context: fork
model: sonnet
effort: low
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
---

# Mini Remote — Fire & Forget Autonomous Coding Relay

## Overview

This skill lets you queue one or more prompts to execute autonomously on your Mac Mini via SSH over Tailscale. Perfect for firing off work before a flight, overnight tasks, or heavy compute jobs.

**Flow:**

1. You code on MacBook Air with Claude Code (auto-saves to GitHub every 3 min)
2. You type: `/mini "run a full security analysis"`
3. The skill SSHs into the Mac Mini and:
   - `git pull` latest from the current repo
   - Runs Claude Code with your prompt in fully autonomous mode
   - Commits and pushes all changes with `[remote-mini]` tag
   - Sends a Slack notification with summary
   - Moves to next queued prompt (if any)
4. You land, `git pull`, and see all the work done

## Prerequisites

Before first use, run the setup script:

```bash
bash /path/to/mini-remote/scripts/setup.sh
```

This will verify and configure:

- SSH access to Mac Mini via Tailscale
- Slack webhook for notifications
- Claude Code CLI availability on the Mini

### Required Environment Variables

Set these in `~/.mini-remote.env` (created by setup) or export them:

```bash
MINI_HOST="your-mac-mini-tailscale-hostname"   # e.g., mac-mini or 100.x.x.x
MINI_USER="your-username"                       # SSH user on the Mini
MINI_WORKSPACE="/Users/yourname/workspace"      # Base workspace dir on Mini
SLACK_WEBHOOK_URL="https://hooks.slack.com/..." # Slack incoming webhook URL
```

## Usage

### Single prompt:

```
/mini "run a full security analysis on the auth module"
```

### Multiple prompts (queued, sequential):

```
/mini queue
1. "run a full security analysis"
2. "add API rate limiting to all public endpoints"
3. "create comprehensive test suite for the payment module"
```

### Check status:

```
/mini status
```

## How It Works

When `/mini` is triggered, Claude should:

### Step 1: Detect Current Context

```bash
# Auto-detect current repo and branch
REPO_URL=$(git remote get-url origin)
BRANCH=$(git branch --show-current)
REPO_NAME=$(basename -s .git "$REPO_URL")
```

### Step 2: Execute the Remote Script

Run the dispatcher script which handles everything:

```bash
bash /path/to/mini-remote/scripts/dispatch.sh \
  --repo "$REPO_URL" \
  --branch "$BRANCH" \
  --repo-name "$REPO_NAME" \
  --prompts "prompt1|||prompt2|||prompt3"
```

The `|||` delimiter separates multiple queued prompts.

### Step 3: Confirm to User

After dispatching, confirm:

- Number of prompts queued
- Repo and branch targeted
- Estimated that Slack notification will arrive on completion

## Safety Rails

The following safety rules are ENFORCED in the execution wrapper on the Mini:

1. **No destructive database operations**: Commands containing `DROP DATABASE`, `DROP TABLE`, `TRUNCATE`, `DELETE FROM` (without WHERE), or `db.dropDatabase` are blocked
2. **No recursive deletions**: `rm -rf /`, `rm -rf ~`, `rm -rf .` are blocked
3. **No permanent file deletions**: Large-scale `rm` operations are blocked; file moves to trash are OK
4. **No credential exposure**: Commands that would echo/cat/print secrets, tokens, or keys to logs are sanitized
5. **Git safety**: Force pushes (`--force`) to `main`/`master` are blocked
6. **All commits** include the `[remote-mini]` tag so you can audit what the Mini did

## Slack Notification Format

On completion of each prompt, a Slack message is sent:

```
🤖 Mini Remote — Task Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 Repo: nuvini/project-name
🌿 Branch: main
📝 Prompt: "run a full security analysis"
✅ Status: Completed (or ❌ Failed)
📊 Summary: 12 files changed, 847 additions, 23 deletions
🔗 Commits: abc1234, def5678
⏱️ Duration: 14m 32s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Queue: 1/3 complete — next: "add API rate limiting..."
```

On full queue completion:

```
🏁 Mini Remote — All Tasks Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3/3 prompts executed successfully
📁 Repo: nuvini/project-name
⏱️ Total duration: 47m 15s
📊 Total: 34 files changed, 2,104 additions, 89 deletions
```

## Architecture Notes

- **No daemon needed** — pure SSH + nohup. The dispatch script starts the job detached so your local terminal returns immediately
- **GitHub is the state bus** — no file sync needed, git pull/push handles everything
- **Claude Code headless mode** — uses `claude -p` (print mode) or `claude --dangerously-skip-permissions` for fully autonomous execution
- **Tailscale** — private encrypted tunnel, no port forwarding needed
- **Sequential execution** — prompts run one after another, not in parallel, to avoid conflicts

## File Reference

| File                      | Purpose                                             |
| ------------------------- | --------------------------------------------------- |
| `SKILL.md`                | This file — skill documentation                     |
| `scripts/dispatch.sh`     | Local script that SSHs into Mini and starts the job |
| `scripts/executor.sh`     | Runs ON the Mini — pulls, executes, commits, pushes |
| `scripts/safety_check.sh` | Pre-execution safety validation                     |
| `scripts/notify.sh`       | Sends Slack notifications                           |
| `scripts/setup.sh`        | First-time setup wizard                             |
| `scripts/status.sh`       | Check running/queued job status                     |
