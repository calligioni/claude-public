# Phase 5 — JS modularization

The production site typically ships a single 2,000-line `main.js` (deminified) written in jQuery flavor. Your job: split it into a clean ES-module tree, replace jQuery with vanilla DOM, keep every GSAP API surface identical, wire to Barba's namespace dispatcher.

## Target structure

```
src/scripts/
├── index.ts                      # entry + per-namespace dispatcher
├── env.ts                        # isDesktop, isMobile, getLangCode, etc.
├── core/
│   ├── scroll.ts                 # Lenis singleton + start/stop/scrollTo
│   ├── transitions.ts            # Barba init + pageTransitionIn/Out
│   ├── splitText.ts              # SplitText global plugin wrapper
│   ├── loader.ts                 # initLoaderHome + initLoader (FLIP)
│   └── cursor.ts                 # cursor state (minimal usually)
└── features/
    ├── nav.ts                    # burger, sticky header, lang switcher, bottom-bar, menu_services smooth-scroll
    ├── forms.ts                  # CF7 multi-step (often dormant on HubSpot sites)
    ├── sliders.ts                # Swiper instances
    ├── ajax-pagination.ts        # blog load-more
    ├── home-webgl.ts             # Three.js home scene
    ├── distortion.ts             # WebGL image hover
    ├── hubspot.ts                # HubSpot form polling + create
    ├── page-anim.ts              # animationOnPageLoad + scrollTriggerAnimations
    ├── text-scramble.ts          # the "let's discuss your X next" effect
    └── accordion.ts              # FAQ accordions
```

## The entry point dispatcher

```ts
// src/scripts/index.ts
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

import { initCursor } from "./core/cursor";
import { initLoader, initLoaderHome } from "./core/loader";
import { initSmoothScroll } from "./core/scroll";
import { initSplitText, splittingLinesOverflow } from "./core/splitText";
import { initPageTransitions } from "./core/transitions";

import { initAccordion } from "./features/accordion";
import { initAjaxPagination } from "./features/ajax-pagination";
import { initDistortion } from "./features/distortion";
import { initForms } from "./features/forms";
import { ensureWebGLEffectGlobal } from "./features/home-webgl";
import { initHubspot } from "./features/hubspot";
import { initNav } from "./features/nav";
import {
  animationOnPageLoad,
  headingNameIndent,
  resizeVhHeight,
  scrollTriggerAnimations,
} from "./features/page-anim";
import { initSliders } from "./features/sliders";
import { initTextScramble } from "./features/text-scramble";

gsap.registerPlugin(ScrollTrigger);
gsap.config({ nullTargetWarn: false });

function dispatchByNamespace(): void {
  const container = document.querySelector<HTMLElement>("[data-barba-namespace]");
  const namespace = container?.getAttribute("data-barba-namespace") ?? "other";

  // Always: SplitText + core hover/scroll setups.
  initSplitText();
  headingNameIndent();
  scrollTriggerAnimations();
  splittingLinesOverflow();
  resizeVhHeight();

  // Always: shared features.
  initNav();
  initSliders();
  initForms();
  initAjaxPagination();
  initHubspot();
  ensureWebGLEffectGlobal();
  void initDistortion();
  initTextScramble();
  initAccordion();

  // Namespace-specific
  switch (namespace) {
    case "home": break;  // home WebGL boot happens inside initLoaderHome
    case "other":
    default: break;
  }
}

function boot(): void {
  initCursor();

  if (!document.querySelector('[data-barba="wrapper"]')) {
    // Direct-mount fallback for environments without Barba
    initSmoothScroll(document.body);
    dispatchByNamespace();
    initLoader(animationOnPageLoad);
    return;
  }

  initPageTransitions({
    onScriptInit: () => dispatchByNamespace(),
    onPageLoad: () => animationOnPageLoad(),
  });
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", boot, { once: true });
} else {
  boot();
}
```

## Vanilla DOM replacements for jQuery

| jQuery | Vanilla |
|---|---|
| `$(selector)` | `document.querySelectorAll(selector)` |
| `$(selector).first()` | `document.querySelector(selector)` |
| `$(el).on("click", fn)` | `el.addEventListener("click", fn)` |
| `$(el).find(child)` | `el.querySelectorAll(child)` |
| `$(window).width()` | `window.innerWidth` |
| `$(el).height()` | `el.getBoundingClientRect().height` |
| `$(el).css("height")` (on hidden) | `measureHidden(sel, "height")` — see pitfalls.md |
| `$(el).addClass("x")` | `el.classList.add("x")` |
| `$(el).hasClass("x")` | `el.classList.contains("x")` |
| `$(el).attr("data-x")` | `el.dataset.x` or `el.getAttribute("data-x")` |
| `$(el).html(s)` | `el.innerHTML = s` |
| `$(el).text(s)` | `el.textContent = s` |
| `$(this)` inside event handler | `event.currentTarget` or `event.target.closest(...)` |
| `$(el).slideDown(300)` | Custom — see accordion.ts pattern |

## Idempotency: tag the DOM element, not the module

Every feature module that binds listeners needs to be safe to call multiple times (Barba re-init). DO NOT use module-scoped `let bound = false; if (bound) return;` flags — they break on Barba transition because the new container's elements are fresh and unbound, but the module flag is still true.

Tag the element:

```ts
function bindBurgerMenu(): void {
  const burger = document.querySelector<HTMLElement>(".burger-toggle");
  if (!burger || burger.dataset.navBound === "1") return;
  burger.dataset.navBound = "1";
  burger.addEventListener("click", /* ... */);
}
```

When Barba swaps containers, the new burger element has no `dataset.navBound`, so it gets bound fresh. The old element is garbage-collected.

## Resize listener cleanup

Named function + module-scope reference for removability:

```ts
let resizeFn: (() => void) | null = null;

function bindLoader(): void {
  const onResize = (): void => { /* ... */ };
  if (resizeFn) window.removeEventListener("resize", resizeFn);
  resizeFn = onResize;
  window.addEventListener("resize", resizeFn, { passive: true });
}
```

## Library imports

```ts
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import Lenis from "lenis";
import barba from "@barba/core";
import Swiper from "swiper";
import { Pagination, Navigation } from "swiper/modules";
```

For libraries the bundle expects on `window.*` (HubSpot's hbspt, SplitText, the Three.js scene globals), use feature detection rather than imports.

## Lenis + ScrollTrigger integration

The critical wiring in `core/scroll.ts`:

```ts
let scroll: Lenis | null = null;

export function initSmoothScroll(): Lenis {
  setTimeout(() => window.scrollTo(0, 0), 50);
  if (scroll) try { scroll.destroy(); } catch {}
  scroll = new Lenis();
  scroll.on("scroll", ScrollTrigger.update);
  scroll.scrollTo(0, { immediate: true });
  gsap.ticker.remove(tickerFn);
  gsap.ticker.add(tickerFn);
  gsap.ticker.lagSmoothing(0);
  ScrollTrigger.refresh();
  return scroll;
}

function tickerFn(time: number) {
  if (scroll) scroll.raf(time * 1000);
}
```

This pattern wires Lenis's `raf` callback to GSAP's ticker (so ScrollTrigger updates land in sync) and pipes Lenis scroll events into ScrollTrigger.update. Without it, ScrollTrigger lags behind smooth-scroll and pinned elements look glitchy.

## Per-page animation gates

`features/page-anim.ts` is where the bulk of per-page reveals live. The shape:

```ts
export function animationOnPageLoad(): void {
  const tl = gsap.timeline();

  if (document.getElementById("textable_page")) {
    if (document.getElementById("service_s_page")) {
      // service-detail intro
    } else {
      // generic textable page intro
    }
  }
  if (document.getElementById("page_project")) { /* work-detail intro */ }
  if (document.getElementById("page_work")) { /* work-index intro */ }
  if (document.getElementById("page_about")) { /* about intro */ }
  if (document.getElementById("page_services")) { /* services intro */ }
  if (document.getElementById("page_blog")) { /* blog intro */ }
  if (document.getElementById("page_contact")) { /* contact intro */ }
  if (document.getElementById("page_error")) { /* 404 intro */ }
  if (document.getElementById("page_home")) {
    tl.call(() => homeFirstAnim(tl), undefined, 0);
  }
}
```

Each branch runs a GSAP timeline with the original easing strings (`power4.inOut`, `power4`, etc.) and the original durations. Port verbatim — don't optimize.

## ScrollTrigger pin/stack setups

Production sites use heavy ScrollTrigger pin/scrub animations (project cards collapse, process tiles compress, hero pinned scenes). These typically come in 12-20 named helpers like:

- `stickyProjects()` — home work showcase collapse
- `stickyProcessAccordion()` — process tiles horizontal compress
- `stickyForces()` — about page item_forces morph
- `stickyWorkItems()` — work index card collapse
- `stickyAboutTopHeader()` — about hero sidebar expand
- `stickyStackCards()` — 3D rotateX stack
- `stickyImageStory()` — story image height grow
- `stickyTestimonialEpic/Wins()`
- `stickyItemsService()` — service list slide-in
- `stickyBlogImagePreview()`, `stickyProjectHeader()`, `stickyNextProject()`, `stickyArticleSingleImage()`
- `stickyProcessWrapperHeader()`
- `parallaxWrapperTextImage()`

All these MUST be ported. Skipping them is the #1 reason a port "feels dead" — Wave 1 of the atoll session missed every pin setup because the modularizer agent's checklist only mentioned parallax. Read the original main.js for `ScrollTrigger.create` and `gsap.timeline({ scrollTrigger: {...} })` blocks and port each one verbatim.

Use the `id: "page-anim"` convention on every ScrollTrigger so Barba's leave hook can kill them safely:

```ts
gsap.timeline({
  scrollTrigger: {
    trigger: el,
    scrub: true,
    id: "page-anim",
  },
});
```

## SplitText: the GSAP plugin gotcha

SplitText is loaded as a global script (`window.SplitText`). GSAP doesn't auto-register globals — you must call `gsap.registerPlugin(window.SplitText)` before instantiating, or it throws:

```ts
let registered = false;
const getSplitText = (): SplitTextCtor | null => {
  if (typeof window === "undefined") return null;
  const ctor = window.SplitText;
  if (!ctor) return null;
  if (!registered) {
    try { gsap.registerPlugin(ctor); registered = true; } catch {}
  }
  return ctor;
};
```

Then wrap every `new SplitText()` call in a try/catch so any future failure can't take down the boot:

```ts
let split: SplitTextInstance;
try {
  split = new SplitText(targets, { type: "lines", linesClass: "line" });
} catch (err) {
  console.warn("SplitText failed", err);
  return;
}
```

## Things to leave dormant

- CF7 form module — usually replaced by HubSpot in the captured HTML; keep the code for parity but it won't fire
- AJAX pagination — needs a WP backend endpoint that doesn't exist in the replica; leave the binding, no-op without `window.ajaxpagination`
- Cursor — typically minimal (`html { cursor: wait }` toggling). Don't over-engineer

## Anti-patterns

- Don't rewrite easing strings ("power4.inOut" must stay "power4.inOut")
- Don't optimize timeline durations — fidelity > taste
- Don't merge multiple small `features/` modules into one file "for cleanliness" — readability matters when porting
- Don't add ESLint or Prettier mid-port — saves you from churn-only diffs
