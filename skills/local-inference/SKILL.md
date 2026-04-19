---
name: local-inference
description: "Set up a local multi-model inference gateway with LiteLLM. Routes tasks to local models (MLX, Ollama) with cloud fallback (OpenRouter, Anthropic). Use alongside Claude Max. Triggers on: local inference, setup litellm, model gateway, local models, inference gateway, multi-model setup, run local models"
user-invocable: true
context: fork
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
  - AskUserQuestion
tool-annotations:
  Bash: { destructiveHint: false }
---

# Local Inference Gateway

Set up a unified, multi-model inference gateway using [LiteLLM](https://github.com/BerriAI/litellm). Run local models on your Mac (MLX, Ollama) with automatic cloud fallback (OpenRouter, Anthropic) — all behind a single OpenAI-compatible API at `http://localhost:4000/v1`.

Use this alongside your Claude Max plan. Claude handles orchestration and complex reasoning. Local models handle the cheap stuff — summarization, formatting, classification, text generation — for free.

---

## Table of Contents

1. [Why](#why)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Step-by-Step Setup](#step-by-step-setup)
5. [Configuration Reference](#configuration-reference)
6. [Usage Examples](#usage-examples)
7. [Model Recommendations](#model-recommendations)
8. [Persistence (Auto-Start)](#persistence-auto-start)
9. [Monitoring & Debugging](#monitoring--debugging)
10. [Integration with Claude Code](#integration-with-claude-code)
11. [Troubleshooting](#troubleshooting)
12. [Skill Workflow](#skill-workflow)

---

## Why

| Without gateway                         | With gateway                                       |
| --------------------------------------- | -------------------------------------------------- |
| Every API call goes to Anthropic/OpenAI | Cheap tasks routed to free local models            |
| If the API is down, you're stuck        | Automatic fallback across multiple backends        |
| Multiple endpoints to manage            | One endpoint: `localhost:4000/v1`                  |
| Pay per token for everything            | Local inference = $0, only pay for complex tasks   |
| Models locked to one provider           | Mix models from MLX, Ollama, OpenRouter, Anthropic |

**Real-world cost impact:** A typical development session generates hundreds of small LLM calls (linting, formatting, classification, summarization). At ~$0.003/call on Sonnet, that's $1-3/day. With a local gateway, those calls are free. You still use Claude Max for the 10-20% of calls that need deep reasoning.

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  YOUR APPLICATIONS                                        │
│  ─────────────────                                        │
│  Claude Code  ·  Python scripts  ·  curl  ·  any app     │
│  that speaks the OpenAI API format                        │
└────────────────────────┬─────────────────────────────────┘
                         │ HTTP POST to localhost:4000/v1
                         ▼
┌──────────────────────────────────────────────────────────┐
│  LITELLM GATEWAY (http://localhost:4000)                  │
│  ──────────────────────────────────────                   │
│  Routes requests by model name                            │
│  Automatic fallback if a backend fails                    │
│  Retries, timeouts, load balancing                        │
│  OpenAI-compatible API in, OpenAI-compatible API out      │
└────────┬──────────┬──────────┬──────────┬────────────────┘
         │          │          │          │
         ▼          ▼          ▼          ▼
┌────────────┐ ┌─────────┐ ┌──────────┐ ┌──────────────┐
│ MLX LM     │ │ Ollama  │ │ Open-    │ │ Anthropic    │
│ Server     │ │         │ │ Router   │ │ (Claude)     │
│            │ │         │ │          │ │              │
│ Port 1235  │ │ Port    │ │ Cloud    │ │ Cloud API    │
│ Apple      │ │ 11434   │ │ API      │ │              │
│ Silicon    │ │ Any     │ │ Free     │ │ Max plan     │
│ fastest    │ │ platform│ │ previews │ │ or API key   │
└────────────┘ └─────────┘ └──────────┘ └──────────────┘
   Tier 0a       Tier 0b     Tier 0c       Tier 1

Fallback order: 0a → 0b → 0c → 1
(configurable — skip any tier you don't need)
```

**How fallback works:** When you send `{"model": "local", ...}` to the gateway, LiteLLM tries Tier 0a first. If it times out or errors (model not loaded, server down), it automatically tries 0b, then 0c. You get a response from whichever backend is available — your application never sees the failure.

---

## Prerequisites

### Minimum Requirements

| Requirement | Details                                                          |
| ----------- | ---------------------------------------------------------------- |
| **OS**      | macOS 12+ (Apple Silicon recommended), Linux, or Windows WSL2    |
| **Python**  | 3.10 or higher (pre-installed on modern macOS)                   |
| **RAM**     | 8GB minimum (for 7B models), 16GB+ recommended (for 14B+ models) |
| **Disk**    | 5-15GB per model (4-bit quantized)                               |

### What You Need to Provide

| Backend           | Required?           | What you need                                                                   |
| ----------------- | ------------------- | ------------------------------------------------------------------------------- |
| **MLX LM Server** | Optional (Mac only) | Apple Silicon Mac + `pip install mlx-lm`                                        |
| **Ollama**        | Optional (any OS)   | `curl -fsSL https://ollama.com/install.sh \| sh`                                |
| **OpenRouter**    | Optional (cloud)    | Free API key from [openrouter.ai](https://openrouter.ai)                        |
| **Anthropic**     | Optional (cloud)    | API key from [console.anthropic.com](https://console.anthropic.com) or Max plan |

You need at least ONE backend. The gateway gets more useful the more backends you add (more fallback options).

---

## Step-by-Step Setup

### Step 1: Check Your Environment

Run these commands to see what you already have:

```bash
# What OS and architecture?
uname -sm
# Expected: "Darwin arm64" for Apple Silicon Mac
# Expected: "Darwin x86_64" for Intel Mac
# Expected: "Linux x86_64" for Linux

# Python version?
python3 --version
# Need 3.10+. If missing: brew install python@3.12

# Already have Ollama?
curl -s http://localhost:11434/api/tags 2>/dev/null | head -c 200
# If you see JSON with model names, Ollama is running

# Already have MLX LM Server?
curl -s http://localhost:1235/v1/models 2>/dev/null | head -c 200
# If you see JSON with model info, MLX is running

# Already have LiteLLM?
which litellm 2>/dev/null && litellm --version
# If found, you can skip the install step

# How much RAM?
sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f GB\n", $1/1073741824}'
# 8GB = 7B models, 16GB = 14B models, 32GB+ = 35B+ models
```

### Step 2: Install LiteLLM

```bash
# Install LiteLLM with proxy support
pip install 'litellm[proxy]'

# Verify installation
litellm --version

# If "litellm: command not found", try:
python3 -m litellm --version
# If that works, use "python3 -m litellm" instead of "litellm" in all commands below
```

### Step 3: Install at Least One Backend

Pick one or more backends based on your hardware:

#### Option A: Ollama (Recommended — Works Everywhere)

Ollama is the easiest way to run local models. Works on Mac, Linux, and Windows.

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a model (pick based on your RAM)
# 8GB RAM:
ollama pull qwen2.5:7b           # 4.7GB, good general-purpose

# 16GB RAM:
ollama pull qwen2.5:14b          # 9.0GB, better reasoning
ollama pull qwen2.5-coder:7b     # 4.7GB, code generation

# 32GB+ RAM:
ollama pull qwen2.5:32b          # 19GB, near-GPT-4 quality
ollama pull deepseek-r1:14b      # 9.0GB, strong reasoning

# Verify Ollama is running
curl -s http://localhost:11434/api/tags | python3 -m json.tool
# You should see your pulled models listed
```

**What just happened:** Ollama downloaded a quantized model to `~/.ollama/models/` and started a server at `localhost:11434`. It auto-starts on boot.

#### Option B: MLX LM Server (Mac Apple Silicon Only — Fastest)

MLX is Apple's ML framework. It runs models directly on the GPU/Neural Engine, making it the fastest option on Apple Silicon.

```bash
# Install MLX LM
pip install mlx-lm

# Download and start a model server
# For 8GB RAM:
mlx_lm.server --model mlx-community/Qwen2.5-7B-Instruct-4bit --port 1235 &

# For 16GB+ RAM:
mlx_lm.server --model mlx-community/Qwen2.5-14B-Instruct-4bit --port 1235 &

# For 32GB+ RAM (recommended — MoE architecture, only 3B active params):
mlx_lm.server --model mlx-community/Qwen3.5-35B-A3B-4bit --port 1235 &

# Verify it's running
curl -s http://localhost:1235/v1/models | python3 -m json.tool
```

**What just happened:** MLX downloaded the model from HuggingFace (~4-9GB), loaded it into unified memory, and started an OpenAI-compatible server at `localhost:1235`. The `&` runs it in the background.

**Note:** MLX LM Server does NOT auto-start on boot. See [Persistence](#persistence-auto-start) to set that up.

#### Option C: OpenRouter (Cloud — Free Preview Models)

OpenRouter gives you access to dozens of models through one API. Many new models are free during their preview period.

```bash
# 1. Go to https://openrouter.ai and create a free account
# 2. Go to https://openrouter.ai/keys and create an API key
# 3. Set the environment variable:
export OPENROUTER_API_KEY="sk-or-v1-your-key-here"

# Add to your shell profile so it persists:
echo 'export OPENROUTER_API_KEY="sk-or-v1-your-key-here"' >> ~/.zshrc

# Verify it works
curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen/qwen3-235b-a22b", "messages": [{"role": "user", "content": "Hi"}], "max_tokens": 5}'
```

#### Option D: Anthropic API (Claude — For Max Plan Users)

If you have a Claude Max plan or an Anthropic API key:

```bash
# Set your API key
export ANTHROPIC_API_KEY="sk-ant-your-key-here"

# Add to your shell profile
echo 'export ANTHROPIC_API_KEY="sk-ant-your-key-here"' >> ~/.zshrc
```

### Step 4: Create the LiteLLM Configuration

Create a config directory and file:

```bash
mkdir -p ~/.config/litellm
```

Now create `~/.config/litellm/config.yaml`. **Include only the backends you installed in Step 3.** Below is the full config with all backends — remove sections you don't need.

```yaml
# ~/.config/litellm/config.yaml
# LiteLLM Gateway Configuration
#
# How it works:
# - Entries with the SAME model_name form a fallback chain
# - LiteLLM tries them top-to-bottom
# - If one fails (timeout, error, down), it tries the next
# - First successful response wins

model_list:
  # ──────────────────────────────────────────────────────
  # MODEL NAME: "local"
  # Use for: general text tasks, summarization, Q&A
  # Fallback: MLX → Ollama → OpenRouter
  # ──────────────────────────────────────────────────────

  # Tier 0a: MLX LM Server (Apple Silicon, fastest, ~100 tok/s)
  # Remove this block if you don't have MLX installed
  - model_name: local
    litellm_params:
      model: openai/mlx-model # Name doesn't matter for routing
      api_base: http://localhost:1235/v1
      api_key: none # MLX doesn't need auth
      max_tokens: 4096
      timeout: 15 # Short timeout — if MLX is down, fail fast

  # Tier 0b: Ollama (any platform, flexible)
  # Remove this block if you don't have Ollama installed
  - model_name: local
    litellm_params:
      model: ollama/qwen2.5:14b # Must match a pulled model name
      api_base: http://localhost:11434
      timeout: 30 # Ollama may need to load model into RAM

  # Tier 0c: OpenRouter (cloud, free preview models)
  # Remove this block if you don't have an OpenRouter key
  - model_name: local
    litellm_params:
      model: openrouter/qwen/qwen3-235b-a22b
      api_key: os.environ/OPENROUTER_API_KEY
      timeout: 30

  # ──────────────────────────────────────────────────────
  # MODEL NAME: "code"
  # Use for: code generation, code review, refactoring
  # Fallback: Ollama code model → OpenRouter
  # ──────────────────────────────────────────────────────

  - model_name: code
    litellm_params:
      model: ollama/qwen2.5-coder:7b
      api_base: http://localhost:11434
      timeout: 30

  - model_name: code
    litellm_params:
      model: openrouter/qwen/qwen-2.5-coder-32b-instruct
      api_key: os.environ/OPENROUTER_API_KEY
      timeout: 30

  # ──────────────────────────────────────────────────────
  # MODEL NAME: "claude"
  # Use for: complex reasoning routed through the gateway
  # No fallback — this is the premium tier
  # ──────────────────────────────────────────────────────

  - model_name: claude
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: os.environ/ANTHROPIC_API_KEY
      timeout: 60

  - model_name: claude-opus
    litellm_params:
      model: anthropic/claude-opus-4-6
      api_key: os.environ/ANTHROPIC_API_KEY
      timeout: 120

# ──────────────────────────────────────────────────────
# GATEWAY SETTINGS
# ──────────────────────────────────────────────────────

litellm_settings:
  # Fallback: when a "local" backend fails, try the next "local" entry
  fallbacks: [{ "local": ["local"] }, { "code": ["code"] }]

  # Retry each backend once before moving to next
  num_retries: 1

  # Default timeout (overridden per-model above)
  request_timeout: 30

  # Don't flood the logs
  set_verbose: false

  # Enable caching to avoid duplicate calls (optional)
  # cache: true
  # cache_params:
  #   type: local   # or "redis" for shared cache

general_settings:
  # Uncomment if you want to require an API key to access the gateway
  # master_key: os.environ/LITELLM_MASTER_KEY
  pass_through_endpoints: []
```

### Step 5: Start the Gateway

```bash
# Start in foreground (good for first-time testing — you'll see logs)
litellm --config ~/.config/litellm/config.yaml --port 4000

# You should see:
# INFO:     LiteLLM Proxy running on http://0.0.0.0:4000
# INFO:     Models available: local, code, claude, claude-opus
```

Press `Ctrl+C` to stop. Once you've verified it works, start it in the background:

```bash
# Start in background
nohup litellm --config ~/.config/litellm/config.yaml --port 4000 > /tmp/litellm.log 2>&1 &
echo $!  # prints the PID — save this to stop it later
```

### Step 6: Test Everything

```bash
# 1. Test the "local" model (should hit MLX or Ollama)
echo "--- Testing 'local' model ---"
curl -s http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local",
    "messages": [{"role": "user", "content": "What is 2+2? Answer in one word."}],
    "max_tokens": 10
  }' | python3 -c "import sys,json; r=json.load(sys.stdin); print('Response:', r['choices'][0]['message']['content']); print('Model used:', r.get('model','unknown'))"

# 2. Test the "code" model
echo "--- Testing 'code' model ---"
curl -s http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "code",
    "messages": [{"role": "user", "content": "Write a Python hello world"}],
    "max_tokens": 50
  }' | python3 -c "import sys,json; r=json.load(sys.stdin); print('Response:', r['choices'][0]['message']['content'])"

# 3. List all available models
echo "--- Available models ---"
curl -s http://localhost:4000/v1/models | python3 -c "import sys,json; [print(f\"  - {m['id']}\") for m in json.load(sys.stdin)['data']]"

# 4. Test fallback — stop Ollama and verify it falls through
echo "--- Testing fallback ---"
ollama stop 2>/dev/null
curl -s http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "local", "messages": [{"role": "user", "content": "Hi"}], "max_tokens": 5}' \
  | python3 -c "import sys,json; r=json.load(sys.stdin); print('Fallback model used:', r.get('model','unknown'))"
ollama serve &>/dev/null &  # restart Ollama
```

If all tests pass, your gateway is working. Every app that points to `http://localhost:4000/v1` now has access to all your models with automatic fallback.

---

## Configuration Reference

### Model Name Prefixes

| Prefix         | Backend                                        | Example                                     |
| -------------- | ---------------------------------------------- | ------------------------------------------- |
| `openai/`      | Any OpenAI-compatible server (MLX, vLLM, etc.) | `openai/my-model` + `api_base`              |
| `ollama/`      | Ollama                                         | `ollama/qwen2.5:14b`                        |
| `openrouter/`  | OpenRouter                                     | `openrouter/qwen/qwen3-235b-a22b`           |
| `anthropic/`   | Anthropic API                                  | `anthropic/claude-sonnet-4-6`               |
| `groq/`        | Groq                                           | `groq/llama-3.3-70b-versatile`              |
| `together_ai/` | Together AI                                    | `together_ai/meta-llama/Llama-3-8b-chat-hf` |

### Key Config Parameters

| Parameter     | Where              | What it does                                                              |
| ------------- | ------------------ | ------------------------------------------------------------------------- |
| `model_name`  | per entry          | The name your app uses to request this model. Same name = fallback chain. |
| `model`       | `litellm_params`   | The actual model identifier with provider prefix.                         |
| `api_base`    | `litellm_params`   | URL of the backend server. Required for `openai/` and `ollama/` prefixes. |
| `api_key`     | `litellm_params`   | Auth key. Use `none` for local servers, `os.environ/VAR` for env vars.    |
| `timeout`     | `litellm_params`   | Seconds before giving up on this backend. Lower = faster fallback.        |
| `max_tokens`  | `litellm_params`   | Default max tokens if the client doesn't specify.                         |
| `fallbacks`   | `litellm_settings` | Which model names have fallback chains.                                   |
| `num_retries` | `litellm_settings` | How many times to retry a backend before falling back.                    |

### Advanced: Load Balancing

If you have multiple machines (e.g., a Mac Mini and a Mac Studio), you can load-balance across them:

```yaml
model_list:
  - model_name: local
    litellm_params:
      model: openai/model-a
      api_base: http://mac-mini:1235/v1
      api_key: none
  - model_name: local
    litellm_params:
      model: openai/model-b
      api_base: http://mac-studio:1235/v1
      api_key: none

router_settings:
  routing_strategy: least-busy # or: simple-shuffle, latency-based-routing
```

### Advanced: Caching

Avoid paying (or waiting) for the same query twice:

```yaml
litellm_settings:
  cache: true
  cache_params:
    type: local # In-memory cache (lost on restart)
    # type: redis          # Persistent cache (needs Redis)
    # host: localhost
    # port: 6379
    ttl: 3600 # Cache for 1 hour
```

---

## Usage Examples

### From curl

```bash
# Simple completion
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local",
    "messages": [{"role": "user", "content": "Explain recursion in 2 sentences"}],
    "temperature": 0.7
  }'

# Streaming
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local",
    "messages": [{"role": "user", "content": "Write a haiku about programming"}],
    "stream": true
  }'
```

### From Python (OpenAI SDK)

```python
from openai import OpenAI

# Point the OpenAI client at your local gateway
client = OpenAI(
    base_url="http://localhost:4000/v1",
    api_key="none"  # or your master_key if you set one
)

# Use "local" for cheap tasks
response = client.chat.completions.create(
    model="local",
    messages=[{"role": "user", "content": "Summarize this text: ..."}],
    max_tokens=200
)
print(response.choices[0].message.content)

# Use "code" for code tasks
response = client.chat.completions.create(
    model="code",
    messages=[{"role": "user", "content": "Write a Python function to parse CSV"}]
)
print(response.choices[0].message.content)

# Use "claude" for complex reasoning (routes to Anthropic)
response = client.chat.completions.create(
    model="claude",
    messages=[{"role": "user", "content": "Analyze the security implications of..."}]
)
print(response.choices[0].message.content)
```

### From JavaScript/TypeScript

```typescript
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "http://localhost:4000/v1",
  apiKey: "none",
});

const response = await client.chat.completions.create({
  model: "local",
  messages: [{ role: "user", content: "Hello!" }],
});

console.log(response.choices[0].message.content);
```

### From any tool that supports custom OpenAI endpoints

Many tools let you set a custom base URL for OpenAI. Just point them to `http://localhost:4000/v1` with any API key (or `none`):

- **Continue.dev** (VS Code): set `apiBase` in config
- **Aider**: `--openai-api-base http://localhost:4000/v1`
- **LangChain**: `ChatOpenAI(base_url="http://localhost:4000/v1")`
- **LlamaIndex**: `OpenAI(api_base="http://localhost:4000/v1")`

---

## Model Recommendations

### By Hardware (Apple Silicon)

| RAM       | Recommended Model          | Size                  | Speed      | How to get it                             |
| --------- | -------------------------- | --------------------- | ---------- | ----------------------------------------- |
| **8GB**   | Qwen2.5-7B-Instruct-4bit   | ~4.5GB                | ~80 tok/s  | `ollama pull qwen2.5:7b`                  |
| **16GB**  | Qwen2.5-14B-Instruct-4bit  | ~9GB                  | ~45 tok/s  | `ollama pull qwen2.5:14b`                 |
| **24GB**  | Qwen3.5-35B-A3B-4bit (MoE) | ~20GB disk, 3B active | ~100 tok/s | MLX: `mlx-community/Qwen3.5-35B-A3B-4bit` |
| **32GB+** | Qwen2.5-32B-Instruct-4bit  | ~19GB                 | ~25 tok/s  | `ollama pull qwen2.5:32b`                 |
| **48GB+** | Qwen2.5-72B-Instruct-4bit  | ~40GB                 | ~15 tok/s  | `ollama pull qwen2.5:72b`                 |

### By Task

| Task                | Recommended Model          | Why                              |
| ------------------- | -------------------------- | -------------------------------- |
| General chat/Q&A    | qwen2.5:14b                | Best quality/speed balance       |
| Code generation     | qwen2.5-coder:7b           | Specialized for code             |
| Reasoning/math      | deepseek-r1:14b            | Chain-of-thought built in        |
| Fast responses      | Qwen3.5-35B-A3B-4bit (MLX) | MoE — only 3B active, ~100 tok/s |
| Maximum quality     | qwen2.5:32b or 72b         | Approaches GPT-4 level           |
| Free cloud fallback | OpenRouter qwen3-235b-a22b | Free during preview              |

### MoE Models — The Sweet Spot

Mixture-of-Experts (MoE) models are the best choice for local inference. They have many parameters but only activate a small subset per token, giving you big-model quality at small-model speed:

| Model            | Total Params | Active Params | Speed       | Quality    |
| ---------------- | ------------ | ------------- | ----------- | ---------- |
| Qwen3.5-35B-A3B  | 35B          | 3B            | ~100 tok/s  | Excellent  |
| DeepSeek-V3-0324 | 671B         | 37B           | ~10 tok/s\* | Near-GPT-4 |

\*DeepSeek-V3 needs 48GB+ RAM for the 4-bit quantization.

---

## Persistence (Auto-Start)

### macOS (launchd)

Create a launch agent so the gateway starts on login:

```bash
# Create the plist file
cat > ~/Library/LaunchAgents/com.litellm.proxy.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.litellm.proxy</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/litellm</string>
        <string>--config</string>
        <string>~/.config/litellm/config.yaml</string>
        <string>--port</string>
        <string>4000</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/litellm.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/litellm.err</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
    </dict>
</dict>
</plist>
EOF

# Load it (starts immediately + on every login)
launchctl load ~/Library/LaunchAgents/com.litellm.proxy.plist

# Verify it's running
sleep 2 && curl -s http://localhost:4000/v1/models | head -c 100

# To stop:   launchctl unload ~/Library/LaunchAgents/com.litellm.proxy.plist
# To reload: launchctl unload ... && launchctl load ...
```

**Important:** Update the path to `litellm` if it's installed elsewhere. Find it with `which litellm`.

### Also persist MLX LM Server (if using)

MLX doesn't auto-start like Ollama does. Create a second launch agent:

```bash
cat > ~/Library/LaunchAgents/com.mlx.lm.server.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mlx.lm.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/python3</string>
        <string>-m</string>
        <string>mlx_lm.server</string>
        <string>--model</string>
        <string>mlx-community/Qwen2.5-14B-Instruct-4bit</string>
        <string>--port</string>
        <string>1235</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/mlx-lm.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/mlx-lm.err</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.mlx.lm.server.plist
```

### Linux (systemd)

```bash
# Create service file
sudo tee /etc/systemd/system/litellm.service << 'EOF'
[Unit]
Description=LiteLLM Proxy Gateway
After=network.target ollama.service

[Service]
Type=simple
ExecStart=/usr/local/bin/litellm --config /etc/litellm/config.yaml --port 4000
Restart=always
RestartSec=5
Environment=OPENROUTER_API_KEY=your-key-here
Environment=ANTHROPIC_API_KEY=your-key-here

[Install]
WantedBy=multi-user.target
EOF

# Copy config
sudo mkdir -p /etc/litellm
sudo cp ~/.config/litellm/config.yaml /etc/litellm/

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now litellm

# Check status
systemctl status litellm
journalctl -u litellm -f  # follow logs
```

---

## Monitoring & Debugging

### View logs

```bash
# If running in foreground — logs appear in terminal

# If running via launchd
tail -f /tmp/litellm.log
tail -f /tmp/litellm.err

# If running via systemd
journalctl -u litellm -f
```

### Check health

```bash
# Is the gateway up?
curl -s http://localhost:4000/health | python3 -m json.tool

# What models are available?
curl -s http://localhost:4000/v1/models | python3 -m json.tool

# Is MLX up?
curl -s http://localhost:1235/v1/models 2>/dev/null | python3 -m json.tool || echo "MLX: down"

# Is Ollama up?
curl -s http://localhost:11434/api/tags 2>/dev/null | python3 -m json.tool || echo "Ollama: down"
```

### Enable verbose logging

In `config.yaml`:

```yaml
litellm_settings:
  set_verbose: true # Shows which backend was chosen, timing, fallback events
```

### LiteLLM Dashboard (optional)

LiteLLM has a built-in web dashboard:

```bash
litellm --config ~/.config/litellm/config.yaml --port 4000 --detailed_debug
# Open http://localhost:4000/ui in your browser
```

---

## Integration with Claude Code

### Using the gateway from Claude Code skills

The `model-tier-strategy.md` rule defines Tier 0 for local models. With this gateway running, any skill can call local models via the standard OpenAI API:

```python
# In a skill's implementation
import openai
client = openai.OpenAI(base_url="http://localhost:4000/v1", api_key="none")
result = client.chat.completions.create(
    model="local",
    messages=[{"role": "user", "content": "Format this as a markdown table: ..."}]
)
```

### Recommended routing for Claude Code

| Task in Claude Code          | Route to            | Why                            |
| ---------------------------- | ------------------- | ------------------------------ |
| Orchestration, planning      | Claude Max (direct) | Needs deep reasoning           |
| Code implementation          | Claude Max (direct) | Needs full codebase context    |
| Security/architecture review | Claude Max (direct) | High-stakes judgment           |
| Formatting reports           | Gateway → `local`   | Mechanical, no judgment needed |
| Test generation              | Gateway → `code`    | Bounded, spec-driven           |
| Summarizing tool output      | Gateway → `local`   | Compression task               |
| Exploring codebase           | Claude Max (direct) | Needs tool access              |

**Important:** Claude Code subagents (via the Agent tool) always run through Anthropic's API. The gateway is for **your own scripts and tools** that call LLMs, not for replacing Claude Code's built-in model routing.

---

## Troubleshooting

| Problem                        | Diagnosis                     | Fix                                                                             |
| ------------------------------ | ----------------------------- | ------------------------------------------------------------------------------- |
| `litellm: command not found`   | Not in PATH                   | `pip install 'litellm[proxy]'` or use `python3 -m litellm`                      |
| Gateway starts but no models   | Config has wrong model names  | Check `ollama list` and match names exactly                                     |
| MLX model won't load           | Not enough RAM                | Use a smaller model (7B instead of 14B)                                         |
| Ollama connection refused      | Ollama not running            | `ollama serve` or `systemctl start ollama`                                      |
| OpenRouter 401 Unauthorized    | Bad or missing API key        | Check `echo $OPENROUTER_API_KEY`, get key at openrouter.ai                      |
| Anthropic 401                  | Bad or missing API key        | Check `echo $ANTHROPIC_API_KEY`                                                 |
| Fallback not working           | Only one entry per model_name | Need 2+ entries with same `model_name` for fallback                             |
| Timeout before fallback        | Timeout too high              | Lower `timeout` on the failing backend (e.g., 5 seconds)                        |
| Port 4000 already in use       | Another process on that port  | `lsof -i :4000` to find it, then kill or use `--port 4001`                      |
| Slow responses from Ollama     | Model loading from disk       | First request is slow (loading into RAM). Subsequent are fast.                  |
| `pip install` permission error | System Python protected       | Use `pip install --user 'litellm[proxy]'` or a virtualenv                       |
| Gateway crashes on start       | Bad YAML syntax               | Run `python3 -c "import yaml; yaml.safe_load(open('config.yaml'))"` to validate |

---

## Skill Workflow

When this skill is invoked via `/local-inference`, follow this interactive flow:

1. **Detect** — run all environment checks from Step 1. Report what's found.
2. **Ask** — present the user with options:
   - Which backends do you want? (Ollama / MLX / OpenRouter / Anthropic)
   - What's your RAM? (determines model size recommendations)
   - Do you want auto-start on boot?
3. **Install** — install missing prerequisites (LiteLLM, Ollama, MLX, etc.)
4. **Pull models** — download recommended models based on RAM
5. **Configure** — generate `~/.config/litellm/config.yaml` with only the selected backends
6. **Start** — launch the gateway in foreground first for testing
7. **Verify** — run test requests against each model name, verify fallback works
8. **Persist** — if requested, set up launchd/systemd auto-start
9. **Report** — show the endpoint URL, available models, and example usage commands

At each step, explain what you're doing and why. If anything fails, diagnose and offer a fix before continuing.
