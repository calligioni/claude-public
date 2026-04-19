---
name: skill-tree
description: "Split large docs into navigable index + linked sub-files to reduce context bloat. Triggers on: skill tree, split docs, navigable index, reduce context bloat."
argument-hint: "<source file or URL or topic>"
user-invocable: true
context: fork
model: sonnet
effort: medium
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - WebFetch
  - WebSearch
  - Agent
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

# Skill Tree — Hierarchical Knowledge Splitter

Split large documentation into a navigable tree that agents traverse efficiently.
Read the index → follow only the relevant branch → skip everything else.

## When to Use

- API docs returned by `chub get` are too large for a subagent's context
- A SKILL.md has grown beyond ~300 lines and covers multiple domains
- Research output is monolithic and only parts are relevant per query
- Any reference material that multiple agents need different slices of

## Input

One of:

1. **File path** — a local markdown/text file to split
2. **URL** — fetch and split remote docs
3. **Topic + source** — e.g. "Stripe webhooks from chub"

## Output

A directory with:

```
<name>/
  _index.md        # The navigable index (always read this first)
  <section-1>.md   # Sub-file for section 1
  <section-2>.md   # Sub-file for section 2
  ...
```

## Workflow

### Step 1: Acquire Source Material

**If file path:** Read it directly.

**If URL:** Fetch it:

```bash
# Try WebFetch first, fall back to curl
```

**If topic + chub:** Fetch via chub:

```bash
chub get <id> --lang ts --full -o /tmp/chub-<id>.md
```

**If topic (general):** Search and fetch:

```bash
# Use WebSearch to find authoritative docs, then WebFetch
```

### Step 2: Analyze Structure

Read the full source and identify natural section boundaries:

1. **H1/H2 headers** — primary split points
2. **Thematic clusters** — group related subsections
3. **Size targets** — each sub-file should be 50-200 lines (sweet spot for agent context)
4. **Cross-references** — note which sections reference each other

Aim for 4-12 sub-files. Fewer than 4 means the source doesn't need splitting.
More than 12 means sections are too granular — merge related ones.

### Step 3: Generate the Index

Create `_index.md` with this structure:

```markdown
# <Topic> — Skill Tree Index

> Navigate: read this index, then `Read` only the sub-file(s) relevant to your task.

## Sections

| File                       | Topic                  | When to Read                       |
| -------------------------- | ---------------------- | ---------------------------------- |
| [auth.md](auth.md)         | Authentication & JWT   | Working on login, tokens, sessions |
| [webhooks.md](webhooks.md) | Webhook handling       | Processing incoming events         |
| [errors.md](errors.md)     | Error codes & handling | Debugging API responses            |
| ...                        | ...                    | ...                                |

## Quick Reference

<2-3 line summary of the most critical facts that ALL readers need>

## Cross-References

- auth.md ↔ webhooks.md (webhook signature verification uses auth keys)
- errors.md ← all sections (error codes referenced throughout)
```

Key rules for the index:

- **"When to Read" column is critical** — it tells agents whether they need this branch
- **Quick Reference** contains only universally-needed facts (base URL, auth method, rate limits)
- **Cross-References** help agents know when reading one section means they should also read another

### Step 4: Generate Sub-Files

For each section:

```markdown
# <Section Title>

> Part of: [<Topic> Skill Tree](_index.md)
> Related: [other-section.md](other-section.md)

<content from source, cleaned up and focused>
```

Rules:

- Each sub-file is self-contained enough to be useful alone
- Include a back-link to `_index.md` at the top
- Include forward-links to related sub-files
- Strip content that duplicates what's in the index's Quick Reference
- Preserve code examples — they're the most valuable part

### Step 5: Write the Tree

Determine output location:

| Source                   | Output Directory                     |
| ------------------------ | ------------------------------------ |
| chub doc `author/name`   | `.skill-trees/<author>-<name>/`      |
| Local file `docs/api.md` | `.skill-trees/<filename>/`           |
| URL                      | `.skill-trees/<domain>-<path-slug>/` |
| Custom (user specified)  | As specified                         |

Write all files to the output directory.

### Step 6: Report

Output the tree structure and usage instructions:

```
Skill tree created: .skill-trees/<name>/

Files:
  _index.md          (42 lines — read this first)
  auth.md            (128 lines)
  webhooks.md        (95 lines)
  errors.md          (67 lines)
  rate-limits.md     (54 lines)

Usage in spawn prompts:
  "Read .skill-trees/<name>/_index.md first.
   Then read only the sub-files relevant to your task."
```

## Integration with Other Skills

### /get-api-docs

When `chub get` returns docs larger than ~200 lines, suggest:
"This doc is large. Run `/skill-tree <id>` to split it into navigable sections."

### /cto (swarm analysts)

Pre-split large codebases into domain trees before spawning analysts.
Include in analyst spawn prompts:

```
Read .skill-trees/codebase/_index.md first.
Your domain files: auth.md, middleware.md
Skip: database.md, frontend.md (other analysts cover those)
```

### /deep-research

Split research findings per track into a tree, so the synthesizer
reads the index + only the tracks relevant to the final question.

## Anti-Patterns

- **Don't split files under 100 lines** — the index overhead exceeds the savings
- **Don't create sub-files under 20 lines** — merge them into a neighbor
- **Don't nest trees** — one level of index → sub-files is enough. Two levels adds navigational overhead that outweighs context savings
- **Don't duplicate content** — if something is in the index Quick Reference, don't repeat it in sub-files
