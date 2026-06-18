# Forms — detection, integration, fallbacks

Forms are a frequent failure mode. The production page may LOOK like a normal form but be backed by a third-party embed (HubSpot, Marketo, Pardot, Mailchimp), a JS-only validator (Contact Form 7), or a custom POST endpoint. Detect the strategy before porting.

## Detect the strategy

```bash
grep -oE 'wpcf7|contact-form-7' "$work/html/<contact-page>" | head -1 && echo "→ Contact Form 7"
grep -oE 'hbspt\.forms|hsforms\.net' "$work/html/<contact-page>" | head -1 && echo "→ HubSpot"
grep -oE 'munchkin\.js|marketo' "$work/html/<contact-page>" | head -1 && echo "→ Marketo"
grep -oE 'pardot\.com|pi\.pardot' "$work/html/<contact-page>" | head -1 && echo "→ Pardot"
grep -oE 'mailchimp' "$work/html/<contact-page>" | head -1 && echo "→ Mailchimp"
grep -oE 'data-netlify' "$work/html/<contact-page>" | head -1 && echo "→ Netlify Forms"
grep -oE 'formspree\.io|formkeep' "$work/html/<contact-page>" | head -1 && echo "→ Formspree/Formkeep"
grep -oE 'typeform\.com' "$work/html/<contact-page>" | head -1 && echo "→ Typeform embed"
grep -oE '<form[^>]*action="[^"]+"' "$work/html/<contact-page>" | head -1
```

## Per-strategy integration

### HubSpot

Most common in B2B agency / SaaS sites. The markup looks like:

```html
<div id="form_hubspot" data-hs-portal="<PORTAL_ID>" data-hs-form="<FORM_ID>"></div>
```

Stage in BaseLayout:

```astro
<script is:inline async src="//js-na3.hsforms.net/forms/embed/v2.js"></script>
```

Then `features/hubspot.ts`:

```ts
export function initHubspot(): void {
  const target = document.querySelector<HTMLElement>("#form_hubspot");
  if (!target || target.dataset.hsBound === "1") return;
  const portalId = target.getAttribute("data-hs-portal");
  const formId = target.getAttribute("data-hs-form");
  if (!portalId || !formId) return;

  let attempts = 0;
  const tryCreate = () => {
    if (window.hbspt?.forms?.create) {
      window.hbspt.forms.create({
        portalId,
        formId,
        target: "#form_hubspot",
        onFormSubmitted: () => { window.location.href = "/thank-you/"; },
      });
      target.dataset.hsBound = "1";
      return;
    }
    if (attempts++ > 50) return;
    setTimeout(tryCreate, 100);
  };
  tryCreate();
}
```

HubSpot has internal spam protection. **Do not load reCAPTCHA separately.**

### Contact Form 7 (WordPress)

CF7 markup is dense — multi-step, validation, recaptcha integration:

```html
<form action="/wp-json/contact-form-7/v1/contact-forms/<ID>/feedback"
      method="post" class="wpcf7-form" novalidate>
  <input type="hidden" name="_wpcf7" value="<ID>" />
  <input type="hidden" name="_wpcf7_version" value="6.1.1" />
  <input type="hidden" name="_wpcf7_unit_tag" value="..." />
  <!-- field markup -->
</form>
```

**Decision point:**
- **Replica IS going to production** — port CF7 + WPCF7-Redirect + recaptcha verbatim. Substantial. The WP endpoint isn't part of your stack; you need a backend (Astro endpoint, serverless function) to receive POSTs.
- **Replica is a developer study artifact** — preserve the markup (so visual styling renders) but stub the submit handler:

```ts
document.querySelectorAll<HTMLFormElement>("form.wpcf7-form").forEach((form) => {
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    // Optional: redirect to /thank-you/ per the original WPCF7-Redirect plugin
    window.location.href = "/thank-you/";
  });
});
```

### Marketo

```html
<form id="mktoForm_<FORM_ID>"></form>
<script src="//<MUNCHKIN_INSTANCE>.marketo.com/js/forms2/js/forms2.min.js"></script>
<script>MktoForms2.loadForm("//<INSTANCE>.marketo.com", "<MUNCHKIN_ID>", <FORM_ID>);</script>
```

Stage the script in BaseLayout. The `MktoForms2.loadForm` call needs all three IDs from the captured HTML.

### Pardot / Salesforce

```html
<iframe src="https://go.pardot.com/l/<ACCOUNT>/<FORM>" type="text/html"></iframe>
```

Iframe-based. Preserve verbatim. The iframe will only POST to Pardot from the original domain — for a replica running on `localhost:4180`, Pardot will reject submissions. Document this as a known limitation.

### Netlify Forms

```html
<form name="contact" method="POST" data-netlify="true">
  <input type="hidden" name="form-name" value="contact" />
  ...
</form>
```

Native Netlify deployment requirement. If the replica isn't on Netlify, swap to your own backend OR keep the markup and configure on deploy.

### Formspree / Formkeep / similar

```html
<form action="https://formspree.io/f/<FORM_ID>" method="POST">
  ...
</form>
```

Hosted form receivers. Free tier usually fine. Preserve the action URL; submissions still flow to the original mailbox. **Decide with the user** — they may want to swap to their own form receiver to avoid emails going to the original site owner.

### Custom POST endpoint

If `<form action="/api/contact" method="POST">`, the original has a backend. You have three options:

1. **Stub** — preserve markup, intercept submit, redirect to `/thank-you/`.
2. **Astro endpoint** — implement `src/pages/api/contact.ts` (Astro 6 supports SSR endpoints with `output: "server"` or `output: "hybrid"`).
3. **Serverless function** — Vercel / Netlify / Cloudflare Worker.

Default to option 1 for replica work. Option 2/3 only if the user is going to production.

## Multi-step forms (WPCF7-Redirect or similar)

Markup looks like:

```html
<form class="wpcf7-form">
  <div class="wpcf7-redirect_step_1 step is-active">
    <!-- step 1 fields -->
    <button class="wpcf7-redirect_next_step">Next</button>
  </div>
  <div class="wpcf7-redirect_step_2 step">
    <!-- step 2 fields -->
    <button class="wpcf7-redirect_next_step">Next</button>
  </div>
  <div class="wpcf7-redirect_step_3 step">
    <!-- step 3 fields + submit -->
    <button type="submit">Submit</button>
  </div>
</form>
```

Port:

```ts
document.querySelectorAll<HTMLFormElement>("form.wpcf7-form").forEach((form) => {
  const steps = form.querySelectorAll<HTMLElement>(".step");
  let current = 0;

  form.querySelectorAll<HTMLButtonElement>(".wpcf7-redirect_next_step").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      // Optional: validate current step before advancing
      steps[current]?.classList.remove("is-active");
      current = Math.min(current + 1, steps.length - 1);
      steps[current]?.classList.add("is-active");
    });
  });
});
```

## reCAPTCHA

If the original uses reCAPTCHA v3:

```html
<script src="https://www.google.com/recaptcha/api.js?render=<SITE_KEY>"></script>
```

For a replica, you have three options:
1. **Keep it active** — submissions get reCAPTCHA tokens. Original site key works for the original domain only; you may need to register `localhost` in the reCAPTCHA admin.
2. **Stub** — load the script but skip token submission. Validations pass; form goes through.
3. **Skip entirely** — works if your stub doesn't actually submit.

Default to option 3 for replica work.

## Form field styling

The original CSS (loaded via `<link>` in BaseLayout) styles `.wpcf7-form input`, `.wpcf7-form textarea`, `.wpcf7-form button`. If you swap to HubSpot, those rules don't apply — HubSpot renders its own DOM. You'll need to either:

- Add custom CSS targeting HubSpot's `.hs-form` / `.hs-input` classes
- Or let HubSpot's default styling stand

For a faithful replica, prefer to keep the original form provider (CF7 with stubbed submit) so the original styling applies verbatim.

## Anti-patterns

- Don't auto-swap CF7 to HubSpot. Match what the captured HTML shows.
- Don't strip hidden fields (`_wpcf7`, `_wpcf7_version`, etc.) — they're load-bearing for the original styling rules to scope correctly.
- Don't preload form scripts (`<link rel="preload">`). Forms aren't ATF; async load is fine.
- Don't add CAPTCHA where the original didn't have it. Faithful means faithful.
- Don't change action URLs without telling the user — they may have established lead-routing in the original system that the replica would silently break.
