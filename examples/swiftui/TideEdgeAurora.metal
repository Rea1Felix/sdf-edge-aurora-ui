// TideEdgeAurora.metal
// Clean-room SwiftUI + Metal SDF Edge-Glow Aurora Shader (`Tide Send`)
// Coordinates: SwiftUI Y-DOWN (position.y = 0 at top, size.y at bottom).
// Color space: Accepts sRGB-encoded SwiftUI Color arguments (half4), decodes to
// linear light for physically additive HDR accumulation + filmic shoulder tone-map
// (1 - exp(-hdr)), then encodes exact sRGB OETF + 1-LSB TPDF dark-end dithering.

#include <metal_stdlib>
#if __has_include(<SwiftUI/SwiftUI_Metal.h>)
#include <SwiftUI/SwiftUI_Metal.h>
#endif

using namespace metal;

// MARK: - Color Space Conversions (Exact IEC 61966-2-1 sRGB EOTF / OETF)

static inline float srgbChannelToLinear(float c) {
    float x = max(c, 0.0f);
    return (x <= 0.04045f) ? (x / 12.92f) : pow((x + 0.055f) / 1.055f, 2.4f);
}

static inline float3 srgbToLinear(float3 c) {
    return float3(
        srgbChannelToLinear(c.x),
        srgbChannelToLinear(c.y),
        srgbChannelToLinear(c.z)
    );
}

static inline float linearChannelToSrgb(float c) {
    float x = max(c, 0.0f);
    return (x <= 0.0031308f) ? (12.92f * x) : (1.055f * pow(x, 1.0f / 2.4f) - 0.055f);
}

static inline float3 linearToSrgb(float3 c) {
    return float3(
        linearChannelToSrgb(c.x),
        linearChannelToSrgb(c.y),
        linearChannelToSrgb(c.z)
    );
}

// MARK: - Signed Distance Fields (Exact IQ + Smooth Interior p=2 Crease-Free)

// Exact Inigo Quilez sdRoundedBox (negative inside, positive outside).
static inline float sdRoundedBoxExact(float2 p, float2 b, float r) {
    float2 q = abs(p) - b + r;
    return length(max(q, 0.0f)) + min(max(q.x, q.y), 0.0f) - r;
}

// Smooth interior sdRoundedBox eliminating the 45-degree medial-axis crease when d > r.
// Exact Euclidean match for d <= r; inside q.x < 0 && q.y < 0 uses normalized p=2
// reciprocal smooth-min: C^1 continuous across axes, C^infinity on 45-deg diagonal,
// strictly monotonic, <0.5% deviation on straight walls, and zero flat plateau near d == r.
static inline float sdRoundedBoxSmooth(float2 p, float2 b, float r) {
    float2 q = abs(p) - b + r;
    float outside = length(max(q, 0.0f));
    if (q.x < 0.0f && q.y < 0.0f) {
        float a = -q.x;
        float c = -q.y;
        float m = max(a, c);
        if (m > 1e-6f) {
            float u = a / m;
            float v = c / m;
            float smin = (a * v) * rsqrt(u * u + v * v);
            return outside - smin - r;
        }
    }
    return outside + min(max(q.x, q.y), 0.0f) - r;
}

// MARK: - Noise & Volumetric FBM

static inline float hash21(float2 p) {
    p = fract(p * float2(123.34f, 456.21f));
    p += dot(p, p + 45.32f);
    return fract(p.x * p.y);
}

static inline float vnoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0f - 2.0f * f);
    float a = hash21(i);
    float b = hash21(i + float2(1.0f, 0.0f));
    float c = hash21(i + float2(0.0f, 1.0f));
    float d = hash21(i + float2(1.0f, 1.0f));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

static inline float fbm3(float2 p) {
    float v = 0.0f;
    float a = 0.5f;
    for (int i = 0; i < 3; ++i) {
        v += a * vnoise(p);
        p = p * 2.03f + float2(17.1f, 31.7f);
        a *= 0.5f;
    }
    return v;
}

// MARK: - Bilaterally Symmetric Seam-Free Half-Perimeter Coordinate

// Maps any point p (centered, Y-DOWN: p.y > 0 is bottom, p.y < 0 is top) to
// uPerim in [0.0 = Bottom-Center .. 1.0 = Top-Center] with exact bilateral
// symmetry (depends only on abs(p.x)) and C^1 continuity across the entire screen
// (zero 45-degree corner jump discontinuity).
static inline float halfPerimCoord(float2 p, float2 halfSize, float r) {
    const float kHalfPi = 1.57079632679f;
    const float kPi = 3.14159265359f;
    float ax = abs(p.x);
    float pyUp = -p.y; // Y-up: -halfSize.y at bottom, +halfSize.y at top

    if (halfSize.y >= halfSize.x) {
        // Portrait / square: vertical stadium medial spine
        float sp = halfSize.y - halfSize.x;
        float capLen = max(2.0f * (halfSize.x - r) + kHalfPi * r, 1.0f);
        float totalLen = max(2.0f * capLen + 2.0f * sp, 1.0f);

        if (pyUp < -sp) {
            float dy = -(pyUp + sp); // >= 0
            float ang = atan2(ax, max(dy, 1e-6f)); // 0 at BotCtr .. pi/2 at side join
            return clamp((capLen * (ang / kHalfPi)) / totalLen, 0.0f, 1.0f);
        } else if (pyUp > sp) {
            float dy = pyUp - sp; // >= 0
            float ang = atan2(ax, max(dy, 1e-6f)); // pi/2 at side join .. 0 at TopCtr
            return clamp((capLen + 2.0f * sp + capLen * (1.0f - ang / kHalfPi)) / totalLen, 0.0f, 1.0f);
        } else {
            return clamp((capLen + (pyUp + sp)) / totalLen, 0.0f, 1.0f);
        }
    } else {
        // Landscape: horizontal stadium medial spine
        float hsp = halfSize.x - halfSize.y;
        float endLen = max(2.0f * (halfSize.y - r) + kPi * r, 1.0f);
        float totalLen = max(2.0f * hsp + endLen, 1.0f);

        if (ax < hsp && pyUp <= 0.0f) {
            return clamp(ax / totalLen, 0.0f, 1.0f);
        } else if (ax < hsp && pyUp > 0.0f) {
            return clamp((hsp + endLen + (hsp - ax)) / totalLen, 0.0f, 1.0f);
        } else {
            float dx = ax - hsp;
            float ang = atan2(max(dx, 1e-6f), -pyUp); // 0 down .. pi up
            return clamp((hsp + endLen * (ang / kPi)) / totalLen, 0.0f, 1.0f);
        }
    }
}

// MARK: - Smooth 3-Stop Cyclic Palette Sampling

static inline float cosineEase(float edge0, float edge1, float x) {
    float t = clamp((x - edge0) / max(edge1 - edge0, 1e-5f), 0.0f, 1.0f);
    return 0.5f - 0.5f * cos(3.14159265359f * t);
}

static inline float3 sampleCyclicPalette(float phase, float3 cA, float3 cB, float3 cC) {
    float ph = fract(phase);
    // Smooth periodic 3-stop spectrum with a broad deep cC crown window [0.62..0.78]
    // so Top-Center stays uniformly deep cC with zero pinched wrap dot at t = 0.
    float3 c1 = mix(cA, cB, cosineEase(0.00f, 0.34f, ph));
    float3 c2 = mix(c1, cC, cosineEase(0.34f, 0.62f, ph));
    return mix(c2, cA, cosineEase(0.78f, 1.00f, ph));
}

// Smooth C^infinity single-corner diagonal V-ray shaft (summed L + R to avoid centerline fold seam)
static inline float3 evalCornerVRay(float2 fromCorner, float3 cB, float3 cC, float vRayGain) {
    float2 rayDir = normalize(float2(0.45f, 0.27f));
    float along = dot(fromCorner, rayDir);
    float perp  = abs(fromCorner.x * (-rayDir.y) + fromCorner.y * rayDir.x);

    float beamWidth = mix(0.026f, 0.088f, clamp(along * 2.1f, 0.0f, 1.0f));
    float beamCross = exp(-(perp * perp) / (2.0f * beamWidth * beamWidth));
    float beamLong  = smoothstep(-0.01f, 0.05f, along) * exp(-max(along, 0.0f) * 5.6f);
    float3 rayCol   = mix(cC, cB, clamp(along * 2.4f, 0.0f, 1.0f));

    float3 out = rayCol * (vRayGain * 0.85f * beamCross * beamLong);
    out += mix(rayCol, float3(1.0f), 0.55f)
         * (vRayGain * 0.28f * exp(-(perp * perp) / (2.0f * 0.024f * 0.024f)) * beamLong);
    return out;
}

// MARK: - Unified Core Aurora Shading Evaluation

struct AuroraShaderUniforms {
    float2 size;
    float cornerRadius;
    float time;
    float4 motionParams; // x: dragProgress, y: edgeGain, z: cometProgress, w: splitProgress
    float4 fxParams;     // x: vRayGain, y: orbGain, z: drainCutoff, w: smoothCorner
    float4 flagsParams;  // x: reduceMotion, y: orbYNorm, z: sparkleGain, w: edrHeadroom
    float4 colA;         // sRGB RGBA
    float4 colB;         // sRGB RGBA
    float4 colC;         // sRGB RGBA
};

static inline float3 evaluateTideEdgeAurora(
    float2 position,
    AuroraShaderUniforms u
) {
    float2 size = max(u.size, float2(1.0f, 1.0f));
    float2 halfSize = 0.5f * size;
    float r = clamp(u.cornerRadius, 1.0f, min(halfSize.x, halfSize.y) - 0.5f);
    float2 p = position - halfSize; // Y-DOWN: p.y > 0 is bottom, p.y < 0 is top

    // Unpack parameters
    float dragProgress  = clamp(u.motionParams.x, 0.0f, 1.0f);
    float edgeGain      = max(u.motionParams.y, 0.0f);
    float cometProgress = u.motionParams.z; // < 0 when inactive, 0..1.15 when active
    float splitProgress = clamp(u.motionParams.w, 0.0f, 1.0f);

    float vRayGain     = clamp(u.fxParams.x, 0.0f, 1.0f);
    float orbGain      = clamp(u.fxParams.y, 0.0f, 1.2f);
    float drainCutoff  = clamp(u.fxParams.z, 0.0f, 1.2f);
    float smoothCorner = u.fxParams.w;

    float reduceMotion = u.flagsParams.x;
    float orbYNorm     = clamp(u.flagsParams.y, 0.05f, 0.85f);
    float sparkleGain  = clamp(u.flagsParams.z, 0.0f, 1.0f);
    float edrHeadroom  = max(u.flagsParams.w, 0.0f);

    float effTime = (reduceMotion > 0.5f) ? 0.0f : u.time;

    // 1. Interior SDF distance d (pixels inward from inner OLED bezel)
    float sd = (smoothCorner > 0.5f)
        ? sdRoundedBoxSmooth(p, halfSize, r)
        : sdRoundedBoxExact(p, halfSize, r);

    // Anti-aliased bezel cutoff into pure OLED black
    float bezelAA = smoothstep(0.75f, -0.75f, sd);
    if (bezelAA <= 0.0001f) {
        return float3(0.0f);
    }
    float d = max(-sd, 0.0f);

    // Normalized screen coordinates (Y-DOWN: uv.y = 0 at top, 1 at bottom)
    float2 uv = clamp(position / size, 0.0f, 1.0f);
    float yFromBot = 1.0f - uv.y;

    // 2. Top-edge attenuation (~0.78x) to protect Dynamic Island & status bar
    float topRamp = smoothstep(0.0f, 0.35f, uv.y); // 0 at top edge, 1 below 35% H
    float topWidthScale = mix(0.84f, 1.0f, topRamp);
    float topGainScale  = mix(0.74f, 1.0f, topRamp);
    float topGainLin    = pow(topGainScale, 2.2f);
    float dAtten        = d / topWidthScale;

    // 3. Universal dual-exponential inner-glow falloff (exact measured ratios)
    //    sigmaVeil = 0.075 * W (~38px at 506px), sigmaRim = 0.014 * W (~7.1px),
    //    coreHot   = 0.005 * W (~2.5px). Raised to 2.2 in linear space so the
    //    post-OETF sRGB falloff matches the exact measured d50/d25/d10/d05 curve.
    float refW      = min(size.x, size.y);
    float sigmaVeil = 0.075f * refW;
    float sigmaRim  = 0.014f * refW;
    float sigmaCore = 0.005f * refW;

    float veilEnv = exp(-dAtten / sigmaVeil);
    float rimEnv  = exp(-dAtten / sigmaRim);
    float coreEnv = exp(-dAtten / sigmaCore);

    float veilLin = pow(veilEnv, 2.2f);
    float rimLin  = pow(rimEnv,  2.2f);
    float coreLin = pow(coreEnv, 2.2f);

    // 4. Decode sRGB palette stops to linear RGB
    float3 cA = srgbToLinear(u.colA.rgb);
    float3 cB = srgbToLinear(u.colB.rgb);
    float3 cC = srgbToLinear(u.colC.rgb);

    // 5. Strictly mirror-symmetric half-perimeter coordinate & upward 18s hue drift
    float uPerim = halfPerimCoord(p, halfSize, r);
    // Spatial span 0.88 + offset 0.86 places BotCtr in a wide soft cC->cA transition,
    // BotCorner/LowerSide in vibrant cA, MidSide in cB, and the entire Top edge
    // (uPerim in [0.80..1.00]) squarely inside the broad deep cC crown (no TopCtr pinch).
    float huePhase = uPerim * 0.88f - effTime / 18.0f + 0.86f;
    float3 edgeCol = sampleCyclicPalette(huePhase, cA, cB, cC);

    // Gentle sinusoidal breathing (~3.5s period, disabled under Reduce Motion)
    float breathe = (reduceMotion > 0.5f) ? 1.0f : (1.0f + 0.11f * sin(effTime * 1.8f));

    // Perimeter sweep / dismiss drain mask (1.0 around full perimeter when drainCutoff >= 1.15)
    float perimMask = (drainCutoff >= 1.12f)
        ? 1.0f
        : smoothstep(drainCutoff + 0.14f, drainCutoff - 0.10f, uPerim);

    // 6. Full-perimeter inner SDF edge glow (Wide Veil + Tight Rim + Incandescent Core)
    float3 hdr = float3(0.0f);
    if (edgeGain > 0.0001f) {
        float edgeScalar = edgeGain * perimMask * breathe * topGainLin;
        hdr += edgeCol * (edgeScalar * (0.86f * veilLin + 1.95f * rimLin));
        // Narrow incandescent white-core bloom drives d = 0..3px cleanly to pearlescent white
        hdr += float3(1.0f) * (edgeGain * perimMask * breathe * topGainLin * 2.85f * coreLin);
    }

    // 7. Sending twin mirror-symmetric upward comet pulses (disabled under Reduce Motion)
    if (cometProgress >= 0.0f && reduceMotion < 0.5f) {
        float du = uPerim - cometProgress;
        // Sleek asymmetric comet: crisp bright leading nose + luminous trailing tail
        float cometSigma = (du > 0.0f) ? 0.024f : 0.064f;
        float cometArc = exp(-(du * du) / (2.0f * cometSigma * cometSigma));

        // Subtle crown collision flash as twin comets merge at Top-Center (uPerim -> 1.0)
        float mergePulse = exp(-pow((cometProgress - 0.98f) / 0.10f, 2.0f))
                         * exp(-pow((1.0f - uPerim) / 0.12f, 2.0f));

        float cometTotal = cometArc + 0.65f * mergePulse;
        float3 cometTint = mix(edgeCol, float3(1.0f), 0.42f);
        hdr += cometTint * (cometTotal * (3.60f * rimLin + 0.92f * veilLin));
        hdr += float3(1.0f) * (cometTotal * 3.40f * coreLin);
    }

    // 8. Breathing upper-center radial orb (Sending & Release launch core)
    if (orbGain > 0.0001f) {
        float orbPulse = (reduceMotion > 0.5f) ? 1.0f : (1.0f + 0.14f * sin(effTime * 3.2f));
        float2 orbCenter = float2(0.0f, (orbYNorm - 0.5f) * size.y);
        float2 orbDelta = float2(abs(p.x), p.y) - orbCenter;
        float orbDist = length(orbDelta) / refW;
        float orbHalo = exp(-(orbDist * orbDist) / (2.0f * (0.068f * orbPulse) * (0.068f * orbPulse)));
        float orbCore = exp(-(orbDist * orbDist) / (2.0f * (0.022f * orbPulse) * (0.022f * orbPulse)));
        float3 orbTint = mix(cB, cA, 0.35f);
        hdr += orbTint * (orbGain * 0.42f * orbHalo * orbPulse);
        hdr += mix(orbTint, float3(1.0f), 0.72f) * (orbGain * 0.55f * orbCore * orbPulse);
    }

    // 9. Symmetric top-corner V-rays (soft volumetric aurora shafts on Release & Dismiss)
    //    Evaluated independently for top-left & top-right corners and summed so crossing
    //    at x = 0.5 stays C^infinity smooth with exact 0.0000 DN bilateral symmetry.
    if (vRayGain > 0.0001f) {
        hdr += evalCornerVRay(uv, cB, cC, vRayGain);
        hdr += evalCornerVRay(float2(1.0f - uv.x, uv.y), cB, cC, vRayGain);
    }

    // 10. Bottom volumetric FBM aurora curtains + Release dark vertical split
    //     Active during Idle, Drag Lift, Release Launch, and Dismiss settle;
    //     gated cleanly to 0 during Sending (edgeGain >= 0.24 & split == 0) for exact symmetry.
    float bottomMask = (1.0f - smoothstep(0.05f, 0.22f, edgeGain))
                     + splitProgress * 0.90f;
    bottomMask = clamp(bottomMask, 0.0f, 1.0f);

    if (bottomMask > 0.0005f) {
        float curtainH = mix(0.24f, 0.66f, dragProgress);
        float yNorm = yFromBot / max(curtainH, 0.001f);

        // Organic multi-octave FBM curtain warps (gently asymmetric in X like real aurora)
        float warp1 = fbm3(float2(uv.x * 2.6f, yFromBot * 1.55f - effTime * 0.34f));
        float warp2 = fbm3(float2(uv.x * 4.4f + 3.7f, yFromBot * 2.1f - effTime * 0.24f));
        float plumes = 0.68f
            + 0.28f * sin(uv.x * 7.2f + warp1 * 4.0f + effTime * 0.55f)
            + 0.18f * cos(uv.x * 12.0f - warp2 * 3.2f - effTime * 0.40f);
        plumes = max(plumes, 0.42f);

        // Twin subtle corner wings rising slightly along lower-left & lower-right bezels
        float edgeLift = pow(abs(uv.x - 0.5f) * 2.0f, 2.2f);
        float yNormWing = yFromBot / max(curtainH * (1.0f + 0.26f * edgeLift), 0.001f);

        float vFallBase = exp(-yNormWing * mix(3.3f, 1.75f, dragProgress))
                        * smoothstep(1.28f, 0.0f, yNormWing);
        float vFallLin = pow(clamp(vFallBase, 0.0f, 1.0f), 1.85f);

        // Dramatic dark vertical split channel during Release Launch
        float centerBand = exp(-pow((uv.x - 0.5f) * 5.6f, 2.0f));
        float splitMask = 1.0f - splitProgress * 0.96f * centerBand;
        float splitSideBoost = 1.0f + splitProgress * 0.85f * pow(abs(uv.x - 0.5f) * 2.0f, 1.4f);

        float3 bottomCol = mix(cA, cB, clamp(yNorm * 0.85f + warp1 * 0.35f, 0.0f, 1.0f));
        bottomCol = mix(bottomCol, cC, smoothstep(0.55f, 1.15f, yNorm) * 0.65f);

        float dragEnergy = mix(0.68f, 2.05f, dragProgress) * bottomMask * splitMask * splitSideBoost;
        hdr += bottomCol * (vFallLin * plumes * dragEnergy);

        // Bottom bezel incandescent rim core (white-hot saturation at bottom edge)
        float botRimCore = pow(exp(-yFromBot * mix(28.0f, 18.0f, dragProgress)), 2.0f)
                         * (1.0f - 0.82f * splitProgress * centerBand);
        hdr += mix(cA, float3(1.0f), 0.78f) * (botRimCore * mix(1.15f, 2.45f, dragProgress) * bottomMask);

        // Soft lower side-wall inner edge creep during Drag Lift
        if (dragProgress > 0.01f) {
            float sideHeightMask = smoothstep(curtainH + 0.14f, 0.0f, yFromBot);
            float dragEdgeGain = dragProgress * 0.78f * sideHeightMask * bottomMask;
            hdr += mix(cA, cB, clamp(yFromBot * 1.6f, 0.0f, 1.0f)) * (dragEdgeGain * (0.65f * veilLin + 1.35f * rimLin));
            hdr += float3(1.0f) * (dragEdgeGain * 1.45f * coreLin);
        }

        // 11. Rising micro-sparkle motes (~10% H/s upward drift inside active bottom mist)
        if (sparkleGain > 0.001f && reduceMotion < 0.5f) {
            float moteMask = smoothstep(curtainH * 1.05f, 0.04f, yFromBot)
                           * smoothstep(0.0f, 0.07f, yFromBot)
                           * splitMask
                           * bottomMask;
            if (moteMask > 0.005f) {
                float moteAccum = 0.0f;
                const int kMoteCount = 16;
                for (int i = 0; i < kMoteCount; ++i) {
                    float fi = float(i);
                    float seedX = hash21(float2(fi * 13.7f, 2.3f));
                    float seedY = hash21(float2(fi * 29.1f, 7.9f));
                    float speed = mix(0.085f, 0.135f, hash21(float2(fi * 5.3f, 11.1f)));
                    float myFromBot = fract(seedY + effTime * speed) * (curtainH * 1.05f);
                    float sway = 0.028f * sin(effTime * (1.1f + 0.4f * seedX) + fi * 2.1f);
                    float mx = clamp(0.10f + 0.80f * seedX + sway, 0.06f, 0.94f);

                    float2 motePos = float2(mx * size.x, (1.0f - myFromBot) * size.y);
                    float distPx = length(position - motePos);
                    float moteRadius = mix(0.0028f, 0.0046f, hash21(float2(fi * 19.3f, 4.1f))) * refW;
                    float twinkle = 0.65f + 0.35f * sin(effTime * 3.1f + fi * 4.3f);
                    float dotVal = exp(-(distPx * distPx) / (2.0f * moteRadius * moteRadius));
                    moteAccum += dotVal * twinkle;
                }
                float3 moteCol = mix(cA, float3(1.0f), 0.78f);
                hdr += moteCol * (moteAccum * sparkleGain * mix(0.14f, 0.34f, dragProgress) * moteMask);
            }
        }
    }

    // 12. Filmic white-shoulder tone-mapping in linear HDR
    float3 mapped = 1.0f - exp(-hdr);
    if (edrHeadroom > 0.0f) {
        // Optional subtle EDR highlight boost above 1.0 for XDR OLED
        mapped += max(hdr - 2.4f, 0.0f) * min(edrHeadroom, 0.35f) * 0.12f;
    }

    // 13. Exact Linear -> sRGB OETF + anti-aliased bezel mask
    float3 srgb = linearToSrgb(mapped) * bezelAA;

    // 14. 1-LSB Triangular-PDF (TPDF) dark-end dithering to eliminate 8-bit OLED banding
    //     Gated off in pure #000000 void so OLED center stays exact (0,0,0);
    //     mirrored seed preserves exact bilateral symmetry on steady/sending frames.
    float maxCh = max(srgb.x, max(srgb.y, srgb.z));
    if (maxCh > 0.0005f) {
        float2 symPos = float2(abs(p.x), position.y);
        float tSeed = fract(effTime * 13.73f);
        float n1 = hash21(symPos + float2(tSeed * 19.1f, tSeed * 7.3f));
        float n2 = hash21(symPos + float2(17.3f - tSeed * 11.7f, 31.7f + tSeed * 5.9f));
        float dither = (n1 + n2 - 1.0f) / 255.0f;
        srgb += float3(dither);
    }

    float upperBound = 1.0f + min(edrHeadroom, 0.35f);
    return clamp(srgb, 0.0f, upperBound);
}

// MARK: - SwiftUI [[stitchable]] Color Effect Entry Point

[[stitchable]] half4 tideEdgeAurora(
    float2 position,
    half4 currentColor,
    float2 size,
    float cornerRadius,
    float time,
    float4 motionParams,
    float4 fxParams,
    float4 flagsParams,
    half4 colA,
    half4 colB,
    half4 colC
) {
    AuroraShaderUniforms u;
    u.size         = size;
    u.cornerRadius = cornerRadius;
    u.time         = time;
    u.motionParams = motionParams;
    u.fxParams     = fxParams;
    u.flagsParams  = flagsParams;
    u.colA         = float4(colA);
    u.colB         = float4(colB);
    u.colC         = float4(colC);

    float3 rgb = evaluateTideEdgeAurora(position, u);
    half alpha = currentColor.a;
    return half4(half3(rgb) * alpha, alpha);
}

// MARK: - Standalone Headless Verification Compute Kernel (Exact Same Core)

kernel void tideEdgeAuroraKernel(
    texture2d<half, access::write> outTex [[texture(0)]],
    constant AuroraShaderUniforms& uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTex.get_width() || gid.y >= outTex.get_height()) {
        return;
    }
    float2 position = float2(float(gid.x) + 0.5f, float(gid.y) + 0.5f);
    float3 rgb = evaluateTideEdgeAurora(position, uniforms);
    outTex.write(half4(half3(rgb), 1.0h), gid);
}
