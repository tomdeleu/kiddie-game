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
        // soffit rather than leaving a seam, and recessed so the mouth reads as
        // having depth. It is solid: the tin slides in and is hidden by the
        // door, which is also how a real oven works.
        let oversize: Float = 0.002
        let plugDepth: Float = 0.028
        let mouth = RoomBuilder.model(.archPlug(radius: Layout.mouthArchInner + oversize,
                                                legHeight: Layout.mouthLegHeight + oversize,
                                                depth: plugDepth, segments: 6),
                                      Palette.woodBrown, flat: flat, name: "OvenMouth")
        mouth.position = [0, -oversize, archFront - 0.008 - plugDepth / 2]
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

        // Base low enough to bury itself in the dome — the surface is at
        // y = 0.056 out where the chimney stands.
        let chimney = RoomBuilder.model(.prism(radius: 0.011, height: 0.045, sides: 4),
                                        Palette.creamLight, flat: flat, name: "Chimney")
        chimney.position = [0.028, 0.050, -0.030]
        body.addChild(chimney)

        let chimneyCap = RoomBuilder.model(.prism(radius: 0.015, height: 0.008, sides: 4),
                                           Palette.cream, flat: flat, name: "ChimneyCap")
        chimneyCap.position = [0.028, 0.091, -0.030]
        body.addChild(chimneyCap)

        // The face. Two eyes and two cheeks is the whole character — he has no
        // mouth, because the arch already is one.
        var eyes: [ModelEntity] = []
        for (i, dx) in [Float(-0.018), 0.018].enumerated() {
            let eye = RoomBuilder.model(.icosphere(radius: 0.0055, subdivisions: 1),
                                        Palette.woodBrown, flat: flat, name: "OttoEye\(i)")
            eye.position = [dx, 0.052, 0.042]
            body.addChild(eye)
            eyes.append(eye)
        }
        for (i, dx) in [Float(-0.034), 0.034].enumerated() {
            let cheek = RoomBuilder.model(.icosphere(radius: 0.007, subdivisions: 0),
                                          Palette.rose, flat: flat, name: "OttoCheek\(i)")
            cheek.position = [dx, 0.042, 0.030]
            cheek.scale = [1, 0.7, 0.4]
            body.addChild(cheek)
        }

        return Oven(root: root, dome: dome, doorPivot: doorPivot, door: door,
                    eyes: eyes,
                    chimneyTop: Layout.ovenOrigin + SIMD3<Float>(0.028, 0.105, -0.030))
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

    /// One draggable ingredient. Berries are round; honey and star sugar are
    /// not, so she can tell them apart without reading anything.
    static func token(_ ingredient: Ingredient, flat: Bool) -> ModelEntity {
        let name = "Token_\(ingredient.rawValue)"
        switch ingredient {
        case .honing:
            return RoomBuilder.model(.prism(radius: 0.009, height: 0.014, sides: 6),
                                     ingredient.tokenColour, flat: flat, name: name)
        case .sterrensuiker:
            // 20 faces, so it reads as a crystal rather than a berry.
            return RoomBuilder.model(.icosphere(radius: 0.009, subdivisions: 0),
                                     ingredient.tokenColour, flat: flat, name: name)
        case .wolkenroom:
            return RoomBuilder.model(.icosphere(radius: 0.011, subdivisions: 1),
                                     ingredient.tokenColour, flat: flat, name: name)
        default:
            return RoomBuilder.model(.icosphere(radius: 0.0095, subdivisions: 1),
                                     ingredient.tokenColour, flat: flat, name: name)
        }
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

    static func flourSack(flat: Bool) -> Entity {
        let sack = Entity()
        sack.name = "FlourSack"

        let body = RoomBuilder.model(.taperedPrism(bottomRadius: 0.017, topRadius: 0.012,
                                                   height: 0.030, sides: 6),
                                     Palette.creamLight, flat: flat, name: "FlourSackBody")
        sack.addChild(body)

        let neck = RoomBuilder.model(.prism(radius: 0.008, height: 0.008, sides: 6),
                                     Palette.cream, flat: flat, name: "FlourSackNeck")
        neck.position = [0, 0.030, 0]
        sack.addChild(neck)

        let tie = RoomBuilder.model(.prism(radius: 0.0095, height: 0.003, sides: 6),
                                    Palette.blushPinkDeep, flat: flat, name: "FlourSackTie")
        tie.position = [0, 0.031, 0]
        sack.addChild(tie)

        return sack
    }

    struct Sink {
        let root: Entity
        let basin: ModelEntity
        /// Scaled down the Y axis to make the water run.
        let water: ModelEntity
    }

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

        // Anchored at the spout and turned upside down, so scaling it up the Y
        // axis makes the water run *downwards* into the basin.
        let water = RoomBuilder.model(.prism(radius: 0.0028, height: 0.030, sides: 5),
                                      Palette.berryBlue, flat: flat, name: "TapWater")
        water.position = [0, 0.040, -0.002]
        water.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        water.scale = [1, 0.001, 1]
        water.isEnabled = false
        root.addChild(water)

        return Sink(root: root, basin: basin, water: water)
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

        // Flat against the wall, so its cast shadow could only ever print the
        // arch onto the plaster beside it — a hard dark echo, not grounding.
        root.excludeFromShadowCasting()

        return Doorway(root: root, glow: glow)
    }
}
