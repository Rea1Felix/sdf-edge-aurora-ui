import {
  useEffect,
  useId,
  useRef,
  useState,
  type CSSProperties,
  type ReactElement,
  type ReactNode,
} from 'react';

export type AuroraPaletteId = 'ocean' | 'sunset' | 'aurora' | 'pearl';

export type AuroraPhase =
  | 'idle'
  | 'drag'
  | 'release'
  | 'sending'
  | 'success'
  | 'dismiss'
  | 'crossfade';

export type AuroraRendererMode = 'auto' | 'webgl2' | 'css';

export type Vec3 = readonly [number, number, number];

export interface AuroraPalette {
  readonly id: AuroraPaletteId;
  readonly label: string;
  readonly subtitle: string;
  /** Lower-side / primary vibrant accent */
  readonly colA: Vec3;
  /** Mid-side transition band */
  readonly colB: Vec3;
  /** Top crown & drifting bottom-center lobe */
  readonly colC: Vec3;
  /** Bottom incandescent core tint during Drag Lift */
  readonly dragCore: Vec3;
  /** Palette-matched UI accent (e.g. success checkmark stroke) */
  readonly accentHex: string;
  /** CSS fallback color stops (sRGB hex) */
  readonly cssStops: {
    readonly a: string;
    readonly b: string;
    readonly c: string;
    readonly rim: string;
  };
}

export const AURORA_PALETTES: Readonly<Record<AuroraPaletteId, AuroraPalette>> = {
  pearl: {
    id: 'pearl',
    label: 'Pearl Silver',
    subtitle: 'Cool platinum · ice-blue & pearl-lavender aura',
    // Subtle cool ice-blue (H ~216°, S ~9–18% in aura), pearl-lavender (H ~247°, S ~4–8%),
    // and cool graphite-platinum crown (H ~224°) — never flat gray.
    colA: [0.70, 0.78, 0.87],
    colB: [0.80, 0.78, 0.87],
    colC: [0.60, 0.65, 0.75],
    dragCore: [0.95, 0.97, 1.0],
    accentHex: '#FFFFFF',
    cssStops: {
      a: '#B3C7DE',
      b: '#CCC7DE',
      c: '#99A6BF',
      rim: '#FAF8FE',
    },
  },
  ocean: {
    id: 'ocean',
    label: 'Ocean Blue',
    subtitle: 'Indigo · cobalt · electric cyan',
    colA: [0.22, 0.82, 0.99],
    colB: [0.43, 0.56, 0.96],
    colC: [0.49, 0.43, 0.95],
    dragCore: [0.58, 0.98, 0.99],
    accentHex: '#87E8F4',
    cssStops: {
      a: '#38D1FC',
      b: '#6E8FF5',
      c: '#7D6EF2',
      rim: '#D1DBFA',
    },
  },
  sunset: {
    id: 'sunset',
    label: 'Sunset Coral',
    subtitle: 'Magenta · coral · warm amber-gold',
    colA: [0.99, 0.67, 0.36],
    colB: [0.96, 0.48, 0.44],
    colC: [0.90, 0.24, 0.56],
    dragCore: [1.0, 0.94, 0.62],
    accentHex: '#F3D38C',
    cssStops: {
      a: '#FCAB5C',
      b: '#F57A70',
      c: '#E63D8F',
      rim: '#FCE8DA',
    },
  },
  aurora: {
    id: 'aurora',
    label: 'Aurora Mint',
    subtitle: 'Emerald · seafoam · ice-mint',
    colA: [0.28, 0.97, 0.90],
    colB: [0.38, 0.91, 0.74],
    colC: [0.12, 0.72, 0.58],
    dragCore: [0.54, 0.99, 0.98],
    accentHex: '#89F5DB',
    cssStops: {
      a: '#47F7E6',
      b: '#61E8BD',
      c: '#1FB894',
      rim: '#DDFEF9',
    },
  },
};

export interface ChoreographyUniforms {
  drag: number;
  bottomGain: number;
  edgeGain: number;
  wrapProgress: number;
  cometPos: number;
  cometPos2: number;
  split: number;
  vRays: number;
  orbGain: number;
  orbY: number;
  orbSize: number;
  seedOrbGain: number;
  flashBoost: number;
  sparkleGain: number;
  sideCreep: number;
}

export interface AuroraDebugTelemetry {
  renderer: 'webgl2' | 'css';
  palette: AuroraPaletteId;
  phase: AuroraPhase;
  time: number;
  phaseTime: number;
  dragProgress: number;
  smoothCorner: boolean;
  reducedMotion: boolean;
  paused: boolean;
  dpr: number;
  width: number;
  height: number;
  fps: number;
  lastDrawMs: number;
  avgDrawMs: number;
  frameCount: number;
  shaderCompiled: boolean;
  contextLost: boolean;
}

export interface SdfEdgeAuroraProps {
  /** Active color theme. Defaults to `'pearl'` (Pearl Silver). */
  palette?: AuroraPaletteId;
  /** Interaction choreography phase. Defaults to `'idle'`. */
  phase?: AuroraPhase;
  /** Optional explicit elapsed seconds inside the current phase (for deterministic playback/scrubbing). */
  phaseTime?: number;
  /** Optional explicit shader clock in seconds (disables internal time advance when provided). */
  time?: number;
  /** Normalized Lift-to-Pay drag progress in `[0, 1]`. Defaults to `0`. */
  dragProgress?: number;
  /** Inner corner radius expressed as a fraction of container width (`0.154` matches iPhone 15/16 Pro). */
  cornerRadiusRatio?: number;
  /** Optional explicit inner corner radius in CSS pixels (overrides `cornerRadiusRatio`). */
  cornerRadiusPx?: number;
  /** Smooth interior SDF corner (`sdRoundedBoxSmooth`) to eliminate 45° medial-axis crease when `d > R`. Defaults to `true`. */
  smoothCorner?: boolean;
  /** Renderer selection: `'auto'` (WebGL2 with CSS `@property` fallback), `'webgl2'`, or `'css'`. */
  renderer?: AuroraRendererMode;
  /** Pauses animation updates (WCAG 2.2.2). Defaults to `false`. */
  paused?: boolean;
  /** Override OS `prefers-reduced-motion` preference. */
  reducedMotion?: boolean;
  /** Maximum devicePixelRatio for WebGL2 backing store. Defaults to `2.0`. */
  maxDpr?: number;
  /** RGB palette crossfade duration in seconds. Defaults to `0.5`. */
  crossfadeDuration?: number;
  /** Enables a centralized polite `aria-live="polite"` region announcing palette/phase changes. Defaults to `false`. */
  announceStatus?: boolean;
  /** Optional class name for the root clipped container. */
  className?: string;
  /** Optional inline style for the root clipped container. */
  style?: CSSProperties;
  /** Optional callback fired when active renderer resolves or falls back. */
  onRendererChange?: (active: 'webgl2' | 'css') => void;
  /** Optional telemetry callback fired at ~4Hz (never 60Hz React setState). */
  onTelemetry?: (telemetry: AuroraDebugTelemetry) => void;
  /** Foreground UI rendered above the edge-glow layer. */
  children?: ReactNode;
}

export const AURORA_VERTEX_SHADER = `#version 300 es
precision highp float;

void main() {
  // Fullscreen oversized triangle (zero VBO required in WebGL2)
  vec2 pos = vec2(
    float((gl_VertexID & 1) << 2) - 1.0,
    float((gl_VertexID & 2) << 1) - 1.0
  );
  gl_Position = vec4(pos, 0.0, 1.0);
}
`;

export const AURORA_FRAGMENT_SHADER = `#version 300 es
precision highp float;

out vec4 fragColor;

uniform vec2  u_res;
uniform float u_time;
uniform float u_radius;
uniform float u_smoothCorner;
uniform float u_reducedMotion;
uniform float u_drag;
uniform float u_bottomGain;
uniform float u_edgeGain;
uniform float u_wrapProgress;
uniform float u_cometPos;
uniform float u_cometPos2;
uniform float u_split;
uniform float u_vRays;
uniform float u_orbGain;
uniform float u_orbY;
uniform float u_orbSize;
uniform float u_seedOrbGain;
uniform float u_flashBoost;
uniform float u_sparkleGain;
uniform float u_sideCreep;
uniform vec3  u_colA;
uniform vec3  u_colB;
uniform vec3  u_colC;
uniform vec3  u_dragCore;

const float PI = 3.14159265359;
const float HALF_PI = 1.57079632679;

// Exact Inigo Quilez sdRoundedBox (negative inside)
float sdRoundedBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Smooth interior distance eliminating the 45° medial-axis crease when d > r.
// Normalized p=2 harmonic smooth-min on inward corner distances a = -q.x, c = -q.y:
// exact Euclidean arc for d < r, exact wall distance far from corners, C¹ across axes,
// C∞ circular-hyperbolic isolines across |q.x| == |q.y|, overflow-safe, zero plateau.
float sdRoundedBoxSmooth(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  float outsideOrArc = length(max(q, 0.0));
  if (q.x < 0.0 && q.y < 0.0) {
    float a = -q.x;
    float c = -q.y;
    float m = max(a, c);
    float smin = 0.0;
    if (m > 1e-6) {
      float u = a / m;
      float v = c / m;
      smin = (a * v) / sqrt(u * u + v * v);
    }
    return -smin - r;
  }
  return outsideOrArc + min(max(q.x, q.y), 0.0) - r;
}

vec3 srgbToLinear(vec3 c) {
  vec3 low = c / 12.92;
  vec3 high = pow((c + 0.055) / 1.055, vec3(2.4));
  return mix(low, high, step(vec3(0.04045), c));
}

vec3 linearToSrgb(vec3 c) {
  vec3 cl = max(c, vec3(0.0));
  vec3 low = cl * 12.92;
  vec3 high = 1.055 * pow(cl, vec3(1.0 / 2.4)) - 0.055;
  return mix(low, high, step(vec3(0.0031308), cl));
}

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
    mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
    f.y
  );
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  mat2 rot = mat2(0.80, -0.60, 0.60, 0.80);
  for (int i = 0; i < 3; i++) {
    v += a * vnoise(p);
    p = rot * p * 2.03 + vec2(11.7, 5.3);
    a *= 0.5;
  }
  return v;
}

// Continuous bilaterally mirror-symmetric half-perimeter coordinate u in [0 = BotCtr .. 1 = TopCtr].
// Projects radially from the rectangle's medial segment so there is zero diagonal seam at corners
// in both portrait and landscape aspect ratios.
float halfPerimCoord(vec2 p, vec2 b, float r) {
  float ax = abs(p.x);
  float L1 = max(b.x - r, 0.0);
  float L2 = HALF_PI * r;
  float L3 = 2.0 * max(b.y - r, 0.0);
  float total = max(2.0 * L1 + 2.0 * L2 + L3, 1e-4);

  if (b.y >= b.x) {
    float hSpan = max(b.y - b.x, 0.0);
    float sBotEnd = L1 + L2 + max((b.y - r) - hSpan, 0.0);
    float sTopStart = sBotEnd + 2.0 * hSpan;
    if (p.y < -hSpan) {
      float phi = atan(ax, max(-hSpan - p.y, 1e-5));
      return (sBotEnd * (phi / HALF_PI)) / total;
    }
    if (p.y > hSpan) {
      float phi = atan(max(p.y - hSpan, 1e-5), max(ax, 1e-5));
      return (sTopStart + (total - sTopStart) * (phi / HALF_PI)) / total;
    }
    return (sBotEnd + (p.y + hSpan)) / total;
  } else {
    float wSpan = max(b.x - b.y, 0.0);
    if (ax <= wSpan) {
      return (p.y < 0.0 ? ax : (total - ax)) / total;
    }
    float phi = atan(p.y, max(ax - wSpan, 1e-5)); // [-PI/2 .. +PI/2]
    float t = (phi + HALF_PI) / PI;
    return (wSpan + (total - 2.0 * wSpan) * t) / total;
  }
}

// Smooth cosine-eased 3-stop cyclic palette with a broad deep colC crown plateau
// so TopCtr stays a rich uniform crown and BotCtr transitions cleanly without pinching.
vec3 samplePalette(float t) {
  float ph = fract(t);
  float w1 = 0.5 - 0.5 * cos(PI * clamp((ph - 0.08) / 0.24, 0.0, 1.0));
  float w2 = 0.5 - 0.5 * cos(PI * clamp((ph - 0.34) / 0.28, 0.0, 1.0));
  float w3 = 0.5 - 0.5 * cos(PI * clamp((ph - 0.64) / 0.24, 0.0, 1.0));
  vec3 c = mix(u_colC, u_colA, w1);
  c = mix(c, u_colB, w2);
  c = mix(c, u_colC, w3);
  return c;
}

float evalCornerVRay(vec2 uvCoord, float aspect) {
  vec2 q = vec2(uvCoord.x * aspect, uvCoord.y);
  vec2 cornerA = vec2(0.0, 0.93);
  vec2 targetB = vec2(0.5 * aspect, 0.64);
  vec2 seg = targetB - cornerA;
  float segLen = length(seg);
  vec2 dir = seg / max(segLen, 1e-4);
  float proj = dot(q - cornerA, dir);
  vec2 closest = cornerA + dir * clamp(proj, 0.0, segLen);
  float perp = length(q - closest);
  float tSeg = clamp(proj / max(segLen, 1e-4), 0.0, 1.0);
  float width = mix(0.007, 0.028, tSeg);
  float ray = exp(-(perp * perp) / (2.0 * width * width))
    * smoothstep(-0.015, 0.05, proj)
    * smoothstep(0.96, 0.10, tSeg);
  return ray;
}

float evalComet(float uPerim, float cPos) {
  if (cPos < -0.2 || cPos > 1.25) return 0.0;
  float du = uPerim - cPos;
  // Tight bright leading head + slightly elongated trailing wake behind the pulse
  float sigma = du < 0.0 ? 0.088 : 0.044;
  float pulse = exp(-(du * du) / (2.0 * sigma * sigma));
  // Smooth fade-in at bottom launch and gentle collision bloom at top-center
  float env = smoothstep(-0.12, 0.06, cPos) * smoothstep(1.18, 0.96, cPos);
  return pulse * env;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_res;
  vec2 p  = gl_FragCoord.xy - 0.5 * u_res;
  vec2 b  = 0.5 * u_res;
  float aspect = u_res.x / max(u_res.y, 1.0);

  // 1. Inward SDF distance d (pixels)
  float sd = u_smoothCorner > 0.5
    ? sdRoundedBoxSmooth(p, b, u_radius)
    : sdRoundedBox(p, b, u_radius);

  // Smooth 1px anti-aliased inner bezel clip
  float insideMask = smoothstep(0.75, -0.75, sd);
  if (insideMask <= 0.001) {
    fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    return;
  }
  float d = max(-sd, 0.0);

  // 2. Universal dual-exponential falloff (verified sRGB fit: sigmaVeil = 0.075 * W, sigmaRim = 0.014 * W)
  // Exponentiated by 2.2 in linear light so sRGB OETF output reproduces exact measured decay widths.
  float flashSpread = 1.0 + 0.16 * u_flashBoost;
  float sigmaCore   = 0.005 * u_res.x;
  float sigmaRim    = 0.014 * u_res.x;
  float sigmaVeil   = 0.075 * u_res.x * flashSpread;

  float coreHot = exp(-2.2 * d / sigmaCore);
  float rim     = exp(-2.2 * d / sigmaRim);
  float veil    = exp(-2.2 * d / sigmaVeil);

  // Decode sRGB palette uniforms to linear light for physically accurate additive glow
  vec3 linA = srgbToLinear(u_colA);
  vec3 linB = srgbToLinear(u_colB);
  vec3 linC = srgbToLinear(u_colC);
  vec3 linDragCore = srgbToLinear(u_dragCore);

  // 3. Top-edge attenuation (~0.78x in sRGB -> ~0.58x linear) for Dynamic Island & status bar legibility
  float topAttenSrgb = mix(1.0, 0.78, smoothstep(0.65, 1.0, uv.y));
  float topAtten     = pow(topAttenSrgb, 2.2);
  float uPerim       = halfPerimCoord(p, b, u_radius); // 0 = BotCtr .. 1 = TopCtr

  // 4. Symmetric upward-drifting perimeter palette (~18s per half-perimeter)
  float animT = u_reducedMotion > 0.5 ? 0.0 : u_time;
  vec3 edgeColSrgb = samplePalette(uPerim * 0.92 - animT / 18.0 + 0.04);
  vec3 edgeCol     = srgbToLinear(edgeColSrgb);
  float breathe    = u_reducedMotion > 0.5 ? 1.0 : (1.0 + 0.18 * sin(animT * 1.8));

  vec3 hdr = vec3(0.0);

  // 5. Full-perimeter SDF aurora (Release wrap, Sending ambient outline, Success flash & steady border, Dismiss drain)
  if (u_edgeGain > 0.001) {
    float wrapMask = u_wrapProgress >= 0.999
      ? 1.0
      : smoothstep(u_wrapProgress + 0.14, u_wrapProgress - 0.12, uPerim);
    float leadBoost = (u_wrapProgress > 0.02 && u_wrapProgress < 0.98)
      ? 0.85 * exp(-pow((uPerim - u_wrapProgress) / 0.065, 2.0))
      : 0.0;

    float gainLin = pow(u_edgeGain, 1.65) * topAtten * breathe * (wrapMask * wrapMask);
    float radialBody = 3.40 * rim + 0.90 * veil;
    hdr += edgeCol * (gainLin * radialBody);
    hdr += mix(edgeCol, vec3(1.0), 0.78) * (gainLin * (6.20 * coreHot + leadBoost * (2.60 * rim + 2.40 * coreHot)));
  }

  // 6. Sending twin mirror-symmetric upward perimeter comet pulses (BotCtr -> TopCtr)
  if (u_reducedMotion < 0.5 && (u_cometPos >= -0.15 || u_cometPos2 >= -0.15)) {
    float comet = max(evalComet(uPerim, u_cometPos), evalComet(uPerim, u_cometPos2));
    if (comet > 0.001) {
      float cometLin = comet * comet;
      vec3 cometTint = mix(edgeCol, vec3(1.0), 0.44);
      hdr += cometTint * (cometLin * topAtten * (5.60 * rim + 0.78 * veil));
      hdr += vec3(1.0) * (cometLin * topAtten * 8.50 * coreHot);
    }
  }

  // 7. Bottom volumetric FBM aurora curtains (Idle, Drag Lift, Release split, Dismiss pool)
  if (u_bottomGain > 0.001) {
    float curtainH = mix(0.24, 0.68, u_drag);
    float yNorm = uv.y / max(curtainH, 0.001);

    // Organic asymmetric FBM vertical curtains (billowing upward as drag lifts)
    float warp = fbm(vec2(uv.x * 2.5 + 0.35 * sin(animT * 0.25), uv.y * 1.5 - animT * 0.32));
    float warp2 = fbm(vec2(uv.x * 4.2 - 0.20, uv.y * 2.0 - animT * 0.48));
    float lobes = 0.62
      + 0.34 * sin(uv.x * 6.8 + warp * 3.8 + animT * 0.50)
      + 0.20 * sin(uv.x * 12.5 - warp2 * 3.1 - animT * 0.38);
    lobes = clamp(lobes, 0.22, 1.35);

    // Soft twin lower-corner wings visible in Idle and lifting smoothly during Drag
    float wingX = exp(-pow((abs(uv.x - 0.5) - 0.36) / 0.16, 2.0));
    float wings = wingX * exp(-uv.y * mix(16.0, 7.2, u_drag)) * mix(0.55, 0.38, u_drag);

    float vFall = exp(-yNorm * mix(4.6, 2.75, u_drag)) * smoothstep(1.20, 0.0, yNorm);

    // Release dark vertical split channel down screen center (x = 0.5)
    float splitMask = 1.0 - u_split * 0.98 * exp(-pow((uv.x - 0.5) * 6.0, 2.0));
    float splitSidePush = 1.0 + u_split * 0.95 * smoothstep(0.18, 0.48, abs(uv.x - 0.5));

    float curtainField = (vFall * lobes * lobes + wings) * (splitMask * splitMask) * splitSidePush * u_bottomGain;

    // Color stratification in linear light: saturated dragCore/colA at bottom -> colB mid -> colC upper tendrils
    float gradMix = clamp(yNorm * 0.85 + warp * 0.30, 0.0, 1.0);
    vec3 lowCol = mix(linA, linDragCore, 0.35 + 0.45 * u_drag);
    vec3 bottomCol = mix(lowCol, linB, smoothstep(0.0, 0.58, gradMix));
    bottomCol = mix(bottomCol, linC, smoothstep(0.50, 1.0, gradMix));

    hdr += bottomCol * (curtainField * mix(1.05, 3.10, u_drag));

    // Incandescent bezel-hugging bottom rim (follows the rounded corner arc!)
    float botArcMask = pow(smoothstep(mix(0.16, 0.38, u_drag), 0.0, uv.y), 1.8) * (splitMask * splitMask);
    hdr += mix(linDragCore, vec3(1.0), 0.65) * (coreHot * botArcMask * mix(4.0, 7.5, u_drag) * u_bottomGain);
    hdr += mix(linA, linDragCore, 0.5) * (rim * botArcMask * mix(2.2, 4.4, u_drag) * u_bottomGain);

    // Side-wall inner edge creep during Drag Lift
    if (u_sideCreep > 0.001) {
      float sideMask = pow(smoothstep(0.10, 0.46, abs(uv.x - 0.5)), 1.6)
        * pow(smoothstep(mix(0.24, 0.68, u_sideCreep), 0.08, uv.y), 1.6);
      vec3 sideCol = mix(linA, linC, smoothstep(0.08, 0.62, uv.y));
      hdr += sideCol * (u_sideCreep * sideMask * (2.80 * rim + 0.85 * veil) * u_bottomGain);
      hdr += vec3(1.0) * (u_sideCreep * sideMask * 3.80 * coreHot * u_bottomGain);
    }

    // Rising micro-sparkle bokeh motes inside the active bottom aurora
    if (u_sparkleGain > 0.001) {
      float sparkles = 0.0;
      for (int i = 0; i < 16; i++) {
        float fi = float(i);
        float x0 = fract(sin(fi * 91.7 + 1.3) * 43758.5453) * 0.84 + 0.08;
        float p0 = fract(sin(fi * 37.3 + 4.1) * 23421.631);
        float spd = 0.075 + 0.045 * fract(sin(fi * 17.1 + 0.7) * 12345.67);
        float life = fract(p0 + animT * spd);
        float my = life * curtainH * 0.90 + 0.025;
        float mx = x0 + 0.016 * sin(animT * 1.15 + fi * 2.4);
        vec2 deltaPx = (uv - vec2(mx, my)) * u_res;
        float dist2 = dot(deltaPx, deltaPx);
        float rMote = (0.0036 + 0.0020 * fract(fi * 0.37)) * u_res.x;
        float moteEnv = smoothstep(0.0, 0.14, life) * smoothstep(1.0, 0.62, life);
        float twinkle = 0.72 + 0.28 * sin(animT * 2.6 + fi * 3.1);
        sparkles += exp(-dist2 / (2.0 * rMote * rMote)) * moteEnv * twinkle;
      }
      float moteMask = clamp(vFall * 1.8, 0.0, 1.0) * splitMask * u_sparkleGain * u_bottomGain;
      hdr += mix(linA, vec3(1.0), 0.78) * (sparkles * 0.48 * moteMask);
    }
  }

  // 8. Top-corner symmetric diagonal V-rays (evaluated separately per corner for C-infinity smoothness across x = 0.5)
  if (u_vRays > 0.001) {
    float rayL = evalCornerVRay(uv, aspect);
    float rayR = evalCornerVRay(vec2(1.0 - uv.x, uv.y), aspect);
    float rayLin = rayL * rayL + rayR * rayR;
    float rayCore = rayL * rayL * rayL + rayR * rayR * rayR;
    vec3 rayCol = mix(linC, linB, 0.35);
    hdr += rayCol * (rayLin * u_vRays * 0.68);
    hdr += vec3(1.0) * (rayCore * u_vRays * 0.22);
  }

  // 9. Upper-center breathing radial orb (Release vanishing core & Sending orb)
  if (u_orbGain > 0.001) {
    vec2 orbDelta = vec2((uv.x - 0.5) * aspect, uv.y - u_orbY);
    float rOrb = length(orbDelta);
    float halo = exp(-(rOrb * rOrb) / (2.0 * (u_orbSize * 0.74) * (u_orbSize * 0.74)));
    float core = exp(-(rOrb * rOrb) / (2.0 * (u_orbSize * 0.28) * (u_orbSize * 0.28)));
    vec3 orbCol = mix(linB, linA, 0.45);
    hdr += orbCol * (halo * halo * u_orbGain * 0.42) + mix(orbCol, vec3(1.0), 0.65) * (core * core * u_orbGain * 1.15);
  }

  // 10. Bottom-center seed orb (Dismiss collapse)
  if (u_seedOrbGain > 0.001) {
    vec2 sDelta = vec2((uv.x - 0.5) * aspect, uv.y - 0.022);
    float rs = length(sDelta);
    float sHalo = exp(-(rs * rs) / (2.0 * 0.036 * 0.036));
    float sCore = exp(-(rs * rs) / (2.0 * 0.014 * 0.014));
    hdr += linA * (sHalo * sHalo * u_seedOrbGain * 1.10) + vec3(1.0) * (sCore * sCore * u_seedOrbGain * 2.20);
  }

  // 11. Filmic white-shoulder tone-mapping in linear HDR, then IEC sRGB OETF encoding
  vec3 colLin = 1.0 - exp(-max(hdr, 0.0));
  vec3 col = linearToSrgb(colLin);

  // 12. Void-gated triangular-PDF (TPDF) 1-LSB dark-end dithering (pure #000000 OLED center, band-free veil)
  float ditherSeed = u_reducedMotion > 0.5 ? 0.0 : fract(u_time * 0.6180339);
  float n1 = hash21(gl_FragCoord.xy + ditherSeed * 17.3);
  float n2 = hash21(gl_FragCoord.xy + 1.73 + ditherSeed * 31.7);
  float voidGate = smoothstep(0.0, 0.004, max(col.r, max(col.g, col.b)));
  float dither = voidGate * (n1 + n2 - 1.0) / 255.0;

  col = clamp(col + dither, 0.0, 1.0);
  fragColor = vec4(col * insideMask, insideMask);
}
`;

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

function smoothstep(edge0: number, edge1: number, x: number): number {
  const t = clamp01((x - edge0) / (edge1 - edge0));
  return t * t * (3 - 2 * t);
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

function lerpVec3(a: Vec3, b: Vec3, t: number): [number, number, number] {
  return [lerp(a[0], b[0], t), lerp(a[1], b[1], t), lerp(a[2], b[2], t)];
}

/**
 * Evaluates deterministic shader uniforms for all 7 verified Tide Send choreography phases.
 */
export function computeChoreographyUniforms(
  phase: AuroraPhase,
  phaseTime: number,
  dragProgress: number,
  reducedMotion: boolean
): ChoreographyUniforms {
  const t = Math.max(0, phaseTime);
  const drag = clamp01(dragProgress);

  switch (phase) {
    case 'idle':
    case 'crossfade':
      return {
        drag: 0,
        bottomGain: 1,
        edgeGain: 0,
        wrapProgress: 0,
        cometPos: -1,
        cometPos2: -1,
        split: 0,
        vRays: 0,
        orbGain: 0,
        orbY: 0.72,
        orbSize: 0.045,
        seedOrbGain: 0,
        flashBoost: 0,
        sparkleGain: 0.35,
        sideCreep: 0,
      };

    case 'drag': {
      const effectiveDrag = drag > 0 ? drag : smoothstep(0, 0.93, t);
      return {
        drag: effectiveDrag,
        bottomGain: 1,
        edgeGain: 0,
        wrapProgress: 0,
        cometPos: -1,
        cometPos2: -1,
        split: 0,
        vRays: 0,
        orbGain: 0,
        orbY: 0.72,
        orbSize: 0.045,
        seedOrbGain: 0,
        flashBoost: 0,
        sparkleGain: lerp(0.35, 1.0, effectiveDrag),
        sideCreep: smoothstep(0.18, 1.0, effectiveDrag),
      };
    }

    case 'release': {
      const r = clamp01(t / 0.33);
      const splitEnv = Math.sin(clamp01(r * 1.15) * Math.PI);
      const vRayEnv = Math.sin(clamp01(r / 0.88) * Math.PI);
      return {
        drag: lerp(1.0, 0.72, r),
        bottomGain: 1.0 - smoothstep(0.45, 1.0, r),
        edgeGain:
          lerp(0.18, 0.72, smoothstep(0.0, 0.65, r)) *
          (1.0 - 0.35 * smoothstep(0.75, 1.0, r)),
        wrapProgress: smoothstep(0.0, 0.92, r),
        cometPos: -1,
        cometPos2: -1,
        split: reducedMotion ? 0.45 : splitEnv,
        vRays: reducedMotion ? 0.35 : vRayEnv,
        orbGain:
          smoothstep(0.0, 0.25, r) * lerp(1.35, 0.65, smoothstep(0.45, 1.0, r)),
        orbY: lerp(0.54, 0.78, smoothstep(0.0, 1.0, r)),
        orbSize: lerp(0.048, 0.026, smoothstep(0.15, 1.0, r)),
        seedOrbGain: 0,
        flashBoost: 0,
        sparkleGain: 0.5 * (1.0 - r),
        sideCreep: 0.45 * (1.0 - r),
      };
    }

    case 'sending': {
      // Twin mirror-symmetric upward comets: 1.15s half-perimeter transit, 1.05s inter-wave cadence
      let comet1 = -1;
      let comet2 = -1;
      if (!reducedMotion) {
        const cadence = 1.05;
        const transit = 1.15;
        const cycleIdx = Math.floor(t / cadence);
        const local1 = t - cycleIdx * cadence;
        const u1 = local1 / transit;
        if (u1 >= 0 && u1 <= 1.18) {
          comet1 = u1;
        }
        if (cycleIdx > 0) {
          const localPrev = t - (cycleIdx - 1) * cadence;
          const uPrev = localPrev / transit;
          if (uPrev >= 0 && uPrev <= 1.18) {
            comet2 = uPrev;
          }
        }
      }
      const orbPulse = reducedMotion ? 0.55 : 0.54 + 0.16 * Math.sin(t * 3.8);
      return {
        drag: 0,
        bottomGain: 0,
        edgeGain: reducedMotion ? 0.52 : 0.32,
        wrapProgress: 1.0,
        cometPos: comet1,
        cometPos2: comet2,
        split: 0,
        vRays: 0,
        orbGain: orbPulse,
        orbY: 0.795,
        orbSize: 0.056,
        seedOrbGain: 0,
        flashBoost: 0,
        sparkleGain: 0,
        sideCreep: 0,
      };
    }

    case 'success': {
      // Single smooth 2.5-3x perimeter flash surge (~0.42s), then sustained breathing border
      const flashEnv = reducedMotion
        ? 0
        : Math.exp(-Math.pow((t - 0.085) / 0.135, 2));
      const orbFade = 0.45 * (1.0 - smoothstep(0.0, 0.32, t));
      return {
        drag: 0,
        bottomGain: 0,
        edgeGain: 1.0 + 1.45 * flashEnv,
        wrapProgress: 1.0,
        cometPos: -1,
        cometPos2: -1,
        split: 0,
        vRays: 0,
        orbGain: reducedMotion ? 0 : orbFade,
        orbY: 0.795,
        orbSize: 0.056,
        seedOrbGain: 0,
        flashBoost: flashEnv,
        sparkleGain: 0,
        sideCreep: 0,
      };
    }

    case 'dismiss': {
      const k = clamp01(t / 0.43);
      return {
        drag: lerp(0.45, 0.0, k),
        bottomGain: smoothstep(0.18, 0.95, k),
        edgeGain: lerp(1.0, 0.0, smoothstep(0.0, 0.90, k)),
        wrapProgress: 1.0 - smoothstep(0.0, 0.88, k),
        cometPos: -1,
        cometPos2: -1,
        split: 0,
        vRays: reducedMotion ? 0 : 0.72 * Math.sin(clamp01(k / 0.55) * Math.PI),
        orbGain: 0,
        orbY: 0.795,
        orbSize: 0.05,
        seedOrbGain: reducedMotion ? 0 : Math.sin(clamp01(k / 0.65) * Math.PI),
        flashBoost: 0,
        sparkleGain: 0.35 * k,
        sideCreep: 0,
      };
    }
  }
}

const CSS_FALLBACK_STYLE_ID = 'sdf-edge-aurora-fallback-styles';

// Progressive enhancement for gradient color-space interpolation (avoids Oklch powerless-hue bug on Pearl Silver)
// and opts into @keyframes motion only under prefers-reduced-motion: no-preference.
const CSS_FALLBACK_STYLES = `
@property --aurora-shift {
  syntax: '<percentage>';
  initial-value: 0%;
  inherits: false;
}

@property --aurora-breathe {
  syntax: '<number>';
  initial-value: 1;
  inherits: false;
}

:root {
  --aurora-in-oklab: ;
}

@supports (background: linear-gradient(in oklab, white, black)) {
  :root {
    --aurora-in-oklab: in oklab;
  }
}

@keyframes sdf-aurora-drift {
  0% { --aurora-shift: 0%; }
  100% { --aurora-shift: 100%; }
}

@keyframes sdf-aurora-breathe {
  0%, 100% { --aurora-breathe: 0.92; }
  50% { --aurora-breathe: 1.08; }
}

.sdf-edge-aurora-css {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  overflow: hidden;
  pointer-events: none;
  isolation: isolate;
  background: #000000;
}

.sdf-edge-aurora-css__layer {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
}

/* Blur sits on the wrapper so mask-composite on the child ring blurs smoothly inward rather than hard-clipping! */
.sdf-edge-aurora-css__veil-wrap {
  filter: blur(26px);
  opacity: calc(var(--aurora-edge-opacity, 1) * 0.92 * var(--aurora-breathe, 1));
}

.sdf-edge-aurora-css__rim-wrap {
  filter: blur(7px);
  mix-blend-mode: screen;
  opacity: calc(var(--aurora-edge-opacity, 1) * 0.90 * var(--aurora-breathe, 1));
}

.sdf-edge-aurora-css__core-wrap {
  filter: blur(1.4px);
  mix-blend-mode: screen;
  opacity: calc(var(--aurora-edge-opacity, 1) * 0.95);
}

.sdf-edge-aurora-css__ring {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  -webkit-mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
  -webkit-mask-composite: xor;
  mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
  mask-composite: exclude;
  background: linear-gradient(
    to top var(--aurora-in-oklab),
    var(--aurora-c) calc(0% + var(--aurora-shift)),
    var(--aurora-a) calc(28% + var(--aurora-shift)),
    var(--aurora-b) calc(60% + var(--aurora-shift)),
    var(--aurora-c) calc(100% + var(--aurora-shift))
  );
  background-size: 100% 200%;
  background-position: 0 calc(100% - var(--aurora-shift));
}

.sdf-edge-aurora-css__veil {
  padding: 20px;
}

.sdf-edge-aurora-css__rim {
  padding: 5px;
}

.sdf-edge-aurora-css__core {
  padding: 2px;
  background: linear-gradient(
    to top var(--aurora-in-oklab),
    var(--aurora-rim),
    #ffffff 42%,
    var(--aurora-rim)
  );
}

.sdf-edge-aurora-css__top-guard {
  background: linear-gradient(
    to bottom var(--aurora-in-oklab),
    rgba(0, 0, 0, 0.24) 0%,
    rgba(0, 0, 0, 0) 32%
  );
}

.sdf-edge-aurora-css__bottom-pool {
  background:
    radial-gradient(
      85% var(--aurora-curtain-h, 30%) at 50% 102%,
      var(--aurora-rim) 0%,
      var(--aurora-a) 26%,
      var(--aurora-b) 56%,
      transparent 82%
    ),
    radial-gradient(
      55% calc(var(--aurora-curtain-h, 30%) * 0.72) at 16% 100%,
      var(--aurora-c) 0%,
      transparent 75%
    ),
    radial-gradient(
      55% calc(var(--aurora-curtain-h, 30%) * 0.72) at 84% 100%,
      var(--aurora-c) 0%,
      transparent 75%
    );
  opacity: var(--aurora-bottom-opacity, 0);
  mix-blend-mode: screen;
  filter: blur(14px);
  transition: opacity 0.28s ease;
}

.sdf-edge-aurora-css__dither {
  opacity: 0.025;
  mix-blend-mode: overlay;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='64' height='64'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='64' height='64' filter='url(%23n)'/%3E%3C/svg%3E");
}

.sdf-edge-aurora-css[data-animated="true"] .sdf-edge-aurora-css__veil,
.sdf-edge-aurora-css[data-animated="true"] .sdf-edge-aurora-css__rim {
  @media (prefers-reduced-motion: no-preference) {
    animation: sdf-aurora-drift 18s linear infinite;
  }
}

.sdf-edge-aurora-css[data-animated="true"] .sdf-edge-aurora-css__veil-wrap,
.sdf-edge-aurora-css[data-animated="true"] .sdf-edge-aurora-css__rim-wrap {
  @media (prefers-reduced-motion: no-preference) {
    animation: sdf-aurora-breathe 3.5s ease-in-out infinite;
  }
}

.sdf-edge-aurora-sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
  border: 0;
}
`;

function ensureCssFallbackStyles(): void {
  if (typeof document === 'undefined') return;
  if (document.getElementById(CSS_FALLBACK_STYLE_ID)) return;
  const style = document.createElement('style');
  style.id = CSS_FALLBACK_STYLE_ID;
  style.textContent = CSS_FALLBACK_STYLES;
  document.head.appendChild(style);
}

interface UniformLocations {
  u_res: WebGLUniformLocation | null;
  u_time: WebGLUniformLocation | null;
  u_radius: WebGLUniformLocation | null;
  u_smoothCorner: WebGLUniformLocation | null;
  u_reducedMotion: WebGLUniformLocation | null;
  u_drag: WebGLUniformLocation | null;
  u_bottomGain: WebGLUniformLocation | null;
  u_edgeGain: WebGLUniformLocation | null;
  u_wrapProgress: WebGLUniformLocation | null;
  u_cometPos: WebGLUniformLocation | null;
  u_cometPos2: WebGLUniformLocation | null;
  u_split: WebGLUniformLocation | null;
  u_vRays: WebGLUniformLocation | null;
  u_orbGain: WebGLUniformLocation | null;
  u_orbY: WebGLUniformLocation | null;
  u_orbSize: WebGLUniformLocation | null;
  u_seedOrbGain: WebGLUniformLocation | null;
  u_flashBoost: WebGLUniformLocation | null;
  u_sparkleGain: WebGLUniformLocation | null;
  u_sideCreep: WebGLUniformLocation | null;
  u_colA: WebGLUniformLocation | null;
  u_colB: WebGLUniformLocation | null;
  u_colC: WebGLUniformLocation | null;
  u_dragCore: WebGLUniformLocation | null;
}

interface GlResources {
  gl: WebGL2RenderingContext;
  program: WebGLProgram;
  vao: WebGLVertexArrayObject | null;
  uniforms: UniformLocations;
}

function compileShader(
  gl: WebGL2RenderingContext,
  type: number,
  source: string
): WebGLShader | null {
  const shader = gl.createShader(type);
  if (!shader) return null;
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    gl.deleteShader(shader);
    return null;
  }
  return shader;
}

function initWebGL2(canvas: HTMLCanvasElement): GlResources | null {
  const gl = canvas.getContext('webgl2', {
    alpha: true,
    antialias: false,
    depth: false,
    stencil: false,
    premultipliedAlpha: true,
    preserveDrawingBuffer: false,
    powerPreference: 'high-performance',
  });
  if (!gl) return null;

  const vs = compileShader(gl, gl.VERTEX_SHADER, AURORA_VERTEX_SHADER);
  const fs = compileShader(gl, gl.FRAGMENT_SHADER, AURORA_FRAGMENT_SHADER);
  if (!vs || !fs) {
    if (vs) gl.deleteShader(vs);
    if (fs) gl.deleteShader(fs);
    return null;
  }

  const program = gl.createProgram();
  if (!program) {
    gl.deleteShader(vs);
    gl.deleteShader(fs);
    return null;
  }
  gl.attachShader(program, vs);
  gl.attachShader(program, fs);
  gl.linkProgram(program);

  // Shaders can be marked for deletion once linked into the program
  gl.deleteShader(vs);
  gl.deleteShader(fs);

  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    gl.deleteProgram(program);
    return null;
  }

  const vao = gl.createVertexArray();
  const u = (name: string): WebGLUniformLocation | null =>
    gl.getUniformLocation(program, name);

  return {
    gl,
    program,
    vao,
    uniforms: {
      u_res: u('u_res'),
      u_time: u('u_time'),
      u_radius: u('u_radius'),
      u_smoothCorner: u('u_smoothCorner'),
      u_reducedMotion: u('u_reducedMotion'),
      u_drag: u('u_drag'),
      u_bottomGain: u('u_bottomGain'),
      u_edgeGain: u('u_edgeGain'),
      u_wrapProgress: u('u_wrapProgress'),
      u_cometPos: u('u_cometPos'),
      u_cometPos2: u('u_cometPos2'),
      u_split: u('u_split'),
      u_vRays: u('u_vRays'),
      u_orbGain: u('u_orbGain'),
      u_orbY: u('u_orbY'),
      u_orbSize: u('u_orbSize'),
      u_seedOrbGain: u('u_seedOrbGain'),
      u_flashBoost: u('u_flashBoost'),
      u_sparkleGain: u('u_sparkleGain'),
      u_sideCreep: u('u_sideCreep'),
      u_colA: u('u_colA'),
      u_colB: u('u_colB'),
      u_colC: u('u_colC'),
      u_dragCore: u('u_dragCore'),
    },
  };
}

interface MutableRuntimeState {
  palette: AuroraPaletteId;
  prevPalette: AuroraPaletteId;
  crossfadeStartMs: number;
  crossfadeDuration: number;
  phase: AuroraPhase;
  phaseStartMs: number;
  explicitPhaseTime: number | undefined;
  explicitTime: number | undefined;
  dragProgress: number;
  cornerRadiusRatio: number;
  cornerRadiusPx: number | undefined;
  smoothCorner: boolean;
  paused: boolean;
  reducedMotion: boolean;
  maxDpr: number;
  widthCss: number;
  heightCss: number;
  dpr: number;
  clockSec: number;
  lastRafMs: number;
  frameCount: number;
  fps: number;
  fpsAccumFrames: number;
  fpsWindowStartMs: number;
  lastDrawMs: number;
  avgDrawMs: number;
  lastTelemetryMs: number;
  contextLost: boolean;
  shaderCompiled: boolean;
  onTelemetry: ((telemetry: AuroraDebugTelemetry) => void) | undefined;
}

/**
 * Single-pass WebGL2 SDF Edge-Glow Aurora component (clean-room reconstruction of Tide Send)
 * with graceful CSS `@property` multi-layer fallback, DPR capping, ref-backed 60fps uniforms,
 * WCAG 2.2.2 pause support, and `prefers-reduced-motion` static framing.
 */
export function SdfEdgeAurora({
  palette = 'pearl',
  phase = 'idle',
  phaseTime,
  time,
  dragProgress = 0,
  cornerRadiusRatio = 0.154,
  cornerRadiusPx,
  smoothCorner = true,
  renderer = 'auto',
  paused = false,
  reducedMotion,
  maxDpr = 2.0,
  crossfadeDuration = 0.5,
  announceStatus = false,
  className,
  style,
  onRendererChange,
  onTelemetry,
  children,
}: SdfEdgeAuroraProps): ReactElement {
  const instanceId = useId();
  const containerRef = useRef<HTMLDivElement | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const glResRef = useRef<GlResources | null>(null);
  const rafIdRef = useRef<number | null>(null);
  const renderOnceRef = useRef<(() => void) | null>(null);

  const [osReducedMotion, setOsReducedMotion] = useState<boolean>(false);
  const [activeRenderer, setActiveRenderer] = useState<'webgl2' | 'css'>(
    renderer === 'css' ? 'css' : 'webgl2'
  );

  const effectiveReducedMotion = reducedMotion ?? osReducedMotion;

  const runtimeRef = useRef<MutableRuntimeState>({
    palette,
    prevPalette: palette,
    crossfadeStartMs: -1e9,
    crossfadeDuration,
    phase,
    phaseStartMs: 0,
    explicitPhaseTime: phaseTime,
    explicitTime: time,
    dragProgress,
    cornerRadiusRatio,
    cornerRadiusPx,
    smoothCorner,
    paused,
    reducedMotion: effectiveReducedMotion,
    maxDpr,
    widthCss: 0,
    heightCss: 0,
    dpr: 1,
    clockSec: time ?? 0,
    lastRafMs: 0,
    frameCount: 0,
    fps: 0,
    fpsAccumFrames: 0,
    fpsWindowStartMs: 0,
    lastDrawMs: 0,
    avgDrawMs: 0,
    lastTelemetryMs: 0,
    contextLost: false,
    shaderCompiled: false,
    onTelemetry,
  });

  // Track OS prefers-reduced-motion safely in the browser (SSR-safe)
  useEffect(() => {
    if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') {
      return;
    }
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setOsReducedMotion(mq.matches);
    const onChange = (event: MediaQueryListEvent): void => {
      setOsReducedMotion(event.matches);
    };
    mq.addEventListener('change', onChange);
    return () => {
      mq.removeEventListener('change', onChange);
    };
  }, []);

  // Inject CSS fallback stylesheet once when CSS fallback is active
  useEffect(() => {
    if (activeRenderer === 'css') {
      ensureCssFallbackStyles();
    }
  }, [activeRenderer]);

  // Notify renderer transitions
  useEffect(() => {
    onRendererChange?.(activeRenderer);
  }, [activeRenderer, onRendererChange]);

  // Synchronously update ref-backed 60fps uniforms without re-creating WebGL resources
  useEffect(() => {
    const rt = runtimeRef.current;
    const now = typeof performance !== 'undefined' ? performance.now() : 0;

    if (rt.palette !== palette) {
      rt.prevPalette = rt.palette;
      rt.palette = palette;
      rt.crossfadeStartMs = now;
    }
    if (rt.phase !== phase) {
      rt.phase = phase;
      rt.phaseStartMs = now;
    }
    rt.crossfadeDuration = Math.max(0.01, crossfadeDuration);
    rt.explicitPhaseTime = phaseTime;
    rt.explicitTime = time;
    if (time !== undefined) {
      rt.clockSec = time;
    }
    rt.dragProgress = dragProgress;
    rt.cornerRadiusRatio = cornerRadiusRatio;
    rt.cornerRadiusPx = cornerRadiusPx;
    rt.smoothCorner = smoothCorner;
    rt.paused = paused;
    rt.reducedMotion = effectiveReducedMotion;
    rt.maxDpr = Math.max(1, maxDpr);
    rt.onTelemetry = onTelemetry;

    // Trigger an immediate synchronous redraw if WebGL2 is paused or under reduced motion
    renderOnceRef.current?.();
  }, [
    palette,
    phase,
    phaseTime,
    time,
    dragProgress,
    cornerRadiusRatio,
    cornerRadiusPx,
    smoothCorner,
    paused,
    effectiveReducedMotion,
    maxDpr,
    crossfadeDuration,
    onTelemetry,
  ]);

  // Main WebGL2 lifecycle, ResizeObserver, context-loss handling, and rAF loop
  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (renderer === 'css') {
      setActiveRenderer('css');
      return;
    }

    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;

    let disposed = false;

    const resizeCanvas = (): void => {
      const rect = container.getBoundingClientRect();
      const rt = runtimeRef.current;
      const dpr = Math.min(window.devicePixelRatio || 1, rt.maxDpr);
      const cssW = Math.max(1, Math.round(rect.width));
      const cssH = Math.max(1, Math.round(rect.height));
      const pxW = Math.max(1, Math.round(cssW * dpr));
      const pxH = Math.max(1, Math.round(cssH * dpr));

      rt.widthCss = cssW;
      rt.heightCss = cssH;
      rt.dpr = dpr;

      if (canvas.width !== pxW || canvas.height !== pxH) {
        canvas.width = pxW;
        canvas.height = pxH;
      }
      const res = glResRef.current;
      if (res && !rt.contextLost) {
        res.gl.viewport(0, 0, pxW, pxH);
      }
    };

    const disposeGl = (): void => {
      const res = glResRef.current;
      if (!res) return;
      const { gl, program, vao } = res;
      if (!gl.isContextLost()) {
        if (vao) gl.deleteVertexArray(vao);
        gl.deleteProgram(program);
      }
      glResRef.current = null;
      runtimeRef.current.shaderCompiled = false;
    };

    const drawFrame = (nowMs: number): void => {
      const res = glResRef.current;
      const rt = runtimeRef.current;
      if (!res || rt.contextLost) return;

      const { gl, program, vao, uniforms } = res;
      const pxW = canvas.width;
      const pxH = canvas.height;
      if (pxW <= 0 || pxH <= 0) return;

      const t0 = performance.now();

      // Advance clock only when actively running
      const isStatic = rt.paused || rt.reducedMotion || rt.explicitTime !== undefined;
      if (rt.explicitTime !== undefined) {
        rt.clockSec = rt.explicitTime;
      } else if (!isStatic && rt.lastRafMs > 0) {
        const dt = Math.min(0.1, Math.max(0, (nowMs - rt.lastRafMs) / 1000));
        rt.clockSec += dt;
      }
      rt.lastRafMs = nowMs;

      const currentPhaseTime =
        rt.explicitPhaseTime !== undefined
          ? rt.explicitPhaseTime
          : rt.phaseStartMs > 0
            ? (nowMs - rt.phaseStartMs) / 1000
            : 0;

      // Smooth 0.5s RGB palette crossfade
      const targetPal = AURORA_PALETTES[rt.palette];
      const prevPal = AURORA_PALETTES[rt.prevPalette];
      const cfT = rt.reducedMotion
        ? 1
        : smoothstep(
            0,
            1,
            (nowMs - rt.crossfadeStartMs) / (rt.crossfadeDuration * 1000)
          );
      const colA = lerpVec3(prevPal.colA, targetPal.colA, cfT);
      const colB = lerpVec3(prevPal.colB, targetPal.colB, cfT);
      const colC = lerpVec3(prevPal.colC, targetPal.colC, cfT);
      const dragCore = lerpVec3(prevPal.dragCore, targetPal.dragCore, cfT);

      const state = computeChoreographyUniforms(
        rt.phase,
        currentPhaseTime,
        rt.dragProgress,
        rt.reducedMotion
      );

      const radiusPx =
        rt.cornerRadiusPx !== undefined
          ? rt.cornerRadiusPx * rt.dpr
          : rt.cornerRadiusRatio * pxW;

      gl.viewport(0, 0, pxW, pxH);
      gl.useProgram(program);
      if (vao) gl.bindVertexArray(vao);

      gl.uniform2f(uniforms.u_res, pxW, pxH);
      gl.uniform1f(uniforms.u_time, rt.clockSec);
      gl.uniform1f(uniforms.u_radius, radiusPx);
      gl.uniform1f(uniforms.u_smoothCorner, rt.smoothCorner ? 1.0 : 0.0);
      gl.uniform1f(uniforms.u_reducedMotion, rt.reducedMotion ? 1.0 : 0.0);
      gl.uniform1f(uniforms.u_drag, state.drag);
      gl.uniform1f(uniforms.u_bottomGain, state.bottomGain);
      gl.uniform1f(uniforms.u_edgeGain, state.edgeGain);
      gl.uniform1f(uniforms.u_wrapProgress, state.wrapProgress);
      gl.uniform1f(uniforms.u_cometPos, state.cometPos);
      gl.uniform1f(uniforms.u_cometPos2, state.cometPos2);
      gl.uniform1f(uniforms.u_split, state.split);
      gl.uniform1f(uniforms.u_vRays, state.vRays);
      gl.uniform1f(uniforms.u_orbGain, state.orbGain);
      gl.uniform1f(uniforms.u_orbY, state.orbY);
      gl.uniform1f(uniforms.u_orbSize, state.orbSize);
      gl.uniform1f(uniforms.u_seedOrbGain, state.seedOrbGain);
      gl.uniform1f(uniforms.u_flashBoost, state.flashBoost);
      gl.uniform1f(uniforms.u_sparkleGain, state.sparkleGain);
      gl.uniform1f(uniforms.u_sideCreep, state.sideCreep);
      gl.uniform3f(uniforms.u_colA, colA[0], colA[1], colA[2]);
      gl.uniform3f(uniforms.u_colB, colB[0], colB[1], colB[2]);
      gl.uniform3f(uniforms.u_colC, colC[0], colC[1], colC[2]);
      gl.uniform3f(uniforms.u_dragCore, dragCore[0], dragCore[1], dragCore[2]);

      gl.drawArrays(gl.TRIANGLES, 0, 3);
      if (vao) gl.bindVertexArray(null);

      const drawMs = performance.now() - t0;
      rt.frameCount += 1;
      rt.lastDrawMs = drawMs;
      rt.avgDrawMs =
        rt.frameCount === 1 ? drawMs : rt.avgDrawMs * 0.92 + drawMs * 0.08;

      rt.fpsAccumFrames += 1;
      if (rt.fpsWindowStartMs === 0) {
        rt.fpsWindowStartMs = nowMs;
      } else if (nowMs - rt.fpsWindowStartMs >= 500) {
        rt.fps = (rt.fpsAccumFrames * 1000) / (nowMs - rt.fpsWindowStartMs);
        rt.fpsAccumFrames = 0;
        rt.fpsWindowStartMs = nowMs;
      }

      if (rt.onTelemetry && nowMs - rt.lastTelemetryMs >= 250) {
        rt.lastTelemetryMs = nowMs;
        rt.onTelemetry({
          renderer: 'webgl2',
          palette: rt.palette,
          phase: rt.phase,
          time: rt.clockSec,
          phaseTime: currentPhaseTime,
          dragProgress: rt.dragProgress,
          smoothCorner: rt.smoothCorner,
          reducedMotion: rt.reducedMotion,
          paused: rt.paused,
          dpr: rt.dpr,
          width: pxW,
          height: pxH,
          fps: rt.fps,
          lastDrawMs: rt.lastDrawMs,
          avgDrawMs: rt.avgDrawMs,
          frameCount: rt.frameCount,
          shaderCompiled: rt.shaderCompiled,
          contextLost: rt.contextLost,
        });
      }
    };

    const stopLoop = (): void => {
      if (rafIdRef.current !== null) {
        cancelAnimationFrame(rafIdRef.current);
        rafIdRef.current = null;
      }
    };

    const tick = (nowMs: number): void => {
      if (disposed) return;
      rafIdRef.current = null;
      const rt = runtimeRef.current;
      drawFrame(nowMs);

      const cfActive =
        !rt.reducedMotion &&
        nowMs - rt.crossfadeStartMs < rt.crossfadeDuration * 1000 + 34;
      const shouldContinue =
        !rt.contextLost &&
        ((!rt.paused && !rt.reducedMotion && rt.explicitTime === undefined) ||
          cfActive);

      if (shouldContinue) {
        rafIdRef.current = requestAnimationFrame(tick);
      } else {
        rt.lastRafMs = 0;
      }
    };

    const scheduleFrame = (): void => {
      if (disposed || runtimeRef.current.contextLost) return;
      if (rafIdRef.current === null) {
        rafIdRef.current = requestAnimationFrame(tick);
      }
    };

    renderOnceRef.current = () => {
      if (disposed) return;
      const now = performance.now();
      drawFrame(now);
      const rt = runtimeRef.current;
      const cfActive =
        !rt.reducedMotion &&
        now - rt.crossfadeStartMs < rt.crossfadeDuration * 1000 + 34;
      if (
        (!rt.paused && !rt.reducedMotion && rt.explicitTime === undefined) ||
        cfActive
      ) {
        scheduleFrame();
      } else {
        stopLoop();
      }
    };

    resizeCanvas();
    const resources = initWebGL2(canvas);
    if (!resources) {
      runtimeRef.current.shaderCompiled = false;
      setActiveRenderer('css');
      return () => {
        disposed = true;
        renderOnceRef.current = null;
      };
    }

    glResRef.current = resources;
    runtimeRef.current.shaderCompiled = true;
    runtimeRef.current.contextLost = false;
    runtimeRef.current.phaseStartMs = performance.now();
    setActiveRenderer('webgl2');

    const handleContextLost = (event: Event): void => {
      event.preventDefault();
      runtimeRef.current.contextLost = true;
      stopLoop();
      if (renderer === 'auto') {
        setActiveRenderer('css');
      }
    };

    const handleContextRestored = (): void => {
      if (disposed) return;
      const restored = initWebGL2(canvas);
      if (restored) {
        glResRef.current = restored;
        runtimeRef.current.contextLost = false;
        runtimeRef.current.shaderCompiled = true;
        setActiveRenderer('webgl2');
        resizeCanvas();
        drawFrame(performance.now());
        scheduleFrame();
      }
    };

    canvas.addEventListener('webglcontextlost', handleContextLost);
    canvas.addEventListener('webglcontextrestored', handleContextRestored);

    let ro: ResizeObserver | null = null;
    if (typeof ResizeObserver !== 'undefined') {
      ro = new ResizeObserver(() => {
        resizeCanvas();
        drawFrame(performance.now());
      });
      ro.observe(container);
    }

    // Render initial frame immediately and kick off loop when animated
    drawFrame(performance.now());
    scheduleFrame();

    return () => {
      disposed = true;
      renderOnceRef.current = null;
      stopLoop();
      ro?.disconnect();
      canvas.removeEventListener('webglcontextlost', handleContextLost);
      canvas.removeEventListener('webglcontextrestored', handleContextRestored);
      disposeGl();
    };
  }, [renderer]);

  const pal = AURORA_PALETTES[palette];
  const cssState = computeChoreographyUniforms(
    phase,
    phaseTime ?? 0,
    dragProgress,
    effectiveReducedMotion
  );

  const rootBorderRadius =
    cornerRadiusPx !== undefined
      ? `${cornerRadiusPx}px`
      : style?.borderRadius ?? '44px';

  const cssVars = {
    '--aurora-a': pal.cssStops.a,
    '--aurora-b': pal.cssStops.b,
    '--aurora-c': pal.cssStops.c,
    '--aurora-rim': pal.cssStops.rim,
    '--aurora-edge-opacity': String(clamp01(cssState.edgeGain)),
    '--aurora-bottom-opacity': String(
      clamp01(cssState.bottomGain * (0.72 + 0.28 * cssState.drag))
    ),
    '--aurora-curtain-h': `${Math.round(lerp(28, 70, cssState.drag))}%`,
  } as CSSProperties;

  const isCssAnimated =
    activeRenderer === 'css' && !paused && !effectiveReducedMotion;

  return (
    <div
      ref={containerRef}
      id={instanceId}
      className={className}
      data-aurora-renderer={activeRenderer}
      data-aurora-palette={palette}
      data-aurora-phase={phase}
      style={{
        position: 'relative',
        overflow: 'hidden',
        backgroundColor: '#000000',
        borderRadius: rootBorderRadius,
        ...style,
      }}
    >
      <canvas
        ref={canvasRef}
        aria-hidden="true"
        style={{
          position: 'absolute',
          inset: 0,
          width: '100%',
          height: '100%',
          display: activeRenderer === 'webgl2' ? 'block' : 'none',
          pointerEvents: 'none',
        }}
      />

      {activeRenderer === 'css' ? (
        <div
          className="sdf-edge-aurora-css"
          aria-hidden="true"
          data-animated={isCssAnimated ? 'true' : 'false'}
          style={cssVars}
        >
          <div className="sdf-edge-aurora-css__layer sdf-edge-aurora-css__bottom-pool" />
          <div className="sdf-edge-aurora-css__layer sdf-edge-aurora-css__veil-wrap">
            <div className="sdf-edge-aurora-css__ring sdf-edge-aurora-css__veil" />
          </div>
          <div className="sdf-edge-aurora-css__layer sdf-edge-aurora-css__rim-wrap">
            <div className="sdf-edge-aurora-css__ring sdf-edge-aurora-css__rim" />
          </div>
          <div className="sdf-edge-aurora-css__layer sdf-edge-aurora-css__core-wrap">
            <div className="sdf-edge-aurora-css__ring sdf-edge-aurora-css__core" />
          </div>
          <div className="sdf-edge-aurora-css__layer sdf-edge-aurora-css__top-guard" />
          <div className="sdf-edge-aurora-css__layer sdf-edge-aurora-css__dither" />
        </div>
      ) : null}

      {children ? (
        <div
          style={{
            position: 'relative',
            zIndex: 1,
            width: '100%',
            height: '100%',
          }}
        >
          {children}
        </div>
      ) : null}

      {announceStatus ? (
        <div
          role="status"
          aria-live="polite"
          aria-atomic="true"
          className="sdf-edge-aurora-sr-only"
        >
          {`${pal.label} aurora, ${phase} state${paused ? ', paused' : ''}`}
        </div>
      ) : null}
    </div>
  );
}

export default SdfEdgeAurora;
