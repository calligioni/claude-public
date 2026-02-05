# MCP Permission Configuration

Guidelines for configuring MCP server permissions in Claude Code.

## Wildcard Permission Syntax

Claude Code 2.1+ supports wildcard permissions for MCP servers.

### Allow All Tools from a Server

```json
{
  "permissions": {
    "allow": ["mcp__filesystem__*"]
  }
}
```

This allows all tools from the `filesystem` MCP server without prompting.

### Deny All Tools from a Server

```json
{
  "permissions": {
    "deny": ["mcp__untrusted-server__*"]
  }
}
```

This blocks all tools from the specified server.

### Mixed Permissions

```json
{
  "permissions": {
    "allow": ["mcp__filesystem__*", "mcp__git__*"],
    "deny": ["mcp__slack__send_message"]
  }
}
```

## Permission Evaluation Order (v2.1.27+)

Content-level permissions override tool-level permissions. This enables fine-grained control:

```json
{
  "permissions": {
    "allow": ["Bash"], // Allow all bash commands
    "ask": ["Bash(rm *)"] // EXCEPT: prompt for rm commands
  }
}
```

### Common Override Patterns

**Git with protected commands:**

```json
{
  "permissions": {
    "allow": ["Bash(git *)"],
    "ask": ["Bash(git push --force *)", "Bash(git reset --hard *)"]
  }
}
```

**File operations with protection:**

```json
{
  "permissions": {
    "allow": ["Bash"],
    "ask": ["Bash(rm -rf *)", "Bash(chmod 777 *)"]
  }
}
```

**MCP with selective prompts:**

```json
{
  "permissions": {
    "allow": ["mcp__postgres__*"],
    "ask": ["mcp__postgres__execute"]
  }
}
```

## Common Permission Patterns

### Development (Permissive)

For local development, allow trusted servers:

```json
{
  "permissions": {
    "allow": [
      "mcp__filesystem__*",
      "mcp__git__*",
      "mcp__postgres__query",
      "mcp__brave-search__*"
    ]
  }
}
```

### Production (Restrictive)

For production or sensitive environments:

```json
{
  "permissions": {
    "allow": [
      "mcp__filesystem__read_file",
      "mcp__git__status",
      "mcp__git__log"
    ],
    "deny": [
      "mcp__filesystem__write_file",
      "mcp__git__push",
      "mcp__postgres__*"
    ]
  }
}
```

### Read-Only Mode

For code review or audit scenarios:

```json
{
  "permissions": {
    "allow": [
      "mcp__filesystem__read_file",
      "mcp__filesystem__list_directory",
      "mcp__git__log",
      "mcp__git__diff",
      "mcp__git__status"
    ],
    "deny": ["mcp__*__write*", "mcp__*__delete*", "mcp__*__create*"]
  }
}
```

## Server-Specific Recommendations

### filesystem

- **Allow in dev**: Read/write for local files
- **Restrict in prod**: Read-only, no sensitive directories

### git

- **Allow in dev**: All operations
- **Restrict for review**: Read-only (log, diff, status)
- **Deny push without review**: Prevent accidental pushes

### postgres / database

- **Allow queries**: For read operations
- **Prompt for writes**: Require confirmation for INSERT/UPDATE/DELETE
- **Deny DDL**: Prevent schema changes without review

### github

- **Allow reads**: Issues, PRs, files
- **Prompt for writes**: Creating PRs, comments
- **Deny deletes**: Prevent accidental deletions

### slack / communication

- **Always prompt**: For sending messages
- **Allow reads**: For fetching channel/message info

## Best Practices

1. **Principle of Least Privilege**: Start restrictive, add permissions as needed
2. **Separate Dev/Prod**: Different permission profiles for different environments
3. **Audit Regularly**: Review what permissions are being used
4. **Prompt for Destructive**: Always require confirmation for deletes, pushes
5. **Log MCP Activity**: Track which tools are being invoked

## Setting Permissions

Permissions can be set in:

1. **Global settings**: `~/.claude/settings.json`
2. **Project settings**: `.claude.json` in project root
3. **MCP config**: `.mcp.json` in project root

Example in settings.json:

```json
{
  "permissions": {
    "allow": ["mcp__filesystem__*"],
    "deny": [],
    "prompt": ["mcp__git__push"]
  }
}
```
