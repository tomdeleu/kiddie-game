import RealityKit
import simd

/// Little faceted bits that fly out and vanish.
///
/// **Not a particle system.** `ParticleEmitterComponent` would do this, but its
/// output is soft round billboards — which is the one thing this art direction
/// does not have. Twelve 20-face icospheres thrown by the same clock as
/// everything else stay inside the style, and cost nothing at this scale.
///
/// This is the game's whole reward vocabulary. `CONCEPT.md` §5: rewards are
/// animation and sound, because points are meaningless to a pre-reader.
@MainActor
enum Sparkles {

    /// A burst of bits from a point. The default is the "well done" sparkle.
    static func burst(at position: SIMD3<Float>,
                      in parent: Entity,
                      ticker: Ticker,
                      colour: UIColorLike = Palette.creamLight,
                      count: Int = 12,
                      size: Float = 0.0026,
                      speed: Float = 0.09,
                      gravity: Float = 0.18,
                      life: Float = 0.75) {
        let geometry = FacetedMesh.icosphere(radius: size, subdivisions: 0)
        let mesh = FacetedMesh.flatShaded(positions: geometry.positions,
                                          indices: geometry.indices)
        var material = UnlitMaterial(color: colour)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.95))

        for _ in 0..<count {
            let bit = ModelEntity(mesh: mesh, materials: [material])
            bit.name = "Sparkle"
            bit.position = position

            // Up-biased hemisphere, so a burst reads as *pop* rather than spray.
            let angle = Float.random(in: 0..<(2 * .pi))
            let lift = Float.random(in: 0.45...1.0)
            let spread = Float.random(in: 0.35...1.0)
            var velocity = SIMD3<Float>(cos(angle) * spread, lift, sin(angle) * spread)
            velocity *= speed * Float.random(in: 0.7...1.3)

            let spin = simd_quatf(angle: Float.random(in: 1...4),
                                  axis: normalize(SIMD3<Float>(
                                    Float.random(in: -1...1),
                                    Float.random(in: -1...1),
                                    Float.random(in: -1...1))))
            let lifetime = life * Float.random(in: 0.75...1.25)

            parent.addChild(bit)
            var age: Float = 0
            var v = velocity
            ticker.add { [weak bit] dt in
                guard let bit else { return false }
                age += dt
                guard age < lifetime else {
                    bit.removeFromParent()
                    return false
                }
                v.y -= gravity * dt
                bit.position += v * dt
                // Identity written out: `simd_quatf()` is the *zero* quaternion,
                // not the identity one, and slerping from it gives NaNs.
                let identity = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
                bit.orientation = simd_slerp(identity, spin, min(1, age / lifetime))
                // Shrink away rather than blinking out.
                let remaining = 1 - age / lifetime
                bit.scale = SIMD3<Float>(repeating: max(0.02, remaining))
                return true
            }
        }
    }

    /// Slower, bigger, hangs in the air. Steam off a chimney.
    static func puff(at position: SIMD3<Float>,
                     in parent: Entity,
                     ticker: Ticker,
                     colour: UIColorLike = Palette.creamLight,
                     count: Int = 9) {
        burst(at: position, in: parent, ticker: ticker, colour: colour,
              count: count, size: 0.005, speed: 0.045, gravity: 0.02, life: 1.5)
    }

    /// **A cloud of flour**, per `references/ingredients/flour-cloud.png`.
    ///
    /// The flour sack used to poof `Sparkles.puff` — twelve unlit spheres
    /// thrown on a ballistic arc, which is a firework, not a cloud. What the
    /// plate shows is a *cluster*: a few big overlapping lobes that swell and
    /// lift slowly together, ringed by small satellites drifting further out
    /// and fading first.
    ///
    /// Four things separate it from a burst, and all four matter:
    ///
    /// - **It swells.** Each lobe grows to two or three times its size instead
    ///   of shrinking away, which is the difference between dust dispersing
    ///   and debris flying.
    /// - **It is lit.** `Palette.fadingMaterial`, not `UnlitMaterial`, so the
    ///   facets still shade and the cloud has a light side.
    /// - **It barely moves outward.** Drift is a tenth of a sparkle's speed,
    ///   with no gravity — flour hangs.
    /// - **It fades in steps.** Opacity is quantised to eight levels, so a
    ///   sixteen-lobe cloud rebuilds a handful of materials a second rather
    ///   than a thousand.
    static func cloud(at position: SIMD3<Float>,
                      in parent: Entity,
                      ticker: Ticker,
                      colour: UIColorLike = Palette.creamLight,
                      scale: Float = 1.0) {
        // Big lobes first, then the satellites. Radius, offset, and how long it
        // stays — the outliers go first, which is what makes it thin from the
        // edges inward.
        struct Lobe { let radius: Float; let offset: SIMD3<Float>; let life: Float }
        var lobes: [Lobe] = []
        for i in 0..<6 {
            let a = Float(i) / 6 * 2 * .pi + Float.random(in: -0.3...0.3)
            let r = Float.random(in: 0.004...0.007) * scale
            lobes.append(Lobe(radius: r,
                              offset: SIMD3<Float>(cos(a) * 0.006 * scale,
                                                   Float.random(in: -0.002...0.005) * scale,
                                                   sin(a) * 0.006 * scale),
                              life: Float.random(in: 1.5...2.1)))
        }
        for i in 0..<10 {
            let a = Float(i) / 10 * 2 * .pi + Float.random(in: -0.4...0.4)
            let spread = Float.random(in: 0.011...0.019) * scale
            lobes.append(Lobe(radius: Float.random(in: 0.0014...0.0030) * scale,
                              offset: SIMD3<Float>(cos(a) * spread,
                                                   Float.random(in: -0.004...0.008) * scale,
                                                   sin(a) * spread),
                              life: Float.random(in: 0.9...1.5)))
        }

        for lobe in lobes {
            let geometry = FacetedMesh.icosphere(radius: lobe.radius, subdivisions: 1)
            let mesh = FacetedMesh.flatShaded(positions: geometry.positions,
                                              indices: geometry.indices)
            let blob = ModelEntity(mesh: mesh,
                                   materials: [Palette.fadingMaterial(colour, opacity: 0.85)])
            // Named like a sparkle so `Halo.surfaces` keeps stepping over it if
            // one drifts through a prop that happens to be lit.
            blob.name = "Sparkle"
            blob.position = position + lobe.offset
            blob.scale = SIMD3<Float>(repeating: 0.35)
            parent.addChild(blob)

            // Outward and up, slowly. The lift is what says flour rather than
            // smoke: it rises, but only just.
            let drift = normalize(SIMD3<Float>(lobe.offset.x, 0.0001, lobe.offset.z))
                * Float.random(in: 0.006...0.014)
                + SIMD3<Float>(0, Float.random(in: 0.008...0.016), 0)
            let start = blob.position
            var age: Float = 0
            var lastStep = -1
            ticker.add { [weak blob] dt in
                guard let blob else { return false }
                age += dt
                guard age < lobe.life else {
                    blob.removeFromParent()
                    return false
                }
                let t = age / lobe.life
                blob.position = start + drift * age
                // Swells fast at first and then eases, the way a puff does.
                let remaining = 1 - t
                blob.scale = SIMD3<Float>(repeating: 0.35 + 2.0 * (1 - remaining * remaining))
                let step = Int((1 - t) * 8)
                if step != lastStep {
                    lastStep = step
                    blob.model?.materials = [
                        Palette.fadingMaterial(colour, opacity: 0.85 * Float(step) / 8)
                    ]
                }
                return true
            }
        }
    }

    /// A ring that expands and fades on a surface — the "that worked" cue for a
    /// drop, where a vertical burst would be hidden by the prop that landed.
    static func ring(at position: SIMD3<Float>,
                     in parent: Entity,
                     ticker: Ticker,
                     colour: UIColorLike = Palette.creamLight,
                     radius: Float = 0.05) {
        let geometry = FacetedMesh.prism(radius: 1, height: 0.0008, sides: 12)
        let mesh = FacetedMesh.flatShaded(positions: geometry.positions,
                                          indices: geometry.indices)
        var material = UnlitMaterial(color: colour)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.5))

        let ring = ModelEntity(mesh: mesh, materials: [material])
        ring.name = "SparkleRing"
        ring.position = position
        ring.scale = SIMD3<Float>(0.01, 1, 0.01)
        parent.addChild(ring)

        ticker.tween(0.5, ease: Ease.out, step: { [weak ring] t in
            guard let ring else { return }
            let r = radius * t
            ring.scale = SIMD3<Float>(r, 1, r)
            var fading = UnlitMaterial(color: colour)
            fading.blending = .transparent(opacity: .init(floatLiteral: 0.5 * (1 - t)))
            ring.model?.materials = [fading]
        }, done: { [weak ring] in ring?.removeFromParent() })
    }
}
