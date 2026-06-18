# Phase 2 — Scaffold the stack

This phase produces a working Astro 6 + Tailwind v4 + Vite 7 project that builds clean before any porting happens. Skip the project-template generators — they bring in dependencies you don't need.

## Decision: where does the replica live?

Three options:

1. **Sibling folder under the original alarinesite repo** (`/Users/.../alarinesite/<target>-replica/`). Use when the host repo is where the work was scoped. Pro: keeps forensic mirror nearby. Con: cluttered git history if you mix commits.
2. **Standalone folder** (`/Users/.../<target>-replica/`). Use when this is its own project.
3. **Both**: do work in option 1 (sibling), then `git subtree split --prefix=<target>-replica -b <target>-only` to extract to a standalone repo when ready. This is what produced the atoll-replica session's GitHub repo.

## Files to create

```
<target>-replica/
├── package.json
├── astro.config.mjs
├── tsconfig.json
├── README.md
├── .gitignore
├── scripts/
│   └── stage-assets.mjs          # copies <work>/<target>_sourcemaps/static_assets → public/
├── public/
│   ├── favicon.svg               # extract a simple glyph from the brand
│   └── (assets staged later)
└── src/
    ├── env.d.ts
    ├── components/
    ├── layouts/
    ├── pages/
    ├── scripts/
    ├── styles/
    └── lib/
```

## package.json

```json
{
  "name": "<target>-replica",
  "type": "module",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "astro dev --port 4180",
    "build": "astro build",
    "preview": "astro preview --port 4181",
    "stage:assets": "node scripts/stage-assets.mjs"
  },
  "dependencies": {
    "@astrojs/sitemap": "^3.7.2",
    "@tailwindcss/vite": "^4.3.0",
    "astro": "^6.3.3",
    "tailwindcss": "^4.3.0"
  },
  "overrides": {
    "vite": "^7.3.3"
  }
}
```

Add runtime libs ONLY after you grep the captured HTML for what's actually loaded. Common additions (with version-matching from the original CDN URLs):

```json
{
  "dependencies": {
    "@barba/core": "2.9.7",
    "gsap": "3.12.5",
    "lenis": "1.1.18",
    "swiper": "^11.0.0",
    "three": "^0.170.0"
  },
  "devDependencies": {
    "@types/three": "^0.170.0"
  }
}
```

The version numbers come from grep'ing the production HTML — for example `<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/...">`.

## astro.config.mjs

```js
import { defineConfig } from "astro/config";
import tailwind from "@tailwindcss/vite";
import sitemap from "@astrojs/sitemap";

export default defineConfig({
  site: "https://<target>.local",
  trailingSlash: "always",       // most CMS sites use trailing-slash URLs
  build: { format: "directory" },
  /* Disable Astro 6's dev-toolbar. Its /@id/astro/runtime/client/
     dev-toolbar/entrypoint.js sometimes returns 504 with no
     Content-Type, which the browser then refuses to load as a JS module
     ("disallowed MIME type") and blocks the rest of the page. */
  devToolbar: { enabled: false },
  integrations: [sitemap()],
  vite: { plugins: [tailwind()] },
});
```

## tsconfig.json

```json
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"],
      "@layouts/*": ["src/layouts/*"],
      "@lib/*": ["src/lib/*"],
      "@scripts/*": ["src/scripts/*"],
      "@styles/*": ["src/styles/*"]
    }
  },
  "include": [".astro/types.d.ts", "**/*"],
  "exclude": ["dist"]
}
```

## scripts/stage-assets.mjs

Mirrors every captured static asset into `public/` at its original URL path. Idempotent.

```js
import { mkdir, copyFile, stat, readFile } from "node:fs/promises";
import { dirname, resolve, join } from "node:path";
import { fileURLToPath, URL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPLICA_ROOT = resolve(__dirname, "..");
const PUBLIC_DIR = join(REPLICA_ROOT, "public");
const MANIFEST = resolve(REPLICA_ROOT, "..", "<target>_sourcemaps", "static_assets_manifest.tsv");

const manifest = await readFile(MANIFEST, "utf8");
const lines = manifest.split("\n").filter((l) => l.trim());

let copied = 0, skipped = 0;
for (const line of lines) {
  const [, originalUrl, srcPath] = line.split("\t");
  if (!originalUrl || !srcPath) continue;
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
  } catch { /* noop */ }
}
console.log(`stage-assets: copied=${copied} skipped=${skipped} total=${lines.length}`);
```

Run with `node scripts/stage-assets.mjs`. This preserves WordPress-style URLs like `/wp-content/uploads/2025/02/Group-2477.png` so captured HTML resolves natively.

## Index page sentinel

Add a placeholder `src/pages/index.astro` that imports BaseLayout (when it exists) and renders the brand wordmark. This proves the dev server boots cleanly before any porting.

## Initial verify

```bash
npm install
npm run build
npm run dev
# curl -sI http://localhost:4180/ should return HTTP 200
```

If anything fails here, fix before proceeding. A clean build is the floor; everything else builds on it.

## Anti-patterns

- Don't add runtime libs you don't yet know are used — grep the captured HTML for CDN URLs first
- Don't use Astro's CLI to scaffold (`npm create astro`) — too much default scaffolding to remove
- Don't enable Astro's integration for React/Vue/Svelte unless the original site uses them (rare in WordPress/Webflow targets)
- Don't set up Storybook, testing frameworks, or linters at this stage — they're noise until there's something to test
