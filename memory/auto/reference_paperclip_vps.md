---
name: reference:paperclip-vps-setup
description: Paperclip AI orchestration running on VPS with 3 companies (Nuvini, Contably, SourceRank) — hybrid claude_local + openclaw_gateway adapters
type: reference
---

## Paperclip on VPS

- **Host:** vmi3065960 (Contabo), Tailscale IP 100.77.51.51
- **Service:** `paperclip.service` (systemd), port 3100, bind 127.0.0.1
- **Database:** PostgreSQL 16 on port 5432, db=paperclip, user=paperclip
- **Config:** `/root/.paperclip/instances/default/config.json`
- **Mode:** `local_trusted` / private
- **Version:** 0.3.1 (npm: paperclipai)
- **Claude Auth:** Max subscription (oauth login, no API key needed)

## Companies

| Company       | ID                                   | Prefix | Budget |
| ------------- | ------------------------------------ | ------ | ------ |
| Nuvini Group  | 4e37d9a0-a4dd-4226-9bc9-f2932243a34e | NUV    | $50/mo |
| Contably      | c025dfac-dbf2-49de-a78f-97e259a89c42 | CON    | $30/mo |
| SourceRank AI | 599ab2a1-533e-477d-b555-5b56e3637f6b | SOU    | $30/mo |

## Agents

| Agent               | Company    | Role    | Adapter          | Model             |
| ------------------- | ---------- | ------- | ---------------- | ----------------- |
| Nuvini CEO          | Nuvini     | ceo     | openclaw_gateway | (via OpenClaw)    |
| Nuvini Orchestrator | Nuvini     | general | claude_local     | claude-sonnet-4-6 |
| Contably CEO        | Contably   | ceo     | openclaw_gateway | (via OpenClaw)    |
| Contably Operator   | Contably   | general | claude_local     | claude-sonnet-4-6 |
| SourceRank CEO      | SourceRank | ceo     | openclaw_gateway | (via OpenClaw)    |
| SourceRank Operator | SourceRank | general | claude_local     | claude-sonnet-4-6 |

## Architecture

- **CEOs** → OpenClaw gateway (ws://127.0.0.1:3001) → Mac Mini node (MLX compute, multi-model)
- **Operators** → claude_local adapter → Claude Code CLI directly on VPS (Max subscription, sonnet-4-6)
- Personal agents (Claudia, Marco, Arnold, etc.) remain OpenClaw-only — not managed by Paperclip
- Paperclip skill installed at `/root/.openclaw/skills/paperclip/SKILL.md`

**Why:** CEOs do strategic/multi-modal work through OpenClaw's model routing. Operators do hands-on code execution directly via Claude Code on the VPS — faster, no gateway hop, direct filesystem access.
**How to apply:** Use Paperclip CLI or API for business task assignment; use OpenClaw directly for personal agent interactions.

## Key Config Notes

- PG port was fixed from 5433→5432 on 2026-03-18 (upstream default changed)
- Claude Code on VPS: v2.1.31, logged in via oauth (Max 20x rate limit)
- Operator agents: `dangerouslySkipPermissions: true`, `maxTurnsPerRun: 50`, `timeoutSec: 1800`
