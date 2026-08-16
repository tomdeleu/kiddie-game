import RealityKit
import simd

/// **What is underneath a point, and what her finger is pointing at.**
///
/// This was `Layout`'s height section, and it lived there because there was one
/// room. There are two now, and every word of it is about the *camera* rather
/// than about the kitchen: the eye never moves (`CONCEPT.md` §9.4), so any world
/// point plus the eye is a complete description of the ray through it, and a
/// touch reported on one horizontal plane can be re-read on any other with no
/// extra plumbing from the gesture. That is true of every room this game will
/// ever have.
///
/// A room declares its own rectangles and hands them to `CarryController`. The
/// kitchen's are in `Layout.surfaces`; the garden's are in
/// `GardenLayout.surfaces`. `ROOMS.md` §6 is the prose version of this file.
///
/// **The two questions it answers are not the same question**, and confusing
/// them cost two failed attempts at the kitchen's drag:
///
/// - `y(at:)` — *what is underneath this world point.* Right for settling a
///   prop that has already been put down, and for the halo, both of which start
///   from a position rather than from a finger.
/// - `pointedAt(from:)` — *which surface does the line from her eye through her
///   fingertip land on first.* Right for a drag, and **a pure function of the
///   touch**: it never looks at the prop.
struct Surfaces {

    /// A horizontal rectangle a prop can stand on.
    struct Rect {
        /// (x, z). Named `centre` rather than a `SIMD3` because a rectangle
        /// lying flat has no height of its own to argue about — see the bug
        /// `Layout.nearPlank` documents, where two spellings of `.y` in one
        /// expression put a snap zone 30 cm out.
        let centre: SIMD2<Float>
        let size: SIMD2<Float>
        let y: Float
    }

    /// A run of wall shelving.
    ///
    /// **Deliberately not one of `rects`**, and the distinction is load-bearing:
    /// these are wall furniture hanging over open floor, so a surface lookup
    /// that returned them would fling anything dragged near that wall up to
    /// shelf height. What needs them is the halo, which asks what a prop is
    /// *standing on* in order to lay its ring there.
    struct Shelf {
        /// The plank run's centre, along the wall it hangs on.
        let x: Float
        let depth: Float
        let centreZ: Float
        /// Half the plank's length.
        let halfSpan: Float
        /// The **top face** of each plank in the run, which is what things
        /// stand on. Derived by the room, never hand-typed — the kitchen's
        /// ingredients hovered 10 mm above their plank for weeks because the
        /// jars took the plank's top and the ingredients took a number
        /// somebody wrote down.
        let tops: [Float]
    }

    /// Where the ground is.
    let floorY: Float

    /// Every surface a prop can be set down on, **nearest-camera first**, so
    /// the table wins over the counter where their footprints meet.
    let rects: [Rect]

    /// Wall shelving, for the halo only. See `Shelf`.
    let shelves: [Shelf]

    /// Boxes that are solid rather than standable — a drop inside one is worse
    /// than a drop behind one.
    let solids: [Rect]

    /// The piece of furniture the fixed camera cannot see past. Floor behind it
    /// is floor she could put something into and never get back.
    let hider: Rect?

    /// How far a carried prop travels. The room's own furniture, not round
    /// numbers, so it moves when the room does.
    let minX: Float, maxX: Float, minZ: Float, maxZ: Float

    /// How far above whatever it is standing on a carried prop floats. Small,
    /// but not nothing: it is what says *held* rather than *shoved*.
    let lift: Float

    // MARK: - What is under a point

    /// **What a prop standing here is standing on.**
    ///
    /// Position-based, where `pointedAt` is ray-based. Tested in declaration
    /// order, which for horizontal planes whose footprints do not nest is
    /// nearest-camera first.
    func y(at point: SIMD3<Float>) -> Float {
        for rect in rects where Self.within(point, rect, margin: 0.006) {
            return rect.y
        }
        return floorY
    }

    /// **What her finger is pointing at**, which is not the same question and is
    /// the one a drag has to ask.
    ///
    /// **The independence from the prop is the entire point, and it is what
    /// fixes the drag.** Carrying used to take the XZ from a plane frozen at
    /// pick-up height while the prop's own height eased between surfaces, so the
    /// prop slid up or down the screen away from her fingertip — 68 mm of world
    /// height between the kitchen's table and its floor, which at this camera
    /// throws the prop most of a thumb's width off her finger and reads as the
    /// thing she is holding jumping somewhere else.
    ///
    /// The obvious repair — re-project onto a plane at the prop's *current*
    /// height each frame — is a feedback loop, and it is worth knowing why the
    /// loop is real: at this eye, moving the plane by Δ slides the intersection
    /// about 1.63Δ along the view direction, so a prop stepping off the table
    /// drops 68 mm, which drags the mapped point ~78 mm back *onto* the table,
    /// which lifts it again. It oscillates, and that is exactly the judder the
    /// kitchen's cake used to have at the plank.
    ///
    /// Deciding the surface from the ray alone breaks the loop, because the
    /// height can no longer feed back into the choice: the surface depends on
    /// her finger, the prop's height chases the surface, and the prop's XZ is
    /// read off the same ray at whatever height it has reached. **Nothing in
    /// that chain points backwards.**
    ///
    /// It reads better as a rule, too. Pointing at the table means the table;
    /// pointing at the floor in front of it means the floor.
    ///
    /// **And it makes losing a prop behind the furniture impossible**, which
    /// falls straight out of the construction: a floor point is hidden exactly
    /// when the sightline to it crosses a table top inside that table's
    /// footprint — and that sightline *is* this ray, so the crossing is the very
    /// point tested on the first line. Any route to the hidden strip is a ray
    /// that hit the table first, and got the table.
    @MainActor
    func pointedAt(from anchor: SIMD3<Float>) -> Float {
        for rect in rects {
            let over = Self.pointOnRay(through: anchor, atHeight: rect.y)
            if Self.within(over, rect, margin: 0.006) { return rect.y }
        }
        return floorY
    }

    /// **The shelf a prop is standing on, if it is standing on one.**
    ///
    /// Height is what makes it safe to ask: a prop only matches while it is
    /// actually up at shelf level, so the moment she lifts one off, the ring
    /// stops following the shelf and goes back to answering for the room.
    ///
    /// The kitchen paid for this being missing. For two of its five fetching
    /// steps the game's only instruction — the halo — was landing **on the floor
    /// 150 mm below the berry it was pointing at**, because the surface lookup
    /// only knew about the table, the counter and the floor. **Add a room's
    /// shelves the moment you add the shelf, not the moment something falls
    /// through it.**
    func shelfY(at point: SIMD3<Float>) -> Float? {
        for shelf in shelves {
            guard abs(point.x - shelf.x) <= shelf.depth / 2 + 0.008,
                  abs(point.z - shelf.centreZ) <= shelf.halfSpan + 0.008 else { continue }
            for top in shelf.tops where point.y > top - 0.005 && point.y < top + 0.032 {
                return top
            }
        }
        return nil
    }

    // MARK: - The ray

    /// **The same ray she is pointing along, read at a different height.**
    ///
    /// The camera never moves, so any world point plus the eye is a complete
    /// description of the ray through it. `TouchRouter` hands the room a point
    /// on a fixed plane; this is what turns it back into "where she is
    /// pointing", and it is the whole basis of `CarryController`.
    @MainActor
    static func pointOnRay(through anchor: SIMD3<Float>, atHeight y: Float) -> SIMD3<Float> {
        let eye = CameraRig.eye
        let along = anchor - eye
        guard abs(along.y) > 1e-6 else { return anchor }
        return eye + along * ((y - eye.y) / along.y)
    }

    /// Horizontal distance. Snapping ignores height on purpose: she aims at
    /// where a thing *is on the table*, not at its centre of mass.
    static func distanceXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        simd_length(SIMD2<Float>(a.x - b.x, a.z - b.z))
    }

    // MARK: - Bounds

    /// A prop released anywhere in here simply stays where it was put, so being
    /// generous costs nothing.
    func clamp(_ p: SIMD3<Float>) -> SIMD3<Float> {
        SIMD3<Float>(min(max(p.x, minX), maxX), p.y, min(max(p.z, minZ), maxZ))
    }

    /// **Somewhere she could put a thing and then not get it back.**
    ///
    /// "It stays where you put it" is right up until she puts it where the
    /// furniture is in the way. The camera never moves, so there is a fixed
    /// patch of floor behind the `hider` that is simply not on screen — a
    /// rolling pin left there is gone, and a 4-year-old has no camera control to
    /// go and find it. Those drops float home instead.
    ///
    /// Only floor-level drops can be lost. Anything on a work surface is above
    /// the things that would hide it.
    ///
    /// **Derived rather than typed in**, so it stays true if the furniture or
    /// the camera ever move: follow the sightline from the eye to the point, see
    /// where it crosses the height of the hider's top, and ask whether that is
    /// over the hider. When the kitchen's table grew, this patch grew with it —
    /// which is the derivation doing its job rather than a regression, because a
    /// bigger table hides more floor behind it.
    @MainActor
    func isOutOfSight(_ point: SIMD3<Float>) -> Bool {
        guard y(at: point) <= floorY + 0.001 else { return false }
        // Inside a solid box is worse than hidden.
        for solid in solids where Self.within(point, solid, margin: 0.004) { return true }
        guard let hider else { return false }
        let eye = CameraRig.eye
        let t = (hider.y - eye.y) / (floorY - eye.y)
        let crossing = SIMD3<Float>(eye.x + (point.x - eye.x) * t, hider.y,
                                    eye.z + (point.z - eye.z) * t)
        return Self.within(crossing, hider, margin: 0.004)
    }

    /// True where `point` is over a rectangle, grown by `margin` so a prop set
    /// down right on an edge lands on the surface rather than beside it.
    static func within(_ point: SIMD3<Float>, _ rect: Rect, margin: Float) -> Bool {
        abs(point.x - rect.centre.x) <= rect.size.x / 2 + margin
            && abs(point.z - rect.centre.y) <= rect.size.y / 2 + margin
    }
}
