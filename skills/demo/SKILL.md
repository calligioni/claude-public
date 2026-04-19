---
name: demo
description: "Create reproducible demo documents using Showboat. Produces executable narratives with captured output that can be verified and streamed remotely. Triggers on: demo, showboat, create demo, demo this, /demo."
argument-hint: "<what to demo — feature, tool, workflow, or script>"
user-invocable: true
context: fork
model: sonnet
effort: low
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
tool-annotations:
  Bash: { readOnlyHint: false, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
invocation-contexts:
  user-direct:
    verbosity: high
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    outputFormat: structured
inject:
  - bash: command -v showboat 2>/dev/null || command -v uvx 2>/dev/null && echo "uvx available" || echo "NO_SHOWBOAT"
  - bash: ls *.md 2>/dev/null | head -5
  - bash: git log --oneline -3 2>/dev/null
---

# Demo — Reproducible Demo Documents with Showboat

Create executable narrative documents that combine commentary, code blocks with captured output, and images. Documents are human-readable markdown AND verifiable — `showboat verify` re-runs all code and diffs output.

---

## Prerequisites

Showboat must be available. If the inject output shows `NO_SHOWBOAT`, tell the user:

```
Showboat is not installed. Install with:
  uvx showboat --help    (one-time run)
  uv tool install showboat   (permanent install)
  pip install showboat
```

If `uvx available` is shown, use `uvx showboat` as the command prefix instead of `showboat`.

Set the command prefix for all subsequent steps:

- If `command -v showboat` succeeded → `CMD=showboat`
- If only uvx is available → `CMD="uvx showboat"`

---

## Process

### Step 1: Understand the Demo Target

Read the user's argument to determine what to demo. Categories:

| Target Type  | Example                        | Approach                                          |
| ------------ | ------------------------------ | ------------------------------------------------- |
| **Feature**  | "demo the auth flow"           | Read relevant code, run key commands, show output |
| **Tool/CLI** | "demo showboat itself"         | Run tool commands, capture help + example output  |
| **Workflow** | "demo the deploy pipeline"     | Walk through each step with real commands         |
| **Script**   | "demo scripts/migrate.sh"      | Read the script, execute it, capture output       |
| **API**      | "demo the /api/users endpoint" | curl requests with captured responses             |
| **Project**  | "demo this project"            | Overview + key commands + test output             |

If the argument is ambiguous, use AskUserQuestion to clarify scope.

### Step 2: Plan the Narrative

Before touching Showboat, plan the document structure. A good demo has:

1. **Opening note** — what this demo shows and why it matters (1-2 sentences)
2. **Setup** (if needed) — install deps, start server, seed data
3. **Core demo** — 3-7 exec blocks showing the key functionality
4. **Verification** — tests passing, expected output confirmed
5. **Closing note** — summary and next steps

Keep it focused. A demo with 15 code blocks is a tutorial, not a demo. Aim for 3-7 exec blocks max.

### Step 3: Initialize the Document

```bash
$CMD init demo.md "Demo: {title}"
```

Use a descriptive filename if the user specified one, otherwise default to `demo.md`. If a `demo.md` already exists, use `demo-{slug}.md`.

### Step 4: Build the Narrative

Alternate between `note` and `exec` commands to build the document:

**Add commentary:**

```bash
$CMD note demo.md "This project uses Prisma for database access. Let's see the schema:"
```

**Execute and capture:**

```bash
$CMD exec demo.md bash 'cat prisma/schema.prisma'
```

**Handle errors gracefully:** `showboat exec` prints stdout and exits with the same code as the executed command. If a command fails:

- Use `$CMD pop demo.md` to remove the failed block
- Fix the issue or adjust the command
- Re-run the exec

**Add images (screenshots, diagrams):**

```bash
$CMD image demo.md path/to/screenshot.png
```

### Step 5: Verify

After building the document, verify it's reproducible:

```bash
$CMD verify demo.md
```

If verification fails (output differs), investigate:

- Non-deterministic output (timestamps, UUIDs) → add a note explaining the variance
- Environment-dependent output → add setup instructions
- Actual bugs → fix and re-capture

### Step 6: Present Results

Tell the user:

- Where the file was saved
- How to view it (it's just markdown)
- How to verify it: `showboat verify demo.md`
- How to extract the commands: `showboat extract demo.md`

---

## Showboat Command Reference

| Command                              | Purpose                         |
| ------------------------------------ | ------------------------------- |
| `showboat init <file> <title>`       | Create new document             |
| `showboat note <file> [text]`        | Add commentary                  |
| `showboat exec <file> <lang> [code]` | Execute code, capture output    |
| `showboat image <file> <path>`       | Add image                       |
| `showboat pop <file>`                | Remove last entry               |
| `showboat verify <file>`             | Re-run and diff all code blocks |
| `showboat extract <file>`            | Output commands to recreate     |

**Global flag:** `--workdir <dir>` sets working directory for execution.

**Stdin support:** Commands accept stdin when no argument given:

```bash
echo "Hello" | $CMD note demo.md
cat script.sh | $CMD exec demo.md bash
```

---

## Guidelines

1. **Keep it short.** 3-7 exec blocks. If you need more, split into multiple demos.
2. **Narrate, don't dump.** Every exec block should have a preceding note explaining what it does and why.
3. **Use real commands.** Don't fake output. Showboat captures actual execution.
4. **Handle non-determinism.** If output includes timestamps, random IDs, or variable data, add a note: "Output may vary — timestamps and IDs are generated at runtime."
5. **Pop failures.** If a command fails and the failure isn't the point of the demo, `pop` it and retry.
6. **Verify before delivering.** Always run `showboat verify` at the end.
7. **Match the language.** Use the correct language tag in exec (bash, python, node, sql, etc.).

---

## Remote Streaming

If the environment variable `SHOWBOAT_REMOTE_URL` is set, Showboat automatically POSTs each update to that URL. This enables real-time viewing of the demo as it's being built.

Do NOT set this variable yourself — the user configures it if they want streaming.

---

## Examples

### Demo a CLI tool

```
/demo "showboat CLI"
```

→ Init, show help, create a sample doc, add notes and exec blocks, verify it

### Demo a feature

```
/demo "user authentication flow"
```

→ Show the auth endpoints, curl a login, show the JWT, decode it, verify token refresh

### Demo a project

```
/demo "this project"
```

→ Show structure, install deps, run tests, show key output

### Demo for a PR

```
/demo "changes in this branch"
```

→ Show git diff stats, run new/modified tests, demonstrate the new behavior
