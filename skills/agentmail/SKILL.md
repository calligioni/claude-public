---
name: agentmail
description: "Email inbox management for AI agents using AgentMail API. Create inboxes, send/receive emails, reply, forward, and manage messages. Use when users want to send emails, create agent inboxes, check messages, or set up email automations."
user-invocable: true
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# AgentMail - Email Inbox Manager for AI Agents

Give any project or agent its own email inbox with AgentMail. Create, send, receive, reply, forward, and manage emails autonomously.

## Commands

- `/agentmail` - Interactive mode: asks what email operation to perform
- `/agentmail create [username]` - Create a new inbox
- `/agentmail send <to> <subject> <body>` - Send an email
- `/agentmail check [inbox_id]` - Check inbox for new messages
- `/agentmail list` - List all inboxes
- `/agentmail setup` - Run first-time setup (install deps, configure API key)

## Prerequisites

1. **AgentMail API Key**: Get one from [console.agentmail.to](https://console.agentmail.to)
2. **Python 3.10+** (3.13 recommended, 3.14 has compatibility issues)
3. **Environment variable**: `AGENTMAIL_API_KEY` must be set

## Setup

The skill repo lives at `/Volumes/AI/Code/agentmail` with a Python virtual environment at `/Volumes/AI/Code/agentmail/.venv/`.

If the venv doesn't exist or dependencies are missing, run setup:

```bash
SKILL_DIR="/Volumes/AI/Code/agentmail"
python3.13 -m venv "$SKILL_DIR/.venv"
"$SKILL_DIR/.venv/bin/pip" install agentmail python-dotenv websockets
```

Set your API key:
```bash
export AGENTMAIL_API_KEY="your_key_here"
# Or add to ~/.zshrc for persistence
echo 'export AGENTMAIL_API_KEY="your_key_here"' >> ~/.zshrc
```

## IMPORTANT: SDK v0.2.9 API Reference

The AgentMail SDK v0.2.9 has specific attribute names that differ from some documentation. Use these exact patterns:

### Key Types

- **Inbox**: `inbox_id` (email address like `user@agentmail.to`), `display_name`, `pod_id`, `created_at`
- **Message (list)**: `message_id`, `from_` (note underscore), `to`, `subject`, `preview`, `thread_id`, `timestamp`, `labels`
- **Message (full)**: same as list + `text`, `html`, `extracted_text`, `extracted_html`, `attachments`
- **Send response**: `message_id`, `thread_id`
- **List responses**: `.inboxes` for inbox list, `.messages` for message list (NOT `.data`)

## How to Execute Operations

All operations MUST use the venv Python interpreter:
```bash
PYTHON="/Volumes/AI/Code/agentmail/.venv/bin/python3"
```

### Create an Inbox

```bash
$PYTHON -c "
from agentmail import AgentMail
from agentmail.inboxes.types.create_inbox_request import CreateInboxRequest
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
inbox = client.inboxes.create(request=CreateInboxRequest(username='my-agent'))
print(f'Email: {inbox.inbox_id}')
"
```

Without custom username (auto-generated):
```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
inbox = client.inboxes.create()
print(f'Email: {inbox.inbox_id}')
"
```

### List Inboxes

```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
response = client.inboxes.list(limit=20)
for inbox in response.inboxes:
    print(f'{inbox.inbox_id} ({inbox.display_name})')
"
```

### Send an Email

```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
msg = client.inboxes.messages.send(
    inbox_id='sender@agentmail.to',
    to='recipient@example.com',
    subject='Subject here',
    text='Email body here'
)
print(f'Sent! Message ID: {msg.message_id}')
print(f'Thread ID: {msg.thread_id}')
"
```

With HTML body and CC:
```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
msg = client.inboxes.messages.send(
    inbox_id='sender@agentmail.to',
    to='recipient@example.com',
    cc=['cc@example.com'],
    subject='Subject',
    html='<h1>Hello</h1><p>HTML body</p>',
    text='Plain text fallback'
)
print(f'Sent! ID: {msg.message_id}')
"
```

### Check Messages in Inbox

```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
response = client.inboxes.messages.list(inbox_id='user@agentmail.to', limit=10)
for msg in response.messages:
    print(f'From: {msg.from_} | Subject: {msg.subject}')
    if msg.preview:
        print(f'  Preview: {msg.preview[:120]}')
    print(f'  Labels: {msg.labels}')
    print()
"
```

### Get Full Message (with body text/html)

```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
msg = client.inboxes.messages.get(inbox_id='user@agentmail.to', message_id='MESSAGE_ID_HERE')
print(f'From: {msg.from_}')
print(f'Subject: {msg.subject}')
print(f'Body: {msg.text}')
print(f'Thread: {msg.thread_id}')
"
```

### Reply to a Message

The SDK has built-in `reply()` and `reply_all()` methods that handle threading automatically:

```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
reply = client.inboxes.messages.reply(
    inbox_id='user@agentmail.to',
    message_id='MESSAGE_ID_HERE',
    text='Your reply text here'
)
print(f'Reply sent! ID: {reply.message_id}')
print(f'Thread: {reply.thread_id}')
"
```

Reply all:
```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
reply = client.inboxes.messages.reply_all(
    inbox_id='user@agentmail.to',
    message_id='MESSAGE_ID_HERE',
    text='Reply to all recipients'
)
print(f'Reply sent! ID: {reply.message_id}')
"
```

### Forward a Message

```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
fwd = client.inboxes.messages.forward(
    inbox_id='user@agentmail.to',
    message_id='MESSAGE_ID_HERE',
    to='forward-to@example.com',
    text='FYI - see below'
)
print(f'Forwarded! ID: {fwd.message_id}')
"
```

### Check Organization Limits

```bash
$PYTHON -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
org = client.organizations.get()
print(f'Inboxes: {org.inbox_count}/{org.inbox_limit}')
print(f'Daily send limit: {org.daily_send_limit}')
"
```

## Helper Module

For complex operations, use the helper module at `/Volumes/AI/Code/agentmail/agentmail_helper.py`. It provides:

- `AgentMailClient` - High-level wrapper with typed `EmailMessage` returns
- `AgentMailWebSocket` - Real-time email listener with auto-reconnect
- CLI commands: `create_inbox`, `list_inboxes`, `send_email`, `check_inbox`, `org_info`

Usage:
```bash
$PYTHON "/Volumes/AI/Code/agentmail/agentmail_helper.py" list_inboxes
$PYTHON "/Volumes/AI/Code/agentmail/agentmail_helper.py" create_inbox [username]
$PYTHON "/Volumes/AI/Code/agentmail/agentmail_helper.py" send_email <inbox_id> <to> <subject> <body>
$PYTHON "/Volumes/AI/Code/agentmail/agentmail_helper.py" check_inbox <inbox_id> [limit]
$PYTHON "/Volumes/AI/Code/agentmail/agentmail_helper.py" org_info
```

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| 401 Unauthorized | Missing or malformed API key | Check AGENTMAIL_API_KEY is set correctly |
| 403 Forbidden + `LimitExceededError` | Inbox limit reached on current plan | Upgrade plan or delete unused inboxes |
| 403 Forbidden | Invalid, expired, or revoked API key | Regenerate key at console.agentmail.to |
| 404 Not Found | Wrong inbox_id or message_id | Verify IDs with list commands |
| 429 Rate Limited | Too many requests | Wait and retry, or upgrade plan |

## API Reference

- **Base URL**: `https://api.agentmail.to` (v0 endpoints)
- **WebSocket URL**: `wss://ws.agentmail.to`
- **Auth**: Bearer token via `Authorization` header
- **SDK**: `agentmail` (Python), v0.2.9+
- **Docs**: [docs.agentmail.to](https://docs.agentmail.to)

## Pricing

| Plan | Inboxes | Emails/month | Price |
|------|---------|--------------|-------|
| Free | 3 | 3,000 | $0 |
| Starter | 25 | 25,000 | $25/mo |
| Pro | 100 | 100,000 | $100/mo |
| Business | 300 | 300,000 | $500/mo |

## Workflow Tips

1. **First use**: Run `/agentmail setup` to verify dependencies and API key
2. **inbox_id = email address**: The inbox ID is the full email address (e.g., `user123@agentmail.to`)
3. **Use reply() for threads**: The SDK's `reply()` method handles subject prefixing and threading automatically
4. **List vs Get**: `messages.list()` returns previews; use `messages.get()` for full body text/html
5. **Labels**: Messages have labels like `sent`, `received`, `unread` - use them to filter
6. **HTML + text**: Send both HTML and plain text bodies for maximum compatibility
