# Webflow target — specific workflow adaptations

Webflow is the second most common non-WordPress target. Webflow sites are HTML-exported with a runtime called IX2 (Interactions 2.0) that animates elements via `data-w-id` attributes. The runtime is closed-source (Webflow CDN-served).

## Detection signals

```bash
grep -oE 'webflow' /tmp/home.html | head -1
grep -oE 'data-w-id="[^"]+"' /tmp/home.html | head -3
grep -oE 'data-wf-page="[^"]+"' /tmp/home.html | head -1
grep -oE 'cdn\.prod\.website-files\.com' /tmp/home.html | head -1
```

## Phase 1 — Forensic discovery for Webflow

### Source maps: don't bother

Webflow's CDN (`cdn.prod.website-files.com`) returns **403 on every `.map` URL** — the maps exist on origin but are unconditionally locked. After detecting Webflow, skip the source-map hunt entirely and write `EMPTY: Webflow CDN locked` as the verdict.

### What you DO have

Webflow exports the full rendered HTML with every animation's initial state inlined as a `<style>` block in `<head>`. That's the load-bearing artifact.

```bash
# Extract the initial-state style block
grep -A 100000 '<style id="wf-anim' "$work/html/<homepage>" \
  | sed '/<\/style>/q' > "$work/agent-notes/webflow-initial-state.css"
```

This block declares pre-animation transforms / opacities for every `data-w-id` across all 4 Webflow breakpoints. **Preserve verbatim** in your replica's BaseLayout `<head>`.

### `data-w-id` is the binding key

Every animated element has a `data-w-id="<24-char-hex>"`. The Webflow runtime reads these on page load and binds the matching IX2 timeline. Without `webflow.js`, the IDs do nothing.

Inventory them:

```bash
grep -hoE 'data-w-id="[^"]+"' "$work/html"/*.html* | sort -u > "$work/agent-notes/wf-ids.txt"
```

Each unique ID corresponds to one IX2 timeline in `webflow.js`.

## Two replication strategies

### Strategy A — Ship webflow.js (faithful, fast)

Modern Webflow sites ship **multiple JS files**, not just `webflow.js`. Real-world observation: the live `aim.obys.agency` loads, in this exact order:

1. **jQuery** (CloudFront, `jquery-3.5.1.min.dc5e7f18c8.js`)
2. **schunk.82f44582…js** (Webflow code-split chunk 1)
3. **schunk.36b8fb49…js** (chunk 2)
4. **schunk.1516315476…js** (chunk 3)
5. **webflow.<HASH>.js** (entry; reads `data-w-id` and binds IX2)
6. **lenis** (if the developer added it — sometimes loaded after Webflow)

Download every same-origin and CloudFront-origin script the captured `<head>` references, stage them in `public/js/` (drop query strings — Webflow's runtime only needs the script tags in order), and load them in BaseLayout in that exact order:

```astro
<script is:inline src="/js/jquery.min.js"></script>
<script is:inline src="/js/schunk-82f44582.js" defer></script>
<script is:inline src="/js/schunk-36b8fb49.js" defer></script>
<script is:inline src="/js/schunk-1516315476.js" defer></script>
<script is:inline src="/js/webflow.js" defer></script>
```

If a chunk is missing, IX2 silently fails on one component group — usually visible as one section that doesn't animate while others do.

### The `w-mod-js` inline-script gotcha

Webflow's exported `<head>` contains a short inline `<script>` that runs BEFORE anything else:

```html
<script>
  document.documentElement.className =
    document.documentElement.className.replace(/\bw-mod-no-js\b/g, '').trim()
    + ' w-mod-js' + ('ontouchstart' in document.documentElement ? ' w-mod-touch' : '');
</script>
```

This stamps `w-mod-js` (and optionally `w-mod-touch`) onto the `<html>` element. The initial-state CSS in the style block is gated on `html.w-mod-js:not(.w-mod-ix) [data-w-id=...]` — so without this stamp, the initial-state rules NEVER MATCH and you get unstyled FOUC + jumpy animations.

**Preserve verbatim in BaseLayout `<head>` as `<script is:inline>` — NOT deferred, NOT in a module.** It must run synchronously before paint.

```astro
<script is:inline set:html={`
  document.documentElement.className =
    document.documentElement.className.replace(/\\bw-mod-no-js\\b/g, '').trim()
    + ' w-mod-js' + ('ontouchstart' in document.documentElement ? ' w-mod-touch' : '');
`}></script>
```

Then `<html>` ships with `class="w-mod-no-js"` initially so the script has something to strip:

```astro
<html lang={lang} class="w-mod-no-js">
```

### Body content with literal `{` / `}` braces

Webflow embeds sometimes have literal `{}` characters in user-authored copy (variable placeholders, code samples, math notation). Astro's JSX parser sees `{Service}` and tries to evaluate it.

The portable fix: capture each route's body HTML as a JSON-string content file and render via `<Fragment set:html={...}>`:

```ts
// src/content/home.json
{ "body": "<div>some content with { literal braces } that won't be JSX-parsed</div>" }
```

```astro
---
import content from "@/content/home.json";
---
<BaseLayout>
  <Fragment set:html={content.body} />
</BaseLayout>
```

This bypasses JSX entirely. Same pattern works for any other replication where body content has CSS in `<style>` blocks (also braces) or template literals from the source CMS.

### Strategy B — Rewrite in GSAP (clean, slow)

Replace IX2 with GSAP timelines. For each `data-w-id`:

1. Open `webflow.js` (deminified) and find the `case "<ID>":` block in the IX2 dispatch
2. Read the timeline definition (Webflow uses its own DSL — looks like `{steps:[{actions:[{type:"STYLE",...}]}]}`)
3. Translate to a GSAP timeline targeting the same element

Tedious. Only worth it if the user explicitly wants the Webflow dependency gone.

Most agency replicas pick Strategy A.

## Page-sentinel pattern: data-wf-page

Webflow doesn't use `<div id="page_xxx">` sentinels. It uses `data-wf-page="<24-char-hex>"` on the `<html>` element. Each route has a unique value:

```html
<html data-wf-page="655793a3fbb135fe41b85512" lang="en">
```

If your replica needs per-route gating:

```astro
<!-- BaseLayout.astro -->
<html data-wf-page={pageId} lang={lang}>
```

```ts
// src/scripts/index.ts dispatcher
const pageId = document.documentElement.getAttribute("data-wf-page");
switch (pageId) {
  case "655793a3fbb135fe41b85512": homeIntro(); break;
  case "655793a3fbb135fe41b85513": aboutIntro(); break;
}
```

Or simply gate on `route.pathname` since Astro file-routing is 1:1 with the URL.

## CSS strategy

Webflow's CSS is in a single file with semantic class names (`.button`, `.hero-section`, `.div-block-42`). Load it via `<link>` in BaseLayout — same pattern as the Atoll production CSS:

```astro
<link
  rel="stylesheet"
  href="/css/<target-site>.webflow.<HASH>.css"
  type="text/css"
  media="all"
/>
```

Do NOT try to extract design tokens from this CSS for Tailwind v4 — Webflow's CSS is component-class-driven, not utility-driven. Just ship it as-is.

If you want a clean port, hand-port section by section to Tailwind utilities. Substantial work; only for replicas going to long-term production.

## Lottie integration

Webflow sites commonly use Lottie SVG renderers via `data-animation-type="lottie"`:

```html
<div data-animation-type="lottie" data-src=".../animation.json" data-renderer="svg"
     data-autoplay="1" data-loop="1" data-direction="1" data-duration="0">
</div>
```

Webflow's runtime loads Lottie automatically. If you ship `webflow.js`, you get Lottie. If you go Strategy B:

```bash
npm install lottie-web
```

```ts
import lottie from "lottie-web";
document.querySelectorAll<HTMLElement>('[data-animation-type="lottie"]').forEach((el) => {
  lottie.loadAnimation({
    container: el,
    renderer: el.dataset.renderer as any || "svg",
    loop: el.dataset.loop === "1",
    autoplay: el.dataset.autoplay === "1",
    path: el.dataset.src,
  });
});
```

## Form integration

Webflow forms typically POST to `/api/forms/submit-form` on the Webflow backend. The replica needs an alternative:

- **HubSpot embed** if you have a HubSpot account — see `references/forms.md`
- **Astro endpoint** that emails via Resend / Postmark / SendGrid
- **Netlify Forms** if deploying to Netlify
- **Formspree** for a hosted receiver

Update the `action` attribute on every `<form>` to point at your chosen receiver.

## Image hosting

Webflow images are served from `uploads-ssl.webflow.com` (or `assets.website-files.com`). For a clean replica, download each image to your `public/` folder and rewrite `src` URLs. Or proxy via Cloudflare R2 / Images for production.

## Anti-patterns

- Don't strip the initial-state `<style>` block — it's the only thing preventing FOUC
- Don't try to deminify `webflow.js` and "improve" it — it's a 30KB minified IX2 runtime; not worth the rewrite
- Don't replace `data-w-id` values with semantic names — IX2 expects the 24-char hex IDs
- Don't load `webflow.js` from CDN in your replica — production CDN may break, refuse cross-origin, or update unexpectedly. Self-host.
- Don't add Tailwind classes alongside Webflow classes — they fight. Pick one CSS system.
