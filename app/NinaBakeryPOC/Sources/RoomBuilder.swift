import RealityKit
import simd

/// Where everything in the kitchen is.
///
/// One table of numbers rather than magic constants spread across the room and
/// the game, because almost every bug in a room like this is two files
/// disagreeing about where the table top is.
enum Layout {

    /// Room box is 0.4 m across, per `POC.md`.
    static let roomSize: Float = 0.4
    static let half: Float = roomSize / 2
    static let wallHeight: Float = 0.22
    static let wallThickness: Float = 0.012
    static let slabThickness: Float = 0.014
    static let floorY: Float = 0.004

    /// The work surface. Everything she drags lives on this plane.
    static let tableTopY: Float = 0.072
    static let tableCentre = SIMD2<Float>(-0.045, 0.050)
    static let tableSize = SIMD2<Float>(0.210, 0.115)
    static let tableThickness: Float = 0.012

    /// The back counter: sink, scale, flour sack.
    static let counterTopY: Float = 0.058
    static let counterCentre = SIMD2<Float>(-0.085, -0.158)
    static let counterSize = SIMD2<Float>(0.200, 0.060)

    /// Otto, on the right against the back wall.
    static let ovenOrigin = SIMD3<Float>(0.115, floorY, -0.100)
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

    // Home positions on the table.
    static let basketHome = SIMD3<Float>(-0.130, tableTopY, 0.082)
    static let bowlHome = SIMD3<Float>(-0.050, tableTopY, 0.048)
    static let whiskHome = SIMD3<Float>(-0.020, tableTopY, 0.014)
    static let tinHome = SIMD3<Float>(0.022, tableTopY, 0.080)
    /// Lies along X from here, so its left end is what has to stay on the table.
    static let rollingPinHome = SIMD3<Float>(-0.105, tableTopY, 0.006)
    /// The ball of dough, and where it is rolled out. Sits in the pin's path.
    static let doughSpot = SIMD3<Float>(-0.105, tableTopY, 0.045)
    /// Where a finished cake lands when Otto hands it over.
    static let cakeSpot = SIMD3<Float>(0.024, tableTopY, 0.030)

    /// Nina herself, behind the table between it and the counter.
    ///
    /// Placed left of the bowl rather than squarely behind it: at the room's
    /// fixed camera angle, standing behind the bowl put her body across the
    /// sightline to the sink, and a toy she is standing in front of is a toy
    /// that never gets tapped.
    static let bakerSpot = SIMD3<Float>(-0.105, floorY, -0.062)

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
            case .plankHoog: return SIMD3<Float>(-0.181, 0.164, 0.030)
            case .plankLaag: return SIMD3<Float>(-0.181, 0.119, 0.030)
            case .aanrecht: return SIMD3<Float>(-0.050, counterTopY + 0.011, -0.150)
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
    // 0.20 m run and is now on the floor, which left the counter with room to
    // breathe: sink, scale, and the ingredient pot.
    static let sinkSpot = SIMD3<Float>(-0.150, counterTopY, -0.158)
    static let scaleSpot = SIMD3<Float>(-0.098, counterTopY, -0.152)

    /// **The flour sack sits on the floor**, in the near-left foreground where
    /// the room is open. A sack of flour is a heavy thing, and a heavy thing on
    /// a worktop reads as a jar; on the ground it reads as a sack. It is also
    /// the one prop in front of the table, which gives the shot a foreground.
    static let flourSpot = SIMD3<Float>(-0.055, floorY, 0.152)

    /// The crate the fifth ingredient waits in, on the floor to Otto's near
    /// side. Placed off the table's right edge rather than behind it: the
    /// camera looks down the +X+Z diagonal, so floor to the *left* of the table
    /// is hidden by the table itself and floor to the right is not.
    static let crateSpot = SIMD3<Float>(0.098, floorY, 0.042)

    /// The plank on the back wall the finished cakes stand on.
    static let cakePlankY: Float = 0.135
    static let cakePlankCentre = SIMD2<Float>(-0.090, -0.172)
    static let cakePlankLength: Float = 0.130
    static let cakeShelfCapacity = 4

    /// The way out, on the left wall. Leads to the decorating room when it
    /// exists; for now it closes the round.
    static let doorwayCentre = SIMD3<Float>(-0.186, floorY, 0.120)
    static let doorwayInner: Float = 0.035
    static let doorwayLegHeight: Float = 0.032

    /// Horizontal distance. Snapping ignores height on purpose: she aims at
    /// where a thing *is on the table*, not at its centre of mass.
    static func distanceXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        simd_length(SIMD2<Float>(a.x - b.x, a.z - b.z))
    }

    // MARK: - Height

    /// **What a prop is standing on at this point in the room.**
    ///
    /// Everything used to be carried at one height — the table top — whatever
    /// it was over, which is why the room read as a painted backdrop: a prop
    /// dragged off the table stayed at table height and simply floated. The
    /// fix is not a physics engine; it is knowing what is underneath. Four
    /// surfaces answer for the whole room, tested nearest-camera first so the
    /// table wins over the counter where their footprints meet.
    ///
    /// `KitchenRoom.carry` eases the carried prop towards this plus a small
    /// lift, and the drag plane follows it down. So dragging the rolling pin
    /// off the table and onto the floor *lowers* it, over about a third of a
    /// second, and it stays under her finger the whole way.
    ///
    /// **The cake plank is deliberately not in here.** It hangs on the wall
    /// directly above the back of the counter, so as a surface it would shadow
    /// the counter and fling the sink brush shelf-high. It is a snap target
    /// instead — see `nearPlank` — and only the cake ever uses it.
    static func surfaceY(at point: SIMD3<Float>) -> Float {
        if within(point, centre: tableCentre, size: tableSize, margin: 0.006) {
            return tableTopY
        }
        if within(point, centre: counterCentre, size: counterSize, margin: 0.006) {
            return counterTopY
        }
        return floorY
    }

    /// Whether a point is close enough to the plank to count as putting a cake
    /// on it. Generous by design: `CONCEPT.md` §5 asks for drops that count
    /// when they land *near*, and this is the last action of the whole round.
    static let plankSnapRadius: Float = 0.062

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

    /// True where `point` is over a rectangle, grown by `margin` so a prop set
    /// down right on an edge lands on the surface rather than beside it.
    private static func within(_ point: SIMD3<Float>, centre: SIMD2<Float>,
                               size: SIMD2<Float>, margin: Float) -> Bool {
        abs(point.x - centre.x) <= size.x / 2 + margin
            && abs(point.z - centre.y) <= size.y / 2 + margin
    }

    /// How far above whatever it is standing on a carried prop floats. Small,
    /// but not nothing: it is what says *held* rather than *shoved*.
    static let carryLift: Float = 0.012

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
    /// x ∈ [−0.18, −0.01], z ∈ [−0.09, 0.04] — a hand-sized patch of floor
    /// between the table and the counter.
    @MainActor
    static func isOutOfSight(_ point: SIMD3<Float>) -> Bool {
        guard surfaceY(at: point) <= floorY + 0.001 else { return false }
        // Inside the counter is inside a solid box, which is worse than hidden.
        if within(point, centre: counterCentre, size: counterSize, margin: 0.004) {
            return true
        }
        let eye = CameraRig.eye
        let t = (tableTopY - eye.y) / (floorY - eye.y)
        let crossing = SIMD3<Float>(eye.x + (point.x - eye.x) * t, tableTopY,
                                    eye.z + (point.z - eye.z) * t)
        return within(crossing, centre: tableCentre, size: tableSize, margin: 0.004)
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
    static func clampToPlayArea(_ p: SIMD3<Float>) -> SIMD3<Float> {
        let minX: Float = -0.180
        let maxX: Float = 0.145
        let minZ: Float = -0.178
        let maxZ: Float = 0.162
        return SIMD3<Float>(min(max(p.x, minX), maxX), p.y, min(max(p.z, minZ), maxZ))
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
/// This file builds only what does not move: the shell, the furniture, Otto's
/// body. Anything she can pick up, fill, stir or eat is in `KitchenProps` and
/// is owned by `KitchenRoom`, because those have state and this does not.
enum RoomBuilder {

    static func build(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "RoomRoot"

        let size = Layout.roomSize
        let half = Layout.half

        // Base slab — the footing every room sits on, from the cottage plate.
        let slab = model(.box([size + 0.03, Layout.slabThickness, size + 0.03]),
                         Palette.cream, flat: flat, name: "Slab")
        slab.position = [0, -Layout.slabThickness / 2, 0]
        root.addChild(slab)

        let floor = model(.box([size, 0.004, size]),
                          Palette.blushPink, flat: flat, name: "Floor")
        floor.position = [0, 0.002, 0]
        root.addChild(floor)

        // Two walls, open on the two near sides.
        let backWall = model(.box([size, Layout.wallHeight, Layout.wallThickness]),
                             Palette.creamLight, flat: flat, name: "WallBack")
        backWall.position = [0, Layout.wallHeight / 2, -half + Layout.wallThickness / 2]
        root.addChild(backWall)

        let leftWall = model(.box([Layout.wallThickness, Layout.wallHeight, size]),
                             Palette.cream, flat: flat, name: "WallLeft")
        leftWall.position = [-half + Layout.wallThickness / 2, Layout.wallHeight / 2, 0]
        root.addChild(leftWall)

        root.addChild(buildTable(flat: flat))
        root.addChild(buildCounter(flat: flat))
        root.addChild(buildShelf(flat: flat, height: 0.150))
        root.addChild(buildShelf(flat: flat, height: 0.105))
        root.addChild(buildCakePlank(flat: flat))

        return root
    }

    // MARK: - Furniture

    static func buildTable(flat: Bool) -> Entity {
        let table = Entity()
        table.name = "Table"
        table.position = [Layout.tableCentre.x, 0, Layout.tableCentre.y]

        let topCentreY = Layout.tableTopY - Layout.tableThickness / 2
        let top = model(.box([Layout.tableSize.x, Layout.tableThickness, Layout.tableSize.y]),
                        Palette.sandyWood, flat: flat, name: "TableTop")
        top.position = [0, topCentreY, 0]
        table.addChild(top)

        let legHeight = topCentreY - Layout.tableThickness / 2
        let dx = Layout.tableSize.x / 2 - 0.014
        let dz = Layout.tableSize.y / 2 - 0.014
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
        counter.position = [Layout.counterCentre.x, 0, Layout.counterCentre.y]

        let bodyHeight = Layout.counterTopY - Layout.floorY - 0.008
        let body = model(.box([Layout.counterSize.x - 0.012, bodyHeight, Layout.counterSize.y - 0.010]),
                         Palette.creamLight, flat: flat, name: "CounterBody")
        body.position = [0, Layout.floorY + bodyHeight / 2, 0]
        counter.addChild(body)

        let top = model(.box([Layout.counterSize.x, 0.008, Layout.counterSize.y]),
                        Palette.sandyWood, flat: flat, name: "CounterTop")
        top.position = [0, Layout.counterTopY - 0.004, 0]
        counter.addChild(top)

        return counter
    }

    static func buildShelf(flat: Bool, height: Float) -> Entity {
        let shelf = Entity()
        shelf.name = "Shelf\(Int(height * 1000))"
        let x = -Layout.half + 0.019

        let plank = model(.box([0.014, 0.008, 0.150]),
                          Palette.sandyWood, flat: flat, name: "ShelfPlank")
        plank.position = [x, height, -0.030]
        shelf.addChild(plank)

        // Three jars, not six — the style wants fewer, bigger props.
        let jarColours = [Palette.mint, Palette.creamLight, Palette.blushPinkDeep]
        for (i, colour) in jarColours.enumerated() {
            let z = Float(-0.085) + Float(i) * 0.045
            let jar = model(.prism(radius: 0.010, height: 0.022, sides: 8),
                            colour, flat: flat, name: "Jar\(Int(height * 1000))_\(i)")
            jar.position = [x, height + 0.004, z]
            shelf.addChild(jar)

            let lid = model(.prism(radius: 0.011, height: 0.005, sides: 8),
                            Palette.rose, flat: flat, name: "JarLid\(Int(height * 1000))_\(i)")
            lid.position = [x, height + 0.026, z]
            shelf.addChild(lid)
        }
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

        let plank = model(.box([Layout.cakePlankLength, 0.008, 0.030]),
                          Palette.rose, flat: flat, name: "CakePlankBoard")
        plank.position = [Layout.cakePlankCentre.x, Layout.cakePlankY, Layout.cakePlankCentre.y]
        shelf.addChild(plank)

        for (i, dx) in [Float(-0.055), 0.055].enumerated() {
            let bracket = model(.box([0.008, 0.020, 0.008]),
                                Palette.blushPinkDeep, flat: flat, name: "CakePlankBracket\(i)")
            bracket.position = [Layout.cakePlankCentre.x + dx,
                                Layout.cakePlankY - 0.014,
                                Layout.cakePlankCentre.y - 0.008]
            shelf.addChild(bracket)
        }
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
