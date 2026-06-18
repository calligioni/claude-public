#!/usr/bin/env node
/**
 * scaffold.mjs — bootstrap an Astro 6 + Tailwind v4 replica project.
 *
 * Usage:
 *   node scaffold.mjs <target-host> <replica-dir>
 *
 * Example:
 *   node scaffold.mjs atolldigital.com /Users/grey/atoll-replica
 *
 * Emits:
 *   - package.json (Astro 6.3.3, Tailwind v4, GSAP/Lenis/Barba/Swiper deps)
 *   - astro.config.mjs (devToolbar disabled, sitemap integration)
 *   - tsconfig.json (strict, path aliases)
 *   - .gitignore
 *   - README.md (provenance + run instructions)
 *   - src/env.d.ts
 *   - src/{components,layouts,pages,scripts,styles,lib}/ empty dirs
 *   - public/favicon.svg (placeholder; replace with real favicon)
 *   - scripts/stage-assets.mjs (asset-staging helper)
 *
 * Saves ~15 minutes per session.
 */

import { mkdir, writeFile, access } from "node:fs/promises";
import { join, resolve, dirname } from "node:path";

const [, , target = "<target>", dir = "./replica"] = process.argv;
const root = resolve(dir);
const host = target.replace(/^https?:\/\//, "").replace(/\/$/, "");

console.log(`==> Scaffolding ${host} replica at ${root}`);

const dirs = [
  "src/components",
  "src/layouts",
  "src/pages",
  "src/scripts",
  "src/scripts/core",
  "src/scripts/features",
  "src/styles",
  "src/lib",
  "public",
  "scripts",
  "notes",
];
for (const d of dirs) {
  await mkdir(join(root, d), { recursive: true });
}

const files = {
  "package.json": JSON.stringify(
    {
      name: `${host.split(".")[0]}-replica`,
      type: "module",
      version: "0.1.0",
      private: true,
      description: `Pixel-faithful Astro replica of ${host}`,
      scripts: {
        dev: "astro dev --port 4180",
        build: "astro build",
        preview: "astro preview --port 4181",
        "stage:assets": "node scripts/stage-assets.mjs",
      },
      dependencies: {
        "@astrojs/sitemap": "^3.7.2",
        "@tailwindcss/vite": "^4.3.0",
        astro: "^6.3.3",
        tailwindcss: "^4.3.0",
      },
      overrides: { vite: "^7.3.3" },
    },
    null,
    2
  ) + "\n",

  "astro.config.mjs": `import { defineConfig } from "astro/config";
import tailwind from "@tailwindcss/vite";
import sitemap from "@astrojs/sitemap";

export default defineConfig({
  site: "https://${host}",
  trailingSlash: "always",
  build: { format: "directory" },
  devToolbar: { enabled: false },
  integrations: [sitemap()],
  vite: { plugins: [tailwind()] },
});
`,

  "tsconfig.json": JSON.stringify(
    {
      extends: "astro/tsconfigs/strict",
      compilerOptions: {
        baseUrl: ".",
        paths: {
          "@/*": ["src/*"],
          "@components/*": ["src/components/*"],
          "@layouts/*": ["src/layouts/*"],
          "@lib/*": ["src/lib/*"],
          "@scripts/*": ["src/scripts/*"],
          "@styles/*": ["src/styles/*"],
        },
      },
      include: [".astro/types.d.ts", "**/*"],
      exclude: ["dist"],
    },
    null,
    2
  ) + "\n",

  ".gitignore": `node_modules/
dist/
.astro/
.env
.env.production
.DS_Store
`,

  "README.md": `# ${host} replica

Pixel-faithful Astro 6 + Tailwind v4 reconstruction of \`${host}\`.

## Run

\`\`\`bash
npm install
npm run dev     # http://localhost:4180
\`\`\`

## Provenance

Reverse-engineered via the [website-replicator](https://github.com/Waiel5/website-replicator) skill from material in \`../<host>_sourcemaps/\`.
`,

  "src/env.d.ts": `/// <reference path="../.astro/types.d.ts" />
`,

  "public/favicon.svg": `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
  <circle cx="12" cy="12" r="10" />
</svg>
`,

  "scripts/stage-assets.mjs": `#!/usr/bin/env node
/* stage-assets.mjs — mirror captured assets into public/ at original URL paths. */
import { mkdir, copyFile, stat, readFile } from "node:fs/promises";
import { dirname, resolve, join } from "node:path";
import { fileURLToPath, URL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPLICA_ROOT = resolve(__dirname, "..");
const PUBLIC_DIR = join(REPLICA_ROOT, "public");
const MANIFEST = resolve(REPLICA_ROOT, "..", "${host.split(".")[0]}_sourcemaps", "static_assets_manifest.tsv");

try {
  const manifest = await readFile(MANIFEST, "utf8");
  const lines = manifest.split("\\n").filter(l => l.trim());
  let copied = 0, skipped = 0;
  for (const line of lines) {
    const parts = line.split("\\t");
    if (parts.length < 3) continue;
    const [, originalUrl, srcPath] = parts;
    let pathname;
    try { pathname = new URL(originalUrl).pathname; } catch { continue; }
    const dstPath = join(PUBLIC_DIR, pathname);
    try {
      const [srcStat, dstStat] = await Promise.all([
        stat(srcPath),
        stat(dstPath).catch(() => null),
      ]);
      if (dstStat && dstStat.size === srcStat.size) { skipped++; continue; }
      await mkdir(dirname(dstPath), { recursive: true });
      await copyFile(srcPath, dstPath);
      copied++;
    } catch {}
  }
  console.log(\`stage-assets: copied=\${copied} skipped=\${skipped} total=\${lines.length}\`);
} catch (err) {
  console.error("Manifest not found. Run discover.sh first.", err.message);
  process.exit(1);
}
`,

  "src/styles/global.css": `@import "tailwindcss";

/* Replace these tokens with your target's :root values (see tokens-and-css.md). */
@theme {
  --color-primary: #000000;
  --color-bg: #ffffff;

  --breakpoint-lg: 1024px;
}

html, body {
  background-color: var(--color-bg);
  color: var(--color-primary);
}
`,

  "src/pages/index.astro": `---
/* Replace with the home page port after running the skill workflow. */
---
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>${host} replica</title>
  </head>
  <body>
    <main>
      <h1>${host} replica — scaffolding complete</h1>
      <p>Next: run the website-replicator skill workflow to port content + chrome + motion.</p>
    </main>
  </body>
</html>
`,
};

for (const [path, content] of Object.entries(files)) {
  const full = join(root, path);
  await mkdir(dirname(full), { recursive: true });
  await writeFile(full, content);
  console.log(`   wrote ${path}`);
}

console.log(`
==> Done.
   cd ${root}
   npm install
   npm run dev

   Then run the skill workflow:
   - Phase 0: detection.md
   - Phase 1: forensics.md  (or run scripts/discover.sh from the skill)
   - Phase 2: scaffold complete (this script)
   - Phase 3+: see SKILL.md
`);
