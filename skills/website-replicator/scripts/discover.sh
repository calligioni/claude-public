#!/usr/bin/env bash
# discover.sh — bootstrap a forensic discovery workspace for a target site.
#
# Usage:
#   ./discover.sh <target-url> <work-dir>
#
# Cross-platform (macOS BSD + Linux GNU). Hardened by real-world feedback:
#   - PATH set at top so xargs sub-shells find tr/sed/curl/perl
#   - JSON validation on every .map file before declaring it "recovered"
#     (detects 403 SPA-fallback responses masquerading as captured maps)
#   - Sitemap-404 fallback: scrape homepage anchors when sitemap.xml is missing
#   - Nuxt _payload.json detection (per-route CMS-content shortcut)
#   - 403-vs-404 distinction in .map probes (403 = "exists but locked")

set -euo pipefail
export PATH="/usr/bin:/usr/local/bin:/bin:/opt/homebrew/bin:$PATH"

target="${1:?usage: discover.sh <target-url> <work-dir>}"
work="${2:?usage: discover.sh <target-url> <work-dir>}"

host="$(echo "$target" | perl -pe 's{^https?://}{}; s{/$}{}')"

mkdir -p "$work/html" "$work/assets" "$work/static_assets" \
  "$work/maps" "$work/recovered_readable" "$work/recovered_sources" \
  "$work/agent-notes" "$work/reports"

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# ============================================================================
# Step 1 — Sitemap + URL discovery (with fallback to homepage crawl)
# ============================================================================

echo "==> Fetching sitemap"
sitemap_status=$(curl -sL -A "$UA" -o "$work/sitemap.xml" -w "%{http_code}" "$target/sitemap.xml" 2>/dev/null || echo "000")

# Validate sitemap is actually XML — Nuxt sites return JSON 404 here
if [ "$sitemap_status" != "200" ] || ! head -c 200 "$work/sitemap.xml" 2>/dev/null | grep -qE '<\?xml|<urlset|<sitemapindex'; then
  echo "    sitemap.xml unusable (status=$sitemap_status, body not XML) — falling back to homepage anchor crawl"
  rm -f "$work/sitemap.xml"
fi

> "$work/page_urls.txt"

if [ -f "$work/sitemap.xml" ]; then
  grep -oE '<loc>[^<]+</loc>' "$work/sitemap.xml" | perl -pe 's{</?loc>}{}g' > "$work/page_urls.txt"
  for child in $(grep -oE '<loc>[^<]+sitemap[^<]+\.xml</loc>' "$work/sitemap.xml" 2>/dev/null | perl -pe 's{</?loc>}{}g'); do
    echo "    child sitemap: $child"
    curl -sL -A "$UA" "$child" | grep -oE '<loc>[^<]+</loc>' | perl -pe 's{</?loc>}{}g' >> "$work/page_urls.txt"
  done
else
  # FALLBACK: fetch homepage, extract every same-origin <a href>
  echo "==> Fallback: crawling homepage for anchor URLs"
  curl -sL -A "$UA" "$target" > "$work/_homepage.html" 2>/dev/null
  perl -ne '
    while (/<a[^>]+href="([^"]+)"/g) {
      my $href = $1;
      $href =~ s{#.*$}{};
      next unless $href;
      next if $href =~ /^(mailto|tel|javascript|data):/;
      if ($href =~ m{^/}) { print "'"$target"'$href\n"; }
      elsif ($href =~ m{^https?://'"$host"'}) { print "$href\n"; }
    }
  ' "$work/_homepage.html" | sort -u > "$work/page_urls.txt"
fi

# Always include the homepage
echo "$target" >> "$work/page_urls.txt"
echo "$target/" >> "$work/page_urls.txt"
sort -u "$work/page_urls.txt" -o "$work/page_urls.txt"

count=$(wc -l < "$work/page_urls.txt" | tr -d ' ')
echo "    $count unique URLs"

# ============================================================================
# Step 2 — Fetch each page in parallel
# ============================================================================

echo "==> Fetching pages (parallel; max 8 at a time)"
> "$work/pages_manifest.tsv"

export HOST="$host"
xargs -P 8 -I {} bash -c '
  url="$1"; work="$2"; host="$HOST"
  slug=$(echo "$url" | perl -pe "
    s{^https?://}{};
    s{^\Q$ENV{HOST}\E/?}{};
    s{/$}{};
    s{/}{__}g;
    s{[^A-Za-z0-9_-]}{_}g;
  " 2>/dev/null)
  [ -z "$slug" ] && slug="root"
  hash=$(echo -n "$url" | md5 -q 2>/dev/null || echo -n "$url" | md5sum | awk "{print substr(\$1,1,12)}")
  out="$work/html/${slug}.html.${hash}"
  status=$(curl -sL --max-time 30 -A "Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/537.36 Chrome/120 Safari/537.36" \
    -o "$out" -w "%{http_code}" "$url")
  printf "%s\t%s\t%s\n" "$status" "$url" "$out" >> "$work/pages_manifest.tsv"
' _ {} "$work" < "$work/page_urls.txt" 2>/dev/null

echo "    $(wc -l < "$work/pages_manifest.tsv" | tr -d ' ') pages captured"

# ============================================================================
# Step 3 — Asset inventory from homepage
# ============================================================================

echo "==> Inventorying same-origin assets from homepage"
home_html=$(awk -F'\t' -v t="$target" -v ts="$target/" '$2==t || $2==ts {print $3; exit}' "$work/pages_manifest.tsv")
[ -z "$home_html" ] && home_html=$(ls "$work/html/root.html."* 2>/dev/null | head -1)
[ -z "$home_html" ] && home_html=$(ls "$work/html/"* 2>/dev/null | head -1)

if [ -n "$home_html" ] && [ -f "$home_html" ]; then
  echo "    homepage: $home_html"
  perl -ne '
    while (/(?:src|href)="([^"]+\.(?:js|css)(?:\?[^"]*)?)"/g) {
      print "$1\n";
    }
  ' "$home_html" | sort -u > "$work/asset_urls.txt"
  echo "    $(wc -l < "$work/asset_urls.txt" | tr -d ' ') asset URLs"
fi

# ============================================================================
# Step 4 — Probe known framework data endpoints (Nuxt _payload.json, etc.)
# ============================================================================

echo "==> Probing framework data endpoints"
for endpoint in "_payload.json" "_nuxt/builds/meta/manifest.json" "api/__contentlayer/__schema__.json"; do
  url="${target%/}/${endpoint}"
  out="$work/agent-notes/$(echo "$endpoint" | tr '/' '_')"
  status=$(curl -sL --max-time 10 -A "$UA" -o "$out" -w "%{http_code}" "$url")
  if [ "$status" = "200" ] && head -c1 "$out" | grep -q '{'; then
    echo "    JACKPOT: $url → $out"
  else
    rm -f "$out"
  fi
done

# ============================================================================
# Step 5 — Fetch assets + hunt source maps (with validation)
# ============================================================================

echo "==> Fetching assets and hunting source maps"
> "$work/agent-notes/map-probe-results.tsv"

while IFS= read -r url; do
  case "$url" in
    /*)    url="${target%/}${url}" ;;
    //*)   url="https:${url}" ;;
    http*) ;;
    *)     url="${target%/}/$url" ;;
  esac

  fname=$(echo "$url" | perl -pe "s{^https?://}{}; s{\\?.*\$}{}; s{/}{__}g; s{[^A-Za-z0-9_.-]}{_}g;")
  curl -sL --max-time 30 -A "$UA" -o "$work/assets/$fname" "$url" 2>/dev/null

  base=$(echo "$url" | perl -pe 's{\?.*$}{}')
  for cand in "${base}.map" "${base%.js}.js.map" "${base%.css}.css.map"; do
    [ "$cand" = "$base" ] && continue
    mapname=$(echo "$cand" | perl -pe "s{^https?://}{}; s{/}{__}g; s{[^A-Za-z0-9_.-]}{_}g;")
    tmp_status=$(curl -sL --max-time 10 -A "$UA" -w "%{http_code}" -o "$work/maps/${mapname}" "$cand")
    # Validate JSON — 403 SPA fallbacks return HTML body with 200 code sometimes
    if [ -f "$work/maps/${mapname}" ] && head -c1 "$work/maps/${mapname}" 2>/dev/null | grep -q '{'; then
      if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$work/maps/${mapname}" 2>/dev/null; then
        printf "VALID\t%s\t%s\n" "$tmp_status" "$cand" >> "$work/agent-notes/map-probe-results.tsv"
      else
        printf "INVALID_JSON\t%s\t%s\n" "$tmp_status" "$cand" >> "$work/agent-notes/map-probe-results.tsv"
        rm -f "$work/maps/${mapname}"
      fi
    elif [ "$tmp_status" = "403" ]; then
      # 403 means file exists but is locked. Document; don't keep the body.
      printf "403_LOCKED\t%s\t%s\n" "$tmp_status" "$cand" >> "$work/agent-notes/map-probe-results.tsv"
      rm -f "$work/maps/${mapname}"
    else
      printf "NOT_JSON\t%s\t%s\n" "$tmp_status" "$cand" >> "$work/agent-notes/map-probe-results.tsv"
      rm -f "$work/maps/${mapname}"
    fi
  done

  # Also check the asset itself for sourceMappingURL comments
  if [ -f "$work/assets/$fname" ]; then
    smu=$(tail -c 4096 "$work/assets/$fname" 2>/dev/null | grep -oE 'sourceMappingURL=[^[:space:]"]+' | head -1 | sed 's/sourceMappingURL=//')
    if [ -n "$smu" ] && ! echo "$smu" | grep -q '^data:'; then
      # Resolve relative
      smu_url="$smu"
      case "$smu_url" in
        http*) ;;
        /*)    smu_url="${target%/}${smu_url}" ;;
        *)     asset_dir=$(echo "$url" | perl -pe 's{/[^/]+$}{}')
               smu_url="${asset_dir}/${smu_url}" ;;
      esac
      smu_name=$(echo "$smu_url" | perl -pe "s{^https?://}{}; s{/}{__}g; s{[^A-Za-z0-9_.-]}{_}g;")
      tmp_status=$(curl -sL --max-time 10 -A "$UA" -w "%{http_code}" -o "$work/maps/${smu_name}" "$smu_url")
      if [ -f "$work/maps/${smu_name}" ] && python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$work/maps/${smu_name}" 2>/dev/null; then
        printf "VALID_SMU\t%s\t%s\n" "$tmp_status" "$smu_url" >> "$work/agent-notes/map-probe-results.tsv"
      else
        rm -f "$work/maps/${smu_name}"
      fi
    fi
  fi
done < "$work/asset_urls.txt"

valid_count=$(grep -c "^VALID" "$work/agent-notes/map-probe-results.tsv" 2>/dev/null || echo 0)
locked_count=$(grep -c "^403_LOCKED" "$work/agent-notes/map-probe-results.tsv" 2>/dev/null || echo 0)
echo "    $valid_count valid maps recovered; $locked_count files locked (403); see map-probe-results.tsv"

# ============================================================================
# Step 6 — Decode source maps with sourcesContent (preserve full structure)
# ============================================================================

echo "==> Decoding source maps with sourcesContent"
for map in "$work/maps"/*; do
  [ -f "$map" ] || continue
  python3 - "$map" "$work/recovered_sources" <<'PYEOF' 2>/dev/null || true
import json, os, sys
from pathlib import Path
map_path, dst = sys.argv[1], sys.argv[2]
try:
    data = json.loads(Path(map_path).read_text())
except Exception:
    sys.exit(0)
sources = data.get("sources", [])
contents = data.get("sourcesContent", [])
if not contents:
    sys.exit(0)
for src, body in zip(sources, contents):
    if body is None: continue
    clean = src.replace("webpack://", "").lstrip("/")
    clean = clean.replace("../", "__up__/")
    out = Path(dst) / clean
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(body)
PYEOF
done
src_count=$(find "$work/recovered_sources" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "    $src_count source files recovered"

# ============================================================================
# Step 7 — Deminify
# ============================================================================

echo "==> Pretty-printing JS + CSS"
if command -v prettier >/dev/null 2>&1; then
  for f in "$work/assets"/*.js; do
    [ -f "$f" ] || continue
    out="$work/recovered_readable/$(basename "$f" .js).pretty.js"
    prettier --parser babel "$f" > "$out" 2>/dev/null || cp "$f" "$out"
  done
  for f in "$work/assets"/*.css; do
    [ -f "$f" ] || continue
    out="$work/recovered_readable/$(basename "$f" .css).pretty.css"
    prettier --parser css "$f" > "$out" 2>/dev/null || cp "$f" "$out"
  done
else
  echo "    prettier not found; copying minified files as-is"
  cp "$work/assets"/*.{js,css} "$work/recovered_readable/" 2>/dev/null || true
fi

# ============================================================================
# Step 8 — Summary
# ============================================================================

echo
echo "==> Done."
echo "    Pages:           $(ls "$work/html" 2>/dev/null | wc -l | tr -d ' ')"
echo "    Assets:          $(ls "$work/assets" 2>/dev/null | wc -l | tr -d ' ')"
echo "    Map candidates:  $(ls "$work/maps" 2>/dev/null | wc -l | tr -d ' ')"
echo "    Valid maps:      $valid_count"
echo "    Locked (403):    $locked_count"
echo "    Recovered:       $(ls "$work/recovered_readable" 2>/dev/null | wc -l | tr -d ' ')"
echo "    Source files:    $src_count"
echo
echo "    Next steps:"
echo "    1. scripts/find-sentinels.sh \"$work/recovered_readable\"     # WP-style sentinels"
echo "    2. scripts/inventory-components.sh \"$work/assets\"            # SPA component leaks (Vue/React/Svelte)"
echo "    3. scripts/inventory-motion-hooks.sh \"$work/html\"            # data-* hooks"
echo "    4. Read recovered_readable/*.pretty.js for the entry-point function"
echo "    5. Read recovered_readable/*.pretty.css :root block for design tokens"
