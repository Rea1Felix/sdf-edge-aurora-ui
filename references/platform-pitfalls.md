# Platform Implementation, Color Space & Accessibility Pitfalls

Production implementation guide covering verified architectural decisions, empirical color-space findings, fallback paths, hardware corner-radius matching, and WCAG / VoiceOver requirements across **WebGL2 / React** and **SwiftUI / Metal**.

---

## 1. WebGL2 + React Architecture & Verified Pitfalls

Reference files: [examples/web/SdfEdgeAurora.tsx](../examples/web/SdfEdgeAurora.tsx) and [examples/web/demo.html](../examples/web/demo.html).

### 1.1 Single-Pass Fullscreen Oversized Triangle (Zero VBO)

In WebGL2 (`#version 300 es`), render a 3-vertex fullscreen oversized triangle using `gl_VertexID` (`gl.drawArrays(gl.TRIANGLES, 0, 3)`) with an empty VAO — zero vertex buffers, zero index buffers, and zero multi-pass blur FBOs. Measured headless Chrome (`ANGLE/Metal`, `DPR = 2`, `744×1623` backing store): **`60.65 FPS`**, **`0.108 ms` avg draw** (`p95 = 0.20 ms`, `max = 0.30 ms`), **`0` WebGL/console errors**.

### 1.2 Zero 60Hz React State Churn & Deterministic Scrubbing

- **Ref-backed 60fps uniforms:** Store `palette`, `prevPalette`, `crossfadeStartMs`, `phase`, `phaseStartMs`, `clockSec`, `dragProgress`, `smoothCorner`, `paused`, `reducedMotion`, and `maxDpr` inside `runtimeRef.current`. Never call `setState` inside `requestAnimationFrame`.
- **Throttled telemetry:** Emit `onTelemetry` at `≥ 250 ms` (`4 Hz`) purely via callback ref without triggering internal React re-renders.
- **Immediate static redraws:** When `paused`, `reducedMotion`, or explicit `time` is set, stop the `rAF` loop (burning `0%` GPU while idle) and invoke `renderOnceRef.current()` synchronously whenever props change.
- **DPR capping:** Cap canvas backing resolution via `Math.min(window.devicePixelRatio || 1, maxDpr)` (`default maxDpr = 2.0`) to prevent 3× mobile displays from quadrupling fragment bandwidth unnecessarily.

### 1.3 Persistent `<canvas>` for `webglcontextlost` & Renderer Switching (Audit Fix)

**Defect caught in audit:** Conditionally unmounting `<canvas ref={canvasRef}>` whenever `activeRenderer === 'css'` causes two production bugs:
1. Under `renderer="auto"`, when `webglcontextlost` falls back to CSS, unmounting `<canvas>` destroys the DOM node so `webglcontextrestored` can never restore WebGL2.
2. Mounting with `renderer="css"` (e.g., SSR or user preference) and later switching the prop to `'webgl2'` or `'auto'` hits `if (!canvas || !container) return` because `canvasRef.current` is still `null`, locking the component in CSS mode permanently.

**Verified fix:** Always keep `<canvas ref={canvasRef}>` mounted in the DOM, toggling `style={{ display: activeRenderer === 'webgl2' ? 'block' : 'none' }}`, and render the `.sdf-edge-aurora-css` overlay whenever `activeRenderer === 'css'`. On `webglcontextrestored`, re-compile shaders, re-measure via `resizeCanvas()`, immediately call `drawFrame(performance.now())`, and resume `scheduleFrame()`. On unmount, cancel `rAF`, disconnect `ResizeObserver`, remove context listeners, and call `gl.deleteVertexArray` + `gl.deleteProgram` (deleting shader objects immediately after linking).

### 1.4 CSS `@property` Fallback Tier (`renderer="css"` or WebGL2 Unavailable)

When WebGL2 is unavailable, blocked, or disabled via `renderer="css"`, `SdfEdgeAurora.tsx` and `demo.html` automatically render a zero-JS-loop CSS fallback:
- Registers `@property --aurora-shift` (`<percentage>`) and `@property --aurora-breathe` (`<number>`) to animate smooth upward gradient drift (`18 s linear infinite`) and breathing (`3.6 s ease-in-out infinite`) with optional `@supports (background: linear-gradient(in oklab, white, black))` perceptual interpolation.
- Stacks three clipped inner rings (`veil` `blur(26px)`, `rim` `blur(6px)` with `mix-blend-mode: screen`, `core` `blur(1.2px)` white shoulder), a bottom radial/linear pool scaled by `--aurora-curtain-h`, a top-edge Dynamic Island attenuation guard, and a subtle SVG fractalNoise overlay (`opacity: 0.025`) to soften 8-bit banding.
- **Tradeoffs vs. WebGL2:** Pure CSS cannot evaluate an exact crease-free interior SDF, volumetric FBM curtains, or rounded-corner twin comet arcs, and full-screen CSS `filter: blur(26px)` consumes significantly more mobile GPU memory bandwidth than the `0.11 ms` WebGL2 shader. Reserve CSS mode strictly for fallback or small cards.

### 1.5 Server-Side Rendering (SSR) Safety

Guard all `window`, `document`, `matchMedia`, `performance`, and `ResizeObserver` access inside `useEffect` or `typeof window !== 'undefined'` checks. Verified under Node `react-dom/server` `renderToString` across all 4 palettes (`pearl`, `ocean`, `sunset`, `aurora`) with zero browser globals.

---

## 2. SwiftUI + `[[stitchable]]` Metal Architecture & Verified Pitfalls

Reference files: [examples/swiftui/TideEdgeAurora.metal](../examples/swiftui/TideEdgeAurora.metal) and [examples/swiftui/SdfEdgeAuroraView.swift](../examples/swiftui/SdfEdgeAuroraView.swift).

### 2.1 Empirical SwiftUI `.colorEffect` Color-Space Finding (`0.021 DN` Parity)

A common misconception is that SwiftUI `[[stitchable]]` `.colorEffect` shaders automatically convert `.color(...)` arguments to linear RGB and apply sRGB OETF on output. **Empirical GPU verification via SwiftUI `ImageRenderer` vs. standalone Metal compute kernel (`rgba8Unorm`) proved otherwise:**

- SwiftUI passes `.color(Color(.sRGB, ...))` components as **sRGB-encoded `half4`** and expects **sRGB-encoded premultiplied `half4`** on return (`half4(half3(rgb) * alpha, alpha)`).
- Decoding `colA/colB/colC` via exact **IEC 61966-2-1 EOTF (`srgbToLinear`)**, evaluating dual-exponential falloff (`pow(exp(-d/σ), 2.2)`), additive HDR bloom, and filmic white-shoulder tone-mapping (`1 - exp(-hdr)`) in **linear light**, then encoding exact **IEC OETF (`linearToSrgb`)** followed by void-gated 1-LSB TPDF dithering produces **`0.021 DN` mean absolute difference** between live SwiftUI `ShaderLibrary.tideEdgeAurora` (`ImageRenderer`) and direct Metal compute output — and matches WebGL2 and the reference video across `d₅₀ / d₂₅ / d₁₀`.

### 2.2 Void-Gated Mirrored TPDF Dithering (`0.0000 DN` Symmetry & `0.00 DN` OLED Void)

Apply triangular-PDF dithering (`(n1 + n2 - 1.0) / 255.0`) **only** where `max(srgb.r, max(srgb.g, srgb.b)) > 0.0005f` and seed the hash with mirrored coordinates `float2(abs(p.x), position.y)`.
- **Result 1:** Center OLED pixels remain exact `#000000` (`0.00 DN`, true OLED pixel shutoff).
- **Result 2:** Dark outer veil gradients (`d = 35..95 px`) are band-free (`0.470 DN` high-pass residual).
- **Result 3:** Steady-state palettes and `Sending` comets achieve exact **`0.0000 DN`** left/right bilateral mirror symmetry.

### 2.3 Extended Dynamic Range (EDR) vs. SDR Tradeoffs on iOS XDR OLED

`TideEdgeAurora.metal` exposes an opt-in `edrHeadroom` uniform (`default 0.0`, clamped to `<= 0.35`):
- **Default SDR (`edrHeadroom = 0.0`):** Output stays strictly within `[0.0, 1.0]`. Guaranteed consistent across SDR displays, screen recordings, screenshots, and dark-room eye comfort.
- **Opt-In EDR (`edrHeadroom = 0.15...0.35`):** Adds a controlled highlight lift `max(hdr - 2.4, 0.0) * edrHeadroom * 0.12` on the narrow `0–3 px` incandescent rim and comet cores so ProMotion XDR OLED displays glow physically brighter than paper white. Always test EDR intensity in a dark room and gate it behind `UIScreen.main.potentialEDRHeadroom > 1.0` (or user preference).

### 2.4 Hardware Corner-Radius Matching Across iPhone & iPad

Hardcoding `cornerRadius: 44` causes dark crescent gaps or clipped white rims on modern hardware bezels. Match the container geometry cleanly:

| Target Surface | Recommended Inner Corner Radius | Notes |
| --- | --- | --- |
| **Full-screen iPhone 15 / 16 Pro** | `~55 pt` (`0.140–0.154 * min(W, H)`) | Apply `.ignoresSafeArea()` to `EdgeAuroraBackdrop`; `0.154 * W` matches the `506×1100` reference ratio (`77.9 px`). |
| **Full-screen iPhone SE / Rectangular Display** | `0 pt` | Pass explicit `cornerRadius: 0` (shader clamps `r >= 1.0` safely for AA without visible rounding). |
| **Full-screen iPad Pro / Air** | `18 pt` (`~0.022 * min(W, H)`) | Override `cornerRadius: 18` rather than using the phone `0.154` ratio, which would over-round an iPad viewport. |
| **Modal / Embedded Card / Sheet** | Card's exact `RoundedRectangle` radius | Match `cornerRadius` verbatim to `.clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))` or `ContainerRelativeShape()`. |

### 2.5 Swift 6 Concurrency & Lifecycle Checklist

- Mark UI controllers `@MainActor @Observable` (`TideSendController`), keep value structs (`AuroraRGB`, `AuroraPalette`, `TideSendPhase`, `TideAuroraUniforms`) strictly `Sendable`.
- Cancel transition tasks in `.onDisappear { controller.stop() }` so background `Task.sleep` animation loops never outlive dismissed views.
- Use `TimelineView(.animation(paused: reduceMotion || overrideTime != nil))` with unified `timeline.date.timeIntervalSinceReferenceDate` (zero `CADisplayLink` boilerplate; pauses automatically when Reduce Motion is enabled).
- Guard `#if __has_include(<SwiftUI/SwiftUI_Metal.h>)` in `.metal` so the shader compiles cleanly both inside Xcode SwiftUI targets and via standalone `xcrun metal -Wall -Wextra -Werror` CLI verification.
- **Pure-SwiftUI Fallback (`useMetal: false`):** Uses three stroked `RoundedRectangle` layers + `.blur()` + `.blendMode(.plusLighter)` + `.mask(...)` + `.drawingGroup()`. Convenient for SwiftUI Previews without a `.metallib`, but allocates multiple full-screen blur passes per frame (`~4–7 ms` vs. `<0.4 ms` for single-pass Metal) — always prefer `useMetal: true` in production.

---

## 3. Accessibility, Reduced Motion & WCAG 2.2.2 Checklists

### Web (`SdfEdgeAurora.tsx` & `demo.html`)
- **Reduced Motion (`prefers-reduced-motion: reduce` / `reducedMotion` prop / `?reduced-motion=1`):**
  - Freezes `animT = 0`, disables `breathe` oscillation (`breathe = 1.0`), disables twin `Sending` comets (`cometPos = -1, cometPos2 = -1`), suppresses release flash spikes, pauses CSS `@keyframes`, and stops the `rAF` loop.
- **WCAG 2.2.2 Pause, Stop, Hide:**
  - Any looping showcase MUST expose a visible Pause/Play button. Because the button's accessible label changes dynamically (`"Pause"` ↔ `"Play"`), **do NOT put `aria-pressed` on it** (avoiding conflicting dual state cues).
- **Screen Readers & Keyboard Access:**
  - Mark decorative `<canvas>` and `.css-fallback` layers `aria-hidden="true"` and `pointer-events: none`.
  - Announce palette changes, payment state transitions, and playback toggles through a single centralized `role="status" aria-live="polite" aria-atomic="true"` region.
  - Pair pointer `Lift to pay` vertical drag gestures with keyboard `Enter`/`Space` activation on the `<button>` handle and `≥ 44×44 px` touch targets on coarse pointers.

### SwiftUI (`SdfEdgeAuroraView.swift`)
- **Reduce Motion (`@Environment(\.accessibilityReduceMotion)`):**
  - Pauses `TimelineView(.animation(paused: reduceMotion))`, forces `effTime = 0`, suppresses comets, sparkle motes, V-ray/split intensity, and perspective zoom, and renders calm static opacity crossfades (verified **`0.0000 DN`** frame-to-frame delta between `t = 0s` and `t = 5.5s`).
- **VoiceOver & Switch Control:**
  - Mark `EdgeAuroraBackdrop` `.allowsHitTesting(false)` and `.accessibilityHidden(true)`.
  - Provide `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityAddTraits(.isButton)`, and `.accessibilityAction` on the Lift handle so non-drag assistive tech users can trigger payment in one tap.
  - Post `AccessibilityNotification.Announcement(...)` on `Sending` and `Payment complete` transitions.
  - Use `.monospacedDigit()` on counting currency amounts (`€680.00`) to prevent horizontal layout jitter.
