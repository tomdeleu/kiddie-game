import RealityKit
import simd

/// The glow around the thing she needs next.
///
/// This is the game's only instruction. There is no text, no arrow, no tutorial
/// — one object is lit and everything else is not, and a 4-year-old reads that
/// instantly. `GAMEPLAY.md` §7 says hints shimmer and never block: the halo
/// disables nothing, and every other prop still answers a tap while it is on.
///
/// It differs from `Ticker.shimmer` in when it appears. The shimmer is the idle
/// nudge, 25 seconds after she has stopped doing anything. The halo is on from
/// the moment a step begins, because "which one do I pick up" is a question she
/// should never have to be idle long enough to ask.
///
/// A ring on the surface rather than a glow on the object itself: tinting the
/// prop would fight the palette, and a prop that changes colour when it becomes
/// active teaches that colour means something, which it does not.
@MainActor
enum Halo {

    static let markerName = "Halo"

    /// Light up a prop. The ring is a child, so it follows the prop when she
    /// picks it up and travels with it to the bowl.
    /// `yOffset` is where the prop meets its surface, in the prop's own space.
    /// Most props here are built standing on their origin, so it is a hair
    /// above zero; the berries are icospheres centred on theirs, and a ring at
    /// zero would saw one in half.
    @discardableResult
    static func attach(to entity: Entity, radius: Float, ticker: Ticker,
                       yOffset: Float = 0.0008,
                       colour: UIColorLike = Palette.butterYellow) -> Int {
        remove(from: entity)

        let geometry = FacetedMesh.prism(radius: radius, height: 0.0008, sides: 14)
        let mesh = FacetedMesh.flatShaded(positions: geometry.positions,
                                          indices: geometry.indices)
        let ring = ModelEntity(mesh: mesh, materials: [Palette.glowMaterial(colour, intensity: 0.5)])
        ring.name = markerName
        ring.position = [0, yOffset, 0]
        entity.addChild(ring)

        var clock: Float = 0
        return ticker.add { [weak ring] dt in
            guard let ring else { return false }
            clock += dt
            // Slow breathing, never a flash. It has to be noticeable across a
            // room and calm enough to sit under a prop for a whole minute.
            let wave = 0.5 + 0.5 * sin(clock * 2.6)
            let scale = 0.88 + 0.22 * wave
            ring.scale = [scale, 1, scale]
            ring.model?.materials = [Palette.glowMaterial(colour, intensity: 0.30 + 0.55 * wave)]
            return true
        }
    }

    static func remove(from entity: Entity) {
        for child in entity.children where child.name == markerName {
            child.removeFromParent()
        }
    }
}
