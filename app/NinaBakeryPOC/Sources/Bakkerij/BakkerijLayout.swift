import RealityKit
import simd

/// **Where everything in De Bakkerij stands.** `GAMEPLAY.md` §6.1.
///
/// Same box and same eye as every other room (`ROOMS.md` §0), so **no touch
/// radius in here needs rescaling** and none of these numbers is a fact about a
/// camera. What is a fact about the camera is the spacing, and this room is the
/// first to have twelve targets on a **vertical** plane — `ROOMS.md` §5's
/// arithmetic was written for props standing on a floor, and the wall of frames
/// is the case it had never been run against.
///
/// It was run before any geometry was written, which is the whole point:
/// *"far cheaper before the props are placed than after"*. What it found, and
/// what these numbers are:
///
/// - On this wall a **z-pitch keeps about 0.84** of its spacing on screen and a
///   **y-pitch about 0.92**. So a grid that looks square in metres is not square
///   to a finger, and the rows are the tighter direction, not the columns.
/// - At a 60 mm column pitch and a 45 mm row pitch, the tightest pair of frames
///   is **41 mm apart on screen — a 71 pt band each** under nearest-wins. That is
///   under `CONCEPT.md` §5's ~120 pt, and it is `ROOMS.md` §5's **sanctioned
///   like-things-in-a-row case**: twelve frames are twelve equally-right answers,
///   an imprecise tap lands on the nearest ghost, and landing on the neighbour
///   costs her nothing but a different friend. The garden's five holes and the
///   kitchen's eight jars are the same trade.
/// - **The unlike pairs are the ones that had to clear**, and six of them did not
///   on the first pass. Five were fixed by moving props; the sixth was fixed by
///   moving the blind, which is the note below.
///
/// **The blind hangs over the shop window, not over the frames.** The first
/// layout put it across the wall of frames, on the reading that `opendoen`
/// reveals the wall. It does — but §6.1 says pulling the cord makes *"daylight
/// flood the room and the wall of frames light up"*, and daylight comes through a
/// window. Hanging it there gives the same reveal by the honest route, puts the
/// cord on the back wall where it is nowhere near a frame, and hands the entire
/// left wall to the twelve. It also pairs the blind with the window, which is
/// already one of §6.1's five toys.
enum BakkerijLayout {

    // MARK: - The two walls

    /// Inner face of the left wall — the frame wall.
    static let leftWallX: Float = -RoomBox.half + RoomBox.wallThickness
    /// Inner face of the back wall — the shop front.
    static let backWallZ: Float = -RoomBox.half + RoomBox.wallThickness

    /// Frames stand 8 mm proud of the plaster, which is what gives them a lit
    /// side at this camera. Anything flatter reads as painted on.
    static let frameX: Float = leftWallX + 0.008
    static let backPropZ: Float = backWallZ + 0.008

    // MARK: - The wall of twelve frames

    /// Four columns and three rows, `GAMEPLAY.md` §2's 3×4 grid.
    ///
    /// **Column 0 is the screen-right end.** Worth stating because it is not
    /// obvious and the gold frame depends on it: the left wall runs along z, and
    /// projecting both ends through `CameraRig.eye` puts z = −0.200 at screen
    /// x ≈ −0.01 and z = −0.020 at ≈ −0.12. The far end of the wall is the one
    /// that reads *right*. So §2's "bottom-right frame" is `column 0, row 0`.
    static let columnZ: [Float] = [-0.200, -0.140, -0.080, -0.020]
    /// Bottom row first, so `row 0` is the bottom — the gold frame's row.
    static let rowY: [Float] = [0.120, 0.165, 0.210]

    static let frameSize: Float = 0.040
    static let frameDepth: Float = 0.011
    /// The gold frame is bigger, because §2 asks it to be: *"larger and gold…
    /// it gives the wall a shape and gives the last cake a weight the other
    /// eleven cannot have."*
    static let goldSize: Float = 0.052

    static let frameRadius: Float = 0.023
    static let goldRadius: Float = 0.030

    /// Which slot each friend waits in. **Fixed, and in `Friend.allCases` order**
    /// — the wall is a place she learns, and a friend who moved between sittings
    /// would break the one thing a textless level select has going for it.
    /// Reading order across the wall as she sees it: top row first, screen-right
    /// to screen-left, which is columns ascending.
    static func slot(for friend: Friend) -> (column: Int, row: Int) {
        let index = Friend.allCases.firstIndex(of: friend) ?? 0
        // Row 2 (top) fills first, then row 1, then row 0 — and the gold frame
        // takes row 0 column 0, so the eleven fill around it.
        let order: [(Int, Int)] = [(0, 2), (1, 2), (2, 2), (3, 2),
                                   (0, 1), (1, 1), (2, 1), (3, 1),
                                   (1, 0), (2, 0), (3, 0)]
        return order[min(index, order.count - 1)]
    }

    /// The gold frame's slot — bottom row, screen-right end.
    static let goldSlot = (column: 0, row: 0)

    static func framePosition(column: Int, row: Int) -> SIMD3<Float> {
        SIMD3<Float>(frameX, rowY[row], columnZ[column])
    }

    static func framePosition(for friend: Friend) -> SIMD3<Float> {
        let s = slot(for: friend)
        return framePosition(column: s.column, row: s.row)
    }

    static var goldPosition: SIMD3<Float> {
        framePosition(column: goldSlot.column, row: goldSlot.row)
    }

    /// How much of a frame's inside the photograph fills, and how big the cake
    /// standing in it is. The cake is `CakeGeometry`'s own 52 mm-wide stack, so
    /// it has to come down a long way to sit inside a 40 mm frame.
    static let photoInset: Float = 0.005
    static let photoCakeScale: Float = 0.36
    static let goldCakeScale: Float = 0.47

    // MARK: - The counter

    /// A long low counter under the frames, from `roombox-v2.png`.
    static let counterTopY: Float = 0.058
    static let counterCentre = SIMD2<Float>(-0.183, -0.070)
    static let counterSize = SIMD2<Float>(0.058, 0.250)

    // MARK: - The shop front, on the back wall

    /// The blind: a roll on a bar with a chunky end cap each side, and a straight
    /// cord ending in an 8-sided knob. `references/bakkerij/rolluik.png`.
    static let blindCentreX: Float = -0.080
    static let blindWidth: Float = 0.108
    static let blindRollY: Float = 0.212
    /// How far the cloth reaches when the shop is shut — just under the window's
    /// sill, so it covers the glass and nothing else.
    static let blindShutY: Float = 0.108

    /// The knob at the end of the cord. **This is the drag target for
    /// `opendoen`**, and it hangs clear of the window's own target.
    static let cordKnobHome = SIMD3<Float>(-0.005, 0.104, backPropZ)
    static let cordRadius: Float = 0.026
    /// How far up the knob travels as the blind rolls.
    static let cordTravel: Float = 0.052

    static let windowCentre = SIMD3<Float>(-0.080, 0.152, backPropZ)
    static let windowSize = SIMD2<Float>(0.086, 0.070)
    static let windowRadius: Float = 0.028

    /// The shop door — `references/bakkerij/winkeldeur.png`. **Not
    /// `Props.doorway`**: that prop carries `ROOMS.md` §9's three-cue grammar for
    /// *the way out*, and this door is a step rather than an exit. The room has
    /// two door-shaped things in it and only one of them may ever mean "this is
    /// finished".
    static let shopDoorCentre = SIMD3<Float>(0.108, RoomBox.floorY, backPropZ)
    static let shopDoorOpening = SIMD2<Float>(0.076, 0.132)
    static let shopDoorRadius: Float = 0.040
    /// Where the friend stands once she has let them in — in front of the
    /// counter, facing the open corner.
    static let friendSpot = SIMD3<Float>(-0.104, RoomBox.floorY, -0.086)
    /// And where they come in from, just inside the shop door.
    static let friendEntry = SIMD3<Float>(0.104, RoomBox.floorY, -0.170)

    static let bellCentre = SIMD3<Float>(0.040, 0.176, backPropZ)
    static let bellRadius: Float = 0.024

    /// The sign above the door, which gains a little colour per filled frame.
    /// `GAMEPLAY.md` §2: *"no numbers, no bar, no percentage."*
    static let signCentre = SIMD3<Float>(0.150, 0.206, backPropZ)
    static let signRadius: Float = 0.026
    static let signSize = SIMD2<Float>(0.052, 0.040)

    // MARK: - The order hook, the drawings, and the way out

    /// `GAMEPLAY.md` §6.1 puts the hook *"by the back door"*, and it is the
    /// destination end of `bestellen`'s journey.
    static let hookCentre = SIMD3<Float>(frameX, 0.122, 0.120)
    static let hookRadius: Float = 0.026
    /// Where the card hangs once she has landed it, a little below the hook.
    static let cardHangCentre = SIMD3<Float>(frameX, 0.104, 0.120)
    /// How near the hook the card has to land. Generous, per `CONCEPT.md` §5 —
    /// this is a snap radius, so it is `RoomBox.distanceXZ`'s sibling in a
    /// vertical plane rather than a screen-separation number.
    static let cardSnapRadius: Float = 0.052

    /// Her own drawings, pinned beside the frames. §6.1's fifth toy, and
    /// `CONCEPT.md` §6's personalisation item.
    static let drawingsCentre = SIMD3<Float>(frameX, 0.192, 0.062)
    static let drawingsRadius: Float = 0.024

    /// **The way out, and the same place it is in every other room.**
    /// `Props.doorway`'s own comment: *"the way out being where it was last time
    /// is worth more to a 4-year-old than variety is."*
    static let doorwayCentre = KitchenLayout.doorwayCentre
    static let doorRadius: Float = 0.040

    // MARK: - The toys on the counter

    static let catCentre = SIMD3<Float>(-0.183, 0.071, -0.112)
    static let catRadius: Float = 0.028
    static let radioCentre = SIMD3<Float>(-0.183, 0.073, -0.022)
    static let radioRadius: Float = 0.024

    /// Where Nina stands. **Passed to `BakerCharacter` explicitly** — its default
    /// home is `KitchenLayout.bakerSpot`, and three rooms have already shipped
    /// with her easing back towards the kitchen after a cheer.
    static let bakerSpot = SIMD3<Float>(-0.150, RoomBox.floorY, 0.036)

    /// Where the photograph waits on the return leg, before she hangs it.
    static let photoRest = SIMD3<Float>(-0.176, counterTopY, -0.166)
    static let photoRadius: Float = 0.030

    // MARK: - Surfaces

    /// The counter, and the floor. Short, because **nothing in this room is
    /// carried** — the card and the photograph are dragged in a vertical plane
    /// against a wall, which `CarryController` is the wrong tool for. What this
    /// is for is the halo: `Halo.attach` asks what a prop is standing on, and the
    /// cord knob and the photograph both stand over the counter.
    static let surfaces = Surfaces(
        floorY: RoomBox.floorY,
        rects: [Surfaces.Rect(centre: counterCentre, size: counterSize,
                              y: counterTopY)],
        // No wall shelving in this room. The frames hang on the wall but nothing
        // ever stands on them, and a `Shelf` the halo could find would put a ring
        // up beside the photographs.
        shelves: [],
        solids: [Surfaces.Rect(centre: counterCentre, size: counterSize,
                               y: counterTopY)],
        hider: nil,
        // The room's own furniture: `minX` reaches the counter against the frame
        // wall, `maxX` the shop door's threshold, `minZ` the back wall and `maxZ`
        // the open floor in front of the counter.
        minX: -0.200, maxX: 0.190, minZ: -0.195, maxZ: 0.200,
        lift: RoomBox.carryLift
    )

    // MARK: - The check

    /// **Every pair of targets, against the sum of their radii.**
    ///
    /// Like against like is skipped — the twelve frames are one row of equals and
    /// `ROOMS.md` §5 says that overlap is intended. Everything else has to clear,
    /// and the version of this room that did not is recorded at the top of the
    /// file.
    ///
    /// `@MainActor` because `RoomBox.screenSeparation` reads `CameraRig.eye`. Its
    /// one caller is `BakkerijRoom.build`, already on the main actor. **This is
    /// the annotation the second build caught missing on `VersierLayout` —** if
    /// it is dropped, this file stops compiling rather than stops checking.
    @MainActor
    static func assertSpacing() {
        #if DEBUG
        var frames: [(String, SIMD3<Float>, Float)] = []
        for friend in Friend.allCases {
            frames.append(("lijst-\(friend.rawValue)", framePosition(for: friend),
                           frameRadius))
        }
        frames.append(("lijst-goud", goldPosition, goldRadius))

        let others: [(String, SIMD3<Float>, Float)] = [
            ("koord", cordKnobHome, cordRadius),
            ("raam", windowCentre, windowRadius),
            ("winkeldeur", SIMD3<Float>(shopDoorCentre.x,
                                        shopDoorCentre.y + shopDoorOpening.y / 2,
                                        shopDoorCentre.z), shopDoorRadius),
            ("bel", bellCentre, bellRadius),
            ("uithangbord", signCentre, signRadius),
            ("poes", catCentre, catRadius),
            ("radio", radioCentre, radioRadius),
            ("haak", hookCentre, hookRadius),
            ("tekeningen", drawingsCentre, drawingsRadius),
            ("deur", SIMD3<Float>(doorwayCentre.x, doorwayCentre.y + 0.056,
                                  doorwayCentre.z), doorRadius),
        ]

        let all = frames + others
        for i in all.indices {
            for j in (i + 1)..<all.count {
                let (an, ap, ar) = all[i]
                let (bn, bp, br) = all[j]
                // Frame against frame: sanctioned overlap, see above.
                if an.hasPrefix("lijst") && bn.hasPrefix("lijst") { continue }
                let d = RoomBox.screenSeparation(ap, bp)
                assert(d >= ar + br - 1e-4,
                       "BakkerijLayout: \(an) and \(bn) are \(Int(d * 1000)) mm apart as "
                       + "the camera sees them but need \(Int((ar + br) * 1000)) mm — "
                       + "whichever one the tie-break prefers is the one she gets.")
            }
        }

        // And the frames must not overlap each other *as geometry*, which is a
        // different question from whether they can be told apart by a finger.
        let columnGap = columnZ[1] - columnZ[0]
        let rowGap = rowY[1] - rowY[0]
        assert(columnGap > goldSize, "BakkerijLayout: the gold frame is wider than "
               + "the column pitch and would overlap its neighbour.")
        assert(rowGap > goldSize, "BakkerijLayout: the gold frame is taller than the "
               + "row pitch.")
        assert(rowY[rowY.count - 1] + goldSize / 2 < RoomBox.wallHeight,
               "BakkerijLayout: the top row reaches above the wall.")
        #endif
    }
}
