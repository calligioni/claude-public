---
name: wiki
description: "LLM Wiki — persistent, compounding knowledge base. Ingest sources, query knowledge, think/synthesize, auto-harvest, lint health. Karpathy + Memex pattern. Triggers on: wiki, wiki ingest, wiki query, wiki think, wiki lint, wiki stats, wiki harvest, add to wiki, knowledge base, remember this"
user-invocable: true
context: inline
model: sonnet
effort: medium
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebFetch
  - WebSearch
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: true
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  WebFetch: { readOnlyHint: true, openWorldHint: true }
  WebSearch: { readOnlyHint: true, openWorldHint: true }
---

# LLM Wiki

Persistent, compounding knowledge base using the Karpathy LLM Wiki pattern.
The wiki lives at `agents/claudia/wiki/` on the VPS (`/opt/claudia/agents/claudia/wiki/`).

## Architecture

```
agents/claudia/wiki/
  raw/          — immutable source documents (never modified after save)
  pages/        — LLM-generated wiki pages (you maintain these)
  index.md      — catalog of all pages with summaries and tags
  log.md        — chronological record of all operations
```

## Operations

### 1. Ingest (`/wiki ingest <url-or-text>`)

When the user provides a URL, article, document, or raw text to ingest:

1. **Fetch the content** — if URL, use WebFetch to get the content. If text, use it directly.
2. **Read the wiki index** — `ssh root@100.77.51.51 "cat /opt/claudia/agents/claudia/wiki/index.md 2>/dev/null"` to understand existing pages.
3. **Extract structured data** from the source:
   - Title
   - 2-3 sentence summary
   - 5-10 key facts (bullet points)
   - Named entities (people, companies, technologies, concepts) with descriptions
   - Tags (3-5 lowercase keywords)
4. **Create/update wiki pages** on the VPS:
   - Create a source summary page: `agents/claudia/wiki/pages/{slug}.md`
   - For each entity: create or append to `agents/claudia/wiki/pages/{entity-slug}.md`
   - Use `[[link|Title]]` syntax for cross-references between pages
5. **Update the index** — add/update entries in `agents/claudia/wiki/index.md`
6. **Log the operation** — append to `agents/claudia/wiki/log.md`
7. **Report** — tell the user what was created/updated

### 2. Query (`/wiki query <question>` or `/wiki <question>`)

When the user asks a question against the wiki:

1. **Search wiki pages** — `ssh root@100.77.51.51 "grep -ril '<keywords>' /opt/claudia/agents/claudia/wiki/pages/"` to find relevant pages
2. **Read matching pages** — fetch content of top 5 matches
3. **Synthesize an answer** with citations to specific pages
4. **Optionally file the answer** — if the answer is a valuable synthesis, offer to save it as a new wiki page

### 3. Think (`/wiki think <topic>`)

Socratic synthesis mode — not lookup, but **reasoning** across the knowledge base:

1. **Find all related pages** — keyword search + tag expansion + wikilink traversal (broader than query)
2. **Detect contradictions** — find pages that make conflicting claims about the same subject
3. **Surface connections** — identify shared entities across different domains/categories
4. **Build thinking context** — structure all findings for LLM synthesis via `buildThinkContext()` from `src/wiki/think.ts`
5. **Generate a thinking brief** with this structure:
   - **What I know** — synthesized knowledge across all pages
   - **What contradicts** — conflicting information and which source to trust
   - **What connects** — non-obvious relationships between ideas
   - **What's missing** — gaps that would strengthen understanding
   - **Questions to explore** — 3-5 Socratic questions that push thinking further
6. **Offer to save** — if the brief is valuable, save it as a wiki page via `saveThinkBrief()`

The key difference from query: think mode asks questions, not just answers them. It's a thinking partner, not an encyclopedia.

### 4. Harvest (`/wiki harvest` or automatic)

Auto-ingest from multiple sources. Runs daily at 06:00 BRT via `wiki-harvest` scheduled task.

**Sources:**

- **Gmail starred emails** — starring an email = "worth remembering". Claudia fetches, extracts, ingests, then unstars.
- **Trend research outputs** — briefs from `trend-research.ts` are auto-ingested into wiki pages.
- **URL queue** — agents or users add URLs to `data/wiki-harvest-queue.json` for batch ingestion.

**Manual trigger:** `/wiki harvest` runs the harvest immediately.

**Adding URLs to the queue:** Any agent can call `queueUrlForHarvest(url, note?, addedBy?)` from `src/scheduler/wiki-harvest.ts`, or the user can say "remember this: <url>" and the URL is queued for the next harvest.

### 5. Lint (`/wiki lint`)

Health-check the wiki:

1. **Read all pages and index** from VPS
2. Check for:
   - Orphan pages (exist but not in index)
   - Empty/stub pages (<50 chars of content)
   - Broken `[[links]]` to non-existent pages
   - Stale pages not updated in 30+ days
   - Index entries pointing to missing files
3. **Report findings** with suggested fixes
4. **Offer to auto-fix** — create missing pages, add orphans to index, remove stale entries

### 4. Stats (`/wiki stats`)

Quick overview:

```bash
ssh root@100.77.51.51 "echo 'Pages:' && ls /opt/claudia/agents/claudia/wiki/pages/*.md 2>/dev/null | wc -l && echo 'Sources:' && ls /opt/claudia/agents/claudia/wiki/raw/ 2>/dev/null | wc -l && echo 'Index:' && wc -l /opt/claudia/agents/claudia/wiki/index.md 2>/dev/null"
```

## Page Format

Every wiki page should follow this structure:

```markdown
# Page Title

_Brief description. Source: filename.md | Updated: 2026-04-07_

## Main Content

The core information about this topic.

## Key Facts

- Fact 1
- Fact 2

## Related

- [[other-page|Other Page Title]]
- [[another-page|Another Page]]

## Sources

- [[source-summary|Source Title]] (date)

## Tags

`tag1` `tag2` `tag3`
```

## Rules

- **Never modify raw sources** — they are immutable records
- **Always update the index** after creating or updating pages
- **Always log operations** to log.md
- **Use [[wikilinks]]** for cross-references — they make the graph navigable
- **One concept per page** — avoid mega-pages. Split into focused pages and link them.
- **Cite sources** — every claim should trace back to a raw source
- **Flag contradictions** — when new info contradicts existing pages, note both views
- The wiki auto-injects into Claudia's memory context — relevant pages appear in the system prompt when queries match

## VPS Access

All wiki operations run on the VPS at `/opt/claudia/agents/claudia/wiki/`:

```bash
ssh root@100.77.51.51 "ls /opt/claudia/agents/claudia/wiki/pages/"
```
