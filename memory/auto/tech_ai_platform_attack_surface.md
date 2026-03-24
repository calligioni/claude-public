---
name: AI platform attack surface patterns
description: Attack chain from McKinsey Lilli breach — unauthenticated endpoints + JSON-key SQLi + system prompt write access = full AI platform compromise
type: tech
---

Specific attack chain (CodeWall vs McKinsey Lilli, Feb 2026):

1. **Unauthenticated API endpoint** — AI/chat endpoints exposed without auth middleware
2. **SQL injection on JSON keys** — standard parameterization protects VALUES but not column names or JSON key paths (`->`, `->>`, `jsonb_extract_path`, `ORDER BY ${input}`). Bypasses prepared statements entirely.
3. **System prompt read/write access** — prompts treated as config, not crown jewels. Write access enables poisoned advice, guardrail removal, data exfiltration via prompt manipulation.
4. **RAG chunk exposure** — vector similarity queries without ownership/permission WHERE clause leak cross-tenant data.

**Impact at McKinsey:** 46.5M chat messages, 728K files, 57K employee accounts, write access to 95 AI assistant system prompts. Patched within 1 day of disclosure.

**Applied in:**

- `/cto` security analyst checklist — added AI PLATFORM ATTACK SURFACE section (2026-03-13)
- `/qa-cycle` Phase 3d cross-persona detection — added AI prompt integrity checks (2026-03-13)
- `/fulltest-skill` Phase 2b — added AI prompt integrity test step (2026-03-13)

Source: https://codewall.ai/blog/how-we-hacked-mckinseys-ai-platform
