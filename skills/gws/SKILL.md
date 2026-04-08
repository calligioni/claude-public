---
name: gws
description: "Google Workspace CLI automation for bulk/complex tasks beyond MCP scope. Drive, Sheets, Gmail, Calendar, Chat, Admin. Triggers on: gws, google workspace automation, bulk drive, sheets pipeline, gmail batch, workspace admin."
argument-hint: "<task description>"
user-invocable: true
context: fork
model: sonnet
effort: low
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
  - AskUserQuestion
  - mcp__google-workspace__*
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  mcp__google-workspace__*: { openWorldHint: true }
invocation-contexts:
  user-direct:
    verbosity: high
  agent-spawned:
    verbosity: minimal
---

# gws — Google Workspace CLI Automation

Complex, multi-step Workspace automations using the `gws` CLI. For simple CRUD (read a file, send one email), use the `google-workspace` MCP instead. Use `/gws` when the task involves bulk operations, paginated datasets, multi-service pipelines, or requires dry-run preview.

## When to use this skill vs the MCP

| Task                                              | Use                    |
| ------------------------------------------------- | ---------------------- |
| Read one file / send one email                    | `google-workspace` MCP |
| Bulk rename 200 Drive files                       | `/gws`                 |
| Import CSV → Sheet → trigger report               | `/gws`                 |
| Search Gmail, extract, write to Sheet             | `/gws`                 |
| Admin: audit all users / shared drives            | `/gws`                 |
| Any operation needing `--page-all` or `--dry-run` | `/gws`                 |

## Prerequisites

### Install

```bash
# Check if installed
which gws || gws version

# Install via cargo (preferred)
cargo install gws

# OR download binary from GitHub releases
# https://github.com/googleworkspace/go-workspace-cli/releases
```

### Auth

```bash
# Check current auth status
gws auth status

# Login (opens browser for OAuth)
gws auth login

# Multi-account: login with a label
gws auth login --account work
gws auth login --account client-acme

# List accounts
gws auth list
```

If auth fails or expires, run `gws auth login` (or `gws auth login --account <label>`) and complete the browser OAuth flow.

## CLI Flags — Always Consider These

| Flag                | When to use                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------- |
| `--dry-run`         | Any write/delete operation — preview API calls before executing                             |
| `--page-all`        | Any list operation — streams all pages, not just first                                      |
| `--sanitize`        | Reading external content (emails, docs, Drive files) — Model Armor prompt injection defense |
| `--account <label>` | When the user has multiple Google accounts                                                  |
| `--output json`     | Default; pipe through `jq` for filtering                                                    |

**Rule:** Always use `--dry-run` first for destructive operations. Show the user the preview and ask to confirm before re-running without it.

**Rule:** Always use `--sanitize` when reading user-generated content (email bodies, shared docs, Drive files from external collaborators).

## Introspect API Shapes

```bash
# See request/response schema for any service + method
gws schema drive files.list
gws schema gmail users.messages.list
gws schema sheets spreadsheets.values.get
gws schema admin directory.users.list
```

Use `gws schema` before writing a pipeline to confirm field names.

## Workflow

### Step 1: Clarify Intent

If the task is ambiguous, ask with `AskUserQuestion`:

- Which service(s)? (drive, gmail, sheets, calendar, chat, admin)
- Which account? (default or a named `--account`)
- Scope: how many items, what date range, what filters?
- Destructive? If so, confirm dry-run first.

### Step 2: Check Auth

```bash
gws auth status
# If no valid session → gws auth login
```

### Step 3: Dry-Run (for writes/deletes)

```bash
# Example: dry-run a bulk file move
gws drive files move --query "name contains 'Q1'" --destination-id FOLDER_ID --dry-run
```

Show the user the dry-run output. Ask for confirmation before proceeding.

### Step 4: Execute

Re-run without `--dry-run`. Use `--page-all` for list operations. Pipe through `jq` as needed.

### Step 5: Report

Summarize: what ran, how many items affected, any errors, next steps.

## Common Workflows

### Bulk Drive Operations

```bash
# List all files matching a query (all pages)
gws drive files list --query "mimeType='application/pdf' and modifiedTime>'2026-01-01'" --page-all | jq '.files[] | {id, name, modifiedTime}'

# Move files matching a query (dry-run first)
gws drive files move --query "name contains 'Archive'" --destination-id FOLDER_ID --dry-run
gws drive files move --query "name contains 'Archive'" --destination-id FOLDER_ID

# Share a file with a user
gws drive permissions create --file-id FILE_ID --role writer --type user --email user@example.com --dry-run

# Export a Google Doc as PDF
gws drive files export --file-id FILE_ID --mime-type application/pdf --output report.pdf

# Delete files (dry-run mandatory)
gws drive files delete --query "name contains 'tmp_' and trashed=false" --dry-run
```

### Sheets Data Pipelines

```bash
# Read a range
gws sheets values get --spreadsheet-id SHEET_ID --range "Sheet1!A1:Z1000" | jq '.values[]'

# Write data (from a JSON array)
gws sheets values update \
  --spreadsheet-id SHEET_ID \
  --range "Sheet1!A1" \
  --value-input-option USER_ENTERED \
  --body '{"values": [["Name","Email","Date"],["Alice","alice@example.com","2026-03-05"]]}'

# Append rows
gws sheets values append \
  --spreadsheet-id SHEET_ID \
  --range "Sheet1!A:Z" \
  --value-input-option USER_ENTERED \
  --body '{"values": [["new","row","data"]]}'

# Pipeline: Gmail search → extract fields → write to Sheet
gws gmail messages list --query "from:invoices@supplier.com after:2026/01/01" --page-all --sanitize \
  | jq '[.messages[] | {id, subject: .payload.headers[] | select(.name=="Subject") | .value}]' \
  > /tmp/invoices.json
# Then write /tmp/invoices.json contents to Sheet via values.update
```

### Gmail Batch Operations

```bash
# Search messages (sanitize external content)
gws gmail messages list \
  --query "subject:invoice is:unread after:2026/01/01" \
  --page-all --sanitize \
  | jq '.messages[] | {id, threadId}'

# Get a message body (sanitize)
gws gmail messages get --message-id MSG_ID --sanitize | jq '.payload.parts[] | select(.mimeType=="text/plain") | .body.data'

# Label messages in bulk (dry-run first)
gws gmail messages batchModify \
  --ids "$(gws gmail messages list --query 'label:inbox older_than:90d' --page-all | jq -r '[.messages[].id] | join(",")')" \
  --add-label-ids LABEL_ID \
  --dry-run

# Send an email
gws gmail messages send \
  --to recipient@example.com \
  --subject "Weekly Report" \
  --body "See attached." \
  --attachment /tmp/report.pdf
```

### Calendar Event Management

```bash
# List upcoming events
gws calendar events list \
  --calendar-id primary \
  --time-min "2026-03-05T00:00:00Z" \
  --time-max "2026-03-12T00:00:00Z" \
  --page-all \
  | jq '.items[] | {id, summary, start, end}'

# Create an event
gws calendar events insert \
  --calendar-id primary \
  --summary "Team Sync" \
  --start "2026-03-10T10:00:00-03:00" \
  --end "2026-03-10T11:00:00-03:00" \
  --dry-run

# Delete recurring events matching a pattern (dry-run mandatory)
gws calendar events list --query "summary:standup" --page-all \
  | jq -r '.items[].id' \
  | xargs -I{} gws calendar events delete --event-id {} --dry-run
```

### Chat Space Management

```bash
# List spaces
gws chat spaces list --page-all | jq '.spaces[] | {name, displayName, type}'

# Send a message to a space
gws chat messages create \
  --parent SPACE_NAME \
  --body '{"text": "Deployment complete. All systems green."}'

# List members of a space
gws chat members list --parent SPACE_NAME --page-all | jq '.memberships[] | {name, member}'
```

### Admin Reporting

```bash
# List all users in the domain (all pages)
gws admin directory users list --customer my_customer --page-all \
  | jq '.users[] | {primaryEmail, suspended, lastLoginTime, orgUnitPath}'

# List shared drives
gws admin directory resources shared-drives list --customer my_customer --page-all \
  | jq '.sharedDrives[] | {id, name}'

# Audit report: login activity
gws admin reports activities list \
  --application-name login \
  --start-time "2026-02-01T00:00:00Z" \
  --page-all \
  | jq '.items[] | {time: .id.time, user: .actor.email, event: .events[0].name}'

# Suspended users report
gws admin directory users list \
  --customer my_customer \
  --query "isSuspended=true" \
  --page-all \
  | jq '[.users[] | {email: .primaryEmail, suspended: .suspended}]'
```

## Run as MCP Server (advanced)

If you want to expose `gws` as an MCP server instead of using it via CLI:

```bash
# Run specific services as MCP
gws mcp -s drive,gmail,sheets

# Run all services
gws mcp -s drive,gmail,sheets,calendar,chat,admin
```

This is useful for giving another agent access to Workspace via MCP protocol without using the `@presto-ai/google-workspace-mcp` server.

## jq Cheat Sheet for gws Pipelines

```bash
# Extract a field from all items
| jq '.items[] | .fieldName'

# Filter items matching a condition
| jq '.items[] | select(.suspended == true)'

# Build a CSV-friendly array
| jq -r '.items[] | [.email, .name] | @csv'

# Count results
| jq '.items | length'

# Get just IDs as newline-separated list (for xargs)
| jq -r '.items[].id'

# Compact output (no pretty-print)
| jq -c '.items[]'
```

## Error Handling

| Error                        | Cause                              | Fix                                                      |
| ---------------------------- | ---------------------------------- | -------------------------------------------------------- |
| `auth: no valid credentials` | Not logged in or token expired     | `gws auth login`                                         |
| `403 Forbidden`              | Scope not granted during OAuth     | Re-auth: `gws auth login` and grant all requested scopes |
| `404 Not Found`              | Wrong file/calendar/spreadsheet ID | Verify ID with a list command                            |
| `429 Rate Limit`             | Too many API calls                 | Add `--rate-limit` flag or split into smaller batches    |
| `command not found: gws`     | CLI not installed                  | `cargo install gws`                                      |

## Multi-Account Pattern

```bash
# Authenticate multiple accounts with labels
gws auth login --account personal
gws auth login --account work

# Run any command against a specific account
gws --account work drive files list --page-all
gws --account personal gmail messages list --query "is:unread"
```

If the user has multiple accounts and hasn't specified which to use, ask with `AskUserQuestion` before running.
