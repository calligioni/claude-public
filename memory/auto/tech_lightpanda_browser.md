---
name: tech-insight:lightpanda-browser
description: Lightpanda headless browser (Zig, CDP-compatible) — evaluated as Chrome/Browserless replacement, not ready due to missing PDF/Lighthouse/SPA gaps. Revisit Q3 2026.
type: reference
---

Lightpanda (github.com/lightpanda-io/browser) is a headless browser in Zig with V8, exposing CDP on port 9222. Claims 9x less memory, 11x faster than Chrome. 22.9k+ stars, AGPL-3.0 (fine for internal use).

**Evaluated 2026-03-21 as replacement for browse CLI / Browserless / Chrome DevTools MCP.**

**Result: NOT READY. Skip migration.**

Hard blockers:

- No `Page.printToPDF` — breaks /proposal-source, /browserless, /pinchtab PDF
- No Lighthouse — breaks /browserless audits, /growth perf analysis
- No CSS rendering (intentional) — visual testing useless
- SPA/React reliability gaps — Contably/SourceRank (Next.js) would fail
- CDP multi-client crash — Playwright sessions break on disconnect
- macOS segfault reports (x86_64), young platform

Narrow viable use case: bulk-crawling simple static pages where memory is the constraint (e.g., /deep-research, /chief-geo landing page analysis).

**Revisit triggers (checkpoint Q3 2026):**

- Lightpanda v1.0 stable release
- `Page.printToPDF` implemented
- Playwright SPA compatibility validated on React/Next.js
- CDP multi-client crash fixed
- `/json` discovery endpoints added (needed for chrome-devtools MCP)

Source: research — github.com/lightpanda-io/browser
Discovered: 2026-03-21
