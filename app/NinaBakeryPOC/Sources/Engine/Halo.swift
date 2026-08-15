import Foundation
import RealityKit
import simd

/// The glow on the thing she needs next.
///
/// This is the game's only instruction. There is no text in it and never will
/// be, so this cue carries the whole thing: one object is marked and everything
/// else is not, and a 4-year-old reads that instantly. `GAMEPLAY.md` §7 says
/// hints shimmer and never block — the halo disables nothing, and every other
/// prop still answers a tap while it is on.
///
/// It differs from `Ticker.shimmer` in when it appears. The shimmer is the idle
/// nudge, 25 seconds after she has stopped doing anything. This is on from the
/// moment a step begins, because "which one do I pick up" is a question she
/// should never have to be idle long enough to ask.
///
/// ## It is a ring on the floor, and it took three goes to get there
///
/// **First** it was a glowing ring drawn on the table around the prop, rejected
/// from a preview in `references/cues/` because as rendered it read as a
/// screen-space UI element dropped into the room — a neon hoop lying on wood.
///
/// **Second** it was the object itself lit from within. That is what the owner
/// picked from those previews, and on the iPad it did not work either: at
/// first it was invisible (pale pastels under a 2200 lx key are already
/// returning most of the light they can, so an emissive term below 1 moves them
/// a few percent, towards white, in a room where everything is nearly white),
/// and once it was strong enough to see it was recolouring the whole prop,
/// which is a lot of screen for one small instruction.
///
/// **Third, and current:** a soft ring of warm light on the surface *around*
/// the prop, chosen by the owner from `references/cues/floor/`. The object
/// keeps its own colour completely. The reason it survives where the first
/// attempt died is entirely softness — the rejected one was a hard-edged hoop,
/// and this is a band with about a third of its own radius of falloff on each
/// side, which reads as light on wood rather than as a decal.
///
/// ## How the softness is built
///
/// Eighteen concentric bands of geometry at graded opacities, not a texture.
///
/// A radial-gradient texture is the obvious way and it was not taken: it needs
/// `TextureResource.generate`, a `CGImage` built by hand, UV coordinates this
/// file's mesh builder does not produce, and an assumption about whether an
/// `UnlitMaterial` respects a base-colour texture's alpha channel. Every one of
/// those is a thing that can fail on a first build, and it would fail as a
/// bright yellow *square*. The bands need none of it.
///
/// Banding is not visible because the falloff is only ~20 screen points wide at
/// the size these props are drawn, so eighteen steps is about a point each.
/// The colour and profile are sampled from `references/cues/floor/A-ring.png`:
/// a `#F6D861` gold that washes out towards `#FFF6D8` at the core, on a
/// Gaussian centred on the ring radius.
@MainActor
enum Halo {

    /// What `attach` hands back. The ring is a sibling of the prop rather than
    /// a child, so removing it is not just cancelling the job.
    struct Handle {
        let job: Int
        let ring: Entity
    }

    /// The band colours, sampled off the reference plate.
    private static let gold = Palette.hex(0xF6D861)
    private static let core = Palette.hex(0xFFF6D8)

    private static let bandCount = 18
    /// How far the falloff reaches either side of the ring, as a fraction of
    /// the ring's radius. The reference's band is soft over about this much.
    private static let spread: Float = 0.34
    /// Gaussian width, again as a fraction of the radius.
    private static let sigma: Float = 0.155

    /// Light up the surface around a prop, and keep it lit until `remove`.
    ///
    /// `size` is roughly the prop's radius; the ring is drawn a little wider
    /// than that and the sparkles lift off from it. The upper clamp is set by
    /// Otto: his dome is 62 mm across and a ring any smaller than this would
    /// sit entirely underneath him.
    ///
    /// `surfaceY` answers "what is this prop standing on", so the ring stays on
    /// the table while the prop is lifted off it, and rises onto the plank with
    /// the cake at the end of the round. Without it the ring would be a child
    /// of the prop and float in mid-air the moment she picked anything up.
    static func attach(to entity: Entity, radius size: Float, ticker: Ticker,
                       colour: UIColorLike = Palette.butterYellow,
                       surfaceY: @escaping @MainActor (SIMD3<Float>) -> Float) -> Handle? {

        guard let parent = entity.parent else { return nil }

        let radius = min(0.080, max(0.020, size * 1.35))
        let ring = Entity()
        ring.name = ringName

        // Bands from the inside of the falloff to the outside. Each is opaque
        // in the middle of the profile and transparent at both ends, so the
        // stack as a whole is a soft band and no single one of them is a hoop.
        let inner = radius * (1 - spread)
        let step = (radius * 2 * spread) / Float(bandCount)
        for band in 0..<bandCount {
            let r0 = inner + step * Float(band)
            let r1 = r0 + step
            let mid = (r0 + r1) / 2
            let alpha = profile(at: mid, radius: radius)
            guard alpha > 0.01 else { continue }

            let geometry = FacetedMesh.annulus(innerRadius: r0, outerRadius: r1,
                                               segments: 24)
            let mesh = FacetedMesh.flatShaded(positions: geometry.positions,
                                              indices: geometry.indices)
            var material = UnlitMaterial(color: tint(alpha))
            material.blending = .transparent(opacity: .init(floatLiteral: alpha))
            let model = ModelEntity(mesh: mesh, materials: [material])
            model.name = ringName
            // A hair apart, so no two bands ever z-fight where they meet.
            model.position = [0, Float(band) * 0.00002, 0]
            ring.addChild(model)
        }
        parent.addChild(ring)

        var clock: Float = 0
        var nextSparkle: Float = 0.25

        let job = ticker.add { [weak entity, weak ring] dt in
            guard let entity, let ring, entity.parent != nil, entity.isEnabled else {
                // The prop went away mid-glow — an ingredient dropped into the
                // bowl, a rebuild. Take the ring with it.
                ring?.removeFromParent()
                return false
            }
            clock += dt

            // Follow the prop across the room, and stay on whatever it is over.
            // Not on the prop: it sits on the surface while she carries the prop
            // above it, which is most of what makes a lifted thing look lifted.
            let spot = entity.position
            ring.position = [spot.x, surfaceY(spot) + 0.0015, spot.z]

            // Breathing, as a slow swell rather than a brightness flicker. It is
            // one transform write per frame, where pulsing the opacity would be
            // twelve material rebuilds — and at this size a ring that grows
            // reads more clearly than one that brightens.
            let wave = 0.5 + 0.5 * sin(clock * 2.4)
            ring.scale = SIMD3<Float>(repeating: 0.94 + 0.10 * wave)

            nextSparkle -= dt
            if nextSparkle <= 0 {
                nextSparkle = Float.random(in: 0.45...0.85)
                // Off the ring itself, not the top of the prop: the cue is down
                // here now, and stars lifting out of the light is what ties the
                // two halves of it together.
                let a = Float.random(in: 0..<(2 * .pi))
                let r = radius * Float.random(in: 0.85...1.1)
                Sparkles.burst(at: ring.position + [cos(a) * r, 0.004, sin(a) * r],
                               in: parentOf(ring), ticker: ticker, colour: colour,
                               count: 2, size: 0.0026, speed: 0.035,
                               gravity: -0.02, life: 1.0)
            }
            return true
        }
        return Handle(job: job, ring: ring)
    }

    /// Put the surface back to plain. Safe to call twice.
    static func remove(_ handle: Handle?, ticker: Ticker) {
        guard let handle else { return }
        ticker.cancel(handle.job)
        handle.ring.removeFromParent()
    }

    // MARK: - Internals

    static let ringName = "HaloRing"

    private static func parentOf(_ ring: Entity) -> Entity { ring.parent ?? ring }

    /// Gaussian centred on the ring radius, pulled down so it reaches exactly
    /// zero at the edge of the falloff rather than stopping at a visible step.
    private static func profile(at r: Float, radius: Float) -> Float {
        let x = (r - radius) / (sigma * radius)
        let g = exp(-0.5 * x * x)
        let edge = exp(-0.5 * (spread / sigma) * (spread / sigma))
        return max(0, (g - edge) / (1 - edge)) * 0.92
    }

    /// Gold in the shoulders, washing out towards warm white at the core —
    /// which is what the reference plate does, and what stops the middle of the
    /// band reading as a flat sticker.
    private static func tint(_ alpha: Float) -> UIColorLike {
        Palette.mix(gold, core, min(1, alpha * 1.25))
    }
}
