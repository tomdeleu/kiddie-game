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
        /// **An eyeball's undeformed scale, and the same rule one level up.**
        ///
        /// The blink squeezes an eye down its Y axis and restores it after, and
        /// it used to restore to whatever `eye.scale` happened to be when that
        /// blink was started. Otto is the most tapped prop in the room and every
        /// tap blinks him, so a second tap mid-blink captured the *squeezed*
        /// scale as the new rest pose and gave it back flattened — and the third
        /// tap flattened that. Poke him half a dozen times and his eyes were
        /// slits that never opened again (owner, 2026-08-16). It is exactly the
        /// compounding `Ticker.Pose` was written to stop for `squash`; the eyes
        /// go through `tween` directly, so they need their own copy of the rule.
        let eyeRest: SIMD3<Float>
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
                    eyeRest: SIMD3<Float>(repeating: 1),
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
    ///
    /// **Slumped, not spherical.** It was a subdivided icosphere, which is a
    /// ball — and a ball of dough left on a table is not a ball for very long
    /// (owner, 2026-08-16: "too much of a perfect sphere, it should be a bit
    /// more blobby on the table"). Dough has almost no structure: it spreads
    /// under its own weight, so it is widest low down, flattens where it meets
    /// the wood, and domes softly over the top.
    ///
    /// That is a lathe profile, and the second half of the fix is the **seven**
    /// sides. A lathe is radially symmetric, so a high side count would give a
    /// smooth circular lump — a ball again, just a squashed one. Seven is few
    /// enough that the plan view is visibly irregular, which is what reads as
    /// *hand-formed* rather than *moulded*, and it is an odd number so no two
    /// facets are parallel across it.
    ///
    /// **The origin is on the table, not at the centre.** A lathe starts at its
    /// base, where the icosphere started at its middle — which is why the old
    /// one had to be lifted 12 mm by hand, and why flattening it needed that
    /// offset animated too. Sitting on its base, it stays planted for free when
    /// `KitchenRoom.shapeDough` squashes it.
    static func doughBall(flat: Bool) -> ModelEntity {
        RoomBuilder.model(.lathe(profile: [[0.0000, 0.0000],
                                           [0.0092, 0.0006],
                                           [0.0142, 0.0034],
                                           [0.0150, 0.0068],
                                           [0.0131, 0.0105],
                                           [0.0088, 0.0132],
                                           [0.0000, 0.0148]],
                                 sides: 7),
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
    ///
    /// **Modelled in Blender**, and the second prop to be — `models/bosbes.py`,
    /// the same route and the same two fallbacks as `flourSack(flat:)`. The
    /// plate wants a faceted globe with a calyx dished into the top and a
    /// folded crown standing in it; a lathe gives broad vertical panels, a pole
    /// at each end, and no way to make a dish and a dome out of one profile.
    ///
    /// No wrapper entity here: `token(_:flat:)` has already made `root`, and it
    /// is upright, which is what the squash on drop needs.
    private static func buildBlueberry(into root: Entity, flat: Bool) {
        if flat, let modelled = ModelLibrary.load("bosbes",
                                                  tint: ["Bosbes": Palette.berryBlueDeep,
                                                         "BosbesCrown": Palette.berryBlue]) {
            root.addChild(modelled)
            return
        }
        buildProceduralBlueberry(into: root, flat: flat)
    }

    /// The code-built berry. See `buildBlueberry(into:flat:)` for when it runs.
    private static func buildProceduralBlueberry(into root: Entity, flat: Bool) {
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
    ///
    /// **A third bigger than the other five** (owner, 2026-08-16). That breaks
    /// the rule the six were built to — roughly 20 mm each, so no one of them is
    /// the big one — and it breaks it for a good reason: this is the only one
    /// whose subject is a *container*, and a container has to read as having an
    /// inside. At 20 mm the pot, its rim, the pool of honey in it and the dipper
    /// lying across it were four details inside a thumbnail, and what carried
    /// the object was its silhouette alone. The extra third is what makes the
    /// honey visible as honey.
    ///
    /// The scale is on an intermediate entity rather than folded into twenty
    /// numbers, and rather than onto the token's own root. Off the root it would
    /// be the base pose `Ticker.squash` captures and restores, which is fine
    /// until something else assumes an ingredient's root is unit scale; here it
    /// is contained in the one prop that wants it.
    private static func buildHoneyPot(into token: Entity, flat: Bool) {
        let root = Entity()
        root.name = "HoningSchaal"
        root.scale = SIMD3<Float>(repeating: 1.33)
        token.addChild(root)

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

    /// **The batter falling out of the bowl into the tin.**
    ///
    /// The pour used to be a cut: the bowl tipped, the batter in it was removed
    /// on the same frame, and the batter in the tin started growing. Both ends
    /// of the action were animated and the action itself was not there — the
    /// batter teleported (owner, 2026-08-16: "we must see some pouring action").
    ///
    /// Built hanging from y = 0 downwards, so growing it down the Y axis is the
    /// pour starting — the same construction as the tap's stream in `sink`, and
    /// for the same reason: it means one scale drives it, and the top stays
    /// pinned to the lip it is coming from.
    ///
    /// The profile is the one falling liquid actually has. It leaves the rim
    /// narrow, swells where it picks up speed, and pulls in again as it lands.
    /// A straight cylinder is what the tap was before it was rebuilt, and it
    /// read as a stick.
    ///
    /// Six sides, so the facets are big enough to see turning — `KitchenRoom`
    /// spins it while it runs, which is most of what makes a fixed shape read as
    /// moving.
    static func pourStream(colour: UIColorLike, length: Float, flat: Bool) -> ModelEntity {
        RoomBuilder.model(.lathe(profile: [[0.0032, -length],
                                           [0.0052, -length * 0.68],
                                           [0.0058, -length * 0.38],
                                           [0.0044, -length * 0.14],
                                           [0.0038, 0]],
                                 sides: 6),
                          colour, flat: flat, name: "PourStream")
    }

    /// **De pollepel** — the big wooden spoon she stirs with.
    ///
    /// Modelled from `references/props/spoon.png`. It replaces a whisk, which
    /// was two prisms — a stick with an upside-down cone on the end — and read
    /// as neither a whisk nor anything else (owner, 2026-08-16: "looks like
    /// shit, create a proper big spoon instead").
    ///
    /// The plate is worth following closely because a spoon is one of the few
    /// kitchen objects a 4-year-old can already draw, which means she knows when
    /// it is wrong. Three things carry it:
    ///
    /// - **The scoop is hollow.** `FacetedMesh.bowl` gives a real rim and a real
    ///   inside, and that is the whole difference between a spoon and a lollipop.
    ///   Nine sides, so the rim is visibly polygonal at 28 mm across.
    /// - **The handle tapers**, thicker where it meets the scoop and narrower at
    ///   the tip, which is what the plate shows and what stops it reading as a
    ///   dowel.
    /// - **It is chunky.** The scoop is 28 mm across on a 32 mm bowl — near
    ///   enough to fill it, the way a real mixing spoon does, and far bigger
    ///   than the whisk's 22 mm head.
    ///
    /// **Built standing on its scoop with the handle straight up**, which is the
    /// convention the whisk used and the reason nothing in `KitchenRoom` had to
    /// change: stirring stands it in the bowl as-is, and resting it on the table
    /// is the same single rotation about X that laid the whisk down.
    ///
    /// The plate's hanging hole in the tip is not modelled. There are no
    /// booleans in `FacetedMesh`, and at 4 mm across the hole would be two
    /// pixels — a smudge, which is the same argument that gave the honey dipper
    /// two parts instead of the plate's five rings.
    static func spoon(flat: Bool) -> Entity {
        let spoon = Entity()
        spoon.name = "Spoon"

        // The scoop. Cream rather than the plate's wood: the table is
        // `sandyWood`, and a wooden spoon lying on a wooden table is a spoon
        // nobody can see. The handle keeps the wood, so the object still reads
        // as one — this is the same split the whisk used, and the one part of
        // it worth keeping.
        let scoop = RoomBuilder.model(.bowl(bottomRadius: 0.0092, topRadius: 0.0140,
                                            height: 0.0110, wallThickness: 0.0022,
                                            floorThickness: 0.0026, sides: 9, rings: 2),
                                      Palette.cream, flat: flat, name: "SpoonScoop")
        spoon.addChild(scoop)

        // The handle, tapering upward out of the scoop. It starts inside the
        // scoop's wall rather than on top of it, so there is no seam where the
        // two meet however the light falls.
        let handle = RoomBuilder.model(.taperedPrism(bottomRadius: 0.0050,
                                                     topRadius: 0.0034,
                                                     height: 0.0440, sides: 6),
                                       Palette.sandyWood, flat: flat, name: "SpoonHandle")
        handle.position = [0, 0.0072, 0]
        spoon.addChild(handle)

        // The flared tip. In the plate it is where the hanging hole is; here it
        // is simply what stops the handle ending in a point.
        let tip = RoomBuilder.model(.prism(radius: 0.0044, height: 0.0060, sides: 6),
                                    Palette.sandyWood, flat: flat, name: "SpoonTip")
        tip.position = [0, 0.0496, 0]
        spoon.addChild(tip)

        return spoon
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
    ///
    /// **The first prop modelled in Blender rather than in code.** Cloth is
    /// where the `FacetedMesh` vocabulary runs out: the code version below is
    /// four stacked lathes and two wedges doing an impression of one gathered
    /// bag, and the gather — the vertical folds pinching into the tie, the
    /// pleated crown above it — is the half of the reference plate it cannot
    /// reach. `models/flour-sack.py` builds those directly. See `ModelLibrary`.
    ///
    /// Two ways to end up with the code version, both wanted:
    /// - the USDZ is missing from the bundle, and a prop she can tap matters
    ///   more than which prop it is;
    /// - `flat` is `false`. The exported mesh carries one normal per face and
    ///   nothing re-derives them, so smooth is a question only the procedural
    ///   mesh can still answer. The lighting panel's A/B keeps working.
    static func flourSack(flat: Bool) -> Entity {
        if flat, let modelled = ModelLibrary.load("flour-sack",
                                                  tint: ["FlourSack": Palette.creamLight,
                                                         "FlourSackTie": Palette.blushPinkDeep,
                                                         "FlourSackCorner": Palette.cream]) {
            modelled.name = "FlourSack"
            return modelled
        }
        return proceduralFlourSack(flat: flat)
    }

    /// The code-built sack. See `flourSack(flat:)` for when it is used.
    static func proceduralFlourSack(flat: Bool) -> Entity {
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

    // MARK: - The portrait

    /// **Nina, in a frame on the back wall above Otto.**
    ///
    /// The photograph the owner supplied on 2026-08-16, hung on the wall.
    ///
    /// **It is the actual JPEG, not a reconstruction of it.** This was built the
    /// other way first — the girl rebuilt out of boxes and stars in the room's
    /// own faceted vocabulary — on the argument that a photograph inside a
    /// flat-shaded room is the flour-cloud mistake again, the one thing on
    /// screen that came from somewhere else. The owner overruled it, and on
    /// reflection the analogy was wrong: the flour cloud was a *photographic
    /// prop pretending to be part of the room*, whereas this is a photograph
    /// **being a photograph**. A framed picture on a wall is supposed to look
    /// like it came from somewhere else. That is what a photograph is for, and a
    /// child who knows the girl in it is not going to be persuaded by an
    /// approximation made of boxes.
    ///
    /// So the frame stays the room's — faceted rose rails, made of the same
    /// stuff as the door — and what is inside it is the file.
    ///
    /// Three things follow from using a real texture, and each of them is a
    /// constraint the procedural props never had:
    ///
    /// - **The picture is a `MeshResource.generatePlane`, not a `FacetedMesh`
    ///   box.** `FacetedMesh` writes positions and normals and no texture
    ///   coordinates, so a texture on one of its meshes has nothing to map to.
    ///   `generatePlane` carries UVs, and a photograph is flat anyway.
    /// - **The frame is sized from the photo**, not the other way round. The
    ///   texture's pixel dimensions give the aspect and the picture is fitted
    ///   inside `Layout.portraitPictureMax`, so replacing the file with one of a
    ///   different shape needs no numbers changed here.
    /// - **It is lit, not unlit.** A `PhysicallyBasedMaterial` with the photo as
    ///   its base colour dims and brightens with the room's key light the way a
    ///   real print behind glass would. Unlit would be truer to the file and
    ///   would read as a screen hanging on the wall.
    ///
    /// If the file is not in the bundle this falls back to the modelled girl
    /// rather than to an empty frame — see `modelledSitter`. That is not
    /// politeness: the frame answers a tap, and `ModelLibrary` sets the
    /// precedent that a missing asset must never leave a live tap target with
    /// nothing behind it.
    ///
    /// Everything is laid out in the frame's local XY plane with +Z out into the
    /// room, so hanging it is one position and no rotation — the back wall
    /// already faces +Z.
    static func portrait(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Portrait"
        root.position = Layout.portraitCentre

        if let photo = photograph() {
            let picture = fit(photo)
            addFrame(to: root, around: picture, flat: flat)
            addPhotograph(photo, size: picture, to: root)
        } else {
            let picture = Layout.portraitFallbackPicture
            addFrame(to: root, around: picture, flat: flat)
            addMount(to: root, size: picture, flat: flat)
            addModelledSitter(to: root, flat: flat)
        }

        // Wall-mounted, like the ingredient shelves and the cake plank: its cast
        // could only ever print the frame onto the plaster beside it, and it is
        // grounded by hanging rather than by a shadow. It has to stay last — it
        // walks the children that exist when it is called.
        root.excludeFromShadowCasting()
        return root
    }

    /// The photograph, out of the asset catalog.
    ///
    /// Two names tried, for the same reason `ModelLibrary` looks in two places:
    /// whether the file arrives as an asset-catalog image set or as a loose
    /// resource is a packaging detail this code should not depend on.
    ///
    /// **`nil` is a real outcome.** The repository ships the frame and the
    /// wiring; the photograph is somebody's child and is added locally. See
    /// `Resources/Assets.xcassets/NinaPortrait.imageset/README.md`.
    private static func photograph() -> TextureResource? {
        for name in ["NinaPortrait", "nina-portrait"] {
            if let texture = try? TextureResource.load(named: name) { return texture }
        }
        return nil
    }

    /// Fit the photo inside `portraitPictureMax`, keeping its aspect. Whichever
    /// side runs out first sets the scale, so neither a tall photo nor a wide
    /// one is ever cropped or squashed.
    private static func fit(_ photo: TextureResource) -> SIMD2<Float> {
        let box = Layout.portraitPictureMax
        let aspect = Float(photo.width) / Float(max(1, photo.height))
        let wide = SIMD2<Float>(box.x, box.x / max(aspect, 0.0001))
        return wide.y <= box.y ? wide : SIMD2<Float>(box.y * aspect, box.y)
    }

    /// The photograph itself, on a plane with real texture coordinates.
    private static func addPhotograph(_ photo: TextureResource, size: SIMD2<Float>,
                                      to root: Entity) {
        // 2 mm oversize on each side, so the print runs under the rails rather
        // than meeting them edge to edge. Two coplanar edges at this scale is a
        // hairline of wall showing through wherever the rasteriser rounds the
        // wrong way, and it would look like a crack in the picture.
        let mesh = MeshResource.generatePlane(width: size.x + 0.004,
                                              height: size.y + 0.004)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .white, texture: .init(photo))
        // Matte, like everything else in the room, and barely specular: a print
        // is not a mirror, and a highlight travelling across a child's face as
        // the halo breathes nearby would be the one thing nobody could ignore.
        material.roughness = .init(floatLiteral: 0.85)
        material.metallic = .init(floatLiteral: 0.0)
        material.specular = .init(floatLiteral: 0.05)

        let print = ModelEntity(mesh: mesh, materials: [material])
        print.name = "PortraitPhoto"
        // Behind the front of the rails by 4 mm, which is the rebate a picture
        // sits in. Proud of the plaster by 8, so nothing z-fights the wall.
        print.position = [0, 0, 0.008]
        root.addChild(print)
    }

    /// The frame: four rails, mitre-less — the two uprights run the full height
    /// and the two crossbars fit between them, which is how a butt-jointed frame
    /// is actually made and one fewer thing to line up.
    private static func addFrame(to root: Entity, around picture: SIMD2<Float>,
                                 flat: Bool) {
        let rail = Layout.portraitRail
        let depth = Layout.portraitDepth
        let outer = SIMD2<Float>(picture.x + rail * 2, picture.y + rail * 2)

        for side: Float in [-1, 1] {
            let upright = RoomBuilder.model(.box([rail, outer.y, depth]),
                                            Palette.rose, flat: flat,
                                            name: "PortraitFrameSide")
            upright.position = [side * (outer.x - rail) / 2, 0, depth / 2]
            root.addChild(upright)

            let crossbar = RoomBuilder.model(.box([picture.x, rail, depth]),
                                             Palette.rose, flat: flat,
                                             name: "PortraitFrameRail")
            crossbar.position = [0, side * (outer.y - rail) / 2, depth / 2]
            root.addChild(crossbar)
        }
    }

    /// The mount behind the sitter. Only the modelled fallback needs it — the
    /// photograph covers its own opening.
    private static func addMount(to root: Entity, size: SIMD2<Float>, flat: Bool) {
        let backing = RoomBuilder.model(.box([size.x, size.y, 0.003]),
                                        Palette.creamLight, flat: flat,
                                        name: "PortraitBacking")
        backing.position = [0, 0, 0.0015]
        root.addChild(backing)
    }

    /// **The girl, rebuilt out of the room's own vocabulary.**
    ///
    /// The frame's occupant when the photograph is not in the bundle. It was the
    /// shipping version for about an hour and is kept because an empty frame
    /// over a live tap target is worse than an approximate one, and because it
    /// is the only thing in the app that shows what the faceted style does with
    /// a human face.
    ///
    /// Laid out for a `Layout.portraitFallbackPicture` opening, and **every part
    /// is staged at its own depth**, climbing from the mount at z = 0.0015 to
    /// the eyes at 0.0118: two surfaces at the same z flicker against each other
    /// and at this size that would read as the picture being broken rather than
    /// as a picture. Nothing reaches back past z = 0, which is the plaster. The
    /// face ends up about 2 mm proud of the rails, which is deliberate — a
    /// portrait perfectly flush with its own frame is a decal.
    private static func addModelledSitter(to root: Entity, flat: Bool) {
        // A shoulders-up crop, the way the photograph is framed: the shirt fills
        // the bottom third and runs off both sides of the mount.
        let shirt = RoomBuilder.model(.box([0.044, 0.022, 0.006]),
                                      Palette.lilac, flat: flat, name: "PortraitShirt")
        shirt.position = [0, -0.026, 0.005]
        root.addChild(shirt)

        // Three daisies on it. An eight-point star is a daisy at 5 mm across,
        // and the yellow middle is the detail that makes it one rather than a
        // snowflake.
        for (i, spot) in [SIMD2<Float>(-0.014, -0.020), [0.004, -0.028],
                          [0.019, -0.017]].enumerated() {
            let petals = RoomBuilder.model(.star(points: 8, outerRadius: 0.0052,
                                                 innerRadius: 0.0022, thickness: 0.0016),
                                           Palette.lilacDeep, flat: flat,
                                           name: "PortraitDaisy\(i)")
            // `star` is built in the XY plane facing +Z, which is already the
            // way the frame looks — so unlike the blueberry's crown this one
            // needs no rotation at all.
            petals.position = [spot.x, spot.y, 0.0086]
            root.addChild(petals)

            let heart = RoomBuilder.model(.prism(radius: 0.0019, height: 0.0014, sides: 6),
                                          Palette.butterYellow, flat: flat,
                                          name: "PortraitDaisyHeart\(i)")
            heart.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            heart.position = [spot.x, spot.y, 0.0099]
            root.addChild(heart)
        }

        // Hair first, as the slab everything else sits in front of.
        let hair = RoomBuilder.model(.box([0.034, 0.034, 0.005]),
                                     Palette.woodBrown, flat: flat, name: "PortraitHair")
        hair.position = [0, 0.002, 0.005]
        root.addChild(hair)

        let head = RoomBuilder.model(.box([0.026, 0.028, 0.008]),
                                     Palette.sandyWood, flat: flat, name: "PortraitFace")
        head.position = [0, 0.000, 0.007]
        root.addChild(head)

        // The fringe swept across the top of the face, and the knot of hair
        // behind her ear. Both are in the photo and both are what stop the head
        // reading as a bald block.
        let fringe = RoomBuilder.model(.box([0.028, 0.008, 0.008]),
                                       Palette.woodBrown, flat: flat, name: "PortraitFringe")
        fringe.position = [0.001, 0.014, 0.0072]
        root.addChild(fringe)

        let knot = RoomBuilder.model(.icosphere(radius: 0.0055, subdivisions: 0),
                                     Palette.woodBrown, flat: flat, name: "PortraitKnot")
        knot.position = [-0.017, 0.012, 0.0055]
        root.addChild(knot)

        for (i, dx) in [Float(-0.0062), 0.0062].enumerated() {
            let eye = RoomBuilder.model(.icosphere(radius: 0.0024, subdivisions: 0),
                                        Palette.woodBrown, flat: flat,
                                        name: "PortraitEye\(i)")
            eye.position = [dx, 0.003, 0.0118]
            root.addChild(eye)

            let cheek = RoomBuilder.model(.prism(radius: 0.0040, height: 0.0012, sides: 6),
                                          Palette.blushPink, flat: flat,
                                          name: "PortraitCheek\(i)")
            cheek.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            cheek.position = [dx * 1.7, -0.004, 0.0116]
            root.addChild(cheek)
        }

        // The grin. She is grinning in the photograph with her teeth showing,
        // and two boxes is the whole of it: a mouth, and a lighter bar along the
        // top of it. One box on its own reads as a frown at any size.
        let mouth = RoomBuilder.model(.box([0.0130, 0.0050, 0.0022]),
                                      Palette.blushPinkDeep, flat: flat,
                                      name: "PortraitMouth")
        mouth.position = [0, -0.0092, 0.0116]
        root.addChild(mouth)

        let teeth = RoomBuilder.model(.box([0.0106, 0.0018, 0.0024]),
                                      Palette.creamLight, flat: flat,
                                      name: "PortraitTeeth")
        teeth.position = [0, -0.0076, 0.0118]
        root.addChild(teeth)

    }

    struct Doorway {
        let root: Entity
        /// **The thing that moves.** The leaf, its
        /// panels and its knob all hang under this, so opening the door is one
        /// rotation about Y — `CONCEPT.md` §9.7's animation budget, spent the
        /// same way Otto's mouth spends it.
        let hinge: Entity
        /// The next room, seen through the opening. Flat against the wall
        /// behind the leaf, so it is only visible while the door stands open —
        /// which is what makes opening it worth doing.
        let glow: ModelEntity
    }

    /// The way out. `GAMEPLAY.md` §6: the door always works, and it is never
    /// disabled and never asks.
    ///
    /// Modelled from `references/props/door.png`: a rose frame, a sandy-wood
    /// leaf, two raised panels and one round butter-yellow knob. Seven boxes
    /// and a prism, counting the light behind it — the panels are the only
    /// detail on it, because
    /// `references/REFERENCES.md` §1 wants fewer and bigger, and because at
    /// this size a moulding is a smudge.
    ///
    /// **The leaf is wood, not the cream of the plate.** The left wall is
    /// `Palette.cream`, so a cream leaf in a rose frame reads as a picture
    /// frame hung on the wall rather than a hole through it. Wood against cream
    /// is the separation the plate did not have to solve, having been rendered
    /// on a grey backdrop.
    static func doorway(flat: Bool) -> Doorway {
        let root = Entity()
        root.name = "Doorway"
        root.position = Layout.doorwayCentre
        // Built in the XY plane extruded along Z; a +90° turn about Y sends its
        // front face down +X, which is the way the left wall looks. So local +X
        // runs towards the back wall and local +Z out into the room.
        root.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

        let open = Layout.doorOpening
        let jamb = Layout.doorFrameWidth
        let depth = Layout.doorFrameDepth
        let leafThickness = Layout.doorLeafThickness

        // The next room: a plate of light standing 1 mm clear of the wall face,
        // deep inside the frame. Clear of it rather than flush, because two
        // coplanar surfaces flicker against each other; behind the leaf, so it
        // is hidden until the door opens.
        let glow = RoomBuilder.model(.box([open.x, open.y, 0.002]),
                                     Palette.butterYellow, flat: flat, name: "DoorwayGlow")
        glow.position = [0, open.y / 2, Layout.doorWallFace + 0.002]
        root.addChild(glow)

        // Frame: two jambs standing on the floor and a lintel across them. It
        // reaches 4 mm back into the wall and stands 12 mm proud of it — a
        // casing chunky enough to have a visible side at this camera, which is
        // most of what stops the door reading as painted on.
        for side: Float in [-1, 1] {
            let post = RoomBuilder.model(.box([jamb, open.y, depth]),
                                         Palette.rose, flat: flat, name: "DoorwayJamb")
            post.position = [side * (open.x + jamb) / 2, open.y / 2, Layout.doorFrameZ]
            root.addChild(post)
        }
        let lintel = RoomBuilder.model(.box([open.x + jamb * 2, jamb, depth]),
                                       Palette.rose, flat: flat, name: "DoorwayLintel")
        lintel.position = [0, open.y + jamb / 2, Layout.doorFrameZ]
        root.addChild(lintel)

        // **The hinge is on the near side**, local -X, which is the corner of
        // the room nearest the camera. A negative turn about Y then swings the
        // leaf into the room with its face coming round *towards* the camera.
        //
        // Hinging it on the back-wall side instead — the first thing tried —
        // swings the leaf away, and at this camera it turns edge-on and reads
        // as a stick standing in a hole. The room has one camera angle
        // (`CONCEPT.md` §9.4), so which edge the hinge is on is a fixed
        // decision with a right answer rather than a preference.
        //
        // The pivot is on the leaf's **back** face, not through its middle: a
        // leaf turning about its own centre line swings its back corner
        // sideways into the jamb, which is 10 mm wide and the nearest thing to
        // the camera in the whole prop. Hinged on the face, every point of the
        // leaf moves out into the room and nothing ever enters the frame.
        let hinge = Entity()
        hinge.name = "DoorHinge"
        hinge.position = [-open.x / 2, 0, Layout.doorLeafZ]
        root.addChild(hinge)

        let leaf = RoomBuilder.model(.box([open.x, open.y, leafThickness]),
                                     Palette.sandyWood, flat: flat, name: "DoorLeaf")
        leaf.position = [open.x / 2, open.y / 2, leafThickness / 2]
        hinge.addChild(leaf)

        // Two panels, raised rather than recessed: a raised box catches the key
        // light on its own facets, and a recess would need the occlusion this
        // style does not have.
        let inset: Float = 0.014
        let panel = SIMD2<Float>(open.x - inset * 2, (open.y - inset * 3) / 2)
        for side: Float in [-1, 1] {
            let plate = RoomBuilder.model(.box([panel.x, panel.y, 0.002]),
                                          Palette.blushPink, flat: flat, name: "DoorPanel")
            plate.position = [0, side * (panel.y + inset) / 2,
                              leafThickness / 2 + 0.001]
            leaf.addChild(plate)
        }

        // The knob, on the swinging edge — the far one, since the hinge took
        // the near one. An 8-sided prism laid on its side reads round from the
        // room's one camera angle and costs 8 facets.
        let knob = RoomBuilder.model(.prism(radius: 0.006, height: 0.007, sides: 8),
                                     Palette.butterYellow, flat: flat, name: "DoorKnob")
        knob.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        knob.position = [open.x / 2 - 0.013, 0, leafThickness / 2]
        leaf.addChild(knob)

        // Architecture against the wall, so its cast shadow could only ever
        // print the door onto the plaster beside it — a hard dark echo, not
        // grounding. Kept from the shadow pass, and it has to stay last: it
        // walks the children that exist when it is called, so a part added
        // after this line would quietly start casting.
        //
        // **The one part with a case for casting is the leaf**, which is the
        // only piece that leaves the wall — but it leaves it towards the wall's
        // own plaster, so what it would print is the same stain the rule
        // exists to stop. Worth an eye on device, not a change made blind.
        root.excludeFromShadowCasting()

        return Doorway(root: root, hinge: hinge, glow: glow)
    }
}
