import RealityKit
import simd

/// Little faceted bits that fly out and vanish.
///
/// **Not a particle system.** `ParticleEmitterComponent` would do this, but its
/// output is soft round billboards — which is the one thing this art direction
/// does not have. Twelve flat-shaded stars thrown by the same clock as
/// everything else stay inside the style, and cost nothing at this scale.
///
/// **They are stars, and they are yellow.** They used to be 20-face icospheres
/// in `creamLight`, which at sparkle size is a grey dot: a cream ball a couple
/// of millimetres across, unlit, against a room that is mostly cream, reads as
/// dust. A star has a silhouette that survives being three pixels wide, and
/// warm yellow is the one hue in the palette that nothing in the room is
/// painted — so a sparkle is never mistaken for a crumb of the thing it came
/// off. Callers that pass a colour still get it: an ingredient dropping into
/// the bowl throws its own colour, which is what says *that* one went in.
///
/// This is the game's whole reward vocabulary. `CONCEPT.md` §5: rewards are
/// animation and sound, because points are meaningless to a pre-reader.
@MainActor
enum Sparkles {

    /// A burst of bits from a point. The default is the "well done" sparkle.
    static func burst(at position: SIMD3<Float>,
                      in parent: Entity,
                      ticker: Ticker,
                      colour: UIColorLike = Palette.butterYellow,
                      count: Int = 12,
                      size: Float = 0.0026,
                      speed: Float = 0.09,
                      gravity: Float = 0.18,
                      life: Float = 0.75,
                      glow: Float = 0) {
        // A five-point star, thin enough to catch the light edge-on as it
        // tumbles. `size` is its outer radius, so every existing call site
        // keeps the scale it was tuned to.
        let geometry = FacetedMesh.star(points: 5, outerRadius: size * 1.6,
                                        innerRadius: size * 0.62,
                                        thickness: size * 0.5)
        let mesh = FacetedMesh.flatShaded(positions: geometry.positions,
                                          indices: geometry.indices)
        // **`glow` is off by default, and only the halo turns it on.** Sparkles
        // are usually seen against a prop or in the air, where an unlit star at
        // full opacity is plenty. The ones lifting off the halo are seen against
        // the pale floor the ring is lying on — which is the case where unlit
        // loses, by the same arithmetic that made the ring itself read as a
        // stain until it started emitting. They belong to a light, so they emit
        // like one.
        let material: RealityKit.Material
        if glow > 0 {
            material = Palette.lightMaterial(colour, emission: colour,
                                             intensity: glow, opacity: 0.95)
        } else {
            var unlit = UnlitMaterial(color: colour)
            unlit.blending = .transparent(opacity: .init(floatLiteral: 0.95))
            material = unlit
        }

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

    /// Slower, bigger, hangs in the air. Flour off a sack, steam off a chimney.
    ///
    /// Cream rather than yellow, because this one is not a reward — it is the
    /// stuff itself, and flour is the colour of flour.
    static func puff(at position: SIMD3<Float>,
                     in parent: Entity,
                     ticker: Ticker,
                     colour: UIColorLike = Palette.creamLight,
                     count: Int = 9) {
        burst(at: position, in: parent, ticker: ticker, colour: colour,
              count: count, size: 0.005, speed: 0.045, gravity: 0.02, life: 1.5)
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
