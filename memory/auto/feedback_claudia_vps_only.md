---
name: Claudia lives on VPS only
description: When discussing Claudia's running state, always check the VPS (/opt/claudia) via SSH — local repo is just source code
type: feedback
---

When talking about Claudia's live state (agents, crons, config, running tasks), always look at the VPS at /opt/claudia, not the local repo at ~/code/claudia. The local repo is source code only — it doesn't have agent directories, runtime data, or the actual .env.

**Why:** User corrected me for checking local paths when discussing what Claudia actually does. The agents/ directory, runtime state, and config live on the VPS.

**How to apply:** SSH into the VPS via Tailscale when checking Claudia's running behavior. Use local repo only for code changes.
