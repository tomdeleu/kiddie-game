import RealityKit
import CoreGraphics
import simd

/// The fixed camera, and the screen ↔ world maths the whole room is driven by.
///
/// The camera never moves (`CONCEPT.md` §9.4), which is what makes this cheap:
/// the view matrix is a constant, so a touch can be turned into a point on the
/// table with a ray and a plane, and no per-frame bookkeeping.
///
/// **Why not `targetedToAnyEntity()`?** Entity-targeted gestures need a
/// `CollisionComponent` per prop and hit exactly the mesh. This game wants the
/// opposite: 120 pt targets and drops that count when they land *near* the bowl
/// (`CONCEPT.md` §5). Owning the ray means the generosity is a number here
/// rather than a shape on every entity.
@MainActor
final class CameraRig {

    /// Same framing the POC signed off on — a raised three-quarter doll's house.
    ///
    /// **Pulled back 8% when the room grew from 0.40 m to 0.46 m.** The old eye
    /// was `(0.589, 0.570, 0.589)`, and at that distance the 0.40 m box already
    /// filled the frame corner to corner: the slab's left and right tips sat at
    /// ±0.97 of half the screen width on a 4:3 iPad, so a wider room simply ran
    /// off the sides. Everything here is the old eye scaled 1.08 away from the
    /// same target, which puts the bigger slab's tips back where the smaller
    /// one's were.
    ///
    /// It is a deliberately *partial* pull-back. Matching the room's full 15%
    /// growth would have shrunk every prop by 15% on screen, and the props are
    /// what has to stay thumb-sized; 8% keeps them near their old size and lets
    /// the two wall-tops and the slab tips crop a few percent more than before
    /// on the one 4:3 iPad still in the line-up. **The touch radii in
    /// `KitchenRoom` were widened by the same 1.08** so nothing on screen got
    /// harder to hit — if this number moves again, they move with it.
    static let eye = SIMD3<Float>(0.636, 0.611, 0.636)
    static let target = SIMD3<Float>(0, 0.06, 0)
    static let fovDegrees: Float = 26

    /// Whether `fieldOfViewInDegrees` is measured vertically.
    ///
    /// `init` sets the orientation explicitly so this is not a guess. If
    /// `fieldOfViewOrientation` ever fails to resolve on a future SDK, delete
    /// that one line and set this to `false` — RealityKit's own default is
    /// horizontal, and everything else here keeps working.
    static let fovIsVertical = true

    let camera = PerspectiveCamera()

    /// Set from the SwiftUI `GeometryReader`. Points, not pixels — touches
    /// arrive in points too, so the two agree.
    private(set) var viewport = CGSize(width: 1024, height: 768)

    init() {
        camera.name = "Camera"
        camera.camera.fieldOfViewInDegrees = Self.fovDegrees
        camera.camera.fieldOfViewOrientation = .vertical
        camera.look(at: Self.target, from: Self.eye, relativeTo: nil)
    }

    func setViewport(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        viewport = size
    }

    // MARK: - Basis

    var forward: SIMD3<Float> { normalize(Self.target - Self.eye) }
    var right: SIMD3<Float> { normalize(cross(forward, SIMD3<Float>(0, 1, 0))) }
    var up: SIMD3<Float> { cross(right, forward) }

    // MARK: - Screen → world

    /// The ray under a touch, in world space.
    func ray(through point: CGPoint) -> (origin: SIMD3<Float>, direction: SIMD3<Float>) {
        let w = Float(viewport.width), h = Float(viewport.height)
        let ndcX = 2 * Float(point.x) / w - 1
        let ndcY = 1 - 2 * Float(point.y) / h

        let tanHalf = tan(Self.fovDegrees * .pi / 180 / 2)
        let aspect = w / h
        let tanX = Self.fovIsVertical ? tanHalf * aspect : tanHalf
        let tanY = Self.fovIsVertical ? tanHalf : tanHalf / aspect

        let direction = normalize(forward + right * (ndcX * tanX) + up * (ndcY * tanY))
        return (Self.eye, direction)
    }

    /// Where a touch lands on a horizontal plane — the table top, the floor,
    /// the counter. This is the drag primitive the whole room uses.
    func point(onPlaneY planeY: Float, through screenPoint: CGPoint) -> SIMD3<Float>? {
        let r = ray(through: screenPoint)
        guard abs(r.direction.y) > 1e-6 else { return nil }
        let t = (planeY - r.origin.y) / r.direction.y
        guard t > 0 else { return nil }
        return r.origin + r.direction * t
    }

    /// Perpendicular distance from a world point to the touch ray, in metres.
    ///
    /// This is the hit test. A prop is "under her finger" when this is smaller
    /// than its hit radius — which makes every target a sphere, deliberately
    /// much bigger than the prop it stands for.
    func distance(fromWorld world: SIMD3<Float>, toRayThrough screenPoint: CGPoint) -> Float {
        let r = ray(through: screenPoint)
        let v = world - r.origin
        let t = max(0, dot(v, r.direction))
        return length(v - r.direction * t)
    }

    /// Metres per point at the room's centre. Used to state hit radii in the
    /// units the age rules are written in ("minimum ~120 pt hit areas").
    var metresPerPoint: Float {
        let h = Float(viewport.height)
        let visibleHeight = 2 * length(Self.target - Self.eye)
            * tan(Self.fovDegrees * .pi / 180 / 2)
        let vertical = Self.fovIsVertical
            ? visibleHeight
            : visibleHeight * h / Float(viewport.width)
        return vertical / h
    }
}
