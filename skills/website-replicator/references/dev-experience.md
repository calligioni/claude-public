# Developer experience — the "feels like home" checklist

The skill exists to produce a replica another developer can clone, read, and confidently modify. A pixel-faithful replica that's impossible to navigate is half a deliverable. This reference is the standard the output must meet.

## The fresh-clone test

Before declaring a replica "done," verify a fresh-clone path works:

```bash
git clone <replica-repo> /tmp/fresh-clone
cd /tmp/fresh-clone
npm install      # ≤90 seconds, no warnings beyond engine peer-dep notes
npm run build    # ≤5 seconds, clean
npm run dev      # ≤2 seconds boot; localhost:4180 shows the home page
```

If any step takes longer or errors, fix before shipping. This is the *single most important* dev-experience metric.

## File organization standards

```
<target>-replica/
├── README.md                       provenance + run + deploy
├── package.json                    minimal deps, no leftover noise
├── astro.config.mjs                short, commented for non-obvious choices
├── tsconfig.json                   strict; path aliases for every src/ dir
├── .gitignore                      Astro defaults + .DS_Store
├── .editorconfig                   tabs vs spaces consistent
├── .nvmrc                          pinned Node version
├── scripts/
│   └── stage-assets.mjs            asset staging helper (commented)
├── public/                         static assets at original URL paths
├── src/
│   ├── env.d.ts
│   ├── components/                 reusable UI components
│   │   ├── Header.astro
│   │   ├── Footer.astro
│   │   ├── Logo.astro
│   │   ├── Preloader.astro
│   │   └── sections/               per-page section components
│   │       └── home/
│   ├── layouts/
│   │   ├── BaseLayout.astro        doc-commented at top
│   │   └── SiteLayout.astro
│   ├── pages/                      file-routing
│   ├── scripts/                    feature-organized TS modules
│   │   ├── index.ts                 entry + per-namespace dispatcher
│   │   ├── env.ts                   isDesktop, getLangCode, etc.
│   │   ├── core/                    foundation
│   │   │   ├── scroll.ts            Lenis singleton
│   │   │   ├── transitions.ts       Barba init + page-transition timeline
│   │   │   ├── splitText.ts
│   │   │   ├── loader.ts
│   │   │   └── cursor.ts
│   │   └── features/                feature modules
│   │       ├── nav.ts
│   │       ├── sliders.ts
│   │       ├── forms.ts
│   │       └── ...
│   ├── styles/
│   │   ├── global.css               Tailwind + theme
│   │   └── tokens.css               :root variables + @font-face
│   └── lib/                         pure data / utilities (no DOM)
└── notes/                          per-session audit notes (gitignored OK)
```

Every directory has a clear purpose. New developers find what they're looking for in one guess.

## Naming conventions

- **Files:** kebab-case (`page-anim.ts`, `home-webgl.ts`, `text-scramble.ts`)
- **Astro components:** PascalCase (`Header.astro`, `HomeMobileMenu.astro`)
- **TS exports:** camelCase (`initNav`, `getScroll`, `measureHidden`)
- **TS types:** PascalCase (`WebglState`, `PageType`, `LoadResponse`)
- **CSS classes:** preserve original verbatim (often kebab-case Tailwind-flavored or snake_case from the source CMS)
- **Branches:** `feature/X`, `fix/X`, `chore/X` — Conventional Commits

## Comment policy

Comments answer WHY, not WHAT. The code itself says WHAT.

✅ **Good — explains a non-obvious decision:**

```ts
// jQuery's `.css("height")` returns the COMPUTED value even on
// display:none elements. We need that here because #sticky_top_height
// has the `hidden` attribute, and our project-card collapse target
// depends on its CSS height (~114px), not the rendered rect (0).
const projectSmallHeight = measureHidden("#sticky_top_height", "height");
```

❌ **Bad — restates the code:**

```ts
// Get the height of sticky_top_height
const projectSmallHeight = measureHidden("#sticky_top_height", "height");
```

Per-file doc comments at the top of every TS file:

```ts
/**
 * features/text-scramble.ts
 * -------------------------
 * The "let's discuss your <X> next" word-scramble effect that sits above
 * the footer on every page except the home, contact, and legal pages.
 *
 * Markup contract (already in every captured HTML):
 *   <div id="text_scrumble" data-phrases="project,idea,success,">...</div>
 *
 * Port of `textScrumbleAnimation()` + `TextScramble` class from
 * `theme-assets-main.pretty.js` lines 1635–1704.
 */
```

This is the contract — every file declares its purpose, its DOM contract, its source.

## TypeScript strict mode

`tsconfig.json` MUST extend `astro/tsconfigs/strict`. Any `// @ts-ignore` needs a comment explaining why:

```ts
// @ts-ignore — Three.js bundle's Vector3 global isn't in @types/three; we
// consume from window.* per home-webgl.ts contract documented at top.
const v = new window.Vector3();
```

Prefer narrowing over `any`. When a value's type is genuinely unknown, use `unknown` + a type guard.

## Path aliases

Make every import readable:

```ts
// ❌ ../../../components/Logo.astro
import Logo from "../../../components/Logo.astro";

// ✅ @components/Logo.astro
import Logo from "@components/Logo.astro";
```

`tsconfig.json`:

```json
{
  "paths": {
    "@/*": ["src/*"],
    "@components/*": ["src/components/*"],
    "@layouts/*": ["src/layouts/*"],
    "@lib/*": ["src/lib/*"],
    "@scripts/*": ["src/scripts/*"],
    "@styles/*": ["src/styles/*"]
  }
}
```

## README requirements

The repo README answers three questions in the first 30 seconds:

1. What is this? (one paragraph)
2. How do I run it? (one code block)
3. How do I deploy it? (link to deployment.md or section)

Plus a "Provenance" section that tells the next developer:
- Where it came from (the original site)
- What the skill was that produced it (link to website-replicator)
- What's a faithful copy vs what's adapted
- Known limitations (e.g., contact form stubbed, original WebGL bundle shipped as-is)

```markdown
# <target>-replica

Pixel-faithful Astro 6 + Tailwind v4 reconstruction of `<target>.com`.

## Run

\`\`\`bash
npm install
npm run dev    # http://localhost:4180
\`\`\`

## Deploy (Cloudflare Pages)

\`\`\`bash
npx wrangler pages deploy dist --project-name <target>-replica
\`\`\`

See `references/cloudflare-pages.md` for the full deployment guide.

## Provenance

Built via [website-replicator](https://github.com/Waiel5/website-replicator)
skill from `<target>.com` captured on <DATE>.

**Faithful:** chrome, motion, content, color palette, typography stack.
**Adapted:** contact form stubbed (original used <ORIGINAL-PROVIDER>);
analytics removed.

## Known limitations

- Home Three.js scene ships the original Vite bundle (567KB) as-is —
  rebuild against npm `three` for a cleaner port.
- Contact form is decorative until you wire a backend endpoint.
- No CMS — pages are static. Edit content via the `src/pages/*.astro` files.
```

## .editorconfig

```ini
# .editorconfig
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false
```

## Prettier config (optional but recommended)

```json
// .prettierrc
{
  "tabWidth": 2,
  "semi": true,
  "singleQuote": false,
  "trailingComma": "all",
  "printWidth": 80
}
```

## Commit message format

Conventional Commits. Each commit message tells the next developer WHY:

```
fix(atoll-replica): preloader runs on localhost; project-card collapse measures display:none reliably

Two genuine bugs that explained why the user was still seeing the same
three issues after my "fix" commits.

1. The dev-server preloader bypass was too greedy.
   transitions.ts had `isLocalhost()` matching `localhost`, `127.0.0.1`,
   AND `1atoll.loc:8888`. ...

2. measureHidden() replaces computedH/W with a real DOM swap.
   ...
```

Subject line: type(scope): short description. Body: WHY this commit exists, not WHAT it changed (diff says that).

## "Definition of Done" checklist

Before declaring a replica complete:

- [ ] `npm install && npm run build` succeeds in ≤30 seconds on a fresh clone
- [ ] `npm run dev` boots in ≤2 seconds; localhost:4180 shows the home page
- [ ] Every public route returns HTTP 200
- [ ] No `console.log` / `debugger` in production JS
- [ ] No localhost / staging URLs in HTML attributes
- [ ] Asset URLs resolve (no 404s in browser console)
- [ ] Lighthouse desktop a11y ≥90, performance ≥85, best-practices ≥90
- [ ] All hreflang declarations point at valid URLs in the replica's domain
- [ ] All ScrollTrigger setups respect `prefers-reduced-motion: reduce`
- [ ] Forms submit (or are intentionally stubbed with a documented stub)
- [ ] No `// @ts-ignore` without an explaining comment
- [ ] Every `src/scripts/**/*.ts` file has a doc comment at the top
- [ ] README has Run + Deploy + Provenance sections
- [ ] Repo has a GitHub Actions / CF Pages preview deploy
- [ ] `.editorconfig`, `.gitignore`, `.nvmrc` present
- [ ] Notes folder has audit screenshots from at least one visual verification pass
- [ ] At least one commit per phase; git history is readable

## Anti-patterns

- Don't ship code with TODO/FIXME without an issue link
- Don't auto-format on every save without telling the user — `prettier --write src/**/*` once at the end is fine; constant churn isn't
- Don't ship `.env` (use `.env.local` and `.env.example`)
- Don't include `node_modules/` in commits (it happens more than you'd think)
- Don't add 47 dependencies for the "DX" — minimal scope means minimal bug surface
- Don't generate code that has comments saying "This was generated by AI" — they read as confused; just write good code

## Anti-anti-pattern

- DO commit notes/ and screenshots from audit passes — they're forensic history
- DO commit per-page audit reports — future devs benefit
- DO leave the `recovered_sources/` / `recovered_readable/` material in a sibling directory with its own README so future audits can re-reference

## The "stranger test"

A developer who's never seen the original site clones your replica and reads `src/scripts/features/page-anim.ts`. Within 60 seconds, they should know:

- What this file does
- What DOM elements it expects
- What gets called when
- Where the original logic lived

If the file fails that test, comment it more or restructure it.

That's dev-friendly.
