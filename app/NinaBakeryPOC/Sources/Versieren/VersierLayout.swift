import simd

/// **Where everything in the decorating room is.**
///
/// One table of numbers rather than magic constants spread across the room and
/// the props, for the reason `KitchenLayout` opens with: almost every bug in a
/// room like this is two files disagreeing about where a surface is.
///
/// The box and the camera are `RoomBox` and `CameraRig`, untouched. `ROOMS.md`
/// §0 is explicit that a room seen from a different chair is a different game
/// with the same palette — so **no touch radius in here needs rescaling**, and
/// every one of them can be read straight against the kitchen's.
enum VersierLayout {

    // MARK: - The turntable, and the cake on it

    /// The turntable stands in the middle, and everything polar is measured from
    /// its axis. Slightly back of centre so the trays along the two open edges
    /// have floor in front of them.
    static let turntableCentre = SIMD2<Float>(-0.010, -0.030)

    /// Top of the pedestal's plate — what the cake stands on.
    static let plateY: Float = 0.062
    static let plateRadius: Float = 0.082
    static let plateThickness: Float = 0.008
    static let pedestalRadius: Float = 0.030
    static let pedestalTopRadius: Float = 0.022

    /// The handle that turns it, off the rim towards the camera.
    static let handleLength: Float = 0.034
    static let handleAngle: Float = .pi / 4   // out along the +X+Z diagonal, towards the eye

    /// **How much bigger the cake is here than everywhere else, and why.**
    ///
    /// `CakeGeometry` is 52 mm across and 33 mm tall. At the committed camera
    /// one point is about 0.63 mm of world, so that cake is **about 82 pt wide
    /// on screen** — fine for a prop she carries across a kitchen, and hopeless
    /// as a canvas she has to place a dozen distinct things on, let alone forty.
    ///
    /// At 2.5× it is 130 mm across (≈ 205 pt) and 82 mm tall, standing on a
    /// plate at y = 0.062 so its top reaches about 0.144 against a 0.235 wall.
    /// That is a bit over a quarter of the room's width, which is right: in this
    /// room the cake *is* the room, and `references/plates/07-decorating-roombox-v2.png`
    /// frames it exactly that way.
    ///
    /// It is a scale on the cake's wrapper rather than a second geometry, so
    /// `CakeSpec` stays the single description of the cake — the same trick
    /// `isTall` already uses.
    static let cakeScale: Float = 2.5

    /// **Where the sticker layer hangs, and why it is not under the stretch.**
    ///
    /// `CakeSpec.isTall` scales the cake wrapper by 1.5 in Y. A sticker parented
    /// under that comes out as a stretched heart. The sticker layer is therefore
    /// a *sibling* of the cake under the turntable node, and `CakeSurface`
    /// resolves `u` against the already-stretched tier heights — so the sticker
    /// lands in the right place and keeps its own shape.
    static var cakeBaseY: Float { plateY }

    // MARK: - The trays
    //
    // **Seven trays is the room's one real crowding problem, and the L is the
    // answer to it.**
    //
    // At the committed camera one point is ≈ 0.63 mm of world. The kitchen's
    // ingredient tokens carry a 0.032 m radius — a 101 pt hit diameter — and
    // that is the practical precedent for `CONCEPT.md` §5's "~120 pt". Two such
    // spheres need 64 mm centres not to overlap, and `TouchRouter` picks the
    // *nearest* centre, so overlapping means the tie-break decides which tray
    // she got. That is exactly the bug the kitchen's counter toys had at 50 mm
    // centres.
    //
    // Seven in one row needs 384 mm of a 460 mm room, which does not fit beside
    // anything else. The box is open on its **+X and +Z sides**, which meet at
    // the near corner — so the trays wrap that corner in two runs of four and
    // three, needing 192 mm and 128 mm. Both fit with room to spare, and it is
    // also what `references/plates/07-decorating-roombox-v2.png` shows.
    //
    // Being handed the wrong tray is, uniquely in this game, free: §6.4 says
    // there is no grid, no snapping and no correct answer, so a mis-grab gives
    // her a different sticker rather than a failure. The trays may be the most
    // forgiving targets in the room rather than the tightest.

    static let trayRadius: Float = 0.032
    static let traySize = SIMD2<Float>(0.042, 0.034)
    static let trayHeight: Float = 0.010
    /// Top face of a tray — where its stack of stickers stands.
    static var trayTopY: Float { RoomBox.floorY + trayHeight }

    /// The seven, in the order they stand: four along the +Z edge, left to
    /// right, then three up the +X edge, near to far.
    static let trayOrder: [StickerKind] = [
        .sprinkel, .hartje, .sterretje, .kaarsje,   // ledge A, along +Z
        .kroontje, .fruitje, .roomtoefje,           // ledge B, along +X
    ]

    /// 64 mm centres, which is the non-overlap distance for a 32 mm radius.
    private static let trayPitch: Float = 0.064

    static func traySpot(_ index: Int) -> SIMD3<Float> {
        let ledgeAZ: Float = 0.170     // the +Z run, in front of the turntable
        let ledgeBX: Float = 0.170     // the +X run, to its right
        if index < 4 {
            let x = -0.116 + Float(index) * trayPitch
            return SIMD3<Float>(x, RoomBox.floorY, ledgeAZ)
        }
        let z = 0.086 - Float(index - 4) * trayPitch
        return SIMD3<Float>(ledgeBX, RoomBox.floorY, z)
    }

    static func traySpot(for kind: StickerKind) -> SIMD3<Float> {
        traySpot(trayOrder.firstIndex(of: kind) ?? 0)
    }

    // MARK: - The two tools
    //
    // Not trays, and placed so they do not read as one: each sits at the far end
    // of its own ledge, past the last tray, with the pitch between them.

    /// **70 mm from the nearest tray, not 64.** The trays carry a 32 mm radius
    /// and the tools a 34 mm one, so the pair needs 66 mm and the tray pitch
    /// alone would have left them overlapping by two millimetres — which
    /// `TouchRouter`'s nearest-centre tie-break would then have resolved
    /// silently, and in a way that changed with the angle she came in from.
    /// Checked by `assertSpacing`, because two millimetres is not a thing anyone
    /// sees in a screenshot.
    static let spuitzakSpot = SIMD3<Float>(-0.186, RoomBox.floorY, 0.170)
    static let strooibusSpot = SIMD3<Float>(0.170, RoomBox.floorY, -0.112)
    static let toolRadius: Float = 0.034

    // MARK: - Toys

    static let counterTopY: Float = 0.058
    static let counterCentre = SIMD2<Float>(-0.100, -0.184)
    static let counterSize = SIMD2<Float>(0.220, 0.060)

    static let glitterpotSpot = SIMD3<Float>(-0.176, counterTopY, -0.184)
    static let taartbordenSpot = SIMD3<Float>(-0.106, counterTopY, -0.180)
    static let kwastjeSpot = SIMD3<Float>(-0.036, counterTopY, -0.180)
    static let krukjeSpot = SIMD3<Float>(0.096, RoomBox.floorY, 0.052)

    /// The wall shelf of sprinkle jars, on the left wall.
    static let shelfDepth: Float = 0.036
    static var shelfX: Float { -RoomBox.half + RoomBox.wallThickness + shelfDepth / 2 }
    static let shelfHeight: Float = 0.140
    static var shelfTopY: Float { shelfHeight + 0.004 }
    static let shelfCentreZ: Float = -0.060
    static let shelfLength: Float = 0.140

    // MARK: - Nina, and the way out

    /// Behind the turntable and left of its axis, so she does not stand between
    /// the camera and the cake — the same sightline reasoning that moved her in
    /// the kitchen.
    static let bakerSpot = SIMD3<Float>(-0.150, RoomBox.floorY, -0.116)

    /// **The same door as the kitchen's, in the same place**, because it is the
    /// same door — she walks through one and arrives at the other, and a way out
    /// that moved between rooms would be a different object.
    static var doorwayCentre: SIMD3<Float> { KitchenLayout.doorwayCentre }
    static var doorHaloSpot: SIMD3<Float> { KitchenLayout.doorHaloSpot }
    static var doorHaloRadius: Float { KitchenLayout.doorHaloRadius }

    // MARK: - Tolerances
    //
    // All written in points and converted by `TouchRouter.radius(points:)` at
    // the call site, because they are world-space spheres satisfying a rule
    // about the *screen*.

    /// How far outside the cake a drop still lands on it. About a finger-width.
    static let stickerSlopPoints: CGFloat = 40
    /// How far outside the cake she has to let go for it to count as *taking a
    /// sticker off* rather than nudging one. Much larger, because the same
    /// gesture does both and only one of them can be wrong.
    static let removeSlopPoints: CGFloat = 90
    /// Placed stickers share one generous radius. Nearest-centre-wins picks one;
    /// any sticker wiggling is the response she wanted, so there is no wrong one.
    static let stickerTapPoints: CGFloat = 44

    // MARK: - The piping bag

    /// A new stroke point every 3 mm of surface arc — about 4.7 pt on screen.
    /// A two-second sweep across the cake front emits about thirty points, not
    /// four hundred.
    static let strokeStep: Float = 0.003
    /// If one frame travels further than this she flicked; the gap is filled by
    /// interpolating **in polar**, because lerping world XYZ chords straight
    /// through the cake.
    static let strokeMaxStep: Float = 0.012
    /// **A bag-full, in metres of surface arc** — about twice round the bottom
    /// tier. It refills itself when she lets go; see `VersierRoom.pipeEnded`.
    static let pipingCapacity: Float = 0.90
    /// Below this fraction the ribbon starts to thin, so the ending is legible
    /// in the drawing itself rather than arriving as a stop.
    static let pipingThinsBelow: Float = 0.15

    /// **The one silent cap in the room**, and it is honest: 120 grains already
    /// cover the cake, so removing the oldest is invisible — and it can never
    /// put Pip's wish of eight sprinkles out of reach.
    static let maxSprinkles = 120
    static let maxStrokes = 40

    // MARK: - The check that keeps the arithmetic honest

    /// **Every pair of floor targets is at least the sum of their radii apart.**
    ///
    /// `TouchRouter` picks the nearest centre, so two overlapping spheres do not
    /// fail loudly — they hand her whichever one the tie-break preferred, and
    /// which that is changes with the angle she reaches in from. The kitchen's
    /// three counter toys shipped like that at 50 mm centres and it was found by
    /// reading the numbers, not by looking at the room.
    ///
    /// Called from `VersierRoom.build` in debug builds. It is an assertion
    /// rather than a test because there is no test target in this project yet,
    /// and a number that has to hold is better checked by the app that depends
    /// on it than not checked at all.
    static func assertSpacing() {
        #if DEBUG
        var spots: [(String, SIMD3<Float>, Float)] = []
        for (i, kind) in trayOrder.enumerated() {
            spots.append((kind.rawValue, traySpot(i), trayRadius))
        }
        spots.append(("spuitzak", spuitzakSpot, toolRadius))
        spots.append(("strooibus", strooibusSpot, toolRadius))
        spots.append(("krukje", krukjeSpot, 0.034))

        for i in spots.indices {
            for j in (i + 1)..<spots.count {
                let (an, ap, ar) = spots[i]
                let (bn, bp, br) = spots[j]
                let d = RoomBox.distanceXZ(ap, bp)
                assert(d >= ar + br - 1e-4,
                       "VersierLayout: \(an) and \(bn) are \(Int(d * 1000)) mm apart "
                       + "but need \(Int((ar + br) * 1000)) mm — their touch spheres overlap.")
            }
        }
        #endif
    }
}
