# Phase 3 — Design tokens & CSS strategy

The production CSS is your treasure map. It contains the design system AND every custom state rule the original site ships. Don't reinvent it — port it verbatim.

## The two-layer cascade strategy

A successful replica loads CSS in this order:

1. **Your `global.css`** (emitted via Astro's Vite pipeline)
   - Tailwind v4 utilities
   - `@theme` block with the brand's colors + fonts
   - `@import "tokens.css"` with `:root` design tokens + custom state CSS you've extracted

2. **The production CSS** (via `<link>` in BaseLayout head, AFTER step 1)
   - All custom state rules the original ships (`.menu_header li a span:before` arrow icons, `body.home #header_sticky` reveal, `.label_wrap` stack, etc.)
   - Original `@font-face` declarations
   - Original Tailwind v3 utility output (cascades on top of v4's, last-wins)

This gives byte-level CSS parity for thousands of custom rules without hand-extracting each one.

## Extract `:root` tokens

Find the production CSS's `:root` block. Typically late in the file (lines 3000-4000). Look for:

```css
:root {
  --primary: #091423;
  --bg: #F0F1F4;
  --px: 0.06944444444444445vw;          /* the magic fluid math */
  --size-20: 1.3888888888888888vw;
  --rounded-base: 0.3472222222222222vw;
  --header-sticky-height: 3.4722222222222223vw;
  /* GSAP-equivalent linear() easing catalog */
  --power3-in-out: linear(0, .0029 13.8%, /* ... */);
}

@media (max-width: 1023px) {
  :root {
    --px: 1px;
    --size-20: 15px;
    /* mobile snap to fixed pixels */
  }
}
```

The fluid math is load-bearing. `--px = 1/1440vw` means at exactly 1440 viewport, `--px === 1px` — every spacing value is `n × --px`. Above 1024px the design scales with viewport width; below, it snaps to fixed pixels. **DO NOT round any decimal.** `2.013888888888889vw` is intentional — it's `29/1440 × 100`.

Copy the `:root` blocks verbatim into `src/styles/tokens.css`.

## @font-face declarations

In the same production CSS, find `@font-face` blocks. Two strategies for staging the font files:

### Strategy A — Keep original hashed paths

If the production CSS references hashed filenames like `PPEditorialOldUltraLight.2e6cfcdbb6ce.woff2`, stage the font files at the original URL path (`/wp-content/themes/<theme>/dist/<file>`). The `@font-face` resolves naturally when the CSS loads.

```bash
# Copy each font with the exact filename the production CSS expects
DST=public/wp-content/themes/<theme>/dist
cp <src>/PPEditorialOldUltraLight.woff2.2e6cfcdbb6ce $DST/PPEditorialOldUltraLight.2e6cfcdbb6ce.woff2
# etc for every font file
```

### Strategy B — Re-declare in your tokens.css

If you don't want to depend on the production CSS (e.g. you're picking just the tokens), add `@font-face` declarations in your `tokens.css` with paths under `/assets/fonts/<family>/`.

```css
@font-face {
  font-family: "Lay Grotesk Trial";
  src: url("/assets/fonts/LayGroteskTrialRegular/LayGroteskTrialRegular.woff2") format("woff2"),
       url("/assets/fonts/LayGroteskTrialRegular/LayGroteskTrialRegular.otf") format("opentype");
  font-style: normal;
  font-display: swap;
  font-weight: 400;
}
```

Both strategies work. Strategy A is faster (no font duplication). Use Strategy B if the host repo will outlast the production reference.

## global.css with Tailwind v4 @theme

```css
@import "tailwindcss";
@import "./tokens.css";

@theme {
  --color-primary: #091423;
  --color-bg: #f0f1f4;

  --font-sans: "Lay Grotesk Trial", serif;
  --font-editorial: "PP Editorial Old", serif;

  --breakpoint-lg: 1024px;
}
```

After this, Tailwind utilities `bg-bg`, `text-primary`, `bg-primary`, `text-bg`, `font_editorial` resolve identically to the original Tailwind v3 output. The original CSS's class definitions (which use `--tw-bg-opacity` etc. from v3) cascade on top and don't conflict because they resolve to the same RGB.

## Load the production CSS via <link>

In BaseLayout.astro head, after your `global.css` import:

```astro
<link
  rel="stylesheet"
  href="/wp-content/themes/<theme>/dist/app-XXXXXXXX.css?ver=1.0.0"
  type="text/css"
  media="all"
/>
```

This loads the full original CSS bundle (typically 80-200KB) at its original URL path. With assets staged via `stage-assets.mjs`, the file is served from `public/`.

## Body baseline

Add explicit body typography in tokens.css to kill the browser's 16px default for unclassed text:

```css
body {
  font-family: "Lay Grotesk Trial", serif;
  font-size: var(--size-20);
  line-height: 1.4;
  color: var(--primary);
  background-color: var(--bg);
  -webkit-font-smoothing: antialiased;
}
```

This is a subtle drift accumulator if missing — most copy is classed and unaffected, but any stray paragraph reads slightly wrong.

## Extracting just the state CSS (alternative)

If you'd rather not load the entire production CSS, extract the custom (non-Tailwind) rules and inline them in `tokens.css`. The rules you need are typically:

- `body.home #header_sticky` reveal (line ~1290 in atoll's CSS)
- `.label_wrap` flex-stack (lines ~1156-1167)
- `.menu_header li a .label_wrap span:before/after` (data-URI arrow icons)
- `.project_wrapper` background colors
- `.top-header.btn` accordion variants
- All `[data-*]` motion-hook defaults (opacity:0, transform values)

This is laborious. Loading the production CSS via `<link>` is faster and more faithful.

## The "label_wrap stacking" example

This single rule explains the nav-doubling pitfall:

```css
.label_wrap {
  position: relative;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.label_wrap span:first-of-type {
  position: absolute;
}
```

The original site's nav links have two identical `<span>` children inside `.label_wrap`. Without this CSS, both spans render inline → "Services Services". With it, the first span is positioned absolutely on top of the second, so only the second is visible. The hover GSAP animation slides the first into view and the second out.

Without loading the production CSS, you'll miss this — and the nav will look broken. Hence the strong recommendation to load it via `<link>`.

## Verifying tokens

After staging:

```ts
// In browser console
getComputedStyle(document.documentElement).getPropertyValue('--bg').trim()   // → "#F0F1F4"
getComputedStyle(document.body).backgroundColor                              // → "rgb(240, 241, 244)"
getComputedStyle(document.querySelector('h1')).fontFamily                     // → "\"Lay Grotesk Trial\", serif"
```

If any of these return unexpected values, the cascade order is wrong or the import is broken.
