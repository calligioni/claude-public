# Active Claude Code sessions

Append one row per active session. Remove (or mark closed) when the session ends.

| Session | Started | Branch | Project | Focus | Status |
|---|---|---|---|---|---|
| sa | 2026-04-19 09:00 | feat/sa-pluggy-rbac | example-project | RBAC tightening on Pluggy endpoints | merged |
| sb | 2026-04-19 10:15 | chore/sb-concurrent-rules | claude-setup | Concurrent session discipline rules | merged |

## Session tag conventions

- 2-letter alphabetic tag (`sa`, `sb`, `sc`…) — one per concurrent session
- Recycle tags after the session ends (`sa` on a new day is fine as long as it's not concurrent with another `sa`)
- Alternatively use date-based tags: `0419-rbac`, `0419-qa-gate` — useful when sessions span multiple days
- Log here before starting work; remove or mark `closed`/`merged` when done

## Why this exists

Two sessions silently picked the same Alembic migration number (`072`) with different content. This log + the `concurrent-sessions.md` rule prevent recurrence. See `rules/concurrent-sessions.md` for the full protocol.
- sa | feat/sa-tx-detail-enrichment | example-project | transaction detail modal enrichment (Phases A/B/C) | 2026-04-19
