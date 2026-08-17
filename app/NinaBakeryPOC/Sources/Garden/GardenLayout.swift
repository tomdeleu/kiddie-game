import RealityKit
import simd

/// Where everything in the garden is.
///
/// One table of numbers rather than magic constants spread across the room and
/// the game, because almost every bug in a room like this is two files
/// disagreeing about where the bed is. `Layout` is the kitchen's copy of this
/// and `ROOMS.md` §11.1 is the rule.
///
/// **Same box, same chair** — `RoomBox`, which is where the box's own numbers
/// live for every room. The whole game is one continuous place, and a room seen
/// from a different chair is a different game with the same palette
/// (`ROOMS.md` §0). Nothing here needed more floor than the kitchen has; the
/// garden's problem is the opposite, one long bed and a lot of open ground.
///
/// **So every touch radius is the kitchen's too**, including its 1.08 camera
/// scaling. They are world-space spheres satisfying a rule about the screen
/// (`CONCEPT.md` §5's ~120 pt targets), and the screen has not changed.
///
/// **What this room does not take from `RoomBox` is `shell()`** — that builds
/// the two walls every other room opens with, and this one has a fence. See
/// `GardenRoomBuilder`.
enum GardenLayout {

    static let roomSize: Float = RoomBox.roomSize
    static let half: Float = RoomBox.half
    static let slabThickness: Float = RoomBox.slabThickness
    static let floorY: Float = RoomBox.floorY

    // MARK: - The fence, where the walls were

    /// **This room has no walls.** Owner's call, 2026-08-16: *"it's a bit
    /// strange that the garden has a wall around it."* It was, and it is the
    /// kind of wrong that only shows once the room is standing — a garden
    /// indoors.
    ///
    /// `references/REFERENCES.md` §1 locks "two walls and a floor" for every
    /// room, so this is a deviation and it is recorded in `app/README.md`. What
    /// matters is that **the rule's purpose survives it exactly**: the fence
    /// stands on the two far edges, precisely where the plaster stood, so the
    /// two near sides are still open, no wall ever comes between the camera and
    /// a prop, and nothing new has entered a sightline.
    ///
    /// The grey backdrop now shows above it, and that is right rather than
    /// merely tolerable — it is `Palette.backdropGrey`, the same grey every
    /// reference plate is shot on, so the room reads as the diorama the plates
    /// already look like.
    ///
    /// **The centreline of each run**, from `references/garden/roombox-v2.png`:
    /// an L meeting at the far corner, back run along X and left run along Z.
    static let fenceLineX: Float = -0.212
    static let fenceLineZ: Float = -0.212

    /// Picket top, and the taller posts that carry the rails.
    ///
    /// 70 mm is a bit over half Nina's height (0.125), which is what a garden
    /// fence is. It also clears the bed's rim at 0.050 and sits level with the
    /// potting bench's worktop at 0.072, so the bench top reads against the
    /// backdrop rather than against a row of pickets.
    static let fenceHeight: Float = 0.070
    static let fencePostHeight: Float = 0.086
    static let fencePostSize: Float = 0.016
    static let fencePicket = SIMD2<Float>(0.008, 0.013)
    /// Centre to centre, so the gap between two pickets is 11 mm — wide enough
    /// to see the backdrop through, which is what makes it a fence rather than
    /// a low wall.
    static let fencePicketSpacing: Float = 0.019
    /// Rails, as a fraction of the picket height. Behind the pickets.
    static let fenceRails: [Float] = [0.30, 0.72]
    /// Posts along a run, roughly every six pickets.
    static let fencePostSpacing: Float = 0.114

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
    /// `KitchenLayout.ingredientsPerRound` rather than a number of its own — if the
    /// basket ever goes back to three (`GAMEPLAY.md` §10 leaves it open), the
    /// bed follows it and nothing else has to be touched.
    static var plotCount: Int { KitchenLayout.ingredientsPerRound }

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

    // MARK: - The potting bench

    /// **The eight seed jars stand on a bench now, not on the wall.**
    ///
    /// They hung on two wall shelves, and the walls have gone. Owner's call on
    /// what replaces them: a potting bench —
    /// `references/garden/potting-bench.png` — four legs, a worktop with a low
    /// backboard, and a second shelf under it.
    ///
    /// Eight, one per `Ingredient`. `GAMEPLAY.md` §5 says six and the kitchen
    /// deals eight; growing six of the eight would leave a hole in the round the
    /// moment the basket is handed over, so the bench is the enum. See
    /// `app/README.md` for the deviation.
    ///
    /// It runs along Z in front of the left fence, which is where the shelves
    /// were — so nothing about *where she looks for a seed* has changed, only
    /// how far down.
    static let benchCentre = SIMD2<Float>(-0.178, -0.030)
    /// The worktop: depth across (x), length along (z).
    static let benchTopSize = SIMD2<Float>(0.048, 0.230)
    /// **The kitchen's table height**, deliberately. The surface she works at is
    /// then the same height in both rooms, which is one less thing for a
    /// 4-year-old's hands to relearn.
    static let benchTopY: Float = 0.072
    static let benchBoard: Float = 0.008
    /// A low upstand along the worktop's back edge. It stops the top row of jars
    /// reading as floating against the backdrop, which with no wall behind them
    /// is a real risk rather than a decoration.
    static let benchBackboard: Float = 0.018
    static let benchLegSize: Float = 0.012

    /// **The lower shelf sticks out in front of the worktop**, and that is the
    /// whole reason the bench works.
    ///
    /// The camera looks down at about 34°, so you can see under an overhang by
    /// roughly 1.5× the drop — and a jar on a shelf 42 mm below a worktop, sitting
    /// *under* that worktop, has its top 9 mm below the overhang and is cut in
    /// half. `potting-bench.png` solves it by projecting the shelf forward, and
    /// the jars on it stand **clear of the worktop's front edge**.
    ///
    /// It is the kitchen's mirrored-shelf bug rotated a quarter turn: two things
    /// at the same place on screen, one above the other, read as one place with
    /// two things in it.
    static let benchShelfY: Float = 0.030
    static let benchShelfSize = SIMD2<Float>(0.062, 0.230)
    /// Centre of the lower shelf, pushed forward of the worktop's centre.
    static var benchShelfX: Float { benchCentre.x + 0.014 }
    /// The front face of the worktop — what the lower jars have to stand clear of.
    static var benchTopFrontX: Float { benchCentre.x + benchTopSize.x / 2 }

    /// Where jar *i* stands. Four on the worktop, four on the shelf below.
    ///
    /// **54 mm centres**, so their 26 mm touch spheres do not meet — the kitchen's
    /// counter toys are the cautionary tale, where 50 mm centres and 32 mm
    /// spheres made every tap a tie-break rather than a choice.
    ///
    /// **And the lower row is staggered half a spacing**, so no jar is ever
    /// directly under another. The projection above already separates the two
    /// rows; the stagger means they are separated twice, by different axes,
    /// which is what makes eight jars read as eight rather than as four with
    /// shadows.
    static let jarSpacing: Float = 0.054
    static func jarSpot(_ index: Int) -> SIMD3<Float> {
        let perRow = 4
        let lower = index >= perRow
        let along = Float(index % perRow) - Float(perRow - 1) / 2
        let stagger: Float = lower ? jarSpacing / 2 : 0
        return SIMD3<Float>(lower ? benchTopFrontX + 0.008 : benchCentre.x,
                            (lower ? benchShelfY : benchTopY) + benchBoard,
                            benchCentre.y + jarSpacing * along + stagger)
    }

    // MARK: - Home positions

    /// **The watering can, on the near-left floor** — the flour sack's job in
    /// the kitchen: the one prop in front of everything, which is what gives the
    /// shot a foreground.
    ///
    /// x = −0.090 rather than further left because the gate's leaf sweeps
    /// x ∈ [−0.212, −0.166] as it opens; this clears that by 76 mm.
    static let canHome = SIMD3<Float>(-0.090, floorY, 0.150)

    // **The basket used to stand on the near-right floor** at (0.150, 0.120),
    // bracketing the open foreground against the can. The pond covers that spot
    // to a depth of 60 mm now, so it moved: `basketHome` lives down with the
    // pond, because the pond is what put it there.

    // MARK: - Toys

    /// Five flowers in a strip of soil, running along Z down the left-hand
    /// floor. **Low to high, left to right**, because they chime in a scale and
    /// a scale that runs the wrong way is a scale nobody hears as one.
    ///
    /// **They moved to the right-hand floor when the bench arrived**, because the
    /// bench's lower shelf now reaches x = −0.134 and they were at −0.150. The
    /// strip the deleted right-hand fence run left empty is the natural home:
    /// 35 mm clear of the bed's right end, 96 mm from the basket, and **nothing
    /// to their right at all**, so five stems on the floor cannot get in front
    /// of anything.
    /// **46 mm apart, up from 32.**
    ///
    /// A target's real size is its **perpendicular distance to the camera ray**,
    /// not its distance on the ground — `TouchRouter.hitTest` measures the
    /// former. A row running along X or Z is tilted about 37° away from the
    /// screen, so it keeps only **0.798** of its spacing as separation on
    /// screen: the old 32 mm row gave each flower a 55 pt band, less than half
    /// `CONCEPT.md` §5's ~120 pt. 46 mm gives 77 pt, which is what fits beside
    /// everything else in this corner.
    ///
    /// (A row along the **X−Z diagonal** would keep 1.000 of its spacing, since
    /// that direction is exactly screen-horizontal. Worth knowing for the next
    /// room that needs a long row — `ROOMS.md` §5.)
    static let flowerX: Float = 0.185
    static let flowerFirstZ: Float = -0.150
    static let flowerSpacing: Float = 0.046
    static let flowerCount = 5
    static func flowerSpot(_ index: Int) -> SIMD3<Float> {
        SIMD3<Float>(flowerX, floorY, flowerFirstZ + flowerSpacing * Float(index))
    }

    /// **The pond, across the bottom of the lawn** — owner's call, 2026-08-16,
    /// in place of the two puddles that stood at `(-0.030, 0.070)` and
    /// `(0.100, 0.018)`.
    ///
    /// It was built once as a 122 mm circle in the middle of the near floor and
    /// that was the wrong read: *"the pond must be bigger and totally at the
    /// bottom"*, with a sketch of a wide oval lying along the front edge. So it
    /// is an **ellipse, 196 mm along the screen and 116 mm deep**, centred on
    /// the room's own diagonal at the near corner. Its far side reaches
    /// `x + z = 0.208`, which leaves the whole middle of the floor open, and its
    /// near side stops 4 mm inside the grass.
    ///
    /// **Long axis along the screen, not along a world axis.** `GardenRoom`
    /// turns it by `GardenProps.towardsCamera`, so the ellipse's long axis is
    /// the X−Z diagonal — the one direction that is exactly screen-horizontal
    /// from this chair (`RoomBox.screenSeparation`). An oval laid along X or Z
    /// would come out as a diamond lying at 45° to the frame.
    ///
    /// **This is as wide as the room allows**, and the three things that bound
    /// it are worth writing down because the next person to be asked for a
    /// bigger one will hit the same three: the grass runs out at `±0.230`, the
    /// flower row's near end stands at `(0.185, 0.034)` — 30 mm off the rim —
    /// and the watering can holds the near-left corner.
    ///
    /// **Nothing else stands in it**, which cost three moves. The basket was in
    /// the middle of the water, the molehill was in it before that, and the
    /// butterfly hovered over the rim. All three are below, and the rule they
    /// were moved by is worth keeping: *the pond is water, and water is empty*.
    /// Anything this room gains later gets tested against the ellipse before it
    /// gets a position.
    static let pondCentre = SIMD2<Float>(0.145, 0.145)
    /// Semi-axis along the screen — the outer edge of the stone rim, not the
    /// water's. The water reaches `0.080` of it; the stones straddle that and
    /// finish here.
    static let pondLong: Float = 0.098
    /// Semi-axis into the screen. 1.7:1, which is the sketch's proportion and
    /// also what the grass allows once the ellipse is pushed this far forward.
    static let pondShort: Float = 0.058

    /// **The basket moved out of the water.**
    ///
    /// It stood at `(0.150, 0.120)`, which the pond now covers to a depth of
    /// 60 mm. This is the ground the molehill had: in front of the bed's
    /// right-hand end, 43 mm clear of its front boards, which is where a basket
    /// wants to be anyway — a picked plant hops into it from the bed, and it is
    /// now the shortest hop in the room. 85 mm of grass to the pond's rim, and
    /// on screen it clears the pond by 101 mm against the 83 the two radii need.
    static let basketHome = SIMD3<Float>(0.090, floorY, 0.008)
    /// Where a picked ingredient lands inside it, and how far apart they stack.
    static let basketRimY: Float = 0.026

    // MARK: - Toys

    /// **The molehill moved out of the water, twice.**
    ///
    /// It stood at `(0.040, 0.160)` when the pond was a circle in the middle of
    /// the floor, which put it in the middle of the water; it moved to
    /// `(0.090, 0.008)`, and the basket needed exactly that ground once the pond
    /// grew across the bottom. So it is out on the left-centre floor now, in
    /// front of the bench: 21 mm of grass to the bench's lower shelf, 185 to the
    /// pond, and on screen it clears the watering can by 89 mm against the 78
    /// two neighbouring targets need, and the nearest seed jar by 75 against 64.
    ///
    /// A mole comes up in a lawn, and this is the only piece of lawn in the room
    /// with nothing else on it.
    static let molehillSpot = SIMD3<Float>(-0.085, floorY, 0.050)

    /// **Both fliers hover, and both had to move.**
    ///
    /// A thing 85 mm in the air and 130 mm nearer the camera lands on almost the
    /// same *screen* point as a thing on the ground behind it — which is how the
    /// butterfly's old home came to sit on top of two of the bed's five holes.
    /// Tapping a ripe plant and getting a butterfly is the required action
    /// losing to a toy, so they are placed by perpendicular separation like
    /// everything else: the butterfly out in the near foreground, the bee over
    /// the far end of the flower row it visits.
    ///
    /// **The butterfly moved twice for the pond.** At `(0.060, 0.075)` its
    /// ground point was 10 mm outside the first pond's rim, which is close
    /// enough that a butterfly hovering there reads as a butterfly sitting on
    /// the water. The big pond pushed it once more, off the molehill's new
    /// screen position: it hovers over the middle of the open floor now, 83 mm
    /// of grass from the rim, 129 mm from the pond's centre on screen against
    /// the 75 the two radii need, and still 66 mm from the nearest hole against
    /// 60 — which is the constraint that put it out here in the first place.
    static let butterflyHome = SIMD3<Float>(0.045, floorY + 0.055, 0.045)
    static let beeHome = SIMD3<Float>(0.215, floorY + 0.045, -0.185)

    /// **Along the back fence**, which is where the bench pushed them.
    ///
    /// They stood in the back-left corner; the bench now occupies that ground,
    /// so the tree and the bushes spread along the back run instead — behind the
    /// bed from the camera, which is the one part of the floor nothing else
    /// wants. The tree overhangs the fence and that is right rather than a
    /// clash: a tree leaning over a garden fence is what a tree does.
    static let treeSpot = SIMD3<Float>(-0.115, floorY, -0.172)
    static let bushSpots = [SIMD3<Float>(-0.020, floorY, -0.192),
                            SIMD3<Float>(0.170, floorY, -0.185)]

    /// **The sandy path at the gate**, from `references/garden/roombox-v2.png`.
    ///
    /// It earns its place beyond the plate. `ROOMS.md` §9 says the way out says
    /// the same thing three ways, and the garden's now says it twice — a gate in
    /// a fence has no wall behind it to hold a lit plate. A patch of worn path
    /// leading out through the gate says *there is somewhere to go* in the one
    /// way left, which is by being the ground people have walked on. It emits
    /// nothing and it is one flat polygon.
    static let pathCentre = SIMD2<Float>(-0.150, 0.150)
    static let pathRadius: Float = 0.062

    // MARK: - The way out

    /// **A gate in the fence, standing where the door stood.**
    ///
    /// The kitchen's door hung on a wall, and there is no wall. What has not
    /// changed is *where*: the way out being in the same place as last time is
    /// worth more to a 4-year-old than variety is, and the swing window against
    /// the can was already worked out for this end of this run.
    ///
    /// `Props.gate` builds it and returns the very same `Props.Doorway` struct
    /// the door does, so every line of `GardenRoom`'s door behaviour — ajar when
    /// the basket is full, the swing, the ring at the threshold — is untouched.
    static let gateCentre = SIMD3<Float>(fenceLineX, floorY, 0.160)
    /// The clear gap between the two gate posts, which is what the leaf fills.
    /// **No lintel**: a gate's opening is full height, so "a door she could not
    /// walk through is a cupboard" is satisfied by construction rather than by
    /// making it 140 mm tall.
    static let gateOpening: Float = 0.080

    // MARK: - Surfaces

    /// **What the garden is made of, for `CarryController`.**
    ///
    /// Two surfaces and the ground. A seed carried over the bed rides at the
    /// **rim**, not at the soil — the rim is what it would otherwise clip, and
    /// every snap test in the room is XZ-only so riding higher cannot make a
    /// drop harder to land (`CarryController.containerRim` has the argument in
    /// full). The bench's worktop is a real surface too, so a seed crosses it
    /// rather than passing through it — and so she can genuinely put the
    /// watering can down on the bench.
    ///
    /// The bed stays the `hider`. The bench hides floor behind it as well, but
    /// that floor is already outside `clampToPlayArea`, so nothing can be lost
    /// there.
    static let surfaces = Surfaces(
        floorY: floorY,
        // Nearest-camera first, which along the +X+Z diagonal means the larger
        // x + z: the bed at −0.045, then the bench at −0.208. Their footprints
        // do not overlap, so this is documentation rather than arbitration.
        rects: [
            Surfaces.Rect(centre: bedCentre, size: bedSize, y: bedRimY),
            Surfaces.Rect(centre: benchCentre, size: benchTopSize,
                          y: benchTopY + benchBoard),
        ],
        // **The lower shelf only.** The worktop is a `Rect` above, and it must
        // not also be a shelf or the two would answer the same question twice.
        // `Surfaces.shelfY` only matches within 32 mm above a top and the
        // worktop sits 42 mm higher, so a jar on the bench can never be mistaken
        // for a jar on the shelf.
        shelves: [
            Surfaces.Shelf(x: benchShelfX, depth: benchShelfSize.x,
                           centreZ: benchCentre.y,
                           halfSpan: benchShelfSize.y / 2,
                           tops: [benchShelfY + benchBoard])
        ],
        solids: [],
        hider: Surfaces.Rect(centre: bedCentre, size: bedSize, y: bedRimY),
        // The room's own furniture: `minX` reaches the bench, `maxX` the
        // flowers, `minZ` the bushes against the back fence, `maxZ` the open
        // ground where the can and the basket stand.
        minX: -0.205, maxX: 0.200, minZ: -0.200, maxZ: 0.200,
        lift: RoomBox.carryLift
    )

    /// Horizontal distance, the only kind that matters for a drop.
    static func distanceXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        RoomBox.distanceXZ(a, b)
    }
}
