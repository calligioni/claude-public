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
- Default model: `qwen/qwen3.6-plus-preview:free` (switched from `qwen/qwen3-235b-a22b` on 2026-04-02)
- `max_tokens` increased from 4096 to 16384 in `openrouter.ts`
- Memory context budget increased from 8000 to 16000 chars in `memory/files.ts`

**Qwen3.6-Plus (April 2, 2026):** 1M context window, native chain-of-thought + tool use, agentic coding with multi-file planning + self-refinement. Free on OpenRouter during preview (`qwen/qwen3.6-plus-preview:free`). Likely MoE architecture. Open weights on phased release — benchmark on Mac Mini M4 Pro when available to evaluate as Tier 0b replacement.

- Applied in: claudia-setup - 2026-04-02 - HELPFUL
