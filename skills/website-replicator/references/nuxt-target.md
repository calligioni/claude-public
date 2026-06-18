# Nuxt 3 target — specific workflow adaptations

Nuxt 3 is the most common non-WordPress target. Three real-world tests of the skill (Terminal Industries, nvg8.io, others) all classified as Nuxt 3 + Vite + Vue 3. This reference is the per-target playbook when `references/detection.md` matches Nuxt.

## Detection signals

Confirm Nuxt 3 specifically (not Nuxt 2 — different runtime):

```bash
curl -sL "$target" | tee /tmp/home.html
grep -oE '/_nuxt/' /tmp/home.html | head -1   # Nuxt 3 asset path
grep -oE '__NUXT__|data-nuxt' /tmp/home.html  # SSR hydration markers
grep -oE 'nuxt:[^"]*"version":"3' /tmp/home.html
```

If `data-nuxt-img` or `data-nuxt-pic` appear → Nuxt Image module. If `data-reka-*` → Reka UI (Vue port of Radix). If `data-radix-*` → Radix.

## Phase 1 — Forensic discovery for Nuxt

Three Nuxt-specific shortcuts to exploit BEFORE deminification:

### 1. `_payload.json` per route — free CMS content

Nuxt SSG/SSR sites with `payloadExtraction: true` (default for static builds) generate one `_payload.json` per route. Each contains the page's STRUCTURED data — including any Storyblok / Sanity / Contentful / Strapi content.

**Critical format gotcha:** the payload is NOT plain nested JSON. Nuxt serializes refs as a **flat array with integer back-references** to dedupe:

```json
{
  "data": [
    /* index 0 */ { "story": 1 },
    /* index 1 */ { "name": 2, "content": 3 },
    /* index 2 */ "Home Page",
    /* index 3 */ { "body": 4 },
    /* index 4 */ [5, 6, 7],
    /* index 5 */ { "component": "Hero", "title": 8 },
    /* index 6 */ { "component": "FeatureGrid", "items": 9 },
    ...
  ]
}
```

A naive recursive walker that follows every integer as a ref blows the stack — because BOOLEAN props (`true` → 1, `false` → 0) also look like back-refs. You need a **shallow-deref + visited-set walker**:

```ts
function derefPayload(arr: any[]): any {
  const seen = new Map();
  function walk(node: any, depth = 0): any {
    if (depth > 50 || node == null) return node;
    if (typeof node === "number" && Number.isInteger(node) && node >= 0 && node < arr.length) {
      // Only deref if the target index actually looks like an object/array
      const target = arr[node];
      if (typeof target === "object" && target !== null) {
        if (seen.has(node)) return seen.get(node);
        seen.set(node, target);
        return walk(target, depth + 1);
      }
      return node; // not a ref; literal small int
    }
    if (Array.isArray(node)) return node.map((x) => walk(x, depth + 1));
    if (typeof node === "object") {
      const out: any = {};
      for (const [k, v] of Object.entries(node)) out[k] = walk(v, depth + 1);
      return out;
    }
    return node;
  }
  return walk(arr[0]);
}
```

Then walk the resolved tree to get the section sequence:

```ts
const payload = JSON.parse(await readFile("/path/to/_payload.json", "utf8"));
const resolved = derefPayload(payload.data);
const sections = resolved.story.content.body;
// → [{ component: "Hero", title: "..." }, { component: "FeatureGrid", items: [...] }, ...]
```

Each section's `component` name maps 1:1 to a `src/components/sections/<Component>.astro` file in your replica. Each section's props become the Astro component's props. **You've recovered the entire CMS-driven page structure without writing any HTML extraction code.**

Saved real time on the Terminal Industries port: the home page's 13 sections (VideoCarousel, SeparatorNotch, SectionIntroduction × 4, FeaturesSteps, YOSSection, FullscreenFeatures, LogoGrid × 2, Quote, FormReference) came out of the payload as a clean ordered array.

Fetch every route's payload:

```bash
# Probe the home payload
curl -sL "$target/_payload.json" -o "$work/agent-notes/home_payload.json"

# For every captured page URL, try the payload
while IFS=$'\t' read -r status url file; do
  [ "$status" != "200" ] && continue
  payload_url="${url%/}/_payload.json"
  payload_name=$(echo "$payload_url" | perl -pe "s{[^A-Za-z0-9._-]}{_}g")
  curl -sL "$payload_url" -o "$work/agent-notes/payloads/$payload_name" 2>/dev/null
done < "$work/pages_manifest.tsv"
```

If the responses are JSON with a `data` key, you have the entire CMS content tree for each route. Read these instead of HTML-extracting copy by hand.

### 2. `__name:` property in chunk bundles — component graph

Vue 3 SFCs compiled by Vite preserve component names via `__name:"ComponentName"` properties in the production bundle. Even when source maps are 403/EMPTY, you get the full component graph for free:

```bash
scripts/inventory-components.sh "$work/assets" | tee "$work/agent-notes/components.txt"
```

This yields output like:
```
SectionHero
SectionChapter1
SectionChapter2
HeaderBar
FooterTransition
IntroTransition
...
```

Each is a Vue component the original site has. Your replica's `src/components/sections/<Name>.astro` file structure mirrors them 1:1.

### 3. Chunk filenames preserve composable names

When Vite uses default chunking, files like `useScrollTrigger.ClxjLDci.css` literally name the composable. Grep:

```bash
ls "$work/assets" | grep -E '^(use|Section|Layout|Component)' > "$work/agent-notes/chunk-names.txt"
```

These are your composables. Port each as `src/lib/<name>.ts` (or `src/scripts/features/<name>.ts` if motion-related).

### 4. Source-map likelihood

Nuxt 3 + Vite production builds:
- **Vercel / Netlify defaults** — maps usually stripped. EMPTY verdict common.
- **Cloudflare Pages defaults** — varies; check both `/_nuxt/*.js.map` and `sourceMappingURL` comments.
- **Self-hosted on a Node server** — sometimes ships maps if `vite.build.sourcemap = true` left at default.
- **Static export via `nuxi generate`** — usually strips maps.

Even with EMPTY, the `_payload.json` + `__name:` leak gives 80% of what source maps would.

## Phase 4 — Layout architecture for Nuxt → Astro

Vue Router + Nuxt's file-routing translates directly to Astro's `src/pages/` file-routing. One-to-one mapping:

| Nuxt | Astro |
|---|---|
| `pages/index.vue` | `src/pages/index.astro` |
| `pages/[slug].vue` | `src/pages/[slug].astro` |
| `pages/blog/[...slug].vue` | `src/pages/blog/[...slug].astro` |
| `layouts/default.vue` | `src/layouts/BaseLayout.astro` |
| `layouts/blog.vue` | `src/layouts/BlogLayout.astro` |
| `components/SectionHero.vue` | `src/components/SectionHero.astro` |
| `composables/useScroll.ts` | `src/lib/use-scroll.ts` (pure TS, no Vue reactivity) |
| `plugins/lenis.client.ts` | `src/scripts/core/scroll.ts` |
| `server/api/contact.post.ts` | `src/pages/api/contact.ts` |
| `nuxt.config.ts` | `astro.config.mjs` |

### Per-page intro animation in Nuxt — NOT sentinel divs

Nuxt sites don't use `<div id="page_xxx">` empty sentinels. They gate on:

- **`route.name`** in a global `app.vue` watch
- **`onMounted`** lifecycle hook in the page component
- **`<RouterView>` transition** props
- **`useNuxtApp()` hooks** like `page:transition:finish`

When porting to Astro, recreate this via the per-namespace dispatcher (see `references/js-modularization.md` — same pattern, different gating source):

```ts
function dispatchByNamespace(): void {
  const route = window.location.pathname;
  if (route === "/" || route === "/index.html") homeIntro();
  else if (route.startsWith("/blog/")) blogIntro();
  else if (route.startsWith("/work/")) workIntro();
  else defaultIntro();
}
```

Or use Barba's namespace pattern if you're shipping Barba transitions (see `references/layout-architecture.md`).

## Phase 5 — JS modularization for Vue/Nuxt sites

The skill's default playbook assumes a monolithic main.js → ES modules port. **Nuxt is the opposite**: 40+ tidy SFCs → Astro components + a small set of feature modules.

### Recipe

1. Read `recovered_sources/` if source-map jackpot — it has the original `.vue` files
2. Otherwise read `agent-notes/components.txt` (from `inventory-components.sh`) — names without bodies
3. For each component:
   - **Visual component** (Section*, Header, Footer, Card, etc.) → `src/components/<Name>.astro`
   - **Layout** → `src/layouts/<Name>.astro`
   - **Composable** (useX) → `src/lib/<name>.ts` if pure data, or `src/scripts/features/<name>.ts` if DOM/motion

### Vue SFC → Astro conversion pattern

```vue
<!-- Vue SFC -->
<template>
  <section class="hero">
    <h1>{{ title }}</h1>
    <ScrollText :text="copy" />
  </section>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import ScrollText from "./ScrollText.vue";
import { useScrollAnimation } from "@/composables/useScrollAnimation";

const props = defineProps<{ title: string; copy: string }>();
const heroRef = ref<HTMLElement>();
onMounted(() => useScrollAnimation(heroRef.value));
</script>
```

→

```astro
---
// Astro component
import ScrollText from "./ScrollText.astro";

interface Props { title: string; copy: string }
const { title, copy } = Astro.props;
---

<section class="hero">
  <h1>{title}</h1>
  <ScrollText text={copy} />
</section>

<script>
  import { useScrollAnimation } from "@/scripts/features/scroll-animation";
  document.querySelectorAll<HTMLElement>(".hero").forEach(useScrollAnimation);
</script>
```

Vue's reactivity (`ref`, `reactive`) becomes either static frontmatter (build-time) or vanilla DOM/scope-tag patterns (runtime).

## Reka UI / Radix UI components

If detection found `data-reka-*` or `data-radix-*` attributes, the original used a headless UI library. Common Reka primitives that leak: `NavigationDropdown`, `NavigationDropdownSection`, `NavigationMenuRoot`, `NavigationMenuTrigger`, `NavigationMenuContent`, `NavigationMenuLink`.

For the Astro port, three options:

1. **Hand-roll CSS-only equivalents** (fastest; ~50 lines per primitive). Trade-off: ARIA fidelity drops vs the original. Acceptable for visual replicas; not acceptable for production sites that need a11y parity.
2. **Pull `@radix-ui/react`** wrapped in an Astro React island via `client:idle`. Trade-off: ships React runtime (~40KB). Preserves ARIA exactly.
3. **Use Headless UI for Astro** (`@headlessui/astro` if available) or `headlessui-vue` via the Vue integration. Trade-off: another dep, but framework-native.

For most agency-style replicas, option 1 is the right default. **Document the a11y compromise** in your replica's README so the next developer knows to upgrade.

## Astro view transitions vs Barba

`references/layout-architecture.md` defaults to Barba for page transitions because that's what the original Atoll session used. For Nuxt → Astro ports specifically, **prefer Astro's native `<ClientRouter />`** (view-transitions API):

```astro
---
import { ClientRouter } from "astro:transitions";
---
<html>
  <head>
    <ClientRouter />
    <!-- ... -->
  </head>
  <body>
    <!-- per-page content -->
  </body>
</html>
```

It's lighter (no Barba dep), uses the browser's native View Transitions API where supported, falls back to instant navigation elsewhere. Per-page hooks via `astro:after-swap` event match the Barba `afterEnter` pattern you'd port from a Vue/Nuxt page.

The Terminal Industries replica uses `<ClientRouter />` exclusively — soft navigation works without the overhead of Barba.

## Phase 9 — External libraries on Nuxt

Common bundles to detect and stage:

| Library | Detection signal | Action |
|---|---|---|
| GSAP + ScrollTrigger | bundle chunks named `Linear.js`, `Power.js`, `ScrollTrigger.js` | npm `gsap` |
| SplitText | bundle chunk `SplitText.js` | Stage CDN script (Club GSAP) |
| ScrollSmoother | bundle chunk `ScrollSmoother.js` | npm `gsap` (Club) |
| Lenis | `lenis@1` in chunk filenames | npm `lenis` |
| Rive | `@rive-app/canvas` | npm `@rive-app/canvas` + Cloudflare CSP `'wasm-unsafe-eval'` |
| ScrollyVideo | `ScrollyVideo` chunk | npm `scrollyvideo` (or custom) |
| TweakPane | `tweakpane` (often dev-only) | Skip in replica |

## Deployment

If the original was on Vercel and you're moving to Cloudflare Pages:
- Use `@astrojs/cloudflare` adapter for SSR routes (only if your replica has them)
- For static replicas (most), use `output: "static"` + CF Pages — simpler, faster
- See `references/cloudflare-pages.md` for the full deployment guide
- Add `Content-Security-Policy` headers in `public/_headers` if the original loaded Rive WASM or other WASM (needs `'wasm-unsafe-eval'`)

## Anti-patterns

- Don't try to port Vue's `<Transition>` component to Astro literally — Astro's view-transitions API or Barba handle this differently
- Don't bring Pinia/Vuex into the Astro port — most replicas don't need client state management; use signal patterns or vanilla DOM
- Don't ship the original `_payload.json` files into your replica — they're build-time outputs. Use them only as a SOURCE of content during porting.
- Don't auto-port `useFetch()` calls to Astro frontmatter without understanding what they fetched. Sometimes they're SSR-only (CMS fetches); sometimes they're client-side (user-specific data) and need different handling.
