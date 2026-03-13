---
name: resend-cli-transactional-email
description: Resend CLI (v1.4.1) configured as transactional send channel in /agentmail skill — use for one-way sends from verified domains (contably.ai, xurman.com, agentwave.io)
type: reference
---

Resend CLI (github.com/resend/resend-cli) is integrated as a transactional email pathway in the `/agentmail` skill.

- **Install:** `npm install -g resend-cli` (not `resend` — that's the SDK)
- **Auth:** `RESEND_API_KEY` env var set in `~/.zshrc` + macOS Keychain
- **API key name:** `claude-cli` (full access, all domains)
- **Resend account:** nove (p@xurman.com Google login, Pro plan)
- **Verified domains:** contably.ai, xurman.com, agentwave.io
- **Partially failed:** agents.xurman.com (DNS records incomplete)
- **NOT on this account:** nuvini.ai
- **Non-TTY mode:** auto-detects agent/CI context, outputs JSON to stdout

**Routing:** AgentMail for inboxes (receive, reply, thread). Resend CLI for one-way transactional sends from business domains.
