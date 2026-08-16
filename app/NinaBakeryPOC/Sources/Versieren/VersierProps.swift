import RealityKit
import simd

/// The decorating room's props, built from the plates in
/// [`references/versieren/`](../../../../references/versieren/README.md).
///
/// Every one of them is `FacetedMesh` primitives, and every one is a plate the
/// facet count was read off rather than guessed: *"~10 sides"* in a plate is
/// directly the argument to `prism`. Blender is deliberately not involved yet —
/// these swap for `models/*.usdz` later the same way the kitchen's ten did, via
/// `ModelLibrary` with a procedural fallback.
@MainActor
enum VersierProps {

    // MARK: - The turntable

    struct Turntable {
        /// Spins. The cake and the sticker layer are its children, which is what
        /// makes turning free.
        let spinner: Entity
        /// Does not spin — the pedestal it stands on.
        let root: Entity
        let handle: Entity
    }

    /// Per `draaitafel.png`: a ~14-sided plate with a visible rim band on a
    /// ~10-sided tapered pedestal, and one square-section handle off the rim.
    static func turntable(flat: Bool) -> Turntable {
        let root = Entity()
        root.name = "Draaitafel"
        root.position = [VersierLayout.turntableCentre.x, 0, VersierLayout.turntableCentre.y]

        let footHeight = VersierLayout.plateY - RoomBox.floorY - VersierLayout.plateThickness
        let foot = RoomBuilder.model(.taperedPrism(bottomRadius: VersierLayout.pedestalRadius,
                                                   topRadius: VersierLayout.pedestalTopRadius,
                                                   height: footHeight, sides: 10),
                                     Palette.sandyWood, flat: flat, name: "DraaitafelVoet")
        foot.position = [0, RoomBox.floorY + footHeight / 2, 0]
        root.addChild(foot)

        // The spinner carries everything that turns: the plate, the cake, and
        // every sticker on it.
        let spinner = Entity()
        spinner.name = "DraaitafelBlad"
        spinner.position = [0, VersierLayout.plateY - VersierLayout.plateThickness, 0]
        root.addChild(spinner)

        let plate = RoomBuilder.model(.prism(radius: VersierLayout.plateRadius,
                                             height: VersierLayout.plateThickness,
                                             sides: 14),
                                      Palette.creamLight, flat: flat, name: "DraaitafelPlaat")
        spinner.addChild(plate)

        // The handle turns with the plate, so where it is *is* the angle. That
        // is the whole readability of the control: she can see how far she has
        // turned it without anything else on screen having to say so.
        let handle = Entity()
        handle.name = "DraaitafelHandvat"
        spinner.addChild(handle)

        let bar = RoomBuilder.model(.box([VersierLayout.handleLength, 0.007, 0.007]),
                                    Palette.rose, flat: flat, name: "DraaitafelStang")
        bar.position = [VersierLayout.plateRadius + VersierLayout.handleLength / 2 - 0.004,
                        VersierLayout.plateThickness / 2, 0]
        handle.addChild(bar)

        let knob = RoomBuilder.model(.prism(radius: 0.010, height: 0.012, sides: 8),
                                     Palette.blushPinkDeep, flat: flat, name: "DraaitafelKnop")
        knob.position = [VersierLayout.plateRadius + VersierLayout.handleLength - 0.008,
                         VersierLayout.plateThickness / 2 + 0.006, 0]
        handle.addChild(knob)

        handle.orientation = simd_quatf(angle: VersierLayout.handleAngle, axis: [0, 1, 0])
        return Turntable(spinner: spinner, root: root, handle: handle)
    }

    // MARK: - The two tools

    struct Spuitzak {
        let root: Entity
        /// The cream inside, Y-scaled to what is left in the bag. She watches it
        /// go down, which is what turns a cap into a thing with an inside.
        let cream: Entity
    }

    /// Per `spuitzak.png`: a ~10-sided tapered cone, a gathered collar with a
    /// tie, an octagonal nozzle collar and a cone tip.
    ///
    /// The plate's fanned crown above the tie is the flour-sack problem again —
    /// cloth is where the `FacetedMesh` vocabulary runs out — so it is one short
    /// flared prism rather than a gather. When this prop goes to Blender, that
    /// is the half worth modelling.
    static func spuitzak(flat: Bool) -> Spuitzak {
        let root = Entity()
        root.name = "Spuitzak"

        let bodyHeight: Float = 0.046
        let body = RoomBuilder.model(.taperedPrism(bottomRadius: 0.006, topRadius: 0.020,
                                                   height: bodyHeight, sides: 10),
                                     Palette.creamLight, flat: flat, name: "SpuitzakBody")
        body.position = [0, 0.016 + bodyHeight / 2, 0]
        root.addChild(body)

        // Inside the bag, and a shade darker so it reads through the mouth.
        let cream = RoomBuilder.model(.taperedPrism(bottomRadius: 0.004, topRadius: 0.016,
                                                   height: bodyHeight - 0.006, sides: 10),
                                      Palette.cream, flat: flat, name: "SpuitzakRoom")
        cream.position = [0, 0.019, 0]
        root.addChild(cream)

        let tie = RoomBuilder.model(.prism(radius: 0.019, height: 0.005, sides: 10),
                                    Palette.mint, flat: flat, name: "SpuitzakBand")
        tie.position = [0, 0.016 + bodyHeight - 0.002, 0]
        root.addChild(tie)

        let crown = RoomBuilder.model(.taperedPrism(bottomRadius: 0.018, topRadius: 0.026,
                                                    height: 0.010, sides: 10),
                                      Palette.cream, flat: flat, name: "SpuitzakKraag")
        crown.position = [0, 0.016 + bodyHeight + 0.006, 0]
        root.addChild(crown)

        let collar = RoomBuilder.model(.prism(radius: 0.008, height: 0.008, sides: 8),
                                       Palette.sage, flat: flat, name: "SpuitzakRing")
        collar.position = [0, 0.012, 0]
        root.addChild(collar)

        let tip = RoomBuilder.model(.taperedPrism(bottomRadius: 0.0012, topRadius: 0.005,
                                                  height: 0.010, sides: 8),
                                    Palette.sageDeep, flat: flat, name: "SpuitzakTuit")
        tip.position = [0, 0.005, 0]
        root.addChild(tip)

        return Spuitzak(root: root, cream: cream)
    }

    /// Per `strooibus.png`: a ~10-sided barrel with a two-part mint cap — a
    /// collar ring and a perforated dome. The perforations are fine detail the
    /// code skips; at 20 mm on screen they are one facet's worth of nothing.
    static func strooibus(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Strooibus"

        let bodyHeight: Float = 0.026
        let body = RoomBuilder.model(.taperedPrism(bottomRadius: 0.013, topRadius: 0.015,
                                                   height: bodyHeight, sides: 10),
                                     Palette.blushPink, flat: flat, name: "StrooibusBody")
        body.position = [0, bodyHeight / 2, 0]
        root.addChild(body)

        let ring = RoomBuilder.model(.prism(radius: 0.016, height: 0.005, sides: 10),
                                     Palette.mint, flat: flat, name: "StrooibusRing")
        ring.position = [0, bodyHeight + 0.002, 0]
        root.addChild(ring)

        let cap = RoomBuilder.model(.dome(radius: 0.014, height: 0.009, sides: 10, rings: 2),
                                    Palette.mintLight, flat: flat, name: "StrooibusDop")
        cap.position = [0, bodyHeight + 0.005, 0]
        root.addChild(cap)

        return root
    }

    // MARK: - A tray, and what stands in it

    /// Per `bakje.png`: a shallow open box with a low rim and a flat inside
    /// floor. Five boxes, and the one mesh is built seven times.
    static func tray(_ kind: StickerKind, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Bakje\(kind.rawValue.capitalized)"

        let size = VersierLayout.traySize
        let h = VersierLayout.trayHeight
        let wall: Float = 0.004

        let floor = RoomBuilder.model(.box([size.x, 0.004, size.y]),
                                      Palette.sandyWood, flat: flat, name: "BakjeBodem")
        floor.position = [0, 0.002, 0]
        root.addChild(floor)

        for (i, side) in [SIMD2<Float>(1, 0), [-1, 0], [0, 1], [0, -1]].enumerated() {
            let along = abs(side.x) > 0 ? SIMD3<Float>(wall, h, size.y)
                                        : SIMD3<Float>(size.x, h, wall)
            let rim = RoomBuilder.model(.box(along), Palette.cream, flat: flat,
                                        name: "BakjeRand\(i)")
            rim.position = [side.x * (size.x - wall) / 2, h / 2, side.y * (size.y - wall) / 2]
            root.addChild(rim)
        }

        // Three of the sticker itself, standing in the tray, so what is in it is
        // legible without a label — `CONCEPT.md` §5 forbids one.
        for i in 0..<3 {
            let token = sticker(kind, flat: flat)
            let across = (Float(i) - 1) * 0.011
            token.position = [across, h + kind.size * 0.4, Float(i % 2) * 0.005 - 0.003]
            token.orientation = simd_quatf(angle: Float(i) * 0.7, axis: [0, 1, 0])
            root.addChild(token)
        }
        return root
    }

    // MARK: - The seven stickers
    //
    // Each from its own plate, at the facet count the plate shows. They are
    // built standing on the XZ plane with +Y as their "up" — `VersierRoom`
    // orients them to the cake's surface normal.

    static func sticker(_ kind: StickerKind, flat: Bool) -> Entity {
        switch kind {
        case .sprinkel: return sprinkel(flat: flat)
        case .kaarsje: return kaarsje(flat: flat)
        case .hartje: return hartje(flat: flat)
        case .sterretje: return sterretje(flat: flat)
        case .kroontje: return kroontje(flat: flat)
        case .fruitje: return fruitje(flat: flat)
        case .roomtoefje: return roomtoefje(flat: flat)
        }
    }

    /// A short hexagonal rod with mitred ends, per `sprinkel.png`.
    private static func sprinkel(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Sprinkel"
        let rod = RoomBuilder.model(.prism(radius: 0.0009, height: StickerKind.sprinkel.size,
                                           sides: 6),
                                    StickerKind.sprinkel.colour, flat: flat, name: "SprinkelStaaf")
        // Lies down: a sprinkle standing on end reads as a nail.
        rod.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        root.addChild(rod)
        return root
    }

    /// A hexagonal-prism candle with a faceted teardrop flame, per `kaarsje.png`.
    /// The flame is a separate, named child so lighting it is a material swap
    /// rather than a rebuild.
    static let flameName = "KaarsjeVlam"

    private static func kaarsje(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Kaarsje"
        let h = StickerKind.kaarsje.size

        let stick = RoomBuilder.model(.prism(radius: 0.0018, height: h, sides: 6),
                                      StickerKind.kaarsje.colour, flat: flat, name: "KaarsjeStok")
        stick.position = [0, h / 2, 0]
        root.addChild(stick)

        let wick = RoomBuilder.model(.box([0.0006, 0.0016, 0.0006]),
                                     Palette.woodBrown, flat: flat, name: "KaarsjeLont")
        wick.position = [0, h + 0.0008, 0]
        root.addChild(wick)

        // Unlit until tapped: cream, not emitting. `VersierRoom.lightCandle`
        // swaps it for a glow material and adds a sparkle.
        let flame = RoomBuilder.model(.lathe(profile: [[0, 0], [0.0022, 0.0018],
                                                       [0.0016, 0.0038], [0, 0.0060]],
                                             sides: 6),
                                      Palette.cream, flat: flat, name: flameName)
        flame.position = [0, h + 0.0016, 0]
        flame.isEnabled = true
        root.addChild(flame)
        return root
    }

    /// **Three convex extrusions, not one heart outline.**
    ///
    /// `FacetedMesh.extrude` fan-triangulates both faces from vertex 0 and so
    /// requires a **convex** outline; a heart is concave at the cleft and would
    /// come back folded. Two lobes and a wedge, each convex, is the same
    /// silhouette and cannot go wrong. `hartje.png` shows a solid heart rather
    /// than a flat plate, which is what the two lobes are for.
    private static func hartje(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Hartje"
        let s = StickerKind.hartje.size
        let t = s * 0.42
        let colour = StickerKind.hartje.colour

        for side in [Float(-1), 1] {
            let lobe = RoomBuilder.model(.prism(radius: s * 0.28, height: t, sides: 8),
                                         colour, flat: flat, name: "HartjeBol")
            lobe.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            lobe.position = [side * s * 0.24, s * 0.60, 0]
            root.addChild(lobe)
        }

        // The point. A triangle is convex, so this one is a real `extrude` —
        // wound **counter-clockwise seen from +Z**, which `FacetedMesh.extrude`
        // requires and which a back-to-front outline turns into a hole, because
        // RealityKit culls back faces and Blender's viewport is not there to
        // warn you.
        let tip = RoomBuilder.model(.extrude(outline: [[0, 0],
                                                       [s * 0.50, s * 0.66],
                                                       [-s * 0.50, s * 0.66]],
                                             thickness: t),
                                    colour, flat: flat, name: "HartjePunt")
        root.addChild(tip)
        return root
    }

    /// `FacetedMesh.star` already builds the ridge down each arm that
    /// `sterretje.png` shows, so this one is free.
    private static func sterretje(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Sterretje"
        let s = StickerKind.sterretje.size
        let star = RoomBuilder.model(.star(points: 5, outerRadius: s * 0.5,
                                           innerRadius: s * 0.22, thickness: s * 0.34),
                                     StickerKind.sterretje.colour, flat: flat, name: "SterretjeVorm")
        // Built in the XY plane facing +Z; stand it up on the cake.
        star.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        star.position = [0, s * 0.5, 0]
        root.addChild(star)
        return root
    }

    /// A ~10-sided band with five triangular points, per `kroontje.png`. Each
    /// point is its own convex `extrude`, for the same reason the heart is
    /// three pieces.
    private static func kroontje(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Kroontje"
        let s = StickerKind.kroontje.size
        let r = s * 0.40
        let colour = StickerKind.kroontje.colour

        let band = RoomBuilder.model(.prism(radius: r, height: s * 0.34, sides: 10),
                                     colour, flat: flat, name: "KroontjeBand")
        band.position = [0, s * 0.17, 0]
        root.addChild(band)

        for i in 0..<5 {
            let a = Float(i) / 5 * 2 * .pi
            let point = RoomBuilder.model(.extrude(outline: [[-s * 0.16, 0],
                                                             [s * 0.16, 0],
                                                             [0, s * 0.34]],
                                                   thickness: s * 0.10),
                                          colour, flat: flat, name: "KroontjePunt\(i)")
            point.position = [cos(a) * r * 0.96, s * 0.34, sin(a) * r * 0.96]
            point.orientation = simd_quatf(angle: -a + .pi / 2, axis: [0, 1, 0])
            root.addChild(point)
        }
        return root
    }

    /// A faceted ball with a bent stalk, per `fruitje.png`. `icosphere` at one
    /// subdivision is the documented sweet spot — 80 faces, and above two the
    /// look is gone.
    private static func fruitje(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Fruitje"
        let s = StickerKind.fruitje.size

        let berry = RoomBuilder.model(.icosphere(radius: s * 0.44, subdivisions: 1),
                                      StickerKind.fruitje.colour, flat: flat, name: "FruitjeBes")
        berry.position = [0, s * 0.44, 0]
        root.addChild(berry)

        let stalk = RoomBuilder.model(.box([0.0007, s * 0.44, 0.0007]),
                                      Palette.sageDeep, flat: flat, name: "FruitjeSteel")
        stalk.position = [s * 0.10, s * 1.02, 0]
        stalk.orientation = simd_quatf(angle: -0.32, axis: [0, 0, 1])
        root.addChild(stalk)
        return root
    }

    /// Three stacked rings tapering to a point, per `roomtoefje.png` — which is
    /// a ready-made `lathe` profile.
    private static func roomtoefje(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Roomtoefje"
        let s = StickerKind.roomtoefje.size
        // Starts with a radius, not at zero: a `lathe` station of radius 0 is an
        // apex, and a cream swirl that comes to a point where it meets the cake
        // is standing on its tip. A radius there gets a flat cap instead, which
        // is what it actually sits on.
        let swirl = RoomBuilder.model(.lathe(profile: [[s * 0.30, 0],
                                                       [s * 0.46, s * 0.06],
                                                       [s * 0.40, s * 0.26],
                                                       [s * 0.34, s * 0.34],
                                                       [s * 0.28, s * 0.54],
                                                       [s * 0.20, s * 0.62],
                                                       [s * 0.14, s * 0.80],
                                                       [0, s * 1.00]],
                                             sides: 8),
                                      StickerKind.roomtoefje.colour, flat: flat,
                                      name: "RoomtoefjeVorm")
        root.addChild(swirl)
        return root
    }

    // MARK: - Toys

    /// Per `glitterpot.png`: a ~10-sided tapered pot with a rim, a matching lid
    /// lying beside it, and faceted nuggets heaped inside.
    static func glitterpot(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Glitterpot"

        let h: Float = 0.020
        let pot = RoomBuilder.model(.taperedPrism(bottomRadius: 0.011, topRadius: 0.014,
                                                  height: h, sides: 10),
                                    Palette.mint, flat: flat, name: "GlitterpotBody")
        pot.position = [0, h / 2, 0]
        root.addChild(pot)

        let rim = RoomBuilder.model(.prism(radius: 0.015, height: 0.004, sides: 10),
                                    Palette.mintLight, flat: flat, name: "GlitterpotRand")
        rim.position = [0, h - 0.001, 0]
        root.addChild(rim)

        for i in 0..<5 {
            let a = Float(i) / 5 * 2 * .pi
            let nugget = RoomBuilder.model(.icosphere(radius: 0.0026, subdivisions: 0),
                                           Palette.butterYellow, flat: flat,
                                           name: "GlitterKorrel\(i)")
            nugget.position = [cos(a) * 0.006, h + 0.002, sin(a) * 0.006]
            root.addChild(nugget)
        }

        let lid = RoomBuilder.model(.prism(radius: 0.014, height: 0.004, sides: 10),
                                    Palette.mint, flat: flat, name: "GlitterpotDeksel")
        lid.position = [0.024, 0.002, 0.004]
        root.addChild(lid)
        return root
    }

    /// Per `taartborden.png`: a stack of ~10-sided discs at graded diameters.
    static func taartborden(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Taartborden"
        let radii: [Float] = [0.019, 0.017, 0.017, 0.015]
        let colours = [Palette.cream, Palette.blushPink, Palette.blushPink, Palette.creamLight]
        var y: Float = 0
        for (i, r) in radii.enumerated() {
            let board = RoomBuilder.model(.prism(radius: r, height: 0.004, sides: 10),
                                          colours[i], flat: flat, name: "Taartbord\(i)")
            board.position = [0, y + 0.002, 0]
            root.addChild(board)
            y += 0.004
        }
        return root
    }

    /// Per `kwastje.png`: a tapered flat handle, a ferrule block and a bristle
    /// block. The plate's cut slots in the bristles are fine detail — one block.
    static func kwastje(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Kwastje"

        let handle = RoomBuilder.model(.box([0.026, 0.004, 0.007]),
                                       Palette.sandyWood, flat: flat, name: "KwastjeSteel")
        handle.position = [-0.010, 0.002, 0]
        root.addChild(handle)

        let ferrule = RoomBuilder.model(.box([0.007, 0.006, 0.010]),
                                        Palette.creamLight, flat: flat, name: "KwastjeRing")
        ferrule.position = [0.006, 0.003, 0]
        root.addChild(ferrule)

        let bristles = RoomBuilder.model(.box([0.011, 0.005, 0.012]),
                                         Palette.cream, flat: flat, name: "KwastjeHaar")
        bristles.position = [0.015, 0.0025, 0]
        root.addChild(bristles)
        return root
    }

    /// Per `krukje.png`: a ~14-sided disc seat on three straight tapered legs.
    /// Promoted from set dressing to a toy when the tea towel was cut.
    static func krukje(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Krukje"

        let legHeight: Float = 0.032
        for i in 0..<3 {
            let a = Float(i) / 3 * 2 * .pi
            let leg = RoomBuilder.model(.taperedPrism(bottomRadius: 0.0028, topRadius: 0.0038,
                                                      height: legHeight, sides: 4),
                                        Palette.cream, flat: flat, name: "KrukjePoot\(i)")
            leg.position = [cos(a) * 0.012, legHeight / 2, sin(a) * 0.012]
            root.addChild(leg)
        }

        let seat = RoomBuilder.model(.prism(radius: 0.020, height: 0.006, sides: 14),
                                     Palette.blushPink, flat: flat, name: "KrukjeZitting")
        seat.position = [0, legHeight + 0.003, 0]
        root.addChild(seat)
        return root
    }

    /// Per `wandplank-potjes.png`: a plank on two triangular brackets with three
    /// 8-sided lidded jars. The kitchen's shelf idiom with different contents.
    static func wandplank(flat: Bool) -> (root: Entity, jars: [Entity]) {
        let root = Entity()
        root.name = "Wandplank"
        root.position = [VersierLayout.shelfX, 0, VersierLayout.shelfCentreZ]

        let plank = RoomBuilder.model(.box([VersierLayout.shelfDepth, 0.008,
                                            VersierLayout.shelfLength]),
                                      Palette.sandyWood, flat: flat, name: "WandplankBlad")
        plank.position = [0, VersierLayout.shelfHeight, 0]
        root.addChild(plank)

        for (i, side) in [Float(-1), 1].enumerated() {
            let bracket = RoomBuilder.model(.box([VersierLayout.shelfDepth * 0.6, 0.014, 0.008]),
                                            Palette.woodBrown, flat: flat,
                                            name: "WandplankSteun\(i)")
            bracket.position = [-0.004, VersierLayout.shelfHeight - 0.010,
                                side * (VersierLayout.shelfLength / 2 - 0.018)]
            root.addChild(bracket)
        }

        var jars: [Entity] = []
        let colours = [Palette.blushPink, Palette.mint, Palette.butterYellow]
        for i in 0..<3 {
            let jar = Entity()
            jar.name = "Sprinkelpot\(i)"
            jar.position = [0, VersierLayout.shelfTopY,
                            (Float(i) - 1) * 0.040]

            let body = RoomBuilder.model(.taperedPrism(bottomRadius: 0.009, topRadius: 0.010,
                                                       height: 0.018, sides: 8),
                                         colours[i], flat: flat, name: "SprinkelpotBody\(i)")
            body.position = [0, 0.009, 0]
            jar.addChild(body)

            let lid = RoomBuilder.model(.prism(radius: 0.008, height: 0.005, sides: 8),
                                        Palette.creamLight, flat: flat, name: "SprinkelpotDeksel\(i)")
            lid.position = [0, 0.020, 0]
            jar.addChild(lid)

            root.addChild(jar)
            jars.append(jar)
        }
        return (root, jars)
    }

    /// The back counter the three counter toys stand on. Same idiom as the
    /// kitchen's: a solid box, because it is seen end-on and a carcass would be
    /// geometry nobody looks at.
    static func counter(flat: Bool) -> Entity {
        let counter = Entity()
        counter.name = "VersierAanrecht"
        counter.position = [VersierLayout.counterCentre.x, 0, VersierLayout.counterCentre.y]

        let bodyHeight = VersierLayout.counterTopY - RoomBox.floorY - 0.008
        let body = RoomBuilder.model(.box([VersierLayout.counterSize.x - 0.012, bodyHeight,
                                           VersierLayout.counterSize.y - 0.010]),
                                     Palette.creamLight, flat: flat, name: "VersierAanrechtBody")
        body.position = [0, RoomBox.floorY + bodyHeight / 2, 0]
        counter.addChild(body)

        let top = RoomBuilder.model(.box([VersierLayout.counterSize.x, 0.008,
                                          VersierLayout.counterSize.y]),
                                    Palette.sandyWood, flat: flat, name: "VersierAanrechtBlad")
        top.position = [0, VersierLayout.counterTopY - 0.004, 0]
        counter.addChild(top)

        counter.excludeFromShadowCasting()
        return counter
    }
}
