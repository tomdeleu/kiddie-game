import RealityKit
import simd

/// Where everything in the kitchen is.
///
/// One table of numbers rather than magic constants spread across the room and
/// the game, because almost every bug in a room like this is two files
/// disagreeing about where the table top is.
enum KitchenLayout {

    // **The box itself is in `RoomBox`** — `roomSize`, `half`, `wallHeight`,
    // `wallThickness`, `slabThickness`, `floorY`, `carryLift`, `distanceXZ`,
    // `pointOnRay` and `within`, plus the two walls and the floor themselves.
    //
    // They moved there when the decorating room arrived, because `ROOMS.md` §0
    // makes "the same box and the same eye" a rule rather than a convention, and
    // a rule kept in two files is the thing the paragraph below is a warning
    // about. What is left here is the kitchen's *furniture*, which is the only
    // thing that was ever kitchen-specific.
    //
    // The history worth keeping: the box is 0.40 m grown 15%, because the 0.40 m
    // kitchen had run out of floor — the table's right edge and Otto's dome were
    // 33 mm apart, the three counter toys sat at 48–52 mm centres, and seven
    // things shared a 0.210 × 0.115 m table top. Everything was reachable and
    // nothing had any air around it. **The camera moved with it**, pulled back
    // 8%, and every touch radius was scaled by the same factor.

    /// The work surface. Everything she drags lives on this plane.
    ///
    /// **Bigger and longer**: 0.280 × 0.140 m, up from 0.210 × 0.115. It is the
    /// one surface with seven things on it, so it took most of what the room
    /// gained — 70 mm of length and 25 mm of depth. It grew leftwards into the
    /// new floor and its right edge barely moved, because that edge is what
    /// Otto has to stand clear of.
    static let tableTopY: Float = 0.072
    static let tableCentre = SIMD2<Float>(-0.058, 0.052)
    static let tableSize = SIMD2<Float>(0.280, 0.140)
    static let tableThickness: Float = 0.012

    /// The back counter: sink, scale, ingredient pot.
    ///
    /// Longer by 30 mm and pushed 24 mm back against the new wall, which is
    /// what takes the three toys on it from 50 mm centres to 70 mm.
    static let counterTopY: Float = 0.058
    static let counterCentre = SIMD2<Float>(-0.092, -0.182)
    static let counterSize = SIMD2<Float>(0.230, 0.062)

    /// Otto, on the right against the back wall.
    ///
    /// **Moved 37 mm right and 12 mm back**, which is what buys the longer
    /// table. He is the room's right-hand bookend: his dome reaches x = 0.214
    /// against a floor edge at 0.230, so this is as far right as he goes
    /// without hanging off it. Moving him back as well clears his footprint out
    /// of the table's depth entirely — the two no longer share any Z at all,
    /// where before the table's corner and his dome were 33 mm apart.
    static let ovenOrigin = SIMD3<Float>(0.152, RoomBox.floorY, -0.112)
    static let ovenDomeRadius: Float = 0.062
    static let ovenDomeHeight: Float = 0.075
    /// Mouth opening, in Otto's local space.
    static let mouthArchInner: Float = 0.024
    static let mouthLegHeight: Float = 0.012
    static let mouthDepth: Float = 0.034
    static let mouthBackZ: Float = 0.042
    static var mouthFrontZ: Float { mouthBackZ + mouthDepth }
    /// Where the tin has to land, in world space: at the lip of the mouth, not
    /// inside it. The dark plug behind is solid, so a target set any deeper
    /// would make the tin vanish on arrival instead of sliding in.
    static var ovenMouth: SIMD3<Float> {
        ovenOrigin + SIMD3<Float>(0, mouthLegHeight + 0.010, mouthFrontZ - 0.002)
    }

    // MARK: - Home positions on the table
    //
    // **Spread across the whole top, in three clusters rather than one heap.**
    // The seven centres used to sit inside a 0.154 × 0.076 m patch of a
    // 0.210 × 0.115 m table, with the bowl and the spoon 1 mm apart and the tin
    // and the cake spot 2 mm; they now cover 0.222 × 0.088 of a 0.280 × 0.140
    // table and **no two are closer than 12 mm**. That number is the whole
    // point of the change — it is the difference between props that touch and
    // props that stand next to each other.
    //
    // The clusters are the round's three jobs, left to right: **roll** (dough
    // and pin, with the basket over them), **mix** (spoon and bowl, in the
    // middle where the stirring happens), **bake** (tin and the cake it comes
    // back as, on the side nearest Otto). Reading the table left to right is
    // now reading the recipe, which the heap could not say.

    static let basketHome = SIMD3<Float>(-0.170, tableTopY, 0.096)
    static let bowlHome = SIMD3<Float>(-0.032, tableTopY, 0.062)
    /// Beside the bowl rather than in front of it. On the old table it sat
    /// between the bowl and the cake spot, which is the one bit of top that
    /// needs to be clear when Otto hands a cake back.
    static let spoonHome = SIMD3<Float>(-0.092, tableTopY, 0.026)
    static let tinHome = SIMD3<Float>(0.052, tableTopY, 0.090)
    /// Lies along X from here, so its left end is what has to stay on the
    /// table: the barrel and handles run from −0.044 to +0.030 of this, which
    /// puts its left tip 6 mm inside the new top's left edge.
    static let rollingPinHome = SIMD3<Float>(-0.148, tableTopY, 0.008)
    /// The ball of dough, and where it is rolled out. Sits in the pin's path,
    /// 44 mm ahead of it — far enough to be a drag, near enough that the roll
    /// starts almost at once, and the basket sits over the pair rather than in
    /// among them.
    static let doughSpot = SIMD3<Float>(-0.150, tableTopY, 0.052)
    /// Where a finished cake lands when Otto hands it over.
    static let cakeSpot = SIMD3<Float>(0.032, tableTopY, 0.032)

    /// Nina herself, behind the table between it and the counter.
    ///
    /// Placed left of the bowl rather than squarely behind it: at the room's
    /// fixed camera angle, standing behind the bowl put her body across the
    /// sightline to the sink, and a toy she is standing in front of is a toy
    /// that never gets tapped.
    ///
    /// **She moved 40 mm left with the table**, which is more than the table
    /// itself moved, and the extra is spent on the same sightline: on the wider
    /// counter the sink went left too, and at x = −0.145 she now clears all but
    /// a sliver of it instead of covering its near half. Further left is not
    /// better — past about −0.150 she starts crossing the lower wall shelf.
    static let bakerSpot = SIMD3<Float>(-0.145, RoomBox.floorY, -0.072)

    /// **The two wall shelves.**
    ///
    /// `shelfX` puts the plank's *back* face exactly on the wall's inner face,
    /// so the depth grows forwards into the room and the shelf never floats off
    /// the plaster however deep it gets.
    ///
    /// The depth is set by what has to stand on it, not by what looks like a
    /// shelf from the side. The widest thing is the honey pot with its dipper at
    /// about 31 mm across, so 36 mm leaves a couple of millimetres at the back
    /// and clears the front. At 14 mm — the depth this was for a long time —
    /// every jar and every ingredient overhung the board and pushed into the
    /// wall behind it.
    static let shelfDepth: Float = 0.036
    static var shelfX: Float { -RoomBox.half + RoomBox.wallThickness + shelfDepth / 2 }

    /// The top face of a shelf plank, which is what everything on it stands on.
    ///
    /// **Derived rather than typed**, because it was typed twice and the two
    /// disagreed: the jars sat at `height + 0.004`, which is the top, and the
    /// ingredients at `height + 0.014`, which is 10 mm above it. They had been
    /// hovering over the plank since the shelves were built, which is hard to
    /// see against a wall and impossible to miss once you know.
    static func shelfTopY(_ height: Float) -> Float { height + 0.004 }

    /// **The five places an ingredient can come from, in order.**
    ///
    /// `GAMEPLAY.md` had all three in one basket on the table. Spreading them
    /// across the room is what makes it a kitchen rather than a work surface —
    /// she has to look up at the shelf, along the counter, and only then down
    /// at the table. The order is suggested by the halo, not enforced, so five
    /// places never becomes five decisions.
    ///
    /// **It grew from three to five**, and the two it grew by are deliberately
    /// the extremes of reach: the top shelf is the highest thing in the room
    /// and the crate is on the floor. Every other prop lives on a work surface
    /// within ten centimetres of the same height, so those two are what make
    /// the room feel like it has a ceiling and a floor rather than one plane
    /// with things on it.
    enum Source: Int, CaseIterable {
        case plankHoog = 0  // the upper wall shelf — the highest reach in the room
        case plankLaag = 1  // the lower wall shelf
        case aanrecht = 2   // the pot on the back counter
        case mandje = 3     // the basket on the table
        case krat = 4       // the crate on the floor — the lowest reach

        /// Where its ingredient waits.
        var spot: SIMD3<Float> {
            switch self {
            // The two shelf spots follow the left wall out to x = −0.211, and
            // each sits at one *end* of its own plank — 38 mm clear of the
            // nearest jar, where they used to be 25 mm from it.
            //
            // **They are at opposite ends, and that is the whole reason the
            // lower shelf is built mirrored.** Both used to be at z = 0.044,
            // which put the toverbosbes exactly 45 mm above the
            // regenboogaardbei — one directly on top of the other, which from a
            // fixed camera is the one arrangement that makes two different
            // places look like one place with two things in it. They are now
            // 148 mm apart along the wall: the high one at the near end, the low
            // one at the far end, and `RoomBuilder.buildShelf(mirrored:)` flips
            // the lower plank's three jars over to suit.
            case .plankHoog: return SIMD3<Float>(shelfX, shelfTopY(0.150), 0.044)
            case .plankLaag: return SIMD3<Float>(shelfX, shelfTopY(0.105), -0.104)
            case .aanrecht: return SIMD3<Float>(-0.034, counterTopY + 0.011, -0.174)
            case .mandje: return basketHome + SIMD3<Float>(0, 0.012, 0)
            case .krat: return crateSpot + SIMD3<Float>(0, 0.017, 0)
            }
        }

        /// The plane a drag off this source starts on — the surface it is
        /// standing on, so the grab does not jump under her finger. It is only
        /// the *starting* plane: `KitchenRoom` moves it with the prop as it
        /// descends, which is what lets one drag cross four different heights.
        var planeY: Float { spot.y }

        /// What Nina says as this one lights up. Through `Line` rather than as
        /// literals, so the five ids are spelled once in the game — a typo here
        /// is a silent source, which is the hardest kind of bug to notice.
        var lineID: String {
            switch self {
            case .plankHoog: return Line.bronPlankHoog
            case .plankLaag: return Line.bronPlankLaag
            case .aanrecht: return Line.bronAanrecht
            case .mandje: return Line.bronMandje
            case .krat: return Line.bronKrat
            }
        }
    }

    /// How many ingredients a round collects. Five sources, five ingredients.
    static var ingredientsPerRound: Int { Source.allCases.count }

    // Toys on the counter. The flour sack used to be the fourth thing on this
    // run and is now on the floor, which left the counter with room to breathe:
    // sink, scale, and the ingredient pot.
    //
    // On the longer 0.230 m counter the three sit at 70 mm centres rather than
    // 50, which is what finally puts daylight between them: bare worktop
    // between them goes from 15 and 17 mm to 33 and 39.
    //
    // It matters for more than the look. Their touch spheres are 32 mm, so at
    // the old spacing **both** neighbouring pairs overlapped and which toy she
    // got was decided by the nearest-wins tie-break in `TouchRouter.hitTest`.
    // At 70 mm centres neither pair overlaps and each tap has one answer.
    static let sinkSpot = SIMD3<Float>(-0.174, counterTopY, -0.182)
    static let scaleSpot = SIMD3<Float>(-0.104, counterTopY, -0.176)

    /// **The flour sack sits on the floor**, in the near-left foreground where
    /// the room is open. A sack of flour is a heavy thing, and a heavy thing on
    /// a worktop reads as a jar; on the ground it reads as a sack. It is also
    /// the one prop in front of the table, which gives the shot a foreground.
    static let flourSpot = SIMD3<Float>(-0.062, RoomBox.floorY, 0.178)

    /// The crate the fifth ingredient waits in, on the floor to Otto's near
    /// side. Placed off the table's right edge rather than behind it: the
    /// camera looks down the +X+Z diagonal, so floor to the *left* of the table
    /// is hidden by the table itself and floor to the right is not.
    ///
    /// **Moved out into the near-right foreground** (owner's note: it sat too
    /// close to both the oven and the table). At (0.132, 0.058) it had 24 mm of
    /// floor between it and the table's right edge and sat tucked into the
    /// corner where the table's corner and Otto's footprint nearly meet — a
    /// place with no floor around it, which is what makes a thing read as shoved
    /// under the furniture rather than standing on the ground. It now has 42 mm
    /// of clear floor to the table's nearest corner and is a full 190 mm from
    /// Otto's dome, out where the room is open.
    ///
    /// It is also now the right-hand half of a pair: the flour sack stands on
    /// the near-left floor and this stands on the near-right, so the two of them
    /// bracket the open foreground instead of both crowding the middle.
    static let crateSpot = SIMD3<Float>(0.150, RoomBox.floorY, 0.126)

    /// The plank on the back wall the finished cakes stand on.
    ///
    /// **0.190 m long, up from 0.150** (owner: it should be longer so putting
    /// something on it is easier). It buys two separate things, and the second
    /// one is the point of the change:
    ///
    /// - the four cake slots go from 37.5 mm to 47.5 mm, and the shrunk cakes
    ///   are 32 mm across, so they stand apart rather than shoulder to shoulder;
    /// - **the landing zone gets 40 mm wider**, because `nearPlank` measures
    ///   half the plank plus `plankSnapRadius` — so the last action of the whole
    ///   round, which is also the one performed at arm's length against the back
    ///   wall, is the most forgiving one in the room.
    ///
    /// It grew leftwards. The right end stays near x = 0 because past that it
    /// would start crossing Otto's chimney; the left end reaches −0.190 against
    /// a wall face at −0.218.
    static let cakePlankY: Float = 0.135
    static let cakePlankCentre = SIMD2<Float>(-0.095, -0.196)
    static let cakePlankLength: Float = 0.190
    static let cakeShelfCapacity = 4

    /// **How many cakes finish the kitchen.**
    ///
    /// The room had no end. It looped: bake a cake, put it on the plank, bake
    /// another, forever, and the only thing that ever changed was which four
    /// cakes were on the shelf. Three gives the loop a shape — long enough that
    /// the third one is an achievement, short enough that it is one sitting for
    /// a 4-year-old at roughly eleven minutes a round.
    ///
    /// It is a floor rather than a quota. Nothing stops at three: a fresh round
    /// still starts, the dough is still on the table, and she can bake a fourth
    /// if she would rather. What three does is **open the door** —
    /// `KitchenRoom.roomComplete`.
    ///
    /// Below `cakeShelfCapacity` on purpose, so finishing the room never
    /// depends on the plank having dropped an older cake off the end of itself.
    static let cakesToFinish = 3

    /// **Nina's portrait, framed, on the back wall above Otto.**
    ///
    /// The one picture in the kitchen, and the only thing hanging on the back
    /// wall's right-hand half — which until now was the only large blank surface
    /// in the room, and read as blank.
    ///
    /// It is built rather than textured, which is the same call
    /// `references/props/README.md` records for every other prop: a photograph
    /// mapped onto a plane in a room made of flat-shaded facets is the flour
    /// cloud all over again — the one thing on screen that came from somewhere
    /// else. So the photo is the *brief*, and what hangs on the wall is the
    /// faceted version of it. See `KitchenProps.portrait`.
    ///
    /// The height is fixed at both ends: the frame's bottom edge clears the top
    /// of Otto's chimney rim (0.114) and its top edge clears the wall (0.235).
    static let portraitCentre = SIMD3<Float>(0.152, 0.175, -RoomBox.half + RoomBox.wallThickness)
    /// Outer size of the frame, and how far it stands off the plaster.
    /// **The box the picture fits inside**, rather than a fixed picture size.
    ///
    /// The photograph decides its own shape: `KitchenProps.portrait` reads the
    /// texture's pixel dimensions and fits it in here preserving its aspect, so
    /// dropping in a landscape photo gives a landscape frame and a portrait one
    /// gives a portrait frame, both at about the same visual weight on the wall.
    /// Nothing has to be re-measured when the file changes.
    static let portraitPictureMax = SIMD2<Float>(0.076, 0.076)
    /// The picture size the *modelled* fallback is laid out for — it is a face
    /// built to fit an opening, not a photo that can be any shape.
    static let portraitFallbackPicture = SIMD2<Float>(0.058, 0.074)
    /// Width of the frame's rails.
    static let portraitRail: Float = 0.006
    /// Deep enough to be a shallow shadow-box rather than a flat plaque, so
    /// everything inside it sits *behind* the front of the rails and only the
    /// face is in relief. It is the same 12 mm the door frame stands proud of
    /// the left wall, for the same reason: at this camera a casing with no
    /// visible side reads as paint.
    static let portraitDepth: Float = 0.012

    /// The way out, on the left wall. Leads to the decorating room when it
    /// exists; for now it opens, shows the light on the other side, and swings
    /// shut again.
    ///
    /// **It is a door now, not an arch** (owner's call on the 2026-08-15
    /// build: "that doesn't look like a door at all"). What it was — a pink
    /// arched ring flat on the wall, with a butter-yellow plug filling it that
    /// no code ever lit — read as decoration, which is what it had become when
    /// the round stopped ending here. A leaf, two panels and a knob read as a
    /// way out from across the room.
    ///
    /// The x follows the left wall out — it is the wall face plus the 2 mm
    /// `doorFrameZ` stands proud of it, and `doorWallFace` re-derives that
    /// from `half`, so the two cannot drift apart.
    ///
    /// **It moved 32 mm towards the camera, because it could not open.** At
    /// z = 0.140 the opening ran from z = 0.103 to 0.177 and the table's near
    /// edge is at z = 0.122, so the two overlapped by 19 mm — and the leaf
    /// swings *into* the room off the near jamb, which put its outer half
    /// straight through the table top. Owner's report on the 2026-08-16 build:
    /// "the door cannot open without being through the table."
    ///
    /// The fix is z, not x, and it is bounded on both sides. The whole left wall
    /// is spoken for — the counter takes z ∈ [−0.213, −0.151], the two
    /// ingredient shelves take [−0.120, 0.060] and the table takes
    /// [−0.018, 0.122] — so the only clear run is the near-left corner, and the
    /// door is 94 mm wide across its frame. Working the swing out gives the
    /// window: the leaf's worst reach over the table's x-range is 71.8 mm back
    /// from the hinge (at 14°, not at full open — a nearly-shut door is longer
    /// in z than an open one), so the centre has to sit above z = 0.157; and the
    /// frame's outer edge has to stay on the floor, which caps it at 0.183.
    /// **0.172 sits in the middle of that window**: 15 mm of daylight between
    /// the swept leaf and the table, and 11 mm between the frame and the floor's
    /// near edge.
    ///
    /// The table did not have to move, and did not. It is the one thing in the
    /// room seven props are laid out on, and every one of those positions is
    /// absolute.
    static let doorwayCentre = SIMD3<Float>(-0.216, RoomBox.floorY, 0.172)

    /// The hole in the wall: width, then height. **Taller than Nina**, who is
    /// 0.125 m — a door she could not walk through is a cupboard, and the one
    /// thing this prop has to say is *there is somewhere else*.
    static let doorOpening = SIMD2<Float>(0.074, 0.140)
    /// Jamb and lintel width.
    static let doorFrameWidth: Float = 0.010
    static let doorFrameDepth: Float = 0.016
    static let doorLeafThickness: Float = 0.007

    /// **Where the wall is, in the door's own space.** The door is built in a
    /// local frame whose +Z points out into the room, and the one number every
    /// part of it has to agree with is the face of the wall it hangs on: a
    /// millimetre the wrong side of this and the part is inside the wall,
    /// which is exactly how the arch it replaced ended up with a glow nobody
    /// could ever have seen. Derived, so moving the door along the wall or
    /// changing the wall's thickness cannot leave it stale.
    static var doorWallFace: Float { (-RoomBox.half + RoomBox.wallThickness) - doorwayCentre.x }
    /// The frame's centre, and the leaf's back face — both out in the room.
    static let doorFrameZ: Float = 0.002
    static let doorLeafZ: Float = 0.003

    /// **Where the leaf rests once the kitchen is finished: on the latch, not
    /// shut.** About 11°, which is the smallest angle that still shows a slice
    /// of the light behind it at this camera — the point is not to open the
    /// door, it is to say the door is *openable*, and a door standing ajar says
    /// that without a word or an arrow. Tapping it takes it the rest of the way
    /// and lets it fall back to here rather than to shut.
    static let doorAjarAngle: Float = -0.20
    /// How far a tap opens it. **35°, not wide open**: past about 45° the leaf's
    /// face turns out of the key light, which comes over the camera's right
    /// shoulder, and a door that goes dark as it opens looks like a hole.
    static let doorOpenAngle: Float = -0.62

    /// **Directly below the middle of the doorframe**, which is the only place
    /// it reads as the door's.
    ///
    /// It has been out in the room twice — first 46 mm from the wall, then 40 —
    /// on the reasoning that a ring must not reach into the plaster, and both
    /// times it read as *a disc of light near a door* rather than as light
    /// coming from one. From a camera on the +X+Z diagonal, a point 40 mm out
    /// from the wall is also visibly down and to the right of the door it
    /// belongs to, so it looked mispositioned as well as detached.
    ///
    /// It now sits on the frame's own centre plane, so the ring is concentric
    /// with the doorway. **Its back half is inside the wall and that is fine** —
    /// the wall is a solid box from y = 0 up, so the buried part is simply
    /// occluded, with no z-fighting, and what is left is a bright crescent
    /// hugging the threshold. Which is what light through a doorway actually
    /// looks like: the thing that was wrong was never the clipping, it was
    /// pulling the ring away from the door to avoid it.
    static var doorHaloSpot: SIMD3<Float> {
        SIMD3<Float>(doorwayCentre.x + doorFrameZ, RoomBox.floorY, doorwayCentre.z)
    }
    /// Passed to `Halo.attach`, which multiplies it by 1.10 — so this is 35 mm
    /// of ring, of which the front ~60% clears the wall and shows. Slightly
    /// larger than the prop halos on purpose: half of it is behind plaster.
    static let doorHaloRadius: Float = 0.032

    // MARK: - Height

    /// **The kitchen's own surfaces**, handed to `CarryController`.
    ///
    /// This section used to *be* the height model, and it lived here because
    /// there was one room. There are two now, so the model moved to
    /// `Engine/Surfaces.swift` and this is the kitchen's instance of it — the
    /// same four rectangles, the same two shelves, the same bounds, declared
    /// off the constants above so nothing can drift.
    ///
    /// **Everything below this is a one-line forward**, deliberately: every call
    /// site in `KitchenRoom` keeps the name it has always used, so moving the
    /// model could not change the room's behaviour.
    ///
    /// **The cake plank is not in here.** It hangs on the wall directly above
    /// the back of the counter, so as a surface it would shadow the counter and
    /// fling the sink brush shelf-high. It is a snap target instead — see
    /// `nearPlank` — and only the cake ever uses it, through
    /// `CarryController.pointedExtra`.
    static let surfaces = Surfaces(
        floorY: floorY,
        // Nearest-camera first, so the table wins over the counter where their
        // footprints meet.
        rects: [
            Surfaces.Rect(centre: tableCentre, size: tableSize, y: tableTopY),
            Surfaces.Rect(centre: counterCentre, size: counterSize, y: counterTopY),
        ],
        // Both planks, as one run down the left wall. Registered the moment the
        // shelves were built is the rule; they were not, and for two of the five
        // fetching steps the halo landed on the floor 150 mm below the berry it
        // was pointing at.
        shelves: [
            Surfaces.Shelf(x: shelfX, depth: shelfDepth, centreZ: -0.030,
                           halfSpan: 0.090,
                           tops: [shelfTopY(0.150), shelfTopY(0.105)])
        ],
        // Inside the counter is inside a solid box, which is worse than hidden.
        solids: [Surfaces.Rect(centre: counterCentre, size: counterSize, y: counterTopY)],
        // The table is what the fixed camera cannot see past.
        hider: Surfaces.Rect(centre: tableCentre, size: tableSize, y: tableTopY),
        // The room's own furniture, not round numbers, which is why they moved
        // when it did: `minX` reaches the wall shelves at −0.211, `maxX` reaches
        // past Otto's mouth at 0.152 so the tin can be pushed all the way in,
        // `minZ` reaches the cake plank at −0.196, and `maxZ` is the open floor
        // in front of the table.
        //
        // **The near edge grew** when props stopped floating home. A prop
        // released nowhere in particular now lands on whatever is under it, and
        // the floor strip in front of the table is both the most visible floor
        // there is and the only place a thing can be set down without something
        // else already being there.
        minX: -0.215, maxX: 0.190, minZ: -0.205, maxZ: 0.190,
        lift: 0.012
    )

    /// **What a prop is standing on at this point in the room.**
    ///
    /// Everything used to be carried at one height — the table top — whatever
    /// it was over, which is why the room read as a painted backdrop: a prop
    /// dragged off the table stayed at table height and simply floated. The
    /// fix is not a physics engine; it is knowing what is underneath.
    ///
    /// `CarryController` eases the carried prop towards this plus a small lift,
    /// and the drag plane follows it down. So dragging the rolling pin off the
    /// table and onto the floor *lowers* it, over about a third of a second, and
    /// it stays under her finger the whole way.
    static func surfaceY(at point: SIMD3<Float>) -> Float { surfaces.y(at: point) }

    /// **What her finger is pointing at**, which is not the same question as
    /// `surfaceY(at:)` and is the one a drag has to ask.
    ///
    /// `surfaceY(at:)` answers "what is underneath this world point" — right for
    /// settling a prop that has already been put down, and for the halo, both of
    /// which start from a position. This answers "which surface does the line
    /// from her eye through her fingertip land on first", and it is a pure
    /// function of the touch: it does not look at the prop at all.
    ///
    /// **That independence is the entire point, and it is what fixes the drag.**
    /// Carrying used to take the XZ from a plane frozen at pick-up height while
    /// the prop's own height eased between surfaces, so the prop slid up or down
    /// the screen away from her fingertip — 68 mm of world height between the
    /// table and the floor, which at this camera throws the prop most of a
    /// thumb's width off her finger and reads as it jumping somewhere else
    /// (owner, 2026-08-16). The obvious repair — re-project on a plane at the
    /// prop's *current* height — is the thing `CarryController.pickUp` documents
    /// as a feedback loop, and it is worth knowing why the loop is real: at this
    /// eye, moving the plane by Δ slides the intersection about 1.63Δ along the
    /// view direction, so a prop stepping off the table drops 68 mm, which drags
    /// the mapped point 78 mm back *onto* the table, which lifts it again. It
    /// oscillates, and that is exactly the judder the cake used to have at the
    /// plank.
    ///
    /// Deciding the surface from the ray alone breaks the loop, because the
    /// height can no longer feed back into the choice: the surface depends on
    /// her finger, the prop's height chases the surface, and the prop's XZ is
    /// read off the same ray at whatever height it has reached. Nothing in that
    /// chain points backwards, so the prop stays under her fingertip at every
    /// height and cannot flip between two of them.
    ///
    /// It reads better as a rule, too. Pointing at the table means the table;
    /// pointing at the floor in front of it means the floor.
    ///
    /// **And it makes losing a prop behind the table impossible**, which is
    /// worth spelling out because it falls straight out of the construction. A
    /// floor point is hidden exactly when the sightline to it crosses the table
    /// top inside the table's footprint — and that sightline *is* this ray, so
    /// the crossing is the very point tested on the first line. Any floor she
    /// could reach the hidden strip through is a ray that hit the table first,
    /// and got the table. `isOutOfSight` and the float-home in `settle` stay as
    /// the safety net for the small constant grab offset a carried prop keeps
    /// off the ray, but they should now essentially never fire.
    ///
    /// Tested top-down, which for horizontal planes whose footprints do not nest
    /// is nearest-camera first.
    @MainActor
    static func surfacePointedAt(from anchor: SIMD3<Float>) -> Float {
        surfaces.pointedAt(from: anchor)
    }

    /// **The shelf a prop is standing on, if it is standing on one.**
    ///
    /// Deliberately *not* part of `surfaceY(at:)`, for the same reason the cake
    /// plank is not: these are wall furniture hanging over open floor, and a
    /// surface lookup that returned them would fling anything dragged near the
    /// left wall up to shelf height.
    ///
    /// What needs them is the halo, which asks what a prop is *standing on* in
    /// order to lay its ring there — and for the two ingredients that wait on
    /// the shelves it was answering "the floor", putting the ring 150 mm below
    /// the berry it was pointing at. For two of the five fetching steps the only
    /// instruction in the game was pointing at the wrong place.
    ///
    /// Height is what makes it safe to ask: a prop only matches while it is
    /// actually up at shelf level, so the moment she lifts one off, the ring
    /// stops following the shelf and goes back to answering for the room.
    static func shelfSurfaceY(at point: SIMD3<Float>) -> Float? {
        surfaces.shelfY(at: point)
    }

    /// Whether a point is close enough to the plank to count as putting a cake
    /// on it. Generous by design: `CONCEPT.md` §5 asks for drops that count
    /// when they land *near*, and this is the last action of the whole round.
    static let plankSnapRadius: Float = 0.067

    /// **Read `cakePlankCentre` as (x, z), the way every other centre in this
    /// file is read.** It used to build a `SIMD3(x, cakePlankY, z)` first and
    /// then compare `point.z` against that vector's `.y` — which is the plank's
    /// *height*, 0.135, not its depth, −0.172. The snap zone landed 30 cm out,
    /// in front of the table instead of against the back wall, so the cake rose
    /// to shelf height when dragged towards the camera and did nothing at all
    /// when dragged to the plank. Two spellings of `.y` in one expression, one
    /// meaning a height and the other a depth, is the whole bug.
    static func nearPlank(_ point: SIMD3<Float>) -> Bool {
        // Along the plank it is a whole shelf wide; away from the wall it is
        // the snap radius, so reaching for it from the table still counts.
        abs(point.x - cakePlankCentre.x) <= cakePlankLength / 2 + plankSnapRadius
            && abs(point.z - cakePlankCentre.y) <= plankSnapRadius
    }

    /// **Somewhere she could put a thing and then not get it back.**
    ///
    /// "It stays where you put it" is right up until she puts it where the
    /// table is in the way. The camera never moves (`CONCEPT.md` §9.4), so
    /// there is a fixed patch of floor behind the table that is simply not on
    /// screen — a rolling pin left there is gone, and a 4-year-old has no
    /// camera control to go and find it. Those drops float back instead.
    ///
    /// Only floor-level drops can be lost. Anything on a work surface is above
    /// the things that would hide it.
    ///
    /// The patch is derived rather than typed in, so it stays true if the table
    /// or the camera ever move: follow the sightline from the eye to the point,
    /// see where it crosses the height of the table top, and ask whether that
    /// is over the table. At the committed camera that region is roughly
    /// x ∈ [−0.215, 0.02], z ∈ [−0.11, 0.06] — the strip of floor between the
    /// table and the counter, which is where Nina stands.
    ///
    /// **It grew with the table**, from a hand-sized patch to that strip, and
    /// that is the derivation doing its job rather than a regression: a bigger
    /// table hides more floor behind it, so more floor has to be off limits.
    @MainActor
    static func isOutOfSight(_ point: SIMD3<Float>) -> Bool {
        surfaces.isOutOfSight(point)
    }

    /// How far a carried prop may travel.
    ///
    /// **The whole working half of the room, not the table.** Two things pushed
    /// it out from the table's own footprint, and both were bugs first:
    ///
    /// - the tin has to reach Otto's mouth, off the table's far corner —
    ///   clamping to the table left it four millimetres short and the round
    ///   could not be finished;
    /// - ingredients now start on the wall shelf and the back counter, and a
    ///   clamp that began at the table's edge yanked them four centimetres
    ///   sideways the instant she picked one up.
    ///
    /// A prop released anywhere in here simply stays where it was put, so being
    /// generous costs nothing.
    ///
    /// **The near edge grew** when props stopped floating home. A prop released
    /// nowhere in particular now lands on whatever is under it, and the floor
    /// strip in front of the table — the open near side of the room box — is
    /// both the most visible floor there is and the only place a thing can be
    /// set down without something else already being there. Stopping the clamp
    /// at the table's near edge would have made the one obvious place to put a
    /// rolling pin down the one place it could not go.
    ///
    /// **The bounds are the room's own furniture, not round numbers**, which is
    /// why they moved with it: `minX` reaches the wall shelves at −0.211,
    /// `maxX` reaches past Otto's mouth at 0.152 so the tin can be pushed all
    /// the way in, `minZ` reaches the cake plank at −0.196, and `maxZ` is the
    /// open floor in front of the table.
    static func clampToPlayArea(_ p: SIMD3<Float>) -> SIMD3<Float> {
        surfaces.clamp(p)
    }
}

/// Builds the kitchen room box procedurally, matching
/// `references/plates/03-kitchen-roombox.png`.
///
/// Procedural rather than imported on purpose. The style is primitives —
/// boxes, prisms, faceted spheres — so code is a faster loop than a modelling
/// round-trip, and it removes the asset pipeline from the question the POC
/// existed to answer.
///
/// This file builds only what does not move: the furniture and Otto's body.
/// The shell — two walls, a floor and a slab — is `RoomBox.shell`, because it is
/// the same in every room. Anything she can pick up, fill, stir or eat is in
/// `KitchenProps` and is owned by `KitchenRoom`, because those have state and
/// this does not.
enum RoomBuilder {

    static func build(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "RoomRoot"

        // **The shell is `RoomBox`'s**, not the kitchen's — two walls, a floor
        // and a slab, identical in every room. What follows is the furniture,
        // which is the only part that was ever the kitchen's own.
        root.addChild(RoomBox.shell(flat: flat))

        root.addChild(buildTable(flat: flat))
        root.addChild(buildCounter(flat: flat))
        // The lower shelf is built mirrored end for end. Its ingredient then
        // stands at the far end while the upper shelf's stands at the near one,
        // so the two are 148 mm apart along the wall instead of one directly
        // above the other — see `KitchenLayout.Source.spot`.
        root.addChild(buildShelf(flat: flat, height: 0.150, mirrored: false))
        root.addChild(buildShelf(flat: flat, height: 0.105, mirrored: true))
        root.addChild(buildCakePlank(flat: flat))

        return root
    }

    // MARK: - Furniture

    static func buildTable(flat: Bool) -> Entity {
        let table = Entity()
        table.name = "Table"
        table.position = [KitchenLayout.tableCentre.x, 0, KitchenLayout.tableCentre.y]

        let topCentreY = KitchenLayout.tableTopY - KitchenLayout.tableThickness / 2
        let top = model(.box([KitchenLayout.tableSize.x, KitchenLayout.tableThickness, KitchenLayout.tableSize.y]),
                        Palette.sandyWood, flat: flat, name: "TableTop")
        top.position = [0, topCentreY, 0]
        table.addChild(top)

        let legHeight = topCentreY - KitchenLayout.tableThickness / 2
        let dx = KitchenLayout.tableSize.x / 2 - 0.014
        let dz = KitchenLayout.tableSize.y / 2 - 0.014
        for (i, offset) in [SIMD2<Float>(-dx, -dz), [dx, -dz], [-dx, dz], [dx, dz]].enumerated() {
            let leg = model(.box([0.012, legHeight, 0.012]),
                            Palette.sandyWood, flat: flat, name: "TableLeg\(i)")
            leg.position = [offset.x, legHeight / 2, offset.y]
            table.addChild(leg)
        }
        return table
    }

    /// The run along the back wall. Solid box rather than a carcass with legs —
    /// it is seen end-on and a carcass would be geometry nobody looks at.
    static func buildCounter(flat: Bool) -> Entity {
        let counter = Entity()
        counter.name = "Counter"
        counter.position = [KitchenLayout.counterCentre.x, 0, KitchenLayout.counterCentre.y]

        let bodyHeight = KitchenLayout.counterTopY - RoomBox.floorY - 0.008
        let body = model(.box([KitchenLayout.counterSize.x - 0.012, bodyHeight, KitchenLayout.counterSize.y - 0.010]),
                         Palette.creamLight, flat: flat, name: "CounterBody")
        body.position = [0, RoomBox.floorY + bodyHeight / 2, 0]
        counter.addChild(body)

        let top = model(.box([KitchenLayout.counterSize.x, 0.008, KitchenLayout.counterSize.y]),
                        Palette.sandyWood, flat: flat, name: "CounterTop")
        top.position = [0, KitchenLayout.counterTopY - 0.004, 0]
        counter.addChild(top)

        // Hugs the back wall and meets the floor along its whole footprint —
        // contact grounds it, and its cast could only smear the walls.
        counter.excludeFromShadowCasting()
        return counter
    }

    /// One wall shelf: a plank, three jars, and a gap at one end where the
    /// round's ingredient stands.
    ///
    /// `mirrored` flips the contents end for end about the plank's own centre
    /// (z = −0.030), which moves the gap from the near end to the far one. It
    /// exists for exactly one reason: the two shelves each hold an ingredient,
    /// and with both planks laid out the same way those two sat at the same z
    /// and 45 mm apart in y — one directly above the other, which from a camera
    /// that never moves is indistinguishable from one place holding two things.
    /// Mirroring the lower shelf puts them at opposite ends and costs nothing:
    /// it is the same plank and the same three jars, read backwards.
    static func buildShelf(flat: Bool, height: Float, mirrored: Bool = false) -> Entity {
        let shelf = Entity()
        shelf.name = "Shelf\(Int(height * 1000))"
        let x = KitchenLayout.shelfX
        let plankCentreZ: Float = -0.030

        // 0.180 long, up from 0.150, so the three jars and the ingredient
        // standing at one end all get the wider spacing the room gained.
        //
        // **And 0.036 deep, up from 0.014** — the plank was narrower than the
        // things standing on it. A jar is 20 mm across and the honey pot 31 mm
        // with its dipper, on a 14 mm board whose back edge was already flush
        // with the plaster, so they hung off the front *and* pushed into the
        // wall (owner, 2026-08-16: "ingredients clip the wall"). The depth is
        // now set by the widest prop that can stand here rather than by what
        // looked like a shelf in elevation.
        let plank = model(.box([KitchenLayout.shelfDepth, 0.008, 0.180]),
                          Palette.sandyWood, flat: flat, name: "ShelfPlank")
        plank.position = [x, height, plankCentreZ]
        shelf.addChild(plank)

        // Three jars, not six — the style wants fewer, bigger props. 54 mm
        // centres rather than 45: their touch radius is 24 mm, so at the old
        // spacing the spheres very nearly met.
        let jarColours = [Palette.mint, Palette.creamLight, Palette.blushPinkDeep]
        for (i, colour) in jarColours.enumerated() {
            let along = Float(-0.102) + Float(i) * 0.054
            // Reflect about the plank's centre. The jars keep their order, so
            // the mint one is still the outermost of the three.
            let z = mirrored ? 2 * plankCentreZ - along : along
            let jar = model(.prism(radius: 0.010, height: 0.022, sides: 8),
                            colour, flat: flat, name: "Jar\(Int(height * 1000))_\(i)")
            jar.position = [x, KitchenLayout.shelfTopY(height), z]
            shelf.addChild(jar)

            let lid = model(.prism(radius: 0.011, height: 0.005, sides: 8),
                            Palette.rose, flat: flat, name: "JarLid\(Int(height * 1000))_\(i)")
            lid.position = [x, KitchenLayout.shelfTopY(height) + 0.022, z]
            shelf.addChild(lid)
        }
        // Wall-mounted, centimetres from the plaster: the shadow a shelf and
        // its jars cast onto the wall behind them reads as a stain, and the
        // jars are grounded by standing on the plank, not by a cast.
        shelf.excludeFromShadowCasting()
        return shelf
    }

    /// De taartenplank — where her finished cakes stand.
    ///
    /// A stand-in for the wall of twelve frames (`GAMEPLAY.md` §2), which lives
    /// in the bakery and does not exist yet. It does the same job in miniature:
    /// it means the second cake is not the first cake again.
    static func buildCakePlank(flat: Bool) -> Entity {
        let shelf = Entity()
        shelf.name = "CakePlank"

        let plank = model(.box([KitchenLayout.cakePlankLength, 0.008, 0.030]),
                          Palette.rose, flat: flat, name: "CakePlankBoard")
        plank.position = [KitchenLayout.cakePlankCentre.x, KitchenLayout.cakePlankY, KitchenLayout.cakePlankCentre.y]
        shelf.addChild(plank)

        // The brackets follow the ends of the board rather than sitting at a
        // typed-in offset, so lengthening the plank cannot leave them stranded
        // in the middle of it.
        let bracketInset = KitchenLayout.cakePlankLength / 2 - 0.013
        for (i, dx) in [-bracketInset, bracketInset].enumerated() {
            let bracket = model(.box([0.008, 0.020, 0.008]),
                                Palette.blushPinkDeep, flat: flat, name: "CakePlankBracket\(i)")
            bracket.position = [KitchenLayout.cakePlankCentre.x + dx,
                                KitchenLayout.cakePlankY - 0.014,
                                KitchenLayout.cakePlankCentre.y - 0.008]
            shelf.addChild(bracket)
        }
        // Wall-mounted like the ingredient shelves, and for the same reason.
        shelf.excludeFromShadowCasting()
        return shelf
    }

    // MARK: - Helpers

    /// Geometry cases, so a prop is defined once and rebuilt in either shading
    /// mode when the debug toggle flips.
    enum Shape {
        case box(SIMD3<Float>)
        case prism(radius: Float, height: Float, sides: Int)
        case taperedPrism(bottomRadius: Float, topRadius: Float, height: Float, sides: Int)
        case icosphere(radius: Float, subdivisions: Int)
        case dome(radius: Float, height: Float, sides: Int, rings: Int)
        case bowl(bottomRadius: Float, topRadius: Float, height: Float,
                  wallThickness: Float, floorThickness: Float, sides: Int, rings: Int)
        case archRing(innerRadius: Float, outerRadius: Float, legHeight: Float,
                      depth: Float, segments: Int)
        case archPlug(radius: Float, legHeight: Float, depth: Float, segments: Int)
        case lathe(profile: [SIMD2<Float>], sides: Int)
        case extrude(outline: [SIMD2<Float>], thickness: Float)
        case star(points: Int, outerRadius: Float, innerRadius: Float, thickness: Float)
        /// A flat ring lying in XZ. `FacetedMesh` has had it since the halo was
        /// built; it reaches the `Shape` enum now because the garden's watering
        /// can and harvest basket both want a rim, and a rim is what says a
        /// vessel has an inside.
        case annulus(innerRadius: Float, outerRadius: Float, segments: Int)
        case ribbon(points: [SIMD3<Float>], normals: [SIMD3<Float>],
                    width: Float, thickness: Float)

        var geometry: FacetedMesh.Geometry {
            switch self {
            case .box(let size):
                return FacetedMesh.box(size)
            case .prism(let r, let h, let s):
                return FacetedMesh.prism(radius: r, height: h, sides: s)
            case .taperedPrism(let br, let tr, let h, let s):
                return FacetedMesh.taperedPrism(bottomRadius: br, topRadius: tr, height: h, sides: s)
            case .icosphere(let r, let sub):
                return FacetedMesh.icosphere(radius: r, subdivisions: sub)
            case .dome(let r, let h, let s, let rings):
                return FacetedMesh.dome(radius: r, height: h, sides: s, rings: rings)
            case .bowl(let br, let tr, let h, let wall, let floor, let s, let rings):
                return FacetedMesh.bowl(bottomRadius: br, topRadius: tr, height: h,
                                        wallThickness: wall, floorThickness: floor,
                                        sides: s, rings: rings)
            case .archRing(let ir, let or, let leg, let d, let seg):
                return FacetedMesh.archRing(innerRadius: ir, outerRadius: or,
                                            legHeight: leg, depth: d, segments: seg)
            case .archPlug(let r, let leg, let d, let seg):
                return FacetedMesh.archPlug(radius: r, legHeight: leg,
                                            depth: d, segments: seg)
            case .lathe(let profile, let sides):
                return FacetedMesh.lathe(profile: profile, sides: sides)
            case .extrude(let outline, let thickness):
                return FacetedMesh.extrude(outline, thickness: thickness)
            case .star(let points, let outer, let inner, let thickness):
                return FacetedMesh.star(points: points, outerRadius: outer,
                                        innerRadius: inner, thickness: thickness)
            case .annulus(let inner, let outer, let segments):
                return FacetedMesh.annulus(innerRadius: inner, outerRadius: outer,
                                           segments: segments)
            case .ribbon(let points, let normals, let width, let thickness):
                return FacetedMesh.ribbon(points: points, normals: normals,
                                          width: width, thickness: thickness)
            }
        }
    }

    static func model(_ shape: Shape, _ colour: UIColorLike,
                      flat: Bool, name: String) -> ModelEntity {
        let mesh = FacetedMesh.mesh(shape.geometry, flat: flat)
        let entity = ModelEntity(mesh: mesh, materials: [Palette.material(colour)])
        entity.name = name
        return entity
    }
}
