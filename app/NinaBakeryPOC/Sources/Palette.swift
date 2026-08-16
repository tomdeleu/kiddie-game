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

    /// Not a palette colour — the end point `Halo` mixes a prop's own tint
    /// towards while it breathes. Nothing is ever painted this.
    static let white         = hex(0xFFFFFF)

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

    /// **A third derived colour**, for the same reason and by the same method.
    ///
    /// `references/ingredients/honing.png` puts a pool of honey inside a cream
    /// pot, and `butterYellow` beside `creamLight` is not enough separation to
    /// read as a liquid — the pot swallows it. This is `butterYellow` carried
    /// two steps towards `sandyWood`: the same hue family and the same
    /// desaturation as the locked thirteen, one value darker than any of them.
    /// It appears on exactly one surface in the game, the honey in the pot.
    static let honeyAmber    = hex(0xD2A868)

    /// **A fourth and fifth**, for the portrait on the back wall.
    ///
    /// The photograph the portrait is built from has the girl in a lilac t-shirt
    /// covered in deeper purple daisies, and purple is the second hue the locked
    /// thirteen do not contain — the plates had no more purple in frame than
    /// they had blue. Built the same way `berryBlue` was, and it is worth saying
    /// again because it is the rule rather than the exception: **not sampled off
    /// a screen, derived to the register.** Same desaturation and the same
    /// lightness as `mint` and `berryBlue`, so the shirt sits beside the mint
    /// jars rather than shouting over them, and `lilacDeep` is one step down for
    /// the flowers, matching how `berryBlueDeep` sits under `berryBlue`.
    ///
    /// Two surfaces in the game, both inside the picture frame.
    static let lilac         = hex(0xD3C6E4)
    static let lilacDeep     = hex(0xAE9CC9)

    /// **A sixth**, and the only dark one: the inside of Otto's mouth.
    ///
    /// The locked thirteen bottom out at `woodBrown`, which under the room's
    /// even lighting reads as a wooden surface, not a cavity — and with the
    /// oven door standing open all round, the mouth has to read as depth
    /// ("needs depth and thus more shadow", owner's note on the 2026-08-15
    /// build). The no-AO rule bans shadow pooled onto *surfaces*; a mouth
    /// interior is the one place where dark is the subject. Same hue as
    /// `woodBrown`, taken darker. One surface, the oven's mouth plug.
    static let ovenInside    = hex(0x554C3F)

    /// A palette colour one or more steps into shadow.
    ///
    /// **This is the game's only ambient occlusion**, and it exists against a
    /// standing rule — `references/REFERENCES.md` bans occlusion outright,
    /// because the facets are supposed to do the shading and corners are
    /// supposed to stay light. That rule holds everywhere a facet can answer
    /// the question. The props modelled in Blender are where it cannot: a crown
    /// standing off a globe, a collar fanning over a tie, a board butting into a
    /// corner post, four clover petals crowding one hub, icing hanging over a
    /// cake tier — in all of those joins the surfaces face the same way as
    /// everything around them, so they come back the same tone and nothing says
    /// the two shapes touch. Nothing `FacetedMesh` builds uses this, and neither
    /// do the cake's tiers, which are repainted every round.
    ///
    /// It is not a lightmap and it costs nothing at runtime. `bake_ao_facets`
    /// in `models/lowpoly.py` measures the occlusion at model time and splits
    /// the faces in the crevice into their own mesh named `…Shade1` / `…Shade2`;
    /// `ModelLibrary` sees the suffix and calls this. So the occlusion is still
    /// a flat tone on a facet, which is what the whole style is made of.
    ///
    /// **`occlusionStep` is kept in step with `OCCLUSION_STEP` in
    /// `models/lowpoly.py`**, which is only there so a prop looks the same in
    /// Blender as it does in the game. If one moves, move the other.
    static let occlusionStep = 0.88

    static func occluded(_ colour: UIColorLike, steps: Int) -> UIColorLike {
        guard steps > 0 else { return colour }
        let c = components(colour)
        let f = pow(occlusionStep, Double(steps))
        return UIColorLike(red: c.0 * f, green: c.1 * f, blue: c.2 * f, opacity: 1)
    }

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

    /// A palette colour taken lighter or darker. `1.0` is the base colour.
    ///
    /// **Only for the 2D UI.** In the room the renderer shades every facet from
    /// its own normal, which is the whole point of the style and the reason the
    /// palette has no `lit` or `shaded` entries. The overlay has no renderer,
    /// so `FacetButton` computes the same variation itself — from a light
    /// direction, not by eye — and this is what it multiplies with.
    static func shade(_ colour: UIColorLike, _ factor: Double) -> UIColorLike {
        let c = components(colour)
        return UIColorLike(red: min(1, c.0 * factor),
                           green: min(1, c.1 * factor),
                           blue: min(1, c.2 * factor),
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

    /// **A surface that is a light, rather than a surface that is lit.**
    ///
    /// The distinction is the whole of why the halo took four goes. An
    /// `UnlitMaterial` with transparent blending *replaces* what is under it in
    /// proportion to its alpha, so the brightest it can ever be is its own
    /// colour — and the kitchen's floor is `blushPink`, which is already at 84%
    /// luminance. Any saturated yellow is **darker than that**. Painting the ring
    /// a stronger yellow to make it more visible therefore made it dimmer, and
    /// what it read as was a stain (owner, 2026-08-16: "too dark of a yellow, it
    /// must look like it's giving off light").
    ///
    /// Emission is what fixes that, because `emissiveIntensity` above 1 puts the
    /// surface *above white* in the HDR buffer before tonemapping — a place a
    /// base colour cannot reach by definition. So the ring is now painted a hot
    /// pale yellow and emits on top of it, and the emission is scaled down
    /// across the falloff so the band's centre line glows and its edges fade
    /// into the floor rather than ending.
    ///
    /// Same construction as `glowMaterial`, plus the transparency the falloff
    /// needs; kept separate because that one is for a *prop* that glows a
    /// little, and this is for something that is not a prop at all.
    static func lightMaterial(_ colour: UIColorLike, emission: UIColorLike,
                              intensity: Float, opacity: Float) -> RealityKit.Material {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: colour)
        // Fully rough and non-specular: a pool of light has no highlight of its
        // own, and a glancing specular on a ring lying flat on the floor would
        // travel across it as a bright arc every time the ring breathes.
        m.roughness = .init(floatLiteral: 1.0)
        m.metallic = .init(floatLiteral: 0.0)
        m.specular = .init(floatLiteral: 0.0)
        m.emissiveColor = .init(color: emission)
        m.emissiveIntensity = intensity
        m.blending = .transparent(opacity: .init(floatLiteral: opacity))
        return m
    }

    /// Water, and only water.
    ///
    /// `references/REFERENCES.md` asks for no transparency anywhere, and this
    /// is the one surface that overrules it: an opaque pastel blue prism is
    /// what the tap used to be, and it read as a painted stick. Everything else
    /// about it stays on style — it is still lit, still faceted, still matte.
    static func waterMaterial(_ colour: UIColorLike,
                              opacity: Float = 0.82) -> RealityKit.Material {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: colour)
        m.roughness = .init(floatLiteral: 0.55)
        m.metallic = .init(floatLiteral: 0.0)
        m.specular = .init(floatLiteral: 0.25)
        m.blending = .transparent(opacity: .init(floatLiteral: opacity))
        return m
    }
}
