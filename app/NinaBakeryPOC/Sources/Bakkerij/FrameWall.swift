import Foundation
import RealityKit
import simd

/// **The wall of twelve frames — the game's only progression, and the only room
/// contents in the project that are saved state rather than props.**
/// `GAMEPLAY.md` §2 and §6.1.
///
/// A frame is in one of two states and there is no third:
///
/// - **A grey ghost**, waiting. A pale panel with the friend's silhouette on it.
/// - **A photograph**, which is *the cake she actually made*, rebuilt from the
///   stored `CakeSpec`.
///
/// **The photograph is a render, never a screenshot.** §6.1 is explicit about
/// why: *"a screenshot ties the wall to the resolution it was taken at and to
/// whatever the camera was doing that day."* `Sticker` anchors itself in
/// cake-local polar coordinates precisely so this is possible — `CakeSurface` was
/// written for the decorating room, the party re-renders every sticker from it at
/// 1.8×, and this does the same at 0.36×. Nothing was added to the spec to get a
/// cake onto the wall, which is the same tell `RoomExit.feest` carries: the
/// contract was right.
///
/// **The silhouette on a ghost is built from the friend, not drawn.** It is the
/// same head shapes `GuestCharacter` puts on a body — ears and a muzzle — flattened
/// into a panel. So a ghost of Bo is bird-shaped and a ghost of Mo is mole-shaped
/// for the same reason the guests are, and the day an animal's ears change, both
/// change together.
enum FrameWall {

    /// The name every frame's touchable node carries, so the room can find one
    /// again without keeping a parallel array.
    static func nodeName(for friend: Friend) -> String { "Lijst-\(friend.rawValue)" }
    static let goldNodeName = "Lijst-goud"

    // MARK: - A frame

    struct Frame {
        let root: Entity
        /// What the frame is holding — swapped when a photo is hung.
        let inside: Entity
        /// The moulding, which glows for a moment when a photo lands in it.
        let moulding: ModelEntity
        let friend: Friend?
        let isGold: Bool
    }

    /// Build one frame in whichever state the wall says it is in.
    static func frame(for friend: Friend, fill: FrameFill?, flat: Bool) -> Frame {
        let size = BakkerijLayout.frameSize
        let root = Entity()
        root.name = nodeName(for: friend)
        root.position = BakkerijLayout.framePosition(for: friend)
        // The left wall faces +X, so everything hung on it takes a quarter turn
        // and is then built in its own XY plane.
        root.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

        let moulding = buildMoulding(size: size, colour: Palette.cream, flat: flat)
        root.addChild(moulding)

        let inside = Entity()
        inside.name = "LijstInhoud"
        inside.position = [0, 0, 0.004]
        root.addChild(inside)

        if let fill {
            inside.addChild(picture(of: fill, friend: friend,
                                    scale: BakkerijLayout.photoCakeScale, flat: flat))
        } else {
            inside.addChild(ghost(of: friend, size: size, flat: flat))
        }

        root.excludeFromShadowCasting()
        return Frame(root: root, inside: inside, moulding: moulding,
                     friend: friend, isGold: false)
    }

    /// **The twelfth frame, and it is Nina's own.** Owner's call, 2026-08-16.
    /// Larger and gold, and it stays grey until the other eleven are in colour —
    /// §2: *"the only thing in the game that waits, and it is worth the
    /// exception."*
    static func goldFrame(earned: Bool, fill: FrameFill?, flat: Bool) -> Frame {
        let size = BakkerijLayout.goldSize
        let root = Entity()
        root.name = goldNodeName
        root.position = BakkerijLayout.goldPosition
        root.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

        // Gold when it has been earned, and the same waiting grey as everything
        // else before that — the difference between this frame and the eleven is
        // that it is bigger and that nobody is behind it, not that it shouts.
        let moulding = buildMoulding(size: size,
                                     colour: earned ? Palette.butterYellow : Palette.cream,
                                     flat: flat)
        root.addChild(moulding)

        let inside = Entity()
        inside.name = "LijstInhoud"
        inside.position = [0, 0, 0.004]
        root.addChild(inside)

        if let fill {
            // Nina's own frame has no friend standing beside the cake — the
            // twelfth cake is for the bakery, and GAMEPLAY.md §4 is explicit that
            // nobody comes to the door on the last round.
            inside.addChild(picture(of: fill, friend: nil,
                                    scale: BakkerijLayout.goldCakeScale, flat: flat))
        } else {
            // Nina's own ghost is not an animal. It is her hat — the one shape on
            // the wall that is hers, and the plate's fairy silhouette reduced to
            // the part a 4-year-old picks out of eleven animal heads instantly.
            inside.addChild(ninaGhost(size: size, earned: earned, flat: flat))
        }

        root.excludeFromShadowCasting()
        return Frame(root: root, inside: inside, moulding: moulding,
                     friend: nil, isGold: true)
    }

    // MARK: - The parts

    /// Four sides and a back panel. A mitred-looking box frame, standing proud of
    /// the plaster so it has a lit edge at this camera.
    private static func buildMoulding(size: Float, colour: UIColorLike,
                                      flat: Bool) -> ModelEntity {
        let bar: Float = 0.006
        let depth = BakkerijLayout.frameDepth

        // The back panel *is* the model entity the frame is identified by, so the
        // glow on hanging has one material to change rather than four.
        let back = model(.box([size, size, 0.003]),
                                     colour, flat: flat, name: "LijstPaneel")

        for side: Float in [-1, 1] {
            let upright = model(.box([bar, size + bar * 2, depth]),
                                            colour, flat: flat, name: "LijstStijl")
            upright.position = [side * (size + bar) / 2, 0, depth / 2]
            back.addChild(upright)

            let rail = model(.box([size + bar * 2, bar, depth]),
                                         colour, flat: flat, name: "LijstRegel")
            rail.position = [0, side * (size + bar) / 2, depth / 2]
            back.addChild(rail)
        }
        return back
    }

    /// **A waiting friend.** A pale panel with their silhouette standing on it.
    private static func ghost(of friend: Friend, size: Float, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "LijstSpook"

        let panel = model(.box([size - BakkerijLayout.photoInset * 2,
                                            size - BakkerijLayout.photoInset * 2, 0.002]),
                                      Palette.ghostGrey, flat: flat, name: "SpookPaneel")
        root.addChild(panel)

        let head = silhouette(of: friend.soort, flat: flat)
        head.position = [0, -0.002, 0.002]
        root.addChild(head)

        return root
    }

    /// The friend's head as one flat grey shape — a body lump, a head, and the
    /// ears or the beak that say which animal it is. Deliberately the same
    /// vocabulary `GuestCharacter.buildFace` uses, flattened.
    private static func silhouette(of soort: Friend.Soort, flat: Bool) -> Entity {
        let node = Entity()
        node.name = "SpookVorm"
        let grey = Palette.ghostGreyDeep

        // The body: one lump, wider than it is tall, sitting low in the frame.
        let body = model(.prism(radius: 0.010, height: 0.002, sides: 10),
                                     grey, flat: flat, name: "SpookLijf")
        body.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        body.scale = [1.0, 1.0, 0.72]
        body.position = [0, -0.008, 0]
        node.addChild(body)

        let head = model(.prism(radius: 0.008, height: 0.002, sides: 10),
                                     grey, flat: flat, name: "SpookKop")
        head.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        head.position = [0, 0.005, 0]
        node.addChild(head)

        /// Two ears of a given shape, one each side.
        func ears(dx: Float, dy: Float, radius: Float, sides: Int, tilt: Float = 0) {
            for side: Float in [-1, 1] {
                let ear = model(.prism(radius: radius, height: 0.002,
                                                   sides: sides),
                                            grey, flat: flat, name: "SpookOor")
                ear.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                    * simd_quatf(angle: side * tilt, axis: [0, 1, 0])
                ear.position = [side * dx, dy, 0]
                node.addChild(ear)
            }
        }

        switch soort {
        case .muis:
            ears(dx: 0.007, dy: 0.011, radius: 0.005, sides: 10)
        case .kat:
            ears(dx: 0.005, dy: 0.012, radius: 0.004, sides: 3)
        case .beer:
            ears(dx: 0.006, dy: 0.011, radius: 0.004, sides: 10)
        case .hond:
            // Ears down rather than up, which is the whole difference at this size.
            ears(dx: 0.008, dy: 0.004, radius: 0.004, sides: 10)
        case .kikker:
            // Eyes on top, not ears.
            ears(dx: 0.005, dy: 0.012, radius: 0.004, sides: 10)
        case .vlinder:
            // Wings, which are bigger than the body and are the silhouette.
            for side: Float in [-1, 1] {
                let wing = model(.prism(radius: 0.009, height: 0.002, sides: 3),
                                             grey, flat: flat, name: "SpookVleugel")
                wing.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                    * simd_quatf(angle: side * 0.5, axis: [0, 1, 0])
                wing.position = [side * 0.011, -0.004, -0.001]
                node.addChild(wing)
            }
        case .vogel:
            let beak = model(.prism(radius: 0.004, height: 0.002, sides: 3),
                                         grey, flat: flat, name: "SpookSnavel")
            beak.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                * simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
            beak.position = [0.009, 0.005, 0]
            node.addChild(beak)
        case .schaap:
            // A woolly outline: three lumps around the head.
            for a: Float in [2.2, 3.14, 4.1] {
                let curl = model(.prism(radius: 0.004, height: 0.002, sides: 10),
                                             grey, flat: flat, name: "SpookWol")
                curl.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                curl.position = [cos(a) * 0.009, 0.005 + sin(a) * 0.009, -0.001]
                node.addChild(curl)
            }
        case .mol:
            // A snout, and no ears at all.
            let snout = model(.prism(radius: 0.004, height: 0.002, sides: 10),
                                          grey, flat: flat, name: "SpookSnuit")
            snout.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            snout.position = [0.008, 0.003, 0]
            node.addChild(snout)
        case .egel:
            // Spines along the back.
            for i in 0..<5 {
                let spine = model(.prism(radius: 0.003, height: 0.002, sides: 3),
                                              grey, flat: flat, name: "SpookStekel")
                let a = 2.0 + Float(i) * 0.42
                spine.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                    * simd_quatf(angle: a - 1.6, axis: [0, 1, 0])
                spine.position = [cos(a) * 0.011, -0.008 + sin(a) * 0.011, -0.001]
                node.addChild(spine)
            }
        case .slak:
            // The shell, which is Nel's whole silhouette and her whole wish.
            let shell = model(.prism(radius: 0.009, height: 0.002, sides: 10),
                                          grey, flat: flat, name: "SpookHuisje")
            shell.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            shell.position = [-0.006, -0.006, -0.001]
            node.addChild(shell)
        }
        return node
    }

    /// Nina's own frame, waiting. Her hat, which is the shape she is on every
    /// plate the project has of her.
    private static func ninaGhost(size: Float, earned: Bool, flat: Bool) -> Entity {
        let root = Entity()
        root.name = "LijstSpookNina"

        let panel = model(.box([size - BakkerijLayout.photoInset * 2,
                                            size - BakkerijLayout.photoInset * 2, 0.002]),
                                      earned ? Palette.creamLight : Palette.ghostGrey,
                                      flat: flat, name: "SpookPaneel")
        root.addChild(panel)

        let tint = earned ? Palette.mint : Palette.ghostGreyDeep

        let cone = model(.taperedPrism(bottomRadius: 0.011, topRadius: 0.001,
                                                   height: 0.018, sides: 8),
                                     tint, flat: flat, name: "SpookHoed")
        cone.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        cone.position = [0, 0.002, 0.002]
        root.addChild(cone)

        let brim = model(.prism(radius: 0.014, height: 0.002, sides: 10),
                                     tint, flat: flat, name: "SpookRand")
        brim.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        brim.scale = [1, 1, 0.35]
        brim.position = [0, -0.008, 0.002]
        root.addChild(brim)

        return root
    }

    // MARK: - The photograph itself

    /// **A stored cake, rebuilt.** The same three calls the party makes —
    /// `KitchenProps.cake` for the stack, `VersierProps.sticker` for everything
    /// she pressed on, `CakeSurface` to put them back where she put them.
    ///
    /// `scale` is what makes a 52 mm cake fit a 40 mm frame. It is applied to the
    /// whole node rather than to the geometry, so the stickers' own polar anchors
    /// keep working untouched — `CakeSurface` is asked for positions at the cake's
    /// real size and the result is shrunk, which is the only order that keeps a
    /// candle on the rim it was placed on.
    static func picture(of fill: FrameFill, friend: Friend?, scale: Float,
                        flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Foto-inhoud"

        let node = Entity()
        node.name = "FotoTaart"
        node.scale = .init(repeating: scale)
        root.addChild(node)

        let cake = KitchenProps.cake(fill.cake, flat: flat)
        node.addChild(cake)

        // The decorations, from the spec's own anchors. `CakeSurface` at the
        // cake's true size; the shrink is the parent's.
        let surface = CakeSurface(origin: .zero, scale: 1, turn: 0,
                                  tall: fill.cake.isTall)
        for sticker in fill.cake.placed {
            let one = VersierProps.sticker(sticker.kind, flat: flat)
            let normal = surface.localNormal(of: sticker.at)
            one.position = surface.localPosition(of: sticker.at)
                + normal * (sticker.kind.size * 0.12)
            let up: SIMD3<Float> = sticker.kind == .kaarsje ? [0, 1, 0] : normal
            one.orientation = simd_quatf(from: [0, 1, 0], to: up)
                * simd_quatf(angle: sticker.spin, axis: [0, 1, 0])
            // A candle she lit is still lit in the photograph. It is the same
            // argument the party makes for carrying `lit` across a doorway, and
            // the wall is the doorway that lasts longest.
            if sticker.kind == .kaarsje, sticker.lit == true,
               let flame = one.findEntity(named: VersierProps.flameName) as? ModelEntity {
                flame.model?.materials = [Palette.glowMaterial(Palette.butterYellow,
                                                               intensity: 2.2)]
            }
            node.addChild(one)
        }

        // The friend, standing beside their cake. §6.6: *"a photo of her cake
        // with the friend beside it."*
        //
        // `friend` is passed in rather than read off the fill, because a
        // `FrameFill` deliberately does not name one — the wall's dictionary key
        // does. Storing it twice is how a photograph ends up showing a different
        // animal from the frame it is hanging in.
        if let friend {
            let beside = miniFriend(friend, flat: flat)
            beside.position = [0.030, 0, 0.004]
            node.addChild(beside)
        }

        return root
    }

    /// The friend beside the cake, at photograph size.
    ///
    /// A flat silhouette in their own colours rather than a whole
    /// `GuestCharacter`: a guest is a hundred-odd entities, there can be twelve of
    /// these on the wall at once, and at this size a body, a head and two ears is
    /// all that survives anyway.
    private static func miniFriend(_ friend: Friend, flat: Bool) -> Entity {
        let node = Entity()
        node.name = "FotoVriendje"

        let body = model(.prism(radius: 0.009, height: 0.003, sides: 10),
                                     friend.colour, flat: flat, name: "FotoLijf")
        body.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        body.scale = [1, 1, 0.8]
        body.position = [0, 0.009, 0]
        node.addChild(body)

        let head = model(.prism(radius: 0.007, height: 0.003, sides: 10),
                                     friend.colour, flat: flat, name: "FotoKop")
        head.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        head.position = [0, 0.022, 0]
        node.addChild(head)

        for side: Float in [-1, 1] {
            let ear = model(.prism(radius: 0.004, height: 0.003,
                                               sides: friend.soort == .kat ? 3 : 10),
                                        friend.accent, flat: flat, name: "FotoOor")
            ear.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            ear.position = [side * 0.006, 0.029, -0.001]
            node.addChild(ear)
        }
        return node
    }

    private static func model(_ shape: RoomBuilder.Shape, _ colour: UIColorLike,
                              flat: Bool, name: String) -> ModelEntity {
        RoomBuilder.model(shape, BakkerijAO.paint(colour, name: name),
                          flat: flat, name: name)
    }
}
