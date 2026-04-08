---
name: claude-api
description: "Build apps with the Claude API or Anthropic SDK. Covers Messages API, Managed Agents API, Agent SDK, tool use, streaming, and MCP integration. TRIGGER when: code imports `anthropic`/`@anthropic-ai/sdk`/`claude_agent_sdk`, or user asks to use Claude API, Anthropic SDKs, or Agent SDK. DO NOT TRIGGER when: code imports `openai`/other AI SDK, general coding questions."
user-invocable: true
context: inline
model: sonnet
effort: medium
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - WebSearch
  - Agent
  - AskUserQuestion
tool-annotations:
  WebFetch: { readOnlyHint: true, openWorldHint: true }
---

# Claude API Skill

Help users build applications with the Claude API and Anthropic SDKs. This skill covers two primary integration paths:

1. **Messages API** — Direct model prompting with fine-grained control
2. **Claude Managed Agents** — Pre-built agent harness with managed cloud infrastructure

## When to Use Which

| Need                                               | Use                   |
| -------------------------------------------------- | --------------------- |
| Custom agent loops, fine-grained control           | Messages API          |
| Long-running tasks, async work, minimal infra      | Claude Managed Agents |
| Real-time streaming chat                           | Messages API          |
| Agent with file ops, bash, web search in a sandbox | Claude Managed Agents |
| Tool use with client-side execution                | Messages API          |
| Tool use with server-side execution                | Claude Managed Agents |

---

## Part 1: Messages API

### SDK Installation

```bash
# Python
pip install anthropic

# TypeScript
npm install @anthropic-ai/sdk

# Go
go get github.com/anthropics/anthropic-sdk-go
```

### Basic Usage

```python
from anthropic import Anthropic

client = Anthropic()

message = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Hello, Claude"}
    ]
)
print(message.content[0].text)
```

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-sonnet-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello, Claude" }],
});
console.log(message.content[0].text);
```

### Streaming

```python
with client.messages.stream(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello"}],
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
```

```typescript
const stream = client.messages.stream({
  model: "claude-sonnet-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello" }],
});

for await (const event of stream) {
  if (
    event.type === "content_block_delta" &&
    event.delta.type === "text_delta"
  ) {
    process.stdout.write(event.delta.text);
  }
}
```

### Tool Use

```python
message = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    tools=[
        {
            "name": "get_weather",
            "description": "Get current weather for a location",
            "input_schema": {
                "type": "object",
                "properties": {
                    "location": {"type": "string", "description": "City name"}
                },
                "required": ["location"]
            }
        }
    ],
    messages=[{"role": "user", "content": "What's the weather in Tokyo?"}]
)

# Check if Claude wants to use a tool
for block in message.content:
    if block.type == "tool_use":
        tool_name = block.name
        tool_input = block.input
        # Execute the tool and send result back
```

### Models

| Model      | ID                          | Best For                                  |
| ---------- | --------------------------- | ----------------------------------------- |
| Opus 4.6   | `claude-opus-4-6`           | Complex reasoning, architecture, security |
| Sonnet 4.6 | `claude-sonnet-4-6`         | Balanced performance and cost             |
| Haiku 4.5  | `claude-haiku-4-5-20251001` | Fast, lightweight tasks                   |

### Extended Thinking

```python
message = client.messages.create(
    model="claude-opus-4-6",
    max_tokens=16000,
    thinking={"type": "enabled", "budget_tokens": 10000},
    messages=[{"role": "user", "content": "Solve this complex problem..."}]
)
```

---

## Part 2: Claude Managed Agents (Beta — 2026-04-08)

A fully managed agent runtime. Instead of building your own agent loop, tool execution, and sandbox, you get a cloud environment where Claude can read files, run commands, browse the web, and execute code autonomously.

### Beta Header

All Managed Agents requests require:

```
anthropic-beta: managed-agents-2026-04-01
```

The SDK sets this automatically.

### Core Concepts

| Concept         | Description                                                                               |
| --------------- | ----------------------------------------------------------------------------------------- |
| **Agent**       | Model + system prompt + tools + MCP servers + skills. Created once, referenced by ID.     |
| **Environment** | Cloud container template (packages, network rules, mounted files)                         |
| **Session**     | Running agent instance within an environment. Stateful, persistent across disconnections. |
| **Events**      | SSE-streamed messages in/out (user turns, tool results, status updates)                   |

### Built-In Tools

| Tool       | Name         | Description                            |
| ---------- | ------------ | -------------------------------------- |
| Bash       | `bash`       | Execute bash commands in the container |
| Read       | `read`       | Read files from the filesystem         |
| Write      | `write`      | Write files to the filesystem          |
| Edit       | `edit`       | String replacement in files            |
| Glob       | `glob`       | File pattern matching                  |
| Grep       | `grep`       | Regex text search                      |
| Web Fetch  | `web_fetch`  | Fetch content from URLs                |
| Web Search | `web_search` | Search the web                         |

All enabled by default with `agent_toolset_20260401`.

### Quickstart — Python

```python
from anthropic import Anthropic

client = Anthropic()

# 1. Create an agent (once)
agent = client.beta.agents.create(
    name="Coding Assistant",
    model="claude-sonnet-4-6",
    system="You are a helpful coding assistant.",
    tools=[{"type": "agent_toolset_20260401"}],
)

# 2. Create an environment (once)
environment = client.beta.environments.create(
    name="dev-env",
    config={"type": "cloud", "networking": {"type": "unrestricted"}},
)

# 3. Start a session
session = client.beta.sessions.create(
    agent=agent.id,
    environment_id=environment.id,
    title="My task",
)

# 4. Stream events and send a message
with client.beta.sessions.events.stream(session.id) as stream:
    client.beta.sessions.events.send(
        session.id,
        events=[{
            "type": "user.message",
            "content": [{"type": "text", "text": "Build a REST API with FastAPI"}],
        }],
    )

    for event in stream:
        match event.type:
            case "agent.message":
                for block in event.content:
                    print(block.text, end="")
            case "agent.tool_use":
                print(f"\n[Using tool: {event.name}]")
            case "session.status_idle":
                print("\n\nAgent finished.")
                break
```

### Quickstart — TypeScript

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// 1. Create an agent (once)
const agent = await client.beta.agents.create({
  name: "Coding Assistant",
  model: "claude-sonnet-4-6",
  system: "You are a helpful coding assistant.",
  tools: [{ type: "agent_toolset_20260401" }],
});

// 2. Create an environment (once)
const environment = await client.beta.environments.create({
  name: "dev-env",
  config: { type: "cloud", networking: { type: "unrestricted" } },
});

// 3. Start a session
const session = await client.beta.sessions.create({
  agent: agent.id,
  environment_id: environment.id,
  title: "My task",
});

// 4. Stream events and send a message
const stream = await client.beta.sessions.events.stream(session.id);

await client.beta.sessions.events.send(session.id, {
  events: [
    {
      type: "user.message",
      content: [{ type: "text", text: "Build a REST API with Express" }],
    },
  ],
});

for await (const event of stream) {
  if (event.type === "agent.message") {
    for (const block of event.content) {
      process.stdout.write(block.text);
    }
  } else if (event.type === "agent.tool_use") {
    console.log(`\n[Using tool: ${event.name}]`);
  } else if (event.type === "session.status_idle") {
    console.log("\n\nAgent finished.");
    break;
  }
}
```

### API Endpoints

| Method | Endpoint                    | Description                        |
| ------ | --------------------------- | ---------------------------------- |
| POST   | `/v1/agents`                | Create an agent                    |
| GET    | `/v1/agents/{id}`           | Retrieve agent                     |
| POST   | `/v1/agents/{id}`           | Update agent (creates new version) |
| DELETE | `/v1/agents/{id}`           | Delete agent                       |
| GET    | `/v1/agents`                | List agents                        |
| POST   | `/v1/environments`          | Create environment                 |
| GET    | `/v1/environments/{id}`     | Retrieve environment               |
| POST   | `/v1/environments/{id}`     | Update environment                 |
| DELETE | `/v1/environments/{id}`     | Delete environment                 |
| GET    | `/v1/environments`          | List environments                  |
| POST   | `/v1/sessions`              | Create session                     |
| GET    | `/v1/sessions/{id}`         | Retrieve session                   |
| POST   | `/v1/sessions/{id}`         | Update session metadata            |
| DELETE | `/v1/sessions/{id}`         | Delete session                     |
| POST   | `/v1/sessions/{id}/archive` | Archive session                    |
| GET    | `/v1/sessions`              | List sessions                      |
| POST   | `/v1/sessions/{id}/events`  | Send events to session             |
| GET    | `/v1/sessions/{id}/events`  | List session events                |
| GET    | `/v1/sessions/{id}/stream`  | Stream session events (SSE)        |

### Event Types

**Client → Agent:**

| Type                      | Description                        |
| ------------------------- | ---------------------------------- |
| `user.message`            | Send a text/image/document message |
| `user.interrupt`          | Interrupt the agent mid-execution  |
| `user.tool_confirmation`  | Allow/deny a tool use request      |
| `user.custom_tool_result` | Return result for a custom tool    |

**Agent → Client:**

| Type                    | Description                         |
| ----------------------- | ----------------------------------- |
| `agent.message`         | Agent text response                 |
| `agent.thinking`        | Agent thinking (extended thinking)  |
| `agent.tool_use`        | Agent using a built-in tool         |
| `agent.tool_result`     | Result from a built-in tool         |
| `agent.mcp_tool_use`    | Agent calling an MCP tool           |
| `agent.mcp_tool_result` | Result from an MCP tool             |
| `agent.custom_tool_use` | Agent requesting a custom tool call |

**Session Status:**

| Type                        | Description                          |
| --------------------------- | ------------------------------------ |
| `session.status_idle`       | Agent finished (check `stop_reason`) |
| `session.status_running`    | Agent is processing                  |
| `session.status_terminated` | Session ended                        |

### Tool Configuration

**Enable all tools:**

```json
{ "type": "agent_toolset_20260401" }
```

**Disable specific tools:**

```json
{
  "type": "agent_toolset_20260401",
  "configs": [
    { "name": "web_fetch", "enabled": false },
    { "name": "web_search", "enabled": false }
  ]
}
```

**Allowlist only specific tools:**

```json
{
  "type": "agent_toolset_20260401",
  "default_config": { "enabled": false },
  "configs": [
    { "name": "bash", "enabled": true },
    { "name": "read", "enabled": true },
    { "name": "write", "enabled": true }
  ]
}
```

### Custom Tools

Define client-executed tools alongside built-in tools:

```python
agent = client.beta.agents.create(
    name="Weather Agent",
    model="claude-sonnet-4-6",
    tools=[
        {"type": "agent_toolset_20260401"},
        {
            "type": "custom",
            "name": "get_weather",
            "description": "Get current weather for a location",
            "input_schema": {
                "type": "object",
                "properties": {
                    "location": {"type": "string", "description": "City name"}
                },
                "required": ["location"]
            }
        }
    ],
)
```

When Claude calls a custom tool, you receive an `agent.custom_tool_use` event and respond with `user.custom_tool_result`.

### MCP Servers

First-class in Agent config — no custom adapter code needed:

```python
agent = client.beta.agents.create(
    name="Agent with MCP",
    model="claude-sonnet-4-6",
    tools=[{"type": "agent_toolset_20260401"}],
    mcp_servers=[{
        "name": "my-server",
        "type": "url",
        "url": "https://my-mcp-server.example.com/sse"
    }],
)
```

### Session Resources

Mount GitHub repos or files into the session container:

```python
session = client.beta.sessions.create(
    agent=agent.id,
    environment_id=environment.id,
    resources=[{
        "type": "github_repository",
        "url": "https://github.com/owner/repo",
        "authorization_token": "ghp_...",
        "checkout": {"type": "branch", "name": "main"}
    }],
)
```

### Pricing

| Component       | Cost               |
| --------------- | ------------------ |
| Token usage     | Standard API rates |
| Session runtime | $0.08/session-hour |
| Web searches    | $10/1,000 searches |

### Rate Limits

| Operation       | Limit           |
| --------------- | --------------- |
| Create requests | 60/min per org  |
| Read requests   | 600/min per org |

### Research Preview Features (request access)

- **Outcomes** — Self-evaluation and iteration toward defined outcomes
- **Multi-agent coordination** — Agents monitor/coordinate with other Claude agents
- **Memory** — Persistent agent memory across sessions

Request access: https://claude.com/form/claude-managed-agents

### CLI Tool (`ant`)

```bash
# Install
brew install anthropics/tap/ant

# Create agent
ant beta:agents create \
  --name "Coding Assistant" \
  --model claude-sonnet-4-6 \
  --system "You are a helpful coding assistant." \
  --tool '{type: agent_toolset_20260401}'

# Create environment
ant beta:environments create \
  --name "dev-env" \
  --config '{type: cloud, networking: {type: unrestricted}}'
```

### Branding Rules

Partners integrating Claude Managed Agents:

- **Allowed:** "Claude Agent", "Claude", "{YourAgent} Powered by Claude"
- **NOT allowed:** "Claude Code", "Claude Cowork", or any mimicry of Anthropic products

---

## Reference Links

- Messages API: https://platform.claude.com/docs/en/build-with-claude/working-with-messages
- Managed Agents Overview: https://platform.claude.com/docs/en/managed-agents/overview
- Managed Agents Quickstart: https://platform.claude.com/docs/en/managed-agents/quickstart
- Managed Agents API Reference: https://platform.claude.com/docs/en/api/beta/sessions
- Managed Agents Tools: https://platform.claude.com/docs/en/managed-agents/tools
- SDK (Python): https://pypi.org/project/anthropic/
- SDK (TypeScript): https://www.npmjs.com/package/@anthropic-ai/sdk
