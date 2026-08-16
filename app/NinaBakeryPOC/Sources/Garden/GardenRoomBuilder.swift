import RealityKit
import simd

/// Builds the garden room box, matching `references/garden/roombox.png`.
///
/// Same split `RoomBuilder` makes: **this file builds only what does not
/// move.** The shell, the bed, the two shelves, the fence, the tree and the
/// bushes. Anything she can pick up, plant, water or pick has state and belongs
/// to `GardenRoom`.
enum GardenRoomBuilder {

    static func build(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "GardenRoot"

        let size = GardenLayout.roomSize
        let half = GardenLayout.half

        let slab = model(.box([size + 0.03, GardenLayout.slabThickness, size + 0.03]),
                         Palette.cream, flat: flat, name: "Slab")
        slab.position = [0, -GardenLayout.slabThickness / 2, 0]
        root.addChild(slab)

        // **Sandy cream ground, not the kitchen's blush floor.** `roombox.png`
        // and `plates/05-garden-roombox.png` agree on it, and they are right for
        // a reason beyond taste: the bed, the fence and the flowers are all
        // rose, and rose props on a rose floor is one colour with things
        // happening in it.
        let ground = model(.box([size, 0.004, size]),
                           Palette.cream, flat: flat, name: "Ground")
        ground.position = [0, 0.002, 0]
        root.addChild(ground)

        let backWall = model(.box([size, GardenLayout.wallHeight, GardenLayout.wallThickness]),
                             Palette.creamLight, flat: flat, name: "WallBack")
        backWall.position = [0, GardenLayout.wallHeight / 2,
                             -half + GardenLayout.wallThickness / 2]
        root.addChild(backWall)

        let leftWall = model(.box([GardenLayout.wallThickness, GardenLayout.wallHeight, size]),
                             Palette.cream, flat: flat, name: "WallLeft")
        leftWall.position = [-half + GardenLayout.wallThickness / 2,
                             GardenLayout.wallHeight / 2, 0]
        root.addChild(leftWall)

        // Architecture never casts. The back wall raking across the left wall
        // was the hardest band in the kitchen, and shadowing architecture with
        // architecture buys no grounding — `app/README.md`, "Approved lighting".
        for piece in [slab, ground, backWall, leftWall] {
            piece.excludeFromShadowCasting()
        }

        root.addChild(buildBed(flat: flat))
        for height in GardenLayout.shelfHeights {
            root.addChild(buildShelf(flat: flat, height: height))
        }
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
    static func buildBed(flat: Bool) -> Entity {
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

    // MARK: - The shelves

    /// One seed shelf: a plank on two brackets, and nothing else — the jars
    /// belong to `GardenRoom`, because tapping one is how a round starts.
    ///
    /// **The plank's back face sits on the wall's inner face**, so the depth
    /// grows forwards into the room and the shelf can never float off the
    /// plaster however deep it gets. `GardenLayout.shelfX` derives it.
    static func buildShelf(flat: Bool, height: Float) -> Entity {
        let shelf = Entity()
        shelf.name = "SeedShelf\(Int(height * 1000))"
        let x = GardenLayout.shelfX

        let plank = model(.box([GardenLayout.shelfDepth, 0.008, GardenLayout.shelfLength]),
                          Palette.sandyWood, flat: flat, name: "SeedShelfPlank")
        plank.position = [x, height, GardenLayout.shelfCentreZ]
        shelf.addChild(plank)

        // Two brackets under the ends, following the plank rather than sitting
        // at a typed-in offset — lengthening it cannot strand them in the
        // middle, which is the trap `buildCakePlank` documents.
        let inset = GardenLayout.shelfLength / 2 - 0.020
        for (i, dz) in [-inset, inset].enumerated() {
            let bracket = model(.box([GardenLayout.shelfDepth - 0.010, 0.016, 0.008]),
                                Palette.blushPinkDeep, flat: flat,
                                name: "SeedShelfBracket\(i)")
            bracket.position = [x - 0.004, height - 0.012,
                                GardenLayout.shelfCentreZ + dz]
            shelf.addChild(bracket)
        }

        // Wall-mounted, centimetres from the plaster: what a shelf and its jars
        // cast onto the wall behind them reads as a stain, and they are grounded
        // by standing on the plank.
        shelf.excludeFromShadowCasting()
        return shelf
    }

    // MARK: - The fence

    /// `references/garden/garden-fence.png`: pointed pickets on two rails.
    ///
    /// The plate draws little grey bolt heads on every picket. They are not
    /// modelled — at this scale each one is under a screen pixel, and
    /// `references/REFERENCES.md` §1 is explicit that fine detail fights the
    /// style. Same call the door's four panels made when they became two.
    static func buildFence(flat: Bool) -> Entity {
        let fence = Entity()
        fence.name = "Fence"

        let from = GardenLayout.fenceZ.x
        let to = GardenLayout.fenceZ.y
        let height = GardenLayout.fenceHeight
        let count = 6
        let spacing = (to - from) / Float(count - 1)

        for i in 0..<count {
            let z = from + spacing * Float(i)
            let picket = model(.box([0.007, height, 0.013]),
                               Palette.rose, flat: flat, name: "FencePicket\(i)")
            picket.position = [GardenLayout.fenceX,
                               GardenLayout.floorY + height / 2, z]
            fence.addChild(picket)

            // The point on top: a four-sided pyramid, which a lathe gives for
            // free by taking its top station to radius zero.
            let cap = model(.lathe(profile: [[0.0092, 0], [0, 0.0075]], sides: 4),
                            Palette.rose, flat: flat, name: "FenceCap\(i)")
            cap.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
            cap.position = [GardenLayout.fenceX, GardenLayout.floorY + height, z]
            fence.addChild(cap)
        }

        for rail: Float in [0.34, 0.76] {
            let bar = model(.box([0.011, 0.008, to - from + 0.026]),
                            Palette.blushPink, flat: flat, name: "FenceRail")
            bar.position = [GardenLayout.fenceX + 0.004,
                            GardenLayout.floorY + height * rail,
                            (from + to) / 2]
            fence.addChild(bar)
        }
        return fence
    }

    // MARK: - Greenery

    /// The back-left corner: one tree and two bushes, against the two walls.
    ///
    /// They are the room's only tall geometry and they are deliberately where
    /// nothing else wants to be. The kitchen learned this the expensive way —
    /// the near foreground has to stay open, because it is the most visible
    /// floor there is and the only place a thing can be set down without
    /// something already being there.
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
        RoomBuilder.model(shape, colour, flat: flat, name: name)
    }
}
