import Foundation
import RealityKit

/// Measured saturation lift for De Bakkerij, the same route De Tuin and Het
/// Feest took after the shared 1200 lx dome washed pastels on device.
///
/// The bakery is cream walls and a blush counter, like De Keuken, but this
/// session has no Blender scene to bake kitchen-style shell maps from. The
/// available lesson from the 2026-08-20 lighting work is therefore the one
/// that does not need a texture: lower the dome, punch chroma on the colourful
/// props, leave plaster and wood pale, and restore contact-shadow opacity
/// after `ContactShadows` writes it twice.
enum BakkerijAO {

    /// Same first factor Het Feest landed on. Cream plaster stays pale.
    static let punchAmount: CGFloat = 1.6

    private static let palePrefixes = [
        "Slab", "Floor", "Wall", "Toonbank", "Lijst", "Spook", "Rolluik",
        "Raam", "Haak", "Tekening", "Foto", "Cream", "Gold", "Paneel",
    ]

    static func paint(_ colour: UIColorLike, name: String = "") -> UIColorLike {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-no-bakkerij-ao") {
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
