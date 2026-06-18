# Accessibility parity

A pixel-faithful replica that ships worse accessibility than the original isn't actually faithful. This phase ensures the port preserves (or improves) every a11y signal the production site provides — and adds the ones that disappeared during chrome stripping.

## The audit checklist

Run after every major chunk of porting work.

### 1. Landmark structure

The production HTML has semantic landmarks. The port often replaces them with `<div>` during chrome rewriting.

```bash
# What landmarks does the production HTML use?
grep -oE '<(header|nav|main|aside|footer|section)[^>]*\b(role|aria-label)' "$work/html/<homepage>" | sort -u

# Does the replica preserve them?
curl -s http://localhost:4180/ | grep -oE '<(header|nav|main|aside|footer)[^>]*'
```

**Fix:** every chrome component (BaseLayout, Header, Footer) renders the correct landmark element. `<Header>` should emit `<header role="banner">`, `<Footer>` should emit `<footer role="contentinfo">`, the Barba container should remain `<main>`.

### 2. Sentinel divs need `aria-hidden`

The skill's `pageType` pattern emits empty `<div id="page_xxx">` divs as JS gating hooks. Screen readers shouldn't announce them.

```astro
{pageType === "services" && <div id="page_services" aria-hidden="true" />}
{pageType === "service-detail" && (<>
  <div id="textable_page" aria-hidden="true" />
  <div id="service_s_page" aria-hidden="true" />
</>)}
```

### 3. Preloader / loading-container / transition-container

These are presentational overlays. Must be `aria-hidden` and not focusable.

```astro
<div
  class="loading-container ..."
  aria-hidden="true"
></div>

<div
  class="transition-container ..."
  aria-hidden="true"
></div>
```

### 4. Mobile menu drawer focus management

When the burger opens the drawer, focus should move INTO the drawer. When it closes, focus should return to the burger.

```ts
function openDrawer() {
  burger.classList.add("menu-opened");
  const firstLink = drawer.querySelector("a, button");
  firstLink?.focus();
  drawer.setAttribute("aria-modal", "true");
  drawer.removeAttribute("aria-hidden");
  document.body.style.overflow = "hidden";
}

function closeDrawer() {
  burger.classList.remove("menu-opened");
  burger.focus();
  drawer.setAttribute("aria-hidden", "true");
  drawer.removeAttribute("aria-modal");
  document.body.style.overflow = "";
}
```

Trap Tab inside the drawer while it's open (standard focus-trap pattern: cycle Tab between first + last focusable).

### 5. Decorative SVGs need `aria-hidden`

Inline SVGs that are purely decorative (logos, ornaments, arrow glyphs) need `aria-hidden="true"`. SVGs that are content (a brand mark that IS the page title) need `<title>` inside.

```astro
<svg aria-hidden="true" focusable="false" ...>...</svg>

<svg role="img" aria-labelledby="brand-title" ...>
  <title id="brand-title">Atoll Digital</title>
  ...
</svg>
```

### 6. Skip-to-content link

Production sites often skip this. Add it anyway — costs nothing, helps keyboard users:

```astro
<a
  href="#main"
  class="sr-only focus:not-sr-only focus:absolute focus:top-0 focus:left-0 focus:bg-primary focus:text-bg focus:p-4 focus:z-[200]"
>
  Skip to main content
</a>
```

And make sure `<main>` (the Barba container) has `id="main"` or `tabindex="-1"`.

### 7. Reduced-motion respect

Every GSAP timeline, every parallax scroll, every WebGL scene should bail when `prefers-reduced-motion: reduce`. Audit every `gsap.to`, `gsap.from`, `gsap.timeline`, `ScrollTrigger.create`:

```ts
const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

if (reduced) {
  // Skip the animation. Set the final state instantly:
  gsap.set(target, { autoAlpha: 1, y: 0 });
  return;
}

const tl = gsap.timeline();
tl.fromTo(target, /* ... */);
```

Or use GSAP's `gsap.matchMedia()` API to scope reduced-motion + breakpoint variants together.

For the WebGL home scene specifically:

```ts
export function initHomeWebGL(): Promise<void> {
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) {
    // Display a static fallback image instead of rendering the scene
    document.querySelector("canvas.webgl3d")?.replaceWith(/* static <img> */);
    return Promise.resolve();
  }
  /* ... real init ... */
}
```

### 8. Color contrast

Run an automated contrast check on the replica before declaring done:

```bash
# Use axe-core via Playwright, or pa11y CLI:
npx pa11y http://localhost:4180/ --standard WCAG2AA --reporter cli
```

Common contrast failures:
- Light grey body text on off-white background (e.g. `#72767E` on `#F0F1F4` — passes AA at large size, fails at small)
- Placeholder text in forms
- Disabled / `atoll_current` states (the skill greys these on purpose; verify they still meet 3:1 for non-text contrast)

### 9. Form labels + error messaging

If the contact form is HubSpot embedded, HubSpot's defaults are usually decent. Inspect the rendered form for:

- Every input has a `<label for>` or `aria-label`
- Error messages use `aria-live="polite"` and `role="alert"`
- Required fields are marked with `aria-required="true"` AND a visible `*`

### 10. Keyboard navigation through page transitions

After Barba transitions, focus needs to land somewhere sensible. Without intervention, focus stays where it was on the previous page (which no longer exists), so the user is stranded.

```ts
barba.hooks.afterEnter(() => {
  // Move focus to the new page's main heading
  const h1 = document.querySelector<HTMLElement>("main h1");
  if (h1) {
    h1.setAttribute("tabindex", "-1");
    h1.focus({ preventScroll: true });
  }
});
```

## Tooling

- **Playwright + axe-core** for automated audits per route. Add to the audit-loop agent:
  ```ts
  const { violations } = await page.evaluate(async () => {
    const axe = (window as any).axe;
    return axe.run();
  });
  ```
- **pa11y CLI** for quick command-line checks during dev
- **Browser DevTools → Lighthouse** for a human-reviewable summary
- **VoiceOver (Mac) / NVDA (Win)** for manual screen-reader pass on critical pages

## When to fail the audit

Block the "this is done" milestone if:
- Any page has <90% Lighthouse accessibility score
- Any focus trap is broken (drawer, modal, dropdown)
- WCAG 2 AA contrast failures on body text
- Reduced-motion preference is ignored on any heavy timeline
- Page transitions strand keyboard focus

## Anti-patterns

- Don't `aria-hidden` an entire region when only part of it is decorative
- Don't override the production site's `lang` attribute carelessly — `<html lang="en-US">` matters for screen-reader pronunciation
- Don't replace `<button>` with `<div onClick>` — common in design-led replicas, breaks keyboard activation
- Don't trust the production site's a11y; replicas frequently improve on it
