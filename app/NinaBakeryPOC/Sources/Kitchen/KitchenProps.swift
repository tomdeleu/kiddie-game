import RealityKit
import simd

/// The props that have a state: Otto, the bowl, the batter, the tin, the cake,
/// and the toys that move when tapped.
///
/// Same faceted primitives as the room shell — nothing here is imported, and
/// nothing here is smooth. Where a prop has parts that move independently
/// (Otto's door, the tap's water) the builder returns a little struct of
/// entities rather than one blob, because the game needs to reach the moving
/// part by name and reaching for it through `children` is how rooms rot.
enum KitchenProps {

    // MARK: - Otto

    struct Oven {
        let root: Entity
        /// The body. Squashed and stretched when he speaks or bakes.
        let dome: ModelEntity
        /// Hinged at the bottom of the mouth; rotates about X to open.
        let doorPivot: Entity
        let door: ModelEntity
        let eyes: [ModelEntity]
        let pupils: [ModelEntity]
        /// Where a pupil sits when Otto looks straight ahead, in eye-local
        /// space. Every eye animation tweens back to this, so overlapping
        /// glances can never leave a pupil stranded off-centre.
        let pupilRest: SIMD3<Float>
        let chimneyTop: SIMD3<Float>
    }

    /// Faceted dome, a protruding archway, a chimney, and a face — per
    /// `references/props/oven.png`, plus the two eyes that make him Otto.
    static func oven(flat: Bool) -> Oven {
        let root = Entity()
        root.name = "Otto"
        root.position = Layout.ovenOrigin

        // The body sits under its own entity so squash-and-stretch does not
        // drag the door, the arch or the face around with it.
        let body = Entity()
        body.name = "OttoBody"
        root.addChild(body)

        let dome = RoomBuilder.model(.dome(radius: Layout.ovenDomeRadius,
                                           height: Layout.ovenDomeHeight,
                                           sides: 8, rings: 4),
                                     Palette.mint, flat: flat, name: "OvenDome")
        body.addChild(dome)

        // The mouth is one continuous archway, not a ring of separate blocks:
        // the plate shows a single moulded surround, and loose blocks read as
        // rubble at this size.
        //
        // The Z numbers are the fiddly part. The dome is an ellipsoid,
        // (x²+z²)/r² + y²/h² = 1, so it bulges furthest forward at the centre
        // of the mouth. The arch's back plane sits behind the near one so it
        // looks embedded.
        let archDepth = Layout.mouthDepth
        let archBack = Layout.mouthBackZ
        let archFront = Layout.mouthFrontZ

        let arch = RoomBuilder.model(.archRing(innerRadius: Layout.mouthArchInner,
                                               outerRadius: 0.034,
                                               legHeight: Layout.mouthLegHeight,
                                               depth: archDepth, segments: 6),
                                     Palette.rose, flat: flat, name: "OvenArch")
        arch.position = [0, 0, archBack + archDepth / 2]
        root.addChild(arch)

        // The dark opening. Slightly oversized so its edges hide behind the
        // soffit rather than leaving a seam, and recessed just enough to read
        // as set back rather than painted on.
        //
        // **The recess cannot be deep, and this is the reason.** The arch is
        // not a tunnel through the dome — it is a ring stuck on the front of
        // an ellipsoid that bulges *into* it. The dome reaches z = 0.062 at
        // the base of the mouth, while the arch face is at 0.076, so anything
        // set back more than 0.014 sits behind the dome shell and you see
        // mint through the opening instead of dark. That is exactly what a
        // 0.022 recess did on the 2026-08-15 build. 0.008 keeps the plug
        // clear of the bulge with 0.006 to spare, and the hole reads as a
        // flat dark surface a little way back — which is all it needs to be.
        // It is solid: the tin slides in and is swallowed by the dark, which
        // is also how a real oven works.
        let oversize: Float = 0.002
        let plugDepth: Float = 0.028
        let plugRecess: Float = 0.008
        let mouth = RoomBuilder.model(.archPlug(radius: Layout.mouthArchInner + oversize,
                                                legHeight: Layout.mouthLegHeight + oversize,
                                                depth: plugDepth, segments: 6),
                                      Palette.ovenInside, flat: flat, name: "OvenMouth")
        mouth.position = [0, -oversize, archFront - plugRecess - plugDepth / 2]
        root.addChild(mouth)

        // The door. Hinged at the bottom edge so it drops forward — which is
        // the shape of the gesture she already knows from a real oven.
        let doorPivot = Entity()
        doorPivot.name = "OvenDoorPivot"
        doorPivot.position = [0, 0, archFront - 0.004]
        root.addChild(doorPivot)

        let door = RoomBuilder.model(.archPlug(radius: Layout.mouthArchInner + 0.005,
                                               legHeight: Layout.mouthLegHeight + 0.005,
                                               depth: 0.005, segments: 6),
                                     Palette.blushPinkDeep, flat: flat, name: "OvenDoor")
        doorPivot.addChild(door)

        let handle = RoomBuilder.model(.box([0.020, 0.004, 0.004]),
                                       Palette.butterYellow, flat: flat, name: "OvenDoorHandle")
        handle.position = [0, Layout.mouthLegHeight + 0.026, 0.004]
        doorPivot.addChild(handle)

        // The chimney, per the plate: a square shaft, a wider lighter cap, and
        // a real opening in the top — a rim of four walls around a dark flue,
        // recessed so the hole reads as a hole from the fixed camera. Built
        // from boxes rather than 4-sided prisms because a 4-sided prism puts
        // its vertices on the axes, which stands the shaft on a diamond edge;
        // the plate's chimney is square to the room.
        //
        // The shaft runs all the way to the floor. The ideal dome surface out
        // where the chimney stands is at y = 0.056, but the dome is faceted —
        // its real surface chords *inside* the ideal ellipsoid — so a shaft
        // that merely dips below 0.056 can still hang in the air over a chord,
        // which is exactly what the 2026-08-15 build showed. Grounded, it can
        // never float, whatever the facets do. Boxes are centred, so each y
        // here is the part's centre.
        let chimneyX: Float = 0.028
        let chimneyZ: Float = -0.030

        let shaft = RoomBuilder.model(.box([0.022, 0.096, 0.022]),
                                      Palette.cream, flat: flat, name: "Chimney")
        shaft.position = [chimneyX, 0.048, chimneyZ]
        body.addChild(shaft)

        let capSlab = RoomBuilder.model(.box([0.034, 0.006, 0.034]),
                                        Palette.creamLight, flat: flat, name: "ChimneyCap")
        capSlab.position = [chimneyX, 0.096 + 0.003, chimneyZ]
        body.addChild(capSlab)

        // The rim: four walls, outer 0.030, 0.007 thick, leaving a 0.016
        // square opening.
        let rimTopY: Float = 0.110
        let rimWallY: Float = 0.102 + 0.004
        for (i, spec) in [
            (SIMD3<Float>(0.030, 0.008, 0.007), SIMD3<Float>(chimneyX, rimWallY, chimneyZ - 0.0115)),
            (SIMD3<Float>(0.030, 0.008, 0.007), SIMD3<Float>(chimneyX, rimWallY, chimneyZ + 0.0115)),
            (SIMD3<Float>(0.007, 0.008, 0.016), SIMD3<Float>(chimneyX - 0.0115, rimWallY, chimneyZ)),
            (SIMD3<Float>(0.007, 0.008, 0.016), SIMD3<Float>(chimneyX + 0.0115, rimWallY, chimneyZ)),
        ].enumerated() {
            let wall = RoomBuilder.model(.box(spec.0), Palette.creamLight,
                                         flat: flat, name: "ChimneyRim\(i)")
            wall.position = spec.1
            body.addChild(wall)
        }

        // The flue. Slightly wider than the opening so its sides hide inside
        // the rim walls (same trick as the mouth plug), top 0.003 below the
        // rim so the recess is visible from the camera's angle.
        let flue = RoomBuilder.model(.box([0.017, 0.014, 0.017]),
                                     Palette.woodBrown, flat: flat, name: "ChimneyFlue")
        flue.position = [chimneyX, rimTopY - 0.003 - 0.007, chimneyZ]
        body.addChild(flue)

        // The face. Two eyes is the whole character — he has no mouth,
        // because the arch already is one.
        //
        // Each eye is a light eyeball with a small brown pupil in front — a
        // single dark ball read as a hole in the dome, not an eye. The pupil
        // is a child of the eyeball, so the blink (which scales the entities
        // in `eyes`) squeezes both together.
        let pupilRest = SIMD3<Float>(0, 0, 0.0055)
        var eyes: [ModelEntity] = []
        var pupils: [ModelEntity] = []
        for (i, dx) in [Float(-0.018), 0.018].enumerated() {
            let eye = RoomBuilder.model(.icosphere(radius: 0.008, subdivisions: 1),
                                        Palette.creamLight, flat: flat, name: "OttoEye\(i)")
            eye.position = [dx, 0.052, 0.042]
            body.addChild(eye)
            eyes.append(eye)

            let pupil = RoomBuilder.model(.icosphere(radius: 0.004, subdivisions: 1),
                                          Palette.woodBrown, flat: flat, name: "OttoPupil\(i)")
            pupil.position = pupilRest
            eye.addChild(pupil)
            pupils.append(pupil)
        }
        // **No cheeks.** There were two rose blobs out at x = ±0.034 meant to
        // read as blush. Out there the dome is turning away hard, so a blob
        // small enough not to be a lump is mostly buried, and the faceted
        // surface then exposes a different sliver of it from every angle. On
        // screen it read as debris stuck to the oven, twice over, and moving
        // it forward only made the floating more obvious (owner: "anomalies",
        // 2026-08-15). Blush on a faceted dome wants to be a facet painted a
        // different colour, not a ball — worth doing when the mesh builder can
        // colour faces individually. Until then Otto is eyes and a mouth.

        return Oven(root: root, dome: dome, doorPivot: doorPivot, door: door,
                    eyes: eyes, pupils: pupils, pupilRest: pupilRest,
                    chimneyTop: Layout.ovenOrigin + SIMD3<Float>(0.028, 0.112, -0.030))
    }

    // MARK: - The bake

    /// The basket now holds one ingredient rather than three, so it shrank —
    /// the other two live on the shelf and the counter.
    static func basket(flat: Bool) -> ModelEntity {
        RoomBuilder.model(.bowl(bottomRadius: 0.016, topRadius: 0.022, height: 0.014,
                                wallThickness: 0.003, floorThickness: 0.003,
                                sides: 8, rings: 2),
                          Palette.sandyWood, flat: flat, name: "Basket")
    }

    /// A little open pot for the ingredient waiting on the counter, so it reads
    /// as stored rather than dropped there.
    static func ingredientPot(flat: Bool) -> ModelEntity {
        RoomBuilder.model(.bowl(bottomRadius: 0.011, topRadius: 0.014, height: 0.012,
                                wallThickness: 0.0025, floorThickness: 0.0025,
                                sides: 8, rings: 2),
                          Palette.mint, flat: flat, name: "IngredientPot")
    }

    // MARK: - The dough

    /// The ball of dough, before the rolling pin gets to it.
    static func doughBall(flat: Bool) -> ModelEntity {
        RoomBuilder.model(.icosphere(radius: 0.014, subdivisions: 1),
                          Palette.cream, flat: flat, name: "Dough")
    }

    /// The rolled-out base that goes in the tin. Same colour, different shape —
    /// she should recognise it as the thing she just flattened.
    static func doughBase(flat: Bool) -> ModelEntity {
        RoomBuilder.model(.prism(radius: 0.018, height: 0.004, sides: 12),
                          Palette.cream, flat: flat, name: "DoughBase")
    }

    // MARK: - The six ingredients

    /// One draggable ingredient, modelled to look like the thing it is.
    ///
    /// **These used to be six coloured blobs** — two icospheres, a hexagonal
    /// prism and a smaller icosphere, told apart only by tint. That failed the
    /// one job an ingredient has: `CONCEPT.md` §5 forbids text, so the shape
    /// *is* the label, and "a slightly bigger pale sphere" does not say
    /// wolkenroom to anybody, least of all to someone who cannot read the word
    /// either. A 4-year-old knows what a strawberry looks like long before she
    /// knows the letters in it.
    ///
    /// Each is built from its plate in `references/ingredients/`, which is why
    /// they share a facet budget and a silhouette scale rather than each being
    /// invented at its call site. All six are roughly 20 mm tall and 20 mm
    /// across, so no one of them is the big one, and all six are built from the
    /// same primitives as the room — mostly `FacetedMesh.lathe`, which is what
    /// makes six distinct profiles cheaper than six mesh builders.
    static func token(_ ingredient: Ingredient, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Token_\(ingredient.rawValue)"
        switch ingredient {
        case .aardbei: buildStrawberry(into: root, flat: flat)
        case .bosbes: buildBlueberry(into: root, flat: flat)
        case .honing: buildHoneyPot(into: root, flat: flat)
        case .klaver: buildClover(into: root, flat: flat)
        case .wolkenroom: buildCloudCream(into: root, flat: flat)
        case .sterrensuiker: buildSugarStar(into: root, flat: flat)
        }
        return root
    }

    /// The room's fixed camera sits on the +X+Z diagonal, so a prop with a flat
    /// front — the clover, the star — is turned this far to face it. Nothing
    /// ever moves the camera (`CONCEPT.md` §9.4), so "face the camera" is a
    /// constant rather than a billboard that has to be updated every frame.
    private static let towardsCamera = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])

    /// `regenboogaardbei` — a berry that swells high and comes to a point, under
    /// a splayed crown of six flat leaves.
    private static func buildStrawberry(into root: Entity, flat: Bool) {
        let body = RoomBuilder.model(.lathe(profile: [[0, 0],
                                                      [0.0055, 0.0035],
                                                      [0.0090, 0.0078],
                                                      [0.0100, 0.0118],
                                                      [0.0082, 0.0152],
                                                      [0.0042, 0.0166]],
                                            sides: 8),
                                     Palette.rose, flat: flat, name: "BerryBody")
        root.addChild(body)

        // A pointed leaf, lying in the XY plane with its length along +Y. The
        // rotation below tips it from upright to splayed, which is one
        // quaternion rather than six hand-placed leaves.
        let leaf = RoomBuilder.Shape.extrude(outline: [[0, 0],
                                                       [0.0026, 0.0040],
                                                       [0.0034, 0.0082],
                                                       [0, 0.0135],
                                                       [-0.0034, 0.0082],
                                                       [-0.0026, 0.0040]],
                                             thickness: 0.0012)
        for i in 0..<6 {
            let blade = RoomBuilder.model(leaf, Palette.sage, flat: flat, name: "BerryLeaf\(i)")
            let spin = simd_quatf(angle: Float(i) / 6 * 2 * .pi, axis: [0, 1, 0])
            // -90° lays it flat; the extra 0.55 rad lifts the tip, which is what
            // the plate shows and what keeps it out of the berry's own silhouette.
            let lie = simd_quatf(angle: -.pi / 2 + 0.55, axis: [1, 0, 0])
            blade.orientation = spin * lie
            blade.position = [0, 0.0164, 0]
            root.addChild(blade)
        }
    }

    /// `toverbosbes` — a round berry with the little five-point crown a real
    /// blueberry has, which is the detail that stops it reading as a marble.
    private static func buildBlueberry(into root: Entity, flat: Bool) {
        let body = RoomBuilder.model(.lathe(profile: [[0, 0],
                                                      [0.0058, 0.0022],
                                                      [0.0095, 0.0068],
                                                      [0.0098, 0.0122],
                                                      [0.0068, 0.0168],
                                                      [0, 0.0192]],
                                            sides: 10),
                                     Palette.berryBlueDeep, flat: flat, name: "BosbesBody")
        root.addChild(body)

        let crown = RoomBuilder.model(.star(points: 5, outerRadius: 0.0044,
                                            innerRadius: 0.0018, thickness: 0.0030),
                                      Palette.berryBlue, flat: flat, name: "BosbesCrown")
        // Built facing +Z; laid flat so it sits on top of the berry.
        crown.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        crown.position = [0, 0.0180, 0]
        root.addChild(crown)
    }

    /// `zonnehoning` — a pot rather than a lump. The plate made the case: honey
    /// has no shape of its own, so the readable object is the jar it is in.
    private static func buildHoneyPot(into root: Entity, flat: Bool) {
        let body = RoomBuilder.model(.lathe(profile: [[0.0068, 0],
                                                      [0.0092, 0.0060],
                                                      [0.0100, 0.0110],
                                                      [0.0088, 0.0140]],
                                            sides: 8),
                                     Palette.cream, flat: flat, name: "HoningPot")
        root.addChild(body)

        let rim = RoomBuilder.model(.prism(radius: 0.0106, height: 0.0022, sides: 8),
                                    Palette.creamLight, flat: flat, name: "HoningRim")
        rim.position = [0, 0.0138, 0]
        root.addChild(rim)

        let honey = RoomBuilder.model(.prism(radius: 0.0072, height: 0.0012, sides: 8),
                                      Palette.honeyAmber, flat: flat, name: "HoningVulling")
        honey.position = [0, 0.0154, 0]
        root.addChild(honey)

        // The dipper, lying across the rim. Two parts, not the plate's five
        // rings — at 20 mm the rings would be half a millimetre each.
        let stick = RoomBuilder.model(.prism(radius: 0.0016, height: 0.0230, sides: 5),
                                      Palette.sandyWood, flat: flat, name: "HoningStok")
        stick.orientation = simd_quatf(angle: -.pi / 2, axis: [0, 0, 1])
        stick.position = [-0.0100, 0.0176, 0.0016]
        root.addChild(stick)

        let bead = RoomBuilder.model(.lathe(profile: [[0.0018, 0], [0.0042, 0.0028],
                                                      [0.0018, 0.0056]], sides: 6),
                                     Palette.sandyWood, flat: flat, name: "HoningKop")
        bead.orientation = simd_quatf(angle: -.pi / 2, axis: [0, 0, 1])
        bead.position = [-0.0072, 0.0176, 0.0016]
        root.addChild(bead)
    }

    /// `toverklaver` — four flat hearts around a stem, facing the camera.
    ///
    /// Four, not three. The plate came back with four and it is better: a
    /// four-leaf clover is the lucky one, which is the right note for the one
    /// ingredient with *tover* in its name.
    private static func buildClover(into root: Entity, flat: Bool) {
        root.orientation = towardsCamera

        // A heart, tip at the bottom. Not convex — but every vertex is visible
        // from the tip, which is all `extrude`'s fan needs.
        let heart = RoomBuilder.Shape.extrude(outline: [[0, -0.0050],
                                                        [0.0038, -0.0018],
                                                        [0.0050, 0.0018],
                                                        [0.0038, 0.0042],
                                                        [0.0018, 0.0040],
                                                        [0, 0.0018],
                                                        [-0.0018, 0.0040],
                                                        [-0.0038, 0.0042],
                                                        [-0.0050, 0.0018],
                                                        [-0.0038, -0.0018]],
                                              thickness: 0.0014)
        // The heart's tip is 5 mm below its own origin, so rotating it about the
        // origin would swing all four tips out into a little pinwheel. Each
        // leaf is pushed back out along its own axis by exactly that much,
        // which lands all four tips on the centre where they belong.
        let tipDrop: Float = 0.0050
        let hub: Float = 0.0128
        for i in 0..<4 {
            let colour = i % 2 == 0 ? Palette.sage : Palette.sageDeep
            let leaf = RoomBuilder.model(heart, colour, flat: flat, name: "KlaverBlad\(i)")
            let angle = Float.pi / 4 + Float(i) * Float.pi / 2
            leaf.orientation = simd_quatf(angle: angle, axis: [0, 0, 1])
            leaf.position = [-sin(angle) * tipDrop, hub + cos(angle) * tipDrop, 0]
            root.addChild(leaf)
        }

        // Up to the hub, so there is no gap between the stem and the leaves.
        let stem = RoomBuilder.model(.prism(radius: 0.0013, height: hub, sides: 4),
                                     Palette.sageDeep, flat: flat, name: "KlaverSteel")
        root.addChild(stem)
    }

    /// `wolkenroom` — four overlapping faceted spheres, which is the only way a
    /// cloud has ever been built in this style.
    private static func buildCloudCream(into root: Entity, flat: Bool) {
        let blobs: [(Float, SIMD3<Float>)] = [
            (0.0072, [0, 0.0104, -0.0015]),
            (0.0058, [-0.0075, 0.0062, 0.0010]),
            (0.0060, [0.0072, 0.0064, -0.0020]),
            (0.0055, [0.0000, 0.0058, 0.0055]),
        ]
        for (i, blob) in blobs.enumerated() {
            let ball = RoomBuilder.model(.icosphere(radius: blob.0, subdivisions: 1),
                                         i == 0 ? Palette.creamLight : Palette.cream,
                                         flat: flat, name: "RoomBol\(i)")
            ball.position = blob.1
            root.addChild(ball)
        }
    }

    /// `sterrensuiker` — one chunky star with a raised centre ridge, standing
    /// on two arms and turned to face the camera.
    private static func buildSugarStar(into root: Entity, flat: Bool) {
        root.orientation = towardsCamera
        let star = RoomBuilder.model(.star(points: 5, outerRadius: 0.0105,
                                           innerRadius: 0.0045, thickness: 0.0052),
                                     Palette.mintLight, flat: flat, name: "SterBody")
        // The lowest points of a five-point star standing upright are its two
        // bottom arms, at sin(234°) of the outer radius.
        star.position = [0, 0.0105 * 0.809, 0]
        root.addChild(star)
    }

    static let bowlHeight: Float = 0.026
    static let bowlTopRadius: Float = 0.032

    static func mixingBowl(flat: Bool) -> ModelEntity {
        RoomBuilder.model(.bowl(bottomRadius: 0.021, topRadius: bowlTopRadius,
                                height: bowlHeight, wallThickness: 0.0028,
                                floorThickness: 0.0035, sides: 12, rings: 3),
                          Palette.blushPink, flat: flat, name: "Bowl")
    }

    /// The batter. A faceted disc that rises and changes colour as she fills
    /// the bowl — the only thing on screen that says her choice did something.
    static func batter(colour: UIColorLike, radius: Float, flat: Bool) -> ModelEntity {
        RoomBuilder.model(.prism(radius: radius, height: 0.004, sides: 12),
                          colour, flat: flat, name: "Batter")
    }

    static func whisk(flat: Bool) -> Entity {
        let whisk = Entity()
        whisk.name = "Whisk"

        let handle = RoomBuilder.model(.prism(radius: 0.004, height: 0.036, sides: 6),
                                       Palette.sandyWood, flat: flat, name: "WhiskHandle")
        handle.position = [0, 0.014, 0]
        whisk.addChild(handle)

        // The head, upside down: wide at the top, narrow where it meets the
        // batter. A closed solid, because an open cone has no inside.
        let head = RoomBuilder.model(.taperedPrism(bottomRadius: 0.004, topRadius: 0.011,
                                                   height: 0.016, sides: 6),
                                     Palette.creamLight, flat: flat, name: "WhiskHead")
        head.position = [0, -0.002, 0]
        whisk.addChild(head)

        return whisk
    }

    struct Tin {
        let root: Entity
        /// The batter inside, hidden until she pours.
        let batter: ModelEntity
    }

    static func tin(flat: Bool) -> Tin {
        let root = Entity()
        root.name = "Tin"

        let body = RoomBuilder.model(.bowl(bottomRadius: 0.019, topRadius: 0.022,
                                           height: 0.013, wallThickness: 0.0025,
                                           floorThickness: 0.003, sides: 8, rings: 2),
                                     Palette.blushPinkDeep, flat: flat, name: "TinBody")
        root.addChild(body)

        let batter = KitchenProps.batter(colour: Palette.cream, radius: 0.0175, flat: flat)
        batter.name = "TinBatter"
        batter.position = [0, 0.004, 0]
        batter.isEnabled = false
        root.addChild(batter)

        return Tin(root: root, batter: batter)
    }

    /// The cake, in her colours.
    ///
    /// Three stacked tiers, painted from `CakeSpec.tierColours` — which is what
    /// makes "two colours swirled" and "three colours rainbow" visible rather
    /// than a claim in a design document. Everything else about a cake variant
    /// is a tint, a scale and a particle flag (`GAMEPLAY.md` §5).
    static func cake(_ spec: CakeSpec, flat: Bool) -> Entity {
        let cake = Entity()
        cake.name = "Cake"

        let colours = spec.tierColours(3)
        let radii: [Float] = [0.026, 0.021, 0.015]
        let heights: [Float] = [0.013, 0.011, 0.009]
        let stretch: Float = spec.isTall ? 1.5 : 1.0

        var y: Float = 0
        for tier in 0..<3 {
            let height = heights[tier] * stretch
            let colour = colours[min(tier, colours.count - 1)]
            let mesh = FacetedMesh.mesh(FacetedMesh.prism(radius: radii[tier],
                                                          height: height, sides: 10),
                                        flat: flat)
            let material = spec.glows
                ? Palette.glowMaterial(colour, intensity: 0.35)
                : Palette.material(colour)
            let slice = ModelEntity(mesh: mesh, materials: [material])
            slice.name = "CakeTier\(tier)"
            slice.position = [0, y, 0]
            cake.addChild(slice)
            y += height
        }

        // A cherry, always. It is the thing that makes it read as a cake at
        // thumbnail size, which is what it will be on the plank.
        let cherry = RoomBuilder.model(.icosphere(radius: 0.005, subdivisions: 1),
                                       Palette.rose, flat: flat, name: "CakeCherry")
        cherry.position = [0, y + 0.004, 0]
        cake.addChild(cherry)

        return cake
    }

    // MARK: - Toys

    /// The flour sack, per `references/ingredients/flour-sack.png`.
    ///
    /// **It stands on the floor now**, and it grew to suit: the old one was a
    /// 30 mm tapered prism on the counter, which read as a paper cup. A sack of
    /// flour is a heavy thing that slumps — wide and settled at the bottom,
    /// swelling to its widest about a third of the way up, gathered into a band
    /// at the neck, with the cloth above the band fanning open. That profile is
    /// what says *sack*, and it only works at a size a worktop cannot spare.
    static func flourSack(flat: Bool) -> Entity {
        let sack = Entity()
        sack.name = "FlourSack"

        let body = RoomBuilder.model(.lathe(profile: [[0.0170, 0],
                                                      [0.0215, 0.0080],
                                                      [0.0230, 0.0180],
                                                      [0.0200, 0.0280],
                                                      [0.0120, 0.0360],
                                                      [0.0085, 0.0400]],
                                            sides: 8),
                                     Palette.creamLight, flat: flat, name: "FlourSackBody")
        sack.addChild(body)

        // The two corners of cloth that splay out where a full sack meets the
        // floor. They are most of what stops the body reading as a vase.
        for (i, angle) in [Float(0.5), 2.4].enumerated() {
            let corner = RoomBuilder.model(.prism(radius: 0.011, height: 0.0040, sides: 3),
                                           Palette.cream, flat: flat,
                                           name: "FlourSackCorner\(i)")
            corner.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            corner.position = [cos(angle) * 0.017, 0.0006, sin(angle) * 0.017]
            sack.addChild(corner)
        }

        let tie = RoomBuilder.model(.lathe(profile: [[0.0098, 0], [0.0105, 0.0022],
                                                     [0.0098, 0.0044]], sides: 8),
                                    Palette.blushPinkDeep, flat: flat, name: "FlourSackTie")
        tie.position = [0, 0.0392, 0]
        sack.addChild(tie)

        // The open cloth above the tie, flaring upward and outward.
        let collar = RoomBuilder.model(.lathe(profile: [[0.0082, 0], [0.0175, 0.0092]],
                                              sides: 8),
                                       Palette.creamLight, flat: flat, name: "FlourSackCollar")
        collar.position = [0, 0.0436, 0]
        sack.addChild(collar)

        return sack
    }

    /// The crate the fifth ingredient waits in, down on the floor.
    ///
    /// A four-sided open box, turned to put a corner towards the camera so it
    /// reads as having an inside. It is the only reason to reach below the
    /// table, and reaching down is half of what makes the room feel tall.
    static func crate(flat: Bool) -> Entity {
        let crate = Entity()
        crate.name = "Crate"
        crate.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])

        let box = RoomBuilder.model(.bowl(bottomRadius: 0.021, topRadius: 0.025,
                                          height: 0.022, wallThickness: 0.0035,
                                          floorThickness: 0.0035, sides: 4, rings: 2),
                                    Palette.sandyWood, flat: flat, name: "CrateBody")
        crate.addChild(box)

        let rim = RoomBuilder.model(.lathe(profile: [[0.0262, 0], [0.0262, 0.0035]],
                                           sides: 4),
                                    Palette.woodBrown, flat: flat, name: "CrateRim")
        rim.position = [0, 0.0205, 0]
        crate.addChild(rim)

        return crate
    }

    struct Sink {
        let root: Entity
        let basin: ModelEntity
        /// The falling stream. Grown down the Y axis to turn it on, and slowly
        /// spun about Y while it runs — see `KitchenRoom.tapSink`.
        let stream: ModelEntity
        /// The water gathering in the basin. Rises while the tap runs, drains
        /// after, and is what makes the stream look like it is going somewhere.
        let pool: ModelEntity
        /// World-space point the stream lands on, for droplets and ripples.
        let splash: SIMD3<Float>
    }

    /// The tap. **Rebuilt** — the first one was a single five-sided prism in
    /// flat `berryBlue`, scaled up the Y axis, and it read as a blue stick.
    ///
    /// Three things fix it, none of them a fluid simulation:
    ///
    /// - **The stream has a shape.** It leaves the spout narrow, swells where
    ///   it picks up speed and pulls in again at the bottom, which is what
    ///   falling water actually does and what a straight cylinder cannot say.
    /// - **It goes somewhere.** Water arriving in an empty basin and never
    ///   filling it is the tell; the pool rises while it runs and drains after.
    /// - **It moves.** The stream turns slowly about its own axis, so the
    ///   facets travel downward-ish and the surface reads as running rather
    ///   than as a placed object. Six sides, so the facets are big enough to
    ///   see turning.
    ///
    /// The one deviation from `references/REFERENCES.md` — which asks for no
    /// transparency anywhere — is that the stream and the pool are slightly
    /// see-through. Opaque water in a pastel palette reads as painted plastic,
    /// and this is the only place in the room that does it.
    static func sink(flat: Bool) -> Sink {
        let root = Entity()
        root.name = "Sink"

        let basin = RoomBuilder.model(.bowl(bottomRadius: 0.016, topRadius: 0.020,
                                            height: 0.012, wallThickness: 0.0025,
                                            floorThickness: 0.003, sides: 8, rings: 2),
                                      Palette.mintLight, flat: flat, name: "SinkBasin")
        root.addChild(basin)

        let column = RoomBuilder.model(.prism(radius: 0.004, height: 0.030, sides: 5),
                                       Palette.sage, flat: flat, name: "TapColumn")
        column.position = [0, 0.010, -0.018]
        root.addChild(column)

        let spout = RoomBuilder.model(.prism(radius: 0.003, height: 0.016, sides: 5),
                                      Palette.sage, flat: flat, name: "TapSpout")
        spout.position = [0, 0.038, -0.010]
        spout.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        root.addChild(spout)

        // Built hanging from y = 0 downwards, so growing it down the Y axis is
        // the tap opening. The profile is read bottom-to-top by `lathe`, hence
        // the negative heights in ascending order.
        let streamLength: Float = 0.026
        let stream = ModelEntity(
            mesh: FacetedMesh.mesh(FacetedMesh.lathe(profile: [[0.0020, -streamLength],
                                                               [0.0034, -streamLength * 0.72],
                                                               [0.0038, -streamLength * 0.42],
                                                               [0.0026, -streamLength * 0.16],
                                                               [0.0022, 0]],
                                                     sides: 6),
                                   flat: flat),
            materials: [Palette.waterMaterial(Palette.berryBlue)])
        stream.name = "TapStream"
        stream.position = [0, 0.0400, -0.002]
        stream.scale = [1, 0.001, 1]
        stream.isEnabled = false
        root.addChild(stream)

        // The basin floor is at y = 0.003 and the rim at 0.012; the pool lives
        // between them and is scaled up the Y axis as it fills. It is a lathe
        // rather than a prism because the basin's inner wall is tapered — a
        // straight-sided cylinder wide enough to touch the rim pokes out
        // through the wall down at the floor.
        let pool = ModelEntity(
            mesh: FacetedMesh.mesh(FacetedMesh.lathe(profile: [[0.0128, 0],
                                                               [0.0152, 0.0040],
                                                               [0.0166, 0.0075]],
                                                     sides: 8),
                                   flat: flat),
            materials: [Palette.waterMaterial(Palette.berryBlue, opacity: 0.72)])
        pool.name = "TapPool"
        pool.position = [0, 0.0032, 0]
        pool.scale = [1, 0.001, 1]
        pool.isEnabled = false
        root.addChild(pool)

        return Sink(root: root, basin: basin, stream: stream, pool: pool,
                    splash: SIMD3<Float>(0, 0.0105, -0.002))
    }

    struct Scale {
        let root: Entity
        /// Bounces when tapped.
        let pan: Entity
    }

    static func scale(flat: Bool) -> Scale {
        let root = Entity()
        root.name = "Scale"

        let base = RoomBuilder.model(.box([0.034, 0.012, 0.026]),
                                     Palette.mint, flat: flat, name: "ScaleBase")
        base.position = [0, 0.006, 0]
        root.addChild(base)

        let dial = RoomBuilder.model(.prism(radius: 0.009, height: 0.004, sides: 8),
                                     Palette.creamLight, flat: flat, name: "ScaleDial")
        dial.position = [0, 0.013, -0.008]
        dial.orientation = simd_quatf(angle: .pi / 2.4, axis: [1, 0, 0])
        root.addChild(dial)

        let pan = Entity()
        pan.name = "ScalePan"
        pan.position = [0, 0.012, 0.004]
        root.addChild(pan)

        let panDisc = RoomBuilder.model(.prism(radius: 0.014, height: 0.003, sides: 10),
                                        Palette.butterYellow, flat: flat, name: "ScalePanDisc")
        pan.addChild(panDisc)

        return Scale(root: root, pan: pan)
    }

    /// Lies across the table on its side, so it rolls when she drags it.
    static func rollingPin(flat: Bool) -> Entity {
        let pin = Entity()
        pin.name = "RollingPin"

        let barrel = RoomBuilder.model(.prism(radius: 0.008, height: 0.052, sides: 8),
                                       Palette.creamLight, flat: flat, name: "RollingPinBarrel")
        // Prisms stand on Y; lay it along X and centre it on its own length.
        barrel.position = [-0.026, 0, 0]
        barrel.orientation = simd_quatf(angle: -.pi / 2, axis: [0, 0, 1])
        pin.addChild(barrel)

        // The barrel runs x ∈ [-0.026, 0.026]; a handle grows along +X from
        // where it is placed, so the ends are -0.040 and +0.026.
        for (i, dx) in [Float(-0.040), 0.026].enumerated() {
            let handle = RoomBuilder.model(.prism(radius: 0.004, height: 0.014, sides: 6),
                                           Palette.sandyWood, flat: flat,
                                           name: "RollingPinHandle\(i)")
            handle.position = [dx, 0, 0]
            handle.orientation = simd_quatf(angle: -.pi / 2, axis: [0, 0, 1])
            pin.addChild(handle)
        }
        return pin
    }

    struct Doorway {
        let root: Entity
        /// Brightens once the round is finished.
        let glow: ModelEntity
    }

    /// The way out. `GAMEPLAY.md` §6: the door always works, and it gains a
    /// soft glow once the required action is done — it is never disabled, and
    /// it never asks.
    static func doorway(flat: Bool) -> Doorway {
        let root = Entity()
        root.name = "Doorway"
        root.position = Layout.doorwayCentre
        // Built in the XY plane extruded along Z; a +90° turn about Y sends its
        // front face down +X, which is the way the left wall looks.
        root.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

        let glow = RoomBuilder.model(.archPlug(radius: Layout.doorwayInner,
                                               legHeight: Layout.doorwayLegHeight,
                                               depth: 0.004, segments: 6),
                                     Palette.butterYellow, flat: flat, name: "DoorwayGlow")
        glow.position = [0, 0, -0.004]
        root.addChild(glow)

        let frame = RoomBuilder.model(.archRing(innerRadius: Layout.doorwayInner,
                                                outerRadius: Layout.doorwayInner + 0.012,
                                                legHeight: Layout.doorwayLegHeight,
                                                depth: 0.010, segments: 6),
                                      Palette.rose, flat: flat, name: "DoorwayFrame")
        root.addChild(frame)

        return Doorway(root: root, glow: glow)
    }
}
