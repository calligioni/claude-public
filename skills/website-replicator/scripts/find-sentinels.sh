#!/usr/bin/env bash
# find-sentinels.sh — derive a target site's per-page intro-animation
# gating mechanism. The exact pattern depends on the source framework:
#
#   WordPress / vanilla / custom JS:  getElementById("page_xxx") sentinels
#   Vue / Nuxt:                       route.name / useRoute() / <RouterView>
#   React / Next:                     useRouter().pathname / usePathname()
#   Svelte / SvelteKit:               $page.route.id
#   Webflow:                          data-wf-page attribute on <html>
#
# Usage:
#   ./find-sentinels.sh <path-to-recovered-readable-or-assets-dir> [<path-to-html-dir>]
#
# The script tries WordPress-style first, then SPA-framework patterns, then
# Webflow. If none match, it emits "N/A — this target uses runtime/lifecycle
# gating, not sentinel divs. Build your PageType union from the route table."

set -euo pipefail
dir="${1:?usage: find-sentinels.sh <path-to-js-dir> [<path-to-html-dir>]}"
html_dir="${2:-}"

if [ ! -d "$dir" ]; then
  echo "Not a directory: $dir" >&2
  exit 1
fi

found_any=0

# ============================================================================
# WordPress-style: getElementById("page_xxx") empty sentinel divs
# ============================================================================
echo "==> Probing for WordPress-style getElementById sentinels..."
wp_ids=$(grep -hroE 'getElementById\(["'\'']page_[a-z_-]+["'\''']\)|querySelector\(["'\'']#page_[a-z_-]+["'\'']\)' "$dir" 2>/dev/null \
  | grep -oE 'page_[a-z_-]+' | sort -u || true)
text_ids=$(grep -hroE 'getElementById\(["'\'']textable_page["'\'']\)|getElementById\(["'\'']service_s_page["'\'']\)' "$dir" 2>/dev/null \
  | grep -oE '"[a-z_]+"' | tr -d '"' | sort -u || true)

if [ -n "$wp_ids" ] || [ -n "$text_ids" ]; then
  found_any=1
  echo "=== WordPress-style sentinels (use as your PageType union) ==="
  [ -n "$wp_ids" ] && echo "$wp_ids"
  [ -n "$text_ids" ] && echo "$text_ids"
  echo
  echo "Suggested PageType:"
  echo "    type PageType ="
  echo "$wp_ids" | awk '{ gsub(/^page_/, ""); printf "      | \"%s\"\n", $0 }'
fi

# ============================================================================
# Webflow: data-wf-page attribute on <html>
# ============================================================================
if [ -n "$html_dir" ] && [ -d "$html_dir" ]; then
  echo "==> Probing for Webflow data-wf-page IDs..."
  wf_ids=$(grep -hoE 'data-wf-page="[^"]+"' "$html_dir"/*.html* 2>/dev/null | sort -u || true)
  if [ -n "$wf_ids" ]; then
    found_any=1
    echo "=== Webflow page IDs (data-wf-page attribute on <html>) ==="
    echo "$wf_ids"
    echo
    echo "Note: Webflow uses one unique page ID per route (24-char hex)."
    echo "Build your PageType union from the route paths instead:"
    [ -n "$html_dir" ] && ls "$html_dir" | grep -v '^_' | head -10 | sed 's/^/    | "/' | sed 's/\.html\..*$/"/'
  fi
fi

# ============================================================================
# Vue / Nuxt: useRoute(), $route, route.name
# ============================================================================
echo
echo "==> Probing for Vue / Nuxt route-based gating..."
vue_hits=$(grep -hroE 'useRoute\(\)|\$route\.name|\$route\.path|route\.params\.|\$route\.fullPath' "$dir" 2>/dev/null | wc -l | tr -d ' ')
if [ "$vue_hits" -gt 0 ]; then
  found_any=1
  echo "=== Vue / Nuxt route-driven gating detected ==="
  echo "  $vue_hits route references found"
  echo "  This target uses Vue Router lifecycle, NOT sentinel divs."
  echo "  PageType should be derived from src/pages/ structure (file-routing)."
fi

# ============================================================================
# React / Next.js: useRouter, usePathname
# ============================================================================
echo
echo "==> Probing for React / Next.js route-based gating..."
react_hits=$(grep -hroE 'useRouter\(\)|usePathname\(\)|router\.pathname|router\.asPath' "$dir" 2>/dev/null | wc -l | tr -d ' ')
if [ "$react_hits" -gt 0 ]; then
  found_any=1
  echo "=== React / Next.js route-driven gating detected ==="
  echo "  $react_hits router references found"
  echo "  PageType from app/ or pages/ file structure."
fi

# ============================================================================
# Svelte / SvelteKit
# ============================================================================
echo
echo "==> Probing for Svelte / SvelteKit route-based gating..."
svelte_hits=$(grep -hroE '\$page\.route|\$page\.url\.|navigating' "$dir" 2>/dev/null | wc -l | tr -d ' ')
if [ "$svelte_hits" -gt 0 ]; then
  found_any=1
  echo "=== Svelte / SvelteKit route-driven gating detected ==="
  echo "  $svelte_hits page-store references found"
fi

# ============================================================================
# Verdict
# ============================================================================
echo

if [ "$found_any" = "0" ]; then
  echo "=== No sentinel pattern detected ==="
  echo
  echo "This target uses neither WordPress sentinels nor obvious SPA route gating."
  echo "Possible explanations:"
  echo "  - The bundle is heavily minified; consider running source-map decode first"
  echo "  - Custom gating logic (intersection observer? data-page attribute?)"
  echo "  - Animations don't gate per-route — they're shared across routes"
  echo
  echo "Fallback strategy:"
  echo "  1. Grep '$dir' for unique class / id patterns that appear in some files but not others"
  echo "  2. Look at the captured HTML <body class=...> attributes — they often differ per route"
  echo "  3. Derive PageType from the src/pages/ file structure of your replica"
fi
