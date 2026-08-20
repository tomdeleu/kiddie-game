import Foundation
import RealityKit
import simd

/// De Tuin's measured lawn ambient occlusion.
///
/// The mint ground is one quad. A facet cannot hold contact under the bed,
/// bench, fence posts and tree, so the measured route is one planar AO map
/// on a garden-only UV plane. The ordinary lawn stays underneath as the
/// complete fallback if the texture is missing.
///
/// The map multiplies into base colour because `LightingRig` clears the
/// material AO slot whenever the global lightmap debug switch is off.
enum GardenAO {

    /// Measured against `references/garden/roombox.png`. The locked thirteen
    /// sit at chroma ~0.10; the plate's pastels sit near 0.20. 1.8× on the
    /// props, lawn and foliage left pale, is the first factor that passes
    /// every frozen band (`app/ao-study-tuin/05-punch-1.8.png`).
    static let punchAmount: CGFloat = 1.8

    private static let palePrefixes = [
        "Ground", "Slab", "TuinLawn", "GardenAO", "Tree", "Bush", "Fence",
        "BedSoil", "BedHole", "Mole", "Soil", "HillEarth", "PlantMound",
        "PlantLeaf", "PlantStem", "PlantStalk",
    ]

    static func paint(_ colour: UIColorLike, name: String = "") -> UIColorLike {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-no-garden-ao") {
            return colour
        }
        #endif
        if palePrefixes.contains(where: { name.hasPrefix($0) }) {
            return colour
        }
        return punch(colour, by: punchAmount)
    }

    static func paintTints(_ tints: [String: UIColorLike]) -> [String: UIColorLike] {
        Dictionary(uniqueKeysWithValues: tints.map { key, value in
            (key, paint(value, name: key))
        })
    }

    static func punch(_ colour: UIColorLike, by amount: CGFloat) -> UIColorLike {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        guard colour.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return colour
        }
        let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
        func clamp(_ value: CGFloat) -> Double {
            Double(max(0, min(1, value)))
        }
        return UIColorLike(red: clamp(luma + amount * (r - luma)),
                           green: clamp(luma + amount * (g - luma)),
                           blue: clamp(luma + amount * (b - luma)),
                           opacity: Double(a))
    }

    static func lawnOverlay() -> Entity? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-no-garden-ao") {
            return nil
        }
        #endif
        guard let texture = load("TuinLawnAO") else { return nil }

        let root = Entity()
        root.name = "GardenAO"

        let lawn = ModelEntity(
            mesh: .generatePlane(width: GardenLayout.roomSize,
                                 depth: GardenLayout.roomSize),
            materials: [material(Palette.mintLight, texture: texture)])
        lawn.name = "GardenAOLawn"
        lawn.position = [0, GardenLayout.floorY + 0.0002, 0]
        root.addChild(lawn)

        root.excludeFromShadowCasting()
        return root
    }

    private static func load(_ name: String) -> TextureResource? {
        try? TextureResource.load(named: name)
    }

    private static func material(_ colour: UIColorLike,
                                 texture: TextureResource) -> RealityKit.Material {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: colour, texture: .init(texture))
        material.roughness = .init(floatLiteral: 0.9)
        material.metallic = .init(floatLiteral: 0)
        material.specular = .init(floatLiteral: 0.1)
        return material
    }
}
