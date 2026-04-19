---
name: qmd
description: "Semantic search over markdown collections via QMD hybrid search (BM25 + vector + LLM rerank). Triggers on: search skills, find pattern, which skill, search notes, search memory, qmd."
argument-hint: "<search query>"
user-invocable: true
context: fork
model: haiku
effort: low
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - mcp__qmd__*
  - AskUserQuestion
memory: user
tool-annotations:
  mcp__qmd__*: { readOnlyHint: true, idempotentHint: true }
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

# QMD — Semantic Search Over Your Knowledge Base

Search across your claude-setup collections (skills, agents, rules, memory) and any project docs using QMD's hybrid search engine.

## Available Collections

| Collection | Path                      | Contents                              |
| ---------- | ------------------------- | ------------------------------------- |
| `skills`   | `~/.claude-setup/skills/` | 50+ skill definitions (SKILL.md)      |
| `agents`   | `~/.claude-setup/agents/` | 12 specialized agent definitions      |
| `rules`    | `~/.claude-setup/rules/`  | Strategy docs, memory rules, sync     |
| `memory`   | `~/.claude-setup/memory/` | Session memory, consolidation reports |

## Workflow

### Step 1: Determine Query Intent

Parse the user's query to determine:

1. **What** they're looking for (skill, pattern, decision, bug fix, etc.)
2. **Where** to search (specific collection or all)
3. **How** to present results (list of matches, deep dive into one, comparison)

### Step 2: Execute Search

**Preferred: Use QMD MCP tools if available:**

```
mcp__qmd__query({ query: "<natural language query>", options: { n: 5 } })
```

**Fallback: Use CLI via Bash if MCP is unavailable:**

```bash
qmd query "<natural language query>" --json -n 5
```

**For collection-scoped searches:**

```bash
qmd query "<query>" -c skills --json -n 5
qmd query "<query>" -c rules --json -n 3
```

**For structured queries (when you know specific terms):**

```bash
qmd query $'lex: security audit OWASP\nvec: how to review code for vulnerabilities' --json -n 5
```

**Fallback: mem-search for low-confidence or zero results:**

When QMD's hybrid/vector search returns no results or low-confidence matches (scores below ~0.3), fall back to FTS5 keyword search over auto-memory files:

```bash
~/.claude-setup/tools/mem-search "<query>"
```

This catches cases where the query uses exact terms (entity names, tool names, error strings) that vector search misses. Use it as a complementary second pass, not a replacement for QMD.

### Step 3: Present Results

For **user-direct** invocation, format results as:

```markdown
## Results for: "<query>"

### 1. [Title] (score: X.XX)

**File:** `collection/path/file.md`
**Snippet:** ...relevant excerpt...

### 2. ...
```

For **agent-spawned** invocation, return structured data:

```json
{
  "query": "<query>",
  "results": [
    { "file": "...", "score": 0.82, "title": "...", "snippet": "..." }
  ]
}
```

### Step 4: Offer Follow-up

After presenting results, offer:

- **Read full document:** "Want me to read the full skill file?"
- **Refine search:** "Want to narrow by collection or add terms?"
- **Cross-reference:** "Want to see related patterns/decisions?"

## Collection Management

If the user asks to add a new collection:

```bash
qmd collection add <path> --name <name>
qmd embed  # Generate embeddings for new content
```

If the user asks to update after file changes:

```bash
qmd update  # Re-index all collections
qmd embed   # Refresh embeddings
```

## Tips

- `qmd query` is the most powerful — it expands queries with synonyms, runs BM25 + vector search, and re-ranks with LLM
- `qmd search` is fast BM25-only — good for exact keyword matches
- `qmd vsearch` is vector-only — good for semantic similarity when exact terms aren't known
- Use `--intent` parameter for disambiguation when the query is ambiguous
- Use `-c <collection>` to scope search to specific collections
- Use `--full` flag to get full document content instead of snippets
- If QMD returns zero or low-confidence results, try `~/.claude-setup/tools/mem-search "<query>"` — FTS5 keyword search that catches exact entity names and terms vector search misses
