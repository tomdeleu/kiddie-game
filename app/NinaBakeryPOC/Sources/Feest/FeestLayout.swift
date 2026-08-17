import CoreGraphics
import simd

/// **Where everything in the disco is.**
///
/// One table of numbers, for the reason `KitchenLayout` opens with: almost every
/// bug in a room like this is two files disagreeing about where a surface is.
///
/// The box and the camera are `RoomBox` and `CameraRig`, untouched — `ROOMS.md`
/// §0 makes that a rule, so **no touch radius in here needs rescaling** and
/// every one of them reads straight against the kitchen's.
///
/// ## The one layout idea in this room: build along the diagonal
///
/// `ROOMS.md` §5 and `RoomBox.screenSeparation` between them say the thing that
/// decides this room's shape: **`TouchRouter` measures distance perpendicular to
/// the camera ray**, and this eye stands at 45° to both floor axes — so a row
/// laid along X or along Z keeps only about **0.80** of its spacing, while a row
/// along the **X−Z diagonal** is exactly screen-horizontal and keeps **1.000**
/// of it.
///
/// Versieren was built before that was known and does not pass its own check:
/// seven trays at a 64 mm pitch along an axis are 47–51 mm apart on screen. This
/// room is the first laid out *knowing* it, so **the six pads and both rows of
/// guests run along the diagonal**, and `assertSpacing` below asserts on the
/// screen distance rather than warning about it.
///
/// It is also what set the counts. Six pads on the diagonal is the most that
/// fits at a radius `CONCEPT.md` §5 can live with; six guests plus a DJ is what
/// the floor holds with air around each. `GAMEPLAY.md` §6.5 used to ask for up
/// to twelve guests and the rig was never what stopped it — this was.
enum FeestLayout {

    // MARK: - The diagonal basis
    //
    // `along` is screen-horizontal at this camera and keeps all of its spacing.
    // `back` runs into the screen and keeps about 0.55 of it, because the camera
    // looks down at ~34° so walking away from it is also walking up the screen.
    // Every row in this room is written in these two rather than in x and z.

    static let along = SIMD2<Float>(0.7071, -0.7071)
    static let back = SIMD2<Float>(-0.7071, -0.7071)

    static func spot(from centre: SIMD2<Float>, along a: Float, back b: Float) -> SIMD2<Float> {
        centre + along * a + back * b
    }

    // MARK: - The dance floor

    /// The middle of the lit floor, and the point the ball hangs over, the lamps
    /// aim at, and the guests stand around.
    static let floorCentre = SIMD2<Float>(0.020, -0.030)

    /// **The lit floor runs nearly wall to wall, and the room box plate is why.**
    ///
    /// It was built 4×4 and 137 mm across, centred on the dance area — a lit rug
    /// in the middle of a 460 mm room. `references/feest/roombox.png` is
    /// emphatic that this is wrong: in the plate the tiles cover the floor from
    /// the back corner to the near edges with a narrow border of plain floor
    /// left, and **that is what makes the picture read as a disco at all.** A
    /// small square of light in the middle of a cream floor reads as a rug.
    ///
    /// **The room box overruled the studio plate**, which is the same thing that
    /// happened three times in the garden (`references/garden/README.md`).
    /// `references/feest/dansvloer.png` was asked for a 4×4 grid and delivered
    /// four thick slabs — useful for what a tile is *made of*, useless for how
    /// many there are, and it is the shot with the whole room in it that knows
    /// the answer to that.
    ///
    /// 6×6 at a 62 mm pitch spans 369 mm — four fifths of the room — leaving
    /// 33 mm of plain floor against the walls and 16 mm at the open edges. **The
    /// border is deliberate and it is not just margin**: the two end pads reach
    /// x = 0.228 and would otherwise straddle the last tile's edge, and a button
    /// half on a lit tile and half off it looks like a mistake rather than like a
    /// button. The tiles are not targets, props stand on them, and 36 materials
    /// repainted twice a second is the same order of work sixteen were.
    static let tilesPerSide = 6
    static let tileSize: Float = 0.059
    static let tileGap: Float = 0.003
    static var tilePitch: Float { tileSize + tileGap }
    /// Thin, and lying on the floor rather than sunk into it: a tile flush with
    /// the floor z-fights, and one any thicker reads as a step she would trip on.
    static let tileThickness: Float = 0.0028
    static var tileTopY: Float { RoomBox.floorY + tileThickness }
    static var danceFloorSize: Float { Float(tilesPerSide) * tilePitch - tileGap }

    /// **The grid is centred on the room, not on the dance area.** They are two
    /// different points and conflating them is what put the lit floor off-centre
    /// enough to read as a rug that had slipped. `floorCentre` is where the
    /// *dancing* happens — the ball hangs over it, the lamps aim at it, the
    /// guests stand round it — and it is deliberately back and right of the
    /// middle so the cake has the near-left corner. The tiles are architecture
    /// and belong to the room.
    static let tileGridCentre = SIMD2<Float>(0, 0)

    static func tileSpot(_ row: Int, _ column: Int) -> SIMD3<Float> {
        let half = (Float(tilesPerSide) - 1) / 2
        return SIMD3<Float>(tileGridCentre.x + (Float(column) - half) * tilePitch,
                            RoomBox.floorY,
                            tileGridCentre.y + (Float(row) - half) * tilePitch)
    }

    // MARK: - The six pads
    //
    // **On the diagonal, at the largest pitch the floor allows.** The row is
    // centred near the open corner and runs along `along`; the limit is the
    // floor's own edge, which caps the pitch at 65 mm for six of them — the two
    // end pads clear it by a tenth of a millimetre. Each pad gets a 32 mm radius,
    // a **101 pt** hit diameter at this camera, which is exactly the kitchen's
    // ingredient tokens and the practical precedent for `CONCEPT.md` §5's
    // "~120 pt".
    //
    // **65 mm, not the 64 the sum says.** Two 32 mm radii need 64 mm of screen
    // separation, and the diagonal was supposed to deliver all of it — but
    // `RoomBox.screenSeparation` takes its view direction through the *midpoint
    // of the pair*, not through the room's origin, so a row on the diagonal is
    // exactly screen-horizontal only where it crosses the middle of the room. At
    // the ends of this one it is a degree or so off and keeps 63.4 mm of a 64 mm
    // pitch. The extra millimetre is what pays for that, and it is precisely the
    // sort of thing `assertSpacing` exists to have caught before the room shipped
    // rather than after.
    //
    // Being handed the wrong pad is, uniquely in this game, *free*: every pad is
    // equally right and a wrong one plays a different instrument, which is not a
    // failure in a room with no required action. So these could have been the
    // most forgiving targets in the game rather than the tightest — they are the
    // tightest anyway, because the diagonal made it cost nothing.

    static let padCount = 6
    static let padRowCentre = SIMD2<Float>(0.095, 0.095)
    static let padPitch: Float = 0.065
    static let padRadius: Float = 0.032
    /// The prop, not the target: a squat cylinder she can see her finger land on.
    static let padGeometryRadius: Float = 0.020
    static let padHeight: Float = 0.011
    static var padTopY: Float { RoomBox.floorY + padHeight }

    static func padSpot(_ index: Int) -> SIMD3<Float> {
        let offset = (Float(index) - (Float(padCount) - 1) / 2) * padPitch
        let p = spot(from: padRowCentre, along: offset, back: 0)
        return SIMD3<Float>(p.x, RoomBox.floorY, p.y)
    }

    // MARK: - The guests
    //
    // **Two short rows, both on the diagonal**, the back one offset half a pitch
    // so no guest stands directly behind another. The front row is nearer the
    // camera than the floor centre and the back row further from it, which is
    // what makes the group read as a ring around the dance floor rather than as
    // a queue.
    //
    // The worst pair is a front-to-back diagonal neighbour at **67 mm** of screen
    // separation, against the 64 mm two 32 mm radii need. Within a row it is the
    // full 84 mm.
    //
    // **The back row is 82 mm behind rather than beside**, and that only buys
    // 45 mm: a gap along the view direction keeps about 0.55 of its length,
    // because the camera looks down at ~34° so walking away from it is also
    // walking up the screen. The separation that actually holds these two rows
    // apart is the half-pitch diagonal offset; the depth is scenery.

    static let guestCount = 6
    static let guestRadius: Float = 0.032
    /// The target hangs on a marker at chest height rather than on the character
    /// root, which stands on the floor. A 4-year-old aims at the middle of a
    /// person — the same fix the kitchen's doorway needed once it stopped being
    /// a toy.
    static let guestTouchY: Float = 0.060

    static func guestSpot(_ index: Int) -> SIMD3<Float> {
        // Front row of three, then back row of three.
        let front = index < 3
        let a: Float = front
            ? [-0.084, 0.000, 0.084][index]
            : [-0.126, -0.042, 0.042][index - 3]
        let b: Float = front ? -0.030 : 0.082
        let p = spot(from: floorCentre, along: a, back: b)
        return SIMD3<Float>(p.x, RoomBox.floorY, p.y)
    }

    // MARK: - The DJ, and his booth
    //
    // **They share one target, and that is `ROOMS.md` §5 rather than a shortcut.**
    // The DJ stands directly behind his booth, so at this fixed camera the two
    // are the same point on screen: a booth target and a DJ target 30 mm apart
    // would need 64 mm between them and would hand her whichever one the
    // nearest-centre tie-break preferred. §5's answer to a prop covered by what
    // stands on it is to fold its word into the thing under her finger, at the
    // flour sack's ratio — so tapping the DJ mostly says *the DJ* and now and
    // then says *the decks*.

    /// **Pulled 30 mm forward when the guests got chubby**, and it is a good
    /// illustration of a footprint being a fact about the props rather than about
    /// the plan. The blocky first pass was a 30 mm-wide box, so a DJ fitted
    /// comfortably in the 24 mm between the booth's back and the plaster. A
    /// `beertjes.png` body is **62 mm wide**, and he did not — his back would have
    /// been 9 mm inside the wall, which at this camera is a bear with a slice
    /// missing.
    ///
    /// The booth came forward instead of the DJ, because the DJ has nowhere to
    /// go: he has to be against the wall for the room to have any depth behind
    /// him. Their footprints now overlap by 10 mm, which is not a collision — it
    /// is a DJ standing *at* his decks rather than behind them.
    static let boothCentre = SIMD2<Float>(0.100, -0.140)
    static let boothSize = SIMD2<Float>(0.110, 0.048)
    static let boothTopY: Float = 0.070
    /// The two platters on the top, off the centre line either way.
    static let deckOffset: Float = 0.030
    static let deckRadius: Float = 0.017

    /// As far back as a 62 mm-wide body goes: his back lands at z = −0.216
    /// against a wall face at −0.218.
    static let djSpot = SIMD3<Float>(0.100, RoomBox.floorY, -0.185)
    /// Generous, and deliberately covering the booth as well as its DJ.
    static let djRadius: Float = 0.045
    static let djTouchY: Float = 0.075

    // MARK: - The mirror ball
    //
    // **It hangs on a cord that leaves the top of the frame**, which is what
    // `references/feest/roombox.png` came back with and what the room box rule
    // requires anyway: `references/REFERENCES.md` §1 gives a room two walls and a
    // floor and no ceiling, so a truss to hang it from would be a surface between
    // the camera and the room. The cord simply runs up past the wall tops into
    // the same grey backdrop the garden's fence shows.

    /// **60 mm across, which is bigger than it sounds and is what the plate
    /// shows.** It started at 44 mm — a sensible size for a prop, and about a
    /// tenth of the room. In `references/feest/roombox.png` the ball is nearer a
    /// quarter of the room's width and it is the first thing the eye lands on,
    /// which is right: it is the object that says *disco* before anything has
    /// moved. Otto's dome is 124 mm across, so this is still a small prop by the
    /// standards of the game.
    static let ballCentre = SIMD3<Float>(0.020, 0.180, -0.030)
    static let ballRadius: Float = 0.030
    static let ballTouchRadius: Float = 0.036
    /// **Where the cord stops being drawn, and it has to be off the top of the
    /// screen rather than merely above the wall.**
    ///
    /// It was 0.252 — 17 mm clear of the wall tops, which sounds like enough and
    /// is not: at this eye and a 26° vertical FOV, a point over the ball only
    /// leaves the top of the frame at **y = 0.308**. So the cord ended 56 mm
    /// inside the shot, in mid-air, and the ball read as floating (owner,
    /// 2026-08-17: *"the cord seems to float mid-air. it should come from very
    /// high so you don't see the end."*).
    ///
    /// 0.45 is far past the 0.308 the arithmetic gives, and the margin is the
    /// point: the frame edge moves with the viewport aspect, and a cord that is
    /// merely *just* out of shot is one iPad away from being back in it. It costs
    /// one long thin box over the grey backdrop.
    static let cordTopY: Float = 0.45

    /// **The spots it throws.** Eight small pools of light circling on the floor,
    /// which is the one thing a mirror ball is *for* and the reason the ball
    /// itself can be a plain faceted sphere. They turn on the beat.
    static let ballSpotCount = 8
    static let ballSpotOrbit: Float = 0.135
    static let ballSpotRadius: Float = 0.016

    // MARK: - The light rig

    /// Two bars of lamps, one on each wall, high up and aimed at the floor.
    /// Three on the back wall and two on the left, because the back wall is the
    /// one the camera sees most of.
    static let backBarY: Float = 0.190
    static var backBarZ: Float { -RoomBox.half + RoomBox.wallThickness + 0.012 }
    static var leftBarX: Float { -RoomBox.half + RoomBox.wallThickness + 0.012 }
    static let backLampX: [Float] = [-0.110, 0.000, 0.110]
    static let leftLampZ: [Float] = [-0.090, 0.010]

    /// One target for the whole rig, on the middle lamp of the back bar. Five
    /// lamps mean five words for one thing, and they are 110 mm apart on a wall
    /// nobody needs to aim at precisely.
    static var lampTouchSpot: SIMD3<Float> {
        SIMD3<Float>(0, backBarY, backBarZ)
    }
    static let lampRadius: Float = 0.030

    /// The beam's two radii — at the lens and at the pool it makes on the floor.
    /// **Its length is not here**: `FeestProps.lamp` derives it from how far that
    /// lamp actually is from what it is aimed at, because the five of them are
    /// 251 mm and 294 mm away and one constant was wrong for all of them.
    ///
    /// It is a `Palette.lightMaterial` cone — the halo's material, not the water
    /// exception in `Palette.waterMaterial`. A beam is a light, not a second
    /// licence to use transparency.
    static let beamTopRadius: Float = 0.008
    static let beamBottomRadius: Float = 0.032

    // MARK: - The cake, on its table
    //
    // **The cake is the way out of this room** (`GAMEPLAY.md` §6.5, `ROOMS.md`
    // §9), so it is placed the way a door is placed: clear of everything, easy to
    // aim at, and impossible to hit by accident while reaching for something
    // else. It sits front-left, on the far side of the room from the DJ, with
    // 85 mm of screen between it and the nearest guest.

    static let tableCentre = SIMD2<Float>(-0.148, 0.086)
    static let tableTopY: Float = 0.072
    static let tableRadius: Float = 0.042
    static let tableTopThickness: Float = 0.006
    static let tableFootRadius: Float = 0.026
    static let tableStemRadius: Float = 0.012

    /// **1.8×, between the kitchen's 1.0 and the decorating room's 2.5.**
    ///
    /// In the kitchen a cake is a prop she carries; in Versieren it is the canvas
    /// and it is the room. Here it is the centrepiece *and* the exit, so it has
    /// to read across the room and be easy to hit, but it must not tower over the
    /// guests standing next to it — at 1.8 it is 94 mm across against a guest
    /// 125 mm tall, which is a cake on a table at a party.
    static let cakeScale: Float = 1.8

    /// The target hangs on a marker at the middle of the cake rather than on its
    /// base, for the doorway's reason: a sphere on an origin that sits on the
    /// table covers the plate and not the cake.
    static var cakeTouchSpot: SIMD3<Float> {
        SIMD3<Float>(tableCentre.x, tableTopY + 0.030, tableCentre.y)
    }
    static let cakeRadius: Float = 0.040
    /// The halo under the cake — on the table top, not the floor. It is the one
    /// cue in the room and it is on from the first frame.
    static let cakeHaloRadius: Float = 0.046

    // MARK: - Toys

    /// **In the back-right corner, beside the booth — and it took three goes to
    /// find that out.**
    ///
    /// It started on the *left* of the booth, at (−0.070, −0.190), which looks
    /// obviously fine on a floor plan: 60 mm of clear ground to the nearest
    /// guest. On screen it was **23 mm** from that guest, because the gap between
    /// them ran almost exactly along the view direction — the speaker was
    /// standing directly behind her. Two more positions on the left wall failed
    /// the same way against a different guest, or landed under the mirror ball.
    ///
    /// It is the sharpest illustration in the project of `ROOMS.md` §5's rule,
    /// and of why this room asserts rather than warns: **a distance on the floor
    /// says nothing about a distance on the screen**, and the failure mode is not
    /// a prop that looks wrong, it is a tap that goes to the wrong thing.
    static let speakerSpot = SIMD3<Float>(0.196, RoomBox.floorY, -0.190)

    /// **The other corner, and it deliberately has no target of its own.**
    ///
    /// Owner's call, 2026-08-17: *"you should have a second speaker in the other
    /// corner of the room."* A stereo pair is obviously right — one stack either
    /// side of the DJ is what a disco looks like, and the room had a lopsided
    /// single.
    ///
    /// Every position in this corner fails the screen check against the **mirror
    /// ball**, by a lot: 31–45 mm where two radii need 64. The ball hangs at
    /// y = 0.180 over the middle of the floor and the back-left floor corner sits
    /// almost exactly behind it along the view direction, so they are the same
    /// point on screen however the speaker is nudged. Making the ball's target
    /// smaller to fit is the wrong trade — it is a toy she has to be able to hit.
    ///
    /// So this one is **scenery**, and that is `ROOMS.md` §5's sanctioned case
    /// rather than a concession: a prop that cannot have a target because
    /// something else covers it on screen folds its behaviour into the tap that
    /// *does* land. Tapping the right-hand stack thumps **both** — which is what
    /// a pair of speakers does anyway, and it means nothing is lost by the one on
    /// the left being untappable.
    static let speakerSpotFar = SIMD3<Float>(-0.190, RoomBox.floorY, -0.190)
    static let speakerRadius: Float = 0.028
    static let speakerTouchY: Float = 0.030

    static let popperSpot = SIMD3<Float>(-0.196, RoomBox.floorY, 0.132)
    static let popperRadius: Float = 0.026
    static let popperTouchY: Float = 0.020

    /// The balloon floats, so its target tracks the entity rather than a spot.
    /// This is only where it starts and where it comes home to.
    static let balloonHome = SIMD3<Float>(-0.150, 0.150, -0.120)
    static let balloonRadius: Float = 0.026

    // MARK: - Nina

    /// Behind and left of her own cake, so she is beside it without standing
    /// between it and the camera — the same sightline reasoning that placed her
    /// in the other three rooms.
    static let bakerSpot = SIMD3<Float>(-0.196, RoomBox.floorY, 0.030)

    // MARK: - Colour
    //
    // **Six colours, and the pads, the floor and the lamps all use the same
    // six.** That is what ties the room together: tapping the third pad flashes
    // the floor in the third colour, so the connection between her finger and the
    // room is visible rather than merely audible.
    //
    // Every one of them is already in the game — the locked thirteen plus the
    // three the kitchen derived. Nothing was added for the disco, because the
    // disco is made of *emission* rather than of new pigment (`GAMEPLAY.md`
    // §6.5).

    static let discoColours: [UIColorLike] = [
        Palette.blushPink,
        Palette.mint,
        Palette.butterYellow,
        Palette.berryBlue,
        Palette.lilac,
        Palette.sage,
    ]

    /// **What a tile is painted while it is lit, and it is not the pale set.**
    ///
    /// The floor came out *white* (owner, 2026-08-17: *"it just looks very bright
    /// and white"*), and the cause is arithmetic rather than taste. A lit tile was
    /// `glowMaterial(pastel, intensity: 2.34)`, and an emissive surface that far
    /// above white has lost its own hue by the time it is tonemapped — so six
    /// different pastels all came back the same colour, which is no colour.
    ///
    /// Two changes together fix it, and neither alone would. The **intensity
    /// comes right down** (`FeestProps.floorGlow`), and the tile lights in a
    /// **deep** colour rather than a pale one, so there is chroma left to survive
    /// the exposure. It is the halo's lesson read backwards: the halo wanted to
    /// go above white and be seen against cream, and this wants to stay below it
    /// and be seen *as a colour*.
    static let floorLitColours: [UIColorLike] = [
        Palette.blushPinkDeep,
        Palette.sageDeep,
        Palette.berryBlueDeep,
        Palette.lilacDeep,
        Palette.honeyAmber,
        Palette.rose,
    ]

    static func discoColour(_ index: Int) -> UIColorLike {
        discoColours[((index % discoColours.count) + discoColours.count) % discoColours.count]
    }

    /// **A tile's own colour, and the reason it is not `row * side + column`.**
    ///
    /// The obvious index is the flat one, and with six colours on a six-wide grid
    /// it puts the same colour down every column — six vertical stripes, which is
    /// a barcode rather than a dance floor. `row * 2 + column` shears the pattern
    /// into a shallow diagonal that only repeats every third row, which is what
    /// `references/feest/roombox.png` looks like.
    ///
    /// It lives here rather than at the two call sites because the builder and
    /// the beat's repaint both need it and **a tile that changes colour when it
    /// lights up is a tile that looks broken.**
    static func tileColour(row: Int, column: Int) -> UIColorLike {
        discoColour(row * 2 + column)
    }

    // MARK: - The check that keeps the arithmetic honest

    /// **Every pair of targets is at least the sum of their radii apart, as the
    /// camera sees them.**
    ///
    /// `VersierLayout.assertSpacing` measures XZ and only *warns* about the
    /// screen distance, because that room was already built and on device when
    /// the measurement was understood. This room was laid out knowing it, so
    /// here the screen distance is the assertion and XZ is not measured at all —
    /// XZ was never the question. `ROOMS.md` §5: *do not let a new room ship in
    /// that state; it is far cheaper before the props are placed than after.*
    ///
    /// One pair is deliberately absent and it is `ROOMS.md` §5's sanctioned case
    /// rather than an oversight: the **DJ and his booth** share one target,
    /// because a prop entirely covered by what stands on it cannot have its own.
    ///
    /// **The balloon is checked at its home only**, which is the honest amount of
    /// checking a moving target can have. `FeestRoom.floatBalloon` bounds its
    /// drift to about 40 mm and decays it back, and it drifts in the back-left
    /// air where nothing else is — so the home is representative rather than
    /// merely convenient. If it ever grows a bigger drift, this check stops
    /// meaning anything and the bound is what has to be argued for.
    ///
    /// `@MainActor` because `RoomBox.screenSeparation` reads `CameraRig.eye`. Its
    /// one caller is `FeestRoom.build`, already on the main actor.
    @MainActor
    static func assertSpacing() {
        #if DEBUG
        var spots: [(String, SIMD3<Float>, Float)] = []
        for i in 0..<padCount {
            var p = padSpot(i)
            p.y = padTopY
            spots.append(("pad\(i)", p, padRadius))
        }
        for i in 0..<guestCount {
            var p = guestSpot(i)
            p.y = guestTouchY
            spots.append(("gast\(i)", p, guestRadius))
        }
        spots.append(("dj", SIMD3<Float>(djSpot.x, djTouchY, djSpot.z), djRadius))
        spots.append(("taart", cakeTouchSpot, cakeRadius))
        spots.append(("discobal", ballCentre, ballTouchRadius))
        spots.append(("lampen", lampTouchSpot, lampRadius))
        spots.append(("boxen", SIMD3<Float>(speakerSpot.x, speakerTouchY, speakerSpot.z),
                      speakerRadius))
        spots.append(("knaller", SIMD3<Float>(popperSpot.x, popperTouchY, popperSpot.z),
                      popperRadius))
        spots.append(("ballon", balloonHome, balloonRadius))

        for i in spots.indices {
            for j in (i + 1)..<spots.count {
                let (an, ap, ar) = spots[i]
                let (bn, bp, br) = spots[j]
                let d = RoomBox.screenSeparation(ap, bp)
                assert(d >= ar + br - 1e-4,
                       "FeestLayout: \(an) and \(bn) are \(Int(d * 1000)) mm apart as the "
                       + "camera sees them but need \(Int((ar + br) * 1000)) mm — whichever "
                       + "one the tie-break prefers is the one she gets.")
            }
        }

        // And the props have to fit on the floor, which the diagonal row is the
        // one thing here at risk of failing: six pads at this pitch reach within
        // a couple of millimetres of the edge.
        for i in 0..<padCount {
            let p = padSpot(i)
            assert(abs(p.x) + padGeometryRadius <= RoomBox.half
                   && abs(p.z) + padGeometryRadius <= RoomBox.half,
                   "FeestLayout: pad\(i) hangs off the floor.")
        }
        #endif
    }
}
