---
name: OpenRouter API Key
description: OpenRouter API key for Qwen 3.6 Plus and other models — stored in macOS Keychain and Claudia VPS .env
type: reference
---

OpenRouter API key stored in:

- **macOS Keychain** (this Mac): `security find-generic-password -s "OPENROUTER_API_KEY" -w`
- **Claudia VPS**: `/opt/claudia/.env` as `OPENROUTER_API_KEY`
- **Mac Mini**: not in keychain (SSH blocks interactive auth) — add manually if needed

**Account:** Created March 2026. Free preview pricing for Qwen 3.6 Plus ($0/$0). Expect pricing to change — Qwen 3.5 went to $0.1/$0.3 after preview.

**Where it's used:**

- Claudia VPS (`/opt/claudia/.env`) — Tier 0R fallback in inference chain
- Default model: `qwen/qwen3-235b-a22b` (configurable via `OPENROUTER_MODEL` env var)
