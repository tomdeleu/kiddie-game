import RealityKit
import SwiftUI

/// The locked palette from `references/REFERENCES.md` §4.
///
/// These are **base material colours**. Under flat shading a lit facet comes
/// back brighter and a turned-away facet darker — that variation is the
/// renderer's job. Nothing here has shading baked in, so these values go
/// straight into the material.
enum Palette {
    static let blushPink     = hex(0xFBD0CA)
    static let blushPinkDeep = hex(0xE3B1AE)
    static let rose          = hex(0xEAB5AA)
    static let mintLight     = hex(0xD6F0DE)
    static let mint          = hex(0xC2DECF)
    static let sage          = hex(0xA7C0AC)
    static let sageDeep      = hex(0x7E9A88)
    static let creamLight    = hex(0xF2E6DC)
    static let cream         = hex(0xE4DACA)
    static let butterYellow  = hex(0xDCC994)
    static let sandyWood     = hex(0xC79C86)
    static let woodBrown     = hex(0x8A7A66)

    /// Reference-plate backdrop only. Never on an in-game surface.
    static let backdropGrey  = hex(0xCFCECF)

    static func hex(_ value: UInt32) -> UIColorLike {
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        // sRGB in, which is how the values were sampled.
        return UIColorLike(red: r, green: g, blue: b, opacity: 1.0)
    }
}

#if os(macOS)
typealias UIColorLike = NSColor
#else
typealias UIColorLike = UIColor
#endif

extension UIColorLike {
    convenience init(red: Double, green: Double, blue: Double, opacity: Double) {
        self.init(red: CGFloat(red), green: CGFloat(green),
                  blue: CGFloat(blue), alpha: CGFloat(opacity))
    }
}

extension Palette {
    /// A matte, non-metallic material. Roughness high, no textures anywhere.
    ///
    /// Deliberately **not** `UnlitMaterial`: a surface that ignores lighting
    /// loses its facet shading and collapses into a flat silhouette, which is
    /// the whole thing this POC is testing.
    static func material(_ colour: UIColorLike, roughness: Float = 0.9) -> RealityKit.Material {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: colour)
        m.roughness = .init(floatLiteral: roughness)
        m.metallic = .init(floatLiteral: 0.0)
        m.specular = .init(floatLiteral: 0.1)
        return m
    }
}
