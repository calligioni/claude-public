# Tool Annotations & Invocation Contexts

WebMCP-inspired behavioral hints for skills and agents.

## Tool Annotations

Skills declare `tool-annotations` in their YAML frontmatter to mark tool safety characteristics. These are behavioral hints — follow them when deciding how to use tools.

### Annotation Types

| Hint                    | Meaning                                      | Behavior                                                                                                    |
| ----------------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `destructiveHint: true` | Tool may perform irreversible operations     | Prefer safer alternatives first. When user-direct, confirm before use. When agent-spawned, log but proceed. |
| `readOnlyHint: true`    | Tool does not modify state                   | Safe to call freely, retry on failure, use for exploration.                                                 |
| `idempotentHint: true`  | Same input always produces same result       | Safe to retry on transient failures without side effects.                                                   |
| `idempotentHint: false` | Repeated calls may cause duplicates or drift | Call once, verify result before retrying.                                                                   |
| `openWorldHint: true`   | Tool interacts with external systems         | Results may vary between calls. Cache when possible. Rate-limit usage.                                      |

### How to Apply

1. **Before calling a destructive tool**: Check if a read-only alternative exists (e.g., `git diff` before `git reset`)
2. **On failure of an idempotent tool**: Retry up to 2 times automatically
3. **On failure of a non-idempotent tool**: Do NOT retry — report the failure and ask for guidance
4. **When using open-world tools**: Expect latency, handle timeouts gracefully, don't assume consistent results

### Example in Frontmatter

```yaml
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
  mcp__firecrawl__*: { readOnlyHint: true, openWorldHint: true }
```

## Invocation Contexts

Skills declare `invocation-contexts` to behave differently based on who called them.

### Context Types

| Context         | When Active                                                 | Typical Caller           |
| --------------- | ----------------------------------------------------------- | ------------------------ |
| `user-direct`   | User typed `/skill-name` or triggered via description match | Human user               |
| `agent-spawned` | Skill invoked via `Task()` tool by another skill or agent   | CTO, CPO, ship, qa-cycle |

### Behavioral Differences

**user-direct**:

- `verbosity: high` — Full explanations, progress updates, reasoning shown
- `confirmDestructive: true` — Use `AskUserQuestion` before destructive tool calls
- `outputFormat: markdown` — Rich formatted output with headers, tables, code blocks

**agent-spawned**:

- `verbosity: minimal` — Results only, no explanations or progress narration
- `confirmDestructive: false` — Proceed without confirmation (parent agent already authorized)
- `outputFormat: structured` — Return JSON or concise structured data the parent can parse

### How to Detect Context

- If invoked via `/skill-name` by the user → `user-direct`
- If invoked via `Task(agent_type=...)` by another agent → `agent-spawned`
- If invoked via `TeammateTool` or `SendMessage` → `agent-spawned`
- When uncertain → default to `user-direct`

### Example in Frontmatter

```yaml
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: true
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
```
