#!/usr/bin/env bash
# inventory-scrolltrigger.sh — extract every GSAP ScrollTrigger configuration
# from a recovered/deminified bundle. Critical input for porting GSAP-heavy
# sites where the original main.js has dozens of triggers and you need to
# enumerate them before rebuilding.
#
# Usage:
#   ./inventory-scrolltrigger.sh <path-to-js-dir>
#
# Output (per ScrollTrigger setup):
#   - trigger selector
#   - start / end anchors
#   - scrub: true/false
#   - pin: true/false
#   - onEnter / onLeave / onUpdate callbacks (if visible)
#
# This is roughly the input you need to populate src/scripts/features/page-anim.ts
# with the original site's complete motion choreography.

set -euo pipefail
dir="${1:?usage: inventory-scrolltrigger.sh <path-to-js-dir>}"

if [ ! -d "$dir" ]; then
  echo "Not a directory: $dir" >&2
  exit 1
fi

echo "==> Scanning $dir for ScrollTrigger configurations..."
echo

# Find scrollTrigger:{ blocks
echo "=== ScrollTrigger setup count by file ==="
for f in "$dir"/*.{js,vue,svelte,jsx,tsx,ts} 2>/dev/null; do
  [ -f "$f" ] || continue
  count=$(grep -cE 'scrollTrigger\s*:\s*\{|ScrollTrigger\.create\(' "$f" 2>/dev/null || echo 0)
  if [ "$count" -gt 0 ]; then
    printf "  %4d  %s\n" "$count" "$(basename "$f")"
  fi
done | sort -rn

echo
echo "=== Unique trigger selectors ==="
grep -hroE 'trigger\s*:\s*["'\''][^"'\''']+["'\''']' "$dir" 2>/dev/null \
  | sed -E 's/^trigger\s*:\s*["'\''']?(.+?)["'\''']?$/\1/' \
  | sort -u | head -40

echo
echo "=== Start anchors (start: 'top top', etc.) ==="
grep -hroE 'start\s*:\s*["'\''][^"'\''']+["'\''']' "$dir" 2>/dev/null \
  | sed -E 's/^start\s*:\s*["'\''']?(.+?)["'\''']?$/\1/' \
  | sort | uniq -c | sort -rn | head -15

echo
echo "=== End anchors ==="
grep -hroE 'end\s*:\s*["'\''][^"'\''']+["'\''']' "$dir" 2>/dev/null \
  | sed -E 's/^end\s*:\s*["'\''']?(.+?)["'\''']?$/\1/' \
  | sort | uniq -c | sort -rn | head -15

echo
echo "=== Scrub configurations ==="
grep -hroE 'scrub\s*:\s*(true|false|[0-9.]+)' "$dir" 2>/dev/null \
  | sort | uniq -c | sort -rn

echo
echo "=== Pin configurations ==="
grep -hroE 'pin\s*:\s*(true|false)' "$dir" 2>/dev/null \
  | sort | uniq -c | sort -rn

echo
echo "=== ScrollTrigger callbacks (onEnter / onLeave / onUpdate) ==="
grep -hroE 'on(Enter|EnterBack|Leave|LeaveBack|Update|Refresh|Toggle)\s*:\s*\(?function|\bon(Enter|Leave|Update)\s*:\s*\(?[a-z_]+' "$dir" 2>/dev/null \
  | sort | uniq -c | sort -rn | head -10

echo
echo "When porting, your src/scripts/features/page-anim.ts should contain"
echo "one named helper per unique trigger selector above. Tag every"
echo "ScrollTrigger with 'id: \"page-anim:<name>\"' for safe teardown on"
echo "Barba/ClientRouter transitions."
