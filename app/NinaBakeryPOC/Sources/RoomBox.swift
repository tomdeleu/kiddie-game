import RealityKit
import simd

/// **The box every room stands in, and the camera maths that goes with it.**
///
/// `ROOMS.md` §0 states this as a rule rather than a default: *"Build the next
/// room at the same box and the same eye… If a room genuinely needs more floor,
/// move the walls and pull the eye back with them, and then rescale every touch
/// radius by the same factor."* A rule about two rooms staying identical, kept
/// in two files, is exactly the thing `KitchenLayout`'s own opening warning is
/// about — two files disagreeing about where the table top is. So the box lives
/// here once, and a room's own `…Layout` owns only its furniture.
///
/// What belongs in here is anything that would be **the same number in every
/// room**. What does not: work surfaces, prop homes, snap radii, door positions,
/// and both surface lookups. `KitchenLayout.surfaceY` reads as though it were
/// general and is not — it is a fact about the kitchen's table and counter, and
/// the decorating room's is a fact about a turntable plate. The *shape* is the
/// pattern; the rectangles are the room's.
enum RoomBox {

    /// Room box, **0.46 m across**. `POC.md` asks for "around 0.4 m"; this is
    /// that number grown 15% because the 0.40 m kitchen had run out of floor,
    /// and **the camera moved with it** — `CameraRig.eye` is pulled back 8%.
    ///
    /// It is not sacred, but it is shared: the whole game is one continuous
    /// place, and a room that is a different size or seen from a different chair
    /// is a different game with the same palette.
    static let roomSize: Float = 0.46
    static let half: Float = roomSize / 2
    /// Up from 0.22 with the floor: the same walls on a wider floor read squat.
    static let wallHeight: Float = 0.235
    static let wallThickness: Float = 0.012
    static let slabThickness: Float = 0.014
    static let floorY: Float = 0.004

    /// How far above whatever it is standing on a carried prop floats. Small,
    /// but not nothing: it is what says *held* rather than *shoved*.
    static let carryLift: Float = 0.012

    // MARK: - The shell

    /// **Two walls, a floor and a slab.** Every room opens with this and then
    /// adds its own furniture.
    ///
    /// Lifted out of `RoomBuilder.build` when the decorating room arrived, so
    /// that "every room is an open corner room box" is a function both rooms
    /// call rather than a paragraph in a markdown file that the second room
    /// could quietly disagree with.
    ///
    /// There is no ceiling and no fourth wall. The open front edge is where her
    /// hands come in.
    ///
    /// **De Tuin does not call this, and that is deliberate rather than an
    /// oversight.** A garden with plaster walls read as a room with soil in it
    /// (owner, 2026-08-16), so it builds a picket fence and a gate on exactly
    /// the two lines the walls stood on — `GardenRoomBuilder.buildFence`, and
    /// `GardenLayout.fenceLineX`/`fenceLineZ` are `-half + wallThickness`. The
    /// box, the slab, the floor and the eye are untouched; only what stands on
    /// the two back edges differs. It is the one room allowed to, and any room
    /// that wants the same has to argue for it the same way — `CLAUDE.md`'s
    /// deviations list and `references/REFERENCES.md` §1 both record it.
    static func shell(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "RoomShell"

        // Base slab — the footing every room sits on, from the cottage plate.
        let slab = RoomBuilder.model(.box([roomSize + 0.03, slabThickness, roomSize + 0.03]),
                                     Palette.cream, flat: flat, name: "Slab")
        slab.position = [0, -slabThickness / 2, 0]
        root.addChild(slab)

        let floor = RoomBuilder.model(.box([roomSize, 0.004, roomSize]),
                                      Palette.blushPink, flat: flat, name: "Floor")
        floor.position = [0, 0.002, 0]
        root.addChild(floor)

        let backWall = RoomBuilder.model(.box([roomSize, wallHeight, wallThickness]),
                                         Palette.creamLight, flat: flat, name: "WallBack")
        backWall.position = [0, wallHeight / 2, -half + wallThickness / 2]
        root.addChild(backWall)

        let leftWall = RoomBuilder.model(.box([wallThickness, wallHeight, roomSize]),
                                         Palette.cream, flat: flat, name: "WallLeft")
        leftWall.position = [-half + wallThickness / 2, wallHeight / 2, 0]
        root.addChild(leftWall)

        // The shell never casts — the back wall's shadow raking across the left
        // wall was the hardest band in the room, and architecture shadowing
        // architecture buys no grounding. Receiving is untouched: the floor and
        // walls still catch the shadows of props and characters.
        for shellPiece in [slab, floor, backWall, leftWall] {
            shellPiece.excludeFromShadowCasting()
        }
        return root
    }

    // MARK: - Geometry the rooms share

    /// Horizontal distance. Snapping ignores height on purpose: she aims at
    /// where a thing *is on the surface*, not at its centre of mass.
    static func distanceXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        simd_length(SIMD2<Float>(a.x - b.x, a.z - b.z))
    }

    /// **The same ray she is pointing along, read at a different height.**
    ///
    /// The camera never moves, so any world point plus the eye is a complete
    /// description of the ray through it — which means a touch reported on one
    /// horizontal plane can be re-read on any other with no extra plumbing from
    /// the gesture. `TouchRouter` hands a room a point on a fixed plane; this is
    /// what turns it back into "where she is pointing".
    ///
    /// It is the basis of every carry in the game, and of the decorating room's
    /// ray-versus-cake test.
    @MainActor
    static func pointOnRay(through anchor: SIMD3<Float>, atHeight y: Float) -> SIMD3<Float> {
        let eye = CameraRig.eye
        let along = anchor - eye
        guard abs(along.y) > 1e-6 else { return anchor }
        return eye + along * ((y - eye.y) / along.y)
    }

    /// **How far apart two targets are as the camera sees them**, which is not
    /// how far apart they are on the floor.
    ///
    /// `TouchRouter` picks the target whose centre is nearest her touch *ray*,
    /// and `CameraRig.distance(fromWorld:toRayThrough:)` measures that
    /// perpendicular to the ray. So the separation that decides whether two
    /// targets can be told apart is the component of the gap between them
    /// perpendicular to the view direction — everything along the view direction
    /// is one behind the other and buys nothing.
    ///
    /// **This eye stands at 45° to both floor axes** (`CameraRig.eye` is
    /// (0.636, 0.611, 0.636)), so a row laid out along X or along Z keeps only
    /// about **0.75–0.80** of its spacing, while a row along the X−Z diagonal
    /// keeps essentially all of it. Every "these do not overlap" sum written
    /// before De Tuin was done in XZ and was therefore optimistic by a fifth —
    /// which is not a rounding error when the numbers are chosen to touch
    /// exactly.
    ///
    /// Use this, not `distanceXZ`, whenever the question is *can she tell these
    /// two things apart*. `distanceXZ` remains right for snapping, which is
    /// about where a prop lands rather than about what she is pointing at.
    @MainActor
    static func screenSeparation(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        let eye = CameraRig.eye
        let midpoint = (a + b) / 2
        let toMid = midpoint - eye
        guard length(toMid) > 1e-6 else { return length(b - a) }
        let view = normalize(toMid)
        let gap = b - a
        return length(gap - view * dot(gap, view))
    }

    /// True where `point` is over a rectangle, grown by `margin` so a prop set
    /// down right on an edge lands on the surface rather than beside it.
    ///
    /// Internal rather than private now: both rooms' surface lookups are built
    /// out of it, and each owns its own rectangles.
    static func within(_ point: SIMD3<Float>, centre: SIMD2<Float>,
                       size: SIMD2<Float>, margin: Float) -> Bool {
        abs(point.x - centre.x) <= size.x / 2 + margin
            && abs(point.z - centre.y) <= size.y / 2 + margin
    }
}
