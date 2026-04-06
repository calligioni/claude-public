---
name: VPS connection details
description: How to reach the Contabo VPS (Claudia, Paperclip) — Tailscale IP, SSH user, hostname, ports
type: reference
---

## VPS Connection

- **Tailscale IP:** 100.77.51.51
- **Tailscale hostname:** vmi3065960
- **Public IP:** 167.86.119.7
- **SSH user:** root
- **Provider:** Contabo

## Quick Access

```bash
ssh root@100.77.51.51
```

## Services on VPS

- **Claudia:** systemd `claudia.service`, port 3001, `/opt/claudia/`
- **Paperclip:** systemd `paperclip.service`, port 3100, User=paperclip

## How to Apply

Whenever needing to SSH, rsync, or interact with the VPS — use `root@100.77.51.51`. Do NOT rely on a `vps` SSH alias existing; use the Tailscale IP directly.

Discovered: 2026-04-06
Source: user-feedback — repeated failure to find VPS connection info
Use count: 1
