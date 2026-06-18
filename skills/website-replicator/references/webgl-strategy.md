# Phase 8 — WebGL / Three.js strategy

The biggest mistake in WebGL replication is trying to rewrite the production scene. A typical Vite-bundled Three.js scene is 14,000+ lines of minified code that integrates GLTFLoader, scroll-driven curves, custom shaders, and matchMedia breakpoints. Rewriting takes days. Don't.

## The "ship the bundle" pattern

The production site ships its scene as a Vite-built ES module at something like `wp-content/themes/<theme>/dist/app-<HASH>.js`. This file:

- Is a self-contained IIFE that includes Three.js internally
- Exposes its Three.js constructors on `window.*` (often `window.Scene`, `window.Vector3`, `window.Group`, `window.PerspectiveCamera`, `window.WebGLRenderer`, etc.)
- Attaches the scene init to a specific DOM element (typically `canvas.webgl3d`)
- Listens for scroll events and animates accordingly

Strategy: **ship the bundle at its original URL** and let it run. Then port only the scene-bootstrap function (typically `homeWEBGL()` from the original main.js) to consume the bundle's `window.*` constructors.

```astro
{/* In src/pages/index.astro, ONLY the home page */}
<script
  slot="head"
  type="module"
  src="/wp-content/themes/<theme>/dist/app-BQbjH4ce.js?ver=1.0.0"
  is:inline
></script>
```

Load via `<script type="module">` to match the original's `<script type="module">` declaration. Don't try to load as a regular script — it's an ES module.

## Stage the bundle

Copy from your captured assets into the replica's public folder:

```bash
mkdir -p public/wp-content/themes/<theme>/dist
cp <work>/<target>_sourcemaps/assets/app-BQbjH4ce.js public/wp-content/themes/<theme>/dist/
cp <work>/<target>_sourcemaps/assets/app-CHx12itT.css public/wp-content/themes/<theme>/dist/
```

If the bundle expects GLB textures at specific paths (it does — the Atoll bundle expects `/assets/webgl/TexturesENG.glb`), stage those too:

```bash
mkdir -p public/assets/webgl
cp <work>/.../TexturesENG.glb public/assets/webgl/
cp <work>/.../TexturesFR.glb public/assets/webgl/
```

## The scene-bootstrap function

In `features/home-webgl.ts`, port the original `homeWEBGL()` (typically lines 1800-2020 of main.js) to consume `window.*`:

```ts
export type WebglState = {
  isInitialized: boolean;
  isLoading: boolean;
  loadingProgress: number;
  isMobile: boolean;
};

export const webglState: WebglState = {
  isInitialized: false,
  isLoading: true,
  loadingProgress: 0,
  isMobile: isMobile(),
};

declare global {
  interface Window {
    Scene?: any;
    Vector3?: any;
    Group?: any;
    PerspectiveCamera?: any;
    WebGLRenderer?: any;
    AmbientLight?: any;
    DirectionalLight?: any;
    QuadraticBezierCurve3?: any;
    GLTFLoader?: any;
    initWebGLEffect?: () => void;
  }
}

export function initHomeWebGL(): Promise<void> {
  if (webglState.isInitialized) return Promise.resolve();
  
  const canvas = document.querySelector<HTMLCanvasElement>("canvas.webgl3d");
  if (!canvas) {
    // Fast-resolve so the loader doesn't hang
    webglState.loadingProgress = 100;
    webglState.isInitialized = true;
    webglState.isLoading = false;
    dispatchProgress(100);
    dispatchReady();
    return Promise.resolve();
  }

  // Wait for the bundle to populate window.*
  return new Promise((resolve) => {
    const check = () => {
      if (window.Scene && window.PerspectiveCamera && window.WebGLRenderer) {
        buildScene(canvas, resolve);
      } else {
        setTimeout(check, 50);
      }
    };
    check();
  });
}

function buildScene(canvas: HTMLCanvasElement, resolve: () => void) {
  const scene = new window.Scene!();
  const camera = new window.PerspectiveCamera!(
    50,
    window.innerWidth / window.innerHeight,
    0.1,
    100,
  );
  camera.position.set(0, 0, 4);

  const renderer = new window.WebGLRenderer!({
    canvas,
    alpha: true,
    antialias: true,
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  scene.add(new window.AmbientLight!(0xffffff, 0.5));
  const dl = new window.DirectionalLight!(0xffffff, 1);
  dl.position.set(5, 10, 7);
  scene.add(dl);

  // Load the GLB scene
  const loader = new window.GLTFLoader!();
  const lang = document.documentElement.lang.startsWith("fr") ? "FR" : "ENG";
  loader.load(
    `/assets/webgl/Textures${lang}.glb`,
    (gltf: any) => {
      scene.add(gltf.scene);
      // Port the original's scroll-driven curve animation,
      // mouse-parallax rotation, matchMedia breakpoints
      finishInit(resolve);
    },
    (xhr: any) => {
      const progress = (xhr.loaded / xhr.total) * 100;
      webglState.loadingProgress = progress;
      dispatchProgress(progress);
    },
    (err: any) => {
      console.error("GLB load failed", err);
      finishInit(resolve);
    },
  );

  function tick() {
    renderer.render(scene, camera);
    requestAnimationFrame(tick);
  }
  tick();

  window.addEventListener("resize", () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });
}

function finishInit(resolve: () => void) {
  webglState.isInitialized = true;
  webglState.isLoading = false;
  dispatchReady();
  resolve();
}

function dispatchProgress(progress: number): void {
  document.dispatchEvent(new CustomEvent("webglProgress", { detail: { progress } }));
}

function dispatchReady(): void {
  document.dispatchEvent(new CustomEvent("webglReady"));
}

export function ensureWebGLEffectGlobal(): void {
  if (typeof window === "undefined") return;
  if (!window.initWebGLEffect) window.initWebGLEffect = () => {};
}
```

## The loader handoff

`core/loader.ts` listens for `webglProgress` events to animate the progress bar:

```ts
document.addEventListener("webglProgress", (e) => {
  const detail = (e as CustomEvent<{ progress: number }>).detail;
  gsap.to("#progress_load", {
    duration: 0.3,
    overwrite: true,
    width: `${detail.progress + 10}%`,
  });
});

const interval = setInterval(() => {
  if (webglState.isInitialized) {
    runExitTimeline();
    clearInterval(interval);
  }
}, 0);
```

## Stub the scene during development

When the production bundle isn't loaded yet (or you want fast iteration), provide a stub that fakes a fast progress sweep:

```ts
export function initHomeWebGL(): Promise<void> {
  if (webglState.isInitialized) return Promise.resolve();
  const canvas = document.querySelector<HTMLCanvasElement>("canvas.webgl3d");

  // Real impl when the bundle has populated window.Scene
  if (window.Scene && canvas) {
    return buildSceneFromBundle(canvas);
  }

  // Stub: fake the progress so the loader timeline completes
  return new Promise((resolve) => {
    let progress = 0;
    const step = () => {
      progress = Math.min(100, progress + 12 + Math.random() * 8);
      webglState.loadingProgress = progress;
      dispatchProgress(progress);
      if (progress >= 100) {
        webglState.isInitialized = true;
        webglState.isLoading = false;
        dispatchReady();
        resolve();
      } else setTimeout(step, 90);
    };
    setTimeout(step, 120);
  });
}
```

## The Three.js duplicate-instance warning

When you load the production bundle (which has its own internal Three.js) AND import `three` from npm in `distortion.ts` for the WebGL hover effect, the console prints:

```
WARNING: Multiple instances of Three.js being imported.
```

This is **cosmetic only**. Both scenes render correctly. Two ways to eliminate (both substantial work):

1. **Extend the production bundle** to expose `ShaderMaterial`, `PlaneGeometry`, `TextureLoader` etc. on `window.*`, then rewrite `distortion.ts` to consume `window.Three.*` instead of importing from npm.
2. **Port the home scene to npm `three`** and stop loading the production bundle entirely. Much larger.

For most replicas, accept the warning.

## Distortion module (separate from home scene)

`features/distortion.ts` handles hover-distortion on image tiles (`.wrap-img-distortion`). Since it's used on many pages — not just home — it imports `three` from npm:

```ts
import * as THREE from "three";

export function initDistortion(opts?: DistortionOptions): () => void {
  const containers = document.querySelectorAll(".wrap-img-distortion");
  if (!containers.length) return () => {};
  if (window.innerWidth < 1024) return () => {};
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) return () => {};
  
  // Build a single WebGL renderer + render queue for all containers
  // Attach a canvas inside .wrap-distort-canvas
  // Use a custom shader for the displacement effect
  // Listen to mousemove + mouseenter/leave on each container
}
```

The shader is typically:

```glsl
// fragment
uniform sampler2D uTexture;
uniform float uTime;
uniform float uStrength;
uniform vec2 uMouse;
uniform bool uHover;

void main() {
  vec2 uv = vUv;
  float dist = distance(uv, uMouse);
  float angle = atan(uv.y - uMouse.y, uv.x - uMouse.x);
  float wave = sin(dist * 15.0 - angle) * 0.02 * uStrength;
  vec2 offset = vec2(cos(angle), sin(angle)) * wave * smoothstep(0.45, 0.1, dist);
  vec4 color = texture2D(uTexture, uv + offset);
  // Optional chromatic aberration
  vec4 r = texture2D(uTexture, uv + offset * 1.02);
  vec4 b = texture2D(uTexture, uv + offset * 0.98);
  gl_FragColor = vec4(r.r, color.g, b.b, color.a);
}
```

Port from the original `theme-assets/distortion.js` (typically 300-400 lines).

## Dispose on Barba transition

The disposer matters — without it, every page navigation leaks a renderer + textures:

```ts
function dispose() {
  cancelAnimationFrame(rafId);
  window.removeEventListener("mousemove", onMouseMove);
  textures.forEach((t) => t.dispose());
  materials.forEach((m) => m.dispose());
  geometries.forEach((g) => g.dispose());
  renderer.dispose();
  canvas.remove();
}
```

Call `dispose()` from `core/transitions.ts:leave` hook.

## Reduced-motion respect

```ts
if (matchMedia("(prefers-reduced-motion: reduce)").matches) {
  return () => {};  // skip distortion init
}
```

The image still displays via the underlying `<img>` tag. No motion = no distortion.
