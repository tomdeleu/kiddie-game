import RealityKit
import simd

/// Builds the garden, matching `references/garden/roombox-v2.png`.
///
/// **It is not a room box.** `references/REFERENCES.md` §1 gives every room two
/// walls and a floor, and this one has a **fence** — owner's call, because a
/// garden with plaster around it is a garden indoors. The rule's purpose is
/// kept exactly: the fence stands on the two far edges, where the walls stood,
/// so the two near sides are still open and nothing new has entered a sightline.
///
/// Same split `RoomBuilder` makes: **this file builds only what does not
/// move.** The ground, the fence, the bed, the potting bench, the path and the
/// greenery. Anything she can pick up, plant, water or pick has state and
/// belongs to `GardenRoom`.
enum GardenRoomBuilder {

    static func build(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "GardenRoot"

        let size = GardenLayout.roomSize

        let slab = model(.box([size + 0.03, GardenLayout.slabThickness, size + 0.03]),
                         Palette.cream, flat: flat, name: "Slab")
        slab.position = [0, -GardenLayout.slabThickness / 2, 0]
        root.addChild(slab)

        // **Grass, not the sandy floor it had.**
        //
        // The old ground was `cream`, chosen when there were walls, to stop a
        // rose bed and a rose fence sitting on a rose floor. With the walls gone
        // the ground is most of the frame, and `roombox-v2.png` — the plate
        // generated to answer exactly that question — comes back with a pale
        // mint lawn and a cream *path*. The lawn is right, and for the reason
        // the props README already records twice: **a plate cannot answer a
        // question about the room it is not standing in**, and only the
        // room-box plate is standing in this one. The path the same plate drew
        // at the gate was built and then removed on the owner's call,
        // 2026-08-17 — see `GardenRoom.refreshDoorInvitation`.
        //
        // `mintLight` rather than `mint` because the plants' leaves are `sage`
        // and `mint`; the grass has to be the palest green in the room or the
        // bushes disappear into it.
        let ground = model(.box([size, 0.004, size]),
                           Palette.mintLight, flat: flat, name: "Ground")
        ground.position = [0, 0.002, 0]
        root.addChild(ground)

        // The slab and the ground never cast — they are the things everything
        // else casts *onto*.
        slab.excludeFromShadowCasting()
        ground.excludeFromShadowCasting()
        if let ao = GardenAO.lawnOverlay() {
            root.addChild(ao)
        }

        root.addChild(buildBed(flat: flat))
        root.addChild(buildBench(flat: flat))
        root.addChild(buildFence(flat: flat))
        root.addChild(buildGreenery(flat: flat))

        return root
    }

    // MARK: - The bed

    /// **De zaaibak**, from `references/garden/garden-bed.png`.
    ///
    /// Four corner posts standing proud of two board bands, a soil slab inset
    /// below the rim, and five holes sunk into it as rings. The posts are what
    /// make it joinery rather than a tray — the same thing the crate's plate
    /// taught, and the reason that one went to Blender.
    ///
    /// **The holes are visible rings rather than dark discs**, which is a
    /// gameplay decision the plate happened to make first: a ring standing a
    /// millimetre proud of the soil catches the key light on its own facets, so
    /// an empty hole is legible from across the room without being lit. It has
    /// to be, because the halo can only ever be on one of them.
    ///
    /// **Modelled in Blender**, `models/garden-bed.py`, which takes three more
    /// things off the plate that the code below does not have: **two board
    /// bands** with a groove between them rather than one 40 mm slab, **posts
    /// standing proud** of the boards rather than flush with them, and **holes
    /// with a wall** — a ring you can see into, over soil dropped 3 mm, rather
    /// than a flat annulus laid on top. Every dimension is still
    /// `GardenLayout`'s, because the rim is what a carried seed rides over and
    /// the five holes are `plotSpot` to the millimetre.
    static func buildBed(flat: Bool) -> Entity {
        if flat, let modelled = ModelLibrary.load(
                "garden-bed",
                tint: GardenAO.paintTints(["BedBoards": Palette.blushPinkDeep,
                       "BedFrame": Palette.rose,
                       "BedSoil": Palette.woodBrown,
                       "BedHoles": Palette.mix(Palette.woodBrown,
                                               Palette.sandyWood, 0.35)])) {
            modelled.position = [GardenLayout.bedCentre.x, 0,
                                 GardenLayout.bedCentre.y]
            return modelled
        }
        return buildProceduralBed(flat: flat)
    }

    /// The code-built bed. See `buildBed(flat:)` for when it runs.
    static func buildProceduralBed(flat: Bool) -> Entity {
        let bed = Entity()
        bed.name = "SeedBed"
        bed.position = [GardenLayout.bedCentre.x, 0, GardenLayout.bedCentre.y]

        let size = GardenLayout.bedSize
        let rimY = GardenLayout.bedRimY
        let soilY = GardenLayout.bedSoilY
        let rim = GardenLayout.bedRimWidth
        let post = GardenLayout.bedPostSize

        // The carcass: two long boards and two short ones, from the ground to
        // just under the rim.
        let bodyHeight = rimY - GardenLayout.floorY - 0.006
        for side: Float in [-1, 1] {
            let long = model(.box([size.x - post, bodyHeight, 0.006]),
                             Palette.blushPinkDeep, flat: flat, name: "BedBoardLong")
            long.position = [0, GardenLayout.floorY + bodyHeight / 2, side * (size.y / 2 - 0.003)]
            bed.addChild(long)

            let short = model(.box([0.006, bodyHeight, size.y - post]),
                              Palette.blushPinkDeep, flat: flat, name: "BedBoardShort")
            short.position = [side * (size.x / 2 - 0.003), GardenLayout.floorY + bodyHeight / 2, 0]
            bed.addChild(short)
        }

        // The soil, a step below the rim so the bed has an inside.
        let soil = model(.box([size.x - rim * 2, 0.010, size.y - rim * 2]),
                         Palette.woodBrown, flat: flat, name: "BedSoil")
        soil.position = [0, soilY - 0.005, 0]
        bed.addChild(soil)

        // The rim: four rails laid flat on top of the boards.
        for side: Float in [-1, 1] {
            let long = model(.box([size.x, 0.008, rim]),
                             Palette.rose, flat: flat, name: "BedRimLong")
            long.position = [0, rimY - 0.004, side * (size.y - rim) / 2]
            bed.addChild(long)

            let short = model(.box([rim, 0.008, size.y - rim * 2]),
                              Palette.rose, flat: flat, name: "BedRimShort")
            short.position = [side * (size.x - rim) / 2, rimY - 0.004, 0]
            bed.addChild(short)
        }

        // Four corner posts, standing a little above the rim. The plate's whole
        // structural idea.
        for dx: Float in [-1, 1] {
            for dz: Float in [-1, 1] {
                let leg = model(.box([post, rimY - GardenLayout.floorY + 0.006, post]),
                                Palette.rose, flat: flat, name: "BedPost")
                leg.position = [dx * (size.x - post) / 2,
                                GardenLayout.floorY + (rimY - GardenLayout.floorY + 0.006) / 2,
                                dz * (size.y - post) / 2]
                bed.addChild(leg)
            }
        }

        // The five holes. Built here rather than in `GardenRoom` because a hole
        // does not move and has no state — what grows *in* it does.
        for index in 0..<GardenLayout.plotCount {
            let spot = GardenLayout.plotSpot(index)
            let ring = model(.annulus(innerRadius: GardenLayout.plotRadius - 0.0035,
                                      outerRadius: GardenLayout.plotRadius,
                                      segments: 9),
                             Palette.mix(Palette.woodBrown, Palette.sandyWood, 0.35),
                             flat: flat, name: "BedHole\(index)")
            ring.position = [spot.x - GardenLayout.bedCentre.x,
                             soilY + 0.0012,
                             spot.z - GardenLayout.bedCentre.y]
            bed.addChild(ring)
        }

        return bed
    }

    // MARK: - The potting bench

    /// **De werkbank**, from `references/garden/potting-bench.png`: four square
    /// legs, a worktop with a low backboard, and a lower shelf that **sticks out
    /// in front of the worktop**.
    ///
    /// The projection is the whole design. This camera looks down at about 34°,
    /// so you can see under an overhang by roughly one and a half times the
    /// drop — and a jar standing under a worktop 42 mm above it would be cut in
    /// half by its own bench. The plate solves it by pushing the shelf forward
    /// so the lower row stands clear of the worktop's front edge, and
    /// `GardenLayout.jarSpot` puts them there.
    ///
    /// The jars themselves belong to `GardenRoom` — tapping one is how a round
    /// starts, and this file only builds what has no state.
    static func buildBench(flat: Bool) -> Entity {
        let bench = Entity()
        bench.name = "PottingBench"
        bench.position = [GardenLayout.benchCentre.x, 0, GardenLayout.benchCentre.y]

        let top = GardenLayout.benchTopSize
        let shelf = GardenLayout.benchShelfSize
        let board = GardenLayout.benchBoard
        let shelfDX = GardenLayout.benchShelfX - GardenLayout.benchCentre.x

        let worktop = model(.box([top.x, board, top.y]),
                            Palette.sandyWood, flat: flat, name: "BenchTop")
        worktop.position = [0, GardenLayout.benchTopY + board / 2, 0]
        bench.addChild(worktop)

        // The backboard, standing on the worktop's back edge. With no wall
        // behind the bench any more, it is what stops the top row of jars
        // reading as floating against the backdrop.
        let backboard = model(.box([0.006, GardenLayout.benchBackboard, top.y]),
                              Palette.cream, flat: flat, name: "BenchBackboard")
        backboard.position = [-top.x / 2 + 0.003,
                              GardenLayout.benchTopY + board + GardenLayout.benchBackboard / 2,
                              0]
        bench.addChild(backboard)

        let lower = model(.box([shelf.x, board, shelf.y]),
                          Palette.sandyWood, flat: flat, name: "BenchShelf")
        lower.position = [shelfDX, GardenLayout.benchShelfY + board / 2, 0]
        bench.addChild(lower)

        // Four legs at the corners of the *lower* shelf's footprint, since it is
        // the wider of the two — a leg inside the shelf's edge would leave the
        // front of it cantilevered over nothing.
        let leg = GardenLayout.benchLegSize
        let legTop = GardenLayout.benchTopY
        for dx: Float in [-1, 1] {
            for dz: Float in [-1, 1] {
                let post = model(.box([leg, legTop - GardenLayout.floorY, leg]),
                                 Palette.cream, flat: flat, name: "BenchLeg")
                post.position = [shelfDX + dx * (shelf.x - leg) / 2,
                                 GardenLayout.floorY + (legTop - GardenLayout.floorY) / 2,
                                 dz * (shelf.y - leg) / 2]
                bench.addChild(post)
            }
        }
        return bench
    }

    // MARK: - The fence

    /// **The fence, which is what this room has instead of walls.**
    ///
    /// An L: one run along the back edge and one along the left, meeting at the
    /// far corner, with a **gap in the left run for the gate**.
    /// `references/garden/fence-gate.png` and `roombox-v2.png` between them give
    /// the whole vocabulary — flat pickets with pointed tops nailed across two
    /// rails, with taller square posts at intervals carrying flat pyramid caps.
    ///
    /// **It is cream, not the rose the old edging was.** The bed is rose, and
    /// `roombox-v2.png` puts a cream fence around a rose bed on a mint lawn for
    /// the reason the deleted comment about the floor gave: the same colour on
    /// the boundary and on the thing inside it is one colour with things
    /// happening in it.
    ///
    /// The plate draws little grey bolt heads on every picket. They are not
    /// modelled — at this scale each is under a screen pixel, and
    /// `references/REFERENCES.md` §1 is explicit that fine detail fights the
    /// style. Same call the door's four panels made when they became two.
    ///
    /// **The fence casts, where the walls did not.** Architecture was excluded
    /// because a wall's shadow lands on another wall and reads as a stain
    /// (`app/README.md`, "Approved lighting"). What a fence casts onto is the
    /// *ground*, which is the grounding case that section wanted from the key
    /// light in the first place. It is about forty small casters — worth an eye
    /// on device, and one line to undo if the stripes read as clutter.
    ///
    /// **Modelled in Blender**, `models/garden-fence.py` — and unlike every
    /// other prop in this game the model is **the whole L, in world
    /// coordinates**, dropped at the origin. It is the room's own boundary
    /// rather than a thing standing in the room, and the payoff is that forty-odd
    /// pickets, eleven posts and six rails stop being forty-odd entities: three
    /// meshes carry the lot. The script computes the same post positions, the
    /// same 19 mm picket spacing and the same gate gap that `addRun` below does,
    /// deliberately as a transcription of it.
    ///
    /// What it takes from the plate is the **chamfered picket**: the code cuts a
    /// flat board, which gives a picket two faces and both of them flat, where
    /// the plate draws turned timber with the corners taken off. The footprint
    /// is unchanged, so the 11 mm gap — the thing that makes this a fence and
    /// not a low wall — is unchanged too.
    static func buildFence(flat: Bool) -> Entity {
        if flat, let modelled = ModelLibrary.load(
                "garden-fence",
                tint: GardenAO.paintTints(["FencePickets": Palette.cream,
                       "FencePosts": Palette.creamLight,
                       "FenceRails": Palette.creamLight])) {
            return modelled
        }
        return buildProceduralFence(flat: flat)
    }

    /// The code-built fence. See `buildFence(flat:)` for when it runs.
    static func buildProceduralFence(flat: Bool) -> Entity {
        let fence = Entity()
        fence.name = "Fence"

        let half = GardenLayout.half
        // Each run stops at the far corner and reaches out to the open edge of
        // the slab, so the L closes properly at one end and simply ends at the
        // other — which is what a garden fence disappearing out of frame does.
        addRun(into: fence, alongZ: true, line: GardenLayout.fenceLineX,
               from: GardenLayout.fenceLineZ, upTo: half + 0.004,
               gapCentre: GardenLayout.gateCentre.z, flat: flat)
        addRun(into: fence, alongZ: false, line: GardenLayout.fenceLineZ,
               from: GardenLayout.fenceLineX, upTo: half + 0.004,
               gapCentre: nil, flat: flat)

        return fence
    }

    /// One straight run of fence, optionally with a gap in it for the gate.
    ///
    /// `alongZ` says which way the run travels; `line` is its fixed coordinate
    /// on the other axis. Written once for both runs rather than twice, because
    /// two copies of a picket loop is two places for the rail height to drift.
    private static func addRun(into fence: Entity, alongZ: Bool, line: Float,
                               from start: Float, upTo end: Float,
                               gapCentre: Float?, flat: Bool) {
        let height = GardenLayout.fenceHeight
        let picket = GardenLayout.fencePicket
        let spacing = GardenLayout.fencePicketSpacing
        let floorY = GardenLayout.floorY

        /// Local (across, along) → world.
        func place(_ across: Float, _ y: Float, _ along: Float) -> SIMD3<Float> {
            alongZ ? [line + across, y, along] : [along, y, line + across]
        }

        // The gate's clear opening, plus the two posts that frame it. Nothing is
        // built inside this span — the leaf is `Props.gate`, and it hangs off
        // `GardenRoom` because it moves.
        let gap: ClosedRange<Float>? = gapCentre.map {
            let halfGap = GardenLayout.gateOpening / 2 + GardenLayout.fencePostSize
            return ($0 - halfGap)...($0 + halfGap)
        }

        var posts: [Float] = [start]
        var at = start + GardenLayout.fencePostSpacing
        while at < end {
            posts.append(at)
            at += GardenLayout.fencePostSpacing
        }
        posts.append(end)
        if let gapCentre {
            // A post either side of the opening, which is what a gate hangs from.
            let offset = GardenLayout.gateOpening / 2 + GardenLayout.fencePostSize / 2
            posts.append(gapCentre - offset)
            posts.append(gapCentre + offset)
            posts.removeAll { abs($0 - gapCentre) < offset - 0.001 }
        }

        // A post is square in plan, so unlike the pickets and the rails it does
        // not care which way the run travels.
        let postSize = SIMD3<Float>(GardenLayout.fencePostSize,
                                    GardenLayout.fencePostHeight,
                                    GardenLayout.fencePostSize)
        for (i, along) in posts.enumerated() {
            let post = model(.box(postSize),
                             Palette.creamLight, flat: flat, name: "FencePost\(i)")
            post.position = place(0, floorY + GardenLayout.fencePostHeight / 2, along)
            fence.addChild(post)

            // A flat pyramid cap. A `lathe` whose top station has radius zero
            // gives the apex for free — the same trick the old pickets used.
            let cap = model(.lathe(profile: [[0.0132, 0], [0.0116, 0.0032], [0, 0.0092]],
                                   sides: 4),
                            Palette.creamLight, flat: flat, name: "FenceCap\(i)")
            cap.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
            cap.position = place(0, floorY + GardenLayout.fencePostHeight, along)
            fence.addChild(cap)
        }

        // Pickets, skipping the gate opening and wherever a post already stands.
        var along = start + spacing
        var index = 0
        while along < end {
            defer { along += spacing; index += 1 }
            if let gap, gap.contains(along) { continue }
            if posts.contains(where: { abs($0 - along) < GardenLayout.fencePostSize }) {
                continue
            }
            let board = model(.box(alongZ ? [picket.y, height, picket.x]
                                          : [picket.x, height, picket.y]),
                              Palette.cream, flat: flat, name: "FencePicket\(index)")
            board.position = place(0, floorY + height / 2, along)
            fence.addChild(board)

            let point = model(.lathe(profile: [[0.0074, 0], [0, 0.0060]], sides: 4),
                              Palette.cream, flat: flat, name: "FencePoint\(index)")
            point.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
            point.position = place(0, floorY + height, along)
            fence.addChild(point)
        }

        // Two rails behind the pickets, in segments so the gate's opening stays
        // clear. Behind rather than in front, because the pickets are the face.
        for rail in GardenLayout.fenceRails {
            let y = floorY + height * rail
            let spans: [(Float, Float)]
            if let gap {
                spans = [(start, gap.lowerBound), (gap.upperBound, end)]
            } else {
                spans = [(start, end)]
            }
            for (a, b) in spans where b - a > 0.004 {
                let length = b - a
                let bar = model(.box(alongZ ? [0.010, 0.007, length]
                                            : [length, 0.007, 0.010]),
                                Palette.creamLight, flat: flat, name: "FenceRail")
                bar.position = place(-0.008, y, (a + b) / 2)
                fence.addChild(bar)
            }
        }
    }

    // MARK: - Greenery

    /// One tree and two bushes, spread along the back fence.
    ///
    /// They were in the back-left corner; the potting bench took that ground, so
    /// they run along the back instead — behind the bed from the camera, which
    /// is where nothing else wants to be. The kitchen learned the rule the
    /// expensive way: the near foreground has to stay open, because it is the
    /// most visible floor there is and the only place a thing can be set down
    /// without something already being there.
    ///
    /// **The tree overhangs the fence**, which is right rather than a clash —
    /// leaning over a garden fence is what a tree does, and it is what stops the
    /// fence reading as the top edge of the picture now that there is no wall
    /// above it.
    static func buildGreenery(flat: Bool) -> Entity {
        let greenery = Entity()
        greenery.name = "Greenery"

        let tree = GardenProps.tree(flat: flat)
        tree.position = GardenLayout.treeSpot
        greenery.addChild(tree)

        for (i, spot) in GardenLayout.bushSpots.enumerated() {
            let bush = GardenProps.bush(radius: i == 0 ? 0.026 : 0.021, flat: flat)
            bush.position = spot
            greenery.addChild(bush)
        }
        return greenery
    }

    // MARK: - Helpers

    /// Straight through to `RoomBuilder`, so a garden prop and a kitchen prop
    /// are built by the same function and answer the debug panel's flat/smooth
    /// toggle the same way.
    static func model(_ shape: RoomBuilder.Shape, _ colour: UIColorLike,
                      flat: Bool, name: String) -> ModelEntity {
        RoomBuilder.model(shape, GardenAO.paint(colour, name: name),
                          flat: flat, name: name)
    }
}
