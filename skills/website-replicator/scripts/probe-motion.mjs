#!/usr/bin/env node
/**
 * probe-motion.mjs — Playwright probe that boots a replica + verifies the
 * motion system actually initialized. The most common silent failure on
 * GSAP-heavy sites: bundle loads, no console errors, but ScrollTriggers
 * never registered or Lenis never started. This script catches that.
 *
 * Usage:
 *   node scripts/probe-motion.mjs <replica-dev-url>
 *
 * Example:
 *   node scripts/probe-motion.mjs http://localhost:4182/
 *
 * Reports:
 *   - ScrollTrigger.getAll().length (how many triggers registered)
 *   - window.gsap, window.Lenis, window.SplitText global presence
 *   - <canvas> count (Rive / Three.js scenes)
 *   - .lenis class on <html> (Lenis CSS hook present?)
 *   - Console errors during load
 *   - 404 / failed network requests
 *
 * Requires: @playwright/test installed in the SKILL repo:
 *   npm install -D @playwright/test
 *   npx playwright install chromium
 *
 * Falls back to a curl-based check if Playwright isn't available.
 */

import { spawn } from "node:child_process";

const [, , url = "http://localhost:4180/"] = process.argv;

console.log(`==> Probing motion system at ${url}`);

let playwright;
try {
  playwright = await import("@playwright/test");
} catch {
  console.error(`
Playwright not installed. Install it:
  npm install -D @playwright/test
  npx playwright install chromium

Or run a curl-based check:
  curl -s ${url} | grep -oE 'gsap|lenis|ScrollTrigger|rive|canvas'
`);
  process.exit(1);
}

const { chromium } = playwright;
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const page = await context.newPage();

const consoleErrors = [];
const failedRequests = [];
page.on("console", (msg) => {
  if (msg.type() === "error") consoleErrors.push(msg.text());
});
page.on("requestfailed", (req) => {
  failedRequests.push({ url: req.url(), failure: req.failure()?.errorText });
});

try {
  await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });
} catch (err) {
  console.error(`\nFailed to load ${url}: ${err.message}`);
  await browser.close();
  process.exit(2);
}

// Give motion init a moment after networkidle
await page.waitForTimeout(2000);

const probe = await page.evaluate(() => {
  const gsap = window.gsap || (window).gsap;
  const ScrollTrigger = window.ScrollTrigger || gsap?.ScrollTrigger;
  return {
    gsap: !!gsap,
    gsapVersion: gsap?.version,
    ScrollTrigger: !!ScrollTrigger,
    scrollTriggerCount: ScrollTrigger?.getAll?.().length ?? 0,
    Lenis: !!window.Lenis || !!(window).__lenis,
    SplitText: !!window.SplitText,
    Rive: !!(window).rive || !!document.querySelector("canvas[data-rive], canvas[id*='rive']"),
    Barba: !!window.barba,
    canvasCount: document.querySelectorAll("canvas").length,
    htmlLenisClass: document.documentElement.classList.contains("lenis"),
    bodyClass: document.body.className,
    title: document.title,
    motionHooks: {
      "data-w-id": document.querySelectorAll("[data-w-id]").length,
      "data-anim-text-slide": document.querySelectorAll("[data-anim-text-slide]").length,
      "data-splitting": document.querySelectorAll("[data-splitting]").length,
      "data-lenis-prevent": document.querySelectorAll("[data-lenis-prevent]").length,
    },
  };
});

await browser.close();

console.log("\n=== Motion system probe ===");
console.log(`  GSAP loaded:           ${probe.gsap ? "✓" : "✗"}${probe.gsapVersion ? "  v" + probe.gsapVersion : ""}`);
console.log(`  ScrollTrigger loaded:  ${probe.ScrollTrigger ? "✓" : "✗"}`);
console.log(`  ScrollTrigger count:   ${probe.scrollTriggerCount}`);
console.log(`  Lenis present:         ${probe.Lenis || probe.htmlLenisClass ? "✓" : "✗"}`);
console.log(`  SplitText loaded:      ${probe.SplitText ? "✓" : "✗"}`);
console.log(`  Rive present:          ${probe.Rive ? "✓" : "✗"}`);
console.log(`  Barba loaded:          ${probe.Barba ? "✓" : "✗"}`);
console.log(`  <canvas> count:        ${probe.canvasCount}`);
console.log(`  HTML has .lenis class: ${probe.htmlLenisClass ? "✓" : "✗"}`);
console.log(`  Page title:            ${probe.title}`);

console.log("\n=== Motion-hook attribute counts ===");
for (const [hook, count] of Object.entries(probe.motionHooks)) {
  if (count > 0) console.log(`  ${hook}: ${count}`);
}

if (consoleErrors.length) {
  console.log("\n=== Console errors ===");
  consoleErrors.slice(0, 10).forEach((e) => console.log(`  - ${e.substring(0, 200)}`));
  if (consoleErrors.length > 10) console.log(`  ... and ${consoleErrors.length - 10} more`);
}

if (failedRequests.length) {
  console.log("\n=== Failed network requests ===");
  failedRequests.slice(0, 10).forEach((r) => console.log(`  - ${r.url}  (${r.failure})`));
  if (failedRequests.length > 10) console.log(`  ... and ${failedRequests.length - 10} more`);
}

// Exit codes for CI integration
const motionBroken = !probe.gsap || probe.scrollTriggerCount === 0;
const hasErrors = consoleErrors.length > 0 || failedRequests.length > 0;

if (motionBroken) {
  console.log("\n✗ MOTION BROKEN — GSAP didn't register any ScrollTriggers");
  process.exit(3);
}
if (hasErrors) {
  console.log("\n⚠ MOTION BOOTED, BUT WITH ERRORS — see above");
  process.exit(4);
}

console.log("\n✓ Motion system OK");
