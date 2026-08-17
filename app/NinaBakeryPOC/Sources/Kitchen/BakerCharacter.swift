import RealityKit
import simd

/// Nina, behind the table.
///
/// Built from `references/plates/02-fairy-character.png`: mint chef's hat with
/// a knob, peach face with two dot eyes and a smile, mint apron over a mint
/// dress with a pale pink pocket, faceted mint wings, pink arms and legs.
///
/// **The rig is `CONCEPT.md` §9.7 exactly**: one solid body — head, torso,
/// arms, all one piece — plus two legs that pivot at the hip, on a root that
/// squashes and stretches. Three moving parts, not ten. Arms never articulate,
/// and nothing bends.
///
/// That constraint is doing real work here. A baker who stirs with her arms
/// needs shoulders, elbows and inverse kinematics; a baker who stirs by leaning
/// her whole body over the bowl and bobbing on the beat needs one rotation and
/// one sine wave, and at this scale reads better. The apron hides the hip seam,
/// which is why the legs never have to line up with anything.
///
/// She is 0.125 m tall against a 0.072 m table, so the room sees her from the
/// waist up — which is the half that moves.
@MainActor
final class BakerCharacter {

    let root = Entity()
    private let body = Entity()
    private let legs: [Entity]
    private let wings: [Entity]
    private let hat: Entity
    private let ticker: Ticker

    /// What she is doing. Drives how hard she bobs and where she leans.
    enum Mood {
        case idle
        /// Working at something on the table — she leans towards it.
        case busy(SIMD3<Float>)
        /// Something went right.
        case cheering
    }

    private var mood: Mood = .idle
    private var clock: Float = 0
    private var lean: Float = 0        // current, radians
    private var leanTarget: Float = 0
    private var bobAmount: Float = 0.6
    private var cheerTime: Float = 0
    private var job: Int?

    /// **Where she stands, and where a hop puts her back.**
    ///
    /// It exists because `cheerTime` lands her back on a hardcoded spot, and
    /// three rooms now build her somewhere that is not the kitchen. Optional with
    /// the kitchen's spot as the default, so every existing call site behaves
    /// exactly as it did — see the note on `init`.
    private let home: SIMD3<Float>

    /// `home` defaults to the kitchen's spot, which is what this class assumed
    /// for its whole life. **Rooms that place her by writing `root.position`
    /// after construction and do not pass it have a latent bug**: cheering eases
    /// her back to the kitchen's corner and leaves her there. Versieren and De
    /// Tuin both do that today and neither is changed here — this session's room
    /// is the party (`CLAUDE.md`, "Always ask which room"), and the fix for the
    /// other two is to pass their own `bakerSpot`, which is one argument each.
    init(ticker: Ticker, flat: Bool, home: SIMD3<Float>? = nil) {
        self.ticker = ticker
        self.home = home ?? KitchenLayout.bakerSpot
        root.name = "Nina"
        root.position = self.home

        // Slightly turned towards the room, so she is never a flat cut-out.
        root.orientation = simd_quatf(angle: 0.28, axis: [0, 1, 0])

        let skin = Palette.blushPink
        let dress = Palette.mint
        let apron = Palette.mintLight

        // MARK: Legs — the only parts that move independently.
        var builtLegs: [Entity] = []
        for (i, dx) in [Float(-0.011), 0.011].enumerated() {
            // The pivot is at the hip, not the leg's centre. Rotating a leg
            // about its middle is the classic error and makes it look detached.
            let hip = Entity()
            hip.name = "NinaHip\(i)"
            hip.position = [dx, 0.030, 0]
            root.addChild(hip)

            let leg = RoomBuilder.model(.box([0.012, 0.030, 0.012]),
                                        skin, flat: flat, name: "NinaLeg\(i)")
            leg.position = [0, -0.015, 0]
            hip.addChild(leg)

            let shoe = RoomBuilder.model(.box([0.014, 0.007, 0.017]),
                                         Palette.blushPinkDeep, flat: flat,
                                         name: "NinaShoe\(i)")
            shoe.position = [0, -0.032, 0.002]
            hip.addChild(shoe)

            builtLegs.append(hip)
        }
        legs = builtLegs

        // MARK: Body — one solid piece from the hips up.
        body.name = "NinaBody"
        body.position = [0, 0.030, 0]
        root.addChild(body)

        let torso = RoomBuilder.model(.box([0.034, 0.040, 0.020]),
                                      dress, flat: flat, name: "NinaTorso")
        torso.position = [0, 0.020, 0]
        body.addChild(torso)

        // The apron, and the pocket on it. Two boxes, and they are what makes
        // her read as a baker rather than as a person.
        let apronPanel = RoomBuilder.model(.box([0.026, 0.026, 0.004]),
                                           apron, flat: flat, name: "NinaApron")
        apronPanel.position = [0, 0.014, 0.011]
        body.addChild(apronPanel)

        let pocket = RoomBuilder.model(.box([0.016, 0.010, 0.003]),
                                       Palette.blushPink, flat: flat, name: "NinaPocket")
        pocket.position = [0, 0.008, 0.014]
        body.addChild(pocket)

        // Arms. Part of the body by design — they hang, they never articulate.
        for (i, dx) in [Float(-0.023), 0.023].enumerated() {
            let arm = RoomBuilder.model(.box([0.010, 0.032, 0.010]),
                                        skin, flat: flat, name: "NinaArm\(i)")
            arm.position = [dx, 0.020, 0.002]
            // Angled out a little, the way the plate has them.
            arm.orientation = simd_quatf(angle: dx < 0 ? 0.22 : -0.22, axis: [0, 0, 1])
            body.addChild(arm)
        }

        // MARK: Head and hat.
        let head = RoomBuilder.model(.box([0.026, 0.024, 0.022]),
                                     skin, flat: flat, name: "NinaHead")
        head.position = [0, 0.052, 0]
        body.addChild(head)

        for (i, dx) in [Float(-0.006), 0.006].enumerated() {
            let eye = RoomBuilder.model(.icosphere(radius: 0.0022, subdivisions: 0),
                                        Palette.woodBrown, flat: flat, name: "NinaEye\(i)")
            eye.position = [dx, 0.054, 0.011]
            body.addChild(eye)
        }

        // A hat that is its own entity, so it can wobble a beat behind her.
        let hatNode = Entity()
        hatNode.name = "NinaHat"
        hatNode.position = [0, 0.064, 0]
        body.addChild(hatNode)

        let brim = RoomBuilder.model(.taperedPrism(bottomRadius: 0.017, topRadius: 0.014,
                                                   height: 0.011, sides: 8),
                                     dress, flat: flat, name: "NinaHatBrim")
        hatNode.addChild(brim)

        let knob = RoomBuilder.model(.icosphere(radius: 0.004, subdivisions: 0),
                                     dress, flat: flat, name: "NinaHatKnob")
        knob.position = [0, 0.014, 0]
        hatNode.addChild(knob)
        hat = hatNode

        // MARK: Wings — flat faceted petals behind the shoulders.
        var builtWings: [Entity] = []
        for (i, dx) in [Float(-0.020), 0.020].enumerated() {
            let wing = Entity()
            wing.name = "NinaWing\(i)"
            wing.position = [dx, 0.032, -0.010]
            body.addChild(wing)

            let petal = RoomBuilder.model(.icosphere(radius: 0.013, subdivisions: 0),
                                          Palette.mintLight, flat: flat,
                                          name: "NinaWingPetal\(i)")
            petal.scale = [1.0, 0.9, 0.18]
            petal.position = [dx < 0 ? -0.008 : 0.008, 0.004, 0]
            wing.addChild(petal)

            builtWings.append(wing)
        }
        wings = builtWings

        start()
    }

    // MARK: - Animation

    /// One job, running for as long as she exists. Everything she does is a
    /// function of `mood` and a clock, so there is no animation state to get
    /// out of sync with the game.
    private func start() {
        job = ticker.add { [weak self] dt in
            guard let self else { return false }
            self.tick(dt)
            return true
        }
    }

    func stop() {
        ticker.cancel(job)
        job = nil
    }

    func set(_ mood: Mood) {
        self.mood = mood
        switch mood {
        case .idle:
            bobAmount = 0.6
            leanTarget = 0
        case .busy(let target):
            bobAmount = 1.0
            // Lean towards whatever she is working on, capped so she never
            // folds in half. Positive Z is towards the camera; she stands
            // behind the table, so anything she works on is in front of her.
            let toward = target - root.position(relativeTo: nil)
            leanTarget = max(-0.16, min(0.34, atan2(toward.z, 0.16)))
        case .cheering:
            bobAmount = 1.4
            leanTarget = -0.10
            cheerTime = 0.9
        }
    }

    private func tick(_ dt: Float) {
        clock += dt

        // Bob: the whole body rising and falling, faster when she is working.
        let speed: Float = bobAmount > 0.8 ? 5.2 : 2.6
        let bob = sin(clock * speed) * 0.0022 * bobAmount
        body.position = [0, 0.030 + bob, 0]

        // Squash and stretch on the root, out of phase with the bob. This is
        // the part that reads as alive.
        let squash = 1 + sin(clock * speed + .pi / 2) * 0.018 * bobAmount
        root.scale = SIMD3<Float>(2 - squash, squash, 2 - squash)

        // Lean eases towards its target rather than snapping.
        lean += (leanTarget - lean) * min(1, dt * 4)
        body.orientation = simd_quatf(angle: lean, axis: [1, 0, 0])

        // Legs alternate gently — she is standing, not walking, so this is a
        // weight shift rather than a step.
        for (i, hip) in legs.enumerated() {
            let phase = clock * speed * 0.5 + (i == 0 ? 0 : .pi)
            hip.orientation = simd_quatf(angle: sin(phase) * 0.06 * bobAmount,
                                         axis: [1, 0, 0])
        }

        // Wings flutter, always, and faster when she is pleased. A fairy whose
        // wings are still looks stuffed.
        let flutter = sin(clock * (bobAmount > 1.2 ? 26 : 15)) * (bobAmount > 1.2 ? 0.5 : 0.28)
        for (i, wing) in wings.enumerated() {
            wing.orientation = simd_quatf(angle: i == 0 ? -flutter : flutter,
                                          axis: [0, 1, 0])
        }

        // The hat lags a beat behind the bob, which is most of the charm.
        hat.orientation = simd_quatf(angle: sin(clock * speed - 0.8) * 0.05 * bobAmount,
                                     axis: [0, 0, 1])

        if cheerTime > 0 {
            cheerTime -= dt
            // A little hop on top of everything else.
            let hop = max(0, sin((0.9 - cheerTime) / 0.9 * .pi)) * 0.010
            root.position = home + SIMD3<Float>(0, hop, 0)
            if cheerTime <= 0 {
                root.position = home
                set(.idle)
            }
        }
    }
}
