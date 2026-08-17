import RealityKit
import simd

/// **One of the eleven friends, dancing.**
///
/// Built from `references/feest/gasten.png`, which is the plate that settled how
/// eleven characters cost one builder: **one shared blocky body, and the animal
/// is entirely in the head.** Five faceted animals came back on that plate and
/// the only thing separating a mouse from a bear from a frog was ears, muzzle and
/// colour. Everything below the neck is identical.
///
/// **The rig is `CONCEPT.md` §9.7 exactly**, the same three parts `BakerCharacter`
/// has: one solid body — head, torso, arms, all one piece — plus two legs that
/// pivot at the hip, on a root that squashes and stretches. Arms never
/// articulate. That constraint is doing more work here than it does for Nina: a
/// dancing crowd is where a rig gets expensive, and a dance made of one bob, one
/// sway and one hop costs the same for six characters as for one.
///
/// ## Everything it does is a function of the beat
///
/// Nothing in here owns a clock. `tick` is handed `FeestBeat` and reads `swing`,
/// `hop` and `count` off it, so all six guests, the mirror ball, the floor and
/// the lamps are provably on the same beat rather than six things that happen to
/// be moving at similar speeds. `GAMEPLAY.md` §6.5: *it is her rhythm they are
/// dancing to, not a recording.*
///
/// `phase` is the guest's own offset into that beat — a sixth of a beat apart, so
/// the row moves like a crowd rather than like a chorus line. It is the one thing
/// that differs between two guests' animation, and it is a constant per guest
/// rather than a random per frame.
@MainActor
final class GuestCharacter {

    /// A guest, or the one behind the decks.
    enum Role {
        case gast
        /// Headphones, no hopping, and he leans over his booth. A DJ who bounced
        /// like the crowd would read as a guest standing in the wrong place.
        case dj
    }

    let root = Entity()
    let friend: Friend
    private let role: Role
    private let body = Entity()
    private let head = Entity()
    private let legs: [Entity]
    private let ticker: Ticker
    private let home: SIMD3<Float>

    /// A sixth of a beat, so six of them read as a crowd.
    private let phase: Float

    private var clock: Float = 0
    /// Counts down while a tapped guest is jumping, and while everybody eats.
    private var jumpTime: Float = 0
    private var eatTime: Float = 0
    /// **The wish matched, so this one is going over the top** —
    /// `GAMEPLAY.md` §4's *"a special move only they do"*. It is a bigger hop and
    /// a spin, not a different animation: a special move that needed its own rig
    /// would be eleven special moves.
    private var showingOff = false
    private var job: Int?

    init(friend: Friend, role: Role = .gast, at home: SIMD3<Float>,
         phase: Float, ticker: Ticker, flat: Bool) {
        self.friend = friend
        self.role = role
        self.ticker = ticker
        self.home = home
        self.phase = phase

        root.name = "Gast-\(friend.rawValue)"
        root.position = home
        // Turned towards the open corner, so nobody is a flat cut-out and
        // everybody is broadly facing the camera and the dance floor.
        root.orientation = simd_quatf(angle: role == .dj ? 0.10 : 0.42, axis: [0, 1, 0])

        let coat = friend.colour
        let accent = friend.accent

        // MARK: Legs — the only parts that move independently.
        var builtLegs: [Entity] = []
        for (i, dx) in [Float(-0.010), 0.010].enumerated() {
            // Pivot at the hip, not at the leg's middle. Rotating a leg about
            // its centre is the classic error and makes it look detached.
            let hip = Entity()
            hip.name = "GastHip\(i)"
            hip.position = [dx, 0.026, 0]
            root.addChild(hip)

            let leg = RoomBuilder.model(.box([0.011, 0.026, 0.011]),
                                        coat, flat: flat, name: "GastLeg\(i)")
            leg.position = [0, -0.013, 0]
            hip.addChild(leg)

            let foot = RoomBuilder.model(.box([0.013, 0.006, 0.015]),
                                         accent, flat: flat, name: "GastFoot\(i)")
            foot.position = [0, -0.027, 0.002]
            hip.addChild(foot)

            builtLegs.append(hip)
        }
        legs = builtLegs

        // MARK: Body — one solid piece from the hips up.
        body.name = "GastBody"
        body.position = [0, 0.026, 0]
        root.addChild(body)

        let torso = RoomBuilder.model(.box([0.030, 0.036, 0.019]),
                                      coat, flat: flat, name: "GastTorso")
        torso.position = [0, 0.018, 0]
        body.addChild(torso)

        // A pale front panel, which is what the plate's animals all have and
        // what stops six solid-colour blocks reading as six bollards.
        let front = RoomBuilder.model(.box([0.019, 0.022, 0.003]),
                                      accent, flat: flat, name: "GastBuik")
        front.position = [0, 0.014, 0.010]
        body.addChild(front)

        for (i, dx) in [Float(-0.020), 0.020].enumerated() {
            let arm = RoomBuilder.model(.box([0.009, 0.028, 0.009]),
                                        coat, flat: flat, name: "GastArm\(i)")
            arm.position = [dx, 0.018, 0.001]
            // Held away from the body, the way the plate has them — and the way
            // `references/REFERENCES.md` asks a character plate to be posed.
            arm.orientation = simd_quatf(angle: dx < 0 ? 0.26 : -0.26, axis: [0, 0, 1])
            body.addChild(arm)
        }

        // MARK: Head — the only thing that differs between two friends.
        head.name = "GastHead"
        head.position = [0, 0.048, 0]
        body.addChild(head)

        let skull = RoomBuilder.model(.box([0.026, 0.023, 0.022]),
                                      coat, flat: flat, name: "GastSkull")
        head.addChild(skull)

        // The frog's eyes stand on top of its head instead, which is the whole
        // of what makes a frog a frog at this size.
        if friend.soort != .kikker {
            for (i, dx) in [Float(-0.006), 0.006].enumerated() {
                let eye = RoomBuilder.model(.icosphere(radius: 0.0022, subdivisions: 0),
                                            Palette.woodBrown, flat: flat, name: "GastEye\(i)")
                eye.position = [dx, 0.003, 0.011]
                head.addChild(eye)
            }
        }

        GuestCharacter.buildFace(friend.soort, on: head, coat: coat, accent: accent, flat: flat)

        if role == .dj {
            // Two cups and a band. It is the one prop in the room that says
            // *this animal is working* rather than dancing, and it is three boxes.
            for dx in [Float(-0.015), 0.015] {
                let cup = RoomBuilder.model(.prism(radius: 0.0055, height: 0.005, sides: 8),
                                            Palette.woodBrown, flat: flat, name: "DJCup")
                cup.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
                cup.position = [dx, 0.002, 0]
                head.addChild(cup)
            }
            let band = RoomBuilder.model(.box([0.030, 0.004, 0.006]),
                                         Palette.woodBrown, flat: flat, name: "DJBand")
            band.position = [0, 0.013, 0]
            head.addChild(band)
        }

        start()
    }

    // MARK: - The eleven heads

    /// **Ears and a muzzle, and nothing else.** Two to four primitives each, all
    /// hung on the same head box at the same place, which is what makes eleven
    /// friends one builder rather than eleven builders.
    private static func buildFace(_ soort: Friend.Soort, on head: Entity,
                                  coat: UIColorLike, accent: UIColorLike, flat: Bool) {

        /// A pair of things, mirrored across X.
        func pair(_ dx: Float, _ build: (Float, Int) -> Entity) {
            for (i, side) in [-dx, dx].enumerated() { head.addChild(build(side, i)) }
        }

        /// The snout most of them have, in the accent colour.
        func muzzle(width: Float, out: Float, drop: Float = -0.004) {
            let snout = RoomBuilder.model(.box([width, width * 0.7, out]),
                                          accent, flat: flat, name: "GastSnuit")
            snout.position = [0, drop, 0.011 + out / 2]
            head.addChild(snout)
        }

        switch soort {
        case .muis:
            // Big flat round ears, which is the whole mouse.
            pair(0.011) { dx, i in
                let ear = RoomBuilder.model(.icosphere(radius: 0.008, subdivisions: 0),
                                            accent, flat: flat, name: "MuisOor\(i)")
                ear.scale = [1, 1, 0.28]
                ear.position = [dx, 0.013, 0]
                return ear
            }
            muzzle(width: 0.008, out: 0.006)

        case .beer:
            pair(0.009) { dx, i in
                let ear = RoomBuilder.model(.icosphere(radius: 0.0048, subdivisions: 0),
                                            accent, flat: flat, name: "BeerOor\(i)")
                ear.position = [dx, 0.013, 0]
                return ear
            }
            muzzle(width: 0.011, out: 0.005)

        case .kat:
            // Pointed ears: a four-sided cone is a triangle from every angle
            // this camera has.
            pair(0.008) { dx, i in
                let ear = RoomBuilder.model(.lathe(profile: [[0.006, 0], [0, 0.010]], sides: 4),
                                            accent, flat: flat, name: "KatOor\(i)")
                ear.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
                ear.position = [dx, 0.011, 0]
                return ear
            }
            muzzle(width: 0.008, out: 0.004)

        case .kikker:
            // Eyes on stalks on top, which is the one animal whose eyes are not
            // in the skull — and it is why `init` skips the dot eyes for it.
            pair(0.008) { dx, i in
                let bulge = RoomBuilder.model(.icosphere(radius: 0.0055, subdivisions: 0),
                                              coat, flat: flat, name: "KikkerOog\(i)")
                bulge.position = [dx, 0.013, 0.002]
                return bulge
            }
            pair(0.008) { dx, i in
                let pupil = RoomBuilder.model(.icosphere(radius: 0.0022, subdivisions: 0),
                                              Palette.woodBrown, flat: flat,
                                              name: "KikkerPupil\(i)")
                pupil.position = [dx, 0.015, 0.006]
                return pupil
            }
            // A wide flat mouth across the whole face.
            let mouth = RoomBuilder.model(.box([0.020, 0.003, 0.002]),
                                          accent, flat: flat, name: "KikkerMond")
            mouth.position = [0, -0.006, 0.011]
            head.addChild(mouth)

        case .vogel:
            // **+π/2 about X, not −π/2.** A lathe stands on +Y, and only a
            // positive quarter-turn about X sends +Y down +Z — which is out of
            // the face. The negative one buries the beak in the skull, where it
            // is invisible rather than wrong-looking, and that is the harder
            // mistake to spot.
            let beak = RoomBuilder.model(.lathe(profile: [[0.005, 0], [0, 0.009]], sides: 4),
                                         Palette.butterYellow, flat: flat, name: "VogelSnavel")
            beak.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            beak.position = [0, -0.001, 0.012]
            head.addChild(beak)
            // A crest of three plates, tallest in the middle.
            for (i, dx) in [Float(-0.005), 0, 0.005].enumerated() {
                let quill = RoomBuilder.model(.box([0.003, i == 1 ? 0.010 : 0.007, 0.003]),
                                              accent, flat: flat, name: "VogelKuif\(i)")
                quill.position = [dx, 0.014, -0.002]
                head.addChild(quill)
            }

        case .schaap:
            // A fleece: four small spheres crowding the crown. The one head that
            // is a cluster rather than a pair.
            for (i, offset) in [SIMD3<Float>(-0.008, 0.012, 0.002),
                                SIMD3<Float>(0.008, 0.012, 0.002),
                                SIMD3<Float>(0, 0.015, -0.005),
                                SIMD3<Float>(0, 0.013, 0.008)].enumerated() {
                let curl = RoomBuilder.model(.icosphere(radius: 0.0058, subdivisions: 0),
                                             accent, flat: flat, name: "SchaapWol\(i)")
                curl.position = offset
                head.addChild(curl)
            }
            pair(0.014) { dx, i in
                let ear = RoomBuilder.model(.box([0.008, 0.004, 0.005]),
                                            coat, flat: flat, name: "SchaapOor\(i)")
                ear.position = [dx, 0.002, 0]
                return ear
            }

        case .mol:
            // A long snout and almost no ears, which is a mole seen from a metre
            // away. The pink nose on the end is the readable part.
            let snout = RoomBuilder.model(.taperedPrism(bottomRadius: 0.008, topRadius: 0.004,
                                                        height: 0.011, sides: 6),
                                          accent, flat: flat, name: "MolSnuit")
            snout.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            snout.position = [0, -0.002, 0.011]
            head.addChild(snout)
            let nose = RoomBuilder.model(.icosphere(radius: 0.0028, subdivisions: 0),
                                         Palette.blushPinkDeep, flat: flat, name: "MolNeus")
            nose.position = [0, -0.002, 0.023]
            head.addChild(nose)

        case .egel:
            // Spines: five cones fanning back off the crown.
            for i in 0..<5 {
                let t = Float(i) / 4 - 0.5
                let spine = RoomBuilder.model(.lathe(profile: [[0.0038, 0], [0, 0.012]], sides: 4),
                                              Palette.woodBrown, flat: flat, name: "EgelStekel\(i)")
                spine.orientation = simd_quatf(angle: -0.5 + t * 0.4, axis: [1, 0, 0])
                    * simd_quatf(angle: t * 0.7, axis: [0, 0, 1])
                spine.position = [t * 0.016, 0.011, -0.004]
                head.addChild(spine)
            }
            muzzle(width: 0.007, out: 0.005)

        case .hond:
            // Floppy ears down the sides — the only pair that hangs rather than
            // stands, and the reason a dog is not a bear.
            pair(0.014) { dx, i in
                let ear = RoomBuilder.model(.box([0.005, 0.016, 0.010]),
                                            accent, flat: flat, name: "HondOor\(i)")
                ear.position = [dx, -0.002, 0]
                ear.orientation = simd_quatf(angle: dx < 0 ? 0.18 : -0.18, axis: [0, 0, 1])
                return ear
            }
            muzzle(width: 0.011, out: 0.007)

        case .vlinder:
            // Two flat petal wings behind the head, and antennae with knobs.
            // The wings sit on the *head* rather than the shoulders so they read
            // at this size — a butterfly's wings behind a 30 mm torso are a
            // smudge, and behind the head they are a silhouette.
            pair(0.016) { dx, i in
                let wing = RoomBuilder.model(.icosphere(radius: 0.011, subdivisions: 0),
                                             accent, flat: flat, name: "VlinderVleugel\(i)")
                wing.scale = [1.0, 1.1, 0.16]
                wing.position = [dx, 0.004, -0.012]
                return wing
            }
            pair(0.005) { dx, i in
                let stalk = Entity()
                stalk.name = "VlinderVoelspriet\(i)"
                let rod = RoomBuilder.model(.box([0.0016, 0.010, 0.0016]),
                                            Palette.woodBrown, flat: flat, name: "VlinderRod")
                rod.position = [0, 0.005, 0]
                stalk.addChild(rod)
                let knob = RoomBuilder.model(.icosphere(radius: 0.0022, subdivisions: 0),
                                             accent, flat: flat, name: "VlinderKnop")
                knob.position = [0, 0.011, 0]
                stalk.addChild(knob)
                stalk.position = [dx, 0.011, 0]
                stalk.orientation = simd_quatf(angle: dx < 0 ? 0.25 : -0.25, axis: [0, 0, 1])
                return stalk
            }

        case .slak:
            // A shell on the back, and two eye-stalks. The shell is a lathe with
            // a stepped profile, which is the cheapest thing that reads as a
            // spiral without being one.
            let shell = RoomBuilder.model(.lathe(profile: [[0.004, 0], [0.012, 0.004],
                                                           [0.011, 0.010], [0.006, 0.014],
                                                           [0, 0.016]],
                                                 sides: 8),
                                          accent, flat: flat, name: "SlakHuis")
            shell.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            shell.position = [0, 0.001, -0.014]
            head.addChild(shell)
            pair(0.006) { dx, i in
                let stalk = Entity()
                stalk.name = "SlakSteel\(i)"
                let rod = RoomBuilder.model(.box([0.0016, 0.011, 0.0016]),
                                            coat, flat: flat, name: "SlakRod")
                rod.position = [0, 0.0055, 0]
                stalk.addChild(rod)
                let eye = RoomBuilder.model(.icosphere(radius: 0.0024, subdivisions: 0),
                                            Palette.woodBrown, flat: flat, name: "SlakOog")
                eye.position = [0, 0.012, 0]
                stalk.addChild(eye)
                stalk.position = [dx, 0.011, 0.004]
                stalk.orientation = simd_quatf(angle: dx < 0 ? 0.20 : -0.20, axis: [0, 0, 1])
                return stalk
            }
        }
    }

    // MARK: - Dancing

    /// One job for the life of the character. `beat` is read every frame rather
    /// than captured, so a guest built before she ever touched a pad is dancing
    /// to her tempo the instant she does.
    private func start() {
        job = ticker.add { [weak self] dt in
            guard let self else { return false }
            self.clock += dt
            return true
        }
    }

    func stop() {
        ticker.cancel(job)
        job = nil
    }

    /// Called once a frame by the room, which owns the beat. Deliberately *not*
    /// a job of its own: six guests reading one beat object have to be stepped
    /// after it, and a job order is not something `Ticker` promises.
    func tick(_ dt: Float, beat: FeestBeat) {
        if jumpTime > 0 { jumpTime -= dt }
        if eatTime > 0 { eatTime -= dt }

        // Everything below is a function of one phase-shifted beat.
        var p = beat.phase + phase
        if p >= 1 { p -= 1 }
        let swing = sin(p * .pi)
        let sway = sin(p * 2 * .pi)

        if eatTime > 0 {
            // Head down over the cake, and a fast munch. The one time nobody is
            // on the beat, because eating is not dancing.
            let munch = sin(clock * 22) * 0.5 + 0.5
            body.orientation = simd_quatf(angle: 0.30 + munch * 0.10, axis: [1, 0, 0])
            head.position = [0, 0.048 - munch * 0.004, 0.002]
            root.scale = SIMD3<Float>(1 + munch * 0.04, 1 - munch * 0.05, 1 + munch * 0.04)
            return
        }

        switch role {
        case .dj:
            // He leans over the decks and nods. No hop: a DJ who bounced like
            // the crowd would read as a guest standing in the wrong place.
            body.orientation = simd_quatf(angle: 0.22 + swing * 0.06, axis: [1, 0, 0])
            head.orientation = simd_quatf(angle: sway * 0.10, axis: [0, 1, 0])
            root.position = home
            root.scale = SIMD3<Float>(1 - swing * 0.012, 1 + swing * 0.020, 1 - swing * 0.012)

        case .gast:
            let extra: Float = showingOff ? 1.9 : 1.0
            let jumping = jumpTime > 0 ? 1 - jumpTime / 0.55 : -1

            // A hop on the beat, and a bigger one if she has just been tapped
            // or if this is the friend whose wish came true.
            var lift = beatHop(p) * 0.0055 * extra
            if jumping >= 0 { lift += sin(jumping * .pi) * 0.014 }
            root.position = home + SIMD3<Float>(0, lift, 0)

            // Squash and stretch on the root, out of phase with the hop. This is
            // the part that reads as alive — `CONCEPT.md` §9.7's whole budget.
            let squash = 1 + swing * 0.030 * extra
            root.scale = SIMD3<Float>(2 - squash, squash, 2 - squash)

            // Sway from the hips, which is what arms that never articulate leave
            // you: the whole body rocks instead.
            body.orientation = simd_quatf(angle: sway * 0.16 * extra, axis: [0, 0, 1])
            head.orientation = simd_quatf(angle: sway * 0.18, axis: [0, 1, 0])

            // Legs alternate — a weight shift, not a walk.
            for (i, hip) in legs.enumerated() {
                let leg = sin((p + (i == 0 ? 0 : 0.5)) * 2 * .pi)
                hip.orientation = simd_quatf(angle: leg * 0.16 * extra, axis: [1, 0, 0])
            }

            // The special move: the friend whose wish matched spins, slowly,
            // all the way round and round. §4's *"a special move only they do"*,
            // and it is one rotation.
            if showingOff {
                root.orientation = simd_quatf(angle: 0.42 + clock * 2.2, axis: [0, 1, 0])
            }
        }
    }

    /// Sharper than a sine: up fast, down slow, so the landing is on the beat
    /// rather than the top of the jump.
    private func beatHop(_ p: Float) -> Float {
        p < 0.35 ? sin(p / 0.35 * (.pi / 2)) : cos((p - 0.35) / 0.65 * (.pi / 2))
    }

    // MARK: - Reactions

    /// Tapped. `GAMEPLAY.md` §6.5's *"any guest, who jumps when tapped"*.
    func jump() {
        jumpTime = 0.55
    }

    /// The wish matched, so this one goes over the top for the rest of the party.
    func celebrate() {
        showingOff = true
        jumpTime = 0.55
    }

    /// She tapped the cake. Everybody eats.
    func eat(for duration: Float) {
        eatTime = duration
    }

    /// Back to standing, after the eating.
    func settle() {
        eatTime = 0
        head.position = [0, 0.048, 0]
        body.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
    }
}
