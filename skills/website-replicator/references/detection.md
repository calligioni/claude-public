# Phase 0 — Detection / Recon (run BEFORE forensics)

Before scraping a single page, classify the source site. The rest of the skill assumes WordPress + Vite + jQuery+GSAP+Three.js because that was the original session's target. **Many sites are not that.** Detecting the source stack early conditions every downstream choice.

## What to detect

1. **Framework / CMS:** WordPress, Webflow, Framer, Squarespace, Wix, Next.js, Nuxt, Gatsby, SvelteKit, Astro, Vite SPA, plain HTML, custom PHP.
2. **Bundler:** Vite, Webpack, esbuild, Rollup, Parcel, none.
3. **JS runtime libraries:** jQuery? GSAP? Lenis? Framer Motion? React? Vue?
4. **Motion stack:** GSAP+ScrollTrigger? Framer Motion? Locomotive Scroll? CSS-only?
5. **3D / WebGL:** Three.js? Custom WebGL? PixiJS? Babylon? OGL? None?
6. **Page transitions:** Barba? Astro view transitions? Next.js routing? Native?
7. **CSS approach:** Tailwind (which version)? CSS modules? styled-components? raw CSS?
8. **i18n approach:** WPML? next-intl? prefix routing? subdomain? none?
9. **Forms:** Contact Form 7? HubSpot? Netlify Forms? Formspree? Typeform embed? custom?
10. **Analytics / consent:** GTM? Plausible? Complianz? Cookiebot? OneTrust?
11. **Bot protection:** Cloudflare challenge? AWS WAF? reCAPTCHA wall?

## Detection commands

Run these one-shot before phase 1. Two-second pass; saves hours later.

```bash
TARGET="https://<target>"
WORK="<work-dir>"
mkdir -p "$WORK" && cd "$WORK"

# Fetch homepage HTML
curl -sL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  "$TARGET" > home.html 2>/dev/null

# 1. Framework / CMS hints
echo "=== Framework hints ==="
grep -oE 'wp-content|wp-includes|wp-json' home.html | head -1 && echo "  → WordPress"
grep -oE 'webflow' home.html | head -1 && echo "  → Webflow"
grep -oE 'framer\.com|framerusercontent' home.html | head -1 && echo "  → Framer"
grep -oE 'sqsp\.net|squarespace' home.html | head -1 && echo "  → Squarespace"
grep -oE '/_next/' home.html | head -1 && echo "  → Next.js"
grep -oE '/_nuxt/' home.html | head -1 && echo "  → Nuxt"
grep -oE '_astro/' home.html | head -1 && echo "  → Astro"
grep -oE '_app\.gatsby' home.html | head -1 && echo "  → Gatsby"
grep -oE 'shopify\.com|cdn\.shopify' home.html | head -1 && echo "  → Shopify"
grep -oE 'svelte-' home.html | head -1 && echo "  → SvelteKit / Svelte"

# 2. JS libraries
echo
echo "=== JS libraries ==="
grep -oE 'jquery[^"]*\.js' home.html | head -1 && echo "  → jQuery"
grep -oE 'gsap[^"]*\.js|TweenMax|ScrollTrigger' home.html | head -1 && echo "  → GSAP"
grep -oE 'lenis[^"]*\.js' home.html | head -1 && echo "  → Lenis"
grep -oE 'framer-motion' home.html | head -1 && echo "  → Framer Motion"
grep -oE '@barba/core|barba\.umd\.min\.js' home.html | head -1 && echo "  → Barba"
grep -oE 'swiper[^"]*\.js' home.html | head -1 && echo "  → Swiper"
grep -oE 'splitting\.js|SplitText' home.html | head -1 && echo "  → SplitText / Splitting"
grep -oE 'three[^"]*\.js|three\.module' home.html | head -1 && echo "  → Three.js"
grep -oE 'react[^"]*\.js' home.html | head -1 && echo "  → React"
grep -oE 'vue[^"]*\.js' home.html | head -1 && echo "  → Vue"

# 3. CSS approach
echo
echo "=== CSS approach ==="
grep -oE '\bclass="[^"]*(\bbg-|\btext-|\bflex|\bgrid|\bp[xytrblm]?-\d)' home.html | head -1 && echo "  → Tailwind-like utility classes"
grep -oE 'tailwind|--tw-' home.html | head -1 && echo "    (Tailwind confirmed)"

# 4. Forms
echo
echo "=== Forms ==="
grep -oE 'wpcf7|contact-form-7' home.html | head -1 && echo "  → Contact Form 7"
grep -oE 'hbspt\.forms|hsforms\.net' home.html | head -1 && echo "  → HubSpot"
grep -oE 'netlify' home.html | head -1 && echo "  → Netlify Forms"
grep -oE 'formspree|formkeep|typeform' home.html | head -1 && echo "  → 3rd-party form embed"

# 5. i18n
echo
echo "=== i18n ==="
grep -oE 'wpml-ls|wpml_cookies' home.html | head -1 && echo "  → WPML (WordPress)"
grep -oE 'hreflang="' home.html | sort -u | head -3

# 6. Consent / analytics
echo
echo "=== Consent / analytics ==="
grep -oE 'complianz|cmplz-' home.html | head -1 && echo "  → Complianz"
grep -oE 'cookiebot|onetrust' home.html | head -1 && echo "  → Cookiebot / OneTrust"
grep -oE 'googletagmanager\.com/gtm' home.html | head -1 && echo "  → Google Tag Manager"
grep -oE 'plausible\.io|umami\.is|fathom' home.html | head -1 && echo "  → Privacy-first analytics"

# 7. Bot protection
echo
echo "=== Bot protection (curl behaviour) ==="
status=$(curl -sL -o /dev/null -w "%{http_code}" -A "Mozilla/5.0" "$TARGET")
echo "  Status: $status"
grep -oE 'cf-ray|cloudflare' home.html | head -1 && echo "  → Cloudflare (may challenge)"
grep -oE 'awselb|aws-waf' home.html | head -1 && echo "  → AWS WAF"
```

Save the output as `<work>/agent-notes/detection.md`.

## Decision matrix

After detection, classify into one of these buckets and adjust the workflow:

| Detected | Workflow adjustment |
|---|---|
| **WordPress + Vite + jQuery+GSAP** | **Default path.** Skill's references apply directly. |
| **WordPress + Elementor / Divi / classic** | Skill works but motion is page-builder-driven; less production JS to deminify. Skip phase 5 (JS modularization), focus on phases 4 + 6 (layout + content). |
| **Webflow** | Webflow ships its OWN custom JS interactions. Forensic discovery finds `webflow.js`; skip phase 5. Tokens come from Webflow's CSS but classes use semantic names, not utility. |
| **Framer** | Framer has React Server Components + animation primitives. The "ship the bundle" pattern doesn't apply. Recommend phase 1+2 only; advise user this is a partial port. |
| **Next.js / Nuxt** | Server-rendered React/Vue. Often Tailwind-flavored but with React hooks. The skill's Astro target works but you'll be porting JSX → Astro components, not jQuery → vanilla. |
| **Astro / Gatsby / SvelteKit** | Already in Astro-adjacent territory. The target is more "modernize" than "replicate"; user may want the original framework instead. Confirm before proceeding. |
| **Plain HTML / brochureware** | Phases 1, 4, 6 only. No JS modularization needed. Faster overall. |
| **Behind bot protection** | `curl` may fail / get challenged. Switch to Playwright with a real user-agent + headless: false for the discovery pass. Or use Wayback Machine snapshot. |

## When the detection doesn't match the skill's defaults

Tell the user explicitly. Example:

> "I detected this is a Framer site (framerusercontent.com references in the head). My replication skill is optimized for WordPress + Vite stacks — the layout / page-transitions / WebGL strategies don't transfer 1:1. I can still do phases 1 (forensic discovery) + 2 (Astro scaffold) + 6 (content port) faithfully. Phases 5 + 7 + 8 would need adaptation. Want me to proceed with the partial port, or adapt the workflow to Framer specifically?"

Asking is cheap. Forging ahead with the wrong assumptions wastes hours.

## Output

`<work>/agent-notes/detection.md` should contain:

```markdown
# Detection report

**Target:** https://<target>
**Date:** <ISO date>

## Stack classification
- CMS: <e.g. WordPress 6.9.4>
- Bundler: <e.g. Vite 7>
- Framework: <e.g. custom WP theme>
- CSS: <e.g. Tailwind v3>
- Motion: <e.g. GSAP 3.12.5 + Lenis 1.1.18 + Barba 2.9.7>
- 3D: <e.g. Three.js bundled in app-<HASH>.js>
- Forms: <e.g. HubSpot embed>
- i18n: <e.g. WPML EN/FR>
- Consent: <e.g. Complianz>
- Bot protection: <none | Cloudflare | WAF>

## Workflow adjustment
<which phases apply, which need adaptation, anything to flag to the user>

## Risks / unknowns
<bot challenges, paywalls, dynamic content the discovery scraper can't reach>
```

This report is the input to Phase 1. Future phases reference it.

## Anti-patterns

- Don't skip detection because "the skill says WordPress." The skill DEFAULTS to WordPress because that's what the original session captured. New targets are routinely something else.
- Don't run discovery if detection reports a paywall or geo-block — the captured HTML will be useless or misleading.
- Don't promise pixel-faithful replication for stacks the skill isn't designed for (Framer, Squarespace, Wix). Be upfront.
