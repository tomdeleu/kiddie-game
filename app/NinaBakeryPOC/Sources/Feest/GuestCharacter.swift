import RealityKit
import simd

/// **One of the eleven friends, dancing.**
///
/// Built from `references/feest/beertjes.png`, which replaced an earlier blocky
/// cast sheet on the owner's call, 2026-08-17: *"in the reference plates they are
/// cute little bears. looks so much better."*
///
/// ## What changed, and it is the proportions rather than the species
///
/// The first pass gave every friend a **box torso, a box head and prism limbs**,
/// which is a robot. `beertjes.png` is a **teddy bear**: a plump barrel body
/// widest low down, a big round head nearly as wide as it sitting straight on it
/// with no neck at all, a pale belly patch covering most of the front, and arms
/// and legs so short they read as stubs. The head is about **two fifths of the
/// whole height** — that ratio is most of what makes it cute, and it is the one
/// number here worth protecting.
///
/// **The eleven friends of `GAMEPLAY.md` §4 are unchanged.** They are still a
/// mouse, a cat, a frog, a bird, a sheep and the rest, and the plate confirms
/// that is right: five different animals came back on it and every one of them
/// is the same barrel with different ears and a different muzzle. So the body is
/// one builder and `buildFace` is where a friend actually differs — which is what
/// makes eleven friends cost one character.
///
/// Round does not mean smooth. Everything here is `FacetedMesh` — an icosphere
/// at one subdivision is 80 flat facets, and a lathe with six stations is a
/// barrel with six visible bands. The silhouette is soft and every surface on it
/// is flat, which is the whole art direction in one prop.
///
/// ## The rig is still `CONCEPT.md` §9.7, and the arms still never articulate
///
/// One solid body — head, arms, belly, all one piece — plus two legs pivoting at
/// the hip, on a root that squashes and stretches. **Hands in the air is a pose,
/// not an animation**: each dance style builds its arms at a fixed angle and then
/// never touches them again. What moves them is the body they are welded to.
///
/// That is the whole trick, and it is why six visibly different dances cost six
/// closures rather than six rigs.
@MainActor
final class GuestCharacter {

    /// A guest, or the one behind the decks.
    enum Role {
        case gast
        /// Headphones, no hopping, and he leans over his booth. A DJ who bounced
        /// like the crowd would read as a guest standing in the wrong place.
        case dj
    }

    /// **Six little moves, and no two guests at a party do the same one.**
    ///
    /// Owner's call, 2026-08-17: *"the dance is too much of the same. they should
    /// be hands in the air and each do a different little move."* The first pass
    /// gave all six the identical bob-and-sway and staggered it by a fraction of
    /// a beat, which is a chorus line played slightly out of sync rather than six
    /// friends dancing.
    ///
    /// Each case is **an arm pose plus a motion**, and the two are chosen
    /// together: `pompen` needs one arm down for the pumping to read, `draaien`
    /// needs them out wide so the turn shows, `springen` needs them straight up
    /// so the jump has a top. Every one of them keeps at least one hand above the
    /// head, which is the half of the note that is not negotiable.
    enum DanceStyle: CaseIterable {
        /// Both arms straight up, rocking side to side. The default disco.
        case zwaaien
        /// One arm punching up, one down, leaning into the punch.
        case pompen
        /// Arms out wide and up, turning left and right from the waist.
        case draaien
        /// Arms straight up, a big jump on every single beat.
        case springen
        /// Arms up and out, hips going one way and shoulders the other.
        case wiebelen
        /// Arms up and forward, nodding deeply on the beat.
        case knikken

        /// How far each arm swings from straight up, in radians. **0 is
        /// vertical, π/2 is straight out sideways, π is hanging down** — so the
        /// numbers read as "how far from hands-in-the-air this pose is".
        var raise: (left: Float, right: Float) {
            switch self {
            case .zwaaien: return (0.34, 0.34)
            case .pompen: return (0.26, 2.35)
            case .draaien: return (1.10, 1.10)
            case .springen: return (0.16, 0.16)
            case .wiebelen: return (0.78, 0.78)
            case .knikken: return (0.52, 0.52)
            }
        }

        /// How far forward the arms are carried, so two styles at the same raise
        /// still do not look alike from a fixed camera.
        var forward: Float {
            switch self {
            case .knikken: return 0.55
            case .wiebelen: return 0.22
            case .pompen: return 0.10
            default: return 0
            }
        }
    }

    let root = Entity()
    let friend: Friend
    let style: DanceStyle
    private let role: Role
    private let body = Entity()
    private let head = Entity()
    private let legs: [Entity]
    private let ticker: Ticker
    private let home: SIMD3<Float>
    private let facing: Float

    /// A fraction of a beat, so six of them are together without being identical.
    /// **Much smaller than it was**: the styles now carry the variety, and a big
    /// offset on top of six different moves reads as six guests who cannot hear
    /// the music.
    private let phase: Float

    private var clock: Float = 0
    private var jumpTime: Float = 0
    private var eatTime: Float = 0
    /// **The wish matched, so this one is going over the top** —
    /// `GAMEPLAY.md` §4's *"a special move only they do"*. It is their own move
    /// twice as big plus a spin, rather than a seventh style: a special move that
    /// needed its own rig would be eleven special moves.
    private var showingOff = false
    private var job: Int?

    // MARK: - Proportions
    //
    // **Kept in step with `models/beertje.py`, which measured them off
    // `references/feest/beertje-solo.png` rather than taking them from here.**
    // These numbers changed when the guests were modelled, and the reason is
    // worth recording: the old set put the head's *centre* at the torso's top, so
    // half the head was inside the body and the two — being the same width —
    // fused into one lump with ears on it. Measured off the plate the head
    // overlaps the body by about 3% of its own diameter, and the bear is roughly
    // twice as tall as it is wide where the old rig was 87 mm tall against 62.
    //
    // The width is deliberately unchanged in spirit: `FeestLayout.guestRadius` is
    // a 32 mm *touch* radius and `boothCentre` records the DJ needing to fit
    // behind his decks, so the body got narrower rather than wider. The guest now
    // stands about 102 mm — which is what the comment here always claimed.

    private static let legHeight: Float = 0.014
    private static let bodyBase: Float = 0.012
    private static let bodyHeight: Float = 0.046
    private static let bodyWidest: Float = 0.028
    /// Head centre, in body space. It sits a few millimetres *into* the top of
    /// the barrel — there is no neck on the plate — but only a few: sunk to its
    /// centre it stops being a head.
    private static let headY: Float = 0.064
    private static let headRadius: Float = 0.026
    private static let shoulderY: Float = 0.038
    private static let armLength: Float = 0.024
    /// Where an arm hangs off the body, and where the model puts it.
    private static var shoulderX: Float { bodyWidest * 0.86 }
    /// Where a leg stands. The model pushes them 8 mm forward of the body's axis
    /// so the feet clear the belly's bulge from a camera looking down at 31° —
    /// which is every camera this game has.
    private static let hipX: Float = 0.014
    private static let hipZ: Float = 0.008


    init(friend: Friend, role: Role = .gast, style: DanceStyle = .zwaaien,
         at home: SIMD3<Float>, phase: Float, ticker: Ticker, flat: Bool) {
        self.friend = friend
        self.role = role
        self.style = style
        self.ticker = ticker
        self.home = home
        self.phase = phase
        self.facing = role == .dj ? 0.10 : 0.42

        root.name = "Gast-\(friend.rawValue)"
        root.position = home
        // Turned towards the open corner, so nobody is a flat cut-out and
        // everybody is broadly facing the camera and the dance floor.
        root.orientation = simd_quatf(angle: facing, axis: [0, 1, 0])

        let coat = friend.colour
        let accent = friend.accent
        let faceted = CharacterShading.faceted(flat)

        var builtLegs: [Entity] = []
        let raise = role == .dj ? (left: Float(1.5), right: Float(1.5)) : style.raise
        let forward = role == .dj ? Float(0.9) : style.forward

        // **The modelled friend**, from `models/beertje.py` — one USDZ per
        // species, all eleven of them, so a friend is never headless.
        //
        // The model arrives as one flat set of parts in **root space**, and the
        // rig is rebuilt around it here rather than in Blender: each group is
        // lifted onto the pivot that drives it, preserving its world transform,
        // so the geometry lands exactly where it was modelled and the pivot is
        // the thing that turns. `CONCEPT.md` §9.7 is untouched — one solid body,
        // two legs pivoting at the hip, arms welded on at a fixed pose.
        //
        // **Order matters.** The catch-all at the end sweeps whatever is still
        // under the wrapper into the body, so the head, arms and legs have to
        // have been lifted out before it runs.
        if let modelled = ModelLibrary.load(
                "beertje-\(friend.soort.rawValue)",
                tint: FeestAO.paintTints(["Coat": coat, "Accent": accent,
                                          "Cream": Palette.creamLight,
                                          "Dark": Palette.woodBrown,
                                          "Gold": Palette.butterYellow,
                                          "Rose": Palette.rose])) {
            root.addChild(modelled)

            body.name = "GastBody"
            body.position = [0, GuestCharacter.bodyBase, 0]
            root.addChild(body)

            head.name = "GastHead"
            head.position = [0, GuestCharacter.headY, 0]
            body.addChild(head)

            for i in 0..<2 {
                let arm = Entity()
                arm.name = "GastArm\(i)"
                arm.position = [i == 0 ? -GuestCharacter.shoulderX
                                       : GuestCharacter.shoulderX,
                                GuestCharacter.shoulderY, 0]
                body.addChild(arm)
                GuestCharacter.regroup(modelled, matching: "Arm\(i)", into: arm)
                // Positive Z-rotation swings +Y towards −X, which is the left
                // side — so the left arm takes the angle and the right one takes
                // its negative, and both lean out rather than across.
                let sideways = i == 0 ? raise.left : -raise.right
                arm.orientation = simd_quatf(angle: sideways, axis: [0, 0, 1])
                    * simd_quatf(angle: forward, axis: [1, 0, 0])
            }

            for i in 0..<2 {
                // Pivot at the hip, not at the leg's middle. Rotating a leg
                // about its centre is the classic error and makes it look
                // detached.
                let hip = Entity()
                hip.name = "GastHip\(i)"
                hip.position = [i == 0 ? -GuestCharacter.hipX : GuestCharacter.hipX,
                                GuestCharacter.legHeight, GuestCharacter.hipZ]
                root.addChild(hip)
                GuestCharacter.regroup(modelled, matching: "Been\(i)", into: hip)
                builtLegs.append(hip)
            }

            GuestCharacter.regroup(modelled, matching: "Kop", into: head)
            GuestCharacter.regroup(modelled, matching: "", into: body)
        } else {
            builtLegs = GuestCharacter.buildProcedural(
                root: root, body: body, head: head, friend: friend,
                coat: coat, accent: accent, raise: raise, forward: forward,
                flat: faceted)
        }
        legs = builtLegs

        if role == .dj {
            // The DJ is still whichever one of the eleven friends is not on the
            // floor today. What distinguishes the role is one modelled accessory
            // around the shared head pivot: a bent band, deep cups and cushions
            // from `references/feest/dj.png`. One separate asset avoids eleven
            // near-identical DJ variants and moves with every nod automatically.
            if let headphones = ModelLibrary.load(
                "dj-headphones",
                tint: ["DJMint": Palette.mintLight, "DJDark": Palette.woodBrown,
                       "DJCream": Palette.creamLight, "DJRose": Palette.rose]) {
                headphones.name = "DJKoptelefoon"
                head.addChild(headphones)
            } else {
                // A missing bundle asset still gets a complete, tappable DJ.
                for dx in [Float(-0.027), 0.027] {
                    let cup = RoomBuilder.model(
                        .prism(radius: 0.0090, height: 0.006, sides: 8),
                        Palette.mintLight, flat: faceted, name: "DJCup")
                    cup.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
                    cup.position = [dx, 0.002, 0]
                    head.addChild(cup)
                }
                let band = RoomBuilder.model(.box([0.052, 0.005, 0.007]),
                                             Palette.woodBrown, flat: faceted,
                                             name: "DJBand")
                band.position = [0, 0.027, -0.004]
                head.addChild(band)
            }
        }

        start()
    }


    /// The code-built friend. See `init` for when it runs: the USDZ missing from
    /// the bundle, or the debug panel's flat-shading toggle turned off. A missing
    /// asset must not leave a guest-shaped hole where a tap target was.
    ///
    /// `static` because Swift will not let `init` call an instance method before
    /// every stored property is assigned, and `legs` is what this produces.
    private static func buildProcedural(root: Entity, body: Entity, head: Entity,
                                        friend: Friend, coat: UIColorLike,
                                        accent: UIColorLike,
                                        raise: (left: Float, right: Float),
                                        forward: Float, flat: Bool) -> [Entity] {
        let soort = friend.soort
        // MARK: Legs — stubs, and the only parts that move independently.
        //
        // On the plate they are barely there: two little feet under a barrel,
        // about an eighth of the height. Long enough to swing, short enough that
        // the body reads as sitting on the ground.
        var builtLegs: [Entity] = []
        for (i, dx) in [Float(-0.012), 0.012].enumerated() {
            // Pivot at the hip, not at the leg's middle. Rotating a leg about
            // its centre is the classic error and makes it look detached.
            let hip = Entity()
            hip.name = "GastHip\(i)"
            hip.position = [dx, GuestCharacter.legHeight, 0]
            root.addChild(hip)

            let leg = RoomBuilder.model(
                .lathe(profile: [[0.0080, 0], [0.0090, 0.004], [0.0085, 0.011],
                                 [0.0070, 0.013]], sides: CharacterShading.limbSides),
                coat, flat: flat, name: "GastPoot\(i)")
            leg.position = [0, -GuestCharacter.legHeight, 0]
            hip.addChild(leg)

            builtLegs.append(hip)
        }

        // MARK: Body — one solid piece, and it is a barrel rather than a box.
        body.name = "GastBody"
        body.position = [0, GuestCharacter.bodyBase, 0]
        root.addChild(body)

        // Widest about a third of the way up and pulled in at the shoulders,
        // which is the profile on the plate. Ten sides keeps the facets big.
        let w = GuestCharacter.bodyWidest
        let torso = RoomBuilder.model(
            .lathe(profile: [[w * 0.52, 0], [w * 0.88, 0.007], [w, 0.017],
                             [w * 0.97, 0.029], [w * 0.78, 0.040],
                             [w * 0.45, GuestCharacter.bodyHeight]], sides: CharacterShading.torsoSides),
            coat, flat: flat, name: "GastRomp")
        body.addChild(torso)

        // **The pale belly, and it is not decoration.** Every animal on the plate
        // has one and it covers most of the front. Without it a guest is one
        // solid colour from the chin down and reads as a bollard.
        let belly = RoomBuilder.model(
            .icosphere(radius: w * 0.72, subdivisions: CharacterShading.headSubdivisions),
            Palette.creamLight, flat: flat, name: "GastBuik")
        belly.scale = [1.0, 1.05, 0.42]
        belly.position = [0, 0.019, w * 0.70]
        body.addChild(belly)

        // MARK: Arms — short stubs, welded on at the pose this dance wants.
        //
        // The geometry runs along **+Y from the shoulder**, so the pose angle
        // reads directly as *how far from straight up*: 0 is hands in the air,
        // π/2 is straight out, π is hanging down. `DanceStyle.raise` is written
        // in exactly those terms.
        for (i, dx) in [Float(-0.026), 0.026].enumerated() {
            let arm = RoomBuilder.model(
                .lathe(profile: [[0.0062, 0], [0.0072, 0.006], [0.0068, 0.016],
                                 [0.0075, GuestCharacter.armLength - 0.004],
                                 [0.0055, GuestCharacter.armLength]], sides: CharacterShading.limbSides),
                coat, flat: flat, name: "GastArm\(i)")
            // Positive Z-rotation swings +Y towards −X, which is the left side —
            // so the left arm takes the angle and the right one takes its
            // negative, and both then lean out from the body rather than across
            // it.
            let sideways = i == 0 ? raise.left : -raise.right
            arm.orientation = simd_quatf(angle: sideways, axis: [0, 0, 1])
                * simd_quatf(angle: forward, axis: [1, 0, 0])
            arm.position = [dx, GuestCharacter.shoulderY, 0]
            body.addChild(arm)

            // A paw on the end, which is what makes a raised arm read as a hand
            // in the air rather than as a stick.
            let paw = RoomBuilder.model(.icosphere(radius: 0.0072, subdivisions: 1),
                                        accent, flat: flat, name: "GastPoot\(i)Hand")
            paw.position = [0, GuestCharacter.armLength, 0]
            arm.addChild(paw)
        }

        // MARK: Head — big, round, and sitting straight on the shoulders.
        head.name = "GastHead"
        head.position = [0, GuestCharacter.headY, 0]
        body.addChild(head)

        let skull = RoomBuilder.model(
            .icosphere(radius: GuestCharacter.headRadius,
                       subdivisions: CharacterShading.headSubdivisions),
            coat, flat: flat, name: "GastKop")
        skull.scale = [1.0, 0.94, 0.95]
        head.addChild(skull)

        // The frog's eyes stand on top of its head instead, which is the whole
        // of what makes a frog a frog at this size.
        if soort != .kikker {
            for (i, dx) in [Float(-0.0098), 0.0098].enumerated() {
                let eye = RoomBuilder.model(.icosphere(radius: 0.0032, subdivisions: 1),
                                            Palette.woodBrown, flat: flat, name: "GastOog\(i)")
                eye.position = [dx, 0.003, 0.0224]
                head.addChild(eye)
            }
        }

        buildFace(soort, on: head, coat: coat, accent: accent, flat: flat)

        return builtLegs
    }

    // MARK: - The eleven heads

    /// **Ears and a muzzle, and nothing else.** Two to five primitives each, all
    /// hung on the same round head at the same place, which is what makes eleven
    /// friends one builder rather than eleven builders — and what
    /// `references/feest/beertjes.png` shows five animals doing.
    private static func buildFace(_ soort: Friend.Soort, on head: Entity,
                                  coat: UIColorLike, accent: UIColorLike, flat: Bool) {

        let r = headRadius

        /// A pair of things, mirrored across X.
        func pair(_ dx: Float, _ build: (Float, Int) -> Entity) {
            for (i, side) in [-dx, dx].enumerated() { head.addChild(build(side, i)) }
        }

        /// **The pale rounded snout every animal on the plate has**, plus its
        /// dark nose. It is doing as much work as the ears: it breaks the head's
        /// silhouette and it is where the face *is*.
        func muzzle(width: Float, nose: Bool = true) {
            let snout = RoomBuilder.model(.icosphere(radius: width, subdivisions: 1),
                                          Palette.creamLight, flat: flat, name: "GastSnuit")
            snout.scale = [1.15, 0.80, 0.75]
            snout.position = [0, -0.006, r * 0.78]
            head.addChild(snout)
            guard nose else { return }
            let tip = RoomBuilder.model(.icosphere(radius: width * 0.36, subdivisions: 0),
                                        Palette.woodBrown, flat: flat, name: "GastNeus")
            tip.position = [0, -0.003, r * 0.78 + width * 0.62]
            head.addChild(tip)
        }

        /// A round ear with a paler inner disc — the bear, the cat and the mouse
        /// all have one on the plate and it is what stops an ear being a lump.
        func roundEar(_ dx: Float, _ i: Int, radius: Float, y: Float,
                      flatten: Float = 1) -> Entity {
            let ear = Entity()
            ear.name = "GastOor\(i)"
            ear.position = [dx, y, 0]
            let outer = RoomBuilder.model(.icosphere(radius: radius, subdivisions: 0),
                                          coat, flat: flat, name: "GastOorBuiten")
            outer.scale = [1, 1, flatten]
            ear.addChild(outer)
            let inner = RoomBuilder.model(.icosphere(radius: radius * 0.58, subdivisions: 0),
                                          accent, flat: flat, name: "GastOorBinnen")
            inner.scale = [1, 1, flatten * 0.6]
            inner.position = [0, 0, radius * 0.42 * flatten]
            ear.addChild(inner)
            return ear
        }

        switch soort {
        case .beer:
            pair(0.017) { dx, i in roundEar(dx, i, radius: 0.0088, y: 0.020) }
            muzzle(width: 0.0105)

        case .muis:
            // Big flat round ears, which is the whole mouse.
            pair(0.021) { dx, i in roundEar(dx, i, radius: 0.0125, y: 0.014, flatten: 0.30) }
            muzzle(width: 0.0085)

        case .kat:
            // Pointed ears: a four-sided cone is a triangle from every angle
            // this camera has.
            pair(0.014) { dx, i in
                let ear = RoomBuilder.model(.lathe(profile: [[0.0078, 0], [0, 0.013]], sides: 4),
                                            coat, flat: flat, name: "KatOor\(i)")
                ear.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
                ear.position = [dx, 0.018, 0]
                return ear
            }
            muzzle(width: 0.0092)

        case .hond:
            // Floppy ears down the sides — the only pair that hangs rather than
            // stands, and the reason a dog is not a bear.
            pair(0.023) { dx, i in
                let ear = RoomBuilder.model(
                    .lathe(profile: [[0.0060, 0], [0.0082, 0.006], [0.0074, 0.016],
                                     [0.0030, 0.021]], sides: 6),
                    accent, flat: flat, name: "HondOor\(i)")
                ear.scale = [1, 1, 0.55]
                ear.orientation = simd_quatf(angle: .pi, axis: [0, 0, 1])
                    * simd_quatf(angle: dx < 0 ? -0.20 : 0.20, axis: [0, 0, 1])
                ear.position = [dx, 0.010, 0]
                return ear
            }
            muzzle(width: 0.0110)

        case .kikker:
            // Eyes on bulges on top, which is the one animal whose eyes are not
            // in the skull — and it is why `init` skips the dot eyes for it.
            pair(0.013) { dx, i in
                let bulge = RoomBuilder.model(.icosphere(radius: 0.0092, subdivisions: 0),
                                              coat, flat: flat, name: "KikkerOog\(i)")
                bulge.position = [dx, 0.019, 0.004]
                return bulge
            }
            pair(0.013) { dx, i in
                let pupil = RoomBuilder.model(.icosphere(radius: 0.0032, subdivisions: 0),
                                              Palette.woodBrown, flat: flat,
                                              name: "KikkerPupil\(i)")
                pupil.position = [dx, 0.022, 0.011]
                return pupil
            }
            // A wide flat mouth across the whole face.
            let mouth = RoomBuilder.model(.box([0.028, 0.004, 0.003]),
                                          accent, flat: flat, name: "KikkerMond")
            mouth.position = [0, -0.008, r * 0.88]
            head.addChild(mouth)

        case .vogel:
            // **+π/2 about X, not −π/2.** A lathe stands on +Y, and only a
            // positive quarter-turn about X sends +Y down +Z — which is out of
            // the face. The negative one buries the beak in the skull, where it
            // is invisible rather than wrong-looking, and that is the harder
            // mistake to spot.
            let beak = RoomBuilder.model(
                .lathe(profile: [[0.0075, 0], [0.0055, 0.006], [0, 0.012]], sides: 6),
                Palette.butterYellow, flat: flat, name: "VogelSnavel")
            beak.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            beak.position = [0, -0.002, r * 0.82]
            head.addChild(beak)
            // A crest of three plates, tallest in the middle.
            for (i, dx) in [Float(-0.006), 0, 0.006].enumerated() {
                let quill = RoomBuilder.model(.box([0.0035, i == 1 ? 0.013 : 0.009, 0.0035]),
                                              accent, flat: flat, name: "VogelKuif\(i)")
                quill.position = [dx, 0.026, -0.002]
                head.addChild(quill)
            }

        case .schaap:
            // A fleece: five small spheres crowding the crown. The one head that
            // is a cluster rather than a pair.
            for (i, offset) in [SIMD3<Float>(-0.011, 0.019, 0.003),
                                SIMD3<Float>(0.011, 0.019, 0.003),
                                SIMD3<Float>(0, 0.024, -0.006),
                                SIMD3<Float>(0, 0.021, 0.012),
                                SIMD3<Float>(0, 0.026, 0.002)].enumerated() {
                let curl = RoomBuilder.model(.icosphere(radius: 0.0072, subdivisions: 0),
                                             accent, flat: flat, name: "SchaapWol\(i)")
                curl.position = offset
                head.addChild(curl)
            }
            pair(0.024) { dx, i in
                let ear = RoomBuilder.model(.icosphere(radius: 0.0062, subdivisions: 0),
                                            coat, flat: flat, name: "SchaapOor\(i)")
                ear.scale = [1.5, 0.6, 0.7]
                ear.position = [dx, 0.004, 0]
                return ear
            }
            muzzle(width: 0.0098)

        case .mol:
            // A long snout and almost no ears, which is a mole seen from a metre
            // away. The pink nose on the end is the readable part.
            let snout = RoomBuilder.model(
                .lathe(profile: [[0.0090, 0], [0.0072, 0.006], [0.0050, 0.013]], sides: 6),
                Palette.creamLight, flat: flat, name: "MolSnuit")
            snout.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            snout.position = [0, -0.004, r * 0.76]
            head.addChild(snout)
            let nose = RoomBuilder.model(.icosphere(radius: 0.0038, subdivisions: 0),
                                         Palette.blushPinkDeep, flat: flat, name: "MolNeus")
            nose.position = [0, -0.004, r * 0.76 + 0.014]
            head.addChild(nose)

        case .egel:
            // Spines: five cones fanning back off the crown.
            for i in 0..<5 {
                let t = Float(i) / 4 - 0.5
                let spine = RoomBuilder.model(.lathe(profile: [[0.0042, 0], [0, 0.014]], sides: 4),
                                              Palette.woodBrown, flat: flat, name: "EgelStekel\(i)")
                spine.orientation = simd_quatf(angle: -0.55 + t * 0.4, axis: [1, 0, 0])
                    * simd_quatf(angle: t * 0.8, axis: [0, 0, 1])
                spine.position = [t * 0.020, 0.020, -0.006]
                head.addChild(spine)
            }
            muzzle(width: 0.0085)

        case .vlinder:
            // Two flat petal wings behind the head, and antennae with knobs. The
            // wings sit on the *head* rather than the shoulders so they read at
            // this size — behind a 60 mm barrel they are a smudge, behind the
            // head they are a silhouette.
            pair(0.022) { dx, i in
                let wing = RoomBuilder.model(.icosphere(radius: 0.014, subdivisions: 0),
                                             accent, flat: flat, name: "VlinderVleugel\(i)")
                wing.scale = [1.0, 1.15, 0.16]
                wing.position = [dx, 0.004, -0.016]
                return wing
            }
            pair(0.006) { dx, i in
                let stalk = Entity()
                stalk.name = "VlinderVoelspriet\(i)"
                let rod = RoomBuilder.model(.box([0.0018, 0.012, 0.0018]),
                                            Palette.woodBrown, flat: flat, name: "VlinderRod")
                rod.position = [0, 0.006, 0]
                stalk.addChild(rod)
                let knob = RoomBuilder.model(.icosphere(radius: 0.0026, subdivisions: 0),
                                             accent, flat: flat, name: "VlinderKnop")
                knob.position = [0, 0.013, 0]
                stalk.addChild(knob)
                stalk.position = [dx, 0.019, 0]
                stalk.orientation = simd_quatf(angle: dx < 0 ? 0.25 : -0.25, axis: [0, 0, 1])
                return stalk
            }
            muzzle(width: 0.0080, nose: false)

        case .slak:
            // A shell on the back, and two eye-stalks. The shell is a lathe with
            // a stepped profile, which is the cheapest thing that reads as a
            // spiral without being one.
            let shell = RoomBuilder.model(
                .lathe(profile: [[0.005, 0], [0.015, 0.005], [0.014, 0.012],
                                 [0.008, 0.017], [0, 0.019]], sides: 8),
                accent, flat: flat, name: "SlakHuis")
            shell.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            shell.position = [0, 0.002, -0.018]
            head.addChild(shell)
            pair(0.007) { dx, i in
                let stalk = Entity()
                stalk.name = "SlakSteel\(i)"
                let rod = RoomBuilder.model(.box([0.0018, 0.013, 0.0018]),
                                            coat, flat: flat, name: "SlakRod")
                rod.position = [0, 0.0065, 0]
                stalk.addChild(rod)
                let eye = RoomBuilder.model(.icosphere(radius: 0.0028, subdivisions: 0),
                                            Palette.woodBrown, flat: flat, name: "SlakOog")
                eye.position = [0, 0.014, 0]
                stalk.addChild(eye)
                stalk.position = [dx, 0.018, 0.005]
                stalk.orientation = simd_quatf(angle: dx < 0 ? 0.22 : -0.22, axis: [0, 0, 1])
                return stalk
            }
            muzzle(width: 0.0078, nose: false)
        }
    }

    /// Lift every mesh whose name contains `token` onto `holder`, keeping it
    /// exactly where it was modelled.
    ///
    /// An empty token matches everything still under `source`, which is how the
    /// torso and belly reach the body without being named: by then the head, the
    /// arms and the legs have already been taken out.
    private static func regroup(_ source: Entity, matching token: String,
                                into holder: Entity) {
        var found: [ModelEntity] = []
        collect(source, matching: token, into: &found)
        // Gathered first and moved afterwards: re-parenting mid-walk mutates the
        // children being iterated.
        for mesh in found { mesh.setParent(holder, preservingWorldTransform: true) }
    }

    private static func collect(_ entity: Entity, matching token: String,
                                into found: inout [ModelEntity]) {
        if let model = entity as? ModelEntity, model.model != nil,
           token.isEmpty || model.name.contains(token) {
            found.append(model)
        }
        for child in entity.children { collect(child, matching: token, into: &found) }
    }

    // MARK: - Dancing

    /// One job for the life of the character, and it does nothing but advance a
    /// clock — everything else is driven by the room, which owns the beat.
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

    /// Called once a frame by the room. Deliberately *not* a job of its own: six
    /// guests reading one beat object have to be stepped after it, and job order
    /// is not something `Ticker` promises.
    func tick(_ dt: Float, beat: FeestBeat) {
        if jumpTime > 0 { jumpTime -= dt }
        if eatTime > 0 { eatTime -= dt }

        var p = beat.phase + phase
        if p >= 1 { p -= 1 }
        let swing = sin(p * .pi)
        let sway = sin(p * 2 * .pi)

        if eatTime > 0 {
            eating()
            return
        }

        guard role == .gast else {
            djNods(swing: swing, sway: sway)
            return
        }

        // **Everything below is the style, and nothing below touches an arm.**
        // The arms were posed once at build time; what moves them is the body
        // they are welded to. `CONCEPT.md` §9.7 — arms never articulate.
        let big: Float = showingOff ? 1.9 : 1
        let jumping = jumpTime > 0 ? 1 - jumpTime / 0.55 : -1

        var lift: Float = 0
        var bodyTilt: Float = 0        // about Z — rocking sideways
        var bodyPitch: Float = 0       // about X — nodding
        var bodyTurn: Float = 0        // about Y — twisting
        var hipTurn: Float = 0
        var legSwing: Float = 0

        switch style {
        case .zwaaien:
            lift = beatHop(p) * 0.0045
            bodyTilt = sway * 0.20
            legSwing = sway * 0.14

        case .pompen:
            // Down on the beat and up between, so the raised arm punches.
            lift = beatHop(p) * 0.0075
            bodyTilt = -0.10 - swing * 0.13
            bodyPitch = swing * 0.08
            legSwing = sway * 0.10

        case .draaien:
            lift = beatHop(p) * 0.0035
            bodyTurn = sway * 0.52
            bodyTilt = sway * 0.08
            legSwing = -sway * 0.12

        case .springen:
            // A real jump, every beat, with the legs tucking at the top.
            lift = beatHop(p) * 0.016
            legSwing = -beatHop(p) * 0.45
            bodyPitch = beatHop(p) * 0.10

        case .wiebelen:
            // Hips one way, shoulders the other. The only style where the two
            // halves disagree, which is what makes it read as a wiggle.
            lift = beatHop(p) * 0.0030
            hipTurn = sway * 0.38
            bodyTurn = -sway * 0.24
            bodyTilt = sway * 0.10

        case .knikken:
            lift = beatHop(p) * 0.0040
            bodyPitch = 0.10 + swing * 0.30
            legSwing = sway * 0.08
        }

        if jumping >= 0 { lift += sin(jumping * .pi) * 0.015 }
        root.position = home + SIMD3<Float>(0, lift * big, 0)

        // Squash and stretch on the root, out of phase with the lift. This is
        // the part that reads as alive — `CONCEPT.md` §9.7's whole budget.
        let squash = 1 + swing * 0.032 * big
        root.scale = SIMD3<Float>(2 - squash, squash, 2 - squash)

        body.orientation = simd_quatf(angle: bodyTilt * big, axis: [0, 0, 1])
            * simd_quatf(angle: bodyPitch * big, axis: [1, 0, 0])
            * simd_quatf(angle: bodyTurn * big, axis: [0, 1, 0])
        // The head lags the body a little, which is the hat's trick on Nina and
        // does the same job here: it stops a solid body reading as one rigid
        // lump.
        head.orientation = simd_quatf(angle: sway * 0.16 - bodyTurn * 0.35, axis: [0, 1, 0])

        for (i, hip) in legs.enumerated() {
            let side: Float = i == 0 ? 1 : -1
            hip.orientation = simd_quatf(angle: legSwing * side * big, axis: [1, 0, 0])
                * simd_quatf(angle: hipTurn * big, axis: [0, 1, 0])
        }

        // The special move: the friend whose wish matched turns slowly all the
        // way round while doing their own dance twice as big.
        root.orientation = simd_quatf(angle: showingOff ? facing + clock * 2.2 : facing,
                                      axis: [0, 1, 0])
    }

    private func djNods(swing: Float, sway: Float) {
        // He leans over the decks and nods. No hop: a DJ who bounced like the
        // crowd would read as a guest standing in the wrong place.
        //
        // **0.12 rad, down from 0.22, and the modelled friends are why.** The
        // lean tips the head forward by `sin(angle) × headY`, and the guests grew
        // from 87 mm to 102 mm when they were built from the plate — so the same
        // angle now carries his chin past the console's near edge and lays his
        // face on the platters. Half the lean puts him back over his decks
        // instead of on them.
        body.orientation = simd_quatf(angle: 0.12 + swing * 0.05, axis: [1, 0, 0])
        head.orientation = simd_quatf(angle: sway * 0.12, axis: [0, 1, 0])
        root.position = home
        root.scale = SIMD3<Float>(1 - swing * 0.012, 1 + swing * 0.020, 1 - swing * 0.012)
    }

    private func eating() {
        // Head down over the cake, and a fast munch. The one time nobody is on
        // the beat, because eating is not dancing.
        let munch = sin(clock * 22) * 0.5 + 0.5
        body.orientation = simd_quatf(angle: 0.30 + munch * 0.10, axis: [1, 0, 0])
        head.position = [0, GuestCharacter.headY - munch * 0.004, 0.002]
        root.scale = SIMD3<Float>(1 + munch * 0.04, 1 - munch * 0.05, 1 + munch * 0.04)
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
        head.position = [0, GuestCharacter.headY, 0]
        body.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
    }
}
