# Memory Strategy

## Entity Naming: `{type}:{identifier}`

| Prefix             | Purpose                       |
| ------------------ | ----------------------------- |
| `pattern:`         | Reusable code/design patterns |
| `mistake:`         | Errors to avoid               |
| `tech-insight:`    | Technology-specific learnings |
| `preference:`      | User/project preferences      |
| `design-decision:` | Design choices made           |
| `test-pattern:`    | Reusable test sequences       |
| `common-bug:`      | Frequently found issues       |
| `architecture:`    | Architecture decisions        |

Use lowercase with hyphens. Include project name when project-specific.

## Required Observations

Every entity must include these observations:

- `"Discovered: {date}"`
- `"Source: {type} — {detail}"` (see Source Types below)
- `"Applied in: {project} - {date} - {HELPFUL|NOT HELPFUL|MODIFIED}"`
- `"Use count: {N}"`

### Source Types

Use a typed `Source:` format to enable source-based filtering and pruning during consolidation:

| Type             | Format                                        | Example                                                    |
| ---------------- | --------------------------------------------- | ---------------------------------------------------------- |
| `implementation` | `Source: implementation — {file or feature}`  | `Source: implementation — src/auth/jwt.ts`                 |
| `failure`        | `Source: failure — {what went wrong}`         | `Source: failure — forgot RLS on profiles table`           |
| `user-feedback`  | `Source: user-feedback — {context}`           | `Source: user-feedback — always use pnpm`                  |
| `research`       | `Source: research — {url or paper}`           | `Source: research — github.com/kbanc85/claudia`            |
| `code-review`    | `Source: code-review — {PR or session}`       | `Source: code-review — PR #42 security findings`           |
| `git-history`    | `Source: git-history — {repo}`                | `Source: git-history — contably commit patterns`           |
| `session`        | `Source: session — {skill or context}`        | `Source: session — /ship feature auth`                     |
| `consolidation`  | `Source: consolidation — merged from {names}` | `Source: consolidation — merged from pattern:a, pattern:b` |

During consolidation, source types enable targeted pruning:

- `research` sources decay faster (60 days) — market data goes stale
- `failure` sources are retained longer (180 days) — mistakes are expensive to relearn
- `user-feedback` sources never auto-decay — explicit user preferences are stable

## Dedup Before Write

Before creating any new memory file, check for duplicates using `mem-search`:

```bash
~/.claude-setup/tools/mem-search "<key terms from the memory>"
```

- If a high-relevance match exists → UPDATE the existing file instead of creating a new one
- If partial match (related but different) → consider merging into the existing file
- If no match → create new file as normal
- After writing → run `~/.claude-setup/tools/mem-search --reindex` to update the search index

## Cross-Link on Write

After writing a new memory file, update 3-5 **existing** memory files that the new information touches. This turns isolated memories into a connected knowledge graph at ingest time (Karpathy wiki pattern).

### Process

1. **Search for related memories** — run `mem-search` with 2-3 keyword queries from the new memory's content
2. **Select 3-5 most relevant** existing files, prioritizing:
   - Memories the new one **contradicts** (add contradiction note to both)
   - Memories the new one **extends** (add "Related:" back-reference)
   - Memories the new one **validates** (add confirmation note)
   - Memories in a different type that share the same domain
3. **Update each related file** — append a `Related:` line or update an existing one:
   ```
   Related: [new-memory-title](new-memory-file.md) — one-line why ({date})
   ```
4. **Update MEMORY.md** — if the related file's one-liner in the index should mention the new connection, update it
5. **Reindex** — run `~/.claude-setup/tools/mem-search --reindex` after all writes

### Budget

- Max 5 related files updated per new memory
- Max 2 `mem-search` calls per new memory
- Skip cross-linking if the new memory is trivial (score < 5) or a minor update to an existing file

### When to Skip Cross-Linking

- Simple observation additions to existing memories (e.g., "Applied in: project - date - HELPFUL")
- Updating a single field in an existing memory
- When the `mem-search` returns no results with score >= 3.0

## Save vs Skip

**Save when:** high generality, learned from failure, user explicitly shared, expensive to regenerate, high severity.
**Skip when:** duplicate exists (>85% similar), project-specific detail, trivial/obvious.
