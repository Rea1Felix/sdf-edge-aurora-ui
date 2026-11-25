# Optical, Geometry & Kinematic Specification — SDF Inner Screen-Edge Aurora (`Tide Send`)

Complete forensic pixel, optical, geometric, and kinematic specification for the single-pass SDF inner screen-edge aurora effect across all **4 verified themes** (defaulting to **Pearl Silver**) and **7 interaction states**.

---

## 1. Measurement Provenance & Clean-Room Attribution

- **Source Inspiration:** `@sucodeee`'s MetalForge **Tide Send** showcase ([X post `2124564089527578859`](https://x.com/sucodeee/status/2124564089527578859), posted `2026-11-22 18:02:06 UTC`; design inspiration credited to `@suriadesign`; public catalog page `https://metalforge.xyz/tidesend`). *Note: MetalForge also lists a separate card-level `Aurora Border` component; this specification specifically reconstructs the full-screen `Tide Send` inner OLED bezel aurora and Lift-to-Pay choreography.*
- **Clean-Room Scope:** All equations, color tables, shaders, and UI components in this skill are independent clean-room reconstructions derived exclusively from FFmpeg/NumPy pixel analysis of the public showcase video and independently compiled WebGL2/Metal prototypes.
- **Analyzed Video Ground Truth (`ffprobe`):**
  - Container: MP4 (`isom`/`isomiso4`), `2,614,922` bytes (`2.49 MiB`).
  - Video #0: H.264 High Profile L4.0 (`avc1`), `924 × 1440` (`SAR 1:1`, `DAR 77:120`), `yuv420p` 8-bit progressive, `r_frame_rate = 30/1` (`avg_frame_rate ≈ 29.935 fps`), `932` stream frames (`934` decoded), `31.133659 s`, `671,921 bps`.
  - Audio: **None (`nb_streams: 1`, 0 audio streams — silent)**.
- **Measurement Methods:** `1 fps` & `2 fps` overview extraction, native `30 fps` extraction across Cycle 1 (Ocean Blue, `0–7.5 s`) and Cycle 4 (Pearl Silver, `22–30.5 s`), per-frame 6-ROI luminance telemetry (`934` frames), unwrapped inner-perimeter spatiotemporal kymograph (`3,028.4 px` full loop / `1,514.2 px` half-perimeter at `10 px` inset), 4× nearest-neighbor corner crops, perpendicular falloff nonlinear least-squares fits, and bilateral mirror-difference maps.

---

## 2. Exact Reference Geometry (`924×1440` Frame / `506×1100` Inner OLED)

Scale all optical radii and decay lengths proportionally to inner viewport width `W` (or `min(W, H)` on landscape displays).

| Structural Element | Reference Coordinates (`924×1440`) | Pixel Size | Proportional Ratio (vs. Inner `W = 506`) |
| --- | --- | --- | --- |
| **Outer Studio Stage** | Full frame | `924 × 1440 px` | Solid `#FDFDFD` |
| **Hardware Phone Outer Bezel** | `x ∈ [197..726]`, `y ∈ [158..1281]` | `530 × 1124 px` | Outer corner radius `R_out ≈ 92.1 px` |
| **Bezel Frame Stroke** | `#0C0C0F` (`RGB 12,12,15`) | `L=11, R=13, T=12, B=12 px` | `~0.024 W` |
| **Inner OLED Viewport** | `x ∈ [208..713]`, `y ∈ [170..1269]` | **`506 × 1100 px`** | Aspect **`0.4600`** (iPhone 15/16 Pro `393×852` / `402×874`) |
| **Inner Corner Radius (`R`)** | 83-point bottom-left arc fit (`RMSE = 1.56 px`) | **`77.9 px`** | **`R = 0.154 W`** (~`55–60 pt` iOS hardware display radius) |
| **Inner Perimeter Length** | `10 px` inward loop | `3,028.4 px` | Half-perimeter (BotCtr → TopCtr) = **`1,514.2 px`** |
| **Dynamic Island** | `x ∈ [382..539]`, `y ∈ [180..224]` | `158 × 45 px` | Centered over attenuated top bezel veil |
| **Payment Details Card** | `x ∈ [233..688]`, `y ∈ [645..819]` | `456 × 175 px` | Fill `#19191E`, `1 px` translucent light rim |
| **Circular Lift Button** | `x ∈ [422..499]`, `y ∈ [1116..1186]` | `~74–78 px` diameter | White frosted circle with dark `↑` glyph |
| **Success Checkmark (`✓`)** | `x ∈ [435..490]`, `y ∈ [467..515]` | `~55 × 48 px` | Palette-matched luminescent stroke |
| **Success `Done` Pill** | `x ∈ [405..516]`, `y ∈ [730..779]` | `112 × 50 px` | High-contrast white capsule pill |

---

## 3. Universal Dual-Exponential Falloff & Filmic White-Shoulder Law

Profiling straight left-edge cross-sections (`y ∈ [700..760]`, `d = 0..150 px` inward) during `SUCCESS_STEADY` across all 4 palettes fits a universal **two-component exponential decay** to `< 1.5%` error (`RMSE = 0.007–0.014` in normalized sRGB luminance):

$$I_{\text{edge}}(d) \approx w_1 \, e^{-d / \sigma_1} + w_2 \, e^{-d / \sigma_2}$$

| Palette (Ref Frame) | Peak `L` (`d=0..2`) | `d₅₀` | `d₂₅` | `d₁₀` | `d₀₅` | 2-Exp sRGB Fit (`RMSE`) | Top Edge `peak / d₁₀` | Bottom Edge `peak / d₁₀` |
| --- | ---: | ---: | ---: | ---: | ---: | --- | ---: | ---: |
| **P1 Ocean Blue** (`f160`) | `0.993` | `9 px` (`1.8% W`) | `27 px` | `60 px` (`11.9% W`) | `83 px` | `0.544 e^(-d/6.0) + 0.476 e^(-d/38.0)` (`0.0070`) | `0.836 / 49 px` | `0.995 / 60 px` |
| **P2 Sunset Coral** (`f390`) | `0.998` | `12 px` (`2.4% W`) | `33 px` | `67 px` (`13.2% W`) | `90 px` | `0.491 e^(-d/8.0) + 0.545 e^(-d/38.0)` (`0.0083`) | `0.742 / 49 px` | `0.955 / 61 px` |
| **P3 Aurora Mint** (`f620`) | `0.992` | `16 px` (`3.2% W`) | `40 px` | `72 px` (`14.2% W`) | `98 px` | `0.415 e^(-d/10.0) + 0.654 e^(-d/38.0)` (`0.0120`) | `0.898 / 64 px` | `0.937 / 78 px` |
| **P4 Pearl Silver** (`f850`) | `1.000` | `15 px` (`3.0% W`) | `38 px` | `70 px` (`13.8% W`) | `94 px` | `0.448 e^(-d/10.0) + 0.623 e^(-d/38.0)` (`0.0144`) | `0.993 / 56 px` | `1.000 / 73 px` |

### Canonical Width-Normalized Shader Constants

| Constant | Normalized Formula | Value at `W = 506 px` | Optical Role |
| --- | --- | ---: | --- |
| **Wide Veil (`σ₂`)** | `0.075 * refW` | `38.0 px` | Universal wide inner veil; pure `#000000` OLED void by `~0.28 W` (`140 px`) |
| **Tight Rim (`σ₁`)** | `0.014 * refW` | `7.1 px` | Saturated luminous collar framing the inner bezel |
| **White-Hot Core (`coreHot`)** | `0.005 * refW` | `2.5 px` | Narrow incandescent rim core driving `d = 0..3 px` smoothly into white |
| **Linear Decay Conversion** | `pow(exp(-d / σ), 2.2)` | — | Raises decay envelopes to `2.2` in linear HDR so post-OETF sRGB matches measured `d₅₀ / d₂₅ / d₁₀` |
| **Top-Edge Attenuation** | `0.78×` sRGB (`0.74×` gain / `0.84×` width over top `35% H`) | `d₁₀: 56 vs 70 px` | Keeps `09:41`, status glyphs, and Dynamic Island crisp without glare |
| **Filmic White Shoulder** | `colLin = 1.0 - exp(-max(hdr, 0.0))` | — | Eliminates neon single-channel clipping; naturally desaturates over-bright rims to pearlescent white |
| **Chromatic Offset Check** | `< 0.38 px` R/G/B centroid delta | `0.06–0.38 px` | **Zero** deliberate spatial chromatic aberration prism shift |
| **Dark-End TPDF Dither** | `voidGate * (n1 + n2 - 1.0) / 255.0` | `0.29–0.47 DN` std | Eliminates 8-bit OLED banding (`d = 35..95 px`) while preserving exact `0.00 DN` pure `#000000` center void |

### Verified Cross-Platform Optical Parity (`Pearl Silver`, `506×1100` Normalized)

| Metric | Reference Video (`f850`) | WebGL2 (`demo.html`) | SwiftUI + Metal (`TideEdgeAurora.metal`) |
| --- | ---: | ---: | ---: |
| **Left Rim Peak (`d = 0..2 px`)** | `1.000` | `0.964` | `0.944` |
| **Falloff `d₅₀ / d₂₅ / d₁₀`** | `15 / 38 / 70 px` | `13 / 37 / 65 px` | `16 / 41 / 70 px` |
| **Off-Island Top `d₁₀` vs Left `d₁₀`** | `56 px < 70 px` | `56 px < 65 px` | `39 px < 70 px` |
| **Center OLED Text Void** | `0.00 DN` | `0.00 DN` | `0.00 DN` |
| **Bilateral Symmetry (`mean \|L - mirror(R)\|`)** | `0.621 DN` (lower band) | `0.208 DN` (lower band) | **`0.0000 DN`** (full frame, all 4 palettes & comets) |
| **Dark-End Residual (`d = 35..95 px`)** | `0.449 DN` | `0.292 DN` | `0.470 DN` |
| **45° Corner Medial-Axis Notch** | `~5.0 DN` (IQ exact) | `4.07 → 2.64 DN` (`-35%`) | `4.32 → 1.54 DN` (`-64%`) |

---

## 4. Complete 4-Palette Color Dictionary (Verified RGB / Hex / HSL)

### Palette 4 — Pearl Silver (`pearl` / `.pearl` — Recommended Default)

> **Crucial Optical Detail:** Pearl Silver is **not** flat grayscale `#808080`. Its perimeter aura oscillates gently between **cool ice-blue (`H ≈ 215–225°`, `S ≈ 6–18%`)** and **cool pearl-lavender (`H ≈ 245–252°`, `S ≈ 3–8%`)** while driving the `0–3 px` rim to `#FFFFFF` / `#FAF8FE`, creating a liquid-mercury / titanium refraction quality without neon harshness.

| Sampled Zone / Role | Sampled Hex | RGB (`0–255`) | HSL | Shader Role |
| --- | --- | --- | --- | --- |
| Idle Bot-Core (`462,1262`) | `#FDFDFE` | `(253, 253, 254)` | `240°, 39%, 99%` | White-hot bottom bezel core |
| Idle Bot-Wing (`280,1225`) | `#6D717E` | `(109, 113, 126)` | `224°, 7%, 46%` | Cool slate-silver corner wing |
| Drag Peak Core (`462,1245`) | `#FDFDFD` | `(253, 253, 253)` | `0°, 0%, 99%` | Full-white luminous surge |
| Drag Mid Plume (`462,1080`) | `#C5C8D5` | `(197, 200, 213)` | `230°, 16%, 81%` | Silvery moonlight FBM veil |
| Success Top Rim / Aura | `#D5D8E2` / `#32343A` | `(213,216,226)` / `(50,52,58)` | `224°–231°, 7–18%` | Cool graphite-platinum crown (`colC`) |
| Success Mid-Side Rim / Aura | `#FAF8FE` / `#65646A` | `(250,248,254)` / `(101,100,106)` | `250°, 3%` (aura) | Cool pearl-lavender mid-rim (`colB`) |
| Success Lower-Side Rim / Aura | `#F6FAFE` / `#636871` | `(246,250,254)` / `(99,104,113)` | `212°–220°, 7%` | Cool ice-blue silver tint (`colA`) |
| Success Bot-Center Rim / Aura | `#FAFAFF` / `#555863` | `(250,250,255)` / `(85,88,99)` | `227°–243°, 8%` | Cool silver-periwinkle base |
| Checkmark Stroke (`✓`) | `#FFFFFF` | `(255, 255, 255)` | `0°, 0%, 100%` | Pure crisp white |
| **Normalized Shader Stops (`Web` / `Metal`)** | `colA`: `#B3C7DE` / `#BED5F2` · `colB`: `#CCC7DE` / `#D9D0F1` · `colC`: `#99A6BF` / `#909CBB` | — | `214°–256°` | Feed as sRGB, decode via IEC EOTF |

### Palette 1 — Ocean Blue (`ocean` / `.ocean`)

| Sampled Zone / Role | Sampled Hex | RGB (`0–255`) | HSL | Shader Role |
| --- | --- | --- | --- | --- |
| Idle Bot-Core / Wing | `#FBFCFD` / `#436299` | `(251,252,254)` / `(67,98,153)` | `209°` / `218°, 39%, 43%` | White-hot base + indigo corner wings |
| Drag Peak Core / Mid Plume | `#B8FFFD` / `#7D9DEB` | `(184,255,253)` / `(125,157,235)` | `179°, 100%, 86%` / `223°, 73%, 71%` | Electric aqua core + cornflower plume |
| Success Top Rim / Aura | `#A29FEE` / `#23224C` | `(162,159,238)` / `(35,34,76)` | `242°` | Deep indigo-violet crown (`colC`) |
| Success Mid-Side Rim / Aura | `#D1DBFA` / `#40486B` | `(209,219,250)` / `(64,72,108)` | `226°–229°` | Periwinkle-cobalt transition (`colB`) |
| Success Lower-Side Rim / Aura | `#90E9F9` / `#245177` | `(144,233,249)` / `(36,81,119)` | `189°–208°` | Electric cyan-cerulean wave (`colA`) |
| Success Bot-Center Rim / Aura | `#D8D7FE` / `#3B386B` | `(216,215,254)` / `(59,56,107)` | `241°–243°` | Drifting lavender lobe |
| Checkmark Stroke (`✓`) | `#87E8F4` | `(135, 232, 244)` | `186°, 83%, 74%` | Luminous cyan accent |
| **Normalized Shader Stops (`Web` / `Metal`)** | `colA`: `#38D1FC` / `#2EDAFD` · `colB`: `#6E8FF5` / `#5C80F5` · `colC`: `#7D6EF2` / `#745BEC` | — | `190°–246°` | Feed as sRGB, decode via IEC EOTF |

### Palette 2 — Sunset Coral (`sunset` / `.sunset`)

| Sampled Zone / Role | Sampled Hex | RGB (`0–255`) | HSL | Shader Role |
| --- | --- | --- | --- | --- |
| Idle Bot-Core / Wing | `#FDFDFE` / `#9E574C` | `(253,253,254)` / `(158,87,76)` | `251°` / `8°, 35%, 46%` | White-hot base + terracotta wings |
| Drag Peak Core / Mid Plume | `#FFF8C5` / `#F69A97` | `(255,248,197)` / `(246,154,151)` | `53°, 98%, 89%` / `2°, 84%, 78%` | Solar butter-gold core + salmon curtain |
| Success Top Rim / Aura | `#ED74B8` / `#4B0F29` | `(237,116,184)` / `(75,15,41)` | `326°–334°` | Deep rose-magenta crown (`colC`) |
| Success Mid-Side Rim / Aura | `#FCE8DA` / `#724F48` | `(252,232,219)` / `(114,79,72)` | `11°–24°` | Warm peach-coral transition (`colB`) |
| Success Lower-Side Rim / Aura | `#FDE6BA` / `#824934` | `(253,230,186)` / `(130,73,52)` | `16°–39°` | Amber-apricot wave (`colA`) |
| Success Bot-Center Rim / Aura | `#FCC3F1` / `#712A48` | `(252,195,241)` / `(113,42,73)` | `311°–334°` | Drifting orchid-pink lobe |
| Checkmark Stroke (`✓`) | `#F3D38C` | `(243, 211, 140)` | `42°, 81%, 75%` | Luminous warm gold accent |
| **Normalized Shader Stops (`Web` / `Metal`)** | `colA`: `#FCAB5C` / `#FFB857` · `colB`: `#F57A70` / `#F56B6C` · `colC`: `#E63D8F` / `#E03D94` | — | `330°–38°` | Feed as sRGB, decode via IEC EOTF |

### Palette 3 — Aurora Mint (`aurora` / `.aurora`)

| Sampled Zone / Role | Sampled Hex | RGB (`0–255`) | HSL | Shader Role |
| --- | --- | --- | --- | --- |
| Idle Bot-Core / Wing | `#FDFDFF` / `#389078` | `(253,253,255)` / `(56,144,120)` | `237°` / `164°, 44%, 39%` | White-hot base + deep jade wings |
| Drag Peak Core / Mid Plume | `#A2FFFE` / `#76ECD2` | `(162,255,254)` / `(118,236,210)` | `179°, 100%, 82%` / `167°, 76%, 69%` | Electric ice-cyan core + seafoam plume |
| Success Top Rim / Aura | `#61F2DC` / `#0B4638` | `(97,242,220)` / `(11,70,56)` | `166°–171°` | Deep emerald-teal crown (`colC`) |
| Success Mid-Side Rim / Aura | `#DDFEF9` / `#497164` | `(221,254,249)` / `(74,113,100)` | `160°–171°` | Soft sage-mint transition (`colB`) |
| Success Lower-Side Rim / Aura | `#A5FFF9` / `#2B7B69` | `(165,255,249)` / `(43,123,105)` | `166°–176°` | Bright turquoise-mint wave (`colA`) |
| Success Bot-Center Rim / Aura | `#9DFFFD` / `#266C5D` | `(157,255,253)` / `(38,108,93)` | `167°–179°` | Glowing aqua-jade base |
| Checkmark Stroke (`✓`) | `#89F5DB` | `(137, 245, 219)` | `166°, 84%, 75%` | Luminous mint accent |
| **Normalized Shader Stops (`Web` / `Metal`)** | `colA`: `#47F7E6` / `#57FBE6` · `colB`: `#61E8BD` / `#37E0B3` · `colC`: `#1FB894` / `#1BAC88` | — | `162°–176°` | Feed as sRGB, decode via IEC EOTF |

---

## 5. Core Shader Equations (Verified Crease-Free & Seam-Free)

### 5.1 Smooth Interior Rounded-Box SDF (`p = 2` Normalized Harmonic `sdRoundedBoxSmooth`)

Exact Inigo Quilez `sdRoundedBox` computes `q = abs(p) - b + r`, `sd = length(max(q, 0)) + min(max(q.x, q.y), 0) - r`. In the showcase video, diagonal profiling proves exact IQ geometry (`0.4 DN` match for `d < R = 77.9 px`) transitioning into a `~5.0 DN` darker 45° medial-axis valley for `d ≥ 72 px ≈ R` where `max(q.x, q.y)` creates sharp 90° Chebyshev isolines.

Replacing `min(max(q.x, q.y), 0)` inside the strictly interior quadrant (`q.x < 0 && q.y < 0`) with a **normalized `p = 2` reciprocal harmonic smooth-min** on inward distances $a = -q_x > 0$, $c = -q_y > 0$ eliminates both the 45° diagonal crease and the flat `d == R` plateau caused by naive polynomial `smax`:

$$m = \max(a, c), \quad u = \frac{a}{m}, \quad v = \frac{c}{m}, \qquad \text{smin}_2(a, c) = \frac{a \cdot v}{\sqrt{u^2 + v^2}} = \frac{a c}{\sqrt{a^2 + c^2}}$$

$$\text{sd}_{\text{smooth}}(p, b, r) = \begin{cases} -\text{smin}_2(-q_x, -q_y) - r, & q_x < 0 \;\land\; q_y < 0 \\ \|\max(q, 0)\|_2 + \min(\max(q_x, q_y), 0) - r, & \text{otherwise} \end{cases}$$

**Mathematical properties:**
- **Exact Euclidean arc** for `d ≤ r` (`q.x ≥ 0 || q.y ≥ 0`).
- **`C¹` continuous across axes** (`q.x = 0` and `q.y = 0`) and **`C∞` smooth across the 45° diagonal** (`a = c`).
- **Strictly monotonic & overflow-safe** (dividing by `m = max(a, c)` prevents `a² + c²` overflow; zero flat plateau near `d == r`).
- **Measured crease reduction:** `-35%` on WebGL2 (`4.07 → 2.64 DN`) and `-64%` on Metal (`4.32 → 1.54 DN`), with `< 0.5%` deviation on straight side walls.

### 5.2 `C¹` Stadium Medial-Spine Half-Perimeter Coordinate (`halfPerimCoord`)

A naive quadrant branch (`|y|/b.y < -|x|/b.x`) jumps by **`Δu = 0.105`** across the corner diagonal, slicing `Sending` comets and hue waves. Projecting radially from the rectangle's **medial line segment** guarantees exact bilateral mirror symmetry (`depends only on ax = abs(p.x)`) and `C¹` continuity everywhere in both portrait and landscape viewports.

Let `pyUp` be centered Y pointing **upward** (`p.y` in WebGL2, `-p.y` in SwiftUI/Metal Y-down), `ax = |p.x|`, half-extents `(b_x, b_y)`, and corner radius `r`:

- **Portrait / Square (`b_y ≥ b_x`, vertical spine `sp = b_y - b_x`):**
  $$L_{\text{cap}} = 2(b_x - r) + \frac{\pi}{2} r, \qquad L_{\text{tot}} = 2 L_{\text{cap}} + 2\,\text{sp}$$
  $$u_{\text{perim}} = \begin{cases} \dfrac{L_{\text{cap}} \cdot \operatorname{atan2}(ax,\; -(pyUp + \text{sp})) / (\pi/2)}{L_{\text{tot}}}, & pyUp < -\text{sp} \quad (\text{bottom cap}) \\[8pt] \dfrac{L_{\text{cap}} + (pyUp + \text{sp})}{L_{\text{tot}}}, & |pyUp| \le \text{sp} \quad (\text{side wall}) \\[8pt] \dfrac{L_{\text{cap}} + 2\,\text{sp} + L_{\text{cap}}\!\left(1 - \operatorname{atan2}(ax,\; pyUp - \text{sp}) / (\pi/2)\right)}{L_{\text{tot}}}, & pyUp > \text{sp} \quad (\text{top cap}) \end{cases}$$

- **Landscape (`b_x > b_y`, horizontal spine `hsp = b_x - b_y`):**
  $$L_{\text{end}} = 2(b_y - r) + \pi r, \qquad L_{\text{tot}} = 2\,\text{hsp} + L_{\text{end}}$$
  $$u_{\text{perim}} = \begin{cases} ax / L_{\text{tot}}, & ax < \text{hsp} \;\land\; pyUp \le 0 \\ (\text{hsp} + L_{\text{end}} + (\text{hsp} - ax)) / L_{\text{tot}}, & ax < \text{hsp} \;\land\; pyUp > 0 \\ (\text{hsp} + L_{\text{end}} \cdot \operatorname{atan2}(ax - \text{hsp},\; -pyUp) / \pi) / L_{\text{tot}}, & ax \ge \text{hsp} \end{cases}$$

### 5.3 Broad-Crown Cyclic Palette & Seam-Free Dual V-Rays

- **Crown-Safe Palette Mapping:** Use spatial span `0.88–0.92` (e.g., `huePhase = uPerim * 0.88 - t / 18.0 + 0.86` with cosine-eased cyclic stops holding a broad deep `colC` plateau over `[0.62..0.78]`) so `TopCtr (u = 1.0)` sits squarely inside deep `colC` instead of wrapping back into `colA` and creating a bright pinch dot.
- **Seam-Free Top-Corner V-Rays:** Never fold `uv.x` around `0.5` inside a single beam function (which creates a vertical derivative crease at `x = 0.5`). Evaluate `evalCornerVRay(uv)` and `evalCornerVRay(vec2(1.0 - uv.x, uv.y))` independently and sum them — preserving `0.0000 DN` bilateral symmetry with `C∞` smoothness across the center line.

---

## 6. Seven-State Timing & Kinematics (Verified 30fps Reference Cycle)

The `31.13 s` showcase video loops **4 identical `~7.5 s` cycles** (Ocean Blue → Sunset Coral → Aurora Mint → Pearl Silver → Ocean Blue).

| State | Canonical Duration | Exact Visual, Shader & Foreground UI Kinematics |
| --- | --- | --- |
| **1. `idle`** | `0.90 s` (hold) | Bottom-anchored FBM aurora pool (`curtainH = 24% H`), incandescent bottom bezel rim, twin soft lower-corner wings, gentle rising micro-sparkle motes (`3–5 px`, `~10% H/s`), `edgeGain = 0`. Pure `#000000` upper screen. |
| **2. `drag` (Lift-to-Pay)** | `0.93 s` lift (`Δy = 340.5 px`) + `0.33 s` hold | Normalized `drag ∈ [0, 1]` surges FBM curtains from `24% → 66–68% H` behind the translucent `#19191E` details card (`1 px` rim catches mist), drives bottom rim white-hot (`L = 0.86–0.99`), increases rising sparkle motes (`~100 px/s`), and initiates lower side-wall edge creep. Past commit threshold (`0.55`), copy switches `Lift to pay` → `Let go to pay`. |
| **3. `release` (Launch)** | **`0.33 s`** (`10 f`) | Dramatic **dark vertical split channel** opens at `x = 0.5` in the bottom mist (`split` peaks at `p ≈ 0.45`), pushing twin symmetric curtains up both bezels (`wrapProgress: 0 → 1`) while top-corner diagonal V-rays flare toward the upper vanishing point (`y ≈ 21% H` from top) and `€680.00` perspective-zooms into the emerging orb. |
| **4. `sending`** | **`1.47–1.60 s`** (`~1.55 s` nominal) | Dim ambient 360° perimeter outline (`edgeGain ≈ 0.30–0.32`) + breathing upper-center radial orb (`y ≈ 20.8% H` from top) + `0.80 s` L-to-R shimmer text reveal. **Twin mirror-symmetric comets** spawn at Bottom-Center (`u = 0`), race symmetrically UP both sides at **`1,010–1,290 px/s`** (`~1.17 s` half-perimeter transit, **`~1.05 s` cadence**), and collide/bloom at Top-Center (`u = 1`). |
| **5. `success` (Flash + Steady)** | **`2.90–2.97 s`** (`~2.93 s` nominal) | `<100 ms` radial/bezel surge flash (`2.5–3.2×` brightness jump) settling into full 360° breathing aurora (`±11–18%`, period `~3.5 s`) with continuous symmetric **upward hue drift (`~84 px/s`, `~18.0 s` per half-perimeter)**. UI lands: amount count-up (`0.73 s`), glowing checkmark stroke (`0.53 s`, `+0.08 s` delay), receipt copy, `Done` pill (`0.33 s`). |
| **6. `dismiss`** | **`0.43 s`** (`13 f`) | Exact time-reversed mirror of Release: bright seed orb flares at Bottom-Center while perimeter light drains symmetrically downward from Top-Center (`drainCutoff: 1.12 → 0`), casting brief top-corner V-wisps before pooling into the Idle bottom aurora. |
| **7. `crossfade`** | **`0.50 s`** (`15 f`) | Smooth eased RGB interpolation across `colA`, `colB`, `colC`, `dragCore`, and `checkmark` stops inside the settled Idle pool. |

---

## 7. Complete 7-Layer Visual Stack (Bottom → Top)

| Layer | Blend | Responsibility |
| --- | --- | --- |
| **L0. OLED Surface** | Normal | Pure `#000000` background clipped with `1.5 px` anti-aliased inner bezel mask (`R = 0.154 W`). |
| **L1. Bottom Volumetric Curtains** | Additive (linear HDR) | 3-octave FBM vertical aurora lobes (gently asymmetric in X), lower-corner wings, and Release center split mask. |
| **L2. Wide Inner SDF Veil** | Additive (linear HDR) | `σ₂ = 0.075 W` velvet inner halo tinted by the symmetric `18 s` upward-drifting 3-stop palette; attenuated along top `35% H`. |
| **L3. Tight Rim & White Core** | Additive + Filmic Shoulder | `σ₁ = 0.014 W` rim + `0.005 W` white-hot core passed through `1 - exp(-hdr)` so `d = 0..3 px` blooms naturally to white. |
| **L4. Dynamic State Pulses** | Additive (linear HDR) | Release/Dismiss dual corner V-rays, Sending twin symmetric upward comets + upper breathing orb, Dismiss bottom seed orb. |
| **L5. Rising Sparkle Motes** | Additive (linear HDR) | 16 soft Gaussian bokeh particles (`r ≈ 0.003–0.005 W`) drifting upward at `~10% H/s` with sinusoidal sway inside active bottom mist. |
| **L6. Foreground UI Chrome** | Standard Alpha Over | Status bar & Dynamic Island, translucent `#19191E` details card (`1 px` edge), interactive Lift handle, shimmer Sending caption, stroke-drawn checkmark (`✓`), and `Done` pill. |
