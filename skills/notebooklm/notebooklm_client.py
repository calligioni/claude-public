#!/usr/bin/env python3
"""NotebookLM client script wrapping the notebooklm-py library."""

import asyncio
import json
import sys
import time

# Force UTF-8 output on Windows to handle unicode in titles/errors
if hasattr(sys.stdout, "reconfigure") and sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def error(msg: str, code: int = 1):
    print(json.dumps({"error": msg}))
    sys.exit(code)


def output(data):
    print(json.dumps(data, indent=2, ensure_ascii=False, default=str))


# ---------------------------------------------------------------------------
# Config — check and auto-fix all pipeline dependencies
# ---------------------------------------------------------------------------

def _pip_install(package: str) -> tuple[bool, str]:
    """Run pip install and return (success, message)."""
    import subprocess
    result = subprocess.run(
        [sys.executable, "-m", "pip", "install", package],
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        return True, f"installed {package}"
    return False, (result.stderr or result.stdout).strip()[-200:]


def _ensure_deps():
    """Auto-install all required packages if missing. Called before every command."""
    import subprocess, os

    # notebooklm-py (pulls playwright as dependency)
    try:
        import notebooklm  # noqa: F401
    except ImportError:
        print(json.dumps({"auto_install": "notebooklm-py[browser]", "status": "installing..."}), flush=True)
        ok, msg = _pip_install("notebooklm-py[browser]")
        if not ok:
            error(f"Auto-install failed for notebooklm-py: {msg}")

    # yt-dlp
    try:
        import yt_dlp  # noqa: F401
    except ImportError:
        print(json.dumps({"auto_install": "yt-dlp", "status": "installing..."}), flush=True)
        ok, msg = _pip_install("yt-dlp")
        if not ok:
            error(f"Auto-install failed for yt-dlp: {msg}")

    # Playwright Chromium browser
    local_app = os.environ.get("LOCALAPPDATA", "") if sys.platform == "win32" else ""
    pw_dir = os.path.join(local_app, "ms-playwright") if local_app else os.path.expanduser("~/.local/share/ms-playwright")
    chromium_found = os.path.isdir(pw_dir) and any(
        d.startswith("chromium") and os.path.isdir(os.path.join(pw_dir, d))
        for d in os.listdir(pw_dir)
    )
    if not chromium_found:
        print(json.dumps({"auto_install": "playwright chromium", "status": "installing browser (~290 MB)..."}), flush=True)
        r = subprocess.run([sys.executable, "-m", "playwright", "install", "chromium"],
                           capture_output=True, text=True)
        if r.returncode != 0:
            error(f"Playwright Chromium install failed: {(r.stderr or r.stdout)[-200:]}")


def _emit(step: str, status: str, detail: str, final: bool = True):
    """Print one JSONL line per check. Only recorded in checks[] when final=True."""
    line = json.dumps({"step": step, "status": status, "detail": detail}, ensure_ascii=False)
    print(line, flush=True)
    return final  # caller decides whether to record


def run_config():
    checks = []
    all_deps_ok = True

    def record(step, ok, detail, action_required=False):
        nonlocal all_deps_ok
        status = "ok" if ok else ("action_required" if action_required else "error")
        if not ok and not action_required:
            all_deps_ok = False
        _emit(step, status, detail)
        checks.append({"step": step, "status": status, "detail": detail})

    # 1. Python version
    v = sys.version_info
    py_ok = v >= (3, 10)
    record("python_version", py_ok, f"{v.major}.{v.minor}.{v.micro}" + ("" if py_ok else " — need >=3.10"))

    # 2. yt-dlp
    try:
        import yt_dlp as _yt
        record("yt_dlp", True, getattr(_yt.version, "__version__", "installed"))
    except ImportError:
        _emit("yt_dlp", "fixing", "not installed — running pip install yt-dlp...", final=False)
        ok, msg = _pip_install("yt-dlp")
        record("yt_dlp", ok, "installed successfully" if ok else f"install failed: {msg}")

    # 3. notebooklm-py
    try:
        import notebooklm as _nb
        ver = getattr(_nb, "__version__", None)
        record("notebooklm_py", True, ver or "installed")
    except ImportError:
        _emit("notebooklm_py", "fixing", "not installed — running pip install notebooklm-py[browser]...", final=False)
        ok, msg = _pip_install("notebooklm-py[browser]")
        record("notebooklm_py", ok, "installed successfully" if ok else f"install failed: {msg}")

    # 4. playwright Python package
    try:
        import playwright as _pw
        record("playwright_pkg", True, getattr(_pw, "__version__", "installed"))
    except ImportError:
        _emit("playwright_pkg", "fixing", "not installed — running pip install playwright...", final=False)
        ok, msg = _pip_install("playwright")
        record("playwright_pkg", ok, "installed successfully" if ok else f"install failed: {msg}")

    # 5. Playwright Chromium browser
    import os, subprocess
    local_app = os.environ.get("LOCALAPPDATA", "") if sys.platform == "win32" else ""
    pw_dir = os.path.join(local_app, "ms-playwright") if local_app else os.path.expanduser("~/.local/share/ms-playwright")
    chromium_found = False
    if os.path.isdir(pw_dir):
        chromium_found = any(
            d.startswith("chromium") and os.path.isdir(os.path.join(pw_dir, d))
            for d in os.listdir(pw_dir)
        )
    if chromium_found:
        record("playwright_chromium", True, f"browser found in {pw_dir}")
    else:
        _emit("playwright_chromium", "fixing", "Chromium not found — installing (~290 MB)...", final=False)
        r = subprocess.run(
            [sys.executable, "-m", "playwright", "install", "chromium"],
            capture_output=True, text=True,
        )
        ok = r.returncode == 0
        record("playwright_chromium", ok,
               "browser installed" if ok else f"install failed: {(r.stderr or r.stdout)[-200:]}")

    # 6. notebooklm auth
    auth_ok = False
    auth_detail = ""
    try:
        from notebooklm import NotebookLMClient

        async def _ping():
            async with await NotebookLMClient.from_storage() as client:
                await client.notebooks.list()

        asyncio.run(_ping())
        auth_ok = True
        auth_detail = "autenticado — sessão Google ativa"
    except Exception as e:
        msg = str(e)
        auth_detail = "login pendente — rode: notebooklm login"

    record("notebooklm_auth", auth_ok, auth_detail, action_required=not auth_ok)

    # Summary
    overall = "ready" if (all_deps_ok and auth_ok) else ("needs_auth" if all_deps_ok else "errors")
    summary = {
        "summary": True,
        "overall": overall,
        "checks": checks,
        "next_step": "Pipeline pronto!" if overall == "ready" else (
            "Execute: notebooklm login   (abre browser para login Google, só precisa fazer uma vez)"
            if overall == "needs_auth" else "Corrija os erros acima e rode config novamente."
        ),
    }
    print(json.dumps(summary, indent=2, ensure_ascii=False))


# ---------------------------------------------------------------------------
# Auth check
# ---------------------------------------------------------------------------

_AUTH_HINT = (
    "Autenticação necessária. Execute uma vez em qualquer terminal:\n"
    "  notebooklm login\n"
    "Um browser abrirá para login com sua conta Google. Após concluir, tente novamente."
)


async def check_auth():
    try:
        from notebooklm import NotebookLMClient
        async with await NotebookLMClient.from_storage() as client:
            await client.notebooks.list()
        output({"status": "authenticated"})
    except FileNotFoundError:
        error(_AUTH_HINT, code=2)
    except Exception as e:
        msg = str(e)
        if any(k in msg.lower() for k in ("login", "auth", "storage", "token", "cookie")):
            error(_AUTH_HINT, code=2)
        error(f"Auth check failed: {msg}", code=1)


# ---------------------------------------------------------------------------
# List notebooks
# ---------------------------------------------------------------------------

async def list_notebooks():
    from notebooklm import NotebookLMClient
    async with await NotebookLMClient.from_storage() as client:
        notebooks = await client.notebooks.list()

    result = []
    for nb in notebooks:
        result.append({
            "id": nb.id,
            "title": nb.title,
            "created_at": getattr(nb, "created_at", None),
        })
    output(result)


# ---------------------------------------------------------------------------
# Create notebook + add sources
# ---------------------------------------------------------------------------

async def create_notebook(args: dict):
    title = args.get("title", "Research Notebook")
    urls = args.get("urls", [])

    from notebooklm import NotebookLMClient
    async with await NotebookLMClient.from_storage() as client:
        nb = await client.notebooks.create(title)
        notebook_id = nb.id

        source_ids = []
        failed_urls = []

        for url in urls:
            try:
                source = await client.sources.add_url(notebook_id, url, wait=False)
                source_ids.append(getattr(source, "id", None))
            except Exception as e:
                failed_urls.append({"url": url, "error": str(e)})

        # Poll for sources to be ready (up to 5 min)
        if source_ids:
            deadline = time.time() + 300
            while time.time() < deadline:
                await asyncio.sleep(10)
                try:
                    sources = await client.sources.list(notebook_id)
                    pending = [s for s in sources if getattr(s, "status", 2) not in (2, 3)]
                    if not pending:
                        break
                except Exception:
                    break

    result = {
        "notebook_id": notebook_id,
        "title": title,
        "sources_added": len(source_ids),
        "source_ids": source_ids,
    }
    if failed_urls:
        result["failed_urls"] = failed_urls
    output(result)


# ---------------------------------------------------------------------------
# Add sources to existing notebook
# ---------------------------------------------------------------------------

async def add_sources(args: dict):
    notebook_id = args.get("notebook_id")
    urls = args.get("urls", [])

    if not notebook_id:
        error("notebook_id required")

    from notebooklm import NotebookLMClient
    async with await NotebookLMClient.from_storage() as client:
        source_ids = []
        failed_urls = []
        for url in urls:
            try:
                source = await client.sources.add_url(notebook_id, url, wait=False)
                source_ids.append(getattr(source, "id", None))
            except Exception as e:
                failed_urls.append({"url": url, "error": str(e)})

    result = {"sources_added": len(source_ids), "source_ids": source_ids}
    if failed_urls:
        result["failed_urls"] = failed_urls
    output(result)


# ---------------------------------------------------------------------------
# Generate artifact
# ---------------------------------------------------------------------------

ARTIFACT_METHODS = {
    "infographic": "generate_infographic",
    "slide_deck": "generate_slide_deck",
    "slides": "generate_slide_deck",
    "flashcards": "generate_flashcards",
    "report": "generate_report",
    "mind_map": "generate_mind_map",
    "mindmap": "generate_mind_map",
    "quiz": "generate_quiz",
    "audio": "generate_audio",
}

async def generate(args: dict):
    notebook_id = args.get("notebook_id")
    artifact_type = args.get("type", "infographic").lower()
    instructions = args.get("instructions", "")

    if not notebook_id:
        error("notebook_id required")

    method_name = ARTIFACT_METHODS.get(artifact_type)
    if not method_name:
        error(f"Unknown artifact type '{artifact_type}'. Supported: {', '.join(ARTIFACT_METHODS.keys())}")

    from notebooklm import NotebookLMClient
    async with await NotebookLMClient.from_storage() as client:
        method = getattr(client.artifacts, method_name)

        # Build kwargs based on method
        kwargs = {}
        if instructions:
            kwargs["instructions"] = instructions

        try:
            status = await method(notebook_id, **kwargs)
        except TypeError:
            # Some methods don't accept instructions
            status = await method(notebook_id)

        # Wait for completion (up to 10 min for complex artifacts)
        try:
            final = await client.artifacts.wait_for_completion(
                notebook_id,
                status.task_id,
                timeout=600,
                poll_interval=15,
            )
            result = {
                "artifact_type": artifact_type,
                "status": str(getattr(final, "status", "unknown")),
                "url": getattr(final, "url", None),
                "task_id": getattr(status, "task_id", None),
            }
        except Exception as e:
            result = {
                "artifact_type": artifact_type,
                "task_id": getattr(status, "task_id", None),
                "note": f"Generation started but wait failed: {e}. Check NotebookLM web UI.",
            }

    output(result)


# ---------------------------------------------------------------------------
# Chat
# ---------------------------------------------------------------------------

async def chat(args: dict):
    notebook_id = args.get("notebook_id")
    question = args.get("question", "")

    if not notebook_id:
        error("notebook_id required")
    if not question:
        error("question required")

    from notebooklm import NotebookLMClient
    async with await NotebookLMClient.from_storage() as client:
        result = await client.chat.ask(notebook_id, question)

    output({"answer": str(result), "notebook_id": notebook_id})


# ---------------------------------------------------------------------------
# Delete notebook
# ---------------------------------------------------------------------------

async def delete_notebook(args: dict):
    notebook_id = args.get("notebook_id")
    if not notebook_id:
        error("notebook_id required")

    from notebooklm import NotebookLMClient
    async with await NotebookLMClient.from_storage() as client:
        await client.notebooks.delete(notebook_id)

    output({"deleted": True, "notebook_id": notebook_id})


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

COMMANDS = {
    "config": (None, False),          # handled synchronously below
    "check-auth": (check_auth, False),
    "list-notebooks": (list_notebooks, False),
    "create-notebook": (create_notebook, True),
    "add-sources": (add_sources, True),
    "generate": (generate, True),
    "chat": (chat, True),
    "delete-notebook": (delete_notebook, True),
}

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"available_commands": list(COMMANDS.keys())}))
        sys.exit(0)

    command = sys.argv[1]

    if command not in COMMANDS:
        error(f"Unknown command '{command}'. Available: {', '.join(COMMANDS.keys())}")

    # config is synchronous — run directly (it manages deps itself)
    if command == "config":
        run_config()
        return

    # All other commands: ensure deps are installed before running
    _ensure_deps()

    func, needs_args = COMMANDS[command]

    args = {}
    if needs_args:
        if len(sys.argv) < 3:
            error(f"Command '{command}' requires a JSON argument")
        try:
            args = json.loads(sys.argv[2])
        except json.JSONDecodeError as e:
            error(f"Invalid JSON argument: {e}")

    try:
        if needs_args:
            asyncio.run(func(args))
        else:
            asyncio.run(func())
    except Exception as e:
        error(str(e))


if __name__ == "__main__":
    main()
