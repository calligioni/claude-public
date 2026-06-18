# Phase 4 + Phase 7 — Layout architecture & page transitions

The layout architecture is THE pattern that lets per-page intro animations work without rewriting per-page logic. Get this right and the rest of the port falls out cleanly.

## The two-layout split

```
BaseLayout.astro          ← every page (incl. home)
└── SiteLayout.astro      ← every page EXCEPT home (auto-Header/Footer)
```

The home page uses `BaseLayout` directly because it composes motion-bound chrome inline (HomeHeader / HomeFooter / HomeMobileMenu that integrate with the FLIP wordmark + WebGL preloader). All other 40+ pages use `SiteLayout`, which adds shared Header/Footer/MobileMenu on top of BaseLayout.

## BaseLayout.astro responsibilities

Mount **once per page**, **outside** the Barba container:
- `<head>` with title, meta description, hreflang, favicon, fonts, production CSS link
- `<body data-barba="wrapper">` 
- `<slot name="before-content" />` — Preloader (the home page mounts this; subpages do via SiteLayout)
- The Barba container itself (`<main data-barba="container" data-barba-namespace="..." class="wrapper_site">`)
- The flying-logo container (`.transition-container > .logo-transition-name`) for FLIP transitions
- The mobile drawer (`.menu-bg` + `#menu-mobile`) — pre-Barba so it survives swaps
- The page-title seed script
- The module entry point `<script>import "@scripts/index"</script>`

```astro
---
/* BaseLayout.astro */
import "@styles/global.css";

type Props = {
  title?: string;
  description?: string;
  lang?: "en" | "fr";
  barbaNamespace?: string;
  bodyClass?: string;
};

const {
  title = "...",
  description = "...",
  lang = "en",
  barbaNamespace = "other",
  bodyClass = "",
} = Astro.props;

const htmlLang = lang === "fr" ? "fr-CA" : "en-US";
---

<!doctype html>
<html lang={htmlLang}>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{title}</title>
    <meta name="description" content={description} />
    <link rel="alternate" hreflang="en" href="/" />
    <link rel="alternate" hreflang="fr" href="/fr/" />
    <link rel="stylesheet" href="/wp-content/themes/<theme>/dist/app-XXXXXXXX.css?ver=1.0.0" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <script is:inline define:vars={{ getLangCode: lang }}>
      window.getLangCode = getLangCode;
    </script>
    <script is:inline src="/gh/ilja-van-eck/osmo/assets/gsap/SplitText.min.js"></script>
    <script is:inline async src="//js-na3.hsforms.net/forms/embed/v2.js"></script>
    <slot name="head" />
  </head>

  <body data-barba="wrapper" class={bodyClass}>
    <slot name="before-content" />

    <main
      data-barba="container"
      data-barba-namespace={barbaNamespace}
      class="wrapper_site"
    >
      <slot />
    </main>

    {/* Flying-logo for Barba transitions */}
    <div class="transition-container fixed pointer-events-none inset-0 z-[100] px-[var(--size-20)] py-[var(--size-20)] lg:py-[2.013888888888889vw] h-screen one-height-screen opacity-0 overflow-hidden flex items-end">
      <div class="logo-transition-name w-full flex flex-nowrap items-end"></div>
    </div>

    {/* Seed the flying logo with this page's title SVG on first paint */}
    <script is:inline>
      (function () {
        function seed() {
          var title = document.querySelector(".title_page");
          var slot = document.querySelector(".logo-transition-name");
          if (title && slot && !slot.innerHTML.trim()) slot.innerHTML = title.innerHTML;
        }
        if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", seed);
        else seed();
      })();
    </script>

    <script>import "@scripts/index";</script>
  </body>
</html>
```

## SiteLayout.astro responsibilities

Wraps BaseLayout, adds:
- Preloader (in `before-content` slot)
- `<Header />`
- The required `pageType` prop and the matching sentinel div(s)
- The default `<slot />` for page body
- `<Footer />`
- `<MobileMenu />`

```astro
---
import BaseLayout from "@layouts/BaseLayout.astro";
import Header from "@components/Header.astro";
import Footer from "@components/Footer.astro";
import Preloader from "@components/Preloader.astro";
import MobileMenu from "@components/MobileMenu.astro";

type PageType =
  | "services" | "service-detail"
  | "work" | "project"
  | "blog" | "article"
  | "about" | "contact"
  | "textable" | "error";

type Props = {
  title?: string;
  description?: string;
  lang?: "en" | "fr";
  barbaNamespace?: string;
  bodyClass?: string;
  currentPath?: string;
  pageType: PageType;
};

const { title, description, lang, barbaNamespace = "other", bodyClass, currentPath, pageType } = Astro.props;
---

<BaseLayout
  title={title}
  description={description}
  lang={lang}
  barbaNamespace={barbaNamespace}
  bodyClass={bodyClass}
>
  <Preloader slot="before-content" />

  <div id="page" class="inner_site">
    <Header lang={lang} currentPath={currentPath} />

    {/* Sentinel divs that gate animationOnPageLoad's per-page branches */}
    {pageType === "services" && <div id="page_services" />}
    {pageType === "service-detail" && (<>
      <div id="textable_page" />
      <div id="service_s_page" />
    </>)}
    {pageType === "work" && <div id="page_work" />}
    {pageType === "project" && <div id="page_project" />}
    {pageType === "blog" && <div id="page_blog" />}
    {pageType === "article" && <div id="textable_page" />}
    {pageType === "about" && <div id="page_about" />}
    {pageType === "contact" && <div id="page_contact" />}
    {pageType === "textable" && <div id="textable_page" />}
    {pageType === "error" && <div id="page_error" />}

    <slot />
    <Footer lang={lang} />
    <MobileMenu lang={lang} />
  </div>
</BaseLayout>
```

The sentinels are EMPTY by design. They're hooks that `animationOnPageLoad()` queries via `document.getElementById()` to pick which intro timeline runs.

## Header & Footer components

Single source of truth for each. Both take `lang` (for locale-aware nav labels) and Header takes `currentPath` (for the `atoll_current` active-link class).

### Locale-aware nav table

```astro
const navByLang: Record<"en" | "fr", NavItem[]> = {
  en: [
    { href: "/services/", label: "Services" },
    { href: "/creative-montreal-web-agency/", label: "About" },
    { href: "/work/", label: "Work", count: "(11)" },
    { href: "/articles/", label: "Blog" },
    { href: "/contact/", label: "Contact", isContact: true },
  ],
  fr: [
    { href: "/fr/agence-conception-web-montreal/", label: "AGENCE" },
    { href: "/fr/travaux/", label: "TRAVAUX", count: "(11)" },
    { href: "/fr/contact/", label: "CONTACT", isContact: true },
  ],
};
```

Note the FR variant has fewer entries — this matches the captured French mirror; not all routes have translations.

### The `.label_wrap` pattern

Each nav link has two identical `<span>` children inside `.label_wrap` so the hover slide-text animation has both states present:

```astro
<a href={item.href} data-anim-text-slide class="overflow-hidden leading-none">
  <span class="label_wrap">
    <span class="!opacity-100">{item.label}</span>
    <span class="!opacity-100">{item.label}</span>
  </span>
</a>
```

The `.label_wrap` CSS (from production CSS or your tokens.css) stacks them: first absolutely positioned over the second, overflow hidden. GSAP animates yPercent on hover to slide.

### FR language switcher fill

The WPML widget would populate the `.lang-ls` spans with the OTHER language's 2-letter code at runtime. Replace with an inline script:

```astro
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
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fill);
    else fill();
  })();
</script>
```

## Footer wordmark

Use the SINGLE giant SVG from the captured HTML (typically 1397×584 viewBox with 5 path elements spelling out the brand). NOT the three-glyph shared Logo component — that's sized for an 86px header column and renders only ~3 glyphs at footer width.

Extract from the captured footer, paste verbatim into Footer.astro with `class="w-full h-auto"`.

## Preloader.astro

Slim — only the chrome:

```astro
<div class="loading-container bg-bg pointer-events-none h-screen one-height-screen grid grid-cols-2 items-end pb-[var(--size-20)] lg:pb-[2.013888888888889vw] fixed z-[100] top-0 left-0 w-full h-full"></div>

<div class="transition-progress fixed z-[100] left-[140px] lg:left-1/2 right-0 bottom-5 lg:bottom-[2.013888888888889vw] pr-[8%] border-l border-transparent">
  <div id="wrapper_progress" class="h-[calc(var(--px)*2)] bg-primary/10 rounded-[var(--rounded-base)] overflow-hidden" style="width:0">
    <div id="progress_load" class="bg-primary h-full rounded-[var(--rounded-base)]" style="width:0"></div>
  </div>
</div>
```

The `#logo_preloader` element (the staggered SVG wordmark) lives INSIDE HomeHero on the home page — NOT in Preloader. Putting it in Preloader creates duplicate IDs.

## Page transitions (Phase 7)

Barba init in `core/transitions.ts`:

```ts
barba.init({
  sync: true,
  debug: false,
  timeout: 7000,
  transitions: [
    {
      name: "default",
      once(data) {
        initBarbaNavUpdate(data);
        initSmoothScroll(data.next.container);
        getScroll()?.scrollTo(0, { immediate: true });
        opts.onScriptInit();
        if (isLocalhost()) {
          gsap.set(".loading-container", { autoAlpha: 0 });
          gsap.set(".logo-flip", { autoAlpha: 1 });
        } else {
          initLoader(opts.onPageLoad);
        }
      },
      async leave(data) {
        initChangePageTitle(data.next.container as HTMLElement);  // ← swap flying-logo SVG
        pageTransitionIn();
        await delay(TRANSITION_OFFSET);
        destroyScroll();
        data.current.container.remove();
      },
      async enter() {
        if (document.body.classList.contains("home")) {
          pageTransitionOutHome(opts.onPageLoad);
        } else {
          pageTransitionOut(opts.onPageLoad);
        }
      },
      async beforeEnter(data) {
        // Sync body class from incoming page HTML
        const match = data.next.html.match(/<body.+?class="([^"]*)"/i);
        document.body.setAttribute("class", (match && match[1]) ?? "");
        // Re-init wpcf7 if present
        // Sync <html lang> from language switcher state
      },
    },
  ],
});
```

### `initChangePageTitle` is critical

On every navigation, copy the NEW page's `.title_page` innerHTML into `.logo-transition-name`. Without this, the flying logo shows the OLD page's wordmark during the transition:

```ts
function initChangePageTitle(container: HTMLElement): void {
  const nextTitle = container.querySelector(".title_page")?.innerHTML;
  if (nextTitle) {
    document.querySelectorAll(".logo-transition-name")
      .forEach((el) => (el.innerHTML = nextTitle));
  }
}
```

### `isLocalhost` narrow guard

The original main.js often has a guard that skips the preloader on the developer's dev host. Narrow it to the EXACT production dev host so it doesn't fire on your replica's dev server:

```ts
const isLocalhost = (): boolean => {
  if (typeof window === "undefined") return false;
  return window.location.host === "1atoll.loc:8888"; // or the original dev host
};
```

If broadened to `localhost`, your local dev never sees the preloader animation.

## Per-page composition

Home (`src/pages/index.astro`):

```astro
---
import BaseLayout from "@layouts/BaseLayout.astro";
import Preloader from "@components/Preloader.astro";
import HomeHeader from "@components/sections/home/HomeHeader.astro";
import HomeHero from "@components/sections/home/HomeHero.astro";
/* ... import all the home sections */
---

<BaseLayout
  title="..."
  lang="en"
  barbaNamespace="home"
  bodyClass="home wp-singular page-template page-template-template-home..."
>
  <Preloader slot="before-content" />
  <div id="page" class="inner_site">
    <HomeHeader />
    <HomeHero />
    {/* ... other sections */}
    <HomeMobileMenu />
  </div>

  {/* Home loads the production Three.js scene bundle */}
  <script
    slot="head"
    type="module"
    src="/wp-content/themes/<theme>/dist/app-BQbjH4ce.js?ver=1.0.0"
    is:inline
  ></script>
</BaseLayout>
```

Subpage (`src/pages/services/saas-web-design-agency.astro`):

```astro
---
import SiteLayout from "@layouts/SiteLayout.astro";
---

<SiteLayout
  title="..."
  description="..."
  lang="en"
  barbaNamespace="other"
  bodyClass="..."
  currentPath="/services/saas-web-design-agency/"
  pageType="service-detail"
>
  {/* extracted body content */}
</SiteLayout>
```
