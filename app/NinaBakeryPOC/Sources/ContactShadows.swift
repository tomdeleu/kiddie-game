import RealityKit
import simd

/// The fake dynamic AO from `CONCEPT.md` §9.5 — a soft dark disc under each
/// loose prop, scaled by how close it is to the surface below.
///
/// This is the part baked ambient occlusion could never do: it stays correct
/// while Nina drags something across the table. Cheap, crude, and convincing
/// at this scale.
@MainActor
enum ContactShadows {

    static let markerName = "ContactShadow"

    /// A thin disc. Deliberately flat-coloured rather than a radial gradient:
    /// a gradient needs a generated texture, which is one more thing to get
    /// wrong on first run. If the hard edge shows on device, swapping in a
    /// radial-gradient `TextureResource` here is the fix — the disc geometry
    /// and placement stay as they are.
    static func attach(to prop: Entity, radius: Float, settings: LightingSettings) {
        removeFrom(prop)
        guard settings.contactShadowsEnabled else { return }

        let geometry = FacetedMesh.prism(radius: radius, height: 0.0006, sides: 16)
        let mesh = FacetedMesh.flatShaded(positions: geometry.positions,
                                          indices: geometry.indices)

        var material = UnlitMaterial(color: shadowColour(settings.contactShadowOpacity))
        material.blending = .transparent(
            opacity: .init(floatLiteral: settings.contactShadowOpacity)
        )

        let disc = ModelEntity(mesh: mesh, materials: [material])
        disc.name = markerName
        disc.scale = .init(repeating: settings.contactShadowScale)
        // A shadow must not cast a shadow of itself.
        disc.excludeFromShadowCasting()
        prop.addChild(disc)
        // Positioning is `update`'s job — the surface below is not known here.
        // Callers follow every `attach` with an `update`.
    }

    static func removeFrom(_ prop: Entity) {
        for child in prop.children where child.name == markerName {
            child.removeFromParent()
        }
    }

    /// Drops the disc to the surface below the prop and fades it with distance.
    ///
    /// `surfaceY` is passed in rather than raycast: the POC has two known
    /// surfaces (table top and floor), and a raycast per frame per prop is
    /// more machinery than the question needs.
    static func update(for prop: Entity, surfaceY: Float, settings: LightingSettings) {
        guard let disc = prop.children.first(where: { $0.name == markerName })
                as? ModelEntity else { return }

        let worldProp = prop.position(relativeTo: nil)
        let gap = max(0, worldProp.y - surfaceY)

        // Land the disc just above the surface, directly below the prop.
        // Converted into the prop's space, since that is the disc's parent —
        // mixing disc-space and parent-space here is the easy mistake.
        let worldTarget = SIMD3<Float>(worldProp.x, surfaceY + 0.0008, worldProp.z)
        disc.position = prop.convert(position: worldTarget, from: nil)

        // Closer contact reads darker and tighter.
        let falloff = max(0, 1 - gap / 0.06)
        let opacity = settings.contactShadowOpacity * falloff
        var material = UnlitMaterial(color: shadowColour(opacity))
        material.blending = .transparent(opacity: .init(floatLiteral: opacity))
        disc.model?.materials = [material]
        disc.scale = .init(repeating: settings.contactShadowScale * (0.85 + 0.15 * falloff))
    }

    private static func shadowColour(_ opacity: Float) -> UIColorLike {
        // Warm-tinted rather than neutral black — a pure black blob reads as a
        // hole in a pastel scene.
        UIColorLike(red: 0.30, green: 0.24, blue: 0.22, opacity: Double(opacity))
    }
}
