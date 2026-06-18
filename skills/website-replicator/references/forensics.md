# Phase 1 — Forensic discovery

The replication target is the **production site**, not a description. You need its HTML, its JS, its CSS, and its assets — in raw form. This phase produces a `<work>/atoll_sourcemaps/` (or similarly named) folder that all later phases read from.

## Output layout

By the end of this phase you should have:

```
<work>/<target>_sourcemaps/
├── html/                       # captured HTML for every public route
├── assets/                     # JS + CSS bundles served by the site
├── static_assets/              # images, fonts, GLB, Lottie JSON, videos
├── maps/                       # every .map URL that was checked (incl. 404 evidence)
├── recovered_readable/         # deminified pretty-printed JS + CSS
├── recovered_sources/          # any source-map-decoded original files
├── reports/
│   ├── sourcemap_report.json
│   └── recovery_summary.md
├── agent-notes/                # discovery + validation notes
└── pages_manifest.tsv          # mapping URL → local file → status code
```

## Step 1 — Sitemap discovery

Most production sites expose `/sitemap.xml` or `/sitemap_index.xml`. Yoast-powered WordPress sites have child sitemaps (`page-sitemap.xml`, `post-sitemap.xml`, `category-sitemap.xml`, etc.). Fetch the index, then each child, and produce a flat `page_urls.txt`.

```bash
curl -s https://<target>/sitemap.xml > sitemap_index.xml
# Recursively fetch <loc> children, dedupe, write to page_urls.txt
```

If no sitemap, fall back to: load the homepage, scrape every same-origin `<a href>`, follow 2-3 levels deep.

## Step 2 — Fetch every page

Use parallel `curl -L --compressed -o <local_file> <url>` for each page in `page_urls.txt`. Name files `<flattened_path>.html.<short_hash>` so collisions on similar URLs don't overwrite. Save raw response without any sanitization.

Build `pages_manifest.tsv`:
```
URL\tlocal_file\tstatus_code\tcontent_length\tetag
```

## Step 3 — Asset inventory

For each HTML page, extract every `<script src>`, `<link rel="stylesheet" href>`, `<img src>`, `<source srcset>`, `<video src>`, `<source>`, `<object data>`, etc. Dedupe across all pages, then fetch.

Stash same-origin assets in `assets/`, third-party CDN assets too (e.g. `cdn.jsdelivr.net/.../gsap.min.js`). For each:
- Save body to a hashed filename
- Record original URL, status, content-type, sha256

Same for static media → `static_assets/`.

Build `assets_manifest.tsv` and `static_assets_manifest.tsv` with the same schema.

## Step 4 — Source map hunting (do this AGGRESSIVELY before any deminification)

**Source maps are the holy grail.** When they exist with `sourcesContent`, you get the original source files (often the entire `src/` tree, including framework code, custom hooks, scene logic, shader programs). Hours of deminification + reverse-engineering collapse into seconds of `cp`. Check thoroughly and creatively — DON'T assume they're absent.

Hit-rate reality:
- WordPress + Vite production builds (e.g. Atoll): usually **no first-party maps**, but third-party CDN maps (GSAP, Lenis, Barba) exist
- Next.js / Vercel deployments: maps **often shipped** alongside the chunks at `/_next/static/chunks/*.js.map`
- Webpack builds: maps **sometimes** at `<chunk>.<hash>.js.map`
- Vite SPAs deployed via Netlify / Cloudflare Pages: maps **frequently shipped** with `sourceMappingURL` comments intact
- Webflow / Squarespace / Framer / Wix: rare; their JS is proprietary CDN
- Custom hand-rolled builds (e.g. Obys, Locomotive, 14islands): **roll the dice** — they sometimes leak maps either intentionally (for SEO debugging) or accidentally

### Technique 1: explicit `sourceMappingURL` comments

The fastest hit. Modern bundlers write a comment at the end of each output:

```bash
for asset in "$work/assets"/*.{js,css}; do
  [ -f "$asset" ] || continue
  # Last 2KB of the file usually contains the comment
  tail -c 4096 "$asset" | grep -oE 'sourceMappingURL=[^[:space:]"]+' | head -1
done > "$work/agent-notes/source-map-comments.txt"
```

Follow every comment. The comment value can be:
- A relative URL: `sourceMappingURL=app.js.map` → fetch `<asset-url-base>/app.js.map`
- An absolute URL: `sourceMappingURL=https://...` → fetch directly
- A data URL: `sourceMappingURL=data:application/json;base64,...` → decode in place
- An empty/falsy value: skip

### Technique 2: sibling-file guessing

Try these patterns for every JS/CSS asset:

```bash
for base in "${asset_url%.js}" "${asset_url%.css}" "$asset_url"; do
  for suffix in ".map" ".js.map" ".css.map" ".min.js.map" ".min.css.map" ".min.map"; do
    candidate="${base}${suffix}"
    curl -sL --max-time 10 -A "Mozilla/5.0" "$candidate" \
      -o "$work/maps/$(echo "$candidate" | tr '/' '_').map"
  done
done
```

Save 404 responses too — they're proof of negative results.

### Technique 3: bundler-specific known paths

| Stack | Known map locations |
|---|---|
| **Vite** | `dist/.vite/manifest.json`, `dist/manifest.json`, `<chunk>.<hash>.js.map` sibling |
| **Next.js** | `/_next/static/chunks/*.js.map`, `/_next/static/css/*.css.map` |
| **Nuxt** | `/_nuxt/<chunk>.js.map` |
| **Webpack** | `<bundle>.js.map` sibling; sometimes named after chunk hashes |
| **esbuild** | `*.js.map` sibling, often with full `sourcesContent` |
| **Rollup** | `<bundle>.js.map` sibling |
| **SvelteKit** | `/_app/immutable/chunks/*.js.map` |
| **Parcel** | `*.js.map` sibling |
| **Astro** | `_astro/*.js.map`, `_astro/*.css.map` |

For each detected stack (see `detection.md`), try the known paths even if no `sourceMappingURL` comment was found.

### Technique 4: peek inside the bundle for `webpack://` paths

Even WITHOUT a `.map` file, webpack-built bundles sometimes leak module path info inside the IIFE:

```bash
grep -oE 'webpack://[^"\s]+' "$asset" | sort -u | head -20
```

This won't recover sources, but it tells you the original directory structure and module names — useful for context when porting.

### Technique 5: try the cache-busted variant

Production assets often have a hash in the filename: `app.<HASH>.js`. If the `.map` 404s, try:

- `app.js.map` (without hash)
- `app.js` then `app.js.map`
- Common alternate hashes: drop last 6 chars, drop last 8 chars
- The base path without `dist/` (sometimes maps are served from `/static/maps/`)

### Technique 6: poke at the Vite manifest

If you see a `dist/` or `/_astro/` style path, ALWAYS try:

```bash
curl -sL "$target/dist/.vite/manifest.json"
curl -sL "$target/dist/manifest.json"
curl -sL "$target/_astro/manifest.json"
```

Vite manifests map source-file paths to output filenames. Not the sources themselves, but a roadmap to them. Often a 403 (locked) — that's evidence the build was Vite even if maps are absent.

### Technique 7: source-decoded jackpot — preserve the structure

When a map returns valid JSON with non-null `sourcesContent`, the discovery script writes each source file to `recovered_sources/<original-path>`. Critical:

- **Do NOT collapse leading `../` sequences.** They're meaningful — they point to `node_modules/` from the project's `src/` directory. Replace with `__up__/` so the filesystem doesn't escape, but keep the structure.
- **Webpack `webpack://` prefixes** → strip them but preserve everything after.
- **Random-string source IDs** (`<webpack>:///app.js` etc) → use as filenames as-is.

`discover.sh` does this correctly via its inline Python decoder — see lines around the `sourcesContent` block.

### Verdict & exit criterion

After all 7 techniques, write `<work>/reports/sourcemap_report.md`:

```markdown
# Source map recovery verdict

Target: <target>
Date: <ISO>

## Valid maps found: N
- <map URL>: <K source files> with sourcesContent
- ...

## Maps without sourcesContent: M
- <map URL>: <K sources but no contents>

## 404 candidates checked: P

## Recovery vector
- [x] JACKPOT — full sources recovered to recovered_sources/
- [ ] PARTIAL — some maps without sourcesContent; deminification still needed
- [ ] EMPTY — no first-party maps; deminification only path forward
```

If verdict is JACKPOT, skip steps 5 + 6 (deminification) — work from `recovered_sources/` directly. If PARTIAL or EMPTY, proceed with deminification.

For every JS and CSS asset:

1. **Inline `sourceMappingURL` comments.** `tail -c 2048 <asset> | grep -oE 'sourceMappingURL=[^[:space:]]+'`. Follow each match.
2. **Sibling `.map` files.** For each `<asset>.{js,css}`, try `<asset>.map`, `<asset>.{js,css}.map`, `<asset>.min.map`, `<asset>.min.{js,css}.map`. Fetch each candidate; 404 evidence is itself useful (save the response body to `maps/` so you can prove the chase was thorough).
3. **Vite manifests.** If the build output URLs look like `dist/app-XXXXXXXX.js` (hashed), try `dist/manifest.json` and `dist/.vite/manifest.json`. Usually 403 or 404 on production servers; both responses are evidence.

For any **valid** `.map` JSON:
- Parse `sources` and `sourcesContent`. If `sourcesContent` exists, write each source to `recovered_sources/<original_path>`.
- Record valid map metadata in `reports/sourcemap_report.json`.

For everything else, deminify the production bundle:
- JS: prettier or `js-beautify`
- CSS: prettier or hand-format
- Write to `recovered_readable/<asset>.pretty.{js,css}`

## Step 5 — Validation

Write `agent-notes/validation.md` with a one-paragraph verdict:
- Total maps checked
- Maps that returned valid JSON
- Whether any first-party maps had `sourcesContent`
- Where the deminified bundles live
- What recovery vectors remain (host backups, git deploy hook, dev machine clone)

This file gives the user (and you on next session) closure on whether further source-recovery effort is worth it. Usually the answer is "no, work from `recovered_readable/`".

## Step 6 — Mirror for visual diffing

In addition to the per-page HTML, build a static mirror under `mirror/`:
- Copy all HTML
- Copy all asset paths into a flat `mirror/assets/` directory
- Rewrite asset URLs in the HTML to local paths
- Add a tiny GTM/analytics shim so requests to external services don't pollute the audit

`cd mirror && python -m http.server 4177` gives you a browseable mirror to compare against your replica.

## What to do if the live site is gone

If the user is rebuilding a site that's been taken down:
- Check the Wayback Machine for snapshots: `https://web.archive.org/web/*/<url>`
- If they have a local backup, treat it the same as a live target
- Forensic recovery from `archive.org` is identical, just with `https://web.archive.org/web/<timestamp>id_/` as the URL prefix

## Implementation note

`scripts/discover.sh` (shipped with this skill) automates steps 1-5. It's cross-platform (BSD + GNU) and produces all manifests in one pass. Use this as the bootstrap. Follow up with:

- `scripts/find-sentinels.sh <recovered_readable_dir>` — derives the per-target `pageType` union by grepping `getElementById("page_xxx")` calls in the deminified production bundle. **Critical** because the `pageType` values you'll need for SiteLayout vary by site — never assume the Atoll set (`page_home`, `page_services`, etc.) applies to a new target.
- `scripts/inventory-motion-hooks.sh <html_dir>` — produces a frequency-ranked catalog of every `data-*` motion-hook attribute in the captured HTML. Later phases need this to preserve every hook the production JS expects.
- `scripts/extract-body.py <html-file> <target-domain>` — single-file body extractor with chrome strip + URL rewrite. Use this when porting page content.

## Source-map jackpot

When `.map` files return valid JSON with non-null `sourcesContent`, the agent gets the original source files. `discover.sh` writes them to `recovered_sources/` preserving the source path (with `../` replaced by `__up__/` so the filesystem doesn't escape). This includes node_modules paths, which let you see which libraries the original bundle pulled in.

If the recovered sources include a full project structure (multiple `.js` files organized by feature), you're in jackpot territory — you can read the actual source rather than deminifying. Use these instead of `recovered_readable/`.

## Bot protection / Cloudflare / AWS WAF

If `curl` fails on the target (403, blank body, Cloudflare challenge HTML):

- Add a real User-Agent: `curl -A "Mozilla/5.0 (...) Chrome/120 Safari/537.36"`
- If that fails, use Playwright with `headless: false` to dismiss the challenge interactively
- If geo-blocked or paywalled, use Wayback Machine: `https://web.archive.org/web/<TIMESTAMP>id_/<URL>` — `id_` flag returns the unmodified original response

Stop and tell the user before proceeding if the captured HTML looks like a challenge page rather than the real site.

## `<head>` parity

Capture not just the body but every meta/link in `<head>`:

```bash
grep -oE '<(meta|link|title)[^>]*>' "$work/html/<homepage>" > "$work/agent-notes/head-inventory.txt"
```

Use this to verify canonical URLs, hreflang, OG/Twitter tags, favicons, and DNS prefetches when porting. A pixel-faithful replica that ships wrong canonicals or missing hreflang isn't actually faithful.

## Anti-patterns

- Don't rate-limit yourself harshly during fetch; production CDNs are fine with concurrent gets
- Don't skip 404 evidence — saving the 404 body lets you prove negative results
- Don't try to "interpret" the production JS during discovery; this phase is acquisition only
- Don't strip the trailing query strings (`?ver=1.0.0`) from asset URLs — sometimes the version matters for cache parity
