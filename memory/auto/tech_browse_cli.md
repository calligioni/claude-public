---
name: browse-cli-installation
description: gstack browse CLI binary installed at ~/.local/bin/browse — zero-MCP-overhead headless Chromium for browser automation across 10 skills
type: reference
---

**gstack `browse` CLI** (MIT, from garrytan/gstack) installed at `~/.local/lib/browse/` with symlink at `~/.local/bin/browse`.

Built from source with Bun + Playwright. Architecture: thin CLI client → persistent daemon on localhost (auto-starts on first call, auto-stops after 30min idle). State in `.gstack/browse.json` per project.

**Why:** Zero MCP token overhead (plain stdout) vs 1500-2000 tokens per Chrome DevTools MCP call. ~100ms per call after cold start (~3s first call).

**Key features:**

- `snapshot -i` — interactive refs (@e1, @e2...)
- `snapshot -D` — diff vs previous snapshot (before/after verification)
- `snapshot -a -o path.png` — annotated screenshot with ref labels
- `snapshot -C` — cursor-interactive (finds non-ARIA clickable elements)
- `cookie-import-browser [browser]` — import cookies from Chrome/Arc/Brave/Edge via macOS Keychain
- `console` / `network` — ring buffer captures (50K capacity)
- `BROWSE_STATE_FILE` env var for multi-instance isolation (parallel testers)

**Integrated into 10 skills** (2026-03-14): fulltest-skill, qa-cycle, qa-sourcerank, virtual-user-testing, qa-verify, growth, qa-conta, qa-stonegeo, chief-geo, pinchtab. All use browse as primary, Chrome DevTools MCP as fallback. Detection: `test -x ~/.local/bin/browse`.

**Dependencies:** bun (homebrew), Playwright Chromium (bundled). `~/.local/bin` added to PATH in `~/.zshrc`.

**Build from source:** `cd /tmp && git clone --depth 1 https://github.com/garrytan/gstack.git && cd gstack && bun install && bun run build`
