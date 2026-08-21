import RealityKit
import simd

/// **De Bakkerij's furniture**, built from the plates in
/// `references/bakkerij/`. All `FacetedMesh` primitives — `models/README.md`'s
/// test is *"there is no facet the lathe cannot already make"*, and every prop in
/// this room passes it. The blind is a rectangle and a coarse cylinder, the
/// frames are boxes, the hook is a backplate and two segments; the cat is the one
/// that looked like it might need Blender and turned out to be a lathe, two
/// prisms and a tail.
enum BakkerijProps {

    // MARK: - The counter

    /// A long low counter along the frame wall. `roombox-v2.png` gives it blush
    /// pink with a paler top.
    ///
    /// **It gets no naming target of its own.** `ROOMS.md` §5: a large prop
    /// entirely covered by the smaller ones standing on it loses every tap to
    /// them, so its word is folded into the cat's and the radio's at the flour
    /// sack's ratio.
    static func counter(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Toonbank"
        root.position = [BakkerijLayout.counterCentre.x, 0,
                         BakkerijLayout.counterCentre.y]

        let height = BakkerijLayout.counterTopY - RoomBox.floorY
        let body = model(.box([BakkerijLayout.counterSize.x, height - 0.005,
                                           BakkerijLayout.counterSize.y]),
                                     Palette.blushPink, flat: flat, name: "ToonbankBody")
        body.position = [0, RoomBox.floorY + (height - 0.005) / 2, 0]
        root.addChild(body)

        // A top that oversails the body by 3 mm each way, which is what stops a
        // box reading as a box.
        let top = model(.box([BakkerijLayout.counterSize.x + 0.006, 0.005,
                                          BakkerijLayout.counterSize.y + 0.006]),
                                    Palette.creamLight, flat: flat, name: "ToonbankBlad")
        top.position = [0, BakkerijLayout.counterTopY - 0.0025, 0]
        root.addChild(top)

        root.excludeFromShadowCasting()
        return root
    }

    // MARK: - The blind

    struct Blind {
        let root: Entity
        /// The cloth. Scaled and moved as it rolls up.
        let cloth: ModelEntity
        /// The roll itself, which fattens as the cloth winds onto it.
        let roll: ModelEntity
        /// The knob at the end of the cord — the drag target for `opendoen`.
        let knob: Entity
        /// The cord, which shortens as the knob rises.
        let cord: ModelEntity
    }

    /// **The shop blind, over the window.** `references/bakkerij/rolluik.png`:
    /// a roll on a bar with a chunky faceted end cap each side, on a bracket, and
    /// a straight pull cord ending in an 8-sided butter yellow knob.
    ///
    /// The plate drew it half-unrolled when it was asked for rolled up; that does
    /// not matter, because a blind is a flat rectangle and a coarse cylinder. The
    /// end caps, the bracket and the cord knob are the parts worth copying, and
    /// they are what this builds.
    static func blind(flat: Bool) -> Blind {
        let root = Entity()
        root.name = "Rolluik"
        root.position = [BakkerijLayout.blindCentreX, 0, BakkerijLayout.backPropZ]

        let width = BakkerijLayout.blindWidth
        let rollY = BakkerijLayout.blindRollY

        // The bar, laid on its side. Eight sides is `POC.md`'s cylinder budget.
        let roll = model(.prism(radius: 0.010, height: width, sides: 8),
                                     Palette.creamLight, flat: flat, name: "RolluikRol")
        roll.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        roll.position = [0, rollY, 0.004]
        root.addChild(roll)

        // A chunky faceted end cap each side, and a bracket behind each.
        for side: Float in [-1, 1] {
            let cap = model(.prism(radius: 0.013, height: 0.008, sides: 8),
                                        Palette.rose, flat: flat, name: "RolluikDop")
            cap.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            cap.position = [side * (width / 2 + 0.004), rollY, 0.004]
            root.addChild(cap)

            let bracket = model(.box([0.010, 0.020, 0.010]),
                                            Palette.sandyWood, flat: flat,
                                            name: "RolluikBeugel")
            bracket.position = [side * (width / 2 + 0.008), rollY + 0.006, 0.001]
            root.addChild(bracket)
        }

        // The cloth. Built full-height with its pivot at the top, so rolling up is
        // one scale on Y — a cloth that shortens from the bottom, which is what a
        // blind does.
        let drop = rollY - BakkerijLayout.blindShutY
        let cloth = model(.box([width, drop, 0.004]),
                                      Palette.mint, flat: flat, name: "RolluikDoek")
        cloth.position = [0, rollY - drop / 2, 0.004]
        root.addChild(cloth)

        // The cord hangs from the near end of the bar, ending in the knob she
        // pulls. Its own little entity so the knob can be moved and the cord
        // restretched between the two.
        let cord = model(.box([0.002, 0.060, 0.002]),
                                     Palette.creamLight, flat: flat, name: "RolluikKoord")
        root.addChild(cord)

        let knob = Entity()
        knob.name = "RolluikKnop"
        root.addChild(knob)

        let bead = model(.prism(radius: 0.008, height: 0.009, sides: 8),
                                     Palette.butterYellow, flat: flat, name: "RolluikKnopBol")
        knob.addChild(bead)

        root.excludeFromShadowCasting()
        return Blind(root: root, cloth: cloth, roll: roll, knob: knob, cord: cord)
    }

    // MARK: - The window

    struct Window {
        let root: Entity
        /// The sky. Emissive, and its colour is the hour of the day.
        let pane: ModelEntity
    }

    /// **The window, and it shows the actual time of day** — §6.1's fourth toy.
    ///
    /// `references/bakkerij/raam.png`: a chunky frame around a **solid** pale blue
    /// panel, in four panes. The transparency ban held on this prop, as it did on
    /// the shop door — there is no glass anywhere in this game, so the sky is a
    /// painted board and the way it says *daylight* is by emitting, which is how
    /// the disco was built without touching the lighting rig.
    static func window(flat: Bool) -> Window {
        let root = Entity()
        root.name = "Raam"
        root.position = BakkerijLayout.windowCentre

        let size = BakkerijLayout.windowSize

        let pane = model(.box([size.x, size.y, 0.003]),
                                     Palette.berryBlue, flat: flat, name: "RaamRuit")
        root.addChild(pane)

        // Frame: four sides standing proud of the pane, and a cross of two
        // glazing bars over it — the plate's four panes.
        let bar: Float = 0.009
        for side: Float in [-1, 1] {
            let upright = model(.box([bar, size.y + bar * 2, 0.010]),
                                            Palette.creamLight, flat: flat,
                                            name: "RaamStijl")
            upright.position = [side * (size.x + bar) / 2, 0, 0.003]
            root.addChild(upright)

            let rail = model(.box([size.x + bar * 2, bar, 0.010]),
                                         Palette.creamLight, flat: flat, name: "RaamDorpel")
            rail.position = [0, side * (size.y + bar) / 2, 0.003]
            root.addChild(rail)
        }
        let mullion = model(.box([0.005, size.y, 0.006]),
                                        Palette.creamLight, flat: flat, name: "RaamRoede")
        mullion.position = [0, 0, 0.003]
        root.addChild(mullion)
        let transom = model(.box([size.x, 0.005, 0.006]),
                                        Palette.creamLight, flat: flat, name: "RaamRoedeH")
        transom.position = [0, 0, 0.003]
        root.addChild(transom)

        root.excludeFromShadowCasting()
        return Window(root: root, pane: pane)
    }

    /// **What colour the sky is right now.** Four times of day, derived from the
    /// palette rather than sampled, and every one of them emits a little so the
    /// window reads as a light source in a room that has no other one.
    ///
    /// It is a toy, so it is allowed to be quietly true: a child playing after
    /// tea gets an amber window, and one playing on a Saturday morning gets a
    /// pale gold one.
    static func skyColour(hour: Int) -> (colour: UIColorLike, glow: Float) {
        switch hour {
        case 5..<9:   return (Palette.mix(Palette.berryBlue, Palette.butterYellow, 0.45), 0.30)
        case 9..<17:  return (Palette.berryBlue, 0.38)
        case 17..<20: return (Palette.mix(Palette.berryBlue, Palette.honeyAmber, 0.55), 0.30)
        default:      return (Palette.mix(Palette.berryBlueDeep, Palette.lilacDeep, 0.5), 0.16)
        }
    }

    // MARK: - The shop door

    struct ShopDoor {
        let root: Entity
        let hinge: Entity
        /// The daylight behind it, so opening it is worth doing.
        let glow: ModelEntity
    }

    /// **The door the friend comes in through** —
    /// `references/bakkerij/winkeldeur.png`: a rose leaf in a sandy wood frame, a
    /// solid pale cream inset panel in the upper half, a ~12-sided faceted knob,
    /// two flat strap hinges.
    ///
    /// **The plate's hinges and knob came back on the same side**, which the
    /// folder's README says to mirror. They are mirrored here: straps on the
    /// hanging edge, knob on the swinging one.
    ///
    /// It is built rather than borrowed from `Props.doorway` for the reason
    /// `BakkerijLayout` gives — that prop is the vocabulary of *the way out*, and
    /// this room's way out is the back door. Two doors carrying the same three
    /// cues would be `ROOMS.md` §9's forbidden case: a room with two objects
    /// meaning "this is finished".
    static func shopDoor(flat: Bool) -> ShopDoor {
        let root = Entity()
        root.name = "Winkeldeur"
        root.position = BakkerijLayout.shopDoorCentre

        let open = BakkerijLayout.shopDoorOpening
        let jamb: Float = 0.010

        // Daylight behind it, 2 mm clear of the plaster so two coplanar faces
        // cannot flicker against each other.
        let glow = model(.box([open.x, open.y, 0.002]),
                                     Palette.butterYellow, flat: flat,
                                     name: "WinkeldeurLicht")
        glow.position = [0, open.y / 2, -0.006]
        root.addChild(glow)

        for side: Float in [-1, 1] {
            let post = model(.box([jamb, open.y, 0.014]),
                                         Palette.sandyWood, flat: flat,
                                         name: "WinkeldeurStijl")
            post.position = [side * (open.x + jamb) / 2, open.y / 2, 0.002]
            root.addChild(post)
        }
        let lintel = model(.box([open.x + jamb * 2, jamb, 0.014]),
                                       Palette.sandyWood, flat: flat,
                                       name: "WinkeldeurLatei")
        lintel.position = [0, open.y + jamb / 2, 0.002]
        root.addChild(lintel)

        // Hinged on the near side — the same choice `Props.doorway` documents at
        // length, and for the same reason: the far side swings the leaf away, it
        // turns edge-on at this camera and reads as a stick in a hole. On the back
        // wall the near side is +X, the corner nearest the camera.
        let hinge = Entity()
        hinge.name = "WinkeldeurScharnier"
        hinge.position = [open.x / 2, 0, 0.004]
        root.addChild(hinge)

        let leaf = model(.box([open.x, open.y, 0.007]),
                                     Palette.rose, flat: flat, name: "WinkeldeurBlad")
        leaf.position = [-open.x / 2, open.y / 2, 0.0035]
        hinge.addChild(leaf)

        // The solid cream inset panel in the upper half — the one the plate proved
        // could be asked for without transparency coming back with it.
        let panel = model(.box([open.x - 0.020, open.y * 0.40, 0.002]),
                                      Palette.creamLight, flat: flat,
                                      name: "WinkeldeurPaneel")
        panel.position = [0, open.y * 0.22, 0.0045]
        leaf.addChild(panel)

        // Two flat strap hinges, on the hanging edge — mirrored from the plate.
        for fraction: Float in [0.22, 0.78] {
            let strap = model(.box([open.x * 0.30, 0.006, 0.003]),
                                          Palette.blushPinkDeep, flat: flat,
                                          name: "WinkeldeurBand")
            strap.position = [open.x * 0.35, open.y * (fraction - 0.5), 0.005]
            leaf.addChild(strap)
        }

        // And the knob on the swinging edge. Twelve sides, as the plate has.
        let knob = model(.prism(radius: 0.006, height: 0.007, sides: 12),
                                     Palette.butterYellow, flat: flat,
                                     name: "WinkeldeurKnop")
        knob.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        knob.position = [-open.x / 2 + 0.013, -0.006, 0.005]
        leaf.addChild(knob)

        root.excludeFromShadowCasting()
        return ShopDoor(root: root, hinge: hinge, glow: glow)
    }

    // MARK: - The bell

    struct Bell {
        let root: Entity
        /// What swings when it rings.
        let swing: Entity
    }

    /// The shop bell — `references/bakkerij/bel.png`: a butter yellow dome with a
    /// ball clapper, on a curved arm off a flat backplate.
    ///
    /// §6.1: **the friend rings it, she does not.** That is what keeps it a toy on
    /// her side of the room rather than a required step wearing a toy's clothes —
    /// the trap `ROOMS.md` §8 records as the rolling pin's.
    static func bell(flat: Bool) -> Bell {
        let root = Entity()
        root.name = "Bel"
        root.position = BakkerijLayout.bellCentre

        let plate = model(.box([0.012, 0.026, 0.005]),
                                      Palette.sandyWood, flat: flat, name: "BelPlaat")
        plate.position = [0, 0.004, -0.002]
        root.addChild(plate)

        let arm = model(.box([0.026, 0.006, 0.006]),
                                    Palette.sandyWood, flat: flat, name: "BelArm")
        arm.position = [-0.013, 0.013, 0.004]
        root.addChild(arm)

        // The dome and its clapper hang off a pivot at the arm's end, so ringing
        // it is one rotation.
        let swing = Entity()
        swing.name = "BelSchommel"
        swing.position = [-0.024, 0.011, 0.004]
        root.addChild(swing)

        let dome = model(.dome(radius: 0.011, height: 0.012, sides: 8, rings: 3),
                                     Palette.butterYellow, flat: flat, name: "BelKap")
        dome.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        dome.position = [0, -0.002, 0]
        swing.addChild(dome)

        let lip = model(.prism(radius: 0.012, height: 0.004, sides: 8),
                                    Palette.butterYellow, flat: flat, name: "BelRand")
        lip.position = [0, -0.014, 0]
        swing.addChild(lip)

        let clapper = model(.icosphere(radius: 0.004, subdivisions: 0),
                                        Palette.woodBrown, flat: flat, name: "BelKlepel")
        clapper.position = [0, -0.020, 0]
        swing.addChild(clapper)

        root.excludeFromShadowCasting()
        return Bell(root: root, swing: swing)
    }

    // MARK: - The sign

    struct Sign {
        let root: Entity
        /// The board, whose colour is how much of the wall is filled.
        let board: ModelEntity
        let cake: ModelEntity
        let star: ModelEntity
    }

    /// **The sign above the door, and it is the game's only progress bar.**
    /// `GAMEPLAY.md` §2: *"starts washed-out grey. Each filled frame brings a
    /// little more colour and a little more glow into it… No numbers, no bar, no
    /// percentage."*
    ///
    /// `references/bakkerij/uithangbord-twee-staten.png` was asked for both
    /// states and returned two coloured ones — flux applies saturation to a whole
    /// picture, not to one object in it. The geometry is the plate's; the grey end
    /// is `Palette.ghostGrey`, and the room mixes between them.
    static func sign(flat: Bool) -> Sign {
        let root = Entity()
        root.name = "Uithangbord"
        root.position = BakkerijLayout.signCentre

        let size = BakkerijLayout.signSize

        // The bracket bar and its two hanger rods, from the plate.
        let bar = model(.box([size.x + 0.014, 0.007, 0.008]),
                                    Palette.sandyWood, flat: flat, name: "BordBalk")
        bar.position = [0, size.y / 2 + 0.016, 0]
        root.addChild(bar)
        for side: Float in [-1, 1] {
            let rod = model(.box([0.003, 0.013, 0.003]),
                                        Palette.creamLight, flat: flat, name: "BordStang")
            rod.position = [side * size.x * 0.32, size.y / 2 + 0.007, 0]
            root.addChild(rod)
        }

        let board = model(.box([size.x, size.y, 0.006]),
                                      Palette.ghostGrey, flat: flat, name: "BordPaneel")
        root.addChild(board)

        let rim = model(.box([size.x + 0.007, size.y + 0.007, 0.004]),
                                    Palette.sandyWood, flat: flat, name: "BordLijst")
        rim.position = [0, 0, -0.002]
        root.addChild(rim)

        // A cake and a star standing proud of the board — raised, never recessed,
        // because a recess wants the occlusion this style does not have.
        let cake = model(.taperedPrism(bottomRadius: 0.009, topRadius: 0.007,
                                                   height: 0.010, sides: 8),
                                     Palette.ghostGrey, flat: flat, name: "BordTaart")
        cake.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        cake.position = [-size.x * 0.20, -size.y * 0.04, 0.005]
        root.addChild(cake)

        let star = model(.star(points: 5, outerRadius: 0.010,
                                           innerRadius: 0.004, thickness: 0.004),
                                     Palette.ghostGrey, flat: flat, name: "BordSter")
        star.position = [size.x * 0.22, size.y * 0.02, 0.005]
        root.addChild(star)

        root.excludeFromShadowCasting()
        return Sign(root: root, board: board, cake: cake, star: star)
    }

    // MARK: - The order hook and the wish card

    /// The hook by the back door — `references/bakkerij/bestelhaak.png`: a square
    /// backplate with a two-segment hook.
    static func orderHook(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Bestelhaak"
        root.position = BakkerijLayout.hookCentre
        // The left wall faces +X, so everything on it is turned a quarter turn.
        root.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

        let plate = model(.box([0.018, 0.018, 0.004]),
                                      Palette.sandyWood, flat: flat, name: "HaakPlaat")
        root.addChild(plate)

        let stem = model(.box([0.004, 0.014, 0.004]),
                                     Palette.blushPinkDeep, flat: flat, name: "HaakSteel")
        stem.position = [0, -0.008, 0.004]
        root.addChild(stem)

        let lip = model(.box([0.004, 0.004, 0.009]),
                                    Palette.blushPinkDeep, flat: flat, name: "HaakPunt")
        lip.position = [0, -0.013, 0.007]
        root.addChild(lip)

        root.excludeFromShadowCasting()
        return root
    }

    /// **The wish card**, which she hangs. §6.1: *"the wish card is something she
    /// hangs, not something that appears… earning it with a drag is what stops it
    /// reading as chrome."*
    ///
    /// A flat cream card with **one shape on it and nothing else** — the plate's
    /// finding, reproduced from the retired clay one: a single golden droplet is
    /// legible at thumbnail size and needs no text. The shape is the friend's own
    /// wish, so the card she hangs is the card she will see in the corner all
    /// round.
    ///
    /// **Square corners.** The plate rounded them, which `../REFERENCES.md` §1
    /// rules out; it is the only bevel in the set and it is on the one prop made
    /// of paper.
    static func wishCard(for friend: Friend, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Wenskaart"

        let card = model(.box([0.026, 0.032, 0.002]),
                                     Palette.creamLight, flat: flat, name: "KaartPapier")
        root.addChild(card)

        let mark = wishMark(for: friend, flat: flat)
        mark.position = [0, 0, 0.0022]
        root.addChild(mark)

        return root
    }

    /// The one shape a wish card carries. Each is the friend's wish said as an
    /// object rather than as a word, which is the whole design of the card.
    static func wishMark(for friend: Friend, flat: Bool) -> Entity {
        let node = Entity()
        node.name = "KaartTeken"

        switch friend.wish {
        case .kleur(let colour):
            // A colour wish is a blob of that colour, and nothing else.
            // `CakeColour.base` is the same value the cake itself is baked in, so
            // the card cannot drift from the thing it is asking for.
            let blob = model(.prism(radius: 0.009, height: 0.003, sides: 10),
                                         colour.base, flat: flat, name: "KaartKleur")
            blob.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            node.addChild(blob)
        case .effect(let effect):
            switch effect {
            case .fonkelt, .glimt:
                // Kiki's glitter. `glimt` is here to keep the switch total —
                // no friend wishes for it, and if one ever does, a star is the
                // honest drawing of "it shines" too.
                let star = model(.star(points: 5, outerRadius: 0.010,
                                                   innerRadius: 0.004, thickness: 0.003),
                                             Palette.butterYellow, flat: flat,
                                             name: "KaartGlitter")
                node.addChild(star)
            case .hoog:
                // A tall cloud: two lumps and a taller one, which is Wolkje's wish.
                for (dx, r) in [(Float(-0.007), Float(0.005)), (0.000, 0.007),
                                (0.007, 0.005)] {
                    let puff = model(.icosphere(radius: r, subdivisions: 0),
                                                 Palette.creamLight, flat: flat,
                                                 name: "KaartWolk")
                    puff.position = [dx, 0, 0]
                    node.addChild(puff)
                }
            }
        case .sprinkels:
            // Many little ones, because Pip's wish is a quantity.
            let colours = [Palette.rose, Palette.mint, Palette.butterYellow,
                           Palette.lilac, Palette.sage]
            for i in 0..<9 {
                let a = Float(i) * 0.9
                let bit = model(.box([0.004, 0.0018, 0.0018]),
                                            colours[i % colours.count], flat: flat,
                                            name: "KaartSprinkel")
                bit.orientation = simd_quatf(angle: a, axis: [0, 0, 1])
                bit.position = [cos(a) * 0.008, sin(a * 1.7) * 0.008, 0]
                node.addChild(bit)
            }
        case .stickers(let kind, let count):
            // Three of the thing, laid in a row — the count is the wish.
            for i in 0..<min(count, 3) {
                let one = VersierProps.sticker(kind, flat: flat)
                one.position = [Float(i - 1) * 0.009, 0, 0]
                one.scale = .init(repeating: 0.75)
                node.addChild(one)
            }
        case .tweeKleuren:
            // Nel's shell: two colours through each other.
            for (i, colour) in [Palette.rose, Palette.mint].enumerated() {
                let half = model(.prism(radius: 0.008, height: 0.003, sides: 10),
                                             colour, flat: flat, name: "KaartTweeKleur")
                half.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                half.position = [Float(i) * 0.007 - 0.0035, Float(i) * 0.004 - 0.002, 0]
                node.addChild(half)
            }
        }
        return node
    }

    // MARK: - The toys

    /// **The cat asleep on the counter** — `references/bakkerij/poes.png`.
    /// Curled in a ball, nose tucked to tail, ears folded, eyes two closed curves.
    ///
    /// This is the prop that looked like it might need Blender, and does not: the
    /// body is a squashed icosphere, the head another, the ears two prisms and the
    /// tail a lathe curled round the side. `models/README.md`'s test — *"there is
    /// no facet the lathe cannot already make"* — holds.
    static func cat(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Poes"
        root.position = BakkerijLayout.catCentre

        let body = model(.icosphere(radius: 0.016, subdivisions: 1),
                                     Palette.blushPink, flat: flat, name: "PoesLijf")
        body.scale = [1.25, 0.80, 1.0]
        root.addChild(body)

        let head = model(.icosphere(radius: 0.011, subdivisions: 1),
                                     Palette.blushPink, flat: flat, name: "PoesKop")
        head.position = [-0.014, 0.002, 0.007]
        root.addChild(head)

        // A cream chest, the one place the plate breaks the single colour.
        let chest = model(.icosphere(radius: 0.008, subdivisions: 0),
                                      Palette.creamLight, flat: flat, name: "PoesBorst")
        chest.scale = [1.2, 0.7, 1.0]
        chest.position = [-0.008, -0.006, 0.011]
        root.addChild(chest)

        for side: Float in [-1, 1] {
            let ear = model(.prism(radius: 0.005, height: 0.004, sides: 3),
                                        Palette.blushPinkDeep, flat: flat, name: "PoesOor")
            ear.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            ear.position = [-0.017, 0.009, 0.007 + side * 0.006]
            root.addChild(ear)
        }

        // Two closed eyes and a nose — the whole face, and enough of it.
        for side: Float in [-1, 1] {
            let eye = model(.box([0.005, 0.0012, 0.0012]),
                                        Palette.woodBrown, flat: flat, name: "PoesOog")
            eye.position = [-0.021, 0.002, 0.007 + side * 0.005]
            root.addChild(eye)
        }
        let nose = model(.prism(radius: 0.002, height: 0.002, sides: 3),
                                     Palette.blushPinkDeep, flat: flat, name: "PoesNeus")
        nose.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        nose.position = [-0.023, -0.002, 0.007]
        root.addChild(nose)

        // The tail, curled round the near side to meet the nose.
        let tail = model(.lathe(profile: [[0.003, 0], [0.0035, 0.010],
                                                      [0.002, 0.020]], sides: 6),
                                     Palette.blushPink, flat: flat, name: "PoesStaart")
        tail.orientation = simd_quatf(angle: 1.5, axis: [1, 0, 0])
        tail.position = [0.004, -0.004, 0.014]
        root.addChild(tail)

        return root
    }

    struct Radio {
        let root: Entity
        /// The dial, which turns when the music goes on.
        let dial: Entity
    }

    /// The little radio — `references/bakkerij/radio.png`. It came back blush
    /// pink and with a fifteen-slat grille when it was asked for mint and thick
    /// slats; the silhouette is what was taken from it — body, carry handle, round
    /// grille, octagon dial — and the colour comes from `Palette` as it does for
    /// every prop in the game.
    static func radio(flat: Bool) -> Radio {
        let root = Entity()
        root.name = "Radio"
        root.position = BakkerijLayout.radioCentre

        let body = model(.box([0.030, 0.020, 0.016]),
                                     Palette.mint, flat: flat, name: "RadioKast")
        root.addChild(body)

        let base = model(.box([0.032, 0.003, 0.018]),
                                     Palette.sandyWood, flat: flat, name: "RadioVoet")
        base.position = [0, -0.011, 0]
        root.addChild(base)

        // The carry handle, an arc of three boxes — cheaper than a torus and it
        // reads the same at this size.
        let handle = Entity()
        handle.name = "RadioHandvat"
        for (dx, dy, angle) in [(Float(-0.010), Float(0.013), Float(0.6)),
                                (0.000, 0.017, 0.0),
                                (0.010, 0.013, -0.6)] {
            let piece = model(.box([0.011, 0.003, 0.003]),
                                          Palette.blushPinkDeep, flat: flat,
                                          name: "RadioBeugel")
            piece.orientation = simd_quatf(angle: angle, axis: [0, 0, 1])
            piece.position = [dx, dy, 0]
            handle.addChild(piece)
        }
        root.addChild(handle)

        // The grille: one coarse disc with four thick slats over it, which is the
        // plate's fifteen cut down to what this style says.
        let grille = model(.prism(radius: 0.008, height: 0.002, sides: 10),
                                       Palette.creamLight, flat: flat, name: "RadioRooster")
        grille.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        grille.position = [-0.008, 0.001, 0.009]
        root.addChild(grille)
        for i in 0..<4 {
            let slat = model(.box([0.013, 0.0016, 0.001]),
                                         Palette.sandyWood, flat: flat, name: "RadioLat")
            slat.position = [-0.008, 0.005 - Float(i) * 0.0035, 0.010]
            root.addChild(slat)
        }

        let dial = Entity()
        dial.name = "RadioKnop"
        dial.position = [0.009, 0.000, 0.009]
        root.addChild(dial)
        let knob = model(.prism(radius: 0.005, height: 0.003, sides: 8),
                                     Palette.butterYellow, flat: flat, name: "RadioKnopBol")
        knob.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        dial.addChild(knob)

        return Radio(root: root, dial: dial)
    }

    /// **Her own drawings**, pinned beside the wall of frames — §6.1's fifth toy
    /// and `CONCEPT.md` §6's personalisation. `references/bakkerij/tekeningen.png`
    /// drew them lying on a table; they hang on the wall, and what was taken from
    /// the plate is the sheets, the thick relief shapes and the faceted pin heads.
    static func drawings(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Tekeningen"
        root.position = BakkerijLayout.drawingsCentre
        root.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

        // Three sheets, overlapping and each a little askew — the plates agree
        // across two styles that a literal grid comes back as a warmer irregular
        // cluster, and that it is the design rather than a failure.
        let sheets: [(Float, Float, Float)] = [(-0.016, 0.003, 0.10),
                                               (0.000, -0.002, -0.06),
                                               (0.016, 0.002, 0.13)]
        for (i, layout) in sheets.enumerated() {
            let (dx, dy, tilt) = layout
            let sheet = Entity()
            sheet.orientation = simd_quatf(angle: tilt, axis: [0, 0, 1])
            sheet.position = [dx, dy, Float(i) * 0.0012]
            root.addChild(sheet)

            let paper = model(.box([0.022, 0.026, 0.001]),
                                          Palette.creamLight, flat: flat,
                                          name: "TekeningPapier")
            sheet.addChild(paper)

            let mark: Entity
            switch i {
            case 0:
                mark = model(.prism(radius: 0.006, height: 0.002, sides: 3),
                                         Palette.rose, flat: flat, name: "TekeningHart")
            case 1:
                mark = model(.star(points: 8, outerRadius: 0.007,
                                               innerRadius: 0.004, thickness: 0.002),
                                         Palette.butterYellow, flat: flat,
                                         name: "TekeningZon")
            default:
                mark = model(.star(points: 5, outerRadius: 0.007,
                                               innerRadius: 0.005, thickness: 0.002),
                                         Palette.sage, flat: flat, name: "TekeningBloem")
            }
            mark.position = [0, 0, 0.0012]
            sheet.addChild(mark)

            let pin = model(.prism(radius: 0.002, height: 0.003, sides: 6),
                                        [Palette.berryBlue, Palette.rose,
                                         Palette.sage][i], flat: flat, name: "TekeningPunaise")
            pin.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            pin.position = [0, 0.011, 0.002]
            sheet.addChild(pin)
        }

        root.excludeFromShadowCasting()
        return root
    }

    // MARK: - The photograph

    /// **What she carries home from the party.** A cream mount with the cake
    /// standing on it, which is the same thing the frame will hold — so hanging it
    /// is the photograph *arriving where it belongs* rather than one object being
    /// swapped for another.
    static func photograph(of fill: FrameFill, friend: Friend?, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Foto"

        let mount = model(.box([0.034, 0.038, 0.003]),
                                      Palette.creamLight, flat: flat, name: "FotoKaart")
        root.addChild(mount)

        let picture = FrameWall.picture(of: fill, friend: friend,
                                        scale: BakkerijLayout.photoCakeScale, flat: flat)
        picture.position = [0, -0.010, 0.002]
        root.addChild(picture)

        return root
    }

    private static func model(_ shape: RoomBuilder.Shape, _ colour: UIColorLike,
                              flat: Bool, name: String) -> ModelEntity {
        RoomBuilder.model(shape, BakkerijAO.paint(colour, name: name),
                          flat: flat, name: name)
    }
}
