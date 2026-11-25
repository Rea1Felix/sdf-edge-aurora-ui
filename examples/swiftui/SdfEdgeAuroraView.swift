// SdfEdgeAuroraView.swift
// Clean-room SwiftUI + Metal SDF Edge-Glow Aurora Component (`Tide Send`)
// Compatible with Swift 6 (`-swift-version 6 -warnings-as-errors`), macOS 14+ and iOS 17+.

import Observation
import SwiftUI

// MARK: - Palette Model & Verified 4-Theme Color Dictionary

public struct AuroraRGB: Equatable, Hashable, Sendable {
    public let r: Double
    public let g: Double
    public let b: Double

    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    public var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }

    public var linearRGB: (r: Double, g: Double, b: Double) {
        (Self.toLinear(r), Self.toLinear(g), Self.toLinear(b))
    }

    public func interpolated(to other: AuroraRGB, t: Double) -> AuroraRGB {
        let clamped = min(max(t, 0.0), 1.0)
        return AuroraRGB(
            r: r + (other.r - r) * clamped,
            g: g + (other.g - g) * clamped,
            b: b + (other.b - b) * clamped
        )
    }

    private static func toLinear(_ c: Double) -> Double {
        let x = max(c, 0.0)
        return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
    }
}

public struct AuroraPaletteStops: Equatable, Sendable {
    public let colA: AuroraRGB
    public let colB: AuroraRGB
    public let colC: AuroraRGB
    public let checkmark: AuroraRGB

    public init(colA: AuroraRGB, colB: AuroraRGB, colC: AuroraRGB, checkmark: AuroraRGB) {
        self.colA = colA
        self.colB = colB
        self.colC = colC
        self.checkmark = checkmark
    }

    public func interpolated(to other: AuroraPaletteStops, progress: Double) -> AuroraPaletteStops {
        AuroraPaletteStops(
            colA: colA.interpolated(to: other.colA, t: progress),
            colB: colB.interpolated(to: other.colB, t: progress),
            colC: colC.interpolated(to: other.colC, t: progress),
            checkmark: checkmark.interpolated(to: other.checkmark, t: progress)
        )
    }
}

public enum AuroraPalette: String, CaseIterable, Identifiable, Sendable {
    case ocean
    case sunset
    case aurora
    case pearl

    public static let defaultPalette: AuroraPalette = .pearl

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        case .aurora: return "Aurora"
        case .pearl: return "Pearl"
        }
    }

    public var subtitle: String {
        switch self {
        case .ocean: return "Indigo · Cobalt · Cyan"
        case .sunset: return "Magenta · Coral · Amber"
        case .aurora: return "Emerald · Seafoam · Mint"
        case .pearl: return "Ice-Blue · Lavender · Silver"
        }
    }

    /// Verified sRGB color stops derived from forensic pixel telemetry across all 4 cycles.
    /// Notably, `.pearl` (Pearl Silver) carries subtle cool ice-blue (~216 deg) and
    /// pearl-lavender (~250 deg) chroma modulation rather than flat neutral gray.
    public var stops: AuroraPaletteStops {
        switch self {
        case .ocean:
            return AuroraPaletteStops(
                colA: AuroraRGB(r: 0.180, g: 0.855, b: 0.990), // Electric cyan-aqua (#2EDAFD)
                colB: AuroraRGB(r: 0.360, g: 0.500, b: 0.960), // Cobalt-periwinkle (#5C80F5)
                colC: AuroraRGB(r: 0.455, g: 0.355, b: 0.925), // Deep indigo-violet (#745BEC)
                checkmark: AuroraRGB(r: 0.529, g: 0.910, b: 0.957) // #87E8F4
            )
        case .sunset:
            return AuroraPaletteStops(
                colA: AuroraRGB(r: 1.000, g: 0.720, b: 0.340), // Warm amber-gold (#FFB857)
                colB: AuroraRGB(r: 0.960, g: 0.420, b: 0.425), // Luminous salmon-coral (#F56B6C)
                colC: AuroraRGB(r: 0.880, g: 0.240, b: 0.580), // Deep rose-magenta (#E03D94)
                checkmark: AuroraRGB(r: 0.953, g: 0.827, b: 0.549) // #F3D38C
            )
        case .aurora:
            return AuroraPaletteStops(
                colA: AuroraRGB(r: 0.340, g: 0.985, b: 0.900), // Electric ice-mint (#57FBE6)
                colB: AuroraRGB(r: 0.215, g: 0.880, b: 0.700), // Seafoam emerald (#37E0B3)
                colC: AuroraRGB(r: 0.105, g: 0.675, b: 0.535), // Deep jade-teal (#1BAC88)
                checkmark: AuroraRGB(r: 0.537, g: 0.961, b: 0.859) // #89F5DB
            )
        case .pearl:
            return AuroraPaletteStops(
                colA: AuroraRGB(r: 0.745, g: 0.835, b: 0.950), // Cool ice-blue silver (~214 deg, #BED5F2)
                colB: AuroraRGB(r: 0.850, g: 0.815, b: 0.945), // Luminous pearl-lavender (~256 deg, #D9D0F1)
                colC: AuroraRGB(r: 0.565, g: 0.610, b: 0.735), // Cool graphite-platinum (~224 deg, #909CBB)
                checkmark: AuroraRGB(r: 1.000, g: 1.000, b: 1.000) // Pure crisp white (#FFFFFF)
            )
        }
    }

    public var next: AuroraPalette {
        switch self {
        case .ocean: return .sunset
        case .sunset: return .aurora
        case .aurora: return .pearl
        case .pearl: return .ocean
        }
    }
}

// MARK: - 7-State Interaction Choreography Machine

public enum TideSendPhase: Equatable, Sendable {
    /// Settled bottom-anchored aurora pool waiting for Lift-to-Pay gesture.
    case idle
    /// Interactive vertical lift (`progress` in `0...1`).
    case dragging(progress: Double)
    /// 0.33s release launch: dark vertical split channel, twin bezel wrap, top-corner V-rays.
    case releasing(progress: Double)
    /// ~1.55s network payment call: twin mirror-symmetric upward perimeter comets + breathing orb.
    case sending(elapsed: Double)
    /// ~2.93s confirmation: <100ms 2.5-3x flash settling into sustained 360-deg breathing aurora.
    case success(elapsed: Double)
    /// 0.43s time-reversed symmetric downward drain back into Idle bottom pool.
    case dismissing(progress: Double)
    /// 0.50s smooth RGB crossfade between palettes in settled Idle pool.
    case crossfading(from: AuroraPalette, to: AuroraPalette, progress: Double)

    public var phaseName: String {
        switch self {
        case .idle: return "idle"
        case .dragging: return "dragging"
        case .releasing: return "releasing"
        case .sending: return "sending"
        case .success: return "success"
        case .dismissing: return "dismissing"
        case .crossfading: return "crossfading"
        }
    }
}

public enum TideSendTiming {
    public static let releaseDuration: Double = 0.33
    public static let sendingDuration: Double = 1.55
    public static let cometTransitDuration: Double = 1.17
    public static let cometCadence: Double = 1.05
    public static let successFlashDuration: Double = 0.25
    public static let successAmountCountDuration: Double = 0.73
    public static let successCheckmarkDelay: Double = 0.08
    public static let successCheckmarkDuration: Double = 0.53
    public static let successSteadyDuration: Double = 2.93
    public static let dismissDuration: Double = 0.43
    public static let crossfadeDuration: Double = 0.50
    public static let commitDragThreshold: Double = 0.55
    public static let cornerRadiusRatio: Double = 0.154
}

/// Deterministic shader uniform payload resolved from the 7-state machine.
public struct TideAuroraUniforms: Equatable, Sendable {
    public let dragProgress: Float
    public let edgeGain: Float
    public let cometProgress: Float
    public let splitProgress: Float
    public let vRayGain: Float
    public let orbGain: Float
    public let drainCutoff: Float
    public let smoothCorner: Float
    public let reduceMotion: Float
    public let orbYNorm: Float
    public let sparkleGain: Float
    public let edrHeadroom: Float
    public let stops: AuroraPaletteStops

    public static func resolve(
        phase: TideSendPhase,
        palette: AuroraPalette,
        smoothCorner: Bool = true,
        reduceMotion: Bool = false,
        edrHeadroom: Float = 0.0
    ) -> TideAuroraUniforms {
        var drag: Double = 0.0
        var edge: Double = 0.0
        var comet: Double = -1.0
        var split: Double = 0.0
        var vRay: Double = 0.0
        var orb: Double = 0.0
        var drain: Double = 1.2
        var orbY: Double = 0.208
        var sparkle: Double = 0.0
        var stops = palette.stops

        switch phase {
        case .idle:
            drag = 0.0
            edge = 0.0
            sparkle = reduceMotion ? 0.0 : 0.35

        case .dragging(let rawProgress):
            let p = clamp01(rawProgress)
            drag = reduceMotion ? min(p * 0.45, 0.45) : p
            edge = 0.0
            sparkle = reduceMotion ? 0.0 : (0.35 + 0.65 * p)

        case .releasing(let rawProgress):
            let p = clamp01(rawProgress)
            if reduceMotion {
                drag = 0.25 * (1.0 - p)
                edge = 0.35 * p
                drain = 1.2
            } else {
                let eased = easeOutCubic(p)
                drag = 1.0 - 0.55 * eased
                // Twin symmetric curtains rapidly wrap bezel BotCtr -> TopCtr
                drain = 0.10 + 1.08 * eased
                edge = 0.08 + 0.52 * eased
                // Dramatic dark vertical center split peaks at p ~ 0.45
                split = sin(p * .pi)
                // Top-corner V-rays flare sharply around p ~ 0.35..0.75
                vRay = sin(clamp01((p - 0.12) / 0.88) * .pi) * 0.95
                // Launch orb rises toward upper vanishing point
                orb = smoothstep(0.05, 0.45, p) * 0.90
                orbY = 0.46 - 0.252 * eased
                sparkle = (1.0 - eased) * 0.65
            }

        case .sending(let elapsed):
            let t = max(elapsed, 0.0)
            edge = reduceMotion ? 0.45 : 0.30
            drain = 1.2
            orb = reduceMotion ? 0.50 : (0.65 + 0.25 * smoothstep(0.0, 0.45, t))
            orbY = 0.208
            if !reduceMotion {
                // Twin mirror-symmetric upward comets repeating every ~1.05s
                let waveT = t.truncatingRemainder(dividingBy: TideSendTiming.cometCadence)
                let progress = waveT / TideSendTiming.cometTransitDuration
                comet = progress <= 1.12 ? progress : -1.0
            }

        case .success(let elapsed):
            let t = max(elapsed, 0.0)
            drain = 1.2
            if reduceMotion {
                edge = 1.0
                orb = 0.0
            } else {
                // Fast <100ms 2.5-3x flash surge settling cleanly into steady 1.0 border
                let flashBoost = 0.72 * exp(-t / 0.18) * smoothstep(0.0, 0.05, t)
                edge = 1.0 + flashBoost
                orb = 0.55 * exp(-t / 0.20)
            }

        case .dismissing(let rawProgress):
            let p = clamp01(rawProgress)
            if reduceMotion {
                edge = 1.0 - p
                drain = 1.2
            } else {
                let eased = easeInOutCubic(p)
                // Time-reversed mirror of Release: drains symmetrically TopCtr -> BotCtr
                drain = 1.12 * (1.0 - eased)
                edge = 0.88 * (1.0 - eased)
                split = sin(p * .pi) * 0.65
                vRay = sin(clamp01(p / 0.55) * .pi) * 0.55
                drag = 0.32 * sin(p * .pi)
                sparkle = eased * 0.35
            }

        case .crossfading(let from, let to, let rawProgress):
            let p = clamp01(rawProgress)
            let eased = smoothstep(0.0, 1.0, p)
            stops = from.stops.interpolated(to: to.stops, progress: eased)
            drag = 0.0
            edge = 0.0
            sparkle = reduceMotion ? 0.0 : 0.35
        }

        return TideAuroraUniforms(
            dragProgress: Float(drag),
            edgeGain: Float(edge),
            cometProgress: Float(comet),
            splitProgress: Float(split),
            vRayGain: Float(vRay),
            orbGain: Float(orb),
            drainCutoff: Float(drain),
            smoothCorner: smoothCorner ? 1.0 : 0.0,
            reduceMotion: reduceMotion ? 1.0 : 0.0,
            orbYNorm: Float(orbY),
            sparkleGain: Float(sparkle),
            edrHeadroom: edrHeadroom,
            stops: stops
        )
    }

    private static func clamp01(_ x: Double) -> Double {
        min(max(x, 0.0), 1.0)
    }

    private static func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        guard edge1 > edge0 else { return x >= edge1 ? 1.0 : 0.0 }
        let t = clamp01((x - edge0) / (edge1 - edge0))
        return t * t * (3.0 - 2.0 * t)
    }

    private static func easeOutCubic(_ t: Double) -> Double {
        let u = 1.0 - clamp01(t)
        return 1.0 - u * u * u
    }

    private static func easeInOutCubic(_ t: Double) -> Double {
        let x = clamp01(t)
        return x < 0.5 ? 4.0 * x * x * x : 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0
    }
}

// MARK: - Interactive State Controller (MainActor-Isolated, Swift 6 Safe)

@MainActor
@Observable
public final class TideSendController {
    public var palette: AuroraPalette
    public private(set) var phase: TideSendPhase = .idle
    public var isAutoLooping: Bool = false

    private var activeTask: Task<Void, Never>?

    public init(palette: AuroraPalette = .defaultPalette) {
        self.palette = palette
    }

    public func updateDrag(progress: Double) {
        cancelTransitions()
        let clamped = min(max(progress, 0.0), 1.0)
        phase = .dragging(progress: clamped)
    }

    public func endDrag(progress: Double, reduceMotion: Bool = false) {
        if progress >= TideSendTiming.commitDragThreshold {
            triggerPayment(reduceMotion: reduceMotion)
        } else {
            cancelTransitions()
            phase = .idle
        }
    }

    public func triggerPayment(reduceMotion: Bool = false) {
        cancelTransitions()
        activeTask = Task { [weak self] in
            guard let self else { return }
            await self.runStepAnimation(duration: TideSendTiming.releaseDuration) { p in
                self.phase = .releasing(progress: p)
            }
            guard !Task.isCancelled else { return }

            Self.postAccessibilityAnnouncement("Sending 680 euros to Marco Bellini")
            await self.runElapsedAnimation(duration: TideSendTiming.sendingDuration) { elapsed in
                self.phase = .sending(elapsed: elapsed)
            }
            guard !Task.isCancelled else { return }

            Self.postAccessibilityAnnouncement("Payment complete. Paid 680 euros to Marco Bellini.")
            self.phase = .success(elapsed: 0.0)

            // Drive success landing sequence (amount count-up, checkmark draw, flash settle)
            await self.runElapsedAnimation(duration: TideSendTiming.successSteadyDuration) { elapsed in
                self.phase = .success(elapsed: elapsed)
            }
            guard !Task.isCancelled else { return }

            if self.isAutoLooping && !reduceMotion {
                await self.dismissAndCycleNext(reduceMotion: reduceMotion)
            }
        }
    }

    public func dismiss() {
        cancelTransitions()
        activeTask = Task { [weak self] in
            guard let self else { return }
            await self.runStepAnimation(duration: TideSendTiming.dismissDuration) { p in
                self.phase = .dismissing(progress: p)
            }
            guard !Task.isCancelled else { return }
            self.phase = .idle
        }
    }

    public func selectPalette(_ next: AuroraPalette) {
        guard next != palette else { return }
        let current = palette
        if case .idle = phase {
            cancelTransitions()
            activeTask = Task { [weak self] in
                guard let self else { return }
                await self.runStepAnimation(duration: TideSendTiming.crossfadeDuration) { p in
                    self.phase = .crossfading(from: current, to: next, progress: p)
                }
                guard !Task.isCancelled else { return }
                self.palette = next
                self.phase = .idle
            }
        } else {
            palette = next
        }
    }

    public func setPhaseDirectly(_ newPhase: TideSendPhase) {
        cancelTransitions()
        phase = newPhase
    }

    public func toggleAutoLoop(reduceMotion: Bool) {
        isAutoLooping.toggle()
        if isAutoLooping {
            startAutoLoop(reduceMotion: reduceMotion)
        } else {
            cancelTransitions()
            phase = .idle
        }
    }

    public func stop() {
        isAutoLooping = false
        cancelTransitions()
    }

    private func startAutoLoop(reduceMotion: Bool) {
        cancelTransitions()
        activeTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.isAutoLooping {
                self.phase = .idle
                try? await Task.sleep(for: .milliseconds(650))
                guard !Task.isCancelled else { break }

                await self.runStepAnimation(duration: 0.93) { p in
                    self.phase = .dragging(progress: p)
                }
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { break }

                await self.runStepAnimation(duration: TideSendTiming.releaseDuration) { p in
                    self.phase = .releasing(progress: p)
                }
                guard !Task.isCancelled else { break }

                await self.runElapsedAnimation(duration: TideSendTiming.sendingDuration) { e in
                    self.phase = .sending(elapsed: e)
                }
                guard !Task.isCancelled else { break }

                await self.runElapsedAnimation(duration: TideSendTiming.successSteadyDuration) { e in
                    self.phase = .success(elapsed: e)
                }
                guard !Task.isCancelled else { break }

                await self.dismissAndCycleNext(reduceMotion: reduceMotion)
            }
        }
    }

    private func dismissAndCycleNext(reduceMotion: Bool) async {
        await runStepAnimation(duration: TideSendTiming.dismissDuration) { p in
            self.phase = .dismissing(progress: p)
        }
        guard !Task.isCancelled else { return }

        let current = palette
        let upcoming = palette.next
        if reduceMotion {
            palette = upcoming
            phase = .idle
        } else {
            await runStepAnimation(duration: TideSendTiming.crossfadeDuration) { p in
                self.phase = .crossfading(from: current, to: upcoming, progress: p)
            }
            guard !Task.isCancelled else { return }
            palette = upcoming
            phase = .idle
        }
    }

    private func cancelTransitions() {
        activeTask?.cancel()
        activeTask = nil
    }

    private func runStepAnimation(
        duration: Double,
        step: @MainActor (Double) -> Void
    ) async {
        let start = Date().timeIntervalSinceReferenceDate
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSinceReferenceDate - start
            let progress = min(max(elapsed / max(duration, 0.001), 0.0), 1.0)
            step(progress)
            if progress >= 1.0 { break }
            try? await Task.sleep(for: .milliseconds(16))
        }
    }

    private func runElapsedAnimation(
        duration: Double,
        tick: @MainActor (Double) -> Void
    ) async {
        let start = Date().timeIntervalSinceReferenceDate
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSinceReferenceDate - start
            tick(min(elapsed, duration))
            if elapsed >= duration { break }
            try? await Task.sleep(for: .milliseconds(16))
        }
    }

    private static func postAccessibilityAnnouncement(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }
}

// MARK: - Core EdgeAuroraBackdrop View (Metal Shader + Pure-SwiftUI Fallback)

public struct EdgeAuroraBackdrop: View {
    public let palette: AuroraPalette
    public let phase: TideSendPhase
    public let cornerRadius: CGFloat?
    public let smoothCorner: Bool
    public let useMetal: Bool
    public let shaderLibrary: ShaderLibrary
    public let edrHeadroom: Float
    public let overrideTime: Double?

    @Environment(\.accessibilityReduceMotion) private var envReduceMotion
    public let forceReduceMotion: Bool?

    public init(
        palette: AuroraPalette = .defaultPalette,
        phase: TideSendPhase = .idle,
        cornerRadius: CGFloat? = nil,
        smoothCorner: Bool = true,
        useMetal: Bool = true,
        shaderLibrary: ShaderLibrary = .default,
        edrHeadroom: Float = 0.0,
        overrideTime: Double? = nil,
        forceReduceMotion: Bool? = nil
    ) {
        self.palette = palette
        self.phase = phase
        self.cornerRadius = cornerRadius
        self.smoothCorner = smoothCorner
        self.useMetal = useMetal
        self.shaderLibrary = shaderLibrary
        self.edrHeadroom = edrHeadroom
        self.overrideTime = overrideTime
        self.forceReduceMotion = forceReduceMotion
    }

    private var reduceMotion: Bool {
        forceReduceMotion ?? envReduceMotion
    }

    public var body: some View {
        TimelineView(.animation(paused: reduceMotion || overrideTime != nil)) { timeline in
            let unifiedTime: Double = {
                if let fixed = overrideTime {
                    return reduceMotion ? 0.0 : fixed
                }
                if reduceMotion { return 0.0 }
                return timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000.0)
            }()

            let uniforms = TideAuroraUniforms.resolve(
                phase: phase,
                palette: palette,
                smoothCorner: smoothCorner,
                reduceMotion: reduceMotion,
                edrHeadroom: edrHeadroom
            )

            GeometryReader { geo in
                let radius = cornerRadius ?? (min(geo.size.width, geo.size.height) * TideSendTiming.cornerRadiusRatio)
                if useMetal {
                    Rectangle()
                        .fill(Color.black)
                        .colorEffect(
                            shaderLibrary.tideEdgeAurora(
                                .float2(geo.size),
                                .float(Float(radius)),
                                .float(Float(unifiedTime)),
                                .float4(
                                    uniforms.dragProgress,
                                    uniforms.edgeGain,
                                    uniforms.cometProgress,
                                    uniforms.splitProgress
                                ),
                                .float4(
                                    uniforms.vRayGain,
                                    uniforms.orbGain,
                                    uniforms.drainCutoff,
                                    uniforms.smoothCorner
                                ),
                                .float4(
                                    uniforms.reduceMotion,
                                    uniforms.orbYNorm,
                                    uniforms.sparkleGain,
                                    uniforms.edrHeadroom
                                ),
                                .color(uniforms.stops.colA.color),
                                .color(uniforms.stops.colB.color),
                                .color(uniforms.stops.colC.color)
                            )
                        )
                } else {
                    PureSwiftUIEdgeAuroraFallback(
                        size: geo.size,
                        cornerRadius: radius,
                        time: unifiedTime,
                        uniforms: uniforms
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Pure SwiftUI Zero-Metal Fallback Renderer

private struct PureSwiftUIEdgeAuroraFallback: View {
    let size: CGSize
    let cornerRadius: CGFloat
    let time: Double
    let uniforms: TideAuroraUniforms

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let drift = uniforms.reduceMotion > 0.5 ? 0.0 : (time / 18.0).truncatingRemainder(dividingBy: 1.0)
        let breathe = uniforms.reduceMotion > 0.5 ? 1.0 : (1.0 + 0.10 * sin(time * 1.8))
        let edgeOpacity = min(Double(uniforms.edgeGain) * breathe, 1.35)
        let bottomHeight = size.height * CGFloat(0.26 + 0.40 * Double(uniforms.dragProgress))

        let edgeGradient = LinearGradient(
            stops: [
                .init(color: uniforms.stops.colC.color, location: 0.0),
                .init(color: uniforms.stops.colB.color, location: max(0.25, 0.50 - 0.15 * sin(drift * .pi * 2.0))),
                .init(color: uniforms.stops.colA.color, location: 0.85),
                .init(color: uniforms.stops.colC.color.opacity(0.9), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        ZStack {
            Color.black

            // Bottom volumetric pool fallback (Idle / Drag)
            if uniforms.edgeGain < 0.45 {
                let bottomOpacity = max(0.0, 1.0 - Double(uniforms.edgeGain) * 2.2)
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    LinearGradient(
                        colors: [
                            Color.clear,
                            uniforms.stops.colB.color.opacity(0.55 + 0.30 * Double(uniforms.dragProgress)),
                            uniforms.stops.colA.color.opacity(0.85),
                            Color.white.opacity(0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: bottomHeight)
                    .blur(radius: size.width * 0.065)
                }
                .opacity(bottomOpacity)
            }

            // Upper-center breathing orb fallback (Sending / Release)
            if uniforms.orbGain > 0.01 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                uniforms.stops.colA.color.opacity(0.6),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: size.width * 0.12
                        )
                    )
                    .frame(width: size.width * 0.24, height: size.width * 0.24)
                    .position(x: size.width * 0.5, y: size.height * CGFloat(uniforms.orbYNorm))
                    .opacity(Double(uniforms.orbGain))
                    .blendMode(.plusLighter)
            }

            // Dual-exponential edge glow approximation (Wide Veil + Tight Rim + Incandescent Core)
            if edgeOpacity > 0.01 {
                ZStack {
                    shape
                        .strokeBorder(edgeGradient, lineWidth: max(size.width * 0.055, 16))
                        .blur(radius: size.width * 0.055)
                        .opacity(0.82 * min(edgeOpacity, 1.0))

                    shape
                        .strokeBorder(edgeGradient, lineWidth: max(size.width * 0.014, 4))
                        .blur(radius: size.width * 0.012)
                        .opacity(min(edgeOpacity, 1.0))
                        .blendMode(.plusLighter)

                    shape
                        .strokeBorder(Color.white.opacity(0.88), lineWidth: 2.0)
                        .blur(radius: 1.2)
                        .opacity(min(edgeOpacity, 1.0))
                        .blendMode(.plusLighter)
                }
                // Top-edge attenuation (~0.78x) to keep Dynamic Island & status bar crisp
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.78), location: 0.0),
                            .init(color: .white, location: 0.35),
                            .init(color: .white, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .clipShape(shape)
        .drawingGroup()
    }
}

// MARK: - Luminescent Checkmark Shape (Stroke-Drawn Success Reveal)

public struct TideCheckmarkShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.54))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.84))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.18))
        return path
    }
}

// MARK: - Interactive TideSendShowcaseView Demo

public struct TideSendShowcaseView: View {
    @State private var controller: TideSendController
    @State private var smoothCorner: Bool = true
    @State private var useMetal: Bool = true

    private let shaderLibrary: ShaderLibrary
    private let overrideTime: Double?
    private let showControls: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        initialPalette: AuroraPalette = .defaultPalette,
        initialPhase: TideSendPhase = .idle,
        shaderLibrary: ShaderLibrary = .default,
        overrideTime: Double? = nil,
        showControls: Bool = true
    ) {
        let ctrl = TideSendController(palette: initialPalette)
        ctrl.setPhaseDirectly(initialPhase)
        _controller = State(initialValue: ctrl)
        self.shaderLibrary = shaderLibrary
        self.overrideTime = overrideTime
        self.showControls = showControls
    }

    public var body: some View {
        VStack(spacing: 16) {
            phoneViewport
            if showControls {
                controlBar
            }
        }
        .padding(16)
        .onDisappear {
            controller.stop()
        }
    }

    private var phoneViewport: some View {
        let screenWidth: CGFloat = 320
        let screenHeight: CGFloat = 696 // Exact 0.460 iPhone 15/16 Pro aspect ratio
        let innerRadius = screenWidth * TideSendTiming.cornerRadiusRatio

        return ZStack {
            // Layer 0-5: Single-Pass SDF Edge-Glow Aurora Backdrop
            EdgeAuroraBackdrop(
                palette: controller.palette,
                phase: controller.phase,
                cornerRadius: innerRadius,
                smoothCorner: smoothCorner,
                useMetal: useMetal,
                shaderLibrary: shaderLibrary,
                overrideTime: overrideTime
            )

            // Layer 6: Foreground Payment UI Choreography
            VStack(spacing: 0) {
                statusBar
                    .padding(.top, 10)
                    .padding(.horizontal, 22)

                ZStack {
                    reviewPaymentLayer
                        .opacity(reviewOpacity)
                    sendingLayer
                        .opacity(sendingOpacity)
                    successLayer
                        .opacity(successOpacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: screenWidth, height: screenHeight)
        .clipShape(RoundedRectangle(cornerRadius: innerRadius, style: .continuous))
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: innerRadius + 8, style: .continuous)
                .fill(Color(red: 12.0 / 255.0, green: 12.0 / 255.0, blue: 15.0 / 255.0))
        )
        .shadow(color: .black.opacity(0.35), radius: 22, y: 12)
    }

    private var statusBar: some View {
        HStack {
            Text("09:41")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Capsule()
                .fill(Color.black)
                .frame(width: 96, height: 26)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .accessibilityHidden(true)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
        }
    }

    private var reviewPaymentLayer: some View {
        let dragProg: Double = {
            if case .dragging(let p) = controller.phase { return p }
            if case .releasing(let p) = controller.phase { return 1.0 - p }
            return 0.0
        }()
        let isReadyToRelease = dragProg >= TideSendTiming.commitDragThreshold
        let releaseProgress: Double = {
            if case .releasing(let p) = controller.phase { return p }
            return 0.0
        }()
        let amountScale = reduceMotion ? 1.0 : max(0.28, 1.0 - 0.72 * releaseProgress)
        let amountOffsetY = reduceMotion ? 0.0 : (-110.0 * releaseProgress)

        return VStack(spacing: 14) {
            Text("Review payment")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.top, 16)

            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("MB")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .padding(.top, 8)

            VStack(spacing: 4) {
                Text("To Marco Bellini")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                Text("€680.00")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(amountScale)
                    .offset(y: amountOffsetY)
                Text("Rent · November")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.50))
            }

            // Translucent dark-gray payment details card (#19191E with crisp 1px rim)
            VStack(spacing: 12) {
                detailRow(label: "From", value: "Everyday ·· 4821")
                detailRow(label: "Arrives", value: "In seconds")
                detailRow(label: "Reference", value: "RENT-NOV")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 25.0 / 255.0, green: 25.0 / 255.0, blue: 30.0 / 255.0).opacity(0.84))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .opacity(1.0 - releaseProgress)

            Spacer()

            VStack(spacing: 12) {
                Text(isReadyToRelease ? "Let go to pay" : "Lift to pay")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.90))
                    .offset(y: isReadyToRelease ? -52 : 0)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 52, height: 52)
                        .shadow(color: .white.opacity(0.35), radius: 10)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.black)
                }
                .offset(y: -CGFloat(dragProg) * 268.0)
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            let lifted = max(0, -value.translation.height)
                            controller.updateDrag(progress: Double(lifted / 210.0))
                        }
                        .onEnded { value in
                            let lifted = max(0, -value.translation.height)
                            let p = min(max(Double(lifted / 210.0), 0.0), 1.0)
                            controller.endDrag(progress: p, reduceMotion: reduceMotion)
                        }
                )
                .onTapGesture {
                    controller.triggerPayment(reduceMotion: reduceMotion)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Lift to pay €680.00 to Marco Bellini")
                .accessibilityHint("Drag upward or activate to send payment.")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    controller.triggerPayment(reduceMotion: reduceMotion)
                }
            }
            .padding(.bottom, 34)
        }
    }

    private var sendingLayer: some View {
        let elapsed: Double = {
            if case .sending(let e) = controller.phase { return e }
            return 0.0
        }()
        let revealProgress = reduceMotion ? 1.0 : min(max(elapsed / 0.80, 0.0), 1.0)

        return VStack(spacing: 6) {
            Text("Sending €680 to Marco")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .mask(
                    GeometryReader { geo in
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0.0),
                                .init(color: .white, location: max(0.0, revealProgress - 0.12)),
                                .init(color: .clear, location: min(1.0, revealProgress + 0.08))
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                )

            Text("Rent · November")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.55))
                .opacity(revealProgress)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sending 680 euros to Marco Bellini, Rent November")
    }

    private var successLayer: some View {
        let elapsed: Double = {
            if case .success(let e) = controller.phase { return e }
            return 0.0
        }()
        let amountProgress = reduceMotion ? 1.0 : min(max(elapsed / TideSendTiming.successAmountCountDuration, 0.0), 1.0)
        let easedAmount = 1.0 - pow(1.0 - amountProgress, 3.0)
        let displayedAmount = 680.0 * easedAmount

        let checkProgress = reduceMotion
            ? 1.0
            : min(max((elapsed - TideSendTiming.successCheckmarkDelay) / TideSendTiming.successCheckmarkDuration, 0.0), 1.0)
        let detailFade = reduceMotion ? 1.0 : min(max((elapsed - 0.35) / 0.45, 0.0), 1.0)
        let doneFade = reduceMotion ? 1.0 : min(max((elapsed - 0.65) / 0.33, 0.0), 1.0)
        let checkColor = controller.palette.stops.checkmark.color

        return VStack(spacing: 14) {
            ZStack {
                TideCheckmarkShape()
                    .trim(from: 0, to: checkProgress)
                    .stroke(
                        checkColor,
                        style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: 4.5)
                    .opacity(0.85)

                TideCheckmarkShape()
                    .trim(from: 0, to: checkProgress)
                    .stroke(
                        checkColor,
                        style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round)
                    )
            }
            .frame(width: 44, height: 38)
            .accessibilityHidden(true)

            Text(String(format: "€%.2f", displayedAmount))
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            VStack(spacing: 3) {
                Text("Paid to Marco Bellini")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                Text("22 Nov 2026 · 18:05")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.50))
            }
            .opacity(detailFade)

            Button {
                controller.dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
            .opacity(doneFade)
            .accessibilityLabel("Done, dismiss payment confirmation")
        }
        .accessibilityElement(children: .contain)
    }

    private var controlBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(AuroraPalette.allCases) { item in
                    Button {
                        controller.selectPalette(item)
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(item.stops.colA.color)
                                .frame(width: 8, height: 8)
                            Text(item.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(controller.palette == item ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Palette \(item.displayName), \(item.subtitle)")
                }
            }

            HStack(spacing: 12) {
                Toggle("Smooth SDF", isOn: $smoothCorner)
                    .font(.system(size: 12))
                Toggle("Metal Shader", isOn: $useMetal)
                    .font(.system(size: 12))
                Button(controller.isAutoLooping ? "Pause Demo" : "Play Loop") {
                    controller.toggleAutoLoop(reduceMotion: reduceMotion)
                }
                .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: 340)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
        }
    }

    private var reviewOpacity: Double {
        switch controller.phase {
        case .idle, .dragging, .crossfading:
            return 1.0
        case .releasing(let p):
            return max(0.0, 1.0 - p * 1.15)
        case .dismissing(let p):
            return max(0.0, (p - 0.45) / 0.55)
        case .sending, .success:
            return 0.0
        }
    }

    private var sendingOpacity: Double {
        if case .sending = controller.phase { return 1.0 }
        return 0.0
    }

    private var successOpacity: Double {
        switch controller.phase {
        case .success:
            return 1.0
        case .dismissing(let p):
            return max(0.0, 1.0 - p * 2.2)
        default:
            return 0.0
        }
    }
}
