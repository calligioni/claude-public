# Deployment

The skill ends with a working local replica. Deployment turns it into a live URL. Three classes of target:

| Class | Examples | Use when |
|---|---|---|
| **Static-first** | Cloudflare Pages, Netlify, Vercel, GitHub Pages | Replica has no backend (typical). Free or cheap. |
| **Edge + SSR** | Cloudflare Workers, Vercel, Netlify Edge | Replica needs form receivers, ISR, dynamic content. |
| **Self-hosted** | DigitalOcean, Fly.io, Hetzner + Caddy | Full control. Useful for replicas with custom backend logic. |

Astro 6 supports all three modes via output adapters.

## Static-first (recommended default)

Most replicas need no backend — Astro builds a folder of HTML/CSS/JS and any static host serves it.

```js
// astro.config.mjs
export default defineConfig({
  output: "static",  // default
  site: "https://<replica-domain>",
  build: { format: "directory" },
});
```

### Cloudflare Pages

```bash
npm install -D wrangler
npx wrangler pages deploy dist --project-name <target>-replica
```

Or via the dashboard: connect the GitHub repo, set build command `npm run build`, set output directory `dist/`.

Custom domain: add via Cloudflare's DNS. Cloudflare also handles cache, SSL, and image optimization for free.

### Netlify

```toml
# netlify.toml
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/old-url/*"
  to = "/new-url/:splat"
  status = 301
```

Push to GitHub, link in Netlify dashboard. Custom domain via DNS.

### Vercel

```bash
npm install -g vercel
vercel
```

Auto-detects Astro 6. Custom domain via DNS.

### GitHub Pages

```bash
# astro.config.mjs
site: "https://<USER>.github.io/<repo>/",
base: "/<repo>/",
```

Push to `gh-pages` branch via `actions/checkout` + `actions/deploy-pages`. Limited features but free.

## SSR if you need it

If the replica's contact form posts to a custom endpoint, or you need geo-targeted content, or per-user data:

```js
// astro.config.mjs
import vercel from "@astrojs/vercel";

export default defineConfig({
  output: "server",
  adapter: vercel(),
});
```

Adapters for each host: `@astrojs/vercel`, `@astrojs/netlify`, `@astrojs/cloudflare`, `@astrojs/node`, `@astrojs/deno`.

## Form receivers

If the contact page submits to `/api/contact`, implement as an Astro endpoint:

```ts
// src/pages/api/contact.ts
import type { APIRoute } from "astro";

export const POST: APIRoute = async ({ request }) => {
  const data = await request.formData();
  const name = data.get("name");
  const email = data.get("email");
  const message = data.get("message");

  // Forward to email service (Resend, Postmark, SendGrid, etc.)
  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${import.meta.env.RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "noreply@<replica-domain>",
      to: "<recipient>",
      subject: `Contact from ${name}`,
      text: `${name} <${email}>\n\n${message}`,
    }),
  });

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};
```

Need `output: "server"` or `output: "hybrid"` in astro.config + an SSR adapter.

## Pre-deploy checklist

Before pushing live:

- [ ] `npm run build` clean (no warnings beyond known chunk-size advisories)
- [ ] `npm run preview` renders all routes correctly
- [ ] Pa11y / axe-core sweep — no critical accessibility violations
- [ ] Lighthouse desktop + mobile each scoring ≥90 on a11y + best practices
- [ ] All HTML pages return 200 in `dist/` (none missing)
- [ ] `dist/sitemap-index.xml` and `dist/sitemap-0.xml` present
- [ ] `dist/robots.txt` present and matches expected indexing policy
- [ ] All hreflang declarations point at valid URLs
- [ ] Form endpoints (if any) tested with real submissions
- [ ] OG / Twitter card meta tags valid (use https://opengraph.xyz/)
- [ ] Favicon files render at every required size (16, 32, 192, 512)
- [ ] No `console.log` / `debugger` statements in production JS
- [ ] No localhost / staging URLs in HTML attributes
- [ ] Asset URLs don't point at the original production site

## SEO parity

A pixel-faithful replica that ships broken SEO isn't faithful. Verify:

- **Canonical URLs** point at the replica's domain, not the original
- **hreflang** declarations updated to the replica's URLs
- **Schema.org JSON-LD** matches the production site's structured data (if any)
- **OG / Twitter** image URLs point at the replica's `/wp-content/uploads/...` paths, not the original

Quick check:

```bash
curl -sL https://<replica-domain>/ | grep -oE '<(meta|link|script)[^>]*>' | grep -iE 'canonical|hreflang|og:|twitter:|json-ld'
```

## Custom 404

Astro generates a default 404. Replace with one that matches the original's design:

```astro
---
// src/pages/404.astro
import SiteLayout from "@layouts/SiteLayout.astro";
---

<SiteLayout
  title="Page Not Found"
  description="The page you're looking for doesn't exist."
  pageType="error"
>
  <section class="min-h-screen flex items-center justify-center">
    <div class="text-center">
      <h1 class="font_editorial text-[12vw] lg:text-[8vw]">404</h1>
      <p class="mt-[var(--size-20)]">page not found</p>
      <a href="/" class="mt-[var(--size-20)] inline-block underline">back home</a>
    </div>
  </section>
</SiteLayout>
```

Each static host handles 404s slightly differently — Cloudflare Pages and Netlify auto-serve `dist/404.html`; Vercel requires `vercel.json` config.

## Environment variables

If your endpoints need secrets (form-receiver API keys, analytics tokens):

```ini
# .env.local (gitignored)
RESEND_API_KEY=...
PLAUSIBLE_DOMAIN=...
```

Access via `import.meta.env.VAR_NAME`. Set the same vars in your host's dashboard.

## Performance

Astro 6 + Tailwind v4 + Vite 7 produces optimized output by default, but verify:

- **Total bundle size** under 600KB gzipped (the original Three.js bundle is the heavyweight)
- **LCP** under 2.5s on 4G throttle (Lighthouse mobile)
- **CLS** under 0.1 (load-bearing for the preloader → content transition)
- **TBT** under 200ms (large JS bundles fail this)

If failing:
- Move the home Three.js bundle to lazy-load AFTER first paint
- Add `loading="lazy"` to all images below the fold
- Generate WebP / AVIF responsive sizes via `@astrojs/image` or `astro:assets`
- Preconnect to font hosts: `<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>`

## CDN / edge caching

Static assets benefit from long cache TTLs. Most hosts auto-configure:

```
/_astro/*    → Cache-Control: public, max-age=31536000, immutable
/*.html      → Cache-Control: public, max-age=0, must-revalidate
```

For custom configuration:

```toml
# netlify.toml
[[headers]]
  for = "/_astro/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

## Anti-patterns

- Don't deploy with the original production domain in canonical URLs — search engines will route traffic to the original.
- Don't ship `import.meta.env` secrets into client code. Only use them server-side.
- Don't enable analytics that the user doesn't own (e.g. don't leave the original's GA tag firing).
- Don't auto-redirect old URLs without consulting the user — they may have established SEO that depends on the existing URL shape.
- Don't deploy without `robots.txt` + `sitemap-index.xml` in `dist/`.
