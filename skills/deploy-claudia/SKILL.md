---
name: deploy-claudia
description: "Deploy Claudia to VPS. Commits, pushes to GitHub, pulls on VPS, rebuilds, restarts. Triggers on: deploy claudia, push claudia, claudia deploy"
user-invocable: true
context: inline
model: haiku
effort: low
allowed-tools:
  - Bash
  - Read
---

# Deploy Claudia

Push the current state of the Claudia repo to GitHub, pull on the VPS, rebuild, and restart the service.

## Steps

1. **Pre-flight** — run `git status` in `/Volumes/AI/Code/claudia`. If there are staged or unstaged changes to tracked files, warn the user and stop. Untracked files are fine to ignore.

2. **Push to GitHub**

   ```bash
   cd /Volumes/AI/Code/claudia && unset GITHUB_TOKEN && git push origin main
   ```

3. **Pull + rebuild on VPS**

   ```bash
   ssh root@100.77.51.51 "cd /opt/claudia && git pull origin main --ff-only && pnpm install --frozen-lockfile 2>/dev/null || pnpm install && pnpm build"
   ```

4. **Restart + verify**

   ```bash
   ssh root@100.77.51.51 "systemctl restart claudia && sleep 3 && systemctl is-active claudia"
   ```

   If not active, show the last 20 lines of the journal:

   ```bash
   ssh root@100.77.51.51 "journalctl -u claudia -n 20 --no-pager"
   ```

5. **Report** — tell the user the deploy succeeded (or failed with logs).

## Rules

- Never force-push. Only `--ff-only` pulls on VPS.
- If the VPS pull fails (diverged history), stop and tell the user.
- Run steps 2-4 sequentially — each depends on the previous.
