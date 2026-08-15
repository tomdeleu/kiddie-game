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

    /// Light up a prop, and keep it lit until `remove`.
    ///
    /// `size` is roughly the prop's radius — it only sets how wide the sparkles
    /// scatter, since nothing is drawn at that distance any more.
    @discardableResult
    static func attach(to entity: Entity, radius size: Float, ticker: Ticker,
                       colour: UIColorLike = Palette.butterYellow) -> Int {

        // Every surface of the prop, up to a handful. A compound prop like the
        // tin or the rolling pin has to glow as one thing, but Otto has ten
        // parts and lighting all of them is waste nobody can see.
        let models = surfaces(of: entity, limit: 4)
        let originals = models.map { $0.model?.materials ?? [] }

        var clock: Float = 0
        var lastStep: Int = -1
        var nextSparkle: Float = 0.4

        return ticker.add { [weak entity] dt in
            guard let entity, entity.parent != nil else {
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
                let intensity = 0.25 + 0.85 * (Float(step) / 12)
                for (index, model) in models.enumerated() {
                    guard let tint = tint(of: originals[index]) else { continue }
                    model.model?.materials = [Palette.glowMaterial(tint, intensity: intensity)]
                }
            }

            nextSparkle -= dt
            if nextSparkle <= 0 {
                nextSparkle = Float.random(in: 0.75...1.35)
                if let parent = entity.parent {
                    Sparkles.burst(at: entity.position + [0, size * 0.9, 0],
                                   in: parent, ticker: ticker, colour: colour,
                                   count: 3, size: 0.0022, speed: 0.045,
                                   gravity: 0.05, life: 0.9)
                }
            }
            return true
        }
    }

    /// Put the prop's own materials back. Safe to call on a prop that was never
    /// lit, and on one whose glow job has already ended by itself.
    static func remove(from entity: Entity, restoring saved: [[RealityKit.Material]]? = nil) {
        let models = surfaces(of: entity, limit: 4)
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
    static func materials(of entity: Entity) -> [[RealityKit.Material]] {
        surfaces(of: entity, limit: 4).map { $0.model?.materials ?? [] }
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
