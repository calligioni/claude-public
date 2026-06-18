#!/usr/bin/env bash
# inventory-motion-hooks.sh — list every motion-hook data-* attribute the
# production HTML uses, with counts. Critical input for the porting phase
# so agents preserve every hook the JS expects.
#
# Usage:
#   ./inventory-motion-hooks.sh <path-to-html-mirror-dir> [--include-spa-noise]
#
# Output: /tmp/motion-hooks.tsv (frequency-ranked) + console summary
#
# By default, filters out Vue's scoped-style `data-v-<hash>` attributes
# (they flood the inventory on Vue/Nuxt sites with thousands of entries
# that are NOT motion hooks). Pass --include-spa-noise to keep them.

set -euo pipefail
html_dir="${1:?usage: inventory-motion-hooks.sh <path-to-html-dir>}"
include_noise="${2:-}"

if [ ! -d "$html_dir" ]; then
  echo "Not a directory: $html_dir" >&2
  exit 1
fi

echo "==> Inventorying motion-hook data-* attributes across $html_dir/*.html ..."
echo

# Pull every data-* attribute name (drop the value), count occurrences.
raw="/tmp/motion-hooks-raw.tsv"
grep -hoE 'data-[a-z][a-z0-9-]*=' "$html_dir"/*.html* 2>/dev/null \
  | sed -E 's/=$//' \
  | sort \
  | uniq -c \
  | sort -rn \
  > "$raw"

# Filter Vue scoped-style hashes (data-v-<8-12 char hex>) unless asked to keep
filtered="/tmp/motion-hooks.tsv"
if [ "$include_noise" = "--include-spa-noise" ]; then
  cp "$raw" "$filtered"
else
  grep -vE 'data-v-[0-9a-f]{6,}$' "$raw" > "$filtered"
fi

echo "=== Top 40 motion hooks by frequency (Vue scoped-style noise filtered) ==="
head -40 "$filtered"

echo
echo "=== Suspected motion hooks (anim, scroll, splitting, sticky, etc.) ==="
grep -hoE 'data-[a-z][a-z0-9-]*=' "$html_dir"/*.html* 2>/dev/null \
  | sed -E 's/=$//' | sort -u \
  | grep -vE 'data-v-[0-9a-f]{6,}$' \
  | grep -E 'anim|scroll|split|sticky|target|trigger|home|preloader|webgl|distort|parallax|line|menu|cursor|reveal|lenis|barba|w-id' \
  | sort

echo
echo "=== Framework-specific motion-hook patterns ==="
grep -hoE 'data-w-id="[^"]+"' "$html_dir"/*.html* 2>/dev/null | head -1 && echo "  → Webflow IX2 (data-w-id binds animations)"
grep -hoE 'data-aos="[^"]+"' "$html_dir"/*.html* 2>/dev/null | head -1 && echo "  → AOS (animate-on-scroll)"
grep -hoE 'data-scroll[^=]*=' "$html_dir"/*.html* 2>/dev/null | head -1 && echo "  → Locomotive Scroll"
grep -hoE 'data-barba[^=]*=' "$html_dir"/*.html* 2>/dev/null | head -1 && echo "  → Barba.js"
grep -hoE 'data-lenis[^=]*=' "$html_dir"/*.html* 2>/dev/null | head -1 && echo "  → Lenis lifecycle hooks"
grep -hoE 'data-reka-[^=]*=' "$html_dir"/*.html* 2>/dev/null | head -1 && echo "  → Reka UI (Vue Radix port)"
grep -hoE 'data-radix-[^=]*=' "$html_dir"/*.html* 2>/dev/null | head -1 && echo "  → Radix UI"

echo
echo "Full inventory saved to $filtered"
echo
echo "Caveat for SPA targets (Vue/Nuxt/React/Svelte):"
echo "  Motion hooks may be ADDED at hydration time, not present in SSR HTML."
echo "  For accurate inventory on a hydrated SPA, capture rendered DOM via Playwright:"
echo "    await page.goto(url); html = await page.content();"
echo "  Then run this script against that captured HTML instead."
