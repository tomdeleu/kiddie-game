import RealityKit
import simd

/// **Props more than one room uses.**
///
/// Three ways out, one `Doorway`: a wood leaf, a garden gate, and the disco's
/// velvet rope. `ROOMS.md` §9 gives every room the same behaviour — ajar, what
/// you see through the opening, a ring on the floor at the threshold — and
/// none of that is about a kitchen. The disco's posts and rope are a different
/// *prop* standing in the same *place*; its opening is evening sky rather than
/// the next room's light, because the party is at night.
///
/// The dimensions stay in `Layout`: a door is the same door in every room, and
/// `KitchenLayout.doorOpening` is taller than Nina on purpose (a door she could not
/// walk through is a cupboard).
enum Props {

    /// **A way out**, whether it is a door in a wall or a gate in a fence.
    ///
    /// All three builders return this, which is what lets a room's door behaviour —
    /// ajar when the room is finished, the swing, the ring at the threshold — be
    /// written once and used by both.
    struct Doorway {
        let root: Entity
        /// **The thing that moves.** The leaf, its
        /// panels and its knob all hang under this, so opening it is one
        /// rotation about Y — `CONCEPT.md` §9.7's animation budget, spent the
        /// same way Otto's mouth spends it.
        let hinge: Entity
        /// What you see through the opening. Flat against the wall behind the
        /// leaf, so it is only visible while the door stands open — which is
        /// what makes opening it worth doing. In the kitchen and decorating
        /// room this is the next room's light; in the disco it is evening
        /// outside.
        ///
        /// **Optional, because a gate has no wall to hold one.** `ROOMS.md` §9
        /// asks the way out to say the same thing three ways, and the garden's
        /// says it twice: the light behind it was dropped on the owner's call,
        /// since you can already see straight through a picket fence and there
        /// is nothing behind it to light. Nil rather than a hidden entity
        /// nobody assigns to — dead geometry that looks live is worse than an
        /// optional.
        let glow: ModelEntity?
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
    /// `centre` is where it stands on the left wall. Both rooms so far put it in
    /// the same place, which is deliberate rather than lazy — the way out being
    /// where it was last time is worth more to a 4-year-old than variety is —
    /// but it is a parameter so that the day a room needs it elsewhere is an
    /// argument rather than a fork.
    static func doorway(flat: Bool,
                        centre: SIMD3<Float> = KitchenLayout.doorwayCentre) -> Doorway {
        let root = Entity()
        root.name = "Doorway"
        root.position = centre
        // Built in the XY plane extruded along Z; a +90° turn about Y sends its
        // front face down +X, which is the way the left wall looks. So local +X
        // runs towards the back wall and local +Z out into the room.
        root.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

        let open = KitchenLayout.doorOpening
        let jamb = KitchenLayout.doorFrameWidth
        let depth = KitchenLayout.doorFrameDepth
        let leafThickness = KitchenLayout.doorLeafThickness

        // The next room: a plate of light standing 1 mm clear of the wall face,
        // deep inside the frame. Clear of it rather than flush, because two
        // coplanar surfaces flicker against each other; behind the leaf, so it
        // is hidden until the door opens.
        let glow = RoomBuilder.model(.box([open.x, open.y, 0.002]),
                                     Palette.butterYellow, flat: flat, name: "DoorwayGlow")
        glow.position = [0, open.y / 2, KitchenLayout.doorWallFace + 0.002]
        root.addChild(glow)

        // Frame: two jambs standing on the floor and a lintel across them. It
        // reaches 4 mm back into the wall and stands 12 mm proud of it — a
        // casing chunky enough to have a visible side at this camera, which is
        // most of what stops the door reading as painted on.
        for side: Float in [-1, 1] {
            let post = RoomBuilder.model(.box([jamb, open.y, depth]),
                                         Palette.rose, flat: flat, name: "DoorwayJamb")
            post.position = [side * (open.x + jamb) / 2, open.y / 2, KitchenLayout.doorFrameZ]
            root.addChild(post)
        }
        let lintel = RoomBuilder.model(.box([open.x + jamb * 2, jamb, depth]),
                                       Palette.rose, flat: flat, name: "DoorwayLintel")
        lintel.position = [0, open.y + jamb / 2, KitchenLayout.doorFrameZ]
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
        hinge.position = [-open.x / 2, 0, KitchenLayout.doorLeafZ]
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

    // MARK: - The gate

    /// **The garden's way out: a gate in the fence.**
    ///
    /// From `references/garden/fence-gate.png`: a leaf of five pickets on two
    /// rails with one **diagonal cross-brace**, hung on two strap hinges between
    /// two taller posts, with a latch on the swinging edge. The posts and the
    /// pickets are the fence's own — `GardenRoomBuilder.addRun` leaves the gap
    /// and builds the posts, and this builds only what swings.
    ///
    /// **The brace is not decoration.** It is the one part of the plate that
    /// makes a gate read as a gate rather than as a piece of fence that fell
    /// over: five vertical boards and two horizontals are a fence, and a
    /// diagonal across them is a thing that opens.
    ///
    /// It returns the same `Doorway` as `doorway(flat:centre:)` and `vipRope`, so
    /// a room's ajar-swing-ring behaviour is untouched. Its `glow` is nil
    /// — see the field.
    ///
    /// **No lintel.** A gate's opening is the full-height gap between its posts,
    /// so `CONCEPT.md`'s "a door she could not walk through is a cupboard" is
    /// satisfied by construction rather than by making the leaf taller than she
    /// is.
    static func gate(flat: Bool, centre: SIMD3<Float>) -> Doorway {
        let root = Entity()
        root.name = "Gate"
        root.position = centre
        // Same local frame as the door: built in XY and extruded along Z, then
        // turned so local +X runs towards the back of the room and local +Z out
        // into it.
        root.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

        let opening = GardenLayout.gateOpening
        let height = GardenLayout.fenceHeight
        let thickness: Float = 0.007

        // **Hinged on the near side**, local −X, which is the corner of the room
        // nearest the camera — the same choice the door documents at length, and
        // for the same reason: hinging on the far side swings the leaf away, it
        // turns edge-on at this camera, and it reads as a stick standing in a
        // hole.
        let hinge = Entity()
        hinge.name = "GateHinge"
        hinge.position = [-opening / 2, 0, 0]
        root.addChild(hinge)

        // Five pickets across the opening, with the pointed tops the fence has.
        let picketCount = 5
        let picketWidth = opening / Float(picketCount) * 0.72
        for i in 0..<picketCount {
            let along = (Float(i) + 0.5) / Float(picketCount) * opening
            let board = RoomBuilder.model(.box([picketWidth, height, thickness]),
                                          Palette.cream, flat: flat,
                                          name: "GatePicket\(i)")
            board.position = [along, height / 2, 0]
            hinge.addChild(board)

            let point = RoomBuilder.model(.lathe(profile: [[picketWidth * 0.72, 0],
                                                           [0, 0.0060]],
                                                 sides: 4),
                                          Palette.cream, flat: flat,
                                          name: "GatePoint\(i)")
            point.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
            point.position = [along, height, 0]
            hinge.addChild(point)
        }

        // Two rails behind them, and the brace across.
        for fraction in GardenLayout.fenceRails {
            let rail = RoomBuilder.model(.box([opening - 0.004, 0.008, 0.006]),
                                         Palette.creamLight, flat: flat,
                                         name: "GateRail")
            rail.position = [opening / 2, height * fraction, -thickness / 2 - 0.003]
            hinge.addChild(rail)
        }

        let low = height * GardenLayout.fenceRails[0]
        let high = height * GardenLayout.fenceRails[1]
        let rise = high - low
        let brace = RoomBuilder.model(.box([sqrt(opening * opening + rise * rise) - 0.006,
                                            0.007, 0.006]),
                                      Palette.sandyWood, flat: flat,
                                      name: "GateBrace")
        brace.orientation = simd_quatf(angle: atan2(rise, opening), axis: [0, 0, 1])
        brace.position = [opening / 2, (low + high) / 2, -thickness / 2 - 0.003]
        hinge.addChild(brace)

        // Two strap hinges on the hanging edge, which is the detail that says
        // which side opens before she has touched it.
        for fraction in GardenLayout.fenceRails {
            let strap = RoomBuilder.model(.box([opening * 0.34, 0.005, 0.004]),
                                          Palette.blushPinkDeep, flat: flat,
                                          name: "GateStrap")
            strap.position = [opening * 0.17, height * fraction, thickness / 2 + 0.002]
            hinge.addChild(strap)
        }

        // And a latch on the other, at the height a hand goes for.
        let latch = RoomBuilder.model(.box([0.010, 0.005, 0.004]),
                                      Palette.blushPinkDeep, flat: flat,
                                      name: "GateLatch")
        latch.position = [opening - 0.004, high, thickness / 2 + 0.002]
        hinge.addChild(latch)

        // Everything here stands clear of the ground and casts onto it, which is
        // the grounding the fence gets too — there is no wall left for a shadow
        // to smear across.
        return Doorway(root: root, hinge: hinge, glow: nil)
    }

    // MARK: - The VIP rope

    /// **The disco's way out: a velvet rope on two stanchions, in front of
    /// evening.**
    ///
    /// Owner's call, 2026-08-21: tapping the cake should not end the party, and
    /// the door must not be the kitchen's wood leaf or the garden's gate. Two
    /// butter-yellow posts and a blush rope *are* a door a 4-year-old can read
    /// — they unhook, they show the dark outside, and they stand where the
    /// other rooms put their way out, so the place is the same even though the
    /// prop is not.
    ///
    /// Owner's call, 2026-08-23: the hole is evening, not a cream glow. A lit
    /// plate here would say the next room is as bright as this one, and the
    /// party is at night. The plate in the opening is matte `eveningSky`; the
    /// disco around it stays as bright as every other room. Dark is the
    /// subject of the hole, the same way it is the subject of Otto's mouth.
    ///
    /// It returns the same `Doorway` as the other two. The hinge is the near
    /// post's axis; the rope hangs under it, so the existing ajar-swing-ring
    /// behaviour opens the barrier into the room and leaves the posts standing.
    /// The opening is visible from the first frame, because this room asks her
    /// for nothing and showing the exit is the honest use of the halo
    /// (`ROOMS.md` §9).
    ///
    /// The mesh follows `references/feest/vip-touw.png`: tapered eight-sided
    /// posts, a collar at the neck, metal caps on the rope, a deeper sag. The
    /// lettered sibling of that plate is not a brief. The first keeper filled
    /// the hole with cream light; this mesh overrules that one surface.
    static func vipRope(flat: Bool,
                        centre: SIMD3<Float> = KitchenLayout.doorwayCentre) -> Doorway {
        let root = Entity()
        root.name = "VipTouw"
        root.position = centre
        root.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

        let open = KitchenLayout.doorOpening
        let jamb = KitchenLayout.doorFrameWidth
        let depth = KitchenLayout.doorFrameDepth
        let postZ: Float = 0.018
        let baseH: Float = 0.007
        let postHeight: Float = 0.072
        let ballR: Float = 0.011
        /// Just under the ball — `references/feest/vip-touw.png` hangs the rope
        /// from a collar at the neck, not from mid-post.
        let ropeY: Float = baseH + postHeight
        let gold = Palette.butterYellow
        let ropeColour = Palette.blushPinkDeep
        let metal = Palette.honeyAmber

        // Evening outside, not the next room's light. A cream plate would
        // vanish into this room's plaster; a butter-yellow glow would say day.
        // Matte, not emissive: night is not a lamp.
        let glow = RoomBuilder.model(.box([open.x, open.y, 0.002]),
                                     Palette.eveningSky, flat: flat, name: "VipAvond")
        glow.position = [0, open.y / 2, KitchenLayout.doorWallFace + 0.002]
        root.addChild(glow)

        // Slim butter frame, not the kitchen's rose one. The posts sit in
        // front of cream plaster the same family as themselves; the dark hole
        // is already the separation, and the frame is kept thinner than the
        // kitchen's because the plate has almost none.
        let slim = jamb * 0.7
        for side: Float in [-1, 1] {
            let post = RoomBuilder.model(.box([slim, open.y, depth]),
                                         gold, flat: flat, name: "VipJamb")
            post.position = [side * (open.x + slim) / 2, open.y / 2, KitchenLayout.doorFrameZ]
            root.addChild(post)
        }
        let lintel = RoomBuilder.model(.box([open.x + slim * 2, slim, depth]),
                                       gold, flat: flat, name: "VipLintel")
        lintel.position = [0, open.y + slim / 2, KitchenLayout.doorFrameZ]
        root.addChild(lintel)

        func stanchion(atX x: Float, name: String) {
            let base = RoomBuilder.model(.prism(radius: 0.014, height: baseH, sides: 8),
                                         gold, flat: flat, name: "\(name)Voet")
            base.position = [x, 0, postZ]
            root.addChild(base)

            let pole = RoomBuilder.model(
                .taperedPrism(bottomRadius: 0.007, topRadius: 0.0045,
                              height: postHeight, sides: 8),
                gold, flat: flat, name: "\(name)Paal")
            pole.position = [x, baseH, postZ]
            root.addChild(pole)

            let ball = RoomBuilder.model(.icosphere(radius: ballR, subdivisions: 0),
                                         gold, flat: flat, name: "\(name)Knop")
            ball.position = [x, ropeY + ballR * 0.45, postZ]
            root.addChild(ball)

            // Collar at the neck, the plate's attachment ring. A short fat
            // prism, not a torus: eight sides is already a ring at this size.
            let collar = RoomBuilder.model(.prism(radius: 0.008, height: 0.005, sides: 8),
                                           metal, flat: flat, name: "\(name)Ring")
            collar.position = [x, ropeY - 0.002, postZ]
            root.addChild(collar)
        }
        stanchion(atX: -open.x / 2, name: "VipDichtbij")
        stanchion(atX: open.x / 2, name: "VipVer")

        // Hinge on the near post, so a negative turn about Y swings the rope
        // into the room toward the camera — the same answer the wood leaf and
        // the gate already paid for.
        let hinge = Entity()
        hinge.name = "VipHinge"
        hinge.position = [-open.x / 2, 0, postZ]
        root.addChild(hinge)

        var points: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        let samples = 8
        let span = open.x
        let sagDepth: Float = 0.028
        for i in 0...samples {
            let t = Float(i) / Float(samples)
            let sag = sagDepth * 4 * t * (1 - t)
            points.append([t * span, ropeY - sag, 0.002])
            normals.append([0, 1, 0])
        }
        let cord = RoomBuilder.model(.ribbon(points: points, normals: normals,
                                             width: 0.010, thickness: 0.008),
                                     ropeColour, flat: flat, name: "VipKoord")
        hinge.addChild(cord)

        func endCap(at point: SIMD3<Float>, toward next: SIMD3<Float>, name: String) {
            let cap = RoomBuilder.model(
                .taperedPrism(bottomRadius: 0.005, topRadius: 0.0035,
                              height: 0.010, sides: 6),
                metal, flat: flat, name: name)
            let delta = next - point
            let length = simd_length(delta)
            if length > 1e-6 {
                let dir = delta / length
                let y = SIMD3<Float>(0, 1, 0)
                let axis = simd_cross(y, dir)
                let axisLen = simd_length(axis)
                if axisLen > 1e-6 {
                    cap.orientation = simd_quatf(angle: acos(max(-1, min(1, simd_dot(y, dir)))),
                                                 axis: axis / axisLen)
                }
            }
            cap.position = point
            hinge.addChild(cap)
        }
        endCap(at: points[0], toward: points[1], name: "VipKapDichtbij")
        endCap(at: points[points.count - 1], toward: points[points.count - 2],
               name: "VipKapVer")

        root.excludeFromShadowCasting()
        return Doorway(root: root, hinge: hinge, glow: glow)
    }
}
