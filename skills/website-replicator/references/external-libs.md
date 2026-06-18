# Phase 9 — External libraries

The production site loads several scripts from CDNs that your bundle imports don't replace. Without staging them, specific features silently fail.

## The catalog

| Library | Used for | How to stage |
|---|---|---|
| **HubSpot Forms embed** | `#form_hubspot` div on contact pages | `<script async src="//js-na3.hsforms.net/forms/embed/v2.js">` in BaseLayout head |
| **SplitText (GSAP Club)** | `[data-splitting-lines-overflow]` line-mask reveals | Stage locally + `<script src="/gh/...">` + `gsap.registerPlugin(SplitText)` |
| **ImagesLoaded** | Awaiting media before triggering reveals | Often replaceable with `setTimeout` or `Image.decode()` |
| **Lottie (lottie-web)** | Animated SVG numerals on about pages | Usually NOT actually loaded by the production site — verify before adding |
| **reCAPTCHA** | CF7 form spam protection | Skip if using HubSpot (its captcha is internal) |
| **GTM / Microsoft Clarity** | Analytics | Skip; intentional |

## HubSpot Forms

**Symptom of missing it:** `/contact/` and `/fr/contact/` show an empty `<div id="form_hubspot" data-hs-portal="..." data-hs-form="...">`. Your `features/hubspot.ts` polls `window.hbspt` for 5 seconds then gives up.

**Fix:**

```html
<!-- BaseLayout head -->
<script is:inline async src="//js-na3.hsforms.net/forms/embed/v2.js"></script>
```

Your `features/hubspot.ts` then runs:

```ts
export function initHubspot(): void {
  const target = document.querySelector<HTMLElement>("#form_hubspot");
  if (!target || target.dataset.hsBound === "1") return;
  const portalId = target.getAttribute("data-hs-portal");
  const formId = target.getAttribute("data-hs-form");
  if (!portalId || !formId) return;

  let attempts = 0;
  const tryCreate = () => {
    if (window.hbspt?.forms?.create) {
      window.hbspt.forms.create({
        portalId,
        formId,
        target: "#form_hubspot",
      });
      target.dataset.hsBound = "1";
      return;
    }
    if (attempts++ > 50) return;
    setTimeout(tryCreate, 100);
  };
  tryCreate();
}
```

## SplitText

**Symptom of missing it:** Every `[data-splitting-lines-overflow]` and `[data-splitting]` heading appears with no line-by-line reveal. The text just snaps into place.

**Stage locally:**

```bash
mkdir -p public/gh/ilja-van-eck/osmo/assets/gsap
cp <work>/<target>_sourcemaps/assets/SplitText.min.js public/gh/ilja-van-eck/osmo/assets/gsap/SplitText.min.js
```

**Load in BaseLayout head:**

```html
<script is:inline src="/gh/ilja-van-eck/osmo/assets/gsap/SplitText.min.js"></script>
```

**Critical:** register with GSAP before instantiating. See `pitfalls.md` for the registerPlugin gotcha and the try/catch wrapping pattern.

**License gotcha:** SplitText is a **Club GSAP** plugin. Not installable from public npm. Three options:

1. **Stage from CDN as the Atoll site does** — works fine for replica work since the script is publicly fetchable from gh/ilja-van-eck/osmo (an unofficial mirror). Legal grey-zone for production.
2. **Pull from Club GSAP's private npm registry** if you have a Club membership. Your `.npmrc` needs the registry config.
3. **Ship a CSS-only fallback + extension point** — the cleanest pattern for OSS replicas. Stub `core/splitText.ts` to do the line-mask reveal with pure CSS (per-line spans) and expose a `registerSplitText(ctor)` function so the real plugin can be slotted in later:

```ts
let SplitTextCtor: any = null;
export function registerSplitText(ctor: any): void { SplitTextCtor = ctor; }

export function splitLines(target: Element): { lines: HTMLElement[] } {
  if (SplitTextCtor) return new SplitTextCtor(target, { type: "lines" });
  // CSS-only fallback: assume the source HTML already has <span class="line"> wrapping
  return { lines: Array.from(target.querySelectorAll(".line")) };
}
```

The Terminal Industries replica uses option 3 — the CSS achieves ~80% of the visual effect, and Club GSAP can drop in later via `registerSplitText(window.SplitText)`.

## Lottie (verify before adding)

Captured HTML often contains:

```html
<div class="item_lottie" data-url="/wp-content/themes/<theme>/assets/lottie/number1.json"></div>
```

But the production main.js may not actually load `lottie-web` — the static SVG numerals come from the surrounding CSS/SVG. Before adding lottie-web as a dep, grep main.js for `lottie.loadAnimation` or `bodymovin.loadAnimation`. If absent, the placeholders are dead markup; leave them.

If actually loaded:

```bash
npm install lottie-web
```

Then in a feature module:

```ts
import lottie from "lottie-web";

document.querySelectorAll<HTMLElement>(".item_lottie").forEach((el) => {
  if (el.dataset.lottieBound === "1") return;
  el.dataset.lottieBound = "1";
  const path = el.getAttribute("data-url");
  if (!path) return;
  lottie.loadAnimation({
    container: el,
    renderer: "svg",
    loop: true,
    autoplay: true,
    path,
  });
});
```

## ImagesLoaded

The original main.js may use `imagesLoaded()` to delay an animation until images decode:

```js
imagesLoaded(container, () => {
  ScrollTrigger.refresh();
  gsap.to(target, { /* ... */ });
});
```

Modern replacement using native APIs:

```ts
async function waitForImages(container: Element): Promise<void> {
  const imgs = Array.from(container.querySelectorAll("img"));
  await Promise.all(
    imgs.map((img) => {
      if (img.complete) return Promise.resolve();
      return img.decode().catch(() => undefined);
    }),
  );
}

// Usage
await waitForImages(container);
ScrollTrigger.refresh();
gsap.to(target, { /* ... */ });
```

Or skip entirely — if the reveal animation has a small delay (`>0.5s`), images usually have decoded by then.

## reCAPTCHA

The captured HTML often has:

```html
<script src="https://www.google.com/recaptcha/api.js?render=<SITE_KEY>"></script>
```

For CF7 forms. Since most replicas swap to HubSpot embeds (which have internal spam protection), reCAPTCHA can usually be skipped. If you keep CF7, also load the API and `window.grecaptcha`.

## Cookie banner

The production may load:

```html
<script src="/wp-content/plugins/complianz-gdpr-premium/cookiebanner/js/complianz.min.js"></script>
<link rel="stylesheet" href="/wp-content/plugins/complianz-gdpr-premium/assets/css/cookieblocker.min.css">
```

Replica strategies:
- **Skip entirely** — most preferable for a developer-study replica. Remove the cookie-banner mount + delete any Complianz HTML the body extraction included.
- **Load the CSS only** — banner markup renders correctly but no consent backend. Use the dataset.cmplzAccepted localStorage flag pattern.
- **Full Complianz port** — substantial; only do this if the replica is going to production in a jurisdiction with consent requirements.

The user usually wants the banner gone. Comply: remove the mount from BaseLayout.

## Order of loading

In BaseLayout head, load external scripts in this order:

1. Your `global.css` (Astro Vite emit) — first so Tailwind utilities are available
2. Production CSS (`<link>`) — adds custom state rules
3. Favicon
4. Inline language-code script (`window.getLangCode`)
5. SplitText
6. HubSpot embed (async)
7. Page-specific `<slot name="head" />`

Don't preload fonts unless the production site does. The `font-display: swap` declaration handles FOUT gracefully.

## Verifying

For each external library:

```js
// In browser console
window.hbspt?.forms?.create     // → function
window.SplitText                 // → constructor
gsap.plugins                     // → object containing SplitText
window.lottie                    // → object (only if Lottie loaded)
```

If any returns undefined when it shouldn't, the corresponding feature is silently failing.

## Anti-patterns

- Don't bundle SplitText into your Vite bundle — it's licensed Club GSAP, ship as a separate script
- Don't load reCAPTCHA for HubSpot forms — they don't use it
- Don't preload heavy scripts (`<link rel="preload">`); load async or defer
- Don't add `lottie-web` to deps if grep doesn't show it being used
