---
name: get-api-docs
description: "Fetch current API docs for any library/SDK via chub CLI. 1,000+ APIs (Supabase, Anthropic, Clerk, Prisma, Stripe, Playwright). Triggers on: get api docs, fetch docs, chub, api documentation."
argument-hint: "<library name or chub doc ID>"
user-invocable: true
context: fork
model: haiku
effort: low
allowed-tools:
  - Bash
  - Read
  - Write
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: false
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
---

# Get API Docs via chub

When you need documentation for a library or API, fetch it with the `chub` CLI
rather than guessing from training data. This gives you the current, correct API.

## Step 1 — Find the right doc ID

```bash
chub search "<library name>" --json
```

Pick the best-matching `id` from the results (e.g. `openai/chat`, `anthropic/sdk`,
`stripe/api`). If nothing matches, try a broader term.

## Step 2 — Fetch the docs

```bash
chub get <id> --lang ts    # or --lang js, --lang py
```

Omit `--lang` if the doc has only one language variant — it will be auto-selected.

Default to `--lang ts` for this user's projects (TypeScript stack).

## Step 3 — Use the docs (or split if large)

Read the fetched content and use it to write accurate code or answer the question.
Do not rely on memorized API shapes — use what the docs say.

**If the doc is larger than ~200 lines**, suggest splitting it for efficient subagent use:

```
This doc is large (N lines). Run `/skill-tree <id>` to split it into a
navigable index + sub-files so agents read only the sections they need.
```

If a skill tree already exists for this doc at `.skill-trees/<author>-<name>/`, read `_index.md` first and follow only the relevant branches instead of loading the full doc.

## Step 4 — Annotate what you learned

After completing the task, if you discovered something not in the doc — a gotcha,
workaround, version quirk, or project-specific detail — save it so future sessions
start smarter:

```bash
chub annotate <id> "Webhook verification requires raw body — do not parse before verifying"
```

Annotations are local, persist across sessions, and appear automatically on future
`chub get` calls. Keep notes concise and actionable. Don't repeat what's already in
the doc.

## Step 5 — Give feedback

Rate the doc so authors can improve it. Ask the user before sending.

```bash
chub feedback <id> up                        # doc worked well
chub feedback <id> down --label outdated     # doc needs updating
```

Available labels: `outdated`, `inaccurate`, `incomplete`, `wrong-examples`,
`wrong-version`, `poorly-structured`, `accurate`, `well-structured`, `helpful`,
`good-examples`.

## Quick reference

| Goal                       | Command                                       |
| -------------------------- | --------------------------------------------- |
| List everything            | `chub search`                                 |
| Find a doc                 | `chub search "stripe"`                        |
| Exact id detail            | `chub search stripe/api`                      |
| Fetch TS docs              | `chub get stripe/api --lang ts`               |
| Fetch Python docs          | `chub get stripe/api --lang py`               |
| Fetch specific version     | `chub get stripe/api --version 12.0.0`        |
| Fetch specific file        | `chub get stripe/api --file webhooks.md`      |
| Fetch all files (offline)  | `chub get stripe/api --full`                  |
| Structured JSON output     | `chub get stripe/api --json`                  |
| Save to file               | `chub get anthropic/sdk --lang ts -o docs.md` |
| Fetch multiple             | `chub get openai/chat stripe/api --lang ts`   |
| Save a note                | `chub annotate stripe/api "needs raw body"`   |
| List notes                 | `chub annotate --list`                        |
| Rate a doc                 | `chub feedback stripe/api up`                 |
| Refresh doc registry cache | `chub update`                                 |
| Force re-download          | `chub update --force`                         |
| Download for offline use   | `chub update --full`                          |
| Check cache status         | `chub cache status`                           |
| Clear cache                | `chub cache clear`                            |

## Notes

- `chub search` with no query lists everything available (1,000+ API documents as of 2026-03)
- IDs are `<author>/<name>` — confirm the ID from search before fetching
- If multiple languages exist and you don't pass `--lang`, chub will tell you which are available
- Prefer `--lang ts` for this user's TypeScript projects
- Use `--version` when a project pins a specific library version to avoid drift
- Use `--file` to fetch only a sub-section (e.g., webhooks, auth) — cheaper in subagent contexts
- Use `--full` to pre-download everything for offline or multi-agent sessions
- Use `--json` for programmatic/agent integration (returns structured output with `additionalFiles` array)
- Disable telemetry/feedback sharing: set `telemetry: false` in `~/.chub/config.yaml` or `CHUB_TELEMETRY=0`
