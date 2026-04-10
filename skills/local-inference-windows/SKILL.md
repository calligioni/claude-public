---
name: local-inference-windows
description: "Set up a local multi-model inference gateway on Windows with LiteLLM. Routes tasks to Ollama (native Windows) with cloud fallback (OpenRouter, Anthropic). Use alongside Claude Max. Triggers on: local inference windows, setup litellm windows, model gateway windows, local models windows, inference gateway, run local models"
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

# Local Inference Gateway (Windows)

Set up a unified, multi-model inference gateway on **Windows** using [LiteLLM](https://github.com/BerriAI/litellm). Run local models via Ollama (native Windows) with automatic cloud fallback (OpenRouter, Anthropic) — all behind a single OpenAI-compatible API at `http://localhost:4000/v1`.

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
| Models locked to one provider           | Mix models from Ollama, OpenRouter, Anthropic      |

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
└────────┬──────────────────┬──────────┬───────────────────┘
         │                  │          │
         ▼                  ▼          ▼
┌────────────────┐  ┌──────────┐ ┌──────────────┐
│ Ollama         │  │ Open-    │ │ Anthropic    │
│ (Native Win)   │  │ Router   │ │ (Claude)     │
│                │  │          │ │              │
│ Port 11434     │  │ Cloud    │ │ Cloud API    │
│ CPU or NVIDIA  │  │ API      │ │              │
│ GPU (CUDA)     │  │ Free     │ │ Max plan     │
│                │  │ previews │ │ or API key   │
└────────────────┘  └──────────┘ └──────────────┘
   Tier 0a            Tier 0b       Tier 1

Fallback order: 0a → 0b → 1
(configurable — skip any tier you don't need)
```

**How fallback works:** When you send `{"model": "local", ...}` to the gateway, LiteLLM tries Tier 0a (Ollama) first. If it times out or errors (model not loaded, server down), it automatically tries 0b (OpenRouter). You get a response from whichever backend is available — your application never sees the failure.

**NVIDIA GPU acceleration:** If you have an NVIDIA GPU, Ollama automatically uses CUDA for inference. This can give 3-10x speedup over CPU-only. No extra configuration needed — Ollama detects the GPU automatically.

---

## Prerequisites

### Minimum Requirements

| Requirement | Details                                                           |
| ----------- | ----------------------------------------------------------------- |
| **OS**      | Windows 10/11 (64-bit)                                           |
| **Python**  | 3.10 or higher                                                   |
| **RAM**     | 8GB minimum (for 7B models), 16GB+ recommended (for 14B+ models) |
| **Disk**    | 5-15GB per model (4-bit quantized)                                |
| **GPU**     | Optional — NVIDIA GPU with CUDA for faster inference              |

### What You Need to Provide

| Backend        | Required?         | What you need                                                   |
| -------------- | ----------------- | --------------------------------------------------------------- |
| **Ollama**     | Recommended       | `winget install Ollama.Ollama`                                  |
| **OpenRouter** | Optional (cloud)  | Free API key from [openrouter.ai](https://openrouter.ai)       |
| **Anthropic**  | Optional (cloud)  | API key from [console.anthropic.com](https://console.anthropic.com) |

You need at least ONE backend. The gateway gets more useful the more backends you add (more fallback options).

---

## Step-by-Step Setup

### Step 1: Check Your Environment

Open PowerShell and run these commands:

```powershell
# Windows version
[System.Environment]::OSVersion.Version

# Python version (need 3.10+)
python --version
# If missing: winget install Python.Python.3.12

# Already have Ollama?
try { (Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing).Content | ConvertFrom-Json | Select-Object -ExpandProperty models | Format-Table name, size } catch { Write-Host "Ollama: not running" }

# Already have LiteLLM?
try { (Get-Command litellm -ErrorAction Stop).Source; litellm --version } catch { Write-Host "LiteLLM: not installed" }

# How much RAM?
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "$ram GB RAM"
Write-Host "  8GB  = 7B models"
Write-Host "  16GB = 14B models"
Write-Host "  32GB = 32B+ models"

# NVIDIA GPU? (optional but faster)
try { nvidia-smi --query-gpu=name,memory.total --format=csv,noheader } catch { Write-Host "No NVIDIA GPU detected (CPU inference only)" }
```

### Step 2: Install Python and LiteLLM

```powershell
# Install Python if not present
winget install Python.Python.3.12

# Restart terminal, then install LiteLLM with proxy support
pip install "litellm[proxy]"

# Verify
litellm --version

# If "litellm: command not found", try:
python -m litellm --version
# If that works, use "python -m litellm" instead of "litellm" in all commands below
```

### Step 3: Install at Least One Backend

#### Option A: Ollama (Recommended — Native Windows)

Ollama runs natively on Windows. If you have an NVIDIA GPU, it uses CUDA automatically.

```powershell
# Install Ollama
winget install Ollama.Ollama

# Restart terminal, then pull a model based on your RAM:

# 8GB RAM:
ollama pull qwen2.5:7b           # 4.7GB, good general-purpose

# 16GB RAM:
ollama pull qwen2.5:14b          # 9.0GB, better reasoning
ollama pull qwen2.5-coder:7b     # 4.7GB, code generation

# 32GB+ RAM:
ollama pull qwen2.5:32b          # 19GB, near-GPT-4 quality
ollama pull deepseek-r1:14b      # 9.0GB, strong reasoning

# Verify Ollama is running
ollama list
(Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing).Content | python -m json.tool
```

**What just happened:** Ollama downloaded a quantized model to `%USERPROFILE%\.ollama\models\` and started a server at `localhost:11434`. Ollama runs as a Windows service and auto-starts on boot.

#### Option B: OpenRouter (Cloud — Free Preview Models)

OpenRouter gives you access to dozens of models through one API. Many new models are free during their preview period.

```powershell
# 1. Go to https://openrouter.ai and create a free account
# 2. Go to https://openrouter.ai/keys and create an API key
# 3. Set the environment variable:
$env:OPENROUTER_API_KEY = "sk-or-v1-your-key-here"

# Persist it (PowerShell profile):
Add-Content $PROFILE '$env:OPENROUTER_API_KEY = "sk-or-v1-your-key-here"'

# Or use the Claude setup credential manager:
# .\windows\setup-credentials.ps1 (add openrouter-api-key)

# Verify
$headers = @{ "Authorization" = "Bearer $env:OPENROUTER_API_KEY"; "Content-Type" = "application/json" }
$body = '{"model": "qwen/qwen3-235b-a22b", "messages": [{"role": "user", "content": "Hi"}], "max_tokens": 5}'
Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body
```

#### Option C: Anthropic API (Claude — For Max Plan Users)

```powershell
# Set API key
$env:ANTHROPIC_API_KEY = "sk-ant-your-key-here"

# Or use the credential manager (recommended):
# .\windows\setup-credentials.ps1
# This stores it securely in Windows Credential Manager
```

### Step 4: Create the LiteLLM Configuration

```powershell
# Create config directory
$configDir = "$env:USERPROFILE\.config\litellm"
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
```

Create the config file. **Include only the backends you installed in Step 3:**

```powershell
# Generate config.yaml
@"
# LiteLLM Gateway Configuration (Windows)
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
  # Fallback: Ollama → OpenRouter
  # ──────────────────────────────────────────────────────

  # Tier 0a: Ollama (native Windows, CPU or NVIDIA GPU)
  # Remove this block if you don't have Ollama installed
  - model_name: local
    litellm_params:
      model: ollama/qwen2.5:14b  # Must match a pulled model name
      api_base: http://localhost:11434
      timeout: 30  # Ollama may need to load model into RAM on first call

  # Tier 0b: OpenRouter (cloud, free preview models)
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

litellm_settings:
  fallbacks: [{"local": ["local"]}, {"code": ["code"]}]
  num_retries: 1
  request_timeout: 30
  set_verbose: false

general_settings:
  pass_through_endpoints: []
"@ | Set-Content -Path "$configDir\config.yaml" -Encoding UTF8

Write-Host "Config written to: $configDir\config.yaml"
```

### Step 5: Start the Gateway

```powershell
# Start in foreground (for testing — you'll see logs)
litellm --config "$env:USERPROFILE\.config\litellm\config.yaml" --port 4000

# You should see:
# INFO:     LiteLLM Proxy running on http://0.0.0.0:4000
# INFO:     Models available: local, code, claude, claude-opus
```

Press `Ctrl+C` to stop. Once verified, start in background:

```powershell
# Start in background (hidden window)
Start-Process -WindowStyle Hidden -FilePath "litellm" -ArgumentList "--config", "$env:USERPROFILE\.config\litellm\config.yaml", "--port", "4000" -RedirectStandardOutput "$env:TEMP\litellm.log" -RedirectStandardError "$env:TEMP\litellm.err"
```

### Step 6: Test Everything

```powershell
# 1. Test "local" model (should hit Ollama)
Write-Host "--- Testing 'local' model ---"
$body = '{"model": "local", "messages": [{"role": "user", "content": "What is 2+2? Answer in one word."}], "max_tokens": 10}'
$response = Invoke-RestMethod -Uri "http://localhost:4000/v1/chat/completions" -Method Post -ContentType "application/json" -Body $body
Write-Host "Response: $($response.choices[0].message.content)"
Write-Host "Model used: $($response.model)"

# 2. Test "code" model
Write-Host "--- Testing 'code' model ---"
$body = '{"model": "code", "messages": [{"role": "user", "content": "Write a Python hello world"}], "max_tokens": 50}'
$response = Invoke-RestMethod -Uri "http://localhost:4000/v1/chat/completions" -Method Post -ContentType "application/json" -Body $body
Write-Host "Response: $($response.choices[0].message.content)"

# 3. List all available models
Write-Host "--- Available models ---"
$models = Invoke-RestMethod -Uri "http://localhost:4000/v1/models" -Method Get
$models.data | ForEach-Object { Write-Host "  - $($_.id)" }

# 4. Health check
Write-Host "--- Health ---"
Invoke-RestMethod -Uri "http://localhost:4000/health" -Method Get
```

---

## Configuration Reference

### Model Name Prefixes

| Prefix         | Backend                                        | Example                                     |
| -------------- | ---------------------------------------------- | ------------------------------------------- |
| `ollama/`      | Ollama                                         | `ollama/qwen2.5:14b`                        |
| `openrouter/`  | OpenRouter                                     | `openrouter/qwen/qwen3-235b-a22b`           |
| `anthropic/`   | Anthropic API                                  | `anthropic/claude-sonnet-4-6`               |
| `openai/`      | Any OpenAI-compatible server                   | `openai/my-model` + `api_base`              |
| `groq/`        | Groq                                           | `groq/llama-3.3-70b-versatile`              |
| `together_ai/` | Together AI                                    | `together_ai/meta-llama/Llama-3-8b-chat-hf` |

### Key Config Parameters

| Parameter     | Where              | What it does                                                              |
| ------------- | ------------------ | ------------------------------------------------------------------------- |
| `model_name`  | per entry          | The name your app uses to request this model. Same name = fallback chain. |
| `model`       | `litellm_params`   | The actual model identifier with provider prefix.                         |
| `api_base`    | `litellm_params`   | URL of the backend server. Required for `ollama/` prefix.                 |
| `api_key`     | `litellm_params`   | Auth key. Use `none` for local, `os.environ/VAR` for env vars.           |
| `timeout`     | `litellm_params`   | Seconds before giving up. Lower = faster fallback.                        |
| `max_tokens`  | `litellm_params`   | Default max tokens if the client doesn't specify.                         |
| `fallbacks`   | `litellm_settings` | Which model names have fallback chains.                                   |
| `num_retries` | `litellm_settings` | How many times to retry a backend before falling back.                    |

---

## Usage Examples

### From PowerShell

```powershell
# Simple completion
$body = @{
    model = "local"
    messages = @(@{ role = "user"; content = "Explain recursion in 2 sentences" })
    temperature = 0.7
} | ConvertTo-Json -Depth 3

$response = Invoke-RestMethod -Uri "http://localhost:4000/v1/chat/completions" -Method Post -ContentType "application/json" -Body $body
$response.choices[0].message.content
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

# Use "claude" for complex reasoning (routes to Anthropic API)
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

---

## Model Recommendations

### By Hardware

| RAM       | GPU                | Recommended Model         | Size   | Speed       | Install                            |
| --------- | ------------------ | ------------------------- | ------ | ----------- | ---------------------------------- |
| **8GB**   | None / Intel       | Qwen2.5-7B               | ~4.5GB | ~15 tok/s   | `ollama pull qwen2.5:7b`          |
| **16GB**  | None               | Qwen2.5-14B              | ~9GB   | ~8 tok/s    | `ollama pull qwen2.5:14b`         |
| **8GB**   | NVIDIA RTX 3060+   | Qwen2.5-7B               | ~4.5GB | ~80 tok/s   | `ollama pull qwen2.5:7b`          |
| **16GB**  | NVIDIA RTX 3080+   | Qwen2.5-14B              | ~9GB   | ~45 tok/s   | `ollama pull qwen2.5:14b`         |
| **32GB+** | NVIDIA RTX 4090    | Qwen2.5-32B              | ~19GB  | ~25 tok/s   | `ollama pull qwen2.5:32b`         |
| Any       | Cloud (OpenRouter) | Qwen3-235B (free preview) | 0 local| ~30 tok/s   | Set `OPENROUTER_API_KEY`           |

**NVIDIA GPU makes a HUGE difference on Windows.** CPU-only inference on 14B models is ~8 tok/s. With an RTX 3080, the same model runs at ~45 tok/s.

### By Task

| Task                | Recommended Model           | Why                              |
| ------------------- | --------------------------- | -------------------------------- |
| General chat/Q&A    | qwen2.5:14b                 | Best quality/speed balance       |
| Code generation     | qwen2.5-coder:7b            | Specialized for code             |
| Reasoning/math      | deepseek-r1:14b             | Chain-of-thought built in        |
| Maximum quality     | qwen2.5:32b                 | Approaches GPT-4 level           |
| Free cloud fallback | OpenRouter qwen3-235b-a22b  | Free during preview              |

---

## Persistence (Auto-Start)

### Option A: Task Scheduler (Simplest)

Create a scheduled task that starts LiteLLM on login:

```powershell
$litellmPath = (Get-Command litellm -ErrorAction SilentlyContinue).Source
if (-not $litellmPath) { $litellmPath = "python"; $litellmArgs = "-m litellm" } else { $litellmArgs = "" }

$configPath = "$env:USERPROFILE\.config\litellm\config.yaml"

# Create a startup script
$startupScript = "$env:USERPROFILE\.config\litellm\start-litellm.ps1"
@"
`$logFile = "`$env:TEMP\litellm.log"
`$configPath = "$configPath"
Start-Process -WindowStyle Hidden -FilePath "$litellmPath" -ArgumentList "$litellmArgs --config `$configPath --port 4000" -RedirectStandardOutput `$logFile -RedirectStandardError "`$env:TEMP\litellm.err"
"@ | Set-Content -Path $startupScript -Encoding UTF8

# Register as Task Scheduler task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$startupScript`""
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Unregister-ScheduledTask -TaskName "LiteLLMGateway" -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName "LiteLLMGateway" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "LiteLLM inference gateway on port 4000"

Write-Host "LiteLLM will auto-start on login."
Write-Host "To remove: Unregister-ScheduledTask -TaskName 'LiteLLMGateway' -Confirm:`$false"
```

### Option B: NSSM (Windows Service — Better for Servers)

[NSSM](https://nssm.cc/) (Non-Sucking Service Manager) creates a proper Windows service that auto-restarts on failure:

```powershell
# Install NSSM
winget install NSSM.NSSM

# Create service
$litellmPath = (Get-Command litellm).Source
nssm install LiteLLM $litellmPath "--config" "$env:USERPROFILE\.config\litellm\config.yaml" "--port" "4000"
nssm set LiteLLM AppStdout "$env:TEMP\litellm.log"
nssm set LiteLLM AppStderr "$env:TEMP\litellm.err"
nssm set LiteLLM AppRotateFiles 1
nssm set LiteLLM AppRotateBytes 1048576

# Start the service
nssm start LiteLLM

# Manage:
# nssm status LiteLLM
# nssm restart LiteLLM
# nssm stop LiteLLM
# nssm remove LiteLLM confirm
```

---

## Monitoring & Debugging

### Check health

```powershell
# Is the gateway up?
Invoke-RestMethod -Uri "http://localhost:4000/health"

# What models are available?
(Invoke-RestMethod -Uri "http://localhost:4000/v1/models").data | Format-Table id

# Is Ollama up?
try { ollama list } catch { Write-Host "Ollama: not running" }

# Gateway logs
Get-Content "$env:TEMP\litellm.log" -Tail 30

# Ollama logs
Get-Content "$env:USERPROFILE\.ollama\logs\server.log" -Tail 30 -ErrorAction SilentlyContinue
```

### Enable verbose logging

In `config.yaml`:

```yaml
litellm_settings:
  set_verbose: true  # Shows which backend was chosen, timing, fallback events
```

### Check which ports are in use

```powershell
# Is port 4000 taken?
Get-NetTCPConnection -LocalPort 4000 -ErrorAction SilentlyContinue | Format-Table OwningProcess, LocalPort

# Find process by PID
Get-Process -Id <PID> | Format-Table Name, Id, Path
```

---

## Integration with Claude Code

### Using the gateway from Claude Code

Claude Code itself always runs through Anthropic's API. The gateway is for **your own scripts and tools** that call LLMs — not for replacing Claude Code's model routing.

### Recommended routing

| Task in Claude Code          | Route to            | Why                            |
| ---------------------------- | ------------------- | ------------------------------ |
| Orchestration, planning      | Claude Max (direct) | Needs deep reasoning           |
| Code implementation          | Claude Max (direct) | Needs full codebase context    |
| Security/architecture review | Claude Max (direct) | High-stakes judgment           |
| Formatting reports           | Gateway -> `local`  | Mechanical, no judgment needed |
| Test generation              | Gateway -> `code`   | Bounded, spec-driven           |
| Summarizing tool output      | Gateway -> `local`  | Compression task               |
| Bulk documentation           | Gateway -> `local`  | Text generation, repeatable    |

### Using from Claude Code via Bash

Claude Code can call the gateway via `curl` or `Invoke-RestMethod` in Bash/PowerShell:

```powershell
# Example: Claude Code uses Bash to call local model for documentation
$body = @{ model = "local"; messages = @(@{ role = "user"; content = "Document this function: ..." }); max_tokens = 500 } | ConvertTo-Json -Depth 3
$result = Invoke-RestMethod -Uri "http://localhost:4000/v1/chat/completions" -Method Post -ContentType "application/json" -Body $body
$result.choices[0].message.content
```

---

## Troubleshooting

| Problem                        | Diagnosis                        | Fix                                                                   |
| ------------------------------ | -------------------------------- | --------------------------------------------------------------------- |
| `litellm: not recognized`      | Not in PATH                      | `pip install "litellm[proxy]"` or use `python -m litellm`            |
| Gateway starts but no models   | Config has wrong model names     | Run `ollama list` and match names exactly                             |
| Ollama not running             | Service stopped                  | Start from system tray or `ollama serve`                              |
| OpenRouter 401 Unauthorized    | Bad or missing API key           | Check `$env:OPENROUTER_API_KEY`                                       |
| Anthropic 401                  | Bad or missing API key           | Check `$env:ANTHROPIC_API_KEY`                                        |
| Fallback not working           | Only one entry per model_name    | Need 2+ entries with same `model_name`                                |
| Timeout before fallback        | Timeout too high                 | Lower `timeout` on the failing backend                                |
| Port 4000 already in use       | Another process                  | `Get-NetTCPConnection -LocalPort 4000`                                |
| Slow first response            | Model loading from disk          | Normal — first request loads into RAM. Subsequent are fast.           |
| `pip install` permission error | System Python protected          | Use `pip install --user "litellm[proxy]"` or a venv                  |
| Bad YAML syntax                | Config parse error               | `python -c "import yaml; yaml.safe_load(open('config.yaml'))"`        |
| NVIDIA GPU not used            | Ollama not detecting GPU         | Update NVIDIA drivers, restart Ollama                                 |
| Out of memory (OOM)            | Model too large for RAM          | Use a smaller model (7B instead of 14B)                               |

---

## Skill Workflow

When this skill is invoked via `/local-inference-windows`, follow this interactive flow:

1. **Detect** — run all environment checks from Step 1. Report what's found (Python, Ollama, GPU, RAM).
2. **Ask** — present the user with options:
   - Which backends do you want? (Ollama / OpenRouter / Anthropic)
   - What's your RAM and GPU? (determines model size recommendations)
   - Do you want auto-start on boot?
3. **Install** — install missing prerequisites (LiteLLM, Ollama)
4. **Pull models** — download recommended models based on RAM/GPU
5. **Configure** — generate `config.yaml` with only the selected backends
6. **Start** — launch the gateway in foreground first for testing
7. **Verify** — run test requests against each model name, verify fallback works
8. **Persist** — if requested, set up Task Scheduler or NSSM auto-start
9. **Report** — show the endpoint URL, available models, and example usage commands

At each step, explain what you're doing and why. If anything fails, diagnose and offer a fix before continuing.
