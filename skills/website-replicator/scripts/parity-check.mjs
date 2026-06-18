#!/usr/bin/env node
/**
 * parity-check.mjs — diff captured production HTML against rendered replica
 * HTML, surface missing classes / data-attributes / asset URLs.
 *
 * Usage:
 *   node parity-check.mjs <captured-html-file> <rendered-replica-url-or-file>
 *
 * Example:
 *   node parity-check.mjs <work>/<target>_sourcemaps/html/services.html.abc \\
 *                         http://localhost:4180/services/
 *
 * Outputs a punch list of:
 * - Classes present in captured but missing in replica
 * - data-* attributes present in captured but missing in replica
 * - Asset URLs (src/href) in captured but not resolving in replica
 * - Headings present in captured but not in replica
 */

import { readFile } from "node:fs/promises";

const [, , capturedPath, replicaSource] = process.argv;
if (!capturedPath || !replicaSource) {
  console.error("usage: parity-check.mjs <captured-html-file> <rendered-replica-url-or-file>");
  process.exit(1);
}

async function fetchOrRead(source) {
  if (source.startsWith("http")) {
    const res = await fetch(source);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.text();
  }
  return readFile(source, "utf8");
}

const captured = await fetchOrRead(capturedPath);
const replica = await fetchOrRead(replicaSource);

function inventory(html) {
  return {
    classes: new Set(
      [...html.matchAll(/class="([^"]+)"/g)]
        .flatMap((m) => m[1].split(/\s+/))
        .filter(Boolean),
    ),
    dataAttrs: new Set(
      [...html.matchAll(/\bdata-[a-z][a-z0-9-]*/g)].map((m) => m[0]),
    ),
    ids: new Set(
      [...html.matchAll(/\bid="([^"]+)"/g)].map((m) => m[1]),
    ),
    assets: new Set(
      [...html.matchAll(/(?:src|href)="([^"]+\.(?:js|css|png|jpg|jpeg|webp|svg|mp4|webm|woff2|otf|glb|json))"/g)].map((m) => m[1]),
    ),
    headings: new Set(
      [...html.matchAll(/<h[1-6][^>]*>([^<]+)<\/h[1-6]>/g)].map((m) => m[1].trim()),
    ),
  };
}

const cap = inventory(captured);
const rep = inventory(replica);

function diff(label, capSet, repSet) {
  const missing = [...capSet].filter((x) => !repSet.has(x));
  if (!missing.length) {
    console.log(`✅ ${label}: all ${capSet.size} present`);
    return;
  }
  console.log(`\n🔴 ${label}: ${missing.length} of ${capSet.size} missing in replica`);
  for (const m of missing.slice(0, 25)) console.log(`   - ${m}`);
  if (missing.length > 25) console.log(`   ... + ${missing.length - 25} more`);
}

console.log(`\nParity check: ${capturedPath} → ${replicaSource}\n`);

diff("Classes", cap.classes, rep.classes);
diff("data-* attributes", cap.dataAttrs, rep.dataAttrs);
diff("IDs", cap.ids, rep.ids);
diff("Asset URLs", cap.assets, rep.assets);
diff("Heading texts (verbatim)", cap.headings, rep.headings);

console.log("\nUse this output to prioritize fix passes:");
console.log("- Missing data-* attributes break motion hooks → highest priority");
console.log("- Missing IDs break JS gating (animationOnPageLoad sentinels)");
console.log("- Missing classes may break state CSS or motion targets");
console.log("- Missing asset URLs are 404s in dev (open browser console to confirm)");
console.log("- Missing headings = body content drift");
