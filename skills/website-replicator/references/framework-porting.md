# Framework-specific porting recipes

The skill's defaults assume a WordPress + Vite + jQuery target. Real targets vary widely. This reference is the per-framework playbook: when `references/detection.md` classifies the target as Nuxt / Next / Webflow / Framer, follow the matching section here.

## Nuxt 3 → Astro

Nuxt 3 uses Vue 3 single-file components + Vite + Vue Router + Nitro server engine. The visual outputs translate cleanly to Astro; the internals don't.

### Detect

```bash
grep -oE '/_nuxt/' "$work/html/<homepage>" | head -1     # confirms Nuxt 3
grep -oE 'nuxt:.*"version":"3' "$work/html/<homepage>"   # version
```

### What stays the same

- All HTML markup (Vue templates compile to plain HTML after SSR)
- All `<style>` blocks (Vue scoped styles compile to scoped class hashes; preserve verbatim)
- All client-side animations (GSAP, ScrollTrigger, Lenis are framework-agnostic)
- All CSS classes (Tailwind classes work identically)
- All static assets under `/_nuxt/`

### What needs rewriting

| Nuxt artifact | Astro equivalent |
|---|---|
| `<script setup>` Vue logic | Astro frontmatter (TS, no Vue reactivity) |
| `useNuxtApp()`, `useState()`, `useFetch()` | Frontmatter `fetch()` at build time |
| `<nuxt-link>` | `<a>` with href; Barba handles soft transitions |
| `<nuxt-page>` | Astro file-routing (`src/pages/`) |
| `definePageMeta({ middleware: ... })` | Astro middleware (`src/middleware.ts`) |
| `<NuxtLayout>` | `<BaseLayout>` from `src/layouts/` |
| `composables/use*.ts` | Plain TS modules in `src/lib/` |
| Server routes (`server/api/*`) | Astro endpoints (`src/pages/api/*.ts`) with `output: "server"` |
| `nuxt.config.ts` | `astro.config.mjs` |

### Source-map jackpot likelihood: HIGH

Nuxt 3 + Vite production builds **often ship source maps with `sourcesContent`** intact, especially when deployed to Vercel / Netlify / Cloudflare Pages. Check `/_nuxt/*.js.map` aggressively before any porting work.

If JACKPOT, the recovered tree includes:
- `pages/*.vue` — the original page components (Vue SFC source!)
- `components/*.vue`
- `composables/*.ts`
- `layouts/*.vue`
- `app.vue` / `app.config.ts`

That's the entire project. Use it as your source of truth instead of deminified bundles.

### Recipe

1. Confirm Nuxt 3 + Vite via detection.md
2. Run discover.sh; check `/_nuxt/*.js.map` — if JACKPOT, recovered_sources has the full Vue SFC tree
3. For each `.vue` file, the conversion to Astro is:
   - `<template>` → Astro component body (literal HTML)
   - `<script setup>` → Astro frontmatter (rewrite `useNuxtApp`, `useRoute`, etc. as plain functions or static imports)
   - `<style scoped>` → `<style is:scoped>` (Astro auto-scopes)
4. Vue's reactivity (`ref`, `reactive`, `watch`) becomes either static frontmatter or inline `<script>` tags for interactivity
5. Server routes (`server/api/*.ts`) port nearly verbatim to `src/pages/api/*.ts` — both use H3-style Request/Response handlers; Astro's API surface is simpler
6. Asset paths under `/_nuxt/` should be staged into your replica's `public/_nuxt/` so original URLs resolve

### GSAP ScrollTrigger sites specifically

Nuxt + GSAP ScrollTrigger sites typically structure the motion as:
- A single `composables/useScrollAnimations.ts` initializing all ScrollTriggers
- Per-component `onMounted()` calls registering specific triggers
- A `Lenis` instance in `plugins/lenis.client.ts`

Port pattern:
- Move animation logic to `src/scripts/features/page-anim.ts` (per the skill's existing structure)
- Lenis init lives in `src/scripts/core/scroll.ts`
- Per-page ScrollTriggers go in `dispatchByNamespace()` switch in `src/scripts/index.ts`

### Common Nuxt → Astro pitfalls

- Vue's auto-imports won't carry over — add explicit `import` statements in every Astro frontmatter
- Nuxt's `<script setup>` async at the top level → port as `const data = await fetch(...)` in Astro frontmatter (Astro runs at build time)
- `~/` and `@/` path aliases — re-create in `tsconfig.json` `paths`
- `useHead()` → Astro's `<head>` slot pattern; reorganize SEO meta in BaseLayout
- Nuxt's `definePageMeta({ layout: "blog" })` → import `BlogLayout.astro` per-page

## Next.js → Astro

Next.js 13+ uses React Server Components + the App Router. Heavier rewrite than Nuxt.

### Detect

```bash
grep -oE '/_next/' "$work/html/<homepage>" | head -1
grep -oE 'next/script\|next/image\|next/link' "$work/recovered_readable"/*.js 2>/dev/null
```

### What stays the same

- HTML markup (RSC outputs plain HTML after server render)
- CSS / Tailwind classes
- Static assets under `/_next/static/`

### What needs rewriting

| Next.js | Astro |
|---|---|
| `app/page.tsx` (RSC) | `src/pages/index.astro` |
| `app/layout.tsx` | `src/layouts/BaseLayout.astro` |
| `'use client'` components | `<script>` tags in Astro or React island (`client:idle`) |
| `next/image` | `astro:assets` Image component |
| `next/link` | `<a>` with Barba or Astro view transitions |
| `next/font` | `@font-face` in `tokens.css` |
| `app/api/*/route.ts` | `src/pages/api/*.ts` |
| `getServerSideProps` / `getStaticProps` | Astro frontmatter `fetch()` |
| `useState`, `useEffect`, `useContext` | Vanilla JS in `<script>` OR React island |

### Source-map jackpot likelihood: MODERATE

Next.js prod builds occasionally ship maps at `/_next/static/chunks/*.js.map` but Vercel by default strips them in production. Worth checking; don't be surprised when EMPTY.

### React island compromise

If the original has heavy React state management (Zustand, Redux, complex hooks), porting to vanilla JS is a substantial rewrite. Use Astro's React integration to keep the React component as a client island:

```bash
npx astro add react
```

```astro
---
import HeavyReactComponent from "../components/HeavyReactComponent.tsx";
---
<HeavyReactComponent client:idle />
```

Faster to ship; trade-off is the React bundle ships to the client.

## Webflow → Astro

Webflow generates static HTML with its own `webflow.js` runtime for interactions.

### Detect

```bash
grep -oE 'webflow' "$work/html/<homepage>" | head -1
grep -oE 'data-w-id="[^"]+"' "$work/html/<homepage>" | head -3
```

### What stays the same

- All HTML markup (Webflow exports plain HTML)
- All inline styles (Webflow generates them)
- Static assets

### What needs rewriting

- `webflow.js` — Webflow's runtime. Either ship it as-is from CDN OR rewrite specific interactions in GSAP
- `data-w-id` and `.w-*` classes — these drive Webflow interactions. Without `webflow.js`, the animations don't fire
- jQuery + Webflow's `Webflow.require()` calls — replace with vanilla DOM

### Recipe

For an exact replica that preserves Webflow's interactions:
1. Stage `webflow.js` (downloaded from the original) in `public/js/webflow.js`
2. Load in BaseLayout: `<script src="/js/webflow.js" defer></script>`
3. Preserve every `data-w-id` and `.w-*` class verbatim
4. The animations should just work

For a clean port:
1. Identify each `data-w-id` interaction in `webflow.js` (it's a giant switch on the ID)
2. Rewrite each as a GSAP timeline in `src/scripts/features/page-anim.ts`
3. Remove `webflow.js` from the build

The second path is harder but produces dev-friendlier output.

## Framer → Astro

Framer ships React Server Components served from `framerusercontent.com`. The hardest port.

### Detect

```bash
grep -oE 'framerusercontent\.com\|framer\.com' "$work/html/<homepage>" | head -1
```

### Reality check

Framer sites are deeply React + Framer Motion. The "ship the bundle" pattern barely applies because the bundle is split across CDN chunks. **Recommend partial replication only:**

- Phases 1, 2, 4, 6 (forensic / scaffold / layout / content port) — feasible
- Phases 5, 7, 8 (JS modularization / transitions / WebGL) — not feasible without rewriting most of Framer's runtime

Tell the user upfront. Asking is cheap.

## Squarespace / Wix / Shopify

Three commerce / publishing platforms with proprietary runtimes.

### Detect

```bash
grep -oE 'sqsp\.net\|squarespace' "$work/html/<homepage>"  # Squarespace
grep -oE 'wixstatic\.com'                                   # Wix
grep -oE 'cdn\.shopify\.com'                                # Shopify
```

### Reality check

These platforms are not feasibly replicable to a faithful, code-clean Astro project. Their runtimes are proprietary, often obfuscated, and tied to backend services you don't have. **Pivot to a different goal:**

- "Replicate the visual design as a fresh Astro project" (no content port; visual reference only)
- "Recreate the design language" (extract colors/fonts/spacing; rebuild content from scratch)

Tell the user. Don't pretend the skill can do something it can't.

## Plain HTML / static-site brochureware

Easiest case. No bundler, no SPA, no framework. Just HTML + CSS + maybe vanilla JS.

### Recipe

1. Phase 1: scrape HTML + assets
2. Phase 2: scaffold Astro project
3. Phase 6: port each HTML page as an Astro page (almost copy-paste — wrap body in `<BaseLayout>`)
4. Phase 4: extract chrome (header/footer) into shared components
5. Phase 10: audit + deploy

Most static sites are 1-3 days of work end-to-end. The motion patterns are usually CSS keyframes or minimal vanilla JS, easy to preserve.

## Multi-framework targets

Some sites are hybrids — WordPress for content + a React island for the product configurator, or Webflow for landing + Vue for the dashboard. Detect each region separately:

1. Identify which routes use which framework
2. Port each region using the matching recipe
3. If they share chrome, extract the chrome to BaseLayout once

## Anti-patterns

- Don't promise pixel-faithful replication for stacks the skill isn't designed for. Be upfront when capabilities are limited.
- Don't auto-detect "WordPress" from a single `/wp-content/` URL — many static sites mirror WP paths for no real reason. Check for the WP REST API + Yoast meta to confirm.
- Don't ship Webflow's `webflow.js` to a "clean Astro port" — it's a giant compatibility shim that defeats the purpose.
- Don't try to port Framer SSR JSON; it's not designed for re-hosting.
