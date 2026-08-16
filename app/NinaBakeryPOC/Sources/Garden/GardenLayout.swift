import RealityKit
import simd

/// Where everything in the garden is.
///
/// One table of numbers rather than magic constants spread across the room and
/// the game, because almost every bug in a room like this is two files
/// disagreeing about where the bed is. `Layout` is the kitchen's copy of this
/// and `ROOMS.md` §11.1 is the rule.
///
/// **Same box, same chair.** `roomSize`, `wallHeight`, `floorY` and
/// `CameraRig.eye` are the kitchen's, unchanged, because the whole game is one
/// continuous place and a room seen from a different chair is a different game
/// with the same palette (`ROOMS.md` §0). Nothing here needed more floor than
/// the kitchen has — the garden's problem is the opposite, one long bed and a
/// lot of open ground.
///
/// **So every touch radius is the kitchen's too**, including its 1.08 camera
/// scaling. They are world-space spheres satisfying a rule about the screen
/// (`CONCEPT.md` §5's ~120 pt targets), and the screen has not changed.
enum GardenLayout {

    static let roomSize: Float = Layout.roomSize
    static let half: Float = Layout.half
    static let wallHeight: Float = Layout.wallHeight
    static let wallThickness: Float = Layout.wallThickness
    static let slabThickness: Float = Layout.slabThickness
    static let floorY: Float = Layout.floorY

    /// The inner face of each wall — everything that hangs on one is measured
    /// off this rather than off `half`, so a change to the wall's thickness
    /// cannot leave a shelf floating.
    static var wallFaceX: Float { -half + wallThickness }
    static var wallFaceZ: Float { -half + wallThickness }

    // MARK: - The bed

    /// **The raised planter, and the room's required action.**
    ///
    /// Built from `references/garden/garden-bed.png`: four corner posts, two
    /// board bands between them, a soil slab inset, and **five holes in a
    /// straight row** sunk into the soil as little rings.
    ///
    /// **It is out in the floor, not against the back wall**, which is the one
    /// placement decision here worth arguing. Everything the round is about
    /// happens on this bed — five drags to plant, three sweeps to water, five
    /// taps to pick — and the kitchen's own note on the cake plank says what
    /// happens when the thing she has to reach for lives against the plaster:
    /// it becomes "the hardest one, performed at arm's length". So the bed sits
    /// with 100 mm of clear ground behind it and 150 mm in front, which also
    /// gives the tree and the bushes a back wall to stand against and leaves the
    /// whole near half of the floor for the toys.
    ///
    /// **A row along X, not a block**, because the watering can waters what it
    /// passes over: a row is one left-to-right sweep, which is the most legible
    /// gesture a 4-year-old can make, and a block would need her to trace a
    /// shape.
    static let bedCentre = SIMD2<Float>(0.030, -0.075)
    static let bedSize = SIMD2<Float>(0.250, 0.080)
    /// The top of the rim, which is what a carried seed rides over.
    static let bedRimY: Float = 0.050
    /// The soil, a step below the rim so the bed reads as having an inside.
    static let bedSoilY: Float = 0.040
    static let bedRimWidth: Float = 0.012
    static let bedPostSize: Float = 0.016

    /// **Five holes, and five is `GAMEPLAY.md` §5's basket.**
    ///
    /// The garden grows what the kitchen fetches, so this is
    /// `Layout.ingredientsPerRound` rather than a number of its own — if the
    /// basket ever goes back to three (`GAMEPLAY.md` §10 leaves it open), the
    /// bed follows it and nothing else has to be touched.
    static var plotCount: Int { Layout.ingredientsPerRound }

    /// How many watering passes ripen a plant. Three, as `GAMEPLAY.md` §6.2 has
    /// it — and because the bed is a row, three sweeps ripen all five.
    static let ripeStage = 3

    /// Where hole *i* is, in world space, spread evenly along the bed's length.
    ///
    /// Derived from the bed rather than typed out, so lengthening the bed or
    /// changing the count cannot leave a hole hanging off the end.
    static func plotSpot(_ index: Int) -> SIMD3<Float> {
        let usable = bedSize.x - 2 * bedRimWidth - bedPostSize
        let spacing = usable / Float(plotCount)
        let first = bedCentre.x - usable / 2 + spacing / 2
        return SIMD3<Float>(first + spacing * Float(index), bedSoilY, bedCentre.y)
    }

    /// The visible ring sunk into the soil. Sized so five of them sit along the
    /// bed with a clear gap: at 0.250 of bed the spacing is 42 mm, so a 15 mm
    /// radius leaves 12 mm of soil between neighbours.
    static let plotRadius: Float = 0.015

    /// How near a seed has to land to count as going in a hole.
    ///
    /// **The same 0.067 the kitchen snaps at**, and deliberately not a number of
    /// its own: it is a tolerance she aims by eye, so what matters is how big it
    /// is on screen, and the screen has not changed. It is larger than the 42 mm
    /// spacing between holes, which is fine and is the point — the *nearest*
    /// hole wins, so an imprecise drop always lands somewhere rather than
    /// nowhere. `CONCEPT.md` §5: drop it *near* and it counts.
    static let plotSnapRadius: Float = 0.067

    /// How near the can's rose has to pass over a hole to water it.
    ///
    /// Tighter than the snap radius on purpose: this one is not a drop she aims,
    /// it is a path she sweeps, and a radius wider than the hole spacing would
    /// water the whole bed from one place without moving. 30 mm reaches from a
    /// hole to just past its neighbour's rim, so a sweep has to actually travel.
    static let waterRadius: Float = 0.030
    /// And the distance it has to leave by before that hole can be watered
    /// again. Hysteresis, so a hand that jitters over one plant does not pump it
    /// to ripe — the rolling pin's rule (`KitchenRoom.roll`) with two thresholds
    /// instead of a travel count.
    static let waterReleaseRadius: Float = 0.046

    // MARK: - The seed shelves

    /// **Two shelves of four jars, on the left wall.**
    ///
    /// Eight, one per `Ingredient` — `GAMEPLAY.md` §5 says six, and the kitchen
    /// shipped eight. Growing six of the eight the kitchen deals would leave a
    /// hole in the round the moment the garden fills the basket, so the shelf is
    /// the enum. See `app/README.md` for the deviation.
    ///
    /// Mirrored from the kitchen's shelves in construction but not in contents:
    /// there is no ingredient standing at one end here, because every jar *is*
    /// an ingredient.
    static let shelfDepth: Float = 0.032
    static var shelfX: Float { wallFaceX + shelfDepth / 2 }
    static let shelfLength: Float = 0.224
    static let shelfCentreZ: Float = -0.030
    static let shelfHeights: [Float] = [0.150, 0.105]
    /// The top face of a plank, which is what a jar stands on. **Derived, never
    /// typed** — the kitchen's ingredients hovered 10 mm above their plank for
    /// weeks because two places wrote the number down and disagreed.
    static func shelfTopY(_ height: Float) -> Float { height + 0.004 }

    /// Where jar *i* stands. Four to a plank at 52 mm centres, which keeps their
    /// 24 mm touch spheres from meeting — the kitchen's counter toys are the
    /// cautionary tale, where 50 mm centres and 32 mm spheres made every tap a
    /// tie-break rather than a choice.
    static let jarSpacing: Float = 0.052
    static func jarSpot(_ index: Int) -> SIMD3<Float> {
        let perShelf = 4
        let shelf = min(index / perShelf, shelfHeights.count - 1)
        let along = index % perShelf
        let first = shelfCentreZ - jarSpacing * Float(perShelf - 1) / 2
        return SIMD3<Float>(shelfX,
                            shelfTopY(shelfHeights[shelf]),
                            first + jarSpacing * Float(along))
    }

    // MARK: - Home positions

    /// **The watering can, on the near-left floor** — the flour sack's job in
    /// the kitchen: the one prop in front of everything, which is what gives the
    /// shot a foreground.
    ///
    /// x = −0.090 rather than further left because the door's leaf sweeps
    /// x ∈ [−0.216, −0.142] as it opens; this clears that by 52 mm.
    static let canHome = SIMD3<Float>(-0.090, floorY, 0.150)

    /// **The basket, on the near-right floor**, bracketing the open foreground
    /// against the can. Where the crate stands in the kitchen, and for the same
    /// reason: floor to the left of tall furniture is hidden by it and floor to
    /// the right is not.
    static let basketHome = SIMD3<Float>(0.150, floorY, 0.120)
    /// Where a picked ingredient lands inside it, and how far apart they stack.
    static let basketRimY: Float = 0.026

    // MARK: - Toys

    /// Five flowers in a strip of soil, running along Z down the left-hand
    /// floor. **Low to high, left to right**, because they chime in a scale and
    /// a scale that runs the wrong way is a scale nobody hears as one.
    ///
    /// Placed at x = −0.150: 36 mm clear of the shelves' front face so they are
    /// not read against the jars, and their far end stops at z = 0.098, which is
    /// 49 mm short of the nearest the door's leaf ever reaches.
    static let flowerX: Float = -0.150
    static let flowerFirstZ: Float = -0.030
    static let flowerSpacing: Float = 0.032
    static let flowerCount = 5
    static func flowerSpot(_ index: Int) -> SIMD3<Float> {
        SIMD3<Float>(flowerX, floorY, flowerFirstZ + flowerSpacing * Float(index))
    }

    static let molehillSpot = SIMD3<Float>(0.040, floorY, 0.155)
    static let puddleSpots = [SIMD3<Float>(-0.020, floorY, 0.060),
                              SIMD3<Float>(0.115, floorY, 0.035)]
    /// Both fliers hover; y is their resting height above the ground.
    static let butterflyHome = SIMD3<Float>(0.090, floorY + 0.085, 0.055)
    static let beeHome = SIMD3<Float>(flowerX, floorY + 0.052, 0.034)

    /// The back-left corner, which is the one part of the floor nothing else
    /// wants: too far to reach comfortably and behind the bed from the camera.
    static let treeSpot = SIMD3<Float>(-0.160, floorY, -0.168)
    static let bushSpots = [SIMD3<Float>(-0.088, floorY, -0.186),
                            SIMD3<Float>(-0.186, floorY, -0.108)]

    /// A short run of picket fence along the **far-right open edge**, which is
    /// the one edge it can stand on without crossing a sightline.
    ///
    /// `references/REFERENCES.md` §1 puts the room box's two open sides where
    /// her hands come in, and `plates/05-garden-roombox.png` draws a fence
    /// across the near one — which would put a row of pickets between the camera
    /// and the bed. The far-right edge gives the room the same boundary, seen
    /// nearly end-on, with nothing behind it to hide.
    static let fenceX: Float = 0.205
    static let fenceZ = SIMD2<Float>(-0.190, -0.020)
    static let fenceHeight: Float = 0.034

    // MARK: - The way out

    /// **The same door, in the same place as the kitchen's.**
    ///
    /// Not laziness: the way out being where it was last time is worth more to a
    /// 4-year-old than a gate would be, and `ROOMS.md` §9's three cues — the
    /// leaf off the latch, the light behind it, the ring at the threshold — are
    /// already correct and already argued. `Props.doorway` is the shared build.
    static let doorwayCentre = SIMD3<Float>(-0.216, floorY, 0.172)

    // MARK: - Surfaces

    /// **What the garden is made of, for `CarryController`.**
    ///
    /// Two entries and no more: the ground, and the bed. A seed carried over the
    /// bed rides at the **rim**, not at the soil — the rim is what it would
    /// otherwise clip, and every snap test in the room is XZ-only so riding
    /// higher cannot make a drop harder to land (`CarryController.containerRim`
    /// has the argument in full).
    ///
    /// The bed is also the `hider`: it is the only thing in the room tall enough
    /// to put floor out of sight of a camera that never moves, so the strip
    /// behind it is the one place a drop floats home from.
    static let surfaces = Surfaces(
        floorY: floorY,
        rects: [
            Surfaces.Rect(centre: bedCentre, size: bedSize, y: bedRimY)
        ],
        shelves: [
            Surfaces.Shelf(x: shelfX, depth: shelfDepth, centreZ: shelfCentreZ,
                           halfSpan: shelfLength / 2,
                           tops: shelfHeights.map(shelfTopY))
        ],
        solids: [],
        hider: Surfaces.Rect(centre: bedCentre, size: bedSize, y: bedRimY),
        // The room's own furniture: `minX` reaches the shelves, `maxX` the
        // fence, `minZ` the bushes against the back wall, `maxZ` the open floor
        // where the can and the basket stand.
        minX: -0.205, maxX: 0.200, minZ: -0.200, maxZ: 0.200,
        lift: Layout.carryLift
    )

    /// Horizontal distance, the only kind that matters for a drop.
    static func distanceXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        Surfaces.distanceXZ(a, b)
    }
}
