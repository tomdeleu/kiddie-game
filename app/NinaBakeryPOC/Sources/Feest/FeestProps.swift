import RealityKit
import simd

/// **The disco, in faceted primitives.**
///
/// Built from the twelve plates in `references/feest/`. Every one of them is a
/// handful of `FacetedMesh` shapes — the most complicated thing in here is the
/// DJ booth, which is nine boxes and two prisms.
///
/// ## The one rule this file exists to hold
///
/// **A disco is made of light, not of darkness.** `references/REFERENCES.md` §1
/// asks for soft even lighting, no dark corners and no occlusion, and none of
/// that changed for this room — the plaster is the same plaster and the key light
/// is the same key light. What the disco adds is **emissive surfaces**: the floor
/// tiles, the lamp lenses, the beams, the booth's front panel and the mirror
/// ball's facets are `Palette.glowMaterial` and `Palette.lightMaterial`, which
/// put a surface above white in the HDR buffer where a base colour cannot reach.
///
/// It is the halo's lesson (`Engine/Halo.swift`, four attempts) applied to a
/// whole room: **if it has to look like a light, make it one.** Dimming the room
/// to sell a disco would have thrown the art direction away for one room; six
/// emissive materials bought the same read for nothing, and the palette stayed
/// locked — every colour in here is one of the thirteen or one of the three the
/// kitchen derived.
enum FeestProps {

    /// How hard the glowing things glow. One number, because the whole room's
    /// disco-ness is a single dial and it is the thing most likely to need
    /// turning once this is on an iPad. `Halo.emissionPeak` is the precedent: the
    /// geometry and the profile are right, the value is the lever.
    static let glowPeak: Float = 2.6

    static func lit(_ colour: UIColorLike, _ amount: Float = 1) -> RealityKit.Material {
        Palette.glowMaterial(colour, intensity: glowPeak * max(0, amount))
    }

    // MARK: - The dance floor

    struct DanceFloor {
        let root: Entity
        /// Row-major, `tilesPerSide²` of them. The room repaints these on the
        /// beat and needs them in a flat array to do it cheaply.
        let tiles: [ModelEntity]
    }

    /// **Sixteen thin boxes, and it is the whole disco.**
    ///
    /// `references/feest/dansvloer.png` came back with pastel tiles rather than a
    /// black-and-white chequer, and that is the version that belongs here: a lit
    /// floor in the room's own colours, with three or four brighter than the rest
    /// at any moment. A chequer would have been a second palette.
    static func danceFloor(flat: Bool) -> DanceFloor {
        let root = Entity()
        root.name = "Dansvloer"

        var tiles: [ModelEntity] = []
        let size = FeestLayout.tileSize
        for row in 0..<FeestLayout.tilesPerSide {
            for column in 0..<FeestLayout.tilesPerSide {
                let colour = FeestLayout.discoColour(row * FeestLayout.tilesPerSide + column)
                let tile = RoomBuilder.model(
                    .box([size, FeestLayout.tileThickness, size]),
                    colour, flat: flat, name: "Tegel-\(row)-\(column)")
                var spot = FeestLayout.tileSpot(row, column)
                spot.y = RoomBox.floorY + FeestLayout.tileThickness / 2
                tile.position = spot
                // A lit floor casting a shadow of itself onto the floor it is
                // lying on is the one shadow in this room that could only ever
                // be a stain. Same reasoning as `RoomBox.shell`.
                tile.excludeFromShadowCasting()
                root.addChild(tile)
                tiles.append(tile)
            }
        }
        return DanceFloor(root: root, tiles: tiles)
    }

    // MARK: - The six pads

    struct Pad {
        let root: Entity
        /// The domed top, which is the part that lights when she hits it.
        let cap: ModelEntity
    }

    /// A squat cylinder with a domed glowing top, per
    /// `references/feest/knoppen.png`. She has to be able to see her finger land
    /// on it, so the cap is proud of the body rather than flush.
    static func pad(colour: UIColorLike, flat: Bool) -> Pad {
        let root = Entity()
        root.name = "Knop"

        let base = RoomBuilder.model(
            .prism(radius: FeestLayout.padGeometryRadius, height: FeestLayout.padHeight * 0.6,
                   sides: 8),
            Palette.creamLight, flat: flat, name: "KnopVoet")
        root.addChild(base)

        let cap = RoomBuilder.model(
            .dome(radius: FeestLayout.padGeometryRadius * 0.88,
                  height: FeestLayout.padHeight * 0.5, sides: 8, rings: 2),
            colour, flat: flat, name: "KnopKap")
        cap.position = [0, FeestLayout.padHeight * 0.6, 0]
        root.addChild(cap)

        return Pad(root: root, cap: cap)
    }

    // MARK: - The mirror ball

    struct MirrorBall {
        let root: Entity
        /// What spins. The cord does not.
        let ball: Entity
    }

    /// **A faceted sphere, and eight pools of light on the floor.**
    ///
    /// The ball itself is deliberately plain — a two-subdivision icosphere in
    /// cream, glowing gently. `references/feest/discobal.png` had to be told *no
    /// mirrored chrome, no metal reflections* to stay in the palette, and the
    /// finale plate, which was not, came back with a proper silver mirror ball
    /// that is the one thing in that picture off the direction. A chrome ball is
    /// not available in a style with no reflections in it, so **the spots do the
    /// work the mirror would have done.**
    ///
    /// The cord runs up past the wall tops and stops, because the room box has no
    /// ceiling (`references/REFERENCES.md` §1) and inventing a truss would put a
    /// surface between the camera and the room. What it runs into is the grey
    /// backdrop, which is the same thing the garden's fence shows over.
    static func mirrorBall(flat: Bool) -> MirrorBall {
        let root = Entity()
        root.name = "Discobal"
        root.position = FeestLayout.ballCentre

        let ball = Entity()
        ball.name = "DiscobalBol"
        root.addChild(ball)

        let sphere = RoomBuilder.model(
            .icosphere(radius: FeestLayout.ballRadius, subdivisions: 2),
            Palette.creamLight, flat: flat, name: "DiscobalFacetten")
        sphere.model?.materials = [lit(Palette.creamLight, 0.55)]
        ball.addChild(sphere)

        // Six little squares stuck round its equator, one per disco colour, so
        // the ball turning is visible on a sphere that is otherwise one tone.
        for i in 0..<6 {
            let angle = Float(i) / 6 * 2 * .pi
            let facet = RoomBuilder.model(.box([0.007, 0.007, 0.002]),
                                          FeestLayout.discoColour(i), flat: flat,
                                          name: "DiscobalSpiegel\(i)")
            facet.model?.materials = [lit(FeestLayout.discoColour(i), 0.9)]
            facet.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            facet.position = [sin(angle) * FeestLayout.ballRadius, 0.002,
                              cos(angle) * FeestLayout.ballRadius]
            ball.addChild(facet)
        }

        // The cord, and the ring it hangs from.
        let ring = RoomBuilder.model(.annulus(innerRadius: 0.0032, outerRadius: 0.0050,
                                              segments: 10),
                                     Palette.cream, flat: flat, name: "DiscobalRing")
        ring.position = [0, FeestLayout.ballRadius + 0.002, 0]
        root.addChild(ring)

        let cordLength = FeestLayout.cordTopY - FeestLayout.ballCentre.y
        let cord = RoomBuilder.model(.box([0.0016, cordLength, 0.0016]),
                                     Palette.cream, flat: flat, name: "DiscobalKoord")
        cord.position = [0, FeestLayout.ballRadius + cordLength / 2, 0]
        root.addChild(cord)
        root.excludeFromShadowCasting()

        return MirrorBall(root: root, ball: ball)
    }

    /// The pools of light, built separately because they live on the **floor**
    /// rather than on the ball. Parented to their own node so one rotation moves
    /// all eight.
    static func ballSpots(flat: Bool) -> (root: Entity, spots: [ModelEntity]) {
        let root = Entity()
        root.name = "DiscobalVlekken"
        root.position = [FeestLayout.ballCentre.x,
                         FeestLayout.tileTopY + 0.0008,
                         FeestLayout.ballCentre.z]

        var spots: [ModelEntity] = []
        for i in 0..<FeestLayout.ballSpotCount {
            let angle = Float(i) / Float(FeestLayout.ballSpotCount) * 2 * .pi
            let colour = FeestLayout.discoColour(i)
            let geometry = FacetedMesh.prism(radius: FeestLayout.ballSpotRadius,
                                             height: 0.0006, sides: 10)
            let spot = ModelEntity(
                mesh: FacetedMesh.mesh(geometry, flat: flat),
                materials: [Palette.lightMaterial(colour, emission: colour,
                                                  intensity: glowPeak * 0.7, opacity: 0.55)])
            spot.name = "Vlek\(i)"
            spot.position = [cos(angle) * FeestLayout.ballSpotOrbit, 0,
                             sin(angle) * FeestLayout.ballSpotOrbit]
            spot.excludeFromShadowCasting()
            root.addChild(spot)
            spots.append(spot)
        }
        return (root, spots)
    }

    // MARK: - The light rig

    struct Lamp {
        let root: Entity
        let lens: ModelEntity
        let beam: ModelEntity
    }

    /// One stage lamp: a short faceted cone with a glowing lens, and a beam
    /// widening to a pool on the floor.
    ///
    /// **The beam is `Palette.lightMaterial`, which is the halo's material, not
    /// `Palette.waterMaterial`.** That distinction matters because
    /// `references/REFERENCES.md` bans transparency and `waterMaterial` is the one
    /// sanctioned exception to it — a beam is not a second exception. It is a
    /// *light*, and the halo already established that a light is a transparent
    /// emissive surface rather than a transparent coloured one.
    static func lamp(colour: UIColorLike, aimedAt target: SIMD3<Float>,
                     from origin: SIMD3<Float>, flat: Bool) -> Lamp {
        let root = Entity()
        root.name = "Lamp"
        root.position = origin
        // Point local −Y down the line to the target, so the housing, the lens
        // and the beam are one rotation rather than three.
        let down = simd_normalize(target - origin)
        root.orientation = simd_quatf(from: [0, -1, 0], to: down)

        let housing = RoomBuilder.model(
            .taperedPrism(bottomRadius: 0.0105, topRadius: 0.0068, height: 0.014, sides: 8),
            Palette.creamLight, flat: flat, name: "LampHuis")
        // The lathe stands on +Y, and local −Y is where it has to point.
        housing.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        housing.position = [0, 0.002, 0]
        root.addChild(housing)

        let lens = RoomBuilder.model(.prism(radius: 0.0092, height: 0.0022, sides: 8),
                                     colour, flat: flat, name: "LampLens")
        lens.model?.materials = [lit(colour)]
        lens.position = [0, -0.014, 0]
        root.addChild(lens)

        // **Narrow end first, and that is not obvious.** A `taperedPrism` puts
        // `bottomRadius` at y = 0, and the π turn about X below maps y = 0 to the
        // lens and y = +height to the floor — so the *bottom* radius is the end at
        // the lamp. Writing it the way it reads (wide at the bottom) builds a
        // beam that gets narrower the further it travels, which is a searchlight
        // seen from the wrong end.
        let beamGeometry = FacetedMesh.taperedPrism(
            bottomRadius: FeestLayout.beamTopRadius,
            topRadius: FeestLayout.beamBottomRadius,
            height: FeestLayout.beamLength, sides: 8)
        let beam = ModelEntity(
            mesh: FacetedMesh.mesh(beamGeometry, flat: flat),
            materials: [Palette.lightMaterial(colour, emission: colour,
                                              intensity: glowPeak * 0.5, opacity: 0.16)])
        beam.name = "LampBundel"
        // The taper stands on +Y with its wide end at the bottom, and it has to
        // hang *down* from the lens with the wide end far away — so it is turned
        // over and pushed along −Y by its own length.
        beam.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        beam.position = [0, -0.015, 0]
        beam.excludeFromShadowCasting()
        root.addChild(beam)
        root.excludeFromShadowCasting()

        return Lamp(root: root, lens: lens, beam: beam)
    }

    /// The bar the lamps clamp on. Two of them, one per wall.
    static func lightBar(length: Float, flat: Bool) -> Entity {
        let bar = RoomBuilder.model(.box([length, 0.005, 0.005]),
                                    Palette.woodBrown, flat: flat, name: "Lichtbalk")
        bar.excludeFromShadowCasting()
        return bar
    }

    // MARK: - The DJ booth

    struct Booth {
        let root: Entity
        /// The two platters, which turn on the beat.
        let decks: [Entity]
        /// The front panel, which is the room's biggest single emissive surface.
        let panel: ModelEntity
    }

    /// From `references/feest/dj-booth.png`: a low console, two flat round
    /// platters on the top, a small mixer between them, and one glowing panel
    /// across the front. The plate's knobs came back charcoal, which is off the
    /// palette; these are `woodBrown`, the darkest of the locked thirteen.
    static func booth(flat: Bool) -> Booth {
        let root = Entity()
        root.name = "DJBooth"
        root.position = [FeestLayout.boothCentre.x, RoomBox.floorY, FeestLayout.boothCentre.y]

        let size = FeestLayout.boothSize
        let height = FeestLayout.boothTopY - RoomBox.floorY

        let body = RoomBuilder.model(.box([size.x, height, size.y]),
                                     Palette.cream, flat: flat, name: "BoothKast")
        body.position = [0, height / 2, 0]
        root.addChild(body)

        // The top, in rose, standing a little proud all round so the console has
        // a lip — which is the detail that stops it reading as a sideboard.
        let top = RoomBuilder.model(.box([size.x + 0.006, 0.006, size.y + 0.006]),
                                    Palette.rose, flat: flat, name: "BoothBlad")
        top.position = [0, height + 0.003, 0]
        root.addChild(top)

        let panel = RoomBuilder.model(.box([size.x * 0.78, height * 0.52, 0.002]),
                                      Palette.butterYellow, flat: flat, name: "BoothPaneel")
        panel.model?.materials = [lit(Palette.butterYellow, 0.8)]
        panel.position = [0, height * 0.46, size.y / 2 + 0.001]
        root.addChild(panel)

        var decks: [Entity] = []
        for (i, dx) in [-FeestLayout.deckOffset, FeestLayout.deckOffset].enumerated() {
            let deck = Entity()
            deck.name = "Draaideck\(i)"
            deck.position = [dx, height + 0.006, 0]
            root.addChild(deck)

            let platter = RoomBuilder.model(
                .prism(radius: FeestLayout.deckRadius, height: 0.003, sides: 12),
                Palette.creamLight, flat: flat, name: "Plaat\(i)")
            deck.addChild(platter)

            // One mark on the rim, so a platter that is turning looks like it.
            let mark = RoomBuilder.model(.box([0.004, 0.0035, 0.008]),
                                         Palette.woodBrown, flat: flat, name: "PlaatMerk\(i)")
            mark.position = [0, 0.0006, FeestLayout.deckRadius * 0.6]
            deck.addChild(mark)

            decks.append(deck)
        }

        // The mixer between them: a small slab and four knobs.
        let mixer = RoomBuilder.model(.box([0.022, 0.005, 0.026]),
                                      Palette.mintLight, flat: flat, name: "Mengpaneel")
        mixer.position = [0, height + 0.0085, 0]
        root.addChild(mixer)
        for i in 0..<4 {
            let knob = RoomBuilder.model(.prism(radius: 0.0022, height: 0.003, sides: 6),
                                         Palette.woodBrown, flat: flat, name: "Knopje\(i)")
            knob.position = [Float(i % 2) * 0.010 - 0.005,
                             height + 0.011,
                             Float(i / 2) * 0.010 - 0.005]
            root.addChild(knob)
        }

        return Booth(root: root, decks: decks, panel: panel)
    }

    // MARK: - The speakers

    struct Speakers {
        let root: Entity
        /// The cones, which push in and out on the beat.
        let cones: [Entity]
    }

    /// A stack of two, from `references/feest/boxen.png`: square boxes each with
    /// one large recessed cone and a smaller one above it.
    static func speakers(flat: Bool) -> Speakers {
        let root = Entity()
        root.name = "Boxen"
        root.position = FeestLayout.speakerSpot

        var cones: [Entity] = []
        let box = SIMD3<Float>(0.044, 0.038, 0.030)
        for level in 0..<2 {
            let y = Float(level) * (box.y + 0.002) + box.y / 2
            let cabinet = RoomBuilder.model(.box(box), Palette.sandyWood, flat: flat,
                                            name: "Box\(level)")
            cabinet.position = [0, y, 0]
            root.addChild(cabinet)

            for (i, spec) in [(Float(0.012), Float(-0.008)),
                              (Float(0.006), Float(0.011))].enumerated() {
                let cone = Entity()
                cone.name = "Conus\(level)-\(i)"
                cone.position = [0, y + spec.1, box.z / 2 + 0.001]
                root.addChild(cone)

                let disc = RoomBuilder.model(
                    .taperedPrism(bottomRadius: spec.0, topRadius: spec.0 * 0.45,
                                  height: 0.004, sides: 10),
                    Palette.creamLight, flat: flat, name: "ConusPlaat")
                disc.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                cone.addChild(disc)

                // The dust cap sits at the *inner* end of the cone, which is
                // where the −π/2 turn puts the narrow end: the disc runs from the
                // cabinet face inwards, so a cap proud of the face would be a
                // knob on a hole.
                let cap = RoomBuilder.model(.icosphere(radius: spec.0 * 0.30, subdivisions: 0),
                                            Palette.woodBrown, flat: flat, name: "ConusDop")
                cap.position = [0, 0, -0.0035]
                cone.addChild(cap)

                cones.append(cone)
            }
        }
        return Speakers(root: root, cones: cones)
    }

    // MARK: - The cake table

    /// A pedestal table, from `references/feest/taarttafel.png`. Round, because
    /// the cake is round and because a round table has no corner for a guest to
    /// stand behind.
    static func cakeTable(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Feesttafel"
        root.position = [FeestLayout.tableCentre.x, RoomBox.floorY, FeestLayout.tableCentre.y]

        let foot = RoomBuilder.model(
            .taperedPrism(bottomRadius: FeestLayout.tableFootRadius,
                          topRadius: FeestLayout.tableFootRadius * 0.7,
                          height: 0.008, sides: 10),
            Palette.rose, flat: flat, name: "TafelVoet")
        root.addChild(foot)

        let stemHeight = FeestLayout.tableTopY - RoomBox.floorY
            - FeestLayout.tableTopThickness - 0.008
        let stem = RoomBuilder.model(
            .prism(radius: FeestLayout.tableStemRadius, height: stemHeight, sides: 8),
            Palette.rose, flat: flat, name: "TafelPoot")
        stem.position = [0, 0.008, 0]
        root.addChild(stem)

        let top = RoomBuilder.model(
            .prism(radius: FeestLayout.tableRadius, height: FeestLayout.tableTopThickness,
                   sides: 12),
            Palette.blushPink, flat: flat, name: "TafelBlad")
        top.position = [0, FeestLayout.tableTopY - RoomBox.floorY
                            - FeestLayout.tableTopThickness, 0]
        root.addChild(top)

        return root
    }

    // MARK: - Toys

    /// The confetti popper, from `references/feest/knaller.png`: a short wide cone
    /// standing on its narrow end, with a knob on top.
    static func popper(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Knaller"
        root.position = FeestLayout.popperSpot

        let cone = RoomBuilder.model(
            .taperedPrism(bottomRadius: 0.009, topRadius: 0.018, height: 0.030, sides: 8),
            Palette.blushPinkDeep, flat: flat, name: "KnallerKegel")
        root.addChild(cone)

        let band = RoomBuilder.model(.prism(radius: 0.0195, height: 0.004, sides: 8),
                                     Palette.mintLight, flat: flat, name: "KnallerRand")
        band.position = [0, 0.028, 0]
        root.addChild(band)

        let knob = RoomBuilder.model(.icosphere(radius: 0.005, subdivisions: 0),
                                     Palette.butterYellow, flat: flat, name: "KnallerKnop")
        knob.position = [0, 0.036, 0]
        root.addChild(knob)

        return root
    }

    /// The balloon, from `references/feest/ballon.png`. A lathe rather than a
    /// sphere, because a balloon is a teardrop and a sphere on a string is a
    /// ball on a string.
    static func balloon(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Ballon"
        root.position = FeestLayout.balloonHome

        let skin = RoomBuilder.model(
            .lathe(profile: [[0, -0.020], [0.006, -0.016], [0.013, -0.006],
                             [0.014, 0.004], [0.009, 0.012], [0, 0.016]],
                   sides: 10),
            Palette.rose, flat: flat, name: "BallonVel")
        root.addChild(skin)

        let knot = RoomBuilder.model(.lathe(profile: [[0, -0.026], [0.0035, -0.021],
                                                      [0, -0.019]], sides: 6),
                                     Palette.blushPinkDeep, flat: flat, name: "BallonKnoop")
        root.addChild(knot)

        let string = RoomBuilder.model(.box([0.0012, 0.040, 0.0012]),
                                       Palette.creamLight, flat: flat, name: "BallonTouw")
        string.position = [0, -0.046, 0]
        root.addChild(string)
        root.excludeFromShadowCasting()

        return root
    }

    // MARK: - Confetti

    /// **Flat angular scraps, not sparkles.** `Sparkles.burst` throws five-point
    /// stars and is the game's reward vocabulary; confetti is *stuff*, the way
    /// flour is, and it wants to be paper. Small boxes at six colours, tumbling.
    @MainActor
    static func confetti(at position: SIMD3<Float>, in parent: Entity,
                         ticker: Ticker, count: Int = 26, flat: Bool = true) {
        for i in 0..<count {
            let colour = FeestLayout.discoColour(i)
            let scrap = RoomBuilder.model(.box([0.0042, 0.0007, 0.0030]),
                                          colour, flat: flat, name: "Confetti")
            scrap.position = position
            scrap.excludeFromShadowCasting()
            parent.addChild(scrap)

            let angle = Float.random(in: 0..<(2 * .pi))
            let spread = Float.random(in: 0.2...1.0)
            var velocity = SIMD3<Float>(cos(angle) * spread,
                                        Float.random(in: 0.9...1.6),
                                        sin(angle) * spread) * 0.13
            let spin = simd_quatf(angle: Float.random(in: 3...9),
                                  axis: simd_normalize(SIMD3<Float>(
                                    Float.random(in: -1...1),
                                    Float.random(in: -1...1),
                                    Float.random(in: -1...1))))
            let lifetime = Float.random(in: 1.6...2.6)
            var age: Float = 0

            ticker.add { [weak scrap] dt in
                guard let scrap else { return false }
                age += dt
                guard age < lifetime else {
                    scrap.removeFromParent()
                    return false
                }
                // Paper falls slowly and drifts, where a sparkle drops.
                velocity.y -= 0.10 * dt
                velocity.x *= 1 - 0.9 * dt
                velocity.z *= 1 - 0.9 * dt
                scrap.position += velocity * dt
                let identity = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
                scrap.orientation = simd_slerp(identity, spin, min(1, age / lifetime))
                return true
            }
        }
    }
}
