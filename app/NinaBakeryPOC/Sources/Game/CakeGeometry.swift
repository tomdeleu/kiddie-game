import simd

/// **The cake's shape, in one place.**
///
/// The tier radii and heights existed twice before the decorating room — in
/// `KitchenProps.proceduralCake` and again in `models/cake.py` — and that was
/// survivable while the only thing reading them was the code that drew them.
/// It stops being survivable the moment **every sticker's position is derived
/// from them**: a third copy in `VersierLayout` is how stickers end up two
/// millimetres inside the icing, and it is the same class of bug as the shelf
/// ingredients that hovered 10 mm above their plank because the jars took the
/// plank's top and the ingredients took a number somebody wrote down.
///
/// So this is the source, `KitchenProps.proceduralCake` reads it, and
/// `models/cake.py` mirrors it with a note saying so.
enum CakeGeometry {

    /// Bottom tier first. Ten sides, as the plate and the model both have.
    static let radii: [Float] = [0.026, 0.021, 0.015]
    static let heights: [Float] = [0.013, 0.011, 0.009]
    static let sides = 10

    static var tierCount: Int { radii.count }

    /// **How far the icing stands proud of the tier's side**, from
    /// `models/cake.py`'s `DRIP_OUT`.
    ///
    /// It matters here and nowhere else: the silhouette she aims a sticker at is
    /// the *drip*, not the tier, so the hit test uses `radius(of:) + dripOut`.
    /// The procedural fallback cake has no drips, so on that one a sticker sits
    /// 1.2 mm proud — invisible at this camera, and the right way round. The
    /// other way, stickers would sink into the modelled cake's icing.
    static let dripOut: Float = 0.0012

    /// Total height of the stack, before `isTall`.
    static var height: Float { heights.reduce(0, +) }

    /// The base of tier *i*, measured from the cake's own origin, which is the
    /// bottom of tier 0.
    static func base(of tier: Int, tall: Bool = false) -> Float {
        let stretch: Float = tall ? 1.5 : 1
        return heights[0..<max(0, min(tier, heights.count))].reduce(0, +) * stretch
    }

    static func height(of tier: Int, tall: Bool = false) -> Float {
        heights[tier] * (tall ? 1.5 : 1)
    }

    static func top(of tier: Int, tall: Bool = false) -> Float {
        base(of: tier, tall: tall) + height(of: tier, tall: tall)
    }

    /// The radius a sticker lands on — the tier plus its icing.
    static func radius(of tier: Int) -> Float { radii[tier] + dripOut }
}
