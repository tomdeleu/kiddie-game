import Foundation
import CoreGraphics
import RealityKit
import simd

/// Turns one finger into "she touched *that*".
///
/// Two verbs exist and there is never a third (`GAMEPLAY.md` §3): **tap** and
/// **drag-onto-something**. So this is one `DragGesture` with a zero minimum
/// distance, and a press that travels less than `tapSlop` is a tap.
///
/// Targets are spheres, not meshes. A prop registers a `radius` far bigger than
/// itself — the age rules ask for ~120 pt hit areas, and the small props here
/// are nothing like that on screen. When two targets overlap, the one whose
/// centre is nearest the finger wins, so a big generous target never swallows a
/// small one sitting on top of it.
@MainActor
final class TouchRouter {

    /// One touchable thing. Everything is optional: a prop that only wiggles
    /// needs `onTap`, the bowl during stirring needs only the drag callbacks.
    final class Target {
        let name: String
        weak var entity: Entity?
        /// Hit radius in metres. See `TouchRouter.radius(points:)`.
        var radius: Float
        /// Horizontal plane the drag is projected onto — the table top for
        /// props on the table, the counter for props on the counter.
        ///
        /// It is fixed for the length of a drag, deliberately: driving it with
        /// the prop's height mid-drag is a feedback loop, and the reason is
        /// written out in `KitchenRoom.pickUp`. What does move is where each
        /// drag *starts* — see `tracksEntity`.
        var planeY: Float
        /// Take `planeY` from the prop's own height when a drag begins, rather
        /// than from whatever it was left at. True for everything that can be
        /// put down somewhere other than where it started.
        var tracksEntity = false
        /// Added to the prop's height when `tracksEntity` recomputes the plane.
        /// The bowl is the reason it exists: stirring has to happen on the
        /// plane of its *rim*, two centimetres above where the bowl sits, or
        /// the circle her finger draws lands nowhere near the spoon.
        var planeOffset: Float = 0
        var enabled = true
        // Spelled `@MainActor` because that is what they are: closures formed
        // inside the room, touching entities and game state.
        var onTap: (@MainActor () -> Void)?
        var onDragBegan: (@MainActor (SIMD3<Float>) -> Void)?
        var onDragMoved: (@MainActor (SIMD3<Float>) -> Void)?
        var onDragEnded: (@MainActor (SIMD3<Float>) -> Void)?

        init(name: String, entity: Entity?, radius: Float, planeY: Float) {
            self.name = name
            self.entity = entity
            self.radius = radius
            self.planeY = planeY
        }
    }

    private let camera: CameraRig
    private var targets: [Target] = []

    /// A press that moves less than this is a tap. Generous: her taps drift.
    private let tapSlop: CGFloat = 24

    private var active: Target?
    private var startPoint: CGPoint = .zero
    private var travelled: CGFloat = 0

    /// Called for a press that hit nothing. Used to make empty space respond —
    /// a dead tap reads as a broken iPad (`CONCEPT.md` §5).
    var onEmptyTap: (@MainActor (SIMD3<Float>) -> Void)?
    /// Called on every press, before routing. The idle nudge listens here.
    var onAnyTouch: (@MainActor () -> Void)?

    init(camera: CameraRig) {
        self.camera = camera
    }

    // MARK: - Registration

    @discardableResult
    func register(_ target: Target) -> Target {
        targets.append(target)
        return target
    }

    @discardableResult
    func register(_ name: String, entity: Entity?, radius: Float, planeY: Float,
                  configure: @MainActor (Target) -> Void = { _ in }) -> Target {
        let target = Target(name: name, entity: entity, radius: radius, planeY: planeY)
        configure(target)
        return register(target)
    }

    func removeAll() {
        targets.removeAll()
        active = nil
    }

    /// **Drop a family of targets by name prefix.**
    ///
    /// `register` appends, so re-registering a name that is already there leaves
    /// *both* — which was survivable while every target in the game was
    /// registered once, in `build`, and stopped being survivable the moment a
    /// room could add one mid-round. The decorating room registers one target
    /// per placed sticker and re-registers the set every time she places or
    /// removes one; without this it would accumulate a dead target per grain of
    /// sprinkle, each still holding its entity and still winning hit tests near
    /// where a sticker used to be.
    func remove(prefixed prefix: String) {
        targets.removeAll { $0.name.hasPrefix(prefix) }
        if let active, active.name.hasPrefix(prefix) { self.active = nil }
    }

    func target(named name: String) -> Target? {
        targets.first { $0.name == name }
    }

    /// Hit radius from a screen size, so target sizes can be stated in the
    /// units the age rules use. `radius(points: 120)` is a 120 pt-wide target.
    func radius(points: CGFloat) -> Float {
        Float(points) * camera.metresPerPoint / 2
    }

    // MARK: - Gesture plumbing

    func began(at point: CGPoint) {
        onAnyTouch?()
        startPoint = point
        travelled = 0
        active = hitTest(point)
        guard let active else { return }
        if active.tracksEntity, let entity = active.entity {
            active.planeY = entity.position(relativeTo: nil).y + active.planeOffset
        }
        guard let world = world(for: active, at: point) else { return }
        active.onDragBegan?(world)
    }

    func moved(to point: CGPoint) {
        travelled = max(travelled, hypot(point.x - startPoint.x, point.y - startPoint.y))
        guard let active, let world = world(for: active, at: point) else { return }
        active.onDragMoved?(world)
    }

    func ended(at point: CGPoint) {
        defer { active = nil }
        let isTap = travelled <= tapSlop

        guard let active else {
            if isTap, let world = camera.point(onPlaneY: 0.004, through: point) {
                onEmptyTap?(world)
            }
            return
        }

        if isTap, active.onTap != nil {
            active.onTap?()
            // A tap on a draggable still needs its drag closing out, or the
            // prop is left held. Ending where it began is the no-op.
            if let world = world(for: active, at: point) { active.onDragEnded?(world) }
            return
        }
        if let world = world(for: active, at: point) {
            active.onDragEnded?(world)
        }
    }

    // MARK: - Internals

    private func world(for target: Target, at point: CGPoint) -> SIMD3<Float>? {
        camera.point(onPlaneY: target.planeY, through: point)
    }

    /// Nearest enabled target whose sphere the ray passes through.
    private func hitTest(_ point: CGPoint) -> Target? {
        var best: Target?
        var bestDistance = Float.greatestFiniteMagnitude
        for target in targets {
            // `isEnabled` matters as much as the target's own flag: a token
            // that has gone into the bowl, or the tin while it is inside Otto,
            // is hidden but still has a live entity to hit.
            guard target.enabled, let entity = target.entity, entity.isEnabled else { continue }
            let world = entity.position(relativeTo: nil)
            let d = camera.distance(fromWorld: world, toRayThrough: point)
            guard d <= target.radius, d < bestDistance else { continue }
            best = target
            bestDistance = d
        }
        return best
    }
}
