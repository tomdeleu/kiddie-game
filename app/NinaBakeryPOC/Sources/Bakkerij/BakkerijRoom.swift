import Foundation
import RealityKit
import simd

/// **De Bakkerij — the hub, and the wall of twelve frames.** `GAMEPLAY.md` §6.1
/// and §6.6.
///
/// The only room she passes through twice in a round: out through it on the way
/// to the garden, and back into it holding a photograph. Four steps outbound in
/// about forty seconds — `opendoen`, `kiezen`, `binnenlaten`, `bestellen` — and
/// two on the way home, `ophangen` and `klaar`.
///
/// Four things about it are unlike every other room in the game:
///
/// - **Its contents are saved state rather than props.** Twelve frames, each
///   either a grey ghost or a photograph of a cake that exists nowhere else. See
///   `FrameWall` and `GameStore`.
/// - **`kiezen` has no halo at all**, and that is `ROOMS.md` §3's own floor
///   rather than an exception to it. Eleven ghosts are eleven equally right
///   answers, so there is no fact anywhere in the step to point at. The ghosts
///   breathe on a slow rolling wave instead, which says *any of these* truthfully
///   where one halo would lie and eleven would not be an instruction.
/// - **It has two door-shaped things and only one of them is the way out.** The
///   shop door is a step; the back door is the exit. §9 forbids a room with two
///   objects meaning "this is finished", so the shop door's cue is withdrawn the
///   moment the friend is inside, and only then does the back door light.
/// - **The ritual runs once per sitting.** Come back from a finished round and
///   the blind is already up, so the second round of an afternoon starts at
///   `kiezen`.
@MainActor
final class BakkerijRoom: Room {

    let root = Entity()
    var onExit: ((RoomExit) -> Void)?

    /// `ROOMS.md` §9: one flag, not two implementations. The bakery is the hub,
    /// so "back to the bakery" is not something it can do — what `.bezoek` means
    /// here is *she walked in without a round in progress*, and it changes only
    /// which greeting she gets.
    let mode: RoomMode

    /// **Set when the wish card should appear in the screen corner**, and cleared
    /// when it should go. `ContentView` owns the card itself: it has to survive
    /// four room swaps, and a room is torn down wholesale.
    var onWishCard: (@MainActor (Friend?) -> Void)?
    /// The curtain at the end of §6.6. Also `ContentView`'s, for the same reason.
    var onCurtain: (@MainActor () -> Void)?

    private let ticker: Ticker
    private let touch: TouchRouter
    private let voice: VoiceBank
    private let sound: SoundKit
    private var settings: LightingSettings
    private var flat = true

    private(set) var state: BakkerijState

    /// **Is the shop already open this sitting?** §6.1: *"one boolean in the
    /// save."* It is deliberately **not** in the save — a cold launch is a new
    /// sitting, and the blind going up is the thing that makes an empty bakery
    /// worth standing in. Process lifetime is exactly the life of a sitting.
    private static var shopOpenedThisSitting = false

    // MARK: - Entities

    private var counter: Entity?
    private var blind: BakkerijProps.Blind?
    private var window: BakkerijProps.Window?
    private var shopDoor: BakkerijProps.ShopDoor?
    private var bell: BakkerijProps.Bell?
    private var sign: BakkerijProps.Sign?
    private var hook: Entity?
    private var cat: Entity?
    private var radio: BakkerijProps.Radio?
    private var drawings: Entity?
    private var backDoor: Props.Doorway?
    private var baker: BakerCharacter?

    private var frames: [FrameWall.Frame] = []
    private var goldFrame: FrameWall.Frame?

    /// The friend who came in, once they have. Built from `GuestCharacter` — the
    /// eleven animals already exist and this room does not get to invent a
    /// twelfth way of drawing one.
    private var guest: GuestCharacter?
    private var card: Entity?
    private var photo: Entity?

    private var halo: Halo.Handle?
    private var frameGlow: ModelEntity?

    // MARK: - Interaction

    private var blindProgress: Float = 0
    private var doorProgress: Float = 0
    private var dragFrom: SIMD3<Float>?
    private var radioPlaying = false
    private var radioJob: Int?

    private var idleJob: Int?
    private var idleTime: Float = 0
    private var nudgeStage = 0
    private var alternateNudge = false
    private var shimmerJob: Int?
    private var misses = 0
    private var jobs: [Int] = []

    // MARK: - Life

    init(ticker: Ticker, touch: TouchRouter, voice: VoiceBank,
         sound: SoundKit, settings: LightingSettings,
         mode: RoomMode = .bezoek,
         friend: Friend? = nil, result: FeestResult? = nil) {
        self.ticker = ticker
        self.touch = touch
        self.voice = voice
        self.sound = sound
        self.settings = settings
        self.mode = mode

        let wall = GameStore.load()
        if let result {
            self.state = .returning(wall: wall, result: result)
        } else {
            var fresh = BakkerijState.outbound(wall: wall,
                                               shopOpen: BakkerijRoom.shopOpenedThisSitting)
            // A friend handed in without a party result means the debug strip, or
            // a round resumed mid-flight: she has already chosen.
            if let friend, fresh.step == .kiezen {
                fresh.friend = friend
                fresh.step = .binnenlaten
            }
            self.state = fresh
        }
        root.name = "Bakkerij"
    }

    // MARK: - Building

    func build(flat: Bool) {
        self.flat = flat
        cancelEverything()
        root.children.removeAll()
        touch.removeAll()
        frames.removeAll()

        BakkerijLayout.assertSpacing()

        root.addChild(RoomBox.shell(flat: flat))

        buildCounter()
        buildFrameWall()
        buildShopFront()
        buildHookAndDrawings()
        buildBackDoor()
        buildToys()
        buildBaker()
        if state.step == .ophangen { buildPhotograph() }

        registerTargets()
        applyStep(animated: false)
        startIdleWatch()
    }

    private func buildCounter() {
        let top = BakkerijProps.counter(flat: flat)
        root.addChild(top)
        counter = top
    }

    private func buildFrameWall() {
        for friend in Friend.allCases {
            let frame = FrameWall.frame(for: friend, fill: state.wall.fill(for: friend),
                                        flat: flat)
            root.addChild(frame.root)
            frames.append(frame)
        }
        let gold = FrameWall.goldFrame(earned: state.wall.goldIsEarned,
                                       fill: nil, flat: flat)
        root.addChild(gold.root)
        goldFrame = gold
    }

    private func buildShopFront() {
        let rolluik = BakkerijProps.blind(flat: flat)
        root.addChild(rolluik.root)
        blind = rolluik

        let raam = BakkerijProps.window(flat: flat)
        root.addChild(raam.root)
        window = raam
        paintSky()

        let deur = BakkerijProps.shopDoor(flat: flat)
        root.addChild(deur.root)
        shopDoor = deur

        let bel = BakkerijProps.bell(flat: flat)
        root.addChild(bel.root)
        bell = bel

        let bord = BakkerijProps.sign(flat: flat)
        root.addChild(bord.root)
        sign = bord
        paintSign()

        // The blind starts where the sitting left it.
        blindProgress = BakkerijRoom.shopOpenedThisSitting ? 1 : 0
        applyBlind()
        applyShopDoor()
    }

    private func buildHookAndDrawings() {
        let haak = BakkerijProps.orderHook(flat: flat)
        root.addChild(haak)
        hook = haak

        let tekeningen = BakkerijProps.drawings(flat: flat)
        root.addChild(tekeningen)
        drawings = tekeningen
    }

    private func buildBackDoor() {
        // **The way out, and the same doorway prop and the same spot as every
        // other room.** `Props.doorway`: *"the way out being where it was last
        // time is worth more to a 4-year-old than variety is."*
        let door = Props.doorway(flat: flat, centre: BakkerijLayout.doorwayCentre)
        root.addChild(door.root)
        backDoor = door
    }

    private func buildToys() {
        let poes = BakkerijProps.cat(flat: flat)
        root.addChild(poes)
        cat = poes

        let radioProp = BakkerijProps.radio(flat: flat)
        root.addChild(radioProp.root)
        radio = radioProp
    }

    private func buildBaker() {
        baker?.stop()
        // **Her own spot, passed in.** `BakerCharacter`'s default home is the
        // kitchen's corner, and a room that does not pass its own has her ease
        // back to the kitchen after every cheer.
        let nina = BakerCharacter(ticker: ticker, flat: flat,
                                  home: BakkerijLayout.bakerSpot)
        root.addChild(nina.root)
        baker = nina
    }

    // MARK: - The step machine

    /// **One function that rebuilds everything the step implies** (`ROOMS.md`
    /// §1). Every cue in the room is set from here and nowhere else, so there is
    /// one place to read to know what is lit.
    private func applyStep(animated: Bool) {
        Halo.remove(halo, ticker: ticker)
        halo = nil
        stopGhostWave()
        clearFrameGlow()

        switch state.step {
        case .opendoen:
            // The cord knob, over the counter's own surface so the ring has
            // something real to lie on.
            if let knob = blind?.knob {
                halo = Halo.attach(to: knob, radius: 0.017, ticker: ticker) { _ in
                    BakkerijLayout.cordKnobHome.y - 0.030
                }
            }

        case .kiezen:
            // **Nothing is lit.** See the note on the type. The ghosts breathe
            // instead, one after another on a slow rolling wave.
            startGhostWave()

        case .binnenlaten:
            // The bell rings by itself, and *then* the door is the thing to drag.
            // `references/bakkerij/README.md`: there is no glass in this game, so
            // the cue is the bell and the leaf, never a silhouette behind it.
            if animated { ringBell(thenInvite: true) } else { inviteShopDoor() }

        case .bestellen:
            // A journey, and only the destination end is a fact: the card is
            // already in the friend's hands and obvious, the hook is where it has
            // to go. `ROOMS.md` §3 — light the end that is a fact.
            if let hook {
                halo = Halo.attach(to: hook, radius: 0.016, ticker: ticker) { _ in
                    BakkerijLayout.cardHangCentre.y - 0.026
                }
            }

        case .ophangen:
            // The other journey. The photograph waits on the counter with a ring
            // under it; the destination frame glows from its own moulding,
            // because a floor halo cannot lie on a vertical wall and the doorway's
            // "light behind it" is the precedent for a cue that belongs to
            // something standing against one.
            if let photo {
                halo = Halo.attach(to: photo, radius: 0.020, ticker: ticker) { [weak self] p in
                    self?.surfaceY(at: p) ?? BakkerijLayout.counterTopY
                }
            }
            lightDestinationFrame()

        case .klaar:
            break
        }

        refreshInteractivity()
        refreshDoorInvitation()
    }

    /// Which targets answer, per step. **Nothing is ever disabled that does not
    /// have to be** (`ROOMS.md` §1) — the toys, the frames' naming taps and the
    /// door all stay live throughout; what changes is only what the step's own
    /// prop does.
    private func refreshInteractivity() {
        touch.target(named: "koord")?.enabled = state.step == .opendoen
        touch.target(named: "winkeldeur")?.enabled = state.step == .binnenlaten
        touch.target(named: "kaart")?.enabled = state.step == .bestellen
        touch.target(named: "foto")?.enabled = state.step == .ophangen
    }

    // MARK: - opendoen

    /// The blind, from shut to rolled up. One number drives the cloth, the roll's
    /// thickness, the cord and the knob.
    private func applyBlind() {
        guard let blind else { return }
        let t = max(0, min(1, blindProgress))

        let drop = BakkerijLayout.blindRollY - BakkerijLayout.blindShutY
        let remaining = drop * (1 - t)
        // The cloth shortens from the bottom, so it scales about its top edge.
        blind.cloth.scale = [1, max(0.001, 1 - t), 1]
        blind.cloth.position = [0, BakkerijLayout.blindRollY - remaining / 2, 0.004]

        // The roll fattens a little as the cloth winds onto it.
        blind.roll.scale = [1 + t * 0.35, 1, 1 + t * 0.35]

        let knobY = BakkerijLayout.cordKnobHome.y + BakkerijLayout.cordTravel * t
        blind.knob.position = [BakkerijLayout.cordKnobHome.x - BakkerijLayout.blindCentreX,
                               knobY, 0.004]
        let cordTop = BakkerijLayout.blindRollY - 0.010
        let length = max(0.004, cordTop - knobY)
        blind.cord.scale = [1, length / 0.060, 1]
        blind.cord.position = [BakkerijLayout.cordKnobHome.x - BakkerijLayout.blindCentreX,
                               knobY + length / 2, 0.004]
    }

    private func dragBlind(to world: SIMD3<Float>) {
        guard let from = dragFrom else { return }
        // **A vertical drag, reported on a horizontal plane.** `TouchRouter`
        // projects every drag onto a horizontal plane, which is the right
        // primitive for the four rooms that put things down on tables and the
        // wrong one for a cord on a wall. The camera never moves and looks down
        // at the room, so a finger travelling *up* the screen moves that
        // horizontal intersection *away* from the eye, monotonically — which
        // makes distance along the view's own ground direction a faithful stand-in
        // for screen-vertical. `BakkerijRoom.up` is that direction.
        let rise = simd_dot(SIMD2(world.x - from.x, world.z - from.z), BakkerijRoom.up)
        blindProgress = max(0, min(1, rise / BakkerijRoom.cordDragSpan))
        applyBlind()
    }

    private func endBlindDrag() {
        dragFrom = nil
        // Past two thirds it finishes by itself, which is `CONCEPT.md` §5's
        // generosity applied to a drag rather than to a drop.
        if blindProgress > 0.66 {
            openTheShop()
        } else {
            noteMiss()
            jobs.append(ticker.tween(0.35, step: { [weak self] t in
                guard let self else { return }
                self.blindProgress = self.blindProgress * (1 - t)
                self.applyBlind()
            }))
        }
    }

    private func openTheShop() {
        BakkerijRoom.shopOpenedThisSitting = true
        noteHit()
        sound.play(.roll)

        jobs.append(ticker.tween(0.55, step: { [weak self] t in
            guard let self else { return }
            self.blindProgress = self.blindProgress + (1 - self.blindProgress) * t
            self.applyBlind()
        }, done: { [weak self] in
            self?.revealTheWall()
        }))
    }

    /// **Daylight, and the wall of frames lighting up.** §6.1 asks the blind to
    /// buy the wall a reveal rather than a fade-in, and this is that: a sweep of
    /// sparkles across the twelve, in the order she reads them.
    private func revealTheWall() {
        sound.play(.sparkle)
        baker?.set(.cheering)

        for (index, frame) in frames.enumerated() {
            let delay = Float(index) * 0.055
            jobs.append(ticker.after(delay) { [weak self] in
                guard let self else { return }
                Sparkles.burst(at: frame.root.position, in: self.root, ticker: self.ticker,
                               colour: Palette.butterYellow, count: 4, size: 0.0022,
                               speed: 0.05, life: 0.6, glow: 1.4)
                self.ticker.squash(frame.root, amount: 0.10, duration: 0.35)
            })
        }

        jobs.append(ticker.after(0.75) { [weak self] in
            guard let self else { return }
            self.voice.sayInstead(BakkerijLine.openGedaan)
            self.advance(to: self.state.wall.goldIsEarned ? .binnenlaten : .kiezen)
        })
    }

    // MARK: - kiezen

    /// **The rolling wave.** No halo, so this is the whole of what the step says:
    /// every waiting ghost breathes in turn, endlessly, in reading order.
    private func startGhostWave() {
        stopGhostWave()
        let waiting = frames.filter { frame in
            guard let friend = frame.friend else { return false }
            return !state.wall.isFilled(friend)
        }
        guard !waiting.isEmpty else { return }

        var clock: Float = 0
        shimmerJob = ticker.add { [weak self] dt in
            guard self != nil else { return false }
            clock += dt
            let period: Float = 2.6
            let spacing = period / Float(waiting.count)
            for (index, frame) in waiting.enumerated() {
                let phase = clock - Float(index) * spacing
                let cycle = phase.truncatingRemainder(dividingBy: period)
                // A short breath in a long silence: each frame is only moving for
                // about a fifth of the wave, so the wall reads as one thing
                // travelling rather than twelve things pulsing.
                let lift: Float
                if cycle >= 0 && cycle < 0.55 {
                    lift = sin(cycle / 0.55 * .pi) * 0.055
                } else {
                    lift = 0
                }
                frame.root.scale = .init(repeating: 1 + lift)
            }
            return true
        }
    }

    private func stopGhostWave() {
        ticker.cancel(shimmerJob)
        shimmerJob = nil
        for frame in frames { frame.root.scale = .one }
    }

    private func choose(_ friend: Friend) {
        guard state.step == .kiezen, !state.wall.isFilled(friend) else { return }
        state.friend = friend
        sound.play(.ding)
        noteHit()

        // §6.1: *"that friend's outline colours in a little and steps forward.
        // Today is theirs."*
        if let frame = frames.first(where: { $0.friend == friend }) {
            stopGhostWave()
            ticker.squash(frame.root, amount: 0.16, duration: 0.5)
            Sparkles.burst(at: frame.root.position, in: root, ticker: ticker,
                           colour: friend.colour, count: 8, size: 0.0026,
                           speed: 0.07, life: 0.7, glow: 1.2)
            for child in frame.inside.children {
                tint(child, to: Palette.mix(Palette.ghostGrey, friend.colour, 0.55))
            }
        }

        voice.sayInstead([BakkerijLine.gekozen])
        advance(to: .binnenlaten, after: 1.1)
    }

    // MARK: - binnenlaten

    /// The bell, rung by the friend outside. §6.1 keeps this out of her hands on
    /// purpose — it is what lets the bell stay a toy rather than become a step.
    private func ringBell(thenInvite: Bool) {
        jobs.append(ticker.after(0.9) { [weak self] in
            guard let self else { return }
            self.sound.play(.ding)
            if let swing = self.bell?.swing {
                self.jobs.append(self.ticker.wiggle(swing, angle: 0.5, duration: 0.9))
            }
            self.baker?.set(.cheering)
            self.voice.sayInstead(BakkerijLine.bel)
            if thenInvite {
                self.jobs.append(self.ticker.after(0.5) { [weak self] in
                    self?.inviteShopDoor()
                })
            }
        })
    }

    /// The shop door, ajar and lit — but **only while `binnenlaten` is running**.
    /// The moment the friend is inside this is withdrawn, because from then on
    /// the only thing in the room allowed to mean "this is finished" is the back
    /// door (`ROOMS.md` §9).
    private func inviteShopDoor() {
        guard state.step == .binnenlaten else { return }
        applyShopDoor(ajar: true)
        shopDoor?.glow.model?.materials = [Palette.glowMaterial(Palette.butterYellow,
                                                                intensity: 1.6)]
    }

    private func applyShopDoor(ajar: Bool = false) {
        guard let shopDoor else { return }
        let ajarAngle: Float = 11 * .pi / 180
        let angle = doorProgress > 0 ? doorProgress * 1.35 : (ajar ? ajarAngle : 0)
        shopDoor.hinge.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
    }

    private func dragShopDoor(to world: SIMD3<Float>) {
        guard let from = dragFrom else { return }
        // Towards the camera opens it — the leaf swings into the room.
        let pull = simd_dot(SIMD2(world.x - from.x, world.z - from.z), -BakkerijRoom.up)
        doorProgress = max(0, min(1, pull / BakkerijRoom.doorDragSpan))
        applyShopDoor()
    }

    private func endShopDoorDrag() {
        dragFrom = nil
        if doorProgress > 0.5 {
            letTheFriendIn()
        } else {
            noteMiss()
            jobs.append(ticker.tween(0.3, step: { [weak self] t in
                guard let self else { return }
                self.doorProgress *= (1 - t)
                self.applyShopDoor(ajar: true)
            }))
        }
    }

    private func letTheFriendIn() {
        guard let friend = state.friend else { return }
        noteHit()
        sound.play(.whoosh)

        jobs.append(ticker.tween(0.4, step: { [weak self] t in
            guard let self else { return }
            self.doorProgress = self.doorProgress + (1 - self.doorProgress) * t
            self.applyShopDoor()
        }))

        // **The friend is a `GuestCharacter`.** The eleven animals already exist,
        // built from one body and a swapped head, and this room does not get to
        // invent a twelfth way of drawing one.
        let visitor = GuestCharacter(friend: friend, role: .gast, style: .zwaaien,
                                     at: BakkerijLayout.friendEntry, phase: 0,
                                     ticker: ticker, flat: flat)
        root.addChild(visitor.root)
        visitor.settle()
        guest = visitor

        // They walk to the counter, and Nina says hello when they get there.
        jobs.append(ticker.move(visitor.root, to: BakkerijLayout.friendSpot,
                                duration: 1.5, arc: 0.004) { [weak self] in
            guard let self else { return }
            self.ticker.squash(visitor.root, amount: 0.10, duration: 0.4)
            self.voice.sayInstead(BakkerijLine.binnen)
            self.giveCard(to: friend)
            self.advance(to: .bestellen, after: 0.5)
        })

        // And the shop door stops being a cue the moment it has been used.
        jobs.append(ticker.after(1.2) { [weak self] in
            self?.shopDoor?.glow.model?.materials = [Palette.material(Palette.butterYellow)]
        })
    }

    // MARK: - bestellen

    /// The wish card, held out over the counter.
    private func giveCard(to friend: Friend) {
        let node = BakkerijProps.wishCard(for: friend, flat: flat)
        node.position = [BakkerijLayout.friendSpot.x + 0.020, 0.096,
                         BakkerijLayout.friendSpot.z - 0.012]
        node.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        root.addChild(node)
        card = node

        // **Registered here rather than in `registerTargets`**, because a target
        // with no entity is skipped by the hit test outright — `TouchRouter`
        // guards on `let entity = target.entity`. `remove(prefixed:)` first
        // because `register` appends (`ROOMS.md` §11's trap).
        touch.remove(prefixed: "kaart")
        touch.register("kaart", entity: node, radius: 0.030,
                       planeY: BakkerijLayout.cardHangCentre.y) { [weak self] target in
            target.onDragBegan = { [weak self] world in self?.dragFrom = world }
            target.onDragMoved = { [weak self] world in self?.dragCard(to: world) }
            target.onDragEnded = { [weak self] _ in self?.endCardDrag() }
            target.onTap = { [weak self] in
                guard let self, let friend = self.state.friend else { return }
                self.voice.say(BakkerijLine.wish(for: friend))
            }
        }

        // Nina relays the wish in her own words — `GAMEPLAY.md` §4, and the same
        // line the card replays all round when it is tapped.
        voice.sayWhenQuiet([BakkerijLine.wish(for: friend), BakkerijLine.bestellen])
    }

    private func dragCard(to world: SIMD3<Float>) {
        guard let card else { return }
        card.position = [world.x, BakkerijLayout.cardHangCentre.y, world.z]
    }

    private func endCardDrag() {
        dragFrom = nil
        guard let card else { return }
        let landed = RoomBox.distanceXZ(card.position, BakkerijLayout.cardHangCentre)
        guard landed < BakkerijLayout.cardSnapRadius else {
            // **Nothing is put back.** `ROOMS.md` §6: a wrong drag is not wrong
            // and it is not undone — the card stays where she let go of it and
            // stays draggable.
            noteMiss()
            return
        }
        hangCard(card)
    }

    private func hangCard(_ card: Entity) {
        noteHit()
        sound.play(.plop)
        guard let friend = state.friend else { return }

        jobs.append(ticker.move(card, to: BakkerijLayout.cardHangCentre,
                                duration: 0.25, arc: 0.004) { [weak self] in
            guard let self else { return }
            self.ticker.wiggle(card, angle: 0.18, duration: 0.6)
            Sparkles.burst(at: BakkerijLayout.cardHangCentre, in: self.root,
                           ticker: self.ticker, colour: Palette.butterYellow,
                           count: 6, size: 0.0024, speed: 0.06, life: 0.6, glow: 1.2)

            // **Then it flies to the corner and becomes the wish card.** §4 makes
            // it the only persistent interface element in the game; §6.1 makes
            // her hang it first, so it is earned rather than chrome.
            self.jobs.append(self.ticker.after(0.7) { [weak self] in
                guard let self else { return }
                self.jobs.append(self.ticker.tween(0.45, step: { t in
                    card.scale = .init(repeating: max(0.01, 1 - t))
                    card.position = BakkerijLayout.cardHangCentre
                        + SIMD3<Float>(0, 0.05 * t, 0.06 * t)
                }, done: { [weak self] in
                    card.removeFromParent()
                    self?.card = nil
                    self?.onWishCard?(friend)
                }))
                self.voice.sayInstead(BakkerijLine.naarTuin)
                self.openTheWayOut()
            })
        })
    }

    /// The back door lights, and from here the room is finished with her.
    ///
    /// The halo moves from the hook to the door rather than a second one being
    /// added — `ROOMS.md` §3: exactly one thing is lit.
    private func openTheWayOut() {
        Halo.remove(halo, ticker: ticker)
        halo = nil
        refreshDoorInvitation()
        if let door = backDoor?.root {
            halo = Halo.attach(to: door, radius: 0.026, ticker: ticker) { _ in
                RoomBox.floorY
            }
        }
    }

    // MARK: - ophangen — the return leg

    private func buildPhotograph() {
        guard let result = state.result else { return }
        let fill = FrameFill(version: 1, cake: result.cake,
                             wishMatched: result.matched, when: Date())
        let node = BakkerijProps.photograph(of: fill, friend: result.friend, flat: flat)
        node.position = BakkerijLayout.photoRest
        node.position.y += 0.022
        node.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        root.addChild(node)
        photo = node

        touch.remove(prefixed: "foto")
        touch.register("foto", entity: node, radius: BakkerijLayout.photoRadius,
                       planeY: BakkerijLayout.photoRest.y + 0.030) { [weak self] target in
            target.onDragBegan = { [weak self] world in self?.dragFrom = world }
            target.onDragMoved = { [weak self] world in self?.dragPhoto(to: world) }
            target.onDragEnded = { [weak self] _ in self?.endPhotoDrag() }
            target.onTap = { [weak self] in
                self?.voice.say(BakkerijLine.ophangen)
            }
        }
    }

    /// The frame she is going to hang it in, lit from its own moulding.
    private func lightDestinationFrame() {
        guard let friend = state.friend,
              let frame = frames.first(where: { $0.friend == friend }) else { return }
        frame.moulding.model?.materials = [Palette.glowMaterial(Palette.butterYellow,
                                                                intensity: 1.5)]
        frameGlow = frame.moulding
    }

    private func clearFrameGlow() {
        frameGlow?.model?.materials = [Palette.material(Palette.cream)]
        frameGlow = nil
    }

    private func dragPhoto(to world: SIMD3<Float>) {
        guard let photo else { return }
        photo.position = [world.x, BakkerijLayout.photoRest.y + 0.030, world.z]
    }

    private func endPhotoDrag() {
        dragFrom = nil
        guard let photo, let friend = state.friend else { return }
        let target = BakkerijLayout.framePosition(for: friend)
        // XZ only, as every snap in this game is — and here the row does not need
        // separating, because exactly one frame in the room is a valid
        // destination.
        guard RoomBox.distanceXZ(photo.position, target) < BakkerijLayout.cardSnapRadius
        else {
            noteMiss()
            return
        }
        hangPhoto(photo, for: friend, at: target)
    }

    /// **The most complete moment in the game.** §6.6.
    private func hangPhoto(_ photo: Entity, for friend: Friend, at target: SIMD3<Float>) {
        noteHit()
        guard let result = state.result else { return }

        jobs.append(ticker.move(photo, to: target + SIMD3<Float>(0.006, 0, 0),
                                duration: 0.4, arc: 0.012) { [weak self] in
            guard let self else { return }
            photo.removeFromParent()
            self.photo = nil

            // **The wall is written here and nowhere else**, and the round is
            // cleared with it: the photograph is hung, so today is over.
            self.state.wall.fill(friend, with: result.cake, matched: result.matched,
                                 when: Date())
            self.persistWall(clearingRound: true)

            // The ghost is gone: the frame is rebuilt holding the photograph.
            if let index = self.frames.firstIndex(where: { $0.friend == friend }) {
                let old = self.frames[index]
                old.root.removeFromParent()
                let rebuilt = FrameWall.frame(for: friend,
                                              fill: self.state.wall.fill(for: friend),
                                              flat: self.flat)
                self.root.addChild(rebuilt.root)
                self.frames[index] = rebuilt
                self.ticker.squash(rebuilt.root, amount: 0.18, duration: 0.6)
                rebuilt.moulding.model?.materials =
                    [Palette.glowMaterial(Palette.butterYellow, intensity: 2.0)]
                self.jobs.append(self.ticker.after(1.4) { [weak rebuilt] in
                    rebuilt?.moulding.model?.materials = [Palette.material(Palette.cream)]
                })
            }

            self.sound.play(.reward)
            Sparkles.burst(at: target, in: self.root, ticker: self.ticker,
                           colour: Palette.butterYellow, count: 14, size: 0.0030,
                           speed: 0.09, life: 0.9, glow: 1.6)
            self.baker?.set(.cheering)
            self.onWishCard?(nil)
            self.paintSign()
            self.finishTheDay()
        })
    }

    private func finishTheDay() {
        state.step = .klaar
        refreshInteractivity()

        // The finale, stubbed: `GAMEPLAY.md` §2's every-friend-arrives-at-once is
        // its own job. What is here is the honest minimum — the sign fully lit,
        // one line, and the flag written so the wall knows it has happened.
        let finale = state.wall.goldIsEarned && state.wall.finalePlayed != true
        if finale {
            state.wall.finalePlayed = true
            persistWall()
            jobs.append(ticker.after(1.0) { [weak self] in
                guard let self else { return }
                self.voice.sayInstead(BakkerijLine.alleLijstjes)
                self.sound.play(.applaus)
                for frame in self.frames {
                    Sparkles.burst(at: frame.root.position, in: self.root,
                                   ticker: self.ticker, colour: Palette.butterYellow,
                                   count: 6, size: 0.0026, speed: 0.07, life: 0.9,
                                   glow: 1.5)
                }
            })
        } else {
            jobs.append(ticker.after(0.9) { [weak self] in
                self?.voice.sayInstead(BakkerijLine.klaar)
            })
        }

        // Then the curtain, and the room stands ready at `kiezen` behind it.
        jobs.append(ticker.after(finale ? 4.4 : 3.2) { [weak self] in
            guard let self else { return }
            self.onCurtain?()
            self.jobs.append(self.ticker.after(1.1) { [weak self] in
                guard let self else { return }
                self.state = .outbound(wall: self.state.wall, shopOpen: true)
                self.guest?.stop()
                self.guest?.root.removeFromParent()
                self.guest = nil
                self.build(flat: self.flat)
            })
        })
    }

    // MARK: - The way out

    /// `ROOMS.md` §9, said three ways at once: the leaf off the latch at 11°, the
    /// light behind it, and the ring on the floor at the threshold.
    private func refreshDoorInvitation() {
        guard let door = backDoor else { return }
        let open = state.step == .bestellen && card == nil
        let ajarAngle: Float = 11 * .pi / 180
        door.hinge.orientation = simd_quatf(angle: open ? ajarAngle : 0, axis: [0, 1, 0])
        door.glow?.model?.materials = open
            ? [Palette.glowMaterial(Palette.butterYellow, intensity: 1.7)]
            : [Palette.material(Palette.butterYellow)]
    }

    private func leaveForTheGarden() {
        guard state.step == .bestellen, card == nil, let friend = state.friend else { return }
        sound.play(.whoosh)

        if let door = backDoor {
            jobs.append(ticker.tween(0.6, step: { t in
                door.hinge.orientation = simd_quatf(angle: (0.19 + t * 1.1), axis: [0, 1, 0])
            }))
        }
        voice.sayWhenQuiet(BakkerijLine.naarTuin)

        // **0.9 s after the leaf reaches full open**, which is what every other
        // room does: the beat before the swap is the ceremony, not dead time.
        jobs.append(ticker.after(1.5) { [weak self] in
            self?.onExit?(.tuin(friend))
        })
    }

    // MARK: - Targets

    private func registerTargets() {
        registerFrameTargets()
        registerStepTargets()
        registerToyTargets()

        // **A tap on nothing sparkles under her finger.** Not optional
        // (`ROOMS.md` §5) — a dead tap reads as a broken iPad.
        touch.onEmptyTap = { [weak self] world in
            guard let self else { return }
            Sparkles.burst(at: world, in: self.root, ticker: self.ticker,
                           colour: Palette.creamLight, count: 5, size: 0.0022,
                           speed: 0.06, life: 0.5)
        }
        touch.onAnyTouch = { [weak self] in self?.resetIdle() }
    }

    private func registerFrameTargets() {
        for frame in frames {
            guard let friend = frame.friend else { continue }
            touch.register(FrameWall.nodeName(for: friend), entity: frame.root,
                           radius: BakkerijLayout.frameRadius,
                           planeY: frame.root.position.y) { [weak self] target in
                target.onTap = { [weak self] in
                    guard let self else { return }
                    if self.state.step == .kiezen, !self.state.wall.isFilled(friend) {
                        self.choose(friend)
                    } else {
                        // A filled frame does nothing yet — owner's call, and the
                        // replay in `GAMEPLAY.md` §2 waits until Nina has been
                        // watched with the wall. It still answers, because a dead
                        // tap reads as broken.
                        self.tapFrame(frame)
                    }
                }
            }
        }

        if let gold = goldFrame {
            touch.register(FrameWall.goldNodeName, entity: gold.root,
                           radius: BakkerijLayout.goldRadius,
                           planeY: gold.root.position.y) { [weak self] target in
                target.onTap = { [weak self] in self?.tapFrame(gold) }
            }
        }
    }

    private func tapFrame(_ frame: FrameWall.Frame) {
        ticker.squash(frame.root, amount: 0.12, duration: 0.4)
        sound.play(.plop, volume: 0.5)
        voice.say(BakkerijLine.ditLijstje, priority: .low)
    }

    private func registerStepTargets() {
        if let knob = blind?.knob {
            touch.register("koord", entity: knob, radius: BakkerijLayout.cordRadius,
                           planeY: BakkerijLayout.cordKnobHome.y) { [weak self] target in
                target.onDragBegan = { [weak self] world in self?.dragFrom = world }
                target.onDragMoved = { [weak self] world in self?.dragBlind(to: world) }
                target.onDragEnded = { [weak self] _ in self?.endBlindDrag() }
                target.onTap = { [weak self] in
                    guard let self else { return }
                    self.voice.say(BakkerijLine.ditRolluik, priority: .low)
                    // Every tap does something: a tap on the cord gives it a tug.
                    if let knob = self.blind?.knob { self.ticker.squash(knob, amount: 0.2) }
                }
            }
        }

        if let leaf = shopDoor?.hinge {
            touch.register("winkeldeur", entity: leaf,
                           radius: BakkerijLayout.shopDoorRadius,
                           planeY: BakkerijLayout.shopDoorCentre.y + 0.06) { [weak self] target in
                target.onDragBegan = { [weak self] world in self?.dragFrom = world }
                target.onDragMoved = { [weak self] world in self?.dragShopDoor(to: world) }
                target.onDragEnded = { [weak self] _ in self?.endShopDoorDrag() }
                target.onTap = { [weak self] in
                    self?.voice.say(BakkerijLine.ditWinkeldeur, priority: .low)
                }
            }
        }

        if let hook {
            touch.register("haak", entity: hook, radius: BakkerijLayout.hookRadius,
                           planeY: BakkerijLayout.hookCentre.y) { [weak self] target in
                target.onTap = { [weak self] in
                    self?.voice.say(BakkerijLine.ditHaak, priority: .low)
                }
            }
        }

        if let door = backDoor?.root {
            touch.register("deur", entity: door, radius: BakkerijLayout.doorRadius,
                           planeY: RoomBox.floorY) { [weak self] target in
                target.onTap = { [weak self] in
                    guard let self else { return }
                    if self.state.step == .bestellen, self.card == nil {
                        self.leaveForTheGarden()
                    } else {
                        self.voice.say(Line.ditDeur, priority: .low)
                    }
                }
            }
        }
    }

    /// **Five toys, none of them consumed by anything** (`ROOMS.md` §8, and
    /// §6.1's own list). The bell is rung by the friend rather than by her, which
    /// is what keeps it on this side of the line.
    private func registerToyTargets() {
        if let cat {
            touch.register("poes", entity: cat, radius: BakkerijLayout.catRadius,
                           planeY: BakkerijLayout.catCentre.y) { [weak self] target in
                target.onTap = { [weak self] in
                    guard let self else { return }
                    // Stretches, then resettles.
                    self.jobs.append(self.ticker.tween(1.1, step: { t in
                        let stretch = sin(t * .pi)
                        cat.scale = [1 + stretch * 0.22, 1 - stretch * 0.10,
                                     1 + stretch * 0.06]
                    }, done: { cat.scale = .one }))
                    self.sound.play(.plop, volume: 0.4)
                    self.voice.say(BakkerijLine.ditPoes, priority: .low)
                }
            }
        }

        if let radio {
            touch.register("radio", entity: radio.root, radius: BakkerijLayout.radioRadius,
                           planeY: BakkerijLayout.radioCentre.y) { [weak self] target in
                target.onTap = { [weak self] in self?.toggleRadio() }
            }
        }

        if let window = window?.root {
            touch.register("raam", entity: window, radius: BakkerijLayout.windowRadius,
                           planeY: BakkerijLayout.windowCentre.y) { [weak self] target in
                target.onTap = { [weak self] in
                    guard let self else { return }
                    self.ticker.squash(window, amount: 0.08, duration: 0.4)
                    self.paintSky()
                    self.voice.say(BakkerijLine.ditRaam, priority: .low)
                }
            }
        }

        if let bell = bell {
            touch.register("bel", entity: bell.root, radius: BakkerijLayout.bellRadius,
                           planeY: BakkerijLayout.bellCentre.y) { [weak self] target in
                target.onTap = { [weak self] in
                    guard let self else { return }
                    self.sound.play(.ding, volume: 0.7)
                    self.jobs.append(self.ticker.wiggle(bell.swing, angle: 0.4,
                                                        duration: 0.7))
                    self.voice.say(BakkerijLine.ditBel, priority: .low)
                }
            }
        }

        if let drawings {
            touch.register("tekeningen", entity: drawings,
                           radius: BakkerijLayout.drawingsRadius,
                           planeY: BakkerijLayout.drawingsCentre.y) { [weak self] target in
                target.onTap = { [weak self] in
                    guard let self else { return }
                    for sheet in drawings.children {
                        self.jobs.append(self.ticker.wiggle(sheet, angle: 0.10,
                                                            duration: 0.6))
                    }
                    self.sound.play(.rattle, volume: 0.35)
                    self.voice.say(BakkerijLine.ditTekening, priority: .low)
                }
            }
        }

        if let sign = sign?.root {
            touch.register("uithangbord", entity: sign, radius: BakkerijLayout.signRadius,
                           planeY: BakkerijLayout.signCentre.y) { [weak self] target in
                target.onTap = { [weak self] in
                    guard let self else { return }
                    self.ticker.squash(sign, amount: 0.10, duration: 0.4)
                    self.voice.say(BakkerijLine.ditUithangbord, priority: .low)
                }
            }
        }
    }

    /// The radio plays a little loop, and tapping it again stops it —
    /// `GAMEPLAY.md` §6.1's third toy. **No new `SoundKit` case**: it is the
    /// garden's chiming-flowers trick, existing voices at different rates, which
    /// `ROOMS.md` §10 asks a room to reach for before adding vocabulary.
    private func toggleRadio() {
        radioPlaying.toggle()
        voice.say(BakkerijLine.ditRadio, priority: .low)
        guard let dial = radio?.dial else { return }
        jobs.append(ticker.wiggle(dial, angle: 0.5, duration: 0.4))

        if !radioPlaying {
            ticker.cancel(radioJob)
            radioJob = nil
            return
        }

        let tune: [(Sound, Float)] = [(.ding, 1.0), (.ding, 1.25), (.fluit, 0.9),
                                      (.ding, 1.5), (.toeter, 1.1), (.ding, 1.25)]
        var step = 0
        var since: Float = 0
        radioJob = ticker.add { [weak self] dt in
            guard let self, self.radioPlaying else { return false }
            since += dt
            guard since > 0.42 else { return true }
            since = 0
            let (sound, rate) = tune[step % tune.count]
            self.sound.play(sound, volume: 0.30, rate: rate)
            step += 1
            return true
        }
    }

    // MARK: - The sign, and the sky

    /// **The game's progress bar, and it has no numbers on it.** §2: each filled
    /// frame brings a little more colour and a little more glow into the sign.
    private func paintSign() {
        guard let sign else { return }
        let total = Float(Friend.allCases.count)
        let t = min(1, Float(state.wall.filledCount) / total)

        sign.board.model?.materials = [Palette.material(Palette.mix(Palette.ghostGrey,
                                                                    Palette.blushPink, t))]
        sign.cake.model?.materials = [Palette.material(Palette.mix(Palette.ghostGrey,
                                                                   Palette.creamLight, t))]
        sign.star.model?.materials = [Palette.material(Palette.mix(Palette.ghostGrey,
                                                                    Palette.sage, t))]
        // And by the twelfth it hums.
        if state.wall.goldIsEarned {
            sign.board.model?.materials = [Palette.glowMaterial(Palette.blushPink,
                                                                 intensity: 1.3)]
        }
    }

    /// The window shows the actual time of day — §6.1's fourth toy, and the one
    /// piece of this room that is quietly true.
    private func paintSky() {
        guard let pane = window?.pane else { return }
        let hour = Calendar.current.component(.hour, from: Date())
        let sky = BakkerijProps.skyColour(hour: hour)
        pane.model?.materials = [Palette.glowMaterial(sky.colour, intensity: sky.glow)]
    }

    // MARK: - Room

    func greet() {
        switch state.step {
        case .ophangen:
            voice.say(BakkerijLine.ophangen)
        case .opendoen:
            voice.say(BakkerijLine.hallo)
        default:
            voice.say(state.wall.goldIsEarned ? BakkerijLine.halloVrij
                                              : BakkerijLine.halloOpen)
        }
        // And the step's own line a beat behind the greeting, so the two do not
        // talk over each other.
        jobs.append(voice.whenQuiet(after: 0.5, timeout: 8) { [weak self] in
            guard let self else { return }
            switch self.state.step {
            case .opendoen: self.voice.say(BakkerijLine.opendoen)
            case .kiezen: self.voice.say(BakkerijLine.kiezen)
            default: break
            }
        })
    }

    func save() {
        // The room has no file of its own — everything durable here is the wall's.
        persistWall()
    }

    /// **The wall is this room's to write; the round is `GameScene`'s.**
    ///
    /// So this merges rather than overwrites, and the reason is a bug that was
    /// already in the tin: `GameScene.handle` writes the round the moment she
    /// leaves for the garden, and 1.4 s later `enter` tears this room down, which
    /// calls `leave`, which calls `save`. A `save` that wrote the whole struct
    /// would put `room: "bakkerij"` back over the `room: "tuin"` that had just
    /// been written, and a relaunch would drop her back in the hub instead of the
    /// garden she was walking into.
    ///
    /// Two writers, one file, and each of them owning named fields is the fix.
    private func persistWall(clearingRound: Bool = false) {
        var disk = GameStore.load()
        disk.frames = state.wall.frames
        disk.finalePlayed = state.wall.finalePlayed
        if clearingRound { disk.round = nil }
        GameStore.save(disk)
        state.wall = disk
    }

    /// **One meaning: this round, back to its beginning** (`ROOMS.md` §8).
    ///
    /// It never touches the wall. A button that could quietly empty a fortnight
    /// of baking is not one a 4-year-old should be able to find, and the wall is
    /// not the round's to throw away.
    func restartRound() {
        onWishCard?(nil)
        persistWall(clearingRound: true)
        guest?.stop()
        guest = nil
        voice.sayInstead(BakkerijLine.opnieuw)

        if let result = state.result {
            state = .returning(wall: state.wall, result: result)
        } else {
            state = .outbound(wall: state.wall,
                              shopOpen: BakkerijRoom.shopOpenedThisSitting)
        }
        build(flat: flat)
    }

    /// Measured against the garden and the disco on the same 1200 lx dome.
    /// Scale ambient so a debug-panel move still moves. `-no-bakkerij-ao`
    /// leaves the approved rig.
    static func lighting(from settings: LightingSettings) -> LightingSettings {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-no-bakkerij-ao") {
            return settings
        }
        #endif
        let tuned = LightingSettings()
        tuned.keyEnabled = settings.keyEnabled
        tuned.keyIntensity = settings.keyIntensity
        tuned.keyElevation = settings.keyElevation
        tuned.keyAzimuth = settings.keyAzimuth
        tuned.keyTemperature = settings.keyTemperature
        tuned.shadowsEnabled = settings.shadowsEnabled
        tuned.fillEnabled = settings.fillEnabled
        tuned.fillIntensity = settings.fillIntensity
        tuned.fillTemperature = settings.fillTemperature
        tuned.ambientEnabled = settings.ambientEnabled
        tuned.ambientIntensity = settings.ambientIntensity * (800.0 / 1200.0)
        tuned.iblEnabled = settings.iblEnabled
        tuned.iblIntensity = settings.iblIntensity
        tuned.contactShadowsEnabled = settings.contactShadowsEnabled
        tuned.contactShadowOpacity = settings.contactShadowOpacity
        tuned.contactShadowScale = settings.contactShadowScale
        tuned.flatShading = settings.flatShading
        tuned.lightmapMode = settings.lightmapMode
        return tuned
    }

    func refreshContactShadows(settings: LightingSettings) {
        self.settings = settings
        let shadows = Self.contactShadowSettings(from: settings)
        let props: [(Entity?, Float)] = [
            (cat, 0.014),
            (radio?.root, 0.014),
            (baker?.root, 0.020),
            (guest?.root, 0.020),
        ]
        for (prop, radius) in props {
            guard let prop, prop.isEnabled else { continue }
            ContactShadows.attach(to: prop, radius: radius, settings: shadows)
            ContactShadows.update(for: prop, surfaceY: surfaceY(at: prop.position),
                                  settings: shadows)
        }
    }

    /// `ContactShadows` writes opacity into colour alpha and the transparent
    /// blend, so 0.22 arrives as 0.22². Garden and party already compensate.
    /// Bakery-local so the shared helper must not retune the other rooms.
    private static func contactShadowSettings(from settings: LightingSettings)
        -> LightingSettings {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-no-bakkerij-ao") {
            return settings
        }
        #endif
        let bakeryShadows = LightingSettings()
        bakeryShadows.contactShadowsEnabled = settings.contactShadowsEnabled
        bakeryShadows.contactShadowOpacity = sqrt(settings.contactShadowOpacity)
        bakeryShadows.contactShadowScale = settings.contactShadowScale
        return bakeryShadows
    }

    func leave() {
        cancelEverything()
        save()
    }

    // MARK: - Idle and misses

    private func startIdleWatch() {
        ticker.cancel(idleJob)
        idleTime = 0
        nudgeStage = 0
        idleJob = ticker.add { [weak self] dt in
            guard let self else { return false }
            self.idleTime += dt
            if self.nudgeStage == 0, self.idleTime > 45, self.state.step != .klaar {
                self.nudgeStage = 1
                self.voice.say(self.alternateNudge ? Line.stil : BakkerijLine.wacht,
                               priority: .low)
                self.alternateNudge.toggle()
            }
            if self.idleTime > 105 { self.idleTime = 0; self.nudgeStage = 0 }
            return true
        }
    }

    private func resetIdle() {
        idleTime = 0
        nudgeStage = 0
    }

    /// **She dragged the thing the step is about and it did not land.** Narrow on
    /// purpose (`ROOMS.md` §8): twice something kind, and the third time the
    /// step's own line at full priority with the lit prop squashing.
    private func noteMiss() {
        misses += 1
        guard misses >= 3 else { return }
        misses = 0
        voice.sayInstead(stepLine)
        if let prop = litProp { ticker.squash(prop, amount: 0.14, duration: 0.45) }
    }

    /// Whatever the current step is pointing at, for the third miss.
    private var litProp: Entity? {
        switch state.step {
        case .opendoen: return blind?.knob
        case .binnenlaten: return shopDoor?.hinge
        case .bestellen: return card ?? hook
        case .ophangen: return photo
        default: return nil
        }
    }

    private func noteHit() { misses = 0 }

    private var stepLine: String {
        switch state.step {
        case .opendoen: return BakkerijLine.opendoen
        case .kiezen: return BakkerijLine.kiezen
        case .binnenlaten: return BakkerijLine.bel
        case .bestellen: return BakkerijLine.bestellen
        case .ophangen: return BakkerijLine.ophangen
        case .klaar: return BakkerijLine.klaar
        }
    }

    // MARK: - Helpers

    /// The horizontal direction that reads as **up the screen**. The camera never
    /// moves and stands at 45° to both floor axes, so this is the same diagonal
    /// `FeestLayout.back` uses, and for the same reason.
    private static let up = SIMD2<Float>(-0.7071, -0.7071)
    /// How far along that direction a full pull is. Small, because a 4-year-old's
    /// drag is short — and generous, because the step completes itself past two
    /// thirds. **Both are judgement rather than measurement until Nina has been
    /// watched using them** (`POC.md`'s protocol).
    private static let cordDragSpan: Float = 0.070
    private static let doorDragSpan: Float = 0.060

    private func surfaceY(at point: SIMD3<Float>) -> Float {
        BakkerijLayout.surfaces.y(at: point)
    }

    private func advance(to step: BakkerijStep, after delay: Float = 0) {
        guard delay > 0 else {
            state.step = step
            applyStep(animated: true)
            return
        }
        jobs.append(ticker.after(delay) { [weak self] in
            guard let self else { return }
            self.state.step = step
            self.applyStep(animated: true)
        })
    }

    /// Recolour a built subtree — used when a chosen ghost "colours in a little".
    private func tint(_ entity: Entity, to colour: UIColorLike) {
        if let model = entity as? ModelEntity, model.model != nil {
            model.model?.materials = [Palette.material(colour)]
        }
        for child in entity.children { tint(child, to: colour) }
    }

    // MARK: - Housekeeping

    /// **Every job id, the halo, the wave, and both characters.** `ROOMS.md` §11:
    /// a `Ticker` job a torn-down room still holds animates a detached entity
    /// forever, and nothing on screen says so.
    private func cancelEverything() {
        for job in jobs { ticker.cancel(job) }
        jobs.removeAll()
        ticker.cancel(idleJob)
        idleJob = nil
        ticker.cancel(shimmerJob)
        shimmerJob = nil
        ticker.cancel(radioJob)
        radioJob = nil
        radioPlaying = false
        Halo.remove(halo, ticker: ticker)
        halo = nil
        frameGlow = nil
        guest?.stop()
        guest = nil
        baker?.stop()
        baker = nil
        card = nil
        photo = nil
        dragFrom = nil
        touch.onEmptyTap = nil
        touch.onAnyTouch = nil
        touch.onMoved = nil
    }

    // MARK: - Debug

    var debugTitle: String { RoomID.bakkerij.title }

    var debugRows: [String] {
        [
            "Mode: \(mode == .ronde ? "ronde" : "bezoek")  ·  Stap: \(state.step.rawValue)",
            "Vriend: \(state.friend?.dutchName ?? "nog niemand")",
            "Muur: \(state.wall.filledCount)/\(Friend.allCases.count)"
                + (state.wall.goldIsEarned ? "  ·  gouden lijst verdiend" : ""),
            "Winkel open: \(BakkerijRoom.shopOpenedThisSitting ? "ja" : "nee")",
        ]
    }

    var debugActions: [(String, @MainActor () -> Void)] {
        [
            ("Terug met taart", { [weak self] in self?.debugReturnWithCake() }),
            ("Vul 11 lijstjes", { [weak self] in self?.debugFillWall() }),
            ("Muur leegmaken", { [weak self] in self?.debugClearWall() }),
        ]
    }

    /// Jump to the return leg with a decorated cake, so `ophangen` and the
    /// curtain can be looked at without playing four rooms first.
    private func debugReturnWithCake() {
        let friend = state.wall.waiting.randomElement() ?? .pip
        let result = FeestResult(friend: friend, cake: CakeSpec.dealt(), matched: true)
        state = .returning(wall: state.wall, result: result)
        build(flat: flat)
    }

    private func debugFillWall() {
        for friend in Friend.allCases where !state.wall.isFilled(friend) {
            state.wall.fill(friend, with: CakeSpec.dealt(), matched: true, when: Date())
        }
        persistWall()
        state = .outbound(wall: state.wall, shopOpen: BakkerijRoom.shopOpenedThisSitting)
        build(flat: flat)
    }

    private func debugClearWall() {
        state.wall = GameStore.reset()
        BakkerijRoom.shopOpenedThisSitting = false
        state = .outbound(wall: state.wall, shopOpen: false)
        build(flat: flat)
    }
}

// MARK: - Line ids

/// **The hub's voice, spelled once.** `audio/script-bakkerij.json`.
///
/// `VoiceBank` loads every bundled `script-*.json` and merges by id, so this room
/// needed no Swift plumbing beyond these constants. A typo in a line id is a
/// silent tap, which is why they are written down once here and derived off enum
/// cases wherever a friend is involved.
enum BakkerijLine {
    static let hallo = "nina.bakkerij.hallo"
    static let halloOpen = "nina.bakkerij.halloOpen"
    static let halloVrij = "nina.bakkerij.halloVrij"

    static let opendoen = "nina.bakkerij.opendoen"
    static let openGedaan = "nina.bakkerij.openGedaan"
    static let kiezen = "nina.bakkerij.kiezen"
    static let gekozen = "nina.bakkerij.gekozen"
    static let bel = "nina.bakkerij.bel"
    static let binnen = "nina.bakkerij.binnen"
    static let bestellen = "nina.bakkerij.bestellen"
    static let naarTuin = "nina.bakkerij.naarTuin"

    static let ophangen = "nina.bakkerij.ophangen"
    static let klaar = "nina.bakkerij.klaar"
    static let alleLijstjes = "nina.bakkerij.alleLijstjes"

    static let wacht = "nina.bakkerij.wacht"
    static let opnieuw = "nina.bakkerij.opnieuw"

    /// **Nina repeating today's wish in her own words** — `GAMEPLAY.md` §4, and
    /// also what the persistent wish card replays when it is tapped. Derived off
    /// the enum case, the `Friend.thanksLineID` rule.
    static func wish(for friend: Friend) -> String {
        "nina.bakkerij.wens.\(friend.rawValue)"
    }

    // The naming layer. §3: *"drag to play, tap to find out what a thing is
    // called."*
    static let ditRolluik = "nina.dit.rolluik"
    static let ditLijstje = "nina.dit.lijstje"
    static let ditBel = "nina.dit.bel"
    static let ditPoes = "nina.dit.poes"
    static let ditRadio = "nina.dit.radio"
    static let ditRaam = "nina.dit.raam"
    static let ditTekening = "nina.dit.tekening"
    static let ditHaak = "nina.dit.haak"
    static let ditWinkeldeur = "nina.dit.winkeldeur"
    static let ditUithangbord = "nina.dit.uithangbord"
}
