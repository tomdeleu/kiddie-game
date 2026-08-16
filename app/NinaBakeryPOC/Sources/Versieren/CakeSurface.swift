import simd

/// **Where on the cake she is pointing.**
///
/// `GAMEPLAY.md` §6.4 calls this the first ray-versus-solid test in the game,
/// and asks for it analytically against the tier cylinders and the top discs
/// rather than with a `CollisionComponent`. The reasoning is `CameraRig`'s own,
/// written down there for the same decision about `targetedToAnyEntity()`:
/// **owning the ray keeps the generosity a number in one file rather than a
/// shape on every entity.** A cake with forty stickers on it would otherwise be
/// forty collision shapes, each hitting exactly its own mesh, in a game whose
/// whole touch model is "near enough counts".
///
/// It is a value type built fresh from the cake's state, so there is nothing to
/// keep in sync. Everything below happens in the **cake's own frame**: the ray
/// is moved into it once, which is what makes the turntable free — a spin
/// changes `turn` and no anchor moves.
struct CakeSurface {

    /// Where the cake's origin — the bottom of tier 0, on the axis — sits in the
    /// world.
    var origin: SIMD3<Float>
    /// How much bigger the cake is here than the `CakeGeometry` numbers.
    /// The decorating room presents it far larger than the kitchen does.
    var scale: Float
    /// The turntable's angle, radians about +Y.
    var turn: Float
    /// `CakeSpec.isTall` — a 1.5× stretch on the heights only.
    var tall: Bool

    // MARK: - The tiers, in cake-local units

    private func radius(_ tier: Int) -> Float { CakeGeometry.radius(of: tier) }
    private func base(_ tier: Int) -> Float { CakeGeometry.base(of: tier, tall: tall) }
    private func top(_ tier: Int) -> Float { CakeGeometry.top(of: tier, tall: tall) }

    private var tiers: Range<Int> { 0..<CakeGeometry.tierCount }

    // MARK: - World ↔ cake

    /// The ray, moved into the cake's frame: translated by the origin, spun back
    /// by the turntable's angle, and divided by the scale. Direction is not
    /// normalised again afterwards — a uniform scale leaves `t` meaningful and
    /// every test below only compares `t` values with each other.
    private func localRay(from eye: SIMD3<Float>,
                          through world: SIMD3<Float>) -> (o: SIMD3<Float>, d: SIMD3<Float>) {
        (o: toLocal(eye), d: toLocal(world) - toLocal(eye))
    }

    private func toLocal(_ p: SIMD3<Float>) -> SIMD3<Float> {
        let t = (p - origin) / scale
        let c = cos(-turn), s = sin(-turn)
        return SIMD3<Float>(c * t.x - s * t.z, t.y, s * t.x + c * t.z)
    }

    private func toWorld(_ p: SIMD3<Float>) -> SIMD3<Float> {
        let c = cos(turn), s = sin(turn)
        return origin + SIMD3<Float>(c * p.x - s * p.z, p.y, s * p.x + c * p.z) * scale
    }

    // MARK: - The test

    /// **The nearest point on the cake along the ray through `world`.**
    ///
    /// `world` is any point on the ray — `TouchRouter` hands a room a point on a
    /// fixed horizontal plane, and since the camera never moves that is a
    /// complete description of the ray through her fingertip (`RoomBox.pointOnRay`
    /// exploits the same fact).
    ///
    /// Returns `nil` only when the ray misses the cake entirely *and* misses it
    /// by more than `slop`. See `nearestSurface` for what happens then.
    @MainActor
    func anchor(pointingAt world: SIMD3<Float>, slop: Float = 0) -> StickerAnchor? {
        let ray = localRay(from: CameraRig.eye, through: world)
        if let hit = firstHit(ray) { return hit }
        guard slop > 0 else { return nil }
        return nearestSurface(ray, within: slop / scale)
    }

    /// Every candidate, nearest `t` wins. Six tests for a three-tier cake.
    private func firstHit(_ ray: (o: SIMD3<Float>, d: SIMD3<Float>)) -> StickerAnchor? {
        var best: (t: Float, anchor: StickerAnchor)?

        for tier in tiers {
            if let hit = sideHit(ray, tier: tier), best == nil || hit.t < best!.t {
                best = hit
            }
            if let hit = topHit(ray, tier: tier), best == nil || hit.t < best!.t {
                best = hit
            }
        }
        return best?.anchor
    }

    /// **Ray versus the wall of one tier** — an infinite-cylinder solve clipped
    /// to the tier's band.
    ///
    /// Only the near root is accepted. The far one is the inside of the cake,
    /// and a sticker on the inside of a cake is a sticker that vanished.
    private func sideHit(_ ray: (o: SIMD3<Float>, d: SIMD3<Float>),
                         tier: Int) -> (t: Float, anchor: StickerAnchor)? {
        let r = radius(tier)
        let a = ray.d.x * ray.d.x + ray.d.z * ray.d.z
        // A ray straight down the axis. Cannot happen at the committed camera —
        // `a` is about 0.72 there — but the guard costs a line and the eye is
        // the one number `ROOMS.md` §0 says a later room may move.
        guard a > 1e-9 else { return nil }

        let b = 2 * (ray.o.x * ray.d.x + ray.o.z * ray.d.z)
        let c = ray.o.x * ray.o.x + ray.o.z * ray.o.z - r * r
        let disc = b * b - 4 * a * c
        guard disc >= 0 else { return nil }

        let t = (-b - disc.squareRoot()) / (2 * a)
        guard t > 0 else { return nil }

        let y = ray.o.y + t * ray.d.y
        let lo = base(tier), hi = top(tier)
        guard y >= lo, y <= hi else { return nil }

        let p = ray.o + ray.d * t
        return (t, StickerAnchor(tier: tier, face: .zijkant,
                                 theta: atan2(p.z, p.x),
                                 u: (y - lo) / max(hi - lo, 1e-6)))
    }

    /// **Ray versus the top disc of one tier.**
    ///
    /// The full disc is tested, not the visible annulus. Any ray landing inside
    /// the next tier's footprint was already stopped by that tier's own side or
    /// top, which is nearer along the ray — so **nearest-hit-wins does the
    /// annulus for free**, and an explicit inner bound would be a special case
    /// that only ever agreed with the general one.
    private func topHit(_ ray: (o: SIMD3<Float>, d: SIMD3<Float>),
                        tier: Int) -> (t: Float, anchor: StickerAnchor)? {
        guard abs(ray.d.y) > 1e-6 else { return nil }
        let y = top(tier)
        let t = (y - ray.o.y) / ray.d.y
        guard t > 0 else { return nil }

        let p = ray.o + ray.d * t
        let r = radius(tier)
        let rho = (p.x * p.x + p.z * p.z).squareRoot()
        guard rho <= r else { return nil }

        return (t, StickerAnchor(tier: tier, face: .boven,
                                 theta: atan2(p.z, p.x),
                                 u: min(rho / r, 1)))
    }

    // Undersides are not tested. The radii strictly decrease upward, so no tier
    // overhangs the one below it and no bottom face is ever visible from a
    // camera above. If a cake ever inverts, the case to add is a bottom annulus
    // at `base(tier)` — and the right behaviour is to **reject** it and fall
    // through to the nearest side, because a sticker glued under an overhang is
    // one she cannot see and will read as having vanished.

    // MARK: - Generosity

    /// **She missed, but not by much.**
    ///
    /// `CONCEPT.md` §5 asks for drops that count when they land *near*, and this
    /// is the room she will spend the most time in. For each tier, take where
    /// the ray crosses that tier's mid-height, measure how far outside the wall
    /// that is, and snap to the closest one that is within `slop`.
    ///
    /// `u` is clamped well inside the tier rather than to `0…1`, so a generous
    /// catch never puts a heart half over the edge — it lands on the tier
    /// properly, which is what she was aiming at.
    private func nearestSurface(_ ray: (o: SIMD3<Float>, d: SIMD3<Float>),
                                within slop: Float) -> StickerAnchor? {
        guard abs(ray.d.y) > 1e-6 else { return nil }
        var best: (miss: Float, anchor: StickerAnchor)?

        for tier in tiers {
            let lo = base(tier), hi = top(tier)
            let mid = (lo + hi) / 2
            let t = (mid - ray.o.y) / ray.d.y
            guard t > 0 else { continue }

            let p = ray.o + ray.d * t
            let rho = (p.x * p.x + p.z * p.z).squareRoot()
            let miss = rho - radius(tier)
            guard miss > 0, miss <= slop else { continue }
            if best == nil || miss < best!.miss {
                best = (miss, StickerAnchor(tier: tier, face: .zijkant,
                                            theta: atan2(p.z, p.x), u: 0.5))
            }
        }
        return best?.anchor
    }

    // MARK: - Back out again

    /// Where an anchor is, in the world, right now.
    func position(of anchor: StickerAnchor) -> SIMD3<Float> {
        toWorld(localPosition(of: anchor))
    }

    /// The outward normal at an anchor, in the world.
    func normal(of anchor: StickerAnchor) -> SIMD3<Float> {
        switch anchor.face {
        case .boven:
            return [0, 1, 0]
        case .zijkant:
            let a = anchor.theta + turn
            return [cos(a), 0, sin(a)]
        }
    }

    /// In the cake's own frame — what a sticker parented to the turntable wants,
    /// since the graph applies `turn` for it.
    func localPosition(of anchor: StickerAnchor) -> SIMD3<Float> {
        let tier = min(max(anchor.tier, 0), CakeGeometry.tierCount - 1)
        let r = radius(tier)
        switch anchor.face {
        case .zijkant:
            let lo = base(tier), hi = top(tier)
            return SIMD3<Float>(r * cos(anchor.theta),
                                lo + anchor.u * (hi - lo),
                                r * sin(anchor.theta)) * scale
        case .boven:
            let out = anchor.u * r
            return SIMD3<Float>(out * cos(anchor.theta),
                                top(tier),
                                out * sin(anchor.theta)) * scale
        }
    }

    /// The outward normal in the cake's own frame.
    func localNormal(of anchor: StickerAnchor) -> SIMD3<Float> {
        switch anchor.face {
        case .boven: return [0, 1, 0]
        case .zijkant: return [cos(anchor.theta), 0, sin(anchor.theta)]
        }
    }

    /// **Arc length between two anchors, measured across the cake's surface.**
    ///
    /// The piping bag resamples by this rather than by world distance, so a
    /// sweep across the wide bottom tier and one across the narrow top tier lay
    /// down cream at the same visual density.
    func arc(from a: StickerAnchor, to b: StickerAnchor) -> Float {
        guard a.tier == b.tier, a.face == b.face else { return .greatestFiniteMagnitude }
        let tier = min(max(a.tier, 0), CakeGeometry.tierCount - 1)
        let r = radius(tier)
        var dTheta = b.theta - a.theta
        while dTheta > .pi { dTheta -= 2 * .pi }
        while dTheta < -.pi { dTheta += 2 * .pi }
        switch a.face {
        case .zijkant:
            let h = (top(tier) - base(tier)) * (b.u - a.u)
            return (SIMD2<Float>(r * dTheta, h) * scale).length
        case .boven:
            let mid = (a.u + b.u) / 2 * r
            return (SIMD2<Float>(mid * dTheta, (b.u - a.u) * r) * scale).length
        }
    }

    /// Whether a world point is off the cake by more than `margin` — the test
    /// for *drag a sticker off the edge and it is removed*.
    ///
    /// Deliberately generous: the same gesture nudges a sticker two millimetres,
    /// so anything short of a decisive drag away snaps back. The game taking
    /// something away from her is the one outcome the design forbids outright.
    @MainActor
    func isClearlyOff(_ world: SIMD3<Float>, margin: Float) -> Bool {
        anchor(pointingAt: world, slop: margin) == nil
    }
}

private extension SIMD2 where Scalar == Float {
    var length: Float { (x * x + y * y).squareRoot() }
}
