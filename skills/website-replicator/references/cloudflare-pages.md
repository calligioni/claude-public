# Cloudflare Pages — deep deployment guide

Cloudflare Pages is the recommended default for replica deployment: free tier covers >99% of use cases, global edge, built-in SSL, fast builds, and tight integration with Workers when you need server logic.

## Why CF Pages for replicas specifically

- **Static-first by default** — replicas are mostly static (the Astro build emits a folder of HTML). CF Pages serves them from 300+ POPs with no config.
- **Free tier is generous** — 500 builds/month, unlimited bandwidth, unlimited requests.
- **`_redirects` + `_headers`** files at the project root handle the common deployment tweaks without custom config.
- **Workers for SSR / forms** — when the replica needs an API endpoint (form receiver, dynamic content), Cloudflare Workers integrate natively via Pages Functions.
- **Custom domains** — bring your own; CF handles SSL + DNS.

## Initial setup

### Via Wrangler CLI

```bash
npm install -D wrangler
npx wrangler login            # one-time browser auth
```

Then either deploy manually:

```bash
npm run build
npx wrangler pages deploy dist --project-name <target>-replica
```

Or connect a GitHub repo from the Cloudflare dashboard (recommended — auto-deploys every push):

1. Cloudflare dashboard → Workers & Pages → Create application → Pages → Connect to Git
2. Choose your repo (`Waiel5/<target>-replica`)
3. Build settings:
   - Framework preset: **Astro**
   - Build command: `npm run build`
   - Build output directory: `dist`
   - Root directory (if monorepo): set accordingly
4. Environment variables: add any `import.meta.env` vars (form-receiver API keys, etc.)
5. Deploy

CF Pages auto-detects every branch as a preview deployment; `main` becomes production. PR builds get unique URLs.

## `_redirects` file (project root or `public/`)

Format: `<source> <destination> <status>`. Place at `public/_redirects` so it ships with the build output:

```
# Redirect legacy URLs
/old/services/  /services/  301
/about-us       /creative-montreal-web-agency/  301

# Trailing-slash normalization (CF Pages auto-handles unless explicit override)
/services       /services/  301

# Locale fallback
/fr             /fr/  302

# SPA fallback (Astro static doesn't need this, but if you have a /docs SPA)
/docs/*  /docs/index.html  200

# Legacy 404 → custom 404 page
/*  /404/  404
```

The final wildcard rule with `404` status is the catch-all. It must come last; CF Pages reads top-to-bottom.

## `_headers` file (project root or `public/`)

```
# Long-lived caching for hashed assets
/_astro/*
  Cache-Control: public, max-age=31536000, immutable

/wp-content/themes/*/dist/*
  Cache-Control: public, max-age=31536000, immutable

/assets/*
  Cache-Control: public, max-age=31536000, immutable

/assets/fonts/*
  Cache-Control: public, max-age=31536000, immutable
  Access-Control-Allow-Origin: *

# HTML always revalidates
/*.html
  Cache-Control: public, max-age=0, must-revalidate

# Security headers (apply globally)
/*
  X-Frame-Options: SAMEORIGIN
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  Strict-Transport-Security: max-age=31536000; includeSubDomains; preload

# Allow embedded HubSpot iframes if the contact form needs it
/contact/
  Content-Security-Policy-Report-Only: default-src 'self' https:; script-src 'self' 'unsafe-inline' https://js-na3.hsforms.net https://cdn.jsdelivr.net

# Rive WASM, ScrollyVideo, etc. — modern WebGL/WASM features need
# 'wasm-unsafe-eval' OR drop the CSP entirely
/*
  Content-Security-Policy: default-src 'self' 'unsafe-inline' https: data: blob: 'wasm-unsafe-eval'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' https:; img-src 'self' https: data: blob:; media-src 'self' https: blob:; connect-src 'self' https: wss:; font-src 'self' https: data:; worker-src 'self' blob:
```

The `Access-Control-Allow-Origin: *` on fonts matters if you deploy to a custom domain — without it, browsers reject cross-origin font loads.

## Pages Functions (for forms / dynamic endpoints)

CF Pages can run Workers inline. Create `functions/api/contact.ts`:

```ts
// functions/api/contact.ts
// Runs on CF Workers runtime. Available as /api/contact in production.

interface Env {
  RESEND_API_KEY: string;
}

export const onRequestPost: PagesFunction<Env> = async ({ request, env }) => {
  const data = await request.formData();
  const name = data.get("name");
  const email = data.get("email");
  const message = data.get("message");

  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "noreply@<replica-domain>",
      to: "<recipient>",
      subject: `Contact from ${name}`,
      text: `${name} <${email}>\n\n${message}`,
    }),
  });

  // Redirect to /thank-you/ on success
  return Response.redirect(new URL("/thank-you/", request.url).toString(), 303);
};
```

Set `RESEND_API_KEY` (or whichever secret) in Cloudflare dashboard → Settings → Environment variables (encrypted).

## wrangler.toml for advanced config

```toml
# wrangler.toml at project root
name = "<target>-replica"
compatibility_date = "2026-01-01"
pages_build_output_dir = "dist"

[vars]
PUBLIC_SITE_URL = "https://<replica-domain>"

[[env.production.r2_buckets]]
binding = "ASSETS"
bucket_name = "<target>-replica-assets"

[[env.production.kv_namespaces]]
binding = "RATE_LIMIT"
id = "<kv-id>"
```

Bindings (R2, KV, D1, Durable Objects, Queues) become available on `env` inside Pages Functions.

## SSR vs static for Nuxt-style targets

If you're porting Nuxt 3 → Astro and the original used SSR for personalization or i18n routing:

```js
// astro.config.mjs
import cloudflare from "@astrojs/cloudflare";

export default defineConfig({
  output: "server",
  adapter: cloudflare({
    mode: "advanced",   // generates _worker.js
    runtime: { mode: "local", type: "pages" },
  }),
});
```

CF Pages will detect `_worker.js` and run it on every request. Static assets in `dist/` continue to serve from edge cache.

For most replicas, **stick with static `output: "static"`**. Only switch when you genuinely need server logic per request.

## Custom domain

1. Cloudflare dashboard → Pages → your project → Custom domains → Set up a custom domain
2. Enter the domain (`replica.example.com` or apex `example.com`)
3. Cloudflare auto-creates DNS records (CNAME for subdomains, CNAME flattening for apex)
4. SSL provisions in ~60 seconds

If the domain is registered elsewhere, point its DNS to Cloudflare nameservers OR add a CNAME pointing at `<project>.pages.dev`.

## R2 for large media

Replicas with heavy media (`.glb`, `.mp4`, `.webm` >5MB each) hit CF Pages' per-file 25MB cap. Move to R2:

```bash
npx wrangler r2 bucket create <target>-replica-assets
npx wrangler r2 object put <target>-replica-assets/textures/Textures.glb --file=public/assets/webgl/Textures.glb
```

Then expose via a Pages Function or public R2 URL. Update HTML to use the R2 URL.

## Cloudflare Images

Production sites with many WebP/AVIF variants benefit from Cloudflare Images:

```
https://imagedelivery.net/<account-hash>/<image-id>/<variant>
```

Upload via Wrangler, generate variants on-the-fly. Useful for portfolio sites with 100+ project images.

## Build settings checklist

For the CF Pages dashboard:

- [ ] **Framework preset:** Astro
- [ ] **Build command:** `npm run build`
- [ ] **Build output directory:** `dist`
- [ ] **Root directory:** `/` (or repo subdir if monorepo)
- [ ] **Node version:** 20 (set via `NODE_VERSION=20` env var)
- [ ] **Build comments on PRs:** enabled
- [ ] **Preview branch deployments:** enabled
- [ ] **Production branch:** `main`
- [ ] **Always use latest framework version:** disabled (lock to your tested Astro 6.3.x)

## Performance budgets

Aim for these on the CF Pages preview URL via Lighthouse mobile throttle:

| Metric | Target |
|---|---|
| FCP | <1.5s |
| LCP | <2.5s |
| TBT | <200ms |
| CLS | <0.05 (replicas often hit this thanks to fixed preloader chrome) |
| SI | <3.5s |
| Total page size | <600KB gz |

If the home page exceeds the budget because of the Three.js bundle, defer-load it:

```astro
<script
  slot="head"
  type="module"
  src="/wp-content/themes/<theme>/dist/app-<HASH>.js?ver=1.0.0"
  is:inline
  defer
></script>
```

Or move to a deferred client:idle Astro island.

## Troubleshooting

**Build fails with "Cannot find module '@astrojs/cloudflare'"** — install the adapter explicitly: `npm install -D @astrojs/cloudflare`.

**Build OK but pages 404 in production** — check that `dist/` actually has the HTML at the expected path. CF Pages serves `/some-route/` from `dist/some-route/index.html` if `build.format: "directory"` (which the skill defaults to).

**HubSpot iframe blocked** — add the CSP override above to `_headers`.

**Font CORS errors** — add `Access-Control-Allow-Origin: *` to `/assets/fonts/*`.

**Preview branch deployments are slow** — disable image optimization for preview branches via Pages settings.

**Form posts fail in production** — set the secret env vars in CF dashboard (not just `.env.local`).

## Anti-patterns

- Don't commit `wrangler.toml` with secrets — use dashboard env vars
- Don't put `_redirects` rules that conflict (CF reads top-to-bottom; later rules with same source are dead)
- Don't mix `output: "static"` with Pages Functions on the same project — pick one
- Don't deploy without a `404.html` — CF Pages will serve a generic CF page on missing routes
- Don't enable Cloudflare's Auto Minify on JS — it can break Astro's hashed-filename output
