import RealityKit
import simd

/// The glow on the thing she needs next.
///
/// This is the game's only instruction. There is no text in it and never will
/// be, so this cue carries the whole thing: one object is lit and everything
/// else is not, and a 4-year-old reads that instantly. `GAMEPLAY.md` §7 says
/// hints shimmer and never block — the glow disables nothing, and every other
/// prop still answers a tap while it is on.
///
/// It differs from `Ticker.shimmer` in when it appears. The shimmer is the idle
/// nudge, 25 seconds after she has stopped doing anything. This is on from the
/// moment a step begins, because "which one do I pick up" is a question she
/// should never have to be idle long enough to ask.
///
/// ## Why the object glows rather than standing in a ring
///
/// The first version drew a glowing ring on the surface around the prop.
/// Rendered as a preview (`references/cues/`) it read as a screen-space UI
/// element dropped into the room — a neon hoop lying on a wooden table — and
/// it cut across the base of the thing it was pointing at. It was replaced by
/// what the owner picked from those previews: **the object itself lit from
/// within, plus a few sparkles lifting off it.**
///
/// Two properties make that the cheap answer as well as the pretty one:
///
/// - **The hue never changes.** Only `emissiveIntensity` moves, so the prop
///   stays its own colour. A cue that recoloured things would teach that colour
///   means something, and in this game colour means what the cake will be.
/// - **No new geometry.** An outline needs an inverted hull and back-face
///   culling; this needs a material swap and the sparkles that already exist.
@MainActor
enum Halo {

    /// How many of a prop's surfaces get lit.
    ///
    /// Eight rather than four, because the ingredients stopped being single
    /// blobs: a strawberry is a body and six leaves, a honey pot is five
    /// pieces, and lighting only the first four of them lit *part* of the
    /// thing she was being pointed at, which is worse than lighting none of it.
    /// Otto has more parts than this and is deliberately not fully lit — at his
    /// size the dome and the arch carry it.
    private static let surfaceLimit = 8

    /// Light up a prop, and keep it lit until `remove`.
    ///
    /// `size` is roughly the prop's radius — it only sets how wide the sparkles
    /// scatter, since nothing is drawn at that distance any more.
    ///
    /// ## Why it was invisible, and what changed
    ///
    /// The first version moved `emissiveIntensity` between 0.25 and 1.1 and
    /// left the base colour alone. On paper that is a glow; on the iPad it was
    /// nothing at all, and for a reason worth writing down rather than
    /// re-discovering. Every surface in this game is a **pale pastel** lit by a
    /// **2200 lx key** (`LightingSettings`), so it is already returning most of
    /// the light it can. Adding an emissive term below 1 to a surface that is
    /// three-quarters of the way to white moves it a few percent — and it moves
    /// it *towards white*, in a room where everything else is also nearly
    /// white. The cue was there in the buffer and not on the screen.
    ///
    /// So it now does three things instead of one, and any one of them alone
    /// would be visible:
    ///
    /// - **Emissive runs 1.2 to 5.0**, well past the point where the surface
    ///   clearly outruns its neighbours rather than nudging them.
    /// - **The base colour brightens with it**, up to 40% of the way to white,
    ///   so the prop reads brighter even where emissive is being tone-mapped
    ///   away. The *hue* still never moves — colour means what the cake will
    ///   be, and a cue that recoloured things would teach otherwise.
    /// - **It breathes down to almost nothing.** The bottom of the pulse is
    ///   near the prop's own colour, so the eye catches the *change*. A steady
    ///   bright object in a bright room is camouflage; a pulsing one is not.
    @discardableResult
    static func attach(to entity: Entity, radius size: Float, ticker: Ticker,
                       colour: UIColorLike = Palette.butterYellow) -> Int {

        let models = surfaces(of: entity, limit: surfaceLimit)
        let originals = models.map { $0.model?.materials ?? [] }
        let tints = originals.map { tint(of: $0) }

        var clock: Float = 0
        var lastStep: Int = -1
        var nextSparkle: Float = 0.25

        return ticker.add { [weak entity] dt in
            // `isEnabled` as well as `parent`, and it is not belt-and-braces: an
            // ingredient that goes into the bowl is hidden rather than removed,
            // so it keeps its parent forever. Without this the glow would go on
            // pulsing on a prop nobody can see, throwing sparkles into the bowl
            // it landed in.
            guard let entity, entity.parent != nil, entity.isEnabled else {
                // The prop went away mid-glow — a token dropped into the bowl,
                // a rebuild. Nothing to restore, and nothing to leak.
                return false
            }
            clock += dt

            // Slow breathing, never a flash. It has to be noticeable across a
            // room and calm enough to sit on a prop for a whole minute.
            let wave = 0.5 + 0.5 * sin(clock * 2.4)
            // Stepped, so a material is rebuilt a few times a second rather
            // than sixty. The eye cannot tell, and the allocator can.
            let step = Int(wave * 12)
            if step != lastStep {
                lastStep = step
                let t = Float(step) / 12
                let intensity = 1.2 + 3.8 * t
                for (index, model) in models.enumerated() {
                    guard let tint = tints[index] else { continue }
                    let lit = Palette.mix(tint, Palette.white, 0.40 * t)
                    model.model?.materials = [Palette.glowMaterial(lit, intensity: intensity)]
                }
            }

            nextSparkle -= dt
            if nextSparkle <= 0 {
                nextSparkle = Float.random(in: 0.45...0.85)
                if let parent = entity.parent {
                    Sparkles.burst(at: entity.position + [0, size * 0.9, 0],
                                   in: parent, ticker: ticker, colour: colour,
                                   count: 4, size: 0.0024, speed: 0.05,
                                   gravity: 0.05, life: 0.9)
                }
            }
            return true
        }
    }

    /// Put the prop's own materials back. Safe to call on a prop that was never
    /// lit, and on one whose glow job has already ended by itself.
    static func remove(from entity: Entity, restoring saved: [[RealityKit.Material]]? = nil) {
        let models = surfaces(of: entity, limit: surfaceLimit)
        for (index, model) in models.enumerated() {
            if let saved, index < saved.count {
                model.model?.materials = saved[index]
                continue
            }
            // No snapshot handed in: rebuild a plain material from the tint the
            // glowing one is carrying, which is the prop's own colour.
            guard let tint = tint(of: model.model?.materials ?? []) else { continue }
            model.model?.materials = [Palette.material(tint)]
        }
    }

    /// Snapshot a prop's materials before lighting it, so they can go back
    /// exactly as they were.
    ///
    /// **Always take one.** `remove`'s fallback rebuilds the material from the
    /// tint the *glowing* one is carrying, and that tint is now brightened
    /// towards white — so a prop restored without a snapshot comes back paler
    /// than it started. Every caller in the kitchen passes one.
    static func materials(of entity: Entity) -> [[RealityKit.Material]] {
        surfaces(of: entity, limit: surfaceLimit).map { $0.model?.materials ?? [] }
    }

    // MARK: - Internals

    /// Depth-first walk for the prop's own surfaces, skipping the bits that are
    /// not the prop: its contact shadow, and any sparkle passing through.
    private static func surfaces(of entity: Entity, limit: Int) -> [ModelEntity] {
        var found: [ModelEntity] = []
        func walk(_ node: Entity) {
            guard found.count < limit else { return }
            if let model = node as? ModelEntity,
               model.name != ContactShadows.markerName,
               model.name != "Sparkle",
               model.name != "SparkleRing" {
                found.append(model)
            }
            for child in node.children { walk(child) }
        }
        walk(entity)
        return found
    }

    private static func tint(of materials: [RealityKit.Material]) -> UIColorLike? {
        guard let pbr = materials.first as? PhysicallyBasedMaterial else { return nil }
        return pbr.baseColor.tint
    }
}
