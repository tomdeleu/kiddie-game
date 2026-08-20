import Foundation
import RealityKit

/// Measured saturation lift for Het Feest against `references/feest/roombox.png`.
///
/// The shared 1200 lx dome and emissive tiles wash pastels on device. Lower
/// ambient lives in `FeestRoom.lighting(from:)`; this raises chroma on the
/// matte props the plate expects to read punchy. Emissive surfaces are untouched
/// because they use `Palette.glowMaterial` / `lightMaterial`, not this path.
enum FeestAO {

    /// First factor that moves simulator sat toward the plate band while keeping
    /// cream plaster and wood trim pale. Tune against `app/ao-study-feest/`.
    static let punchAmount: CGFloat = 1.6

    private static let palePrefixes = [
        "Slab", "Floor", "Wall", "Tegel", "Lichtbalk", "LampHuis",
        "BoothLijst", "BoothKanaal", "Plaat", "Booth",
        "Cream", "Dark", "Gold", "DJCream", "GastBuik", "GastSnuit", "MolSnuit",
    ]

    static func paint(_ colour: UIColorLike, name: String = "") -> UIColorLike {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-no-feest-ao") {
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
}
