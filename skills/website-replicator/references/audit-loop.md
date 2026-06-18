# Phase 10 — Multi-pass audit loop

A clean `npm run build` is necessary but never sufficient. The audit loop is what catches silent-failure animations, fidelity drift, and dead JS that the build process can't see. Run at least once; ideally three times with iteration in between.

## The three parallel audit agents

Dispatch these simultaneously (single message, multiple Agent tool calls) after each major batch of work lands:

### 1. Visual verification (Playwright + measurements)

Use a Playwright-capable agent. Brief:

```
Compare the replica at http://localhost:4180/ against the captured original.
Take screenshots at desktop 1440x900 and mobile 390x844 for these routes:
- / (home)
- /services/ index
- /services/<first-detail>
- /work/ index
- /work/<first-detail>
- /articles/ index
- /articles/<first-detail>
- /contact/
- /<about-slug>/
- /fr/ index
- /fr/<first-detail>

For each: ATF screenshot + full-page screenshot.

Verify (with concrete measurements via page.evaluate):
- body.backgroundColor === "rgb(240, 241, 244)"  (or whatever the original ships)
- font on H1
- console errors (capture as text)
- 404s on any image / font / script URL
- Whether the loader animation visibly ran (compare T=0 to T=2000ms screenshots)
- Whether click-driven transitions show the FLIP wordmark (click a nav link, capture during 1.5s window)
- For scroll-driven collapses: measure .item__project element height after scroll past — should match #sticky_top_height value, NOT 0

Save to <work>/visual-audit/v<N>/.
Return: punch list of CRITICAL / MODERATE / MINOR drifts.
```

### 2. Code review

Use a code-review agent. Brief:

```
Review all code on the current branch since <BASE_COMMIT> in <replica-root>/src/.

Focus:
1. TypeScript hygiene — any/ts-ignore that should be tightened, missing types on exported APIs.
2. Astro idioms — components that should be Astro but are full-client, places where client:idle/visible directives should appear.
3. Separation of concerns — features/* vs core/*.
4. Dead code / stubs — components defined but never imported.
5. Naming consistency — kebab-case vs PascalCase file names.
6. Comments — WHAT vs WHY.
7. Idempotency on Barba transitions — features that mount listeners.
8. Asset references hardcoded vs centralized.
9. Accessibility — missing aria-*, missing alt, focus traps.
10. Performance — passive listeners on scroll, cached querySelectorAll.
11. prefers-reduced-motion respect.
12. Original-site behaviour preservation — easing strings not rewritten.

Return a markdown punch list grouped:
🔴 Must fix (bugs, broken assumptions)
🟡 Should fix (smells, weak types)
🟢 Suggestions (DX polish)

Be ruthless — don't manufacture concerns, only flag what's worth fixing.
```

### 3. Mirror diff

Use a general-purpose agent. Brief:

```
Diff captured original HTML vs rendered replica HTML for each major route.

For each route:
- Walk top-to-bottom in original <body>; for each major section, verify
  a matching element exists in replica
- Compare 3 representative element class attributes per section
- Diff data-* attribute inventory between original and replica
- Check every src/href in original; verify the replica's equivalent
  resolves (HTTP 200)
- Spot-check H1/H2/button text for verbatim preservation

Use grep efficiently:
- grep -oE 'class="[^"]*"' file | sort -u
- grep -oE 'data-[a-z-]+' file | sort -u
- grep -oE '<h[1-6][^>]*>[^<]*</h[1-6]>' file
- grep -oE '(src|href)="[^"]*\.(png|webp|svg|mp4|woff2|json)"' file

Return markdown punch list grouped:
🔴 Missing sections / major copy gaps
🟡 Missing classes / data-attrs (motion hooks)
🟢 Missing assets (404s)
🟢 Head metadata gaps

Save findings to <work>/page-audit/per-page.md.
```

## Process the findings

When all three agents return:

1. **Cross-reference.** Issues flagged by multiple agents are highest priority.
2. **Group by file.** If three issues all touch `Header.astro`, fix them in one pass.
3. **Categorize:**
   - **Code:** TypeScript/Astro fixes (silent failures, idempotency)
   - **Content:** missing markup, dropped attributes
   - **CSS:** missing state rules, wrong cascade order
   - **External:** missing scripts (HubSpot, SplitText, Lottie)
   - **Pitfalls:** anything in `pitfalls.md` — known patterns
4. **Apply fixes systematically.** Commit each category as one commit so history is readable.
5. **Re-run all three agents.** Compare to previous iteration via `--previous-workspace` flag if using a benchmark viewer.

## When to stop iterating

Stop when at least two of:
- All three audit agents return mostly PASS / no CRITICAL
- The user says it looks right when they refresh
- You've iterated 3+ times with diminishing-return fixes
- You've covered every item in `pitfalls.md` that applies

Don't iterate forever. Diminishing returns set in around iteration 3-4.

## The "user sends a screenshot showing it's still wrong" loop

The user is the ultimate audit. When they send a screenshot showing something off:

1. Don't argue — they're using the actual product
2. Map the visible symptom to a probable cause (consult `pitfalls.md` first)
3. Curl the live original CSS (`WebFetch`) to verify what the production actually ships if it's a CSS issue
4. Apply the targeted fix
5. Commit with a clear message that links the symptom to the cause

This is more efficient than another full audit pass for one issue.

## What can't be caught by automated audits

- Subjective "feel" of motion timing
- Whether a specific easing curve matches the original
- Mobile-specific behaviour (audits typically run desktop-first)
- Hover states — Playwright can simulate but timing is brittle
- Page transitions in slow motion — eyeballing the FLIP at 1.5x speed is the real test

Reserve human review for these.

## Audit cadence within a session

Roughly:

1. After scaffold + tokens land — do a quick build-check + visit `/`. No audit yet, just sanity.
2. After Wave 1 (chrome + JS modularization + first 5 routes) — first full audit (all 3 agents).
3. After Wave 2 (remaining route ports) — second audit. Focus on cross-page chrome consistency.
4. After integration fixes (audit findings applied) — third audit. Should be mostly PASS.
5. When the user signals "this feels right" or sends a final clear screenshot — stop.

Each audit cycle is ~10 minutes of agent time + 5-15 minutes of integration. Don't skip them — they catch what the build process can't.
