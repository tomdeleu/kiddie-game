import RealityKit
import simd

/// The garden's props, built from the plates in
/// [`references/garden/`](../../../../references/garden/).
///
/// Same rule as everywhere else: **generate images for reference, model the
/// geometry** (`references/props/README.md`). Every shape here is a
/// `FacetedMesh` primitive through `RoomBuilder.model`, so the debug panel's
/// flat/smooth A/B still answers for all of it.
///
/// **The ripe plant carries the kitchen's own ingredient**, which is the single
/// biggest saving in the room and also the best thing about it: what she picks
/// off the plant and what she drops in the bowl are literally the same object,
/// four of them modelled in Blender. `KitchenProps.token` builds all eight.
enum GardenProps {

    /// The room's fixed camera sits on the +X+Z diagonal, so anything with a
    /// flat front is turned this far to face it. A constant, not a billboard —
    /// nothing ever moves the camera (`CONCEPT.md` §9.4).
    static let towardsCamera = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])

    // MARK: - Seeds

    /// **A jar of seeds on the shelf**, one per ingredient.
    ///
    /// `references/garden/seed-jar.png` came back as *glass*, showing the seeds
    /// through the side — which is a good drawing and the wrong prop.
    /// `references/REFERENCES.md` §1 rules out transparency outright, and the
    /// only transparent thing in the game is the kitchen's running water,
    /// which is an explicit exception for a substance that has no other read.
    ///
    /// `roombox.png` drew the same jars opaque and tinted, and that is the
    /// version that ships: the body takes the ingredient's own colour, so the
    /// eight are told apart the way the six shelf jars in the kitchen are — by
    /// hue and nothing else. It is the props README's rule one step sharper: a
    /// plate cannot answer a question about the room it is not standing in, and
    /// the studio plate reached for glass because it had no room to be legible
    /// in.
    /// **It is a flower pot, not a kitchen jar** —
    /// `references/garden/potting-bench.png` draws them as tapered pots with
    /// domed knobbed lids, and that is worth taking rather than reusing the
    /// straight-sided prism the kitchen's shelf jars are. The kitchen's jars are
    /// kitchen jars; the garden's are plant pots, and two rooms whose containers
    /// differ only in colour would be one room twice.
    static func seedJar(_ ingredient: Ingredient, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "SeedJar_\(ingredient.rawValue)"

        let body = RoomBuilder.model(.taperedPrism(bottomRadius: 0.0072,
                                                   topRadius: 0.0098,
                                                   height: 0.018, sides: 8),
                                     ingredient.tokenColour, flat: flat, name: "JarBody")
        root.addChild(body)

        // A lid a shade wider than the pot's mouth, so its rim catches the key
        // light and the two read as separate parts. Cream on every one of them —
        // with eight in a row the lid is what makes them a set and the body is
        // what makes them different.
        let lid = RoomBuilder.model(.lathe(profile: [[0.0110, 0],
                                                      [0.0106, 0.0026],
                                                      [0.0072, 0.0050],
                                                      [0, 0.0058]],
                                            sides: 8),
                                    Palette.creamLight, flat: flat, name: "JarLid")
        lid.position = [0, 0.018, 0]
        root.addChild(lid)

        // The knob, which is what makes it a lid rather than a cap.
        let knob = RoomBuilder.model(.prism(radius: 0.0022, height: 0.0032, sides: 6),
                                     Palette.creamLight, flat: flat, name: "JarKnob")
        knob.position = [0, 0.0236, 0]
        root.addChild(knob)

        return root
    }

    /// The seed she carries from a jar to a hole.
    ///
    /// A small pointed pip, the shape the plate's jar is full of: widest below
    /// the middle, coming to a point at the top. Deliberately not a sphere — a
    /// ball at this size is a crumb, and the point is what says *seed*.
    static func seedToken(_ ingredient: Ingredient, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Seed_\(ingredient.rawValue)"
        let pip = RoomBuilder.model(.lathe(profile: [[0, 0],
                                                     [0.0032, 0.0014],
                                                     [0.0046, 0.0040],
                                                     [0.0038, 0.0072],
                                                     [0, 0.0098]],
                                           sides: 7),
                                    ingredient.tokenColour, flat: flat, name: "SeedBody")
        root.addChild(pip)
        return root
    }

    // MARK: - Plants

    /// **A plant at one of its four stages**, standing in a hole.
    ///
    /// The four stages are one object growing rather than four objects, which is
    /// what makes watering read as growth: the mound is always there, the stem
    /// gets taller, the leaves multiply, and the fruit arrives last.
    ///
    /// | stage | what she sees | plate |
    /// |---|---|---|
    /// | 0 | a mound of turned earth, just sown | — |
    /// | 1 | a short stem and two leaves | `sprout-early.png` |
    /// | 2 | a taller stem, a rosette, and a **bud in the seed's own colour** | `sprout-half.png` |
    /// | 3 | the rosette, a stalk, and the ingredient itself | `plant-*.png` |
    ///
    /// **The bud at stage 2 is tinted, and that is a gameplay decision rather
    /// than a decoration.** The plate drew it pink; making it the seed's colour
    /// means she can tell what each of the five holes is going to give her one
    /// whole stage before it ripens, which turns the third watering sweep from a
    /// chore into an answer to a question she has already asked.
    static func plant(_ ingredient: Ingredient, growth: Int, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Plant_\(ingredient.rawValue)_\(growth)"

        // **The ripe stage is modelled in Blender**, one file per ingredient,
        // from the eight `plant-*.png` plates. See `ripePlantModel` for what
        // that buys and for the one ingredient it does not cover.
        //
        // Only the ripe stage: stages 0–2 are `sprout-early.png` and
        // `sprout-half.png`, which the vocabulary says perfectly well, and the
        // model's mound is `garden.MOUND_*` — the same dome, the same nine
        // sides — so the last sweep of the can grows a head rather than moving
        // the earth.
        if growth >= GardenLayout.ripeStage, flat,
           let modelled = ripePlantModel(ingredient) {
            root.addChild(modelled)
            return root
        }

        // The turned earth every stage stands in. A faceted dome, not a cone:
        // `sprout-early.png` is emphatic about it, and a cone reads as a
        // molehill — which this room also has, eleven centimetres away.
        let mound = RoomBuilder.model(.dome(radius: 0.0125, height: 0.0055,
                                            sides: 9, rings: 2),
                                      Palette.woodBrown, flat: flat, name: "PlantMound")
        root.addChild(mound)
        guard growth > 0 else { return root }

        let stemHeight: Float = growth == 1 ? 0.014 : 0.026
        let stem = RoomBuilder.model(.taperedPrism(bottomRadius: 0.0016,
                                                   topRadius: 0.0012,
                                                   height: stemHeight, sides: 5),
                                     Palette.sageDeep, flat: flat, name: "PlantStem")
        stem.position = [0, 0.0045, 0]
        root.addChild(stem)

        // Two leaves in a V at stage 1, a rosette of six from stage 2 —
        // `sprout-half.png`'s splay, which is what makes the plant look like it
        // has been growing rather than like it has been scaled up.
        let leafCount = growth == 1 ? 2 : 6
        let leafLength: Float = growth == 1 ? 0.0085 : 0.0135
        let tilt: Float = growth == 1 ? 0.55 : 1.15   // radians from upright
        for i in 0..<leafCount {
            let leaf = RoomBuilder.model(leafShape(length: leafLength),
                                         i.isMultiple(of: 2) ? Palette.sage : Palette.mint,
                                         flat: flat, name: "PlantLeaf\(i)")
            let around = Float(i) / Float(leafCount) * 2 * .pi
            leaf.orientation = simd_quatf(angle: around, axis: [0, 1, 0])
                * simd_quatf(angle: tilt, axis: [1, 0, 0])
            leaf.position = [0, 0.0045 + stemHeight * (growth == 1 ? 0.85 : 0.30), 0]
            root.addChild(leaf)
        }

        if growth < GardenLayout.ripeStage {
            guard growth >= 2 else { return root }
            // The closed bud, in the seed's colour. Two shallow cones meeting at
            // their widest, which is the plate's pointed pod without needing a
            // profile of its own.
            let bud = RoomBuilder.model(.lathe(profile: [[0, 0],
                                                          [0.0042, 0.0028],
                                                          [0.0050, 0.0062],
                                                          [0.0030, 0.0104],
                                                          [0, 0.0128]],
                                                sides: 6),
                                        ingredient.tokenColour, flat: flat, name: "PlantBud")
            bud.position = [0, 0.0045 + stemHeight, 0]
            root.addChild(bud)
            return root
        }

        // **Ripe: the ingredient itself, on the end of the stem.**
        //
        // `plant-aardbei.png` hangs the berry off an arched stalk leaning out of
        // the rosette, and every other plate stands its fruit straight up. The
        // difference is worth keeping — a strawberry that hangs and a blueberry
        // that stands are two silhouettes rather than one — so the heavy fruit
        // leans and the light ones do not.
        let head = KitchenProps.token(ingredient, flat: flat)
        head.name = "PlantFruit"
        let lean = ingredient.hangsOnTheStalk
        head.position = [lean ? 0.0105 : 0, 0.0045 + stemHeight + (lean ? 0.001 : 0.004),
                         lean ? 0.0035 : 0]
        root.addChild(head)

        // **The sunflower collar, for the one ingredient that has no plant.**
        //
        // Honey has no shape of its own, which is the problem the kitchen solved
        // by putting it in a pot and letting the pot be the object. A pot does
        // not grow, so `plant-honing.png` asks the same question one level up
        // and answers it the same way: the pot *is* the flower head, ringed by a
        // collar of flat yellow petals, and the collar is the whole of what
        // makes a jar on a stem read as a thing that grew there.
        if ingredient == .honing {
            for i in 0..<8 {
                let around = Float(i) / 8 * 2 * .pi
                let petal = RoomBuilder.model(.prism(radius: 0.0052, height: 0.0022,
                                                     sides: 6),
                                              Palette.butterYellow, flat: flat,
                                              name: "HoneyPetal\(i)")
                petal.position = [cos(around) * 0.0132,
                                  0.0045 + stemHeight + 0.0050,
                                  sin(around) * 0.0132]
                root.addChild(petal)
            }
        }

        if lean {
            // The arched stalk that carries it out. Three short segments rather
            // than a curve: `FacetedMesh` has no bend, and at 10 mm three
            // straight pieces read as an arch and a smooth one would read as
            // nothing at all.
            for (i, step) in [SIMD3<Float>(0.0012, 0.0090, 0.0004),
                              SIMD3<Float>(0.0055, 0.0126, 0.0018),
                              SIMD3<Float>(0.0096, 0.0122, 0.0032)].enumerated() {
                let piece = RoomBuilder.model(.box([0.0055, 0.0016, 0.0016]),
                                              Palette.sageDeep, flat: flat,
                                              name: "PlantStalk\(i)")
                piece.orientation = simd_quatf(angle: Float(i) * -0.55 + 0.9,
                                               axis: [0, 0, 1])
                piece.position = [step.x, 0.0045 + stemHeight * 0.55 + step.y, step.z]
                root.addChild(piece)
            }
        }
        return root
    }

    /// **Mound, rosette, stem and head, modelled in Blender** — one file per
    /// ingredient, built from that ingredient's own `plant-*.png` plate by
    /// `models/plant-*.py`. `nil` means there is no such file, and the caller
    /// falls back to the code-built plant above.
    ///
    /// Three things the plates ask for that `FacetedMesh` cannot say, and they
    /// are why these went to Blender at all:
    ///
    /// - **The fold.** Every plate creases its leaves down the midrib, and
    ///   `.extrude` makes a slab with one front face and one tone. The code
    ///   version paints alternate leaves `sage` and `mint` to compensate — a
    ///   tint standing in for a shape. With a real fold the facets do it, so
    ///   every leaf in these models is one colour, which is also what the
    ///   plates show. It is the clover's argument from `models/README.md`, now
    ///   applying to thirty leaves in a bed rather than to four petals.
    /// - **The bend.** `plant-aardbei.png` hangs its berry off an arched stalk
    ///   and `plant-klaver.png` grows two curved stems out of one crown. There
    ///   is no bend in the vocabulary: the code fakes the first with three
    ///   rotated boxes and cannot attempt the second.
    /// - **Contact shading.** The join where a fruit sits on a stem, where six
    ///   leaves crowd a hub, and where a cloud's lobes push into each other are
    ///   all joins no facet can shade — both surfaces face outwards and come
    ///   back the same tone. `lowpoly.bake_ao_facets` measures them at model
    ///   time and `ModelLibrary` paints the result a step darker.
    ///
    /// **`bosbes` has no model**, and its plant is still the code-built one. It
    /// was not in the batch that was asked for; `references/garden/`
    /// has the plate, and `models/plant-wolkenroom.py` is the shape of the
    /// script it needs. Until then one of the five holes in the bed grows a
    /// plant built the other way, which is visible if you look for it — its
    /// leaves alternate two greens where the other seven are one.
    private static func ripePlantModel(_ ingredient: Ingredient) -> Entity? {
        let head: [String: UIColorLike]
        switch ingredient {
        case .aardbei:
            head = ["BerryBody": Palette.rose, "BerryLeaf": Palette.sage]
        case .honing:
            head = ["HoningPot": Palette.cream,
                    "HoningRand": Palette.creamLight,
                    "HoningVulling": Palette.honeyAmber,
                    "HoningBlad": Palette.butterYellow,
                    "HoningStok": Palette.sandyWood,
                    "HoningKop": Palette.sandyWood]
        case .klaver:
            head = ["KlaverBlad": Palette.sage]
        case .maanstof:
            head = ["MaanstofPeul": Palette.lilac,
                    "MaanstofKroon": Palette.creamLight,
                    "MaanstofOpening": Palette.lilacDeep]
        case .sterrensuiker:
            head = ["SterBody": Palette.mintLight]
        case .veertje:
            head = ["VeertjeBlad": Palette.creamLight,
                    "VeertjeSchacht": Palette.cream]
        case .wolkenroom:
            head = ["RoomBol": Palette.cream, "RoomBolTop": Palette.creamLight]
        case .bosbes:
            return nil
        }
        return ModelLibrary.load("plant-\(ingredient.rawValue)",
                                 tint: plantTint.merging(head) { _, model in model })
    }

    /// What every plant model has below its head. The head's own colours are
    /// merged over this, and nothing in either map is a prefix of anything in
    /// the other — `ModelLibrary.load` matches longest first, so a collision
    /// would be silent.
    private static let plantTint: [String: UIColorLike] = [
        "PlantMound": Palette.woodBrown,
        "PlantLeaf": Palette.sage,
        "PlantStem": Palette.sageDeep,
        "PlantStalk": Palette.sageDeep,
    ]

    /// A flat pointed leaf lying in the XY plane, length along +Y. One outline,
    /// scaled, for every leaf in the room — the plates all draw the same lance.
    private static func leafShape(length: Float) -> RoomBuilder.Shape {
        let w = length * 0.34
        return .extrude(outline: [[0, 0],
                                  [w * 0.55, length * 0.28],
                                  [w, length * 0.62],
                                  [w * 0.62, length * 0.90],
                                  [0, length],
                                  [-w * 0.62, length * 0.90],
                                  [-w, length * 0.62],
                                  [-w * 0.55, length * 0.28]],
                        thickness: 0.0012)
    }

    // MARK: - The watering can

    struct WateringCan {
        let root: Entity
        /// The rose on the end of the spout. **The point the bed is measured
        /// against** — watering asks where the water lands, not where the can
        /// is, and the two are 30 mm apart, which is most of the gap between one
        /// hole and the next.
        let rose: Entity
        /// Hangs from the rose, grown down its Y axis to start the pour.
        let stream: ModelEntity
    }

    /// From `references/garden/watering-can.png`: an eight-sided body **wider at
    /// the bottom than the top**, a loop handle standing over the mouth, a
    /// D-handle at the back, and a straight spout leaving low down and rising to
    /// a faceted rose.
    ///
    /// It is mint rather than the plate's blush, because `roombox.png` put a
    /// mint can in a room with a rose bed and that is the separation the studio
    /// plate had no room to find — the same call the door's leaf made.
    static func wateringCan(flat: Bool) -> WateringCan {
        let root = Entity()
        root.name = "WateringCan"

        let body = RoomBuilder.model(.taperedPrism(bottomRadius: 0.0215,
                                                   topRadius: 0.0165,
                                                   height: 0.030, sides: 8),
                                     Palette.mint, flat: flat, name: "CanBody")
        root.addChild(body)

        // The mouth: a shallow ring on top, so the can has an inside. A flat lid
        // would make it a pot.
        let mouth = RoomBuilder.model(.annulus(innerRadius: 0.0088,
                                               outerRadius: 0.0165, segments: 8),
                                      Palette.mintLight, flat: flat, name: "CanMouth")
        mouth.position = [0, 0.030, 0]
        root.addChild(mouth)

        // The loop handle over the top, five straight segments on an arc. Its
        // plane runs along X so it is seen broadside from the camera.
        for i in 0..<5 {
            let t = Float(i) / 4
            let angle = .pi * t
            let piece = RoomBuilder.model(.box([0.0125, 0.0042, 0.0042]),
                                          Palette.mintLight, flat: flat,
                                          name: "CanHandle\(i)")
            piece.position = [-cos(angle) * 0.0130, 0.0300 + sin(angle) * 0.0150, 0]
            piece.orientation = simd_quatf(angle: -angle + .pi / 2, axis: [0, 0, 1])
            root.addChild(piece)
        }

        // The back D-handle, which is what says *can* rather than *jug* at
        // thumbnail size.
        let grip = RoomBuilder.model(.box([0.0044, 0.0165, 0.0044]),
                                     Palette.mintLight, flat: flat, name: "CanGrip")
        grip.position = [-0.0250, 0.0175, 0]
        root.addChild(grip)
        for side: Float in [-1, 1] {
            let arm = RoomBuilder.model(.box([0.0075, 0.0042, 0.0042]),
                                        Palette.mintLight, flat: flat, name: "CanGripArm")
            arm.position = [-0.0215, 0.0175 + side * 0.0082, 0]
            root.addChild(arm)
        }

        // The spout: one straight bar leaving the body low and rising. Mitred
        // rather than curved, which is the sink tap's lesson — a hard angle is
        // in the vocabulary and a bend is not.
        let spout = RoomBuilder.model(.box([0.0330, 0.0072, 0.0072]),
                                      Palette.mint, flat: flat, name: "CanSpout")
        spout.orientation = simd_quatf(angle: 0.42, axis: [0, 0, 1])
        spout.position = [0.0300, 0.0135, 0]
        root.addChild(spout)

        let rose = Entity()
        rose.name = "CanRose"
        rose.position = [0.0455, 0.0205, 0]
        root.addChild(rose)

        let face = RoomBuilder.model(.prism(radius: 0.0092, height: 0.0038, sides: 8),
                                     Palette.mintLight, flat: flat, name: "CanRoseFace")
        face.orientation = simd_quatf(angle: .pi / 2 - 0.42, axis: [0, 0, 1])
        rose.addChild(face)

        // The water, hanging from the rose and grown down Y — the pour stream
        // from the kitchen, which already narrows at the lip, swells as it
        // falls, and turns about its own axis so its facets travel.
        let stream = KitchenProps.pourStream(colour: Palette.berryBlue,
                                             length: 0.030, flat: flat)
        stream.name = "CanStream"
        stream.isEnabled = false
        rose.addChild(stream)

        return WateringCan(root: root, rose: rose, stream: stream)
    }

    // MARK: - The basket

    struct Basket {
        let root: Entity
        /// Where a picked ingredient lands. A child so the contents ride with
        /// the basket if it is ever carried.
        let contents: Entity
    }

    /// From `references/garden/harvest-basket.png`: a **square** tapered tub,
    /// sandy body, a mint band round the rim, a rose lining, and an arched
    /// handle of chunky straight segments.
    ///
    /// Square rather than round on the plate's say-so, and it earns it: the
    /// kitchen already has a round basket on the table, and two baskets in one
    /// game had better not be the same object in two colours.
    static func basket(flat: Bool) -> Basket {
        let root = Entity()
        root.name = "HarvestBasket"

        let tub = RoomBuilder.model(.bowl(bottomRadius: 0.0180, topRadius: 0.0290,
                                          height: 0.0245, wallThickness: 0.0030,
                                          floorThickness: 0.0030, sides: 4, rings: 2),
                                    Palette.sandyWood, flat: flat, name: "BasketTub")
        tub.orientation = towardsCamera
        root.addChild(tub)

        let rim = RoomBuilder.model(.annulus(innerRadius: 0.0262,
                                             outerRadius: 0.0320, segments: 4),
                                    Palette.mint, flat: flat, name: "BasketRim")
        rim.orientation = towardsCamera
        rim.position = [0, GardenLayout.basketRimY, 0]
        root.addChild(rim)

        // The handle, seven segments on a half-circle standing along X.
        for i in 0..<7 {
            let angle = .pi * Float(i) / 6
            let piece = RoomBuilder.model(.box([0.0110, 0.0050, 0.0050]),
                                          Palette.creamLight, flat: flat,
                                          name: "BasketHandle\(i)")
            piece.position = [-cos(angle) * 0.0250,
                              GardenLayout.basketRimY + sin(angle) * 0.0235, 0]
            piece.orientation = simd_quatf(angle: -angle + .pi / 2, axis: [0, 0, 1])
            root.addChild(piece)
        }

        let contents = Entity()
        contents.name = "BasketContents"
        contents.position = [0, 0.0090, 0]
        root.addChild(contents)

        return Basket(root: root, contents: contents)
    }

    // MARK: - Toys

    /// One of the five chiming flowers: a stem, two leaves, a ring of six flat
    /// petals and a chunky raised centre. `references/garden/flower-row.png`.
    ///
    /// Heights differ down the row because the row is a scale, and a scale you
    /// can see is easier to learn than one you can only hear.
    static func flower(petal: UIColorLike, centre: UIColorLike,
                       height: Float, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Flower"

        let stem = RoomBuilder.model(.box([0.0032, height, 0.0032]),
                                     Palette.sage, flat: flat, name: "FlowerStem")
        stem.position = [0, height / 2, 0]
        root.addChild(stem)

        for side: Float in [-1, 1] {
            let leaf = RoomBuilder.model(leafShape(length: 0.0095),
                                         Palette.sageDeep, flat: flat, name: "FlowerLeaf")
            leaf.position = [0, height * 0.34, 0]
            leaf.orientation = simd_quatf(angle: side * .pi / 2, axis: [0, 1, 0])
                * simd_quatf(angle: 1.25, axis: [1, 0, 0])
            root.addChild(leaf)
        }

        // Six petals round a hub, each a flat hexagonal chip — the plate makes
        // the petals chips rather than pointed, and that is what stops five
        // flowers in a row reading as five stars.
        for i in 0..<6 {
            let around = Float(i) / 6 * 2 * .pi
            let chip = RoomBuilder.model(.prism(radius: 0.0058, height: 0.0026, sides: 6),
                                         petal, flat: flat, name: "FlowerPetal\(i)")
            chip.position = [cos(around) * 0.0082, height, sin(around) * 0.0082]
            root.addChild(chip)
        }
        let eye = RoomBuilder.model(.prism(radius: 0.0050, height: 0.0040, sides: 6),
                                    centre, flat: flat, name: "FlowerCentre")
        eye.position = [0, height + 0.0006, 0]
        root.addChild(eye)

        return root
    }

    struct Molehill {
        let root: Entity
        /// Mo. Below the ground until she taps the hill.
        let mole: Entity
    }

    /// `references/garden/molehill.png`: a wide faceted hill of loose earth with
    /// a round head, two dot eyes and a **pink nose**, which is the whole
    /// character and the only part that has to read at 20 mm.
    ///
    /// **Modelled in Blender**, `models/molehill.py`, and it fixed a real bug
    /// rather than only improving a shape. `tapMolehill` lifts Mo to y = 0.0135;
    /// in the code-built version his head sits at his pivot's own origin with a
    /// radius of 0.0092 against a hill 0.0195 high, so at full pop the head
    /// cleared the earth by 3.2 mm and the nose — which hangs 1.6 mm *below* the
    /// head's centre — never came up at all. The toy was a grey sliver.
    ///
    /// The model builds Mo 11.2 mm up his own pivot, so the room's two tween
    /// positions are untouched: they are gameplay numbers that have been played
    /// against, and what was wrong was the thing they were moving. The plate's
    /// two **paws** resting on the earth are here too, and the hill has the
    /// plate's convex profile instead of a straight taper.
    static func molehill(flat: Bool) -> Molehill {
        if flat, let modelled = ModelLibrary.load(
                "molehill",
                tint: ["HillEarth": Palette.woodBrown,
                       "MoleHead": moleGrey,
                       "MolePaw": moleGrey,
                       "MoleNose": Palette.blushPink,
                       "MoleEye": Palette.ovenInside]),
           let mole = group("Mole", in: modelled) {
            let root = Entity()
            root.name = "Molehill"
            root.addChild(modelled)
            return Molehill(root: root, mole: mole)
        }
        return proceduralMolehill(flat: flat)
    }

    private static let moleGrey = Palette.mix(Palette.creamLight,
                                              Palette.woodBrown, 0.45)

    /// **Put every mesh whose name starts with `prefix` on one upright pivot.**
    ///
    /// `ModelLibrary.pivot` matches a single part by its exact name, and Mo is
    /// six of them — a head, a nose, two eyes and two paws — that have to rise
    /// out of the hill together. The pivot is a plain entity parented to the
    /// loaded wrapper and therefore world-aligned, which is the thing that
    /// matters: everything inside a loaded prop hangs under the exporter's
    /// Z-up-to-Y-up rotation, so a child's local Y is the world's Z, and
    /// `tapMolehill` drives Mo by nudging Y.
    ///
    /// It lives here rather than next to `ModelLibrary.pivot` because it is
    /// De Tuin's problem and `ModelLibrary` is shared with two other rooms.
    ///
    /// Returns `nil` if nothing matched, which is the caller's cue to fall back
    /// rather than animate an empty holder.
    private static func group(_ prefix: String, in wrapper: Entity) -> Entity? {
        var family: [ModelEntity] = []
        collect(prefix, in: wrapper, into: &family)
        guard !family.isEmpty else { return nil }

        let holder = Entity()
        holder.name = prefix
        wrapper.addChild(holder)
        for part in family {
            part.setParent(holder, preservingWorldTransform: true)
        }
        return holder
    }

    private static func collect(_ prefix: String, in entity: Entity,
                                into found: inout [ModelEntity]) {
        if let model = entity as? ModelEntity, model.model != nil,
           model.name.hasPrefix(prefix) {
            found.append(model)
        }
        for child in entity.children {
            collect(prefix, in: child, into: &found)
        }
    }

    /// The code-built molehill. See `molehill(flat:)` for when it runs — and
    /// note that Mo is buried in this one at the room's own pop height.
    private static func proceduralMolehill(flat: Bool) -> Molehill {
        let root = Entity()
        root.name = "Molehill"

        let hill = RoomBuilder.model(.taperedPrism(bottomRadius: 0.0270,
                                                   topRadius: 0.0092,
                                                   height: 0.0195, sides: 10),
                                     Palette.woodBrown, flat: flat, name: "MolehillEarth")
        root.addChild(hill)

        // Mo lives inside the hill and rises out of the top. Parented to a
        // pivot so the pop is one position tween on one entity.
        let mole = Entity()
        mole.name = "Mole"
        mole.position = [0, 0.0060, 0]
        root.addChild(mole)

        let head = RoomBuilder.model(.icosphere(radius: 0.0092, subdivisions: 1),
                                     Palette.mix(Palette.creamLight, Palette.woodBrown, 0.45),
                                     flat: flat, name: "MoleHead")
        mole.addChild(head)

        let nose = RoomBuilder.model(.icosphere(radius: 0.0040, subdivisions: 0),
                                     Palette.blushPink, flat: flat, name: "MoleNose")
        nose.position = [0.0052, -0.0016, 0.0052]
        mole.addChild(nose)

        for side: Float in [-1, 1] {
            let eye = RoomBuilder.model(.prism(radius: 0.0013, height: 0.0012, sides: 6),
                                        Palette.ovenInside, flat: flat, name: "MoleEye")
            eye.orientation = towardsCamera * simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            eye.position = [0.0052 + side * 0.0020, 0.0030, 0.0052 - side * 0.0020]
            mole.addChild(eye)
        }
        return Molehill(root: root, mole: mole)
    }

    /// `references/garden/butterfly.png`: a segmented body, two straight
    /// antennae, and four flat angular wings — a big upper and a smaller lower
    /// on each side.
    ///
    /// Built lying in the XZ plane, seen from above, because that is how it is
    /// seen when it is flying and it never lands.
    static func butterfly(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Butterfly"

        let body = RoomBuilder.model(.lathe(profile: [[0, -0.0090],
                                                       [0.0026, -0.0050],
                                                       [0.0032, 0.0030],
                                                       [0.0022, 0.0082],
                                                       [0, 0.0100]],
                                             sides: 6),
                                     Palette.rose, flat: flat, name: "ButterflyBody")
        body.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        root.addChild(body)

        for side: Float in [-1, 1] {
            let upper = RoomBuilder.model(.extrude(outline: [[0, 0],
                                                              [0.0165, 0.0060],
                                                              [0.0180, 0.0135],
                                                              [0.0075, 0.0125],
                                                              [0.0015, 0.0055]],
                                                    thickness: 0.0011),
                                          Palette.blushPink, flat: flat, name: "WingUpper")
            upper.scale = [side, 1, 1]
            upper.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            upper.position = [0, 0, -0.0010]
            root.addChild(upper)

            let lower = RoomBuilder.model(.extrude(outline: [[0, 0],
                                                              [0.0120, -0.0035],
                                                              [0.0135, -0.0105],
                                                              [0.0060, -0.0120],
                                                              [0.0012, -0.0050]],
                                                    thickness: 0.0011),
                                          Palette.creamLight, flat: flat, name: "WingLower")
            lower.scale = [side, 1, 1]
            lower.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            lower.position = [0, 0, 0.0010]
            root.addChild(lower)

            let antenna = RoomBuilder.model(.box([0.0075, 0.0011, 0.0011]),
                                            Palette.rose, flat: flat, name: "Antenna")
            antenna.orientation = simd_quatf(angle: side * 0.6, axis: [0, 1, 0])
            antenna.position = [side * 0.0030, 0, -0.0125]
            root.addChild(antenna)
        }
        return root
    }

    /// `references/garden/bee.png`: a round faceted body in broad bands, two
    /// small pale wings and two knobbed antennae. Chunky and nearly spherical —
    /// the plate refuses to make it insect-shaped, which is right for four.
    static func bee(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Bee"

        // Five bands stacked as one lathe would give one colour, so they are
        // five short prisms — the only way to get the stripes without a texture.
        let radii: [Float] = [0.0058, 0.0088, 0.0092, 0.0078, 0.0046]
        for (i, radius) in radii.enumerated() {
            let band = RoomBuilder.model(.prism(radius: radius, height: 0.0042, sides: 8),
                                         i.isMultiple(of: 2) ? Palette.woodBrown
                                                             : Palette.butterYellow,
                                         flat: flat, name: "BeeBand\(i)")
            band.position = [0, -0.0105 + Float(i) * 0.0042, 0]
            root.addChild(band)
        }

        for side: Float in [-1, 1] {
            let wing = RoomBuilder.model(.extrude(outline: [[0, 0],
                                                             [0.0105, 0.0028],
                                                             [0.0125, -0.0012],
                                                             [0.0090, -0.0048],
                                                             [0.0015, -0.0032]],
                                                   thickness: 0.0010),
                                         Palette.creamLight, flat: flat, name: "BeeWing")
            wing.scale = [side, 1, 1]
            wing.position = [side * 0.0070, 0.0030, 0]
            wing.orientation = simd_quatf(angle: side * -0.35, axis: [0, 1, 0])
            root.addChild(wing)

            let antenna = RoomBuilder.model(.box([0.0011, 0.0060, 0.0011]),
                                            Palette.woodBrown, flat: flat, name: "BeeAntenna")
            antenna.position = [side * 0.0030, 0.0115, -0.0020]
            antenna.orientation = simd_quatf(angle: side * 0.3, axis: [0, 0, 1])
            root.addChild(antenna)
        }
        return root
    }

    /// `references/garden/pond.png`: a ring of chunky faceted stones round a
    /// shallow pool that **steps down** in four bands, palest at the rim and
    /// deepest in the middle.
    ///
    /// **It replaced two puddles**, owner's call 2026-08-16, and then it was
    /// rebuilt bigger the same day: *"the pond must be bigger and totally at the
    /// bottom"*. So it is an **ellipse** — 196 × 116 mm, `GardenLayout.pondLong`
    /// and `pondShort` — lying along the front edge of the lawn rather than the
    /// 122 mm circle it started as.
    ///
    /// **Built with +X as the long axis, and turned by the room.** `GardenRoom`
    /// gives the root `towardsCamera`, which lands the long axis on the X−Z
    /// diagonal — the one direction that is exactly screen-horizontal from this
    /// chair. Building it pre-turned would bake the camera into the prop.
    ///
    /// **The steps go down without a hole in the floor.** The obvious build —
    /// sinking the water below `floorY` — cannot work: the floor is a solid box
    /// and anything inside it is simply hidden. So the whole basin stands *on*
    /// the grass and the stones stand around it, five to seven millimetres
    /// proud of the water, and what she looks into is the rim rather than the
    /// ground.
    ///
    /// **Opaque, like the puddle was**, and the plate is right about it. Still
    /// water seen from above against one flat ground colour has nothing behind
    /// it for transparency to reveal — `references/REFERENCES.md` §1's
    /// no-transparency rule only ever had one exception, and it was for running
    /// water, which has no other read.
    ///
    /// **The stones are `creamLight`, not the studio plate's sandy ones.** Same
    /// call the seed jar and the watering can already made in this room: the
    /// studio plate is shot on grey and cannot be asked what the prop stands
    /// next to, and `roombox-v3-pond.png` — which can — came back with a pale
    /// near-white rim on the mint lawn. Sandy stones beside a sandy bench and a
    /// brown soil bed would be a third brown.
    static func pond(long: Float, short: Float, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Pond"

        // The stones straddle the water's edge, so both are inset from the
        // footprint the room reserves: the ring by a stone's radial half-extent,
        // the water by that again less the 7 mm of overlap that stops a sliver
        // of grass showing between the rim and the pool.
        let stoneHalf: Float = 0.011
        let ringLong = long - stoneHalf
        let ringShort = short - stoneHalf
        // **One aspect for everything.** Water bands are lathed round and then
        // squashed on Z by this, which keeps every ellipse in the prop similar
        // to every other — an oval pond with a round pool in it reads as two
        // objects.
        let squash = ringShort / ringLong
        let waterLong = ringLong - 0.007

        // Outside in: each band's top sits 1.4 mm below its neighbour's, so the
        // wall between them is a real face that catches its own light. A washer
        // is a lathe rather than a prism because a prism is solid — a smaller
        // prism inside a taller one is buried, not nested.
        let bands: [(outer: Float, inner: Float, top: Float, colour: UIColorLike)] = [
            (1.000, 0.765, 0.0058, Palette.mix(Palette.berryBlue, Palette.white, 0.55)),
            (0.765, 0.530, 0.0044, Palette.mix(Palette.berryBlue, Palette.white, 0.30)),
            (0.530, 0.320, 0.0030, Palette.berryBlue),
        ]
        for (i, band) in bands.enumerated() {
            let outer = waterLong * band.outer, inner = waterLong * band.inner
            let ring = RoomBuilder.model(.lathe(profile: [[outer, 0],
                                                          [outer, band.top],
                                                          [inner, band.top],
                                                          [inner, 0]],
                                                sides: 10),
                                         band.colour, flat: flat, name: "PondBand\(i)")
            ring.scale = [1, 1, squash]
            root.addChild(ring)
        }
        let deep = RoomBuilder.model(.prism(radius: waterLong * 0.320,
                                            height: 0.0018, sides: 10),
                                     Palette.berryBlueDeep, flat: flat, name: "PondDeep")
        deep.scale = [1, 1, squash]
        root.addChild(deep)

        // **Nineteen stones, spaced by arc length rather than by angle.**
        //
        // On an ellipse those are not the same thing: at the ends of the long
        // axis a given step of angle covers about half the ground it covers at
        // the flanks, so equal angles would bunch the stones at the two tips and
        // leave the sides open. So the perimeter is measured once and walked in
        // equal steps. Odd count on purpose — an even ring reads as two halves
        // from this camera.
        let stoneCount = 19
        let samples = 360
        var arc: [Float] = [0]
        for s in 1...samples {
            let a0 = Float(s - 1) / Float(samples) * 2 * .pi
            let a1 = Float(s) / Float(samples) * 2 * .pi
            let dx = ringLong * (cos(a1) - cos(a0))
            let dz = ringShort * (sin(a1) - sin(a0))
            arc.append(arc[s - 1] + (dx * dx + dz * dz).squareRoot())
        }

        // Sizes are a fixed cycle rather than random: a pond that rebuilds
        // differently every time the flat-shading toggle flips is a pond that
        // moved while she was looking. Five sizes into nineteen places never
        // repeats a pattern round the ring.
        let sizes: [Float] = [0.0118, 0.0106, 0.0112, 0.0102, 0.0110]
        for i in 0..<stoneCount {
            let want = arc[samples] * Float(i) / Float(stoneCount)
            var step = 0
            while step < samples - 1 && arc[step + 1] < want { step += 1 }
            let span = max(arc[step + 1] - arc[step], 1e-6)
            let angle = (Float(step) + (want - arc[step]) / span)
                / Float(samples) * 2 * .pi

            let radius = sizes[i % sizes.count]
            let stone = RoomBuilder.model(.icosphere(radius: radius, subdivisions: 0),
                                          i.isMultiple(of: 2) ? Palette.creamLight
                                                              : Palette.cream,
                                          flat: flat, name: "PondStone\(i)")
            // A squashed boulder, **laid along the ring rather than across it**.
            // That is what keeps the rim a rim, and it is what makes the pond's
            // footprint the 0.95 semi-axis rather than the 1.15 one — which is
            // where the 11 mm inset above comes from.
            //
            // The roll is deliberately tiny. A squashed sphere rolled far enough
            // stands its flat axis up and becomes a tall stone; under 0.07 rad
            // the height it adds is 0.06 mm.
            let tangent = SIMD2<Float>(-ringLong * sin(angle), ringShort * cos(angle))
            let facing = atan2(-tangent.y, tangent.x)
            stone.scale = [1.15, 0.66, 0.95]
            stone.orientation = simd_quatf(angle: facing, axis: [0, 1, 0])
                * simd_quatf(angle: Float(i % 3) * 0.06 - 0.06, axis: [1, 0, 0])
            // Sunk 2.2 mm into the grass, so it sits in the ground rather than
            // resting on it. Tops land at 11–13 mm, five to seven above the
            // water — an uneven rim, which is what a ring of stones is.
            stone.position = [ringLong * cos(angle),
                              radius * 0.66 - 0.0022,
                              ringShort * sin(angle)]
            root.addChild(stone)
        }
        return root
    }

    /// `references/garden/garden-tree.png`: a **cluster** of twelve overlapping
    /// faceted balls on a straight tapered trunk, not one ball. The plate is
    /// emphatic and it is the better shape — a single sphere on a stick is a
    /// lollipop, and the cluster is the same construction `wolkenroom` uses.
    static func tree(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Tree"

        let trunk = RoomBuilder.model(.taperedPrism(bottomRadius: 0.0092,
                                                    topRadius: 0.0072,
                                                    height: 0.052, sides: 6),
                                      Palette.cream, flat: flat, name: "TreeTrunk")
        root.addChild(trunk)

        // Eight lobes on two rings plus a cap. Radii and offsets are fixed
        // rather than random: a tree that rebuilds differently every time the
        // flat-shading toggle flips is a tree that moved while she was looking.
        let lobes: [(SIMD3<Float>, Float)] = [
            ([0, 0.0800, 0], 0.0250),
            ([0.0195, 0.0680, 0.0080], 0.0180),
            ([-0.0165, 0.0700, -0.0100], 0.0195),
            ([0.0070, 0.0665, -0.0195], 0.0170),
            ([-0.0060, 0.0690, 0.0190], 0.0175),
            ([0.0150, 0.0865, -0.0110], 0.0160),
            ([-0.0140, 0.0880, 0.0090], 0.0155),
            ([0.0020, 0.0950, 0.0030], 0.0145),
        ]
        for (i, lobe) in lobes.enumerated() {
            let ball = RoomBuilder.model(.icosphere(radius: lobe.1, subdivisions: 1),
                                         i.isMultiple(of: 2) ? Palette.sage : Palette.mint,
                                         flat: flat, name: "TreeLobe\(i)")
            ball.position = lobe.0
            root.addChild(ball)
        }
        return root
    }

    /// The same cluster, lower and without a trunk.
    static func bush(radius: Float, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Bush"
        let lobes: [(SIMD3<Float>, Float)] = [
            ([0, radius * 0.85, 0], radius),
            ([radius * 0.72, radius * 0.55, radius * 0.20], radius * 0.70),
            ([-radius * 0.62, radius * 0.50, -radius * 0.34], radius * 0.66),
            ([radius * 0.10, radius * 0.48, -radius * 0.74], radius * 0.62),
        ]
        for (i, lobe) in lobes.enumerated() {
            let ball = RoomBuilder.model(.icosphere(radius: lobe.1, subdivisions: 1),
                                         i.isMultiple(of: 2) ? Palette.sage : Palette.sageDeep,
                                         flat: flat, name: "BushLobe\(i)")
            ball.position = lobe.0
            root.addChild(ball)
        }
        return root
    }
}

private extension Ingredient {
    /// **Whether its plant hangs its fruit off an arched stalk.**
    ///
    /// `plant-aardbei.png` is the only plate that leans — its berry swings out
    /// of the rosette on a bent stalk — and every other one stands its fruit
    /// straight up on the stem. The difference is worth keeping rather than
    /// picking one for all eight: a bed where every plant has the same
    /// silhouette is one plant five times, and a strawberry is the fruit a
    /// 4-year-old already knows hangs.
    var hangsOnTheStalk: Bool { self == .aardbei }
}
