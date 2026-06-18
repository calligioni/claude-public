# Pitfalls catalog

Every entry here was observed in a real reverse-engineering session. None are theoretical. Consult this file whenever something silently fails — chances are the answer is here.

## Table of contents

- [Browser / Vite / Astro environment](#browser--vite--astro-environment)
- [GSAP plugin loading](#gsap-plugin-loading)
- [Hidden-element measurement](#hidden-element-measurement)
- [Astro JSX braces vs CSS braces](#astro-jsx-braces-vs-css-braces)
- [Per-page sentinel divs](#per-page-sentinel-divs)
- [Page-transition chrome](#page-transition-chrome)
- [Localhost dev-bypass guards](#localhost-dev-bypass-guards)
- [Three.js duplication](#threejs-duplication)
- [HubSpot vs Contact Form 7](#hubspot-vs-contact-form-7)
- [Tailwind v3 → v4 cascade ordering](#tailwind-v3--v4-cascade-ordering)
- [Internal URL rewriting](#internal-url-rewriting)
- [Cookie banner / Complianz noise](#cookie-banner--complianz-noise)
- [WPML language switcher empty spans](#wpml-language-switcher-empty-spans)
- [Module-scoped bound flags vs Barba re-init](#module-scoped-bound-flags-vs-barba-re-init)
- [Anonymous resize-listener leaks](#anonymous-resize-listener-leaks)
- [Wrong wordmark in footer](#wrong-wordmark-in-footer)

---

## Browser / Vite / Astro environment

### Stale Vite optimizeDeps cache

**Symptom:** the dev server runs for a few hours and starts returning `504 + empty Content-Type` for `/@id/astro/runtime/client/dev-toolbar/entrypoint.js`. Browser refuses to load it as a module ("disallowed MIME type"). The page stays blank.

**Cause:** Vite's optimized-deps cache went stale after many file changes.

**Fix:**
```bash
pkill -f "astro dev"
rm -rf node_modules/.astro node_modules/.vite .astro
npm run dev
```

### Astro dev-toolbar 504 (recurring)

**Symptom:** even after a cache clear, the dev-toolbar entrypoint sometimes returns 504.

**Fix:** disable the toolbar entirely in `astro.config.mjs`:

```js
export default defineConfig({
  devToolbar: { enabled: false },
  // …
});
```

It's a developer UI overlay only; zero impact on the actual site.

### Browser hard-refresh is not enough after big script changes

**Symptom:** user says "I refreshed and still see the old behaviour."

**Cause:** Service workers, in-memory cache. Tell the user `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Win). If that fails, DevTools → Network → "Disable cache" checkbox + reload.

---

## GSAP plugin loading

### `new SplitText()` throws → page renders white

**Symptom:** Console shows `Please gsap.registerPlugin(SplitText)`. Then everything after that point in the boot stops. Preloader never fades. Page is white.

**Cause:** GSAP is bundled from npm; SplitText is loaded as a global `window.SplitText`. GSAP doesn't auto-register globals.

**Fix:** In your splitText helper, register on first access:

```ts
let registered = false;
const getSplitText = () => {
  if (typeof window === "undefined") return null;
  const ctor = window.SplitText;
  if (!ctor) return null;
  if (!registered) {
    try { gsap.registerPlugin(ctor); registered = true; } catch { /* idempotent */ }
  }
  return ctor;
};
```

Also wrap every `new SplitText(target, opts)` in a try/catch so a future plugin failure can't take down the entire bundle.

### ScrollTrigger needs `gsap.registerPlugin(ScrollTrigger)` too

Less of a problem because most npm ScrollTrigger setups call this in their module body. But if you write a bespoke loader, do it explicitly.

---

## Hidden-element measurement

### `getBoundingClientRect().height` returns 0 for `display:none`

**Symptom:** A scroll-driven collapse animation animates the cards to height 0 instead of the title-band height. Cards appear to vanish entirely.

**Cause:** the original code used `parseInt($(target).css("height"))`, which returns the computed-but-not-used value (e.g., `"152px"`) even for `display:none` elements. Modern `getBoundingClientRect()` returns `0` for display:none. `getComputedStyle().height` returns `"auto"` in Chrome for explicit-height display:none elements.

**Fix:** use the jQuery-style swap technique:

```ts
function measureHidden(sel: string, dim: "height" | "width"): number {
  const el = document.querySelector<HTMLElement>(sel);
  if (!el) return 0;
  const rect = el.getBoundingClientRect();
  if (rect[dim] > 0) return rect[dim];
  const prev = {
    display: el.style.display,
    visibility: el.style.visibility,
    position: el.style.position,
    hidden: el.hidden,
  };
  el.hidden = false;
  el.style.display = "block";
  el.style.visibility = "hidden";
  el.style.position = "absolute";
  const measured = el.getBoundingClientRect()[dim];
  el.style.display = prev.display;
  el.style.visibility = prev.visibility;
  el.style.position = prev.position;
  el.hidden = prev.hidden;
  return measured;
}
```

Use this anywhere the original main.js does `$.css("height")` or `$.css("width")` on a `hidden` element. Common spots:
- `#sticky_top_height` (project-card collapse target)
- `#space_accord_process` (process tile compression width)
- `#gap_work_info` (work item spacing)

---

## Astro JSX braces vs CSS braces

### Body content with literal `{X}` triggers `ReferenceError: X is not defined`

**Symptom:** Build fails with `ReferenceError: SCROLL is not defined`. The captured HTML had `{ SCROLL }` as display text inside the page.

**Cause:** Astro parses `{...}` in markup as JSX expressions.

**Fix:** HTML-entity-escape literal braces in JSX text content:

```astro
<div>&#123;  SCROLL  &#125;</div>
```

**OR** use template-literal escape:

```astro
<div>{`{`} SCROLL {`}`}</div>
```

### Same escape inside `<style>` blocks BREAKS the CSS

**Symptom:** Build fails with `Invalid declaration: '.project_wrapper &#123'`.

**Cause:** Tailwind v4 / Vite parses the `<style>` block as CSS, but the agent's escaping pass turned `{`/`}` into `&#123;`/`&#125;` even inside style blocks. CSS doesn't decode HTML entities.

**Fix:** the entity escape applies ONLY to body content, never inside `<style>` or `<script>` blocks. Use a per-region porter, or sed back the entities inside `<style>` after a blanket escape:

```bash
find src/pages -name "*.astro" -print0 | xargs -0 sed -i '' '/<style/,/<\/style>/{ s/&#123;/{/g; s/&#125;/}/g; }'
```

### Better: use `<Fragment set:html={bodyHtml} />`

If the body content has lots of stray braces and inline styles, dump the raw HTML into a JS template literal and render via `set:html`:

```astro
---
const bodyHtml = `<div>...the raw HTML with {literals} and <style>.x { color: red }</style>...</div>`;
---
<SiteLayout pageType="article" ...>
  <Fragment set:html={bodyHtml} />
</SiteLayout>
```

Sidesteps the brace-escaping mess entirely.

---

## Per-page sentinel divs

### Every subpage has NO intro animation

**Symptom:** Homepage animates fine, but `/services/`, `/work/`, `/contact/`, etc. just appear instantly with no header bottom-line draw, no fade-in.

**Cause:** The original site has a per-page reveal timeline in `animationOnPageLoad()` that branches on `document.getElementById("page_xxx")`. Different page types use different IDs:
- `#page_home` — home
- `#page_services` — services index
- `#textable_page` + `#service_s_page` — service detail
- `#page_work` — work index
- `#page_project` — work detail / case study
- `#page_blog` — articles index + category + author
- `#textable_page` — article detail, contact, legal pages
- `#page_about` — creative-montreal-web-agency
- `#page_contact` — contact, thank-you
- `#page_error` — 404

The HTML porter agents typically strip these as "empty noise divs." Without them, the per-page branch falls through and no intro animation runs.

**Fix:** add a `pageType` prop to SiteLayout and emit the sentinel automatically. Pattern:

```astro
{pageType === "services" && <div id="page_services" />}
{pageType === "service-detail" && (<>
  <div id="textable_page" />
  <div id="service_s_page" />
</>)}
{pageType === "work" && <div id="page_work" />}
{/* etc */}
```

Then update every ported page to pass the right `pageType="..."`.

---

## Page-transition chrome

### Click-driven page transitions show no animation

**Symptom:** Clicking a nav link or the brand logo navigates immediately (no preloader sweep, no FLIP wordmark). Only refreshing the page shows the loader.

**Cause:** The `pageTransitionOut` function flies the `.logo-transition-name` SVG into `[data-target-heading]` via a FLIP measurement. If `.logo-transition-name` doesn't exist in the DOM, the FLIP fires into nothing.

**Fix:** mount the flying-logo container in BaseLayout (it lives outside the Barba container so it survives swaps):

```astro
<div class="transition-container fixed pointer-events-none inset-0 z-[100] px-[var(--size-20)] py-[var(--size-20)] lg:py-[2.013888888888889vw] h-screen one-height-screen opacity-0 overflow-hidden flex items-end">
  <div class="logo-transition-name w-full flex flex-nowrap items-end"></div>
</div>
```

Plus an inline seed script in BaseLayout that copies `.title_page` SVG into `.logo-transition-name` on DOMContentLoaded so the FIRST page-leave has something to fly:

```html
<script is:inline>
  (function () {
    function seed() {
      var title = document.querySelector(".title_page");
      var slot = document.querySelector(".logo-transition-name");
      if (title && slot && !slot.innerHTML.trim()) slot.innerHTML = title.innerHTML;
    }
    if (document.readyState === "loading")
      document.addEventListener("DOMContentLoaded", seed);
    else seed();
  })();
</script>
```

And ensure your Barba `leave` hook calls `initChangePageTitle(data.next.container)`:

```ts
function initChangePageTitle(container: HTMLElement): void {
  const nextTitle = container.querySelector(".title_page")?.innerHTML;
  if (nextTitle) {
    document.querySelectorAll(".logo-transition-name")
      .forEach((el) => (el.innerHTML = nextTitle));
  }
}
```

### Header is visible on hero on the home page

**Symptom:** User screenshot shows the desktop nav bar covering the hero on the home page. Should be hidden until scroll.

**Cause:** Missing CSS rule (often in line ~1300 of production CSS):

```css
body.home #header_sticky { position: fixed; transform: translateY(-102%); }
body.home #header_sticky.is_visible { transform: translateY(0); }
```

This rule hides the header off-screen on home until JS adds `.is_visible` on scroll past the WebGL section. If you're loading the production CSS via `<link>` you get it for free. If you're only extracting tokens, manually add it.

---

## Localhost dev-bypass guards

### Preloader animation never runs on `localhost`

**Symptom:** The page just appears with no preloader sweep / FLIP wordmark.

**Cause:** The original main.js has a guard like:

```js
if (window.location.host === "1atoll.loc:8888") {
  // skip preloader on dev box
  gsap.set(".loading-container", { autoAlpha: 0 });
}
```

When you port it, the guard sometimes gets broadened to `localhost`, `127.0.0.1`, etc. — which kills the preloader on your dev server too.

**Fix:** narrow the guard to the EXACT original dev host so it never fires on your dev server:

```ts
const isLocalhost = (): boolean => {
  if (typeof window === "undefined") return false;
  return window.location.host === "1atoll.loc:8888";
};
```

---

## Three.js duplication

### `Multiple instances of Three.js being imported`

**Cause:** the production scene bundle (e.g. `app-BQbjH4ce.js`) includes its own internal Three.js. Your distortion module imports `three` from npm separately. The bundle's three and the npm three coexist on the page.

**Outcome:** **cosmetic only**. Both scenes render correctly. The warning is just Three.js's own internal sanity check.

**Fix options if you want it gone:**
1. Extend the production bundle to expose `ShaderMaterial`, `PlaneGeometry`, `TextureLoader`, etc. on `window.*`, then rewrite distortion to consume `window.Three.*`.
2. OR rewrite the home scene against npm `three` and stop loading the production bundle.

Both are large changes. The warning is fine to ignore.

---

## HubSpot vs Contact Form 7

### Contact page form is a blank box

**Symptom:** /contact renders but the form area shows nothing.

**Cause:** The user assumed the original used Contact Form 7 (WordPress's default). The captured HTML actually uses a **HubSpot embed**:

```html
<div id="form_hubspot" data-hs-portal="..." data-hs-form="...""></div>
```

Without `//js-na3.hsforms.net/forms/embed/v2.js` loaded, `window.hbspt` is undefined; your `features/hubspot.ts` polls for 5 seconds and gives up.

**Fix:** load HubSpot's embed script in BaseLayout head:

```html
<script is:inline async src="//js-na3.hsforms.net/forms/embed/v2.js"></script>
```

`features/hubspot.ts` then calls `hbspt.forms.create({ portalId, formId, target: "#form_hubspot" })`.

---

## Tailwind v3 → v4 cascade ordering

### Original CSS overrides Tailwind utilities unexpectedly

**Cause:** When you load the production CSS via `<link>` AND Tailwind v4 emits its own utilities, both define `.bg-bg`, `.text-primary`, etc. The later-loaded one wins.

**Strategy:** load Tailwind v4 first (it's processed by Vite), then the production CSS via `<link rel="stylesheet">` after — original's specific state rules (`body.home #header_sticky`, `.menu_header li a .label_wrap span:before` data-URI arrows) win, but Tailwind's utility output stays consistent for new utilities you introduce.

In BaseLayout head:
1. `<style>` from `global.css` (Tailwind v4 + your tokens) → emitted by Astro's Vite pipeline
2. `<link href="/wp-content/themes/atoll/dist/app-CHx12itT.css">` → ships after

If the order is reversed, the original's `.bg-bg` (Tailwind v3 syntax with `--tw-bg-opacity`) overrides Tailwind v4's emit, which is fine — both resolve to the same color.

---

## Internal URL rewriting

### Clicking a nav link goes to the live production site

**Symptom:** Clicking "Services" navigates to `https://atolldigital.com/services/` instead of `/services/`.

**Cause:** captured HTML uses absolute URLs. Without rewriting, your replica's nav points at the live site.

**Fix:** rewrite during the body extraction pass:

```bash
perl -i -pe 's{https://atolldigital\.com/}{/}g' src/components/Header.astro src/components/Footer.astro src/components/sections/home/*.astro
```

Leave references in legal-page body content alone — `https://atolldigital.com` appearing in the privacy policy as text is correct.

---

## Cookie banner / Complianz noise

### Unstyled "Manage Consent" text floats at top-left of every page

**Cause:** the production CSS doesn't include the Complianz cookie-banner styles by default — they're inside a separate `cookieblocker.min.css` from the WP plugin. You've ported the HTML but not loaded the CSS.

**Fix options:**
- Load `cookieblocker.min.css` from the staged plugin path AND load the Complianz JS.
- OR delete the banner HTML entirely from BaseLayout. Users often want this for non-production replicas.

The banner is rarely a blocker for replica work — delete unless the user explicitly needs it.

---

## WPML language switcher empty spans

### FR/EN language toggle in top-right is invisible

**Cause:** the captured HTML has empty `<span class="lang-ls"></span>` placeholders that the original WPML widget populates with the OTHER language's 2-letter code at runtime.

**Fix:** an inline script in Header.astro that reads `document.documentElement.lang` and writes "FR" or "EN" into every `.lang-ls`:

```html
<script is:inline>
  (function () {
    function fill() {
      var html = document.documentElement.lang || "en";
      var isFr = /^fr/i.test(html);
      var other = isFr ? "EN" : "FR";
      document.querySelectorAll(".lang-ls").forEach(function (s) {
        if (!s.textContent.trim()) s.textContent = other;
      });
      document.querySelectorAll("a.lang-switcher").forEach(function (a) {
        if (!a.getAttribute("href") || a.getAttribute("href") === "#!") {
          a.setAttribute("href", isFr ? "/" : "/fr/");
        }
      });
    }
    if (document.readyState === "loading")
      document.addEventListener("DOMContentLoaded", fill);
    else fill();
  })();
</script>
```

---

## Module-scoped bound flags vs Barba re-init

### After one page transition, burger menu / sticky header stop working

**Cause:** the original modular code uses `let bound = false; if (bound) return; bound = true;` to ensure one-time binding. But when Barba swaps to a new page, the DOM elements that the listener targeted are GONE, and the new container's burger element is fresh and unbound — but the module-scope `bound = true` flag is still set, so the binder skips.

**Fix:** tag the DOM element instead of the module:

```ts
function bindBurgerMenu(): void {
  const burger = document.querySelector<HTMLElement>(".burger-toggle");
  if (!burger || burger.dataset.navBound === "1") return;
  burger.dataset.navBound = "1";
  burger.addEventListener("click", /* ... */);
}
```

When Barba swaps containers, the new burger element has no `dataset.navBound`, so it gets bound fresh. The old element is garbage-collected with the old container.

---

## Anonymous resize-listener leaks

### Animation jank or doubled tweens after several page transitions

**Cause:** `window.addEventListener("resize", () => { ... })` inside an init function. Every Barba navigation calls the init function again, attaching a new anonymous listener. The OLD listener is still attached because you can't `removeEventListener` an anonymous function.

**Fix:** named function + module-scope reference:

```ts
let resizeFn: (() => void) | null = null;

function bindLoader(): void {
  const onResize = (): void => { /* … */ };
  if (resizeFn) window.removeEventListener("resize", resizeFn);
  resizeFn = onResize;
  window.addEventListener("resize", resizeFn, { passive: true });
}
```

Audit every `addEventListener("resize"` and `addEventListener("scroll"` for this pattern.

---

## Wrong wordmark in footer

### Footer brand SVG is truncated to first 3 glyphs ("ato")

**Cause:** the shared `<Logo />` component renders 3 small header-sized glyphs sized for an 86px column. At footer width (full column), the compact viewBoxes don't scale — only the first ~3 glyphs fit.

**Fix:** the footer uses a DIFFERENT single SVG — a full-bleed `1397×584` viewBox with the full word "atoll" as 5 paths. Extract from the captured HTML (`<footer>` area, look for the largest SVG) and inline directly in `Footer.astro` instead of using the shared component.

The same pattern applies to other "wordmark vs logotype" splits: headers use compact spaced glyphs, footers use a single big SVG.

---

## Two burger-toggle elements; only one was bound

**Symptom:** Burger opens drawer on first click. Second click does nothing.

**Cause:** The page typically renders TWO `.burger-toggle` elements — one fixed in the header (visible when drawer closed), one inside the `#menu-mobile` drawer (only reachable when drawer open). `document.querySelector(".burger-toggle")` returns only the first; the drawer's burger has no listener.

**Fix:** `querySelectorAll`, bind each, and toggle the `.menu-opened` class on ALL burgers in lockstep so the open/close state is consistent regardless of which one the user clicks:

```ts
const burgers = document.querySelectorAll<HTMLElement>(".burger-toggle");
burgers.forEach((burger) => {
  burger.addEventListener("click", () => {
    burgers.forEach((b) => b.classList.toggle("menu-opened"));
    if (burger.classList.contains("menu-opened")) { /* open animation */ }
    else { /* close animation */ }
  });
});
```

## Active-page link not greyed in mobile drawer

**Symptom:** User on `/services/` opens the mobile drawer; "services" link looks identical to others. Should be greyed to signal "you're already here."

**Cause:** Production CSS ships `.mobile_menu a.atoll_current { color: rgb(114, 118, 126) }` for the cue, but the drawer component doesn't know which page is current.

**Fix:** Pass `currentPath` as a prop to the drawer component, compare against each link's `href`, apply `atoll_current` class on match:

```astro
---
type Props = { currentPath?: string };
const { currentPath = "/" } = Astro.props;
function isActive(href: string): boolean {
  const norm = href.endsWith("/") ? href : `${href}/`;
  const cur = currentPath.endsWith("/") ? currentPath : `${currentPath}/`;
  return cur === norm;
}
---
<a
  href="/services/"
  class:list={["...", isActive("/services/") && "atoll_current"]}
>Services</a>
```

Plumb `currentPath` through SiteLayout → MobileMenu so every non-home page passes it. Apply the same pattern to Header and Footer if those components have active-state styling.

## Body line-height stack mismatch makes everything read compressed

**Symptom:** Headings + nav items look visibly smaller / more compressed than the original side-by-side, even though all `text-[Xpx]` classes are identical.

**Cause:** Production typically declares the body as:
```css
body { font-size: var(--18px); }
body { -webkit-font-smoothing: antialiased; color: var(--primary); font-weight: 400; }
body { margin: 0; line-height: inherit; }  /* preflight */
```
which means `line-height` inherits from `html` (Tailwind preflight default `1.5`). At `text-[44px]`, line-box is 66px.

If you set `body { line-height: 1.4 }` in your tokens.css, you compute 61.6px per line. Multiplied across 6 menu rows that's ~30px of cumulative compression.

**Fix:** Match production body verbatim:

```css
body {
  margin: 0;
  font-size: var(--18px);
  line-height: inherit;     /* let html's 1.5 cascade */
  color: var(--primary);
  font-weight: 400;
  -webkit-font-smoothing: antialiased;
}
```

This applies broadly — any place you set body typography without checking the production cascade will accumulate per-line drift.

## Nuxt sitemap returns JSON 404 (not XML)

**Symptom:** `discover.sh` runs, reports 0 page URLs, and the entire pipeline downstream stalls silently. No HTML captured, no assets fetched.

**Cause:** Nuxt sites without `@nuxtjs/sitemap` configured return a JSON error body (`{"statusCode":404,"statusMessage":"Page not found"...}`) at `/sitemap.xml` instead of HTTP 404. `discover.sh` saved the response body as `sitemap.xml`, grep'd it for `<loc>`, and found zero hits.

**Fix:** v0.5+ `discover.sh` validates the response IS XML before using it (`grep -qE '<\?xml|<urlset'`). If not, falls back to fetching the homepage and extracting every same-origin `<a href>` to seed page_urls.txt. Manual workaround if running the older script:

```bash
curl -sL "$target" | perl -ne '
  while (/<a[^>]+href="([^"]+)"/g) {
    print "$target$1\n" if $1 =~ m{^/};
  }
' | sort -u > "$work/page_urls.txt"
```

## 403-SPA-fallback masquerading as captured source maps

**Symptom:** `discover.sh` reports "8 source maps recovered" — but `recovered_sources/` is empty and `maps/*.js.map` files all start with `<!DOCTYPE html>`.

**Cause:** When a `.map` URL doesn't exist, CDNs (CloudFront, Cloudflare, Vercel) commonly return the SPA index.html instead of a 404 (because they route unknown paths to the SPA shell). The original `discover.sh` saved every 200-response body to `maps/` regardless of content type.

**Fix:** v0.5+ `discover.sh` validates each saved map with `python3 -c "import json; json.load(open(sys.argv[1]))"` and only counts it as VALID if JSON parses. Failed validations are logged to `agent-notes/map-probe-results.tsv` as `INVALID_JSON` or `NOT_JSON`. Distinct from `404` and `403_LOCKED` outcomes.

## Vue scoped-style `data-v-*` attributes flood the motion-hook inventory

**Symptom:** `inventory-motion-hooks.sh` returns thousands of `data-v-c018db0d` style attributes at the top of the frequency list, drowning out actual motion hooks.

**Cause:** Vue SFC's `<style scoped>` blocks emit `data-v-<hash>` attributes on every element in the component. They are NOT motion hooks; they're CSS-scope tags. On a heavy Nuxt site, every element has one or more.

**Fix:** v0.5+ `inventory-motion-hooks.sh` filters out attributes matching `data-v-[0-9a-f]{6,}` by default. Pass `--include-spa-noise` to see them. Manual workaround for the older script:

```bash
grep -hoE 'data-[a-z][a-z0-9-]*=' "$work/html"/*.html* \
  | sed -E 's/=$//' | sort | uniq -c | sort -rn \
  | grep -vE 'data-v-[0-9a-f]{6,}$' \
  | head -40
```

## ScrollSmoother + Lenis on the same page

**Symptom:** Smooth scroll feels janky / fighting itself. Inertia conflicts, scroll position glitches on resize, ScrollTrigger refresh produces flickers.

**Cause:** GSAP's `ScrollSmoother` and `Lenis` both intercept the native scroll and re-render via their own RAF loops. Running both at once means two competing scroll positions per frame.

**Fix:** Pick one. Common pattern in production sites (observed on nvg8.io): instantiate Lenis as the source of truth, then **call `ScrollSmoother.kill()` early** to remove GSAP's smoother. Or vice-versa — instantiate Smoother and don't initialize Lenis. Document the choice in your `core/scroll.ts` doc comment.

## Webflow's pre-JS initial-state `<style>` block is load-bearing

**Symptom:** Page flashes its FINAL animated state for a few frames before IX2 hydrates and runs the intro animation. Looks broken.

**Cause:** Webflow's exported HTML includes a multi-kilobyte `<style>` block in `<head>` declaring initial transforms / opacities for every `data-w-id` element across 4 media-query breakpoints. It's gated on `html.w-mod-js:not(.w-mod-ix)` — runs before Webflow's IX2 JS finishes binding. If you strip this style block thinking it's noise, FOUC.

**Fix:** Preserve verbatim in BaseLayout `<head>`. Same gate selector. Don't refactor.

## Known-403 CDN hosts (short-circuit map probing)

**Symptom:** `discover.sh` spends 30+ seconds probing `.map` URLs that all return 403.

**Cause:** Some CDNs unconditionally lock source maps — they exist on origin but never serve to the public:

| Host | Behavior |
|---|---|
| `cdn.prod.website-files.com` (Webflow) | 403 on every `.map` |
| `framerusercontent.com` (Framer) | 403 |
| `cdn.shopify.com` | 403 |
| `static.squarespace.com` | 403 |
| `static.wixstatic.com` | 403 |

**Optimization:** if you detect any of these as the CDN serving production assets, skip the map probe entirely and write a verdict of `EMPTY: known-403 CDN`. Save the 30 seconds for other recovery techniques.

## Webflow's `w-mod-js` inline script must stay inline

**Symptom:** Webflow-strategy-A replica has FOUC: page renders unstyled (or jumpy) for ~200ms before animations kick in. Initial-state declarations from the production CSS are completely ignored.

**Cause:** Webflow's exported `<head>` includes an inline `<script>` that stamps `w-mod-js` onto `<html>`. The initial-state CSS is gated on `html.w-mod-js:not(.w-mod-ix) [data-w-id=...]`. Without the stamp, those selectors never match.

**Fix:** preserve the stamp inline + ensure `<html>` ships with `class="w-mod-no-js"` initially. See `references/webflow-target.md` for the exact snippet. Use `<script is:inline>` (NOT module / NOT deferred).

## Webflow ships multiple JS chunks, not just webflow.js

**Symptom:** Some sections animate correctly, others stay frozen at their initial state.

**Cause:** Modern Webflow uses code-splitting — the live page loads jQuery, then 2-3 `schunk.<HASH>.js` files, then `webflow.<HASH>.js`. If you only ship `webflow.js`, the IX2 timelines defined in the schunks never bind. Each missing chunk silently disables one section group.

**Fix:** capture the homepage `<head>` and stage EVERY `<script src>` reference (drop query strings; vendor as `public/js/<name>.js`). Load in the original order. See `references/webflow-target.md`.

## Astro JSX parses literal `{...}` in body content

**Symptom:** Build fails with `ReferenceError: X is not defined` when porting body content that has placeholder text like `{Service}` or `{Date}` or math like `{x + y}`.

**Cause:** Astro's `.astro` files are JSX-flavored; `{expr}` evaluates `expr` as JS at build time.

**Fix:** capture body HTML as a JSON string and render via `<Fragment set:html={...}>`:

```ts
// src/content/home.json
{ "body": "<div>{literal braces} survive here</div>" }
```

```astro
---
import content from "@/content/home.json";
---
<Fragment set:html={content.body} />
```

`set:html` is opaque to Astro's parser — no escape needed. Same fix works for body content containing inline `<style>` blocks with CSS braces (the other half of the brace-escape pitfall).

## scaffold.mjs import was missing dirname

**Symptom:** Running `scripts/scaffold.mjs` crashed with `ReferenceError: dirname is not defined` immediately on first execution.

**Cause:** The import line `import { mkdir, writeFile, access } from "node:fs/promises"; import { join, resolve } from "node:path"` omitted `dirname`. The body uses `dirname(full)` inside the write loop.

**Fix:** ensure scaffold.mjs imports `dirname` from `node:path`. Already corrected in v0.6+; previous versions of the script need a one-line patch.

## Nuxt `_payload.json` is flat-array with back-refs, not nested JSON

**Symptom:** Naive recursive `JSON.parse(...)` walk of a Nuxt payload blows the stack or returns garbage. The structure looks like nested objects but contains integer values that ARE NOT counts — they're indices into the top-level array.

**Cause:** Nuxt's payload serializer dedupes shared objects via integer back-refs. `{"title": 8}` doesn't mean "title equals 8"; it means "title is the value at index 8 of the data array." And boolean props (`true` → 1, `false` → 0) also LOOK like back-refs to a naive walker.

**Fix:** shallow-deref + visited-set walker. Only deref an integer if the target index points at an object/array AND the integer is within bounds. See `references/nuxt-target.md` for the exact `derefPayload()` implementation. Saves an enormous amount of time on Storyblok/Sanity/Contentful Nuxt sites — the resolved payload gives you the complete section sequence + all CMS-driven content.

## scaffold.mjs errors when stage-assets.mjs has no manifest

**Symptom:** Right after running `scripts/scaffold.mjs`, the generated `scripts/stage-assets.mjs` errors with "Manifest not found" on its first run.

**Cause:** scaffold.mjs writes a stage-assets.mjs that expects `../<host>_sourcemaps/static_assets_manifest.tsv` to exist. If the target wasn't first put through discover.sh (or the discovery didn't produce a manifest because the site has no `<img>`/`<source>` assets), the stage step fails noisily.

**Fix:** the v0.7+ stage-assets.mjs gracefully no-ops with a friendly message when the manifest is missing. For older versions, run discover.sh BEFORE scaffold.mjs's stage step, or stub-create an empty manifest.

## Non-standard Nuxt font paths (/static/fonts/)

**Symptom:** Font-discovery script returns zero results, but the rendered site clearly uses custom fonts.

**Cause:** Nuxt sites sometimes alias `~/assets/fonts` to `/static/fonts/` in `nuxt.config.ts`, bypassing the default `/_nuxt/` build path. The skill's default discovery looks for fonts under `/_nuxt/` and misses them.

**Fix:** also grep the captured HTML for `@font-face` blocks (inline `<style>` or production CSS) — the `src: url(...)` paths tell you exactly where the fonts live, regardless of build convention. Then fetch those URLs directly.

## Astro <ClientRouter /> beats Barba for Nuxt-flavored replicas

**Symptom:** The skill defaults to Barba for page transitions (correct for the Atoll/WordPress target). For Nuxt-flavored ports, Barba adds runtime + complexity without benefit.

**Fix:** use Astro's native `<ClientRouter />` (view-transitions API). It uses the browser's native API where supported, falls back cleanly, and gets per-page hooks via the `astro:after-swap` event (which maps to Barba's `afterEnter`). The Terminal Industries replica uses this exclusively. See `references/nuxt-target.md`.

## Rive state-machine names are not "State Machine 1"

**Symptom:** `new Rive({ src: "/foo.riv", stateMachines: "State Machine 1" })` constructs but no animation plays. The canvas mounts but stays empty.

**Cause:** Real-world `.riv` files don't use Rive's default state-machine name. The designer picked something specific (e.g. "Scrolling", "Footer Arrow Scroll", "Hover Idle"). Passing the wrong name silently no-ops.

**Fix:** discover the names via `strings(1)`:

```bash
strings /tmp/work/static_assets/hero.riv | grep -iE 'scroll|machine|state|hover|idle' | head -10
```

Or use Rive's auto-detection (v2+):

```ts
import { Rive } from "@rive-app/canvas";
const r = new Rive({
  src: "/rive/hero.riv",
  canvas: document.querySelector("canvas[data-rive-hero]"),
  autoplay: true,
  onLoad: () => {
    // Pick the first state machine the file actually has
    const names = r.stateMachineNames;
    if (names.length) r.play(names[0]);
  },
});
```

## @rive-app/canvas WASM points at unpkg by default

**Symptom:** Rive works in dev (unpkg accessible), but fails on Cloudflare Pages with a CSP violation: `Refused to load script from https://unpkg.com/...`.

**Cause:** `@rive-app/canvas` ships with its WASM URL pointed at `https://unpkg.com/@rive-app/canvas@<VER>/rive.wasm`. CSP-strict deploys reject it.

**Fix:** self-host the WASM and tell Rive about it before any construction:

```ts
import { Rive, RuntimeLoader } from "@rive-app/canvas";
RuntimeLoader.setWasmUrl("/rive/rive.wasm");

// Copy the WASM into public/rive/ at scaffold time:
// node -e "import('@rive-app/canvas/rive.wasm', { with: { type: 'json' } })"
// Or via wget from unpkg into public/rive/rive.wasm
```

Then your CSP doesn't need to allow `https://unpkg.com`. See `references/cloudflare-pages.md` for the full CSP header pattern.

## `__name:` component inventory is a SUPERSET of rendered components

**Symptom:** `inventory-components.sh` returns 60 Vue components, but the home page only shows 30 of them. Half are unused on the home route.

**Cause:** Vue/Nuxt bundles include EVERY component the app could render — including admin tools (TweakPane), route-specific stuff (VueDatePicker for a date-picker page), prerelease/dev components, and shared widgets that only appear on specific routes.

**Fix:** cross-reference the inventory against the **captured rendered HTML** to find the actually-rendered subset before porting:

```bash
# Get the inventory
scripts/inventory-components.sh /tmp/work/assets > /tmp/components-all.txt

# Find which appear in the captured home HTML (rough match by name)
while read comp; do
  if grep -q "$comp" /tmp/work/html/*home*; then
    echo "USED: $comp"
  else
    echo "UNUSED: $comp"
  fi
done < /tmp/components-all.txt | grep ^USED
```

Port the USED set for the home route. Defer UNUSED until you tackle the route that needs them.

## Nuxt `_payload.json` is empty on pure-prerendered sites

**Symptom:** Site is Nuxt 3 with `_payload.json` per route, but the payload contains essentially nothing — `[{"data":1,"prerenderedAt":3},["ShallowReactive",2],{},...]` — no CMS content.

**Cause:** Nuxt's `payloadExtraction: true` only stores content that comes from async data calls (`useFetch`, `useAsyncData`). If the site is static-content (everything baked into Vue templates), there's nothing to extract — the payload is just runtime metadata.

**Fix:** detect this early. If the home page's `_payload.json` is <2KB or contains no string content, fall back to HTML scraping for the actual copy. The `__name:` component graph is still useful (it tells you the structure), but you'll need to extract section copy from the captured HTML, not the payload.

## ScrollTrigger inventory script is missing — write your own per-target

**Symptom:** You're porting a GSAP-heavy site and the original main.js has 20+ ScrollTrigger configs. Manually grepping `scrollTrigger:{` is tedious.

**Fix:** v0.8+ ships `scripts/inventory-scrolltrigger.sh` that extracts: unique trigger selectors, start/end anchor frequencies, scrub configs, pin configs, callback names. Output gives you a complete map of the original's motion choreography in one command.

```bash
./scripts/inventory-scrolltrigger.sh /tmp/work/recovered_readable
```

## Playwright motion probe — verify the system actually boots

**Symptom:** You think the replica's motion works, but you've only checked `npm run build` clean. The site boots silently broken — GSAP loaded but registered zero ScrollTriggers, or Lenis loaded but `.lenis` class never stamped on `<html>`.

**Fix:** v0.8+ ships `scripts/probe-motion.mjs` — a Playwright probe that visits the dev URL and verifies the motion system actually initialized. Reports: `ScrollTrigger.getAll().length`, Lenis presence, SplitText presence, Rive canvas count, console errors, failed network requests.

```bash
npm install -D @playwright/test
npx playwright install chromium
node scripts/probe-motion.mjs http://localhost:4180/
```

Exits non-zero if motion is broken — wire into your audit loop.

## When you observe a NEW pitfall

Add it here. Use the same format:
- **Symptom** (user-observable)
- **Cause** (one-sentence root cause)
- **Fix** (concrete code or steps)

Future replication sessions benefit from every gotcha captured.
