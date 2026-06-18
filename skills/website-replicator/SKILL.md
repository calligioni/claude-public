---
name: website-replicator
description: Pixel-faithful website replication into Astro 6 + Tailwind v4 + Vite. Triggers on clone / replicate / mirror / rebuild / recover / reverse-engineer / recreate / copy a website; "I lost my source code"; "rebuild my WordPress site"; "make this site in Astro"; or a bare URL with "do this" / "give me this" / "build me this". Fires eagerly on URL drops without explicit verbs. Orchestrates 11 phases (stack detection → forensic discovery → token extraction → layout architecture → JS modularization → page port → transitions → WebGL → external libs → multi-agent audits) with 28+ documented pitfalls including SplitText/GSAP registration, hidden-element measurement, JSX brace escapes, page-sentinel patterns, Vite cache traps, and Tailwind cascade ordering. Primary target stack is Astro 6 + Tailwind v4; the skill detects the source stack first and adapts (WordPress, Webflow, Framer, Next.js, plain HTML) or warns when adaptation is needed. Strongly prefer this skill over generic frontend tools whenever a live production website is the source of truth.
---

# Website Replicator

This skill turns a live URL into a working, pixel-faithful Astro 6 + Tailwind v4 + Vite codebase. It captures the workflow proven across a full reverse-engineering of `atolldigital.com` (54 routes, full motion system, 19 commits) and bakes in every pitfall that wasted time the first time.

The user typically says one of:
- "Clone this site: <URL>"
- "I lost my source code, can you recover this site"
- "Rebuild this in Astro for me"
- "Replicate the design of <URL>"
- And sometimes just: a URL and "do this"

When triggered, follow the phases in order. Each phase has a dedicated reference file in `references/`. Read the reference when you start that phase — don't load all of them upfront.

## First five minutes (do this immediately)

When the user gives you a URL, before reading any reference file, do these in order:

1. **Acknowledge the target.** Say one sentence: "I'll replicate `<URL>` into Astro 6 + Tailwind v4 — starting with stack detection." No long preamble.
2. **Create a work directory.** If the user named a path, use it. Otherwise default to `<work>/<target>_sourcemaps/` (where `<target>` is the stripped hostname). Plus a sibling `<target>-replica/` for the project itself.
3. **Run Phase 0 detection.** Read `references/detection.md` and run its detection commands against the target. Classify the stack. Save findings to `<work>/agent-notes/detection.md`. **Don't skip this** — the references below assume WordPress+Vite, which is not most sites.
4. **If detection says "adapt the workflow"** — tell the user what you found and ask if they want to proceed, adapt, or pause. Asking is cheap. Forging ahead with wrong assumptions wastes hours.
5. **Then spawn a scrape agent** with the brief in `references/forensics.md`. While it runs, read `references/forensics.md` + `references/pitfalls.md` so you know what to look for when results arrive.
6. **When the scrape returns**, run `scripts/find-sentinels.sh` and `scripts/inventory-motion-hooks.sh` against the captured material — these derive per-target values (the `pageType` union, the motion-hook catalog) that all later phases consume.

Don't try to do all the phases sequentially in one turn. Each phase has its own work; commit early, commit often. The forensic phase produces material; phases 2-10 consume it.

## Quick triggers — when in doubt, fire this skill

The skill should fire when the user says any of:

- "Clone <url>" / "Clone this site"
- "Rebuild my site" / "I lost my source code"
- "Replicate this design"
- "Make this in Astro" / "Make this in Tailwind"
- "I need to recover atolldigital.com" (or any specific URL)
- "Reverse-engineer this site"
- Just shares a URL and "do this" / "build me this" / "I want this"
- "Give me <url>"

Even when the user phrases it casually ("hey can you make me a copy of this") — fire. The skill is heavy but the workflow is fully captured; running it on a wrong-fit task is cheap relative to running a wrong-skill on the right task.

## The replication phases

```
┌──────────────────────────────────────────────────────────────────────┐
│ Phase 0  Detection / recon       → references/detection.md           │
│ Phase 1  Forensic discovery      → references/forensics.md           │
│ Phase 2  Scaffold the stack      → references/stack-setup.md         │
│ Phase 3  Extract design tokens   → references/tokens-and-css.md      │
│ Phase 4  Layout architecture     → references/layout-architecture.md │
│ Phase 5  JS modularization       → references/js-modularization.md   │
│ Phase 6  Page content port       → references/page-content-port.md   │
│ Phase 7  Page transitions        → references/layout-architecture.md │
│ Phase 8  WebGL / Three.js        → references/webgl-strategy.md      │
│ Phase 9  External libraries      → references/external-libs.md       │
│ Phase 10 i18n / multi-locale     → references/i18n.md                │
│ Phase 11 Forms                   → references/forms.md               │
│ Phase 12 Accessibility           → references/accessibility.md       │
│ Phase 13 Framework adaptations   → references/framework-porting.md   │
│   Nuxt 3 specific                → references/nuxt-target.md         │
│   Webflow specific               → references/webflow-target.md      │
│ Phase 14 Audit loop              → references/audit-loop.md          │
│ Phase 15 Deployment (generic)    → references/deployment.md          │
│ Phase 16 Deployment (CF Pages)   → references/cloudflare-pages.md    │
│ Phase 17 Dev experience          → references/dev-experience.md      │
│ Pitfalls catalog (consult often) → references/pitfalls.md            │
└──────────────────────────────────────────────────────────────────────┘

Helper scripts (all in scripts/):

| Script | What it does |
|---|---|
| `discover.sh <target> <work>` | Bootstrap forensic workspace — fetch pages, assets, hunt source maps. Cross-platform (BSD + GNU). |
| `find-sentinels.sh <recovered-js-dir>` | Derive the target's `pageType` union by grepping `getElementById("page_xxx")` calls. |
| `inventory-motion-hooks.sh <html-dir>` | Frequency-ranked catalog of every `data-*` motion-hook attribute. |
| `extract-body.py <html> <domain>` | Clean body extraction + chrome strip + URL rewrite + JSX-vs-set:html escape. |
| `scaffold.mjs <target-host> <replica-dir>` | One-command Astro 6 project bootstrap with all path aliases. |
| `stage-bundle.sh <work> <replica>` | Copy production CSS/JS bundles + fonts into `public/` at original URL paths. |
| `parity-check.mjs <captured> <replica-url>` | Diff captured HTML vs rendered HTML, surface missing classes / data-attrs / assets. |
```

**Phase 0 is non-optional.** It classifies the source stack (WordPress vs Webflow vs Framer vs Next.js vs plain HTML) and adjusts the workflow accordingly. The references below assume a WordPress + Vite + jQuery+GSAP target by default because that's what the original session captured — but real targets vary. Run detection first; adapt.

## Working principles

These shape every decision below — they exist because each one came from a real session where ignoring them cost hours.

### 1. Ship original assets at original URLs when possible

If the production site ships a `dist/app-CHx12itT.css` and a Three.js scene bundle `app-BQbjH4ce.js`, **stage them at their exact original paths** under `public/wp-content/themes/atoll/dist/` (or whatever the original WP/CMS path is). Load the production CSS via `<link>` in your `BaseLayout` head, AFTER Tailwind v4's emit, so the original's custom state rules (e.g. `body.home #header_sticky { transform: translateY(-102%) }`) cascade on top of your utility classes. This gives byte-level parity for every custom rule the original ships — no need to hand-extract 5,000 lines of state CSS.

Same logic for big JS bundles: don't rewrite 14,000 lines of Three.js — ship the production bundle, consume its `window.*` exports.

### 2. Read the recovered code first, write code second

Before writing any port, read:
- `<mirror>/recovered_readable/<theme>-main.pretty.js` (or equivalent deminified entry point)
- `<mirror>/recovered_readable/<theme>-app-XXXX.pretty.css` (or production CSS)

Find the entry-point function (often `initScript()` or `initPageTransitions()`) and the `animationOnPageLoad()` (or equivalent). These tell you the per-page-type intro animation gates, which determine your layout architecture.

### 3. Per-page-type sentinels gate intro animations

Production sites almost always have `<div id="page_home"></div>`, `<div id="page_services"></div>`, `<div id="textable_page"></div>` etc. as **empty sentinel divs** that gate which intro animation timeline runs. The HTML porter agents will strip these as "noise"; **always re-add them via a `pageType` prop on your layout**. Without them, every subpage shows up unanimated. This is by far the most common reason a port "feels dead."

### 4. The chrome belongs in BaseLayout, NOT in pages

Mount `.loading-container`, `.transition-container > .logo-transition-name`, `.transition-progress`, `#menu-mobile`, `.menu-bg` once in `BaseLayout` (outside the Barba container). They are pre-Barba chrome — they survive page swaps. Every per-page reinstance is a leak waiting to happen.

### 5. Dispatch parallel agents for independent work

When porting 40+ pages, never do them sequentially. Dispatch 4-6 parallel agents — one per route family (services, work, articles, static, French). Same for verification: visual audit + code review + mirror diff fire in parallel. See `references/audit-loop.md` for the exact prompts that produced clean results in the test session.

### 6. Verify in browser, not in code

A clean `npm run build` is necessary but never sufficient. Dispatch a Playwright agent to visit each page, scroll, click links, and measure actual element heights. Code that "looks right" can silently fail when `getComputedStyle` returns `"auto"` instead of px on a `display:none` element. The `pitfalls.md` reference catalogs every silent-failure pattern observed.

---

## Recommended workflow

Use TodoWrite to track these once the user gives you a target URL.

### Step 0 — Detect the stack

Read `references/detection.md` and run its diagnostic commands. Classify the target: WordPress / Webflow / Framer / Next.js / Astro / plain HTML. Save the report to `<work>/agent-notes/detection.md`. If the stack doesn't match the skill's defaults (WordPress + Vite + jQuery+GSAP), surface that to the user with the adaptation matrix from `detection.md`.

### Step 1 — Confirm the target & scope

Ask the user (only what you can't infer):
- Target URL (required)
- Single domain or include external subdomains?
- Brand replacement: keep original branding, or swap names/logos to user's own?
- Visibility: production-ready replica, or developer study artifact?

### Step 2 — Forensic discovery

Read `references/forensics.md`. Run `scripts/discover.sh <target> <work>` to bootstrap, then follow up with the manual extensions (motion-hook inventory, sentinel detection):
- Fetch the sitemap + all linked HTML
- Inventory same-origin JS/CSS/images/fonts
- Hunt for `.map` files (sourceMappingURL comments, sibling guesses, Vite manifests)
- Decode any maps that include `sourcesContent` (jackpot — preserves original file structure)
- Deminify what can't be source-mapped
- Output: `<work>/<target>_sourcemaps/{html,assets,maps,recovered_readable,recovered_sources,static_assets}/`

The verdict on source maps varies wildly by target. Some sites (e.g. Locomotive) ship full source maps with `sourcesContent` — that's a jackpot, preserve the directory structure. Others (e.g. Atoll Digital) ship nothing first-party — work from `recovered_readable/` (deminified production bundle).

After discovery, **always run** `scripts/find-sentinels.sh` and `scripts/inventory-motion-hooks.sh` against the captured material. These produce per-target values that subsequent phases consume.

### Step 3 — Scaffold the stack

Read `references/stack-setup.md`. Create a new sibling folder `<target>-replica/` with:
- Astro 6.3.3 + Tailwind v4 + Vite 7
- Match the original's runtime deps versions (use `package-lock` or grep CDN URLs in captured HTML)
- Path aliases (`@components`, `@layouts`, `@scripts`, `@styles`, `@lib`)
- `astro.config.mjs` with `devToolbar.enabled = false` (avoids a known module-load error)
- `scripts/stage-assets.mjs` to copy captured assets into `public/` preserving original URL paths

### Step 4 — Extract design tokens

Read `references/tokens-and-css.md`. Find the production CSS's `:root` block — almost always a fluid-math system (e.g. `--px: 0.06944vw` = 1/1440vw). Copy verbatim into `src/styles/tokens.css`. Add `@font-face` from the original (including hashed font filenames). Load the **entire production CSS** via `<link>` in `BaseLayout` for state-rule parity.

### Step 5 — Build layout architecture

Read `references/layout-architecture.md`. Build:
- `BaseLayout.astro` — head + Barba wrapper + Preloader + flying-logo container + seed script
- `SiteLayout.astro` — extends BaseLayout, takes a required `pageType` prop, mounts Header/Footer/MobileMenu, emits page-gating sentinel divs
- Per-namespace `Home*` chrome (HomeHeader/HomeFooter/HomeMobileMenu) for the home page if it differs

### Step 6 — Modularize the JS monolith

Read `references/js-modularization.md`. Split the original main.js (typically 2,000+ lines, jQuery-flavored) into:
- `src/scripts/index.ts` — entry + per-namespace dispatcher
- `src/scripts/env.ts` — isDesktop, isMobile, getLangCode, etc.
- `src/scripts/core/` — scroll (Lenis), transitions (Barba), splitText, loader, cursor
- `src/scripts/features/` — nav, sliders, forms, ajax-pagination, distortion, hubspot, text-scramble, accordion, page-anim (intro reveals + scroll-trigger)
- All `$(sel)` → `document.querySelector(sel)`
- jQuery `.css("height")` on hidden elements → `measureHidden(sel, "height")` (the swap technique — see pitfalls.md)
- GSAP/Lenis/Barba/Swiper imported from npm

### Step 7 — Port pages in parallel

Read `references/page-content-port.md`. Dispatch 4-6 agents simultaneously, one per route family. Each agent:
- Reads the captured HTML for its routes
- Extracts the body content between the `<header>` close and the `<footer>` open
- Rewrites `https://<target>.com/X` → `/X`
- Strips WordPress/Yoast/oEmbed/plugin noise
- Wraps in `<SiteLayout pageType="..." ...>`
- HTML-entity-escapes literal `{`/`}` in body content (JSX would parse them) — but **NOT inside `<style>` blocks**

### Step 8 — Page transitions & FLIP

Already covered in `references/layout-architecture.md` (the transitions section). Wire Barba's `default` + `to-home` transitions with the FLIP-wordmark flying into `[data-target-heading]`. The flying-logo container's HTML must swap to the destination page's `.title_page` content on every navigation — that's `initChangePageTitle()` and is essential.

### Step 9 — WebGL & Three.js

Read `references/webgl-strategy.md`. Don't rewrite the production bundle. Ship `app-XXXX.js` verbatim at its original URL, then port the small scene-setup function (typically `homeWEBGL()`) to consume `window.Scene`, `window.Vector3`, etc. that the bundle exposes.

### Step 10 — External libraries

Read `references/external-libs.md`. The original site loads several scripts from CDNs that your bundle imports won't replace:
- HubSpot embed (`//js-na3.hsforms.net/forms/embed/v2.js`) — required for contact forms
- SplitText Club GSAP plugin — required for line-mask reveals; must call `gsap.registerPlugin(SplitText)`
- Lottie (sometimes) — for animated SVG numerals
- ImagesLoaded (sometimes) — for awaiting media before triggering reveals

Stage these in `public/` and load via `<script is:inline>` in BaseLayout head.

### Step 11 — Audit loop

Read `references/audit-loop.md`. Dispatch three parallel agents:
1. Visual verification (Playwright screenshots + DOM measurements)
2. Code review (TypeScript / Astro idioms / dead code)
3. Mirror diff (captured HTML vs rendered HTML, class-by-class)

Apply fixes. Re-run. Stop when all three agents return PASS or when you've done 3 iterations with diminishing returns.

### Step 12 — Stand up the repo

`git init` inside the replica folder (or `git subtree split` if it lives under a host repo), `gh repo create --private`, push. This protects the work and gives the user a URL they can clone elsewhere.

---

## Pitfalls catalog — consult often

`references/pitfalls.md` contains 25+ specific gotchas observed in real sessions. The most common ones that block visible progress:

- **`new SplitText()` throws → page renders white.** Must `gsap.registerPlugin(SplitText)` first.
- **Cards collapse to height 0 instead of title-band height.** `getBoundingClientRect()` on `display:none` returns 0; the original used jQuery's swap. Use the `measureHidden(sel, "height")` helper.
- **Subpages have no intro animation.** Missing `<div id="page_xxx">` sentinel — add via `pageType` prop on SiteLayout.
- **No transition animation on click.** The `.transition-container > .logo-transition-name` element doesn't exist in your chrome, so `pageTransitionOut` flies into nothing.
- **Vite `504 + empty Content-Type` for dev-toolbar.** Set `devToolbar.enabled = false` in astro.config.
- **`{SCROLL}` JSX evaluation error.** Literal braces in body text must be escaped to `&#123;` `&#125;` — but ONLY in JSX context, not inside `<style>` blocks.
- **isLocalhost dev-bypass swallows the entire preloader.** The original site's dev-host guard often matches `localhost` too broadly; narrow it to the production dev host only.
- **Multiple Three.js instances warning.** Cosmetic; both render correctly. Only fixable by extending the bundle to expose more constructors.

There are many more — read `references/pitfalls.md` early and reference it whenever something silently fails.

---

## Output

When the workflow is complete, the user should have:

- A standalone `<target>-replica/` folder that runs with `npm install && npm run dev`
- All public routes from the original (typically 40-60 pages)
- Pixel-faithful chrome (header / footer / mobile drawer / preloader)
- All motion: GSAP timelines, ScrollTrigger pins, Lenis smooth-scroll, Barba transitions, SplitText reveals, text scramble, distortion hover, WebGL scenes
- A private GitHub repo with full commit history
- A short `notes/` directory with audit screenshots and per-page audit notes for future-proofing

The replica should pass a visual side-by-side comparison: same fonts, same color palette, same layout, same animation timing, same scroll choreography.
