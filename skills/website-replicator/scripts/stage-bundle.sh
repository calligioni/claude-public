#!/usr/bin/env bash
# stage-bundle.sh — copy the production CSS/JS bundles + hashed font
# files into the replica's public/ at their EXACT original URL paths,
# so loading them via <link> / <script> resolves natively.
#
# Usage:
#   ./stage-bundle.sh <work-dir> <replica-dir>
#
# Example:
#   ./stage-bundle.sh /tmp/atoll-work /tmp/atoll-replica
#
# Reads:
#   <work>/assets/* — production JS + CSS bundles
#   <work>/static_assets_manifest.tsv — URL → local-file mapping
#
# Writes:
#   <replica>/public/<original-pathname>/* — bundles + fonts at original URLs

set -euo pipefail

work="${1:?usage: stage-bundle.sh <work-dir> <replica-dir>}"
replica="${2:?usage: stage-bundle.sh <work-dir> <replica-dir>}"

if [ ! -d "$work" ] || [ ! -d "$replica" ]; then
  echo "Both directories must exist" >&2
  exit 1
fi

pub="$replica/public"
mkdir -p "$pub"

# Stage assets via the manifest if available — preserves original URLs
manifest="$work/static_assets_manifest.tsv"
if [ -f "$manifest" ]; then
  echo "==> Staging from $manifest"
  count=0
  while IFS=$'\t' read -r filename url src; do
    [ -z "$url" ] && continue
    # Extract pathname from URL
    pathname=$(echo "$url" | perl -pe 's{^https?://[^/]+}{}; s{\?.*$}{}')
    [ -z "$pathname" ] || [ "$pathname" = "/" ] && continue
    dst="$pub$pathname"
    mkdir -p "$(dirname "$dst")"
    if [ -f "$src" ]; then
      cp "$src" "$dst"
      count=$((count + 1))
    fi
  done < "$manifest"
  echo "    Staged $count assets"
fi

# Stage production JS + CSS bundles from assets/ folder by reading the original URL from the filename hint
echo
echo "==> Staging production bundles (JS + CSS)"
for asset in "$work/assets"/*.js "$work/assets"/*.css; do
  [ -f "$asset" ] || continue
  # Filename pattern: foo__bar__app-XXX.js — reverse-engineer the original path
  # by replacing __ with /
  fname=$(basename "$asset")
  pathname=$(echo "$fname" | perl -pe 's{^}{/}; s{__}{/}g; s{\.([0-9a-f]{8,16})$}{}')
  # If it doesn't start with a known production path, fall back to /assets/
  case "$pathname" in
    /wp-content/*|/_next/*|/_nuxt/*|/_astro/*|/dist/*|/static/*|/build/*)
      dst="$pub$pathname"
      ;;
    *)
      dst="$pub/assets/$fname"
      ;;
  esac
  mkdir -p "$(dirname "$dst")"
  cp "$asset" "$dst"
  echo "    $fname → $pathname"
done

echo
echo "==> Done. Now in BaseLayout.astro <head>, load the production CSS:"
echo "    <link rel=\"stylesheet\" href=\"<production-css-path>\" />"
echo
echo "And on the home page, load the production JS bundle:"
echo "    <script type=\"module\" src=\"<production-js-path>\" is:inline></script>"
echo
echo "Asset directory: $pub"
echo "Total files: $(find "$pub" -type f | wc -l | tr -d ' ')"
