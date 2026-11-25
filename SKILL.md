---
name: sdf-edge-aurora-ui
description: >-
  Builds a 60/120fps single-pass signed-distance-field (SDF) inner screen-edge aurora glow with
  universal dual-exponential falloff, filmic white-shoulder rim tone-mapping, void-gated 1-LSB TPDF
  dark-end dithering, 4 verified color palettes (defaulting to Pearl Silver), and 7-state Lift-to-Pay
  volumetric FBM curtain plus twin bilaterally symmetric comet choreography for WebGL2/React (with CSS
  @property fallback) and SwiftUI [[stitchable]] Metal .colorEffect (macOS 14+ & iOS 17+, Swift 6).
  Use this skill whenever the user asks to build or customize an edge glow, iridescent border,
  screen-edge aurora, OLED bezel glow, SDF border shader, Tide Send, Lift-to-Pay animation,
  SwiftUI Metal .colorEffect glow, or WebGL2 fragment shader glow.
---

# SDF Inner Screen-Edge Aurora Glow (`sdf-edge-aurora-ui`)

Build a single-pass, 60/120fps inner OLED bezel aurora shader clipped inside a rounded display frame. Instead of stacking costly multi-pass blurs, evaluate the interior rounded-box SDF analytically in one fragment pass to combine a wide velvet veil, a tight incandescent white-shoulder rim, bottom-anchored volumetric FBM drag curtains, and bilaterally mirror-symmetric perimeter comet waves across 4 verified themes.

**Attribution & Clean-Room Scope:** Inspired by `@sucodeee`'s MetalForge **Tide Send** showcase (`https://metalforge.xyz/tidesend`, [X status `2124564089527578859`](https://x.com/sucodeee/status/2124564089527578859), design credit `@suriadesign`). `Tide Send` is a commercial MetalForge component; this skill, its optical specification, and all bundled WebGL2/React and SwiftUI/Metal implementations are independent **clean-room reconstructions** derived from FFmpeg pixel/kymograph analysis of the public silent `924×1440` @ 30fps video and verified against live WebGL2 and Metal GPU renders.

---

## Palette Selection (Default: Pearl Silver)

All 4 palettes share identical SDF geometry, dual-exponential decay widths, bilateral symmetry, and 7-state choreography. **Default to Pearl Silver (`pearl` / `.pearl`)** unless the user requests a chromatic theme.

| Palette (`Web` / `SwiftUI`) | Character & Visual Signature | `colA` (Lower Accent) | `colB` (Mid Band) | `colC` (Top Crown) | Checkmark `✓` |
| --- | --- | --- | --- | --- | --- |
| **Pearl Silver** (`pearl` / `.pearl`) — **Default** | Cool platinum-white rim (`#FFFFFF`/`#FAF8FE`) with subtle ice-blue (`215–225°`) & pearl-lavender (`245–252°`) aura — *never flat neutral gray* | `#B3C7DE` / `#BED5F2` | `#CCC7DE` / `#D9D0F1` | `#99A6BF` / `#909CBB` | `#FFFFFF` |
| **Ocean Blue** (`ocean` / `.ocean`) | Electric cyan lower surge, cobalt mid-wall, deep indigo-violet crown | `#38D1FC` / `#2EDAFD` | `#6E8FF5` / `#5C80F5` | `#7D6EF2` / `#745BEC` | `#87E8F4` |
| **Sunset Coral** (`sunset` / `.sunset`) | Warm amber-gold base, luminous salmon-coral mid-wall, deep rose-magenta crown | `#FCAB5C` / `#FFB857` | `#F57A70` / `#F56B6C` | `#E63D8F` / `#E03D94` | `#F3D38C` |
| **Aurora Mint** (`aurora` / `.aurora`) | Electric ice-mint base, seafoam emerald mid-wall, deep jade-teal crown | `#47F7E6` / `#57FBE6` | `#61E8BD` / `#37E0B3` | `#1FB894` / `#1BAC88` | `#89F5DB` |

---

## Core Optical Law & 7-State Choreography

Scale all falloff widths proportionally to inner viewport width `W` (reference inner OLED `506×1100`, aspect `0.460`, corner radius `R = 0.154 W`):

- **Universal Dual-Exponential Edge Falloff:**
  - Wide velvet veil: `σ₂ = 0.075 W` (`38 px` at `W = 506`, `d₁₀ ≈ 65–70 px`, pure `#000000` OLED text void by `~0.28 W`).
  - Tight incandescent rim: `σ₁ = 0.014 W` (`~7 px`) + white-hot core `coreHot = exp(-d / 0.005 W)` passed through a **filmic white-shoulder tone mapper** (`1 - exp(-hdr)`) in linear light so `d = 0..3 px` blooms naturally into incandescent white without neon channel clipping.
  - Top-edge attenuation: Attenuate peak gain by `~0.78×` (and narrow top veil `d₁₀`) across the top `35%` of screen height to protect the status bar and Dynamic Island.
- **Strict Bilateral Mirror Symmetry (`uPerim ∈ [0, 1]`):** Compute a symmetric half-perimeter coordinate (`u = 0` Bottom-Center → `u = 1` Top-Center, dependent only on `abs(p.x)`) driving both the `~18 s` upward steady-state hue drift and `Sending` twin comets (`1,010–1,290 px/s`, `~1.17 s` transit, `~1.05 s` cadence).

```text
idle (bottom FBM aurora pool, 24% H, soft sparkle motes)
  └─[drag y↑]─▶ drag (curtains surge to 66–68% H, side-wall creep, rising motes)
                  └─[release Δy≥55%]─▶ release (0.33s: dark center split, twin bezel wrap, top-corner V-rays, amount zoom)
                                         └─▶ sending (1.55s: dim outline + twin mirror-symmetric upward comets + breathing orb)
                                               └─▶ success (2.93s: <100ms 2.5–3× flash → 360° breathing border + 18s upward hue drift)
                                                     └─[Done]─▶ dismiss (0.43s: time-reversed downward drain + bottom seed orb)
                                                                  └─[theme switch]─▶ crossfade (0.50s RGB palette blend) ─▶ idle
```

Read [references/optical-sdf-spec.md](./references/optical-sdf-spec.md) for the complete 4-palette RGB/Hex/HSL tables, exact `C¹` stadium-spine `halfPerimCoord` and `p=2` harmonic `sdRoundedBoxSmooth` equations, 7-state timing/kinematics, and FFmpeg/kymograph provenance.

---

## Implementation Workflow

1. **Select target starter and inspect the verified clean-room reference:**
   - **WebGL2 + React (+ CSS `@property` fallback):** Start from [examples/web/SdfEdgeAurora.tsx](./examples/web/SdfEdgeAurora.tsx) and standalone interactive playground [examples/web/demo.html](./examples/web/demo.html).
   - **SwiftUI + Metal (`[[stitchable]]` `.colorEffect`, Swift 6, macOS 14+ & iOS 17+):** Start from [examples/swiftui/TideEdgeAurora.metal](./examples/swiftui/TideEdgeAurora.metal) and [examples/swiftui/SdfEdgeAuroraView.swift](./examples/swiftui/SdfEdgeAuroraView.swift).
2. **Implement the crease-free interior SDF and seam-free symmetric perimeter coordinate:**
   - Use normalized `p = 2` harmonic `sdRoundedBoxSmooth` inside `q.x < 0 && q.y < 0` to eliminate both the 45° medial-axis crease (`d > R`) and any flat plateau near `d == R`.
   - Use the `C¹` stadium medial-spine projection for `halfPerimCoord(p, b, r)` (portrait and landscape branches) so comets and hue waves never slice at corners.
3. **Accumulate light in linear HDR, apply filmic shoulder + IEC OETF + void-gated TPDF dither:**
   - Decode sRGB palette stops with exact IEC 61966-2-1 EOTF, accumulate dual-exponential veil/rim/core + comets + FBM curtains + V-rays in linear HDR, tone-map via `1 - exp(-hdr)`, encode exact IEC sRGB OETF, and add void-gated `±1 LSB` triangular-PDF dithering (gated off where `max(r,g,b) == 0` so the OLED center stays exact `0.00 DN` `#000000`).
4. **Wire the 7-state machine and platform lifecycle safely:**
   - Follow [references/platform-pitfalls.md](./references/platform-pitfalls.md) for ref-backed 60fps WebGL2 uniforms, persistent `<canvas>` context-loss recovery, CSS `@property` fallback, SwiftUI `[[stitchable]]` color-space rules, optional XDR/EDR headroom, and device corner-radius matching across iPhone/iPad.
5. **Enforce WCAG 2.2.2, reduced motion, ARIA, and VoiceOver:**
   - Honor `prefers-reduced-motion` (Web) and `@Environment(\.accessibilityReduceMotion)` (SwiftUI): pause `rAF`/`TimelineView` clocks, suppress twin comet sweeps and rising motes, and present a calm static frame.
   - Provide dynamic Pause/Play controls without `aria-pressed` on changing labels, announce state transitions via `aria-live="polite"` / `AccessibilityNotification.Announcement`, and expose tap/keyboard activation alternatives to vertical drag gestures.
6. **Verify compilers, shaders, optics, and accessibility:** Run `./scripts/verify_skill_examples.sh` and check the verification checklist below.

---

## Verified Engineering Pitfalls (Caught & Solved During Audit)

Avoid these nine concrete defects uncovered and resolved during independent multi-target verification:

### Shared Shader & Optical Pitfalls (WebGL2 & Metal)
1. **Corner diagonal seam in naive `halfPerimCoord` (`Δu = 0.105` jump):** Switching branches on `|y|/b.y < -|x|/b.x` causes a `~10.5%` jump across the corner diagonal, slicing `Sending` comets and hue bands. Use the `C¹` stadium medial-spine projection (zero diagonal seam in portrait & landscape).
2. **Flat plateau in unclamped polynomial `sdRoundedBoxSmooth`:** Naive polynomial `smax` goes positive near `q = (0, 0)`, creating a flat `7×7 px` patch at `d == R`. Use normalized `p = 2` reciprocal smooth-min (`(a * v) / sqrt(u² + v²)`) inside `q.x < 0 && q.y < 0` — exact Euclidean arc for `d ≤ R`, `C¹` across axes, `C∞` on the 45° diagonal, reducing medial-axis notch by **`-35%` (WebGL2)** and **`-64%` (Metal)** with zero plateau.
3. **Top-Center color wrap pinch:** Spanning `uPerim * 1.12` wraps `TopCtr (u = 1.0)` back toward `colA`, leaving an unwanted bright cyan/amber dot at Top-Center. Keep spatial span `0.88–0.92` with a broad cosine-eased `colC` crown plateau (`[0.62..0.78]`) so the top edge stays uniformly deep `colC`.
4. **Vertical `x = 0.5` fold seam on top-corner V-rays:** Folding `mx = 0.5 - abs(uv.x - 0.5)` inside a single beam creates a visible crease down center-screen during `Release`/`Dismiss`. Evaluate left (`uv`) and right (`1 - uv.x, uv.y`) `evalCornerVRay` shafts independently and sum them (`C∞` crossing, exact `0.0000 DN` symmetry).
5. **Top-edge glare obscuring Dynamic Island & status bar:** Uniform 360° gain washes out `09:41` and status glyphs. Apply a smooth top attenuation ramp (`0.78×` sRGB / `0.74–0.84×` width over top `35% H`) so top `d₁₀` stays narrower than side `d₁₀`.

### SwiftUI + `[[stitchable]]` Metal Pitfalls
6. **SwiftUI `[[stitchable]]` color-space mismatch & dark OLED banding:** Empirical `ImageRenderer` verification proves SwiftUI `.colorEffect` passes and expects sRGB-encoded `half4` (`0.021 DN` mean parity with standalone Metal compute when decoding via IEC EOTF, shading in linear HDR, encoding IEC OETF, and applying void-gated 1-LSB TPDF dithering). Skipping EOTF/OETF washes out colors; skipping TPDF causes 8-bit dark-end banding; skipping the void gate lifts `#000000` OLED blacks.

### WebGL2 / React & Accessibility Pitfalls
7. **Conditional `<canvas>` unmounting breaks `webglcontextrestored` & renderer switching:** Unmounting `<canvas ref={canvasRef}>` when falling back to CSS prevents `webglcontextrestored` from firing on the live DOM node and breaks `renderer="css" -> "webgl2"` prop transitions (`canvasRef.current === null`). Keep `<canvas>` mounted (toggling `display: 'block' | 'none'`) and mount the CSS fallback overlay alongside it.
8. **60Hz React `setState` churn & GPU leaks:** Keep all 60fps uniforms, clocks, and crossfade ramps inside `runtimeRef.current` (throttle `onTelemetry` to `≥250 ms` / 4Hz), cap `devicePixelRatio` at `≤ 2.0`, and dispose VAO, WebGL program, `ResizeObserver`, `rAF`, and context listeners on unmount.
9. **Vestibular motion & screen-reader traps:** Always freeze `time` and disable comets (`cometPos = -1`) under `prefers-reduced-motion` / `accessibilityReduceMotion`; never combine `aria-pressed` with a dynamically renamed `"Pause"`/`"Play"` button; pair vertical drag handles with tap/keyboard payment triggers.

---

## Validation Checklist

Run the bundled automated verifier from the skill directory:

```bash
./scripts/verify_skill_examples.sh
```

Verify all checks pass:
- **Skill integrity:** `SKILL.md` frontmatter matches `sdf-edge-aurora-ui`, all relative Markdown links (including `./assets/preview.gif`) resolve, and zero local/ephemeral workspace paths or UUIDs exist.
- **Metal shaders (`macosx` & `iphonesimulator`):** Zero warnings and zero errors under `xcrun metal -Wall -Wextra -Werror`.
- **SwiftUI (`macOS 14+` & `iOS 17+ Simulator`):** Zero warnings and zero errors under `swiftc -swift-version 6 -warnings-as-errors -parse-as-library -typecheck`.
- **WebGL2 React TSX & Demo HTML:** Zero strict TypeScript errors (`--strict --noUnusedLocals --noUnusedParameters --noEmit`) when `tsc` + `@types/react` are installed; `demo.html` passes structural marker & `node --check` checks and runs at ~60fps (`0.11 ms` avg draw, `window.__AURORA_DEBUG__.getState()` / `measureFrames(60)`).

---

## Bundled Files

- [references/optical-sdf-spec.md](./references/optical-sdf-spec.md) — Verified `506×1100` geometry, universal dual-exponential falloff constants, complete 4-palette RGB/Hex/HSL tables, `C¹` perimeter & `p=2` smooth SDF equations, 7-state kinematics, and FFmpeg/kymograph provenance.
- [references/platform-pitfalls.md](./references/platform-pitfalls.md) — WebGL2/React + CSS `@property` fallback architecture, SwiftUI `[[stitchable]]` Metal color-space verification (`0.021 DN` parity), EDR vs. SDR tradeoffs, iPhone/iPad corner radius matching, and accessibility checklists.
- [examples/web/SdfEdgeAurora.tsx](./examples/web/SdfEdgeAurora.tsx) — Production React + WebGL2 + CSS `@property` fallback component with SSR support and ref-backed 60fps uniforms.
- [examples/web/demo.html](./examples/web/demo.html) — Zero-build interactive WebGL2 & CSS playground with Lift-to-Pay physics, scrubber, palette crossfade, and `window.__AURORA_DEBUG__` API.
- [examples/swiftui/TideEdgeAurora.metal](./examples/swiftui/TideEdgeAurora.metal) — Single-pass `[[stitchable]]` SwiftUI Metal `.colorEffect` shader and matching headless verification compute kernel.
- [examples/swiftui/SdfEdgeAuroraView.swift](./examples/swiftui/SdfEdgeAuroraView.swift) — Production Swift 6 SwiftUI `EdgeAuroraBackdrop`, `TideSendController`, pure-SwiftUI fallback, and interactive `TideSendShowcaseView`.
- [scripts/verify_skill_examples.sh](./scripts/verify_skill_examples.sh) — Automated frontmatter, link, Metal (`macosx`/`iphonesimulator`), Swift 6, TypeScript, and `demo.html` verification script.
