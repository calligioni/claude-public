# website-replicator

A Claude Code skill for pixel-faithful replication of any production website into a clean Astro 6 + Tailwind v4 + Vite codebase.

## What it does

Turns a live URL into a working, locally-running replica with:

- All public routes scaffolded as Astro pages
- Pixel-faithful chrome (header / footer / mobile drawer / preloader)
- Full motion: GSAP timelines, ScrollTrigger pins, Lenis smooth-scroll, Barba page transitions, SplitText line reveals, WebGL scenes
- Original design tokens (fluid math, color palette, typography stack)
- A private GitHub repo with full commit history

Forged from a real reverse-engineering of `atolldigital.com` — 54 routes, 19 commits, every pitfall documented.

## Install

```bash
git clone https://github.com/Waiel5/website-replicator.git ~/.claude/skills/website-replicator
```

The skill auto-discovers in Claude Code (and any Claude harness that reads `~/.claude/skills/`).

## Use

In any Claude Code session:

> Clone atolldigital.com into Astro

Or:

> I lost my source code — rebuild this site: <URL>

Or simply paste a URL with "do this." The skill will fire eagerly on any rebuild / replicate / clone / recover wording.

## Structure

```
website-replicator/
├── SKILL.md                          orchestration (~225 lines)
├── scripts/
│   └── discover.sh                   forensic bootstrap shell
└── references/                       loaded on-demand per phase
    ├── forensics.md                  scrape, source maps, deminify
    ├── stack-setup.md                Astro 6 + Tailwind v4 scaffold
    ├── tokens-and-css.md             two-layer cascade strategy
    ├── layout-architecture.md        BaseLayout / SiteLayout / pageType
    ├── js-modularization.md          jQuery → ES modules
    ├── page-content-port.md          parallel agent dispatch + brace escape
    ├── webgl-strategy.md             "ship the bundle" pattern
    ├── external-libs.md              HubSpot, SplitText, Lottie
    ├── audit-loop.md                 3-agent parallel verification
    └── pitfalls.md                   28+ documented gotchas (W/ fixes)
```

## The 11 phases

```
1   Forensic discovery     → references/forensics.md
2   Scaffold the stack     → references/stack-setup.md
3   Extract design tokens  → references/tokens-and-css.md
4   Layout architecture    → references/layout-architecture.md
5   JS modularization      → references/js-modularization.md
6   Page content port      → references/page-content-port.md
7   Page transitions       → references/layout-architecture.md
8   WebGL / Three.js       → references/webgl-strategy.md
9   External libraries     → references/external-libs.md
10  Audit loop             → references/audit-loop.md
11  Pitfalls catalog (consult often) → references/pitfalls.md
```

## What it captures

Every load-bearing decision from a real session — including failures:

- **Ship the original bundle.** Don't rewrite 14K lines of Three.js; serve the production bundle and consume its `window.*` exports.
- **Two-layer CSS cascade.** Tailwind v4 + production CSS via `<link>` for byte-level state-rule parity.
- **`pageType` sentinel pattern.** Empty `<div id="page_xxx">` divs gate per-route intro animations; without them every subpage feels dead.
- **`measureHidden()`** for jQuery's `.css("height")` quirk on `display:none` (the original used a swap-render technique; modern `getBoundingClientRect` returns 0 for hidden elements).
- **`gsap.registerPlugin(SplitText)`** before instantiating — otherwise the constructor throws and the entire preloader timeline aborts → white page.
- **`isLocalhost` narrow guard** so the original dev-bypass doesn't swallow YOUR dev server's preloader.
- **Brace escape inside `<style>` vs JSX context** — critical for body content with literal CSS.
- **`.transition-container` outside Barba container** so the flying-logo FLIP survives page swaps.
- **HubSpot embed script** (sites often use HubSpot for contact forms, not Contact Form 7).
- **Module-scoped bound flags break Barba re-init** — use `dataset` tagging on the DOM element instead.
- **Body line-height cascade** — production sets `line-height: inherit`; mismatches accumulate 5px per line across the design.
- **Two burger-toggle elements** — bind via `querySelectorAll`, not the first only.
- **Active-page greying** via `atoll_current` class on `currentPath` match.

Plus 15+ more documented in `references/pitfalls.md`.

## License

MIT — fork it, modify it, learn from it.

## Provenance

Reverse-engineered alongside a real session that rebuilt `atolldigital.com`
(54 routes, 19 commits) at <https://github.com/Waiel5/atoll-replica> (private).
Every pitfall in `pitfalls.md` was observed and fixed in that session.
