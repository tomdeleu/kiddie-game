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

    // MARK: - Added for the kitchen

    /// **Two colours the locked thirteen do not contain.**
    ///
    /// `GAMEPLAY.md` §5 needs a blue: the toverbosbes gives one, and Bo de
    /// vogel's whole wish is a blue cake. The palette sampled from the plates
    /// has pink, mint, sage, cream, butter and wood, and no blue at all — the
    /// cottage and kitchen plates simply had none in frame.
    ///
    /// These are built to sit in the same register rather than sampled: the
    /// same desaturation and the same lightness as `mint` and `sage`, so a blue
    /// cake belongs beside a green one. Sample a real one if a plate with blue
    /// in it ever gets rendered — until then this is the derivation, and it is
    /// recorded here rather than inlined at the call site so it stays one edit.
    static let berryBlue     = hex(0xC2D2E8)
    static let berryBlueDeep = hex(0x9BB2D2)

    /// Blend two palette colours. Used for one thing: batter coming up to
    /// colour as she stirs. Reading components back out is platform-specific,
    /// which is why it lives here rather than at the call site.
    static func mix(_ a: UIColorLike, _ b: UIColorLike, _ t: Float) -> UIColorLike {
        let ca = components(a), cb = components(b)
        let k = Double(max(0, min(1, t)))
        return UIColorLike(red: ca.0 + (cb.0 - ca.0) * k,
                           green: ca.1 + (cb.1 - ca.1) * k,
                           blue: ca.2 + (cb.2 - ca.2) * k,
                           opacity: 1)
    }

    private static func components(_ colour: UIColorLike) -> (Double, Double, Double) {
        #if os(macOS)
        let srgb = colour.usingColorSpace(.sRGB) ?? colour
        return (Double(srgb.redComponent), Double(srgb.greenComponent),
                Double(srgb.blueComponent))
        #else
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        colour.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #endif
    }

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

    /// The same matte surface, lit from within.
    ///
    /// Used for exactly three things: a sun-honey cake's glow, Otto's mouth
    /// while he is baking, and the doorway when it is inviting her through. It
    /// is not a lighting change — the facets still do the shading — it just
    /// stops those three reading as painted-on.
    static func glowMaterial(_ colour: UIColorLike, intensity: Float = 1.0) -> RealityKit.Material {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: colour)
        m.roughness = .init(floatLiteral: 0.9)
        m.metallic = .init(floatLiteral: 0.0)
        m.specular = .init(floatLiteral: 0.1)
        m.emissiveColor = .init(color: colour)
        m.emissiveIntensity = intensity
        return m
    }
}
