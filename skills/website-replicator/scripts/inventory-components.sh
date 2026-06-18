#!/usr/bin/env bash
# inventory-components.sh — extract the component graph from a SPA bundle
# without source maps. Works on Vue / Nuxt / React / Svelte / Solid.
#
# Usage:
#   ./inventory-components.sh <path-to-recovered-readable-or-assets-dir>
#
# Why this matters: modern SPAs leak their component names in production
# bundles even when source maps are stripped:
#   - Vue 3 / Nuxt 3: `__name:"SectionHero"` properties on each SFC
#   - React: `displayName="HeaderBar"` and `Component.displayName`
#   - Svelte: `$$.fragment.c` filenames + `__svelte_meta` annotations
#   - Vite chunk filenames: `useScrollTrigger.ClxjLDci.css` — composable
#     names preserved when Vite uses default chunking
#
# This is a free recovery primitive — gives the entire component graph
# in one grep when source-map hunting comes up EMPTY.

set -euo pipefail
dir="${1:?usage: inventory-components.sh <path-to-js-dir>}"

if [ ! -d "$dir" ]; then
  echo "Not a directory: $dir" >&2
  exit 1
fi

echo "==> Component graph extraction from $dir"
echo

echo "=== Vue 3 / Nuxt 3: __name: leaks ==="
grep -hroE '__name:"[A-Z][a-zA-Z0-9_]+"' "$dir" 2>/dev/null \
  | sort -u | sed 's/__name:"\(.*\)"/  \1/' | head -60

echo
echo "=== React: displayName leaks ==="
grep -hroE 'displayName="[A-Z][a-zA-Z0-9_]+"' "$dir" 2>/dev/null \
  | sort -u | sed 's/displayName="\(.*\)"/  \1/' | head -40

grep -hroE '\.displayName\s*=\s*"[A-Z][a-zA-Z0-9_]+"' "$dir" 2>/dev/null \
  | sort -u | head -20

echo
echo "=== Svelte: __svelte_meta annotations ==="
grep -hroE '__svelte_meta[^,}]*[,}]' "$dir" 2>/dev/null | sort -u | head -30
grep -hroE 'svelte-[a-z0-9]+["]?\.svelte' "$dir" 2>/dev/null | sort -u | head -30

echo
echo "=== Vite chunk filenames (composables + sections) ==="
ls "$dir" 2>/dev/null | grep -E '^(use|Section|Layout|Component|Page|Block|App)' | head -30

echo
echo "=== Composable usage hints (use*) ==="
grep -hroE '\b(use[A-Z][a-zA-Z]+)\b' "$dir" 2>/dev/null \
  | sort -u | head -40

echo
echo "=== Build the file tree from leaks ==="
echo "  Suggested src/components/ structure based on __name + filenames above."
echo "  Each unique component name becomes a .vue, .tsx, or .svelte file."
echo
echo "Output: pipe to a file and use as the input to framework-porting.md's"
echo "        framework-specific recipes. e.g.:"
echo "        ./inventory-components.sh /tmp/nuxt-target/assets > /tmp/nuxt-target/components.txt"
