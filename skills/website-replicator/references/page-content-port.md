# Phase 6 — Page content port

This phase takes the captured HTML mirror and produces one `.astro` file per route. Done right, it takes 30 minutes via parallel agents. Done wrong, it takes a day and produces orphaned `{SCROLL}` JSX errors.

## Strategy: dispatch 4-6 parallel agents by route family

Don't port pages one at a time. Group routes by family and dispatch one agent per family, all at once:

1. Home (manual — too special for an agent; use the home sections you've already extracted)
2. Services index + N service-detail pages
3. Work index + N case studies
4. Articles index + N article details + archives (category, author)
5. Static pages (contact, thank-you, legal, about)
6. Foreign-language mirror (FR / DE / ES)

Each agent gets the same brief structure (see "Agent brief template" below) but customized for its routes.

## Agent brief template

```
You are porting all N <family> pages of <target>.com from a captured HTML
mirror into Astro pages. Cold start.

# Project

Pixel-faithful replica at <replica-root>/. Astro 6 + Tailwind v4.

# Pages to port

Source HTML in <work>/<target>_sourcemaps/html/:

| URL | Source file | Target Astro path |
|---|---|---|
| /services/ | services.html.<hash> | src/pages/services/index.astro |
| /services/saas/ | services__saas.html.<hash> | src/pages/services/saas.astro |
| ... etc

# Already in place

- src/layouts/SiteLayout.astro — auto-mounts Header + Footer
- src/components/Header.astro, Footer.astro, Logo.astro
- Path aliases: @components, @layouts, @scripts, @styles
- Static assets at /wp-content/... resolve from public/

# Page template

```astro
---
import SiteLayout from "@layouts/SiteLayout.astro";
---

<SiteLayout
  title="[exact <title>]"
  description="[exact <meta name='description'>]"
  lang="en"
  barbaNamespace="other"
  bodyClass="[exact body class from original]"
  currentPath="/<slug>/"
  pageType="<service-detail | service | work | project | blog | article | about | contact | textable>"
>
  {/* extracted body content */}
</SiteLayout>
```

# Critical rules

1. Preserve every class, data-* attribute, ARIA, inline SVG verbatim
2. Rewrite internal URLs: https://<target>.com/X → /X
3. Strip ONLY WordPress noise (Yoast schema, oEmbed, RSS, classic-theme-styles, global-styles inline CSS, dns-prefetch, Complianz banner, original <header>/<footer>/preloader chrome — provided by SiteLayout)
4. HTML-entity-escape literal { and } in body text (but NOT inside <style> blocks)
5. Use <Fragment set:html={bodyHtml} /> + a template literal if the body has many literal braces / inline styles (see below)
6. Don't touch any file outside src/pages/<family>/

# Verification

cd <replica-root> && npm run build  → must succeed

# Return

A list of files created + any embedded <script> blocks preserved + the
distortion-target containers per page.
```

## The body-extraction approach

Two patterns work; the second is more robust.

### Pattern A — JSX inline

Useful when the body is mostly markup with few literal braces.

```astro
---
import SiteLayout from "@layouts/SiteLayout.astro";
---

<SiteLayout ...>
  <div class="...">
    <h1>Heading</h1>
    <p>Body text with no literal braces</p>
  </div>
</SiteLayout>
```

If literal `{` or `}` appears as display text, escape them:
- HTML entity: `&#123;` `&#125;`
- OR JSX-template: `{`{`} foo {`}`}` (produces literal `{ foo }`)

### Pattern B — `<Fragment set:html={bodyHtml} />` (preferred)

Best when the body has `<style>` blocks, inline `style="..."` with `calc(...)`, or any other CSS-like content that's hostile to JSX.

```astro
---
import SiteLayout from "@layouts/SiteLayout.astro";

const bodyHtml = `
  <div class="some-class">
    <style>.x { color: red; }</style>
    <h1>Heading</h1>
    <p>Body text with literal { braces } and inline style="height: calc(100% - 20px)"</p>
  </div>
`;
---

<SiteLayout ...>
  <Fragment set:html={bodyHtml} />
</SiteLayout>
```

`set:html` is opaque to Astro's JSX parser, so raw HTML — including `<style>` blocks and CSS braces — passes through unmolested. This sidesteps the brace-escape mess entirely.

## Body extraction recipe

For each captured HTML file:

1. Find the body open: `<body data-barba="wrapper" class="...">`
2. Find the FIRST element AFTER the preloader chrome — usually after the `.transition-container` block
3. Find the body close: `</body>`
4. Capture everything between the start of the Barba container's content and the closing `</footer>` (since SiteLayout provides its own footer)
5. Strip:
   - `<header id="header_sticky">...</header>` chrome (SiteLayout provides it)
   - `<div class="loading-container">`, `<div class="transition-progress">`, `<div class="transition-container">` (Preloader provides them)
   - `<div id="menu-mobile">`, `<div class="menu-bg">` (MobileMenu provides them)
   - The Complianz banner block (if any)
6. Rewrite all `https://<target>.com/X` → `/X` in the captured slice
7. Rewrite all `https://<target>.com/wp-content/X` → `/wp-content/X` (assets resolve from public/)
8. Optionally entity-escape `{` and `}` outside `<style>` blocks (only if using Pattern A)

A Python helper that does this in one pass:

```python
import re
import html
from pathlib import Path

def port_page(html_path, target_domain):
    text = Path(html_path).read_text()
    body = re.search(r'<body[^>]*>(.*?)</body>', text, re.DOTALL).group(1)
    body = re.sub(r'<header[^>]*id="header_sticky".*?</header>', '', body, flags=re.DOTALL)
    body = re.sub(r'<div[^>]*class="loading-container.*?</div>', '', body, flags=re.DOTALL)
    body = re.sub(r'<div[^>]*class="transition-progress.*?</div>\s*</div>', '', body, flags=re.DOTALL)
    body = re.sub(r'<div[^>]*class="transition-container.*?</div>\s*</div>', '', body, flags=re.DOTALL)
    body = re.sub(r'<div[^>]*id="menu-mobile".*?</div>\s*</div>', '', body, flags=re.DOTALL)
    body = body.replace(f'https://{target_domain}/', '/')
    return body
```

## Per-pageType conventions

| pageType | Used for | Sentinel emitted | Notable hooks |
|---|---|---|---|
| `services` | `/services/` index | `#page_services` | `[data-about-vertical-line]`, `[data-about-image]`, `.menu_services` (smooth-scroll anchors) |
| `service-detail` | `/services/<slug>/` | `#textable_page` + `#service_s_page` | `[data-serv-line-horiz]`, `[data-anim-opacity]` |
| `work` | `/work/` index | `#page_work` | `.work-item` (staggered reveal), `[data-line-top-work]` |
| `project` | `/work/<slug>/` | `#page_project` | `[data-line-top-project]`, `.project_wrapper` + custom bg color |
| `blog` | `/articles/`, `/articles/category/`, `/articles/author/` | `#page_blog` | `[data-image-blog]`, `[data-blog-title]`, `#pagination-blog` |
| `article` | `/articles/<slug>/` | `#textable_page` | `[data-anim-opacity]`, inline `<style>` blocks for prose |
| `about` | `/<about-slug>/` | `#page_about` | `[data-about-image]`, `.item_forces`, accordions |
| `contact` | `/contact/`, `/thank-you/` | `#page_contact` | `#form_hubspot`, `[full-line-contact]` |
| `textable` | privacy, cookie-policy | `#textable_page` | Just prose; minimal hooks |

## URL family routing

Astro page routing:

| URL pattern | File location |
|---|---|
| `/services/` | `src/pages/services/index.astro` |
| `/services/<slug>/` | `src/pages/services/<slug>.astro` |
| `/work/` | `src/pages/work/index.astro` |
| `/articles/category/<slug>/` | `src/pages/articles/category/<slug>.astro` |
| `/fr/travaux/<slug>/` | `src/pages/fr/travaux/<slug>.astro` |

Astro's `trailingSlash: "always"` config matches the production URL shape (every public route ends with `/`).

## Bulk pageType insertion

After agents finish porting, a perl one-liner adds the `pageType` prop based on URL:

```bash
add_page_type() {
  local file="$1" type="$2"
  grep -q 'pageType=' "$file" && return
  perl -i -pe 's{(\s*currentPath="[^"]*"\s*)$}{$1\n  pageType="'"$type"'"}' "$file"
}

add_page_type src/pages/services/index.astro services
for f in src/pages/services/*.astro; do
  [ "$f" = "src/pages/services/index.astro" ] && continue
  add_page_type "$f" service-detail
done
# ... etc
```

## Verification

After all agents return:

```bash
npm run build
```

If it fails with `ReferenceError: <NAME> is not defined`, you have an unescaped JSX brace in body content. Grep for the pattern and fix:

```bash
grep -rn "{ *[A-Z]\+ *}" src/pages/ | head
```

Common culprits: `{ SCROLL }`, `{ ABOUT }`, page-section labels.

## Anti-patterns

- Don't try to "DRY up" content across pages mid-port — fidelity first, refactoring later
- Don't strip data-* attributes you don't recognize; they drive motion
- Don't simplify inline SVGs — Astro will optimize on build
- Don't replace the captured `bodyClass` with a generic class — the original CSS hooks rely on it (`body.home`, `body.single-work`, etc.)
- Don't run a sweeping entity-escape on every file then sed it back inside `<style>` blocks — you'll miss some. Use `<Fragment set:html>` instead
