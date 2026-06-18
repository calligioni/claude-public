# Changelog

All notable changes to the `website-replicator` skill.

Each version corresponds to a published commit on `main` of github.com/Waiel5/website-replicator. Iteration cadence was driven by real-world tests: each version landed after an actual replication of a different production site surfaced new patterns / pitfalls / scripts that needed to ship.

## v0.8 — 2026-05-18

Triggered by: full `nvg8.io` replica build (Nuxt 3 + GSAP + ScrollSmoother + Rive WASM, 7 commits)

### Added
- `scripts/inventory-scrolltrigger.sh` — enumerate every GSAP ScrollTrigger config in a deminified bundle (selectors, anchors, scrub, pin, callbacks)
- `scripts/probe-motion.mjs` — Playwright probe that verifies the motion system actually booted (`ScrollTrigger.getAll().length`, Lenis, Rive canvas count, console errors); exits non-zero on broken motion for CI integration
- `package.json` at skill root so `npm install && npm run probe` work after `git clone`

### New pitfalls (catalog → 48)
- Rive state-machine names ≠ `"State Machine 1"` — use `strings(1)` or `stateMachineNames` auto-detect
- `@rive-app/canvas` WASM URL defaults to unpkg.com — fails on CSP-strict Cloudflare; self-host + `RuntimeLoader.setWasmUrl()`
- `__name:` component inventory is a SUPERSET of rendered components
- Nuxt `_payload.json` is empty on pure-prerendered sites without async data calls

## v0.7 — 2026-05-18

Triggered by: full `terminal-industries.com` replica build (Nuxt 3 + Storyblok + Reka UI, 5 commits, Cloudflare-ready)

### Deepened
- `references/nuxt-target.md` — `_payload.json` flat-array-with-back-refs format with working `derefPayload()` walker (recursion blows stack on naive impl); Reka UI / Radix port options with a11y trade-offs; Astro `<ClientRouter />` recommended over Barba
- `references/external-libs.md` — SplitText Club GSAP license-aware patterns (CSS-only fallback + `registerSplitText()` extension point)

### New pitfalls (catalog → 42)
- Nuxt `_payload.json` is flat-array with back-refs, not nested JSON
- `scaffold.mjs` errors when stage-assets.mjs has no manifest
- Non-standard Nuxt font paths (`/static/fonts/` vs `/_nuxt/`)
- Astro `<ClientRouter />` beats Barba for Nuxt-flavored replicas

## v0.6 — 2026-05-18

Triggered by: full `aim.obys.agency` replica build (Webflow, 5 commits)

### Deepened
- `references/webflow-target.md` — modern Webflow ships multiple JS chunks not just `webflow.js`; jQuery + 3-4 schunks + webflow.js loaded in order; w-mod-js inline-script stamp is load-bearing; JSON-string + `<Fragment set:html>` pattern for body content with literal `{}` braces

### New pitfalls (catalog → 38)
- Webflow's `w-mod-js` inline script must stay inline (FOUC fix)
- Webflow ships multiple JS chunks, not just webflow.js
- Astro JSX parses literal `{...}` in body content
- `scaffold.mjs` was missing `dirname` import (one-line fix)

## v0.5 — 2026-05-18

Triggered by: three parallel Phase 1 tests on aim.obys.agency, terminal-industries.com, nvg8.io

### Hardened scripts
- `discover.sh` — PATH export at top (subshell tr/sed/curl); sitemap-XML validation + homepage-anchor crawl fallback; JSON validation on every `.map` file (403 SPA-fallback was masquerading as captured map); distinct 403_LOCKED / NOT_JSON / VALID outcomes; sourceMappingURL comment scan; Nuxt `_payload.json` probe
- `find-sentinels.sh` — multi-framework aware (WordPress, Webflow `data-wf-page`, Vue `useRoute()`, React `useRouter()`, Svelte `$page.route`); explicit "N/A — route-driven gating" verdict
- `inventory-motion-hooks.sh` — filters Vue scoped-style `data-v-*` noise; detects framework-specific motion patterns

### New
- `scripts/inventory-components.sh` — extracts component graph from SPA bundles via Vue `__name:` / React `displayName` / Svelte `__svelte_meta` / Vite chunk filenames
- `references/nuxt-target.md` — Nuxt-specific deep dive
- `references/webflow-target.md` — Webflow-specific deep dive

### New pitfalls (catalog → 34)
- Nuxt sitemap returns JSON 404 (not XML)
- 403-SPA-fallback masquerading as captured source maps
- Vue scoped-style `data-v-*` flooding motion-hook inventory
- ScrollSmoother + Lenis on the same page (foot-gun)
- Webflow's pre-JS initial-state `<style>` block is load-bearing
- Known-403 CDN hosts (short-circuit map probing)

## v0.4 — 2026-05-18

Triggered by: explicit user direction "nothing deferred"

### Added
- `references/i18n.md` — multi-locale strategies (path prefix vs slug translation vs subdomain vs TLD), WPML pattern, RTL, per-locale sitemap
- `references/forms.md` — per-provider integration: HubSpot, CF7, Marketo, Pardot, Netlify, Formspree, custom POST
- `references/accessibility.md` — landmark structure, focus traps, reduced-motion, page-transition focus management, Definition-of-Done a11y items
- `references/cloudflare-pages.md` — Wrangler, `_redirects`, `_headers` templates, Pages Functions, R2, custom domains, performance budgets, troubleshooting
- `references/framework-porting.md` — per-framework recipes: Nuxt 3, Next.js, Webflow, Framer, Squarespace/Wix/Shopify, plain HTML, multi-framework targets
- `references/dev-experience.md` — fresh-clone test, naming conventions, comment policy, TypeScript strict, path aliases, README requirements, Definition-of-Done checklist
- `scripts/scaffold.mjs` — one-command Astro project bootstrap
- `scripts/parity-check.mjs` — captured vs rendered HTML diff
- `scripts/stage-bundle.sh` — stage production bundles at original URL paths

## v0.3 — 2026-05-18

Triggered by: skill-critique agent + cold-start test on locomotive.ca

### Fixed
- `discover.sh` — replaced BSD-incompatible `sed -E` regex with `perl -pe`; fixed homepage HTML resolution; added User-Agent header; added inline source-map decoder with `__up__/` path preservation
- `forensics.md` — extended with source-map jackpot branch, bot-protection / Cloudflare / WAF fallback, `<head>` parity report instructions
- Dropped ghost `scripts/discover.py` reference

### Added
- `references/detection.md` — Phase 0 stack classifier with decision matrix
- `SKILL.md` — added Phase 0 detection as non-optional; rewrote description to front-load triggers + cover WordPress recovery

## v0.2 — 2026-05-18

Triggered by: initial v0.1 audit + Webflow test

### Fixed
- Various
- Description tweaked

## v0.1 — 2026-05-18

Initial release.

### Genesis

Forged from a real reverse-engineering of `atolldigital.com` — 54 routes, 20 commits, every pitfall documented. The skill captured every load-bearing decision from that session:

- "Ship the original bundle" pattern (avoid rewriting 14K lines of Three.js)
- Two-layer CSS cascade (Tailwind v4 + production CSS via `<link>`)
- `pageType` sentinel architecture pattern
- `measureHidden()` swap technique
- `gsap.registerPlugin(SplitText)` requirement
- `isLocalhost` narrow-guard
- JSX brace escape vs `<style>` blocks
- `.transition-container` outside Barba container
- HubSpot embed required for contact forms
- WPML lang switcher fill
- Footer wordmark needs single SVG, not three-glyph header logo
- Module-scoped bound flags break Barba re-init
- Resize-listener leaks across page transitions

11 phases, 25 pitfalls, 1 helper script.

## Statistics

| Version | Files | Lines | Pitfalls | Scripts | References | Real-world tests |
|---|---|---|---|---|---|---|
| v0.1 | 12 | 2,797 | 25 | 1 | 10 | atoll (during build) |
| v0.2 | 15 | ~3,300 | 27 | 1 | 11 | locomotive (Phase 1) |
| v0.3 | 16 | ~3,700 | 27 | 4 | 12 | detection agent |
| v0.4 | 27 | 4,986 | 28 | 6 | 16 | — |
| v0.5 | 30 | 5,450 | 34 | 7 | 18 | obys + terminal + nvg8 (Phase 1) |
| v0.6 | 30 | ~5,700 | 38 | 7 | 18 | obys-aim full replica |
| v0.7 | 30 | ~5,900 | 42 | 7 | 18 | terminal-industries full replica |
| v0.8 | 33 | ~6,300 | 48 | 10 | 18 | nvg8 full replica |

## Shipped replicas (built using this skill)

1. **github.com/Waiel5/atoll-replica** (private) — WordPress + Vite, 54 routes, 20 commits
2. **github.com/Waiel5/obys-aim-replica** (private) — Webflow, 5 commits
3. **github.com/Waiel5/terminal-industries-replica** (private) — Nuxt 3 + Storyblok, 5 commits, CF Pages ready
4. **github.com/Waiel5/nvg8-replica** (private) — Nuxt 3 + GSAP + Rive, 7 commits, CF Pages ready
