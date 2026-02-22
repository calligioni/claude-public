# Tool Annotations & Invocation Contexts

## Annotations (declared in skill YAML frontmatter)

| Hint                    | Behavior                                                   |
| ----------------------- | ---------------------------------------------------------- |
| `destructiveHint: true` | Prefer safer alternatives first. Confirm when user-direct. |
| `readOnlyHint: true`    | Safe to call freely and retry.                             |
| `idempotentHint: true`  | Safe to retry on failure.                                  |
| `idempotentHint: false` | Call once, verify before retrying.                         |
| `openWorldHint: true`   | Cache when possible, handle timeouts.                      |

## Invocation Contexts

- **user-direct** (user typed `/skill`): verbose output, confirm destructive actions, markdown format.
- **agent-spawned** (invoked via Task/SendMessage): minimal output, no confirmation, structured format.
