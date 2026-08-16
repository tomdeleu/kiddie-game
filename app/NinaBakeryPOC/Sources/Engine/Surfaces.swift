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
/// kitchen's are in `KitchenLayout.surfaces`; the garden's are in
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
        /// `KitchenLayout.nearPlank` documents, where two spellings of `.y` in one
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

    /// **A solid box the fixed camera cannot see through.**
    ///
    /// This is the general form of `hider`, and it exists because `hider` was
    /// too small a model of the problem in two separate ways. It was **one**
    /// piece of furniture, where a room has several; and it was a **thin plate**
    /// tested only against floor-height drops, where what actually hides things
    /// is a box with a height, and what gets hidden sits at whatever height it
    /// settled at.
    ///
    /// The kitchen paid for both (owner, 2026-08-16: things dropped below the
    /// table, behind the oven and below the back counter cannot be picked up
    /// again). Its table was the `hider`, so the floor behind Otto — who is
    /// 124 mm of mint dome standing on the ground — was never tested at all.
    ///
    /// A box rather than the real silhouette on purpose. Otto is a dome, so the
    /// box around him claims about 18 mm of floor at each front corner that is
    /// technically visible. That is the right way to be wrong: the cost of
    /// over-claiming is a prop floating home from a place she could just about
    /// have seen it, and the cost of under-claiming is a prop she has lost for
    /// the rest of the round.
    struct Occluder {
        /// (x, z), like `Rect.centre`.
        let centre: SIMD2<Float>
        let size: SIMD2<Float>
        /// The box's floor and ceiling. Most stand on the ground, so `bottom` is
        /// usually the room's `floorY` — a table with visible legs still counts
        /// as solid all the way down, because at this camera the floor under a
        /// table is never somewhere a prop can rest anyway: the surface lookup
        /// puts it on the table top instead.
        let bottom: Float
        let top: Float

        /// **Does the sightline from the eye to `point` pass through this box?**
        ///
        /// The slab method, run on the *segment* from the eye to the point
        /// rather than on an infinite ray — a box behind the prop does not hide
        /// it. `clearance` shortens the far end so a prop standing **on** an
        /// occluder is not hidden by the thing it is standing on: a rolling pin
        /// on the table top ends its segment exactly on the table box's ceiling
        /// face, which without this reads as a hit.
        @MainActor
        func hides(_ point: SIMD3<Float>, clearance: Float) -> Bool {
            let eye = CameraRig.eye
            let low = SIMD3<Float>(centre.x - size.x / 2, bottom, centre.y - size.y / 2)
            let high = SIMD3<Float>(centre.x + size.x / 2, top, centre.y + size.y / 2)
            let along = point - eye
            let span = simd_length(along)
            guard span > 1e-5 else { return false }

            // Named rather than spelled `exit`, which is a function in the
            // standard library and would be shadowed here.
            var enter: Float = 0
            var leave = 1 - clearance / span
            guard leave > enter else { return false }

            for axis in 0..<3 {
                let origin = eye[axis], direction = along[axis]
                // Parallel to this pair of faces: either the whole segment is
                // between them or it can never be inside the box at all.
                guard abs(direction) > 1e-6 else {
                    if origin < low[axis] || origin > high[axis] { return false }
                    continue
                }
                let a = (low[axis] - origin) / direction
                let b = (high[axis] - origin) / direction
                enter = max(enter, min(a, b))
                leave = min(leave, max(a, b))
                if enter > leave { return false }
            }
            return true
        }
    }

    /// Boxes that are solid rather than standable — a drop inside one is worse
    /// than a drop behind one.
    let solids: [Rect]

    /// **Everything in this room the fixed camera cannot see past.** Empty by
    /// default, so a room that has not been given one behaves exactly as it did
    /// before this existed. See `Occluder`.
    var occluders: [Occluder] = []

    /// The piece of furniture the fixed camera cannot see past. Floor behind it
    /// is floor she could put something into and never get back.
    ///
    /// **Superseded by `occluders`**, which is the same idea with a height and a
    /// plural. Kept because De Tuin still uses it and changing a room nobody
    /// asked about is how a fix to one room becomes a bug in another
    /// (`CLAUDE.md`, "always ask which room"). A room declares one or the other.
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
            let over = RoomBox.pointOnRay(through: anchor, atHeight: rect.y)
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
    //
    // **`RoomBox` owns the generic half of this**, and did before this type
    // existed: `pointOnRay`, `distanceXZ`, `within`, `carryLift` and the box's
    // own constants are all there, and `Layout` was already delegating to them.
    // This type had grown its own copies while the two were being built in
    // parallel, and one geometry vocabulary is worth more than two correct ones.
    //
    // What is left here is the part that is genuinely per-room: which
    // rectangles a room has, and which questions they answer.

    // MARK: - Bounds

    /// A prop released anywhere in here simply stays where it was put, so being
    /// generous costs nothing.
    func clamp(_ p: SIMD3<Float>) -> SIMD3<Float> {
        SIMD3<Float>(min(max(p.x, minX), maxX), p.y, min(max(p.z, minZ), maxZ))
    }

    /// **How much of the far end of a sightline does not count.**
    ///
    /// A prop resting on a surface touches the box that surface belongs to, and
    /// a prop being let go of keeps a small constant offset from the ray her
    /// finger is on (`CarryController.pickUp` explains where that comes from).
    /// Both would read as "hidden by the thing it is sitting on" without a
    /// little slack at the point end. 12 mm is the same order as that offset,
    /// and small against the shadows this is actually looking for: the ones it
    /// found in the kitchen run from a few centimetres deep behind the table to
    /// most of a quadrant behind Otto.
    static let sightClearance: Float = 0.012

    /// **Somewhere she could put a thing and then not get it back.**
    ///
    /// "It stays where you put it" is right up until she puts it where the
    /// furniture is in the way. The camera never moves, so behind every solid
    /// thing in the room there is a fixed patch that is simply not on screen — a
    /// rolling pin left there is gone, and a 4-year-old has no camera control to
    /// go and find it. Those drops float home instead.
    ///
    /// **Ask this about where the prop will come to rest, not about where her
    /// finger let go of it.** They are different heights — a drop is released at
    /// carry height, a hand's breadth above the surface it lands on — and only
    /// one of them is the position she will later be looking for.
    ///
    /// Three ways to lose something, in the order they are worth testing:
    ///
    /// - **Inside a solid.** Worse than hidden, and tested against the prop's
    ///   own height rather than its footprint alone: the top of a solid is
    ///   usually a perfectly good place to put something down, and the kitchen's
    ///   counter is both at once.
    /// - **Behind an occluder.** The general case — see `Occluder`.
    /// - **Behind the `hider`**, the older single-plate form of the same
    ///   question, for rooms that still declare one.
    ///
    /// **Derived rather than typed in**, all three of them, so they stay true if
    /// the furniture or the camera ever move. When the kitchen's table grew, its
    /// hidden patch grew with it — which is the derivation doing its job rather
    /// than a regression, because a bigger table hides more floor behind it.
    @MainActor
    func isOutOfSight(_ point: SIMD3<Float>) -> Bool {
        // Inside a solid box. The height test is what keeps this from claiming
        // the box's own lid: standing *on* the counter is not being *in* it.
        for solid in solids
        where point.y < solid.y - 0.002 && Self.within(point, solid, margin: 0.004) {
            return true
        }

        for occluder in occluders
        where occluder.hides(point, clearance: Self.sightClearance) {
            return true
        }

        // The single-plate hider. Floor-only, because a plate has no height to
        // hide anything standing above it — which is exactly the limitation
        // `occluders` exists to lift.
        guard let hider, y(at: point) <= floorY + 0.001 else { return false }
        let eye = CameraRig.eye
        let t = (hider.y - eye.y) / (floorY - eye.y)
        let crossing = SIMD3<Float>(eye.x + (point.x - eye.x) * t, hider.y,
                                    eye.z + (point.z - eye.z) * t)
        return Self.within(crossing, hider, margin: 0.004)
    }

    /// True where `point` is over one of this room's rectangles, grown by
    /// `margin` so a prop set down right on an edge lands on the surface rather
    /// than beside it. Straight through to `RoomBox.within`, which takes the
    /// centre and size loose; this is the `Rect` overload of it.
    static func within(_ point: SIMD3<Float>, _ rect: Rect, margin: Float) -> Bool {
        RoomBox.within(point, centre: rect.centre, size: rect.size, margin: margin)
    }
}
