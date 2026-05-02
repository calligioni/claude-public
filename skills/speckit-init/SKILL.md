---
name: speckit-init
description: Initialize spec-kit in the current project — installs the `.specify/` directory (templates, scripts, memory, specs) that all `speckit-*` skills depend on. Use this skill whenever the user wants to set up spec-driven development, asks to create or initialize the `.specify` folder, says they want to use speckit/spec-kit but don't have the setup yet, wants to bootstrap a project for spec-driven workflows, or invokes any `speckit-*` skill in a project that's missing `.specify/`. Triggers on phrases like "init speckit", "inicializar speckit", "create .specify", "criar .specify", "setup spec-kit", "configurar spec-kit", "bootstrap spec-kit", "preparar projeto para speckit", "speckit init", "/speckit-init", "habilitar speckit aqui".
---

# speckit-init

Bootstraps the `.specify/` directory in the **current project** by running the official `specify init` CLI from GitHub's spec-kit. Without `.specify/`, none of the other `speckit-*` skills (specify, plan, tasks, implement, clarify, analyze, constitution, checklist, taskstoissues, the git-* family) can run.

The skill must do **all four phases** every time it is invoked: prerequisite check → run init → verification → report. Do not skip the verification phase even if the CLI exits 0 — verification is the contract this skill promises the user.

---

## Phase 1 — Prerequisite check (`uv` / `uvx`)

The `specify` CLI is shipped via `uvx`, which requires Astral's `uv`. Check whether it is installed before doing anything else:

```powershell
uv --version
```

(Or `uvx --version` — either works.)

**If it is installed:** continue to Phase 2.

**If the command is not found:** stop and ask the user for permission to install `uv`. Do not install silently — installing a system package is the kind of action that warrants user confirmation. Show the install command first.

Install commands by platform (detect the platform; do not guess):

- **Windows (PowerShell):**
  ```powershell
  winget install astral-sh.uv
  ```
  Fallback if `winget` is unavailable:
  ```powershell
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
  ```

- **macOS / Linux:**
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```

After installation, re-verify with `uv --version`. If it still fails, ask the user to open a fresh shell (PATH may not be picked up by the current session) and stop — do not try to work around it.

---

## Phase 2 — Run `specify init`

Confirm the **current working directory** is the project root where the user wants `.specify/` to live. If you are not certain, ask. Spec-kit is per-project, not global — running it in the wrong directory pollutes that directory with config it doesn't need.

Pick the right `--script` flag based on the OS:
- Windows → `--script ps` (PowerShell scripts)
- macOS / Linux → `--script sh` (Bash scripts) — this is the default, the flag can be omitted

Then run:

```powershell
# Windows
uvx --from git+https://github.com/github/spec-kit.git specify init . --script ps
```

```bash
# macOS / Linux
uvx --from git+https://github.com/github/spec-kit.git specify init .
```

**Handling a non-empty directory:** if the CLI complains that the directory already has files, ask the user whether to merge with `--force`. Do not auto-add `--force` — overwriting files in someone's project without asking is exactly the kind of destructive default this skill must avoid.

```powershell
uvx --from git+https://github.com/github/spec-kit.git specify init . --script ps --force
```

**Handling an existing `.specify/`:** if the directory already exists and is non-empty, treat that as a strong signal the project is already initialized. Stop and tell the user, listing what's there. Offer to either (a) re-init with `--force` (destructive) or (b) skip and just verify the existing structure. Default to (b) unless the user explicitly chooses (a).

**Other useful flags** (use only if the user asks):
- `--integration claude` — wire up Claude-specific artifacts (most likely what the user wants here, since they're using Claude Code; offer this proactively if they don't specify).
- `--no-git` — skip git initialization (useful when the project's git is already set up — usually the case in an existing repo).
- `--branch-numbering timestamp` — for distributed teams; default is sequential.

---

## Phase 3 — Verify the structure

This is the part most easily skipped, and the part that most matters. The CLI exiting 0 does not mean every expected file landed — networks flake, partial writes happen, integration flags drop files in different places. Verify directly.

Check that **all of the following exist** under `.specify/`:

| Path | Why it matters |
|---|---|
| `.specify/memory/constitution.md` | Required by `/speckit.constitution`. |
| `.specify/templates/spec-template.md` | Required by `/speckit.specify` (it copies this file). |
| `.specify/templates/plan-template.md` | Required by `/speckit.plan`. |
| `.specify/templates/tasks-template.md` | Required by `/speckit.tasks`. |
| `.specify/scripts/` (non-empty) | Required by hooks and several skills. Should contain at least `check-prerequisites`, `common`, `create-new-feature`, `setup-plan` with the `.ps1` or `.sh` extension matching `--script`. |
| `.specify/specs/` | Created (usually empty). Populated later by `/speckit.specify`. |

Concrete check (Windows example):

```powershell
$base = Join-Path (Get-Location) ".specify"
$required = @(
  "memory/constitution.md",
  "templates/spec-template.md",
  "templates/plan-template.md",
  "templates/tasks-template.md"
)
$missing = @()
foreach ($r in $required) {
  if (-not (Test-Path (Join-Path $base $r))) { $missing += $r }
}
$scripts = Get-ChildItem -Path (Join-Path $base "scripts") -ErrorAction SilentlyContinue
if (-not $scripts -or $scripts.Count -eq 0) { $missing += "scripts/ (empty or missing)" }

if ($missing.Count -gt 0) {
  Write-Host "MISSING:"
  $missing | ForEach-Object { Write-Host "  - $_" }
} else {
  Write-Host "OK: all expected paths present"
}
```

Use the `Read` and `Glob` tools rather than spawning shell scripts where possible — they're faster and don't pollute the conversation with subprocess output. Glob `.specify/**/*` and check the listing against the table above.

If anything from the **required** rows is missing, the init failed even if the CLI exited 0. Surface that to the user with the exact missing paths; do not declare success.

---

## Phase 4 — Report

Tell the user concisely:

1. **Outcome** — success / partial / failed.
2. **What was created** — show the resulting tree (you can use `Glob` `.specify/**/*` and format it). Keep it compact, just the structure.
3. **Next step** — point them at the natural first command:
   ```
   /speckit.constitution   # define project principles
   ```
   Then the typical flow: `/speckit.specify` → `/speckit.clarify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`.

If the run was **partial** (CLI succeeded but verification found missing files), include the list of missing paths and recommend re-running with `--force`. Don't auto-retry — let the user decide.

If the run **failed**, include the CLI's stderr output verbatim and stop. Do not start guessing fixes; common causes are network issues (uvx couldn't reach GitHub), a stale uv cache (`uv cache clean` may help), or PATH problems after a fresh `uv` install.

---

## Why this skill exists separately

The `speckit-*` skills assume `.specify/` is already there and silently break when it isn't, with confusing error messages like "cannot find templates/spec-template.md". This skill is a one-shot, idempotent bootstrap that fills that gap and makes the failure mode (missing prerequisite) become a clear, actionable workflow instead.
