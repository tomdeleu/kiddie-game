import Foundation
import RealityKit
import simd

/// De Keuken — the first room, whole.
///
/// The required action is `GAMEPLAY.md` §6.3: roll the base, three ingredients
/// into the bowl, stir, pour, bake. Around it sit six toys that gate nothing,
/// Nina working behind the table, and an oven with a face. The shape every room
/// shares is one required action, four to six toys, and a door that always
/// works.
///
/// Two things here are not in that section as written, and both are recorded
/// there as later changes: the rolling pin is a **required step** rather than a
/// toy, and the three ingredients come from **three places in a fixed order**
/// rather than from one basket. The halo is what makes an order free of
/// puzzles — the one she needs glows, and nothing else does.
///
/// Three rules from `GAMEPLAY.md` §7 are load-bearing here and are worth
/// naming, because each one is a place where the obvious implementation is the
/// wrong one:
///
/// - **Nothing is driven by a clock.** Stirring advances on her hand, not on a
///   timer. Baking is the single exception and it is four seconds of Otto being
///   pleased, not a wait.
/// - **She cannot fail.** There is no rejected drop: a miss floats home and
///   Nina says something kind. Nothing is ever disabled, greyed, or refused.
/// - **Every tap does something.** Including a tap on nothing, which sparkles.
@MainActor
final class KitchenRoom: GameRoom {

    let root = Entity()

    private let ticker: Ticker
    private let touch: TouchRouter
    private let voice: VoiceBank
    private let sound: SoundKit

    private(set) var state: RoundState
    private var settings: LightingSettings
    private var flat = true

    // Props with state. Built in `build`, cleared on a rebuild.
    private var oven: KitchenProps.Oven?
    private var bowl: ModelEntity?
    private var bowlBatter: ModelEntity?
    private var spoon: Entity?
    private var tin: KitchenProps.Tin?
    private var basket: ModelEntity?
    private var tokens: [(ingredient: Ingredient, entity: Entity, home: SIMD3<Float>)] = []
    private var cake: Entity?
    private var shelfCakes: [Entity] = []
    private var sink: KitchenProps.Sink?
    private var scaleProp: KitchenProps.Scale?
    private var flourSack: Entity?
    private var crate: Entity?
    private var rollingPin: Entity?
    private var doorway: KitchenProps.Doorway?
    /// Nina's picture, framed, on the back wall over Otto.
    private var portrait: Entity?
    /// The door's open-hold-shut turn, held so a second tap restarts it.
    private var doorSwing: Int?
    /// **Where the leaf sits when nothing is swinging it** — shut while the
    /// kitchen is unfinished, ajar once it is.
    private var doorRest: Float = 0
    /// An empty marker on the floor at the threshold, so the door's halo has a
    /// place to stand that is not inside the wall. See `Layout.doorHaloSpot`.
    private var doorMarker: Entity?
    /// And one at the middle of the leaf, so the whole door answers a tap
    /// rather than only its bottom half — see `buildDoorway`.
    private var doorTouchSpot: Entity?
    /// **The second halo, and the second time the game lights two things at
    /// once.**
    ///
    /// Every step lights exactly one prop, because a cue that names two things
    /// names neither. The first exception was the cake going up onto the plank,
    /// where the step is a journey and a journey has two ends. This is the
    /// second, and it is a different shape: once three cakes are up, the room
    /// genuinely has **two right answers** — carry on baking, or go through the
    /// door — and a cue that lit only one of them would be a lie. So the step
    /// keeps its own halo and the door gets one of its own, lit for as long as
    /// the room is finished.
    private var doorHalo: Halo.Handle?
    private var cakePlank: ModelEntity?
    private var flourPatches: [Entity] = []
    private var baker: BakerCharacter?
    private var dough: ModelEntity?
    private var tinBase: ModelEntity?
    private var ingredientPot: ModelEntity?
    /// The glow on whatever she needs next: the job driving it, the prop it is
    /// on, and that prop's own materials so they can be put back exactly.
    /// The lit ring on the surface, and the job driving it. One handle instead
    /// of a job plus an entity plus a snapshot of its materials: the halo does
    /// not touch the prop any more, so there is nothing to put back.
    private var halo: Halo.Handle?

    /// **Carrying, which is now `Engine/CarryController.swift`.**
    ///
    /// It used to be eight stored properties and seven methods sitting in this
    /// file, and every word of it was about the camera rather than about a
    /// kitchen. The garden drags a seed into a hole and sweeps a can across a
    /// bed, which is the same model — and `ROOMS.md` §6 says inherit it rather
    /// than rediscover it, so it moved out. The wrappers below keep every call
    /// site in this file spelled exactly as it was.
    private var carrier: CarryController!

    /// **Three tries and the instruction comes back.** `missCount` only counts
    /// attempts at the step she is actually on, and resets whenever the step
    /// changes or something works — so it measures "she is trying this and it
    /// is not taking", not "she has been playing with the rolling pin".
    private var missCount = 0
    private var missStep: KitchenStep?

    private var sinkJobs: [Int] = []
    private var plankGlowJob: Int?

    private var stirLastAngle: Float?
    private var stirLastPoint: SIMD3<Float>?
    private var stirTickAccumulator: Float = 0
    private var saidGoodStirring = false
    private var idleJob: Int?
    private var eyeLifeJob: Int?
    /// The running blink, one job per eyeball. Held so the next blink can
    /// cancel it rather than run alongside it — see `blink`.
    private var blinkJobs: [Int] = []
    private var bakeJobs: [Int] = []
    /// **Otto is already baking.** `state.step` stays `.bakken` for the whole
    /// four seconds he performs, so without this a second tap on him started a
    /// second bake — five taps, five overlapping breathe jobs, five puff
    /// schedules, and five cakes arriving on top of each other. He still
    /// answers every tap while it runs; he just chats instead of starting again.
    private var baking = false
    private var lastSavedStir: Float = 0
    private var lastBatterMix: Float = -1
    /// What the batter is painted right now, so a new ingredient can bleed from
    /// it rather than cut to its own colour.
    private var lastBatterColour: UIColorLike?
    private var rollTickAccumulator: Float = 0
    private var rollLastPoint: SIMD3<Float>?

    // The idle nudge.
    private var idleTime: Float = 0
    private var hintJob: Int?
    private var hintEntity: Entity?
    private var hintScale = SIMD3<Float>(repeating: 1)
    private var nudgeStage = 0
    private var alternateNudge = false

    /// Drop generosity. `CONCEPT.md` §5: drop the egg *near* the bowl and it
    /// goes in the bowl.
    ///
    /// Scaled 1.08 with the camera, like the touch radii — this is a tolerance
    /// she aims by eye, so what matters is how big it is on screen. It is now
    /// about a quarter of the longer table rather than a third of the old one,
    /// and it is still comfortably the largest thing on the top: the nearest
    /// two home positions to the bowl are the spoon at 70 mm and the cake spot
    /// at 71 mm, so nothing sits inside it by accident.
    private let snapRadius: Float = 0.067

    init(ticker: Ticker, touch: TouchRouter, voice: VoiceBank,
         sound: SoundKit, settings: LightingSettings) {
        self.ticker = ticker
        self.touch = touch
        self.voice = voice
        self.sound = sound
        self.settings = settings
        self.state = RoundStore.load()
        root.name = "Kitchen"

        let carrier = CarryController(ticker: ticker, sound: sound,
                                      surfaces: Layout.surfaces, settings: settings)
        // Everything with an inside, read fresh every frame of a drag — see
        // `CarryController.containers` for why this is a closure.
        carrier.containers = { [weak self] in
            guard let self else { return [] }
            var found: [CarryController.Container] = []
            if let bowl = self.bowl {
                found.append((bowl, KitchenProps.bowlHeight, KitchenProps.bowlTopRadius))
            }
            if let tin = self.tin?.root, tin.isEnabled { found.append((tin, 0.013, 0.024)) }
            if let basket = self.basket { found.append((basket, 0.014, 0.024)) }
            if let crate = self.crate { found.append((crate, 0.022, 0.027)) }
            return found
        }
        // **The cake plank, the room's one exception to the surface model.** It
        // hangs above the back of the counter, so as a real surface it would
        // shadow the counter and fling the sink shelf-high. Only the cake, and
        // only on the round's last step, can ever reach it.
        carrier.pointedExtra = { [weak self] anchor, entity in
            guard let self, entity === self.cake else { return nil }
            let plankHeight = Layout.cakePlankY + 0.004
            guard Layout.nearPlank(Surfaces.pointOnRay(through: anchor,
                                                       atHeight: plankHeight))
            else { return nil }
            return plankHeight
        }
        // The same exception asked position-based, which is what the halo needs
        // so its ring climbs onto the plank with the cake.
        carrier.restingExtra = { [weak self] point, entity in
            guard let self, entity === self.cake, Layout.nearPlank(point) else { return nil }
            return Layout.cakePlankY + 0.004
        }
        carrier.onPickUp = { [weak self] _ in self?.stopHint() }
        carrier.onMiss = { [weak self] in self?.noteMiss() }
        self.carrier = carrier
    }

    // MARK: - Building

    /// Rebuild everything from `state`. Called on launch, when the debug panel
    /// flips flat shading, and at the start of every new round — which is only
    /// possible because the room is a pure function of the round.
    func build(flat: Bool) {
        self.flat = flat
        cancelEverything()
        root.children.removeAll()
        touch.removeAll()
        tokens.removeAll()
        shelfCakes.removeAll()
        flourPatches.removeAll()
        cake = nil
        bowlBatter = nil

        root.addChild(RoomBuilder.build(flat: flat))

        buildOven()
        buildBaker()
        buildTableProps()
        buildToys()
        buildDoorway()
        buildShelfCakes()

        registerTargets()
        applyStep(animated: false)
        startIdleWatch()
    }

    private func buildBaker() {
        baker?.stop()
        let nina = BakerCharacter(ticker: ticker, flat: flat)
        root.addChild(nina.root)
        baker = nina
    }

    private func buildOven() {
        let node = KitchenProps.oven(flat: flat)
        oven = node
        root.addChild(node.root)
        startEyeLife()
    }

    private func buildTableProps() {
        let basketNode = KitchenProps.basket(flat: flat)
        basketNode.position = Layout.basketHome
        root.addChild(basketNode)
        basket = basketNode

        let pot = KitchenProps.ingredientPot(flat: flat)
        pot.position = SIMD3<Float>(Layout.Source.aanrecht.spot.x,
                                    Layout.counterTopY,
                                    Layout.Source.aanrecht.spot.z)
        root.addChild(pot)
        ingredientPot = pot

        // **One ingredient per source.** Token *i* stands where source *i* is —
        // top shelf, lower shelf, counter, basket, crate — and the ones she has
        // already used are simply not built. `usedSlots` rather than a count,
        // because she may take them in any order she likes.
        let used = state.usedSlots
        for (i, ingredient) in state.basket.enumerated() {
            guard let source = Layout.Source(rawValue: i) else { continue }
            let token = KitchenProps.token(ingredient, flat: flat)
            let home = source.spot
            token.position = home
            token.name = "Token\(i)_\(ingredient.rawValue)"
            token.isEnabled = !used.contains(i)
            root.addChild(token)
            tokens.append((ingredient, token, home))
            // Only the ones standing on something the shadow can land on. The
            // two on the wall shelves have a plank 8 mm thick under them and
            // nothing else, so a disc there lands on the floor far below.
            if source == .mandje || source == .krat || source == .aanrecht {
                ContactShadows.attach(to: token, radius: 0.012, settings: settings)
            }
        }

        // The dough she rolls out before any of that.
        let ball = KitchenProps.doughBall(flat: flat)
        // Straight on the table: the blob's origin is its base — see
        // `KitchenProps.doughBall` — where the old sphere's was its centre and
        // had to be lifted by half its height.
        ball.position = Layout.doughSpot
        root.addChild(ball)
        dough = ball
        ContactShadows.attach(to: ball, radius: 0.016, settings: settings)

        let bowlNode = KitchenProps.mixingBowl(flat: flat)
        bowlNode.position = Layout.bowlHome
        root.addChild(bowlNode)
        bowl = bowlNode
        ContactShadows.attach(to: bowlNode, radius: 0.030, settings: settings)
        refreshBowlBatter(animated: false)

        let spoonNode = KitchenProps.spoon(flat: flat)
        spoonNode.position = Layout.spoonHome + [0, 0.006, 0]
        // Resting on the table it lies over; standing in the bowl it is upright.
        spoonNode.orientation = simd_quatf(angle: .pi / 2.2, axis: [1, 0, 0])
        root.addChild(spoonNode)
        spoon = spoonNode

        let tinNode = KitchenProps.tin(flat: flat)
        tinNode.root.position = Layout.tinHome
        root.addChild(tinNode.root)
        tin = tinNode
        ContactShadows.attach(to: tinNode.root, radius: 0.022, settings: settings)

        let pin = KitchenProps.rollingPin(flat: flat)
        pin.position = Layout.rollingPinHome + [0, 0.008, 0]
        root.addChild(pin)
        rollingPin = pin
    }

    private func buildToys() {
        let sinkNode = KitchenProps.sink(flat: flat)
        sinkNode.root.position = Layout.sinkSpot
        root.addChild(sinkNode.root)
        sink = sinkNode

        let scaleNode = KitchenProps.scale(flat: flat)
        scaleNode.root.position = Layout.scaleSpot
        root.addChild(scaleNode.root)
        scaleProp = scaleNode

        // On the floor, in the near foreground. See `Layout.flourSpot`.
        let sack = KitchenProps.flourSack(flat: flat)
        sack.position = Layout.flourSpot
        root.addChild(sack)
        flourSack = sack
        ContactShadows.attach(to: sack, radius: 0.024, settings: settings)
        ContactShadows.update(for: sack, surfaceY: Layout.floorY, settings: settings)

        let box = KitchenProps.crate(flat: flat)
        box.position = Layout.crateSpot
        root.addChild(box)
        crate = box
        // 30 mm, not 26: the modelled crate is a square box 46 mm across the
        // flats and 65 mm across the corners, where the tub it replaced was 37
        // and 52. The disc has to reach the corner posts or the crate looks
        // like it is standing on a coaster.
        ContactShadows.attach(to: box, radius: 0.030, settings: settings)
        ContactShadows.update(for: box, surfaceY: Layout.floorY, settings: settings)

        cakePlank = root.findEntity(named: "CakePlankBoard") as? ModelEntity

        // The picture over Otto. Built here rather than in `RoomBuilder` with
        // the rest of the wall furniture because it answers a tap, and this
        // class owns everything that does.
        let frame = KitchenProps.portrait(flat: flat)
        root.addChild(frame)
        portrait = frame
    }

    private func buildDoorway() {
        let node = KitchenProps.doorway(flat: flat)
        root.addChild(node.root)
        doorway = node

        // Nothing to look at — it exists so the door's ring of light has a
        // position on the floor to follow, out where the ring is not half
        // buried in the wall. An empty entity rather than a hidden model,
        // because `Halo` only ever reads its position.
        let marker = Entity()
        marker.name = "DoorHaloSpot"
        marker.position = Layout.doorHaloSpot
        root.addChild(marker)
        doorMarker = marker

        // **And a second marker, at the middle of the leaf, for the touch.**
        //
        // Targets are spheres centred on an entity's own origin, and the
        // doorway's origin is on the *floor* — so a 54 mm sphere there covered
        // the bottom of the door and nothing else. Tapping the middle of the
        // leaf sat about 50 mm off that centre and the top of it about 100 mm,
        // which means the top half of the door has never been tappable. That
        // was survivable while the door was a toy. It is not survivable now that
        // tapping it is how the room ends, and a 4-year-old aims at the middle
        // of a door.
        let hit = Entity()
        hit.name = "DoorTouchSpot"
        hit.position = SIMD3<Float>(Layout.doorwayCentre.x + 0.010,
                                    Layout.floorY + Layout.doorOpening.y / 2,
                                    Layout.doorwayCentre.z)
        root.addChild(hit)
        doorTouchSpot = hit
    }

    /// **The kitchen is finished.** Three cakes on the plank, and the door is
    /// the way on — see `Layout.cakesToFinish`.
    ///
    /// A floor, not a quota: a fresh round still starts, and she is free to
    /// bake a fourth instead. It stays true once true, so coming back to a
    /// finished kitchen finds the door still open and still lit.
    var roomComplete: Bool { state.shelf.count >= Layout.cakesToFinish }

    /// **Put the door in the state the plank has earned.**
    ///
    /// Three things at once, and they are three ways of saying the same
    /// sentence to somebody who cannot read: the leaf comes off the latch, the
    /// light behind it starts to glow so the slice of it showing through is
    /// worth seeing, and a ring lands on the floor at the threshold. None of
    /// them is an arrow and none of them is a word.
    ///
    /// Called from `applyStep`, so it is correct on a rebuild, on every step
    /// change, and on coming back to a saved round that was already finished.
    private func refreshDoorInvitation() {
        guard let doorway else { return }
        let done = roomComplete

        doorRest = done ? Layout.doorAjarAngle : 0
        // Only when nothing is swinging it — mid-tap the tween owns the hinge,
        // and it returns to `doorRest` by itself.
        if doorSwing == nil {
            doorway.hinge.orientation = simd_quatf(angle: doorRest, axis: [0, 1, 0])
        }

        // The next room, seen through the gap. Lit rather than merely painted:
        // it is a butter-yellow plate deep inside the frame with a leaf across
        // most of it, and unlit it reads as the inside of a cupboard.
        doorway.glow.model?.materials = [
            done ? Palette.glowMaterial(Palette.butterYellow, intensity: 1.8)
                 : Palette.material(Palette.butterYellow)
        ]

        guard done else {
            Halo.remove(doorHalo, ticker: ticker)
            doorHalo = nil
            return
        }
        guard doorHalo == nil, let marker = doorMarker else { return }
        doorHalo = Halo.attach(to: marker, radius: Layout.doorHaloRadius, ticker: ticker,
                               surfaceY: { _ in Layout.floorY })
    }

    /// Her finished cakes, standing on the plank.
    private func buildShelfCakes() {
        for (i, spec) in state.shelf.enumerated() {
            let cakeNode = KitchenProps.cake(spec, flat: flat)
            cakeNode.name = "ShelfCake\(i)"
            cakeNode.position = shelfSlot(i)
            cakeNode.scale = SIMD3<Float>(repeating: 0.62)
            root.addChild(cakeNode)
            shelfCakes.append(cakeNode)
        }
    }

    private func shelfSlot(_ index: Int) -> SIMD3<Float> {
        let spacing = Layout.cakePlankLength / Float(Layout.cakeShelfCapacity)
        let start = Layout.cakePlankCentre.x - Layout.cakePlankLength / 2 + spacing / 2
        return SIMD3<Float>(start + spacing * Float(index),
                            Layout.cakePlankY + 0.004,
                            Layout.cakePlankCentre.y)
    }

    // MARK: - Targets

    /// **Every radius below is 1.08× what it was**, and that number is
    /// `CameraRig.eye`'s pull-back, not a judgement about any one prop.
    ///
    /// These are world-space spheres, but what they have to satisfy is a rule
    /// about the screen — `CONCEPT.md` §5's "minimum ~120 pt hit areas". When
    /// the camera stepped back 8% to fit the wider room, every one of them got
    /// 8% smaller under her finger for free. Scaling them by the same factor is
    /// what keeps that from being a silent regression: the room is bigger, the
    /// props are the same size in metres, and nothing on screen is any harder
    /// to hit than it was. **If the camera moves again, these move with it.**
    private func registerTargets() {
        for (index, token) in tokens.enumerated() {
            let source = Layout.Source(rawValue: index) ?? .mandje
            touch.register("token\(index)", entity: token.entity,
                           radius: 0.032, planeY: source.planeY) { target in
                target.tracksEntity = true
                target.onDragBegan = { [weak self] world in
                    self?.pickUp(token.entity, at: world)
                }
                target.onDragMoved = { [weak self] world in self?.carry(to: world) }
                target.onDragEnded = { [weak self] world in
                    self?.dropToken(index: index, at: world)
                }
                target.onTap = { [weak self] in self?.nudgeToken(index) }
            }
        }

        touch.register("bowl", entity: bowl, radius: 0.048,
                       planeY: Layout.tableTopY + 0.020) { target in
            target.tracksEntity = true
            target.planeOffset = 0.020
            target.onDragBegan = { [weak self] world in self?.bowlTouchBegan(world) }
            target.onDragMoved = { [weak self] world in self?.bowlTouchMoved(world) }
            target.onDragEnded = { [weak self] world in self?.bowlTouchEnded(world) }
            target.onTap = { [weak self] in self?.sayName(Line.ditKom, wobbling: self?.bowl) }
        }

        // **The spoon is a target now, and it is switched off while she stirs.**
        // During `roeren` it stands in the middle of the bowl, so leaving it
        // live would put a 26 mm sphere in the one place her finger has to land
        // to make batter — and `TouchRouter` picks the *nearest* centre, not the
        // biggest target, so it would win about half the time.
        touch.register("spoon", entity: spoon, radius: 0.026,
                       planeY: Layout.tableTopY) { target in
            target.tracksEntity = true
            // Draggable like every other loose prop, and for the reason
            // `refreshInteractivity` gives for not locking things: a spoon she
            // can see and cannot pick up is a locked door with a nice sound on
            // it. The one thing that still owns its position is the stirring
            // step, which stands it in the bowl and puts it back after — that is
            // the action, not the room tidying up after her.
            target.onDragBegan = { [weak self] world in
                guard let self, let spoon = self.spoon else { return }
                self.pickUp(spoon, at: world)
            }
            target.onDragMoved = { [weak self] world in self?.carry(to: world) }
            target.onDragEnded = { [weak self] _ in
                guard let self, let spoon = self.spoon else { return }
                self.settle(spoon, missed: false)
            }
            target.onTap = { [weak self] in self?.sayName(Line.ditLepel, wobbling: self?.spoon) }
        }

        touch.register("tin", entity: tin?.root, radius: 0.037,
                       planeY: Layout.tableTopY) { target in
            target.tracksEntity = true
            target.onDragBegan = { [weak self] world in
                guard let self, let tin = self.tin else { return }
                self.pickUp(tin.root, at: world)
            }
            target.onDragMoved = { [weak self] world in self?.carry(to: world) }
            target.onDragEnded = { [weak self] world in self?.dropTin(at: world) }
            target.onTap = { [weak self] in self?.sayName(Line.ditVorm, wobbling: self?.tin?.root) }
        }

        touch.register("otto", entity: oven?.root, radius: 0.076,
                       planeY: Layout.floorY) { target in
            target.onTap = { [weak self] in self?.tapOtto() }
        }

        // Centred on the middle of the leaf rather than on the doorway's own
        // origin, which is on the floor — see `buildDoorway`. 56 mm reaches the
        // top of the door and stops 3 mm short of the basket's token, which is
        // the nearest other target at 85 mm.
        touch.register("doorway", entity: doorTouchSpot, radius: 0.056,
                       planeY: Layout.floorY) { target in
            target.onTap = { [weak self] in self?.tapDoorway() }
        }

        touch.register("cake", entity: nil, radius: 0.043,
                       planeY: Layout.tableTopY) { target in
            target.tracksEntity = true
            target.onTap = { [weak self] in self?.tapCake() }
            target.onDragBegan = { [weak self] world in
                guard let self, let cake = self.cake else { return }
                self.pickUp(cake, at: world)
            }
            target.onDragMoved = { [weak self] world in self?.carry(to: world) }
            target.onDragEnded = { [weak self] world in self?.dropCake(at: world) }
        }

        registerToyTargets()

        touch.onEmptyTap = { [weak self] world in self?.tapNothing(at: world) }
        touch.onAnyTouch = { [weak self] in self?.resetIdle() }
    }

    private func registerToyTargets() {
        // The sack is on the floor now, and big — a 96 mm target on a prop she
        // has to reach down for.
        touch.register("flour", entity: flourSack, radius: 0.048,
                       planeY: Layout.floorY) { target in
            target.onTap = { [weak self] in self?.tapFlour() }
        }
        touch.register("sink", entity: sink?.root, radius: 0.032,
                       planeY: Layout.counterTopY) { target in
            target.onTap = { [weak self] in self?.tapSink() }
        }
        touch.register("scale", entity: scaleProp?.root, radius: 0.032,
                       planeY: Layout.counterTopY) { target in
            target.onTap = { [weak self] in self?.tapScale() }
        }
        touch.register("crate", entity: crate, radius: 0.037,
                       planeY: Layout.floorY) { target in
            target.onTap = { [weak self] in
                guard let self, let crate = self.crate else { return }
                self.ticker.squash(crate, amount: 0.12)
                self.sound.playVaried(.thud, volume: 0.5)
                self.voice.say(Line.ditKist, priority: .low)
            }
        }
        // **The basket, live only once its ingredient has gone.** The `mandje`
        // token stands 12 mm above the basket's own centre, which from a fixed
        // camera is the same point on screen — two targets a millimetre apart in
        // ray distance, and which one a tap got would be a coin toss. So the
        // basket is simply not there while there is something in it: the tap
        // that matters is the one that picks the ingredient up.
        touch.register("basket", entity: basket, radius: 0.026,
                       planeY: Layout.tableTopY) { target in
            target.onTap = { [weak self] in self?.sayName(Line.ditMandje, wobbling: self?.basket) }
        }
        touch.register("cakePlank", entity: cakePlank, radius: 0.038,
                       planeY: Layout.cakePlankY) { target in
            // No wobble: it is screwed to the wall, and the plank is the one
            // prop in the room where a squash would read as the shelf coming
            // loose with four cakes on it.
            target.onTap = { [weak self] in self?.sayName(Line.ditTaartenplank, wobbling: nil) }
        }
        // 50 mm rather than 36: the frame is now sized from the photograph and
        // can be up to 88 mm across, so a target measured against the old fixed
        // frame would have left its corners dead. Nothing is near it — Otto,
        // the closest other target, is 201 mm away.
        touch.register("portrait", entity: portrait, radius: 0.050,
                       planeY: Layout.portraitCentre.y) { target in
            target.onTap = { [weak self] in self?.tapPortrait() }
        }
        touch.register("rollingPin", entity: rollingPin, radius: 0.035,
                       planeY: Layout.tableTopY) { target in
            target.tracksEntity = true
            target.onDragBegan = { [weak self] world in self?.rollBegan(at: world) }
            target.onDragMoved = { [weak self] world in self?.roll(to: world) }
            target.onDragEnded = { [weak self] _ in
                guard let self, let pin = self.rollingPin else { return }
                self.rollLastPoint = nil
                // **It stays where she leaves it**, including on the floor.
                // The pin is the prop most likely to be carried off for its own
                // sake, and sending it home was the clearest case of the room
                // undoing what she had just done.
                self.settle(pin, missed: false)
            }
            target.onTap = { [weak self] in
                guard let self, let pin = self.rollingPin else { return }
                self.ticker.wiggle(pin, angle: 0.10)
                self.sound.playVaried(.roll, volume: 0.5)
                self.voice.say(Line.ditDeegroller, priority: .low)
            }
        }
        // **The ball of dough, whose drags belong to the rolling pin.**
        //
        // It is the one prop with a target that does not drive itself, and that
        // is the point. It sits 44 mm from the pin's home, so a target of its
        // own would sometimes win the grab that was meant to start the rolling —
        // and a target that answers a tap but eats a drag would break the
        // round's first step. Forwarding the drag means a grab anywhere around
        // the dough picks up the pin, which is what she meant by it anyway, and
        // a *tap* on the dough gets to be a tap on the dough.
        touch.register("dough", entity: dough, radius: 0.024,
                       planeY: Layout.tableTopY) { target in
            target.onDragBegan = { [weak self] world in self?.rollBegan(at: world) }
            target.onDragMoved = { [weak self] world in self?.roll(to: world) }
            target.onDragEnded = { [weak self] _ in
                guard let self, let pin = self.rollingPin else { return }
                self.rollLastPoint = nil
                self.settle(pin, missed: false)
            }
            target.onTap = { [weak self] in self?.sayName(Line.ditDeeg, wobbling: self?.dough) }
        }
        // The six jars on the two wall shelves.
        for height in [150, 105] {
            for i in 0..<3 {
                let name = "Jar\(height)_\(i)"
                guard let jar = root.findEntity(named: name) else { continue }
                touch.register(name, entity: jar, radius: 0.024,
                               planeY: Float(height) / 1000) { target in
                    target.onTap = { [weak self] in self?.tapJar(jar) }
                }
            }
        }
    }

    /// **A tap said what the thing is.**
    ///
    /// The whole naming layer goes through here, so the two rules it has to obey
    /// are written once. `.low` priority is the important one: `VoiceBank` drops
    /// a low line outright while anyone is speaking, so a tap can never talk
    /// over the step instruction it would be explaining, and a burst of taps
    /// gets one name rather than a pile-up.
    ///
    /// The wobble is the other half. She is four, and the connection between
    /// "the thing I touched" and "the voice I hear" is made by the thing moving
    /// at the same moment; a name with nothing moving is a name about the room
    /// in general.
    private func sayName(_ lineID: String, wobbling entity: Entity?) {
        if let entity, entity.isEnabled { ticker.squash(entity, amount: 0.13) }
        sound.play(.stirTick, volume: 0.3, rate: 1.25)
        voice.say(lineID, priority: .low)
    }

    /// The picture on the back wall. It cannot wobble — it is screwed to the
    /// plaster — so the answer is a sparkle over it and Nina saying who it is.
    private func tapPortrait() {
        guard let portrait else { return }
        sound.play(.sparkle, volume: 0.5)
        Sparkles.burst(at: portrait.position + [0, 0.030, 0.010], in: root,
                       ticker: ticker, colour: Palette.lilacDeep,
                       count: 7, size: 0.0022, speed: 0.05, life: 0.8)
        voice.say(Line.ditPortret, priority: .low)
    }

    /// Which targets are live right now.
    ///
    /// Note what this does *not* do: it never disables a toy, and it never
    /// disables Otto or the door. Only the props belonging to a step she has
    /// already passed go quiet, and those are the ones that have nothing left
    /// to do.
    private func refreshInteractivity() {
        // **Everything that is in the room can be picked up.**
        //
        // This used to be the opposite: only the ingredient whose turn it was
        // could be dragged, the bowl only during stirring and pouring, the tin
        // only on the way to Otto. Out of turn a prop wobbled and refused to
        // travel, which is a locked door with a nice sound on it — and
        // `GAMEPLAY.md` §7 has no locked doors in it. She can now move any of
        // them anywhere at any time, and the halo carries the whole instruction
        // by itself, which is what it was always supposed to do.
        //
        // What is still disabled is only what is genuinely not there: an
        // ingredient already in the bowl, and the tin while it is inside Otto.
        let used = state.usedSlots
        for index in tokens.indices {
            touch.target(named: "token\(index)")?.enabled = !used.contains(index)
        }
        touch.target(named: "bowl")?.enabled = true
        touch.target(named: "tin")?.enabled = state.step != .bakken && state.step != .klaar
        touch.target(named: "cake")?.entity = cake
        touch.target(named: "cake")?.enabled = cake != nil
        // The two naming targets that have to stand aside for a real one — the
        // spoon sits inside the bowl during the stir, and the basket sits under
        // its own ingredient until she has taken it. Both are explained where
        // they are registered.
        touch.target(named: "spoon")?.enabled = state.step != .roeren
        touch.target(named: "basket")?.enabled = used.contains(Layout.Source.mandje.rawValue)
        refreshHalo()
    }

    /// Take the ring away.
    ///
    /// Called before lighting anything else, and directly by `bake()` — once
    /// she has tapped Otto the cue has done its job. Nothing needs restoring:
    /// the halo is a separate entity on the surface and never touched the
    /// prop's own materials.
    private func clearHalo() {
        Halo.remove(halo, ticker: ticker)
        halo = nil
    }

    /// Light up whatever she needs next, and nothing else.
    private func refreshHalo() {
        clearHalo()
        guard let target = haloTarget(), target.isEnabled else { return }
        halo = Halo.attach(to: target, radius: haloRadius(for: target), ticker: ticker,
                           surfaceY: { [weak self, weak target] point in
            guard let self, let target else { return Layout.surfaceY(at: point) }
            // Through `surfaceUnder`, so the ring climbs onto the plank with
            // the cake at the end of the round instead of staying on the table.
            return self.surfaceUnder(point, for: target)
        })
    }

    /// The one prop the current step is about.
    private func haloTarget() -> Entity? {
        switch state.step {
        case .uitrollen: return rollingPin
        case .vullen: return tokens.indices.contains(state.nextIndex)
            ? tokens[state.nextIndex].entity : nil
        case .roeren: return bowl
        case .gieten: return bowl
        case .inOven: return tin?.root
        case .bakken: return oven?.root
        // The cake, which she now carries up to the plank. The plank itself
        // pulses separately — `setPlankInviting` — because this is the one step
        // that is a journey rather than a poke, and a journey needs both ends
        // lit. Every other step lights exactly one thing.
        case .klaar: return cake
        }
    }

    /// Roughly how big the prop is — it sets how high and wide the sparkles
    /// lift off it, and nothing else.
    private func haloRadius(for entity: Entity) -> Float {
        if entity === rollingPin { return 0.026 }
        if entity === bowl { return 0.034 }
        if entity === tin?.root { return 0.024 }
        if entity === oven?.root { return 0.080 }
        if entity === doorway?.root { return 0.075 }   // taller since it is a door
        if entity === cake { return 0.030 }
        return 0.018
    }

    // MARK: - Step presentation

    private func applyStep(animated: Bool) {
        guard let oven, let spoon, let tin else { return }

        // The spoon: on the table until she needs it, standing in the bowl
        // while she stirs, back on the table once the batter is done.
        // Off the bowl's *live* position, not `Layout.bowlHome`: the bowl can be
        // carried anywhere now, and a spoon that stands where the bowl used to
        // be is a spoon standing in mid-air.
        let stirring = state.step == .roeren
        let spoonTarget = stirring
            ? (bowl?.position ?? Layout.bowlHome) + [0, 0.030, 0]
            : Layout.spoonHome + [0, 0.006, 0]
        let spoonTilt = stirring ? simd_quatf(angle: 0, axis: [0, 1, 0])
                                 : simd_quatf(angle: .pi / 2.2, axis: [1, 0, 0])
        if animated {
            ticker.move(spoon, to: spoonTarget, duration: 0.4)
            spoon.orientation = spoonTilt
        } else {
            spoon.position = spoonTarget
            spoon.orientation = spoonTilt
        }

        // The dough is only out while she is rolling it; after that it is the
        // base sitting in the tin.
        dough?.isEnabled = state.step == .uitrollen
        if let dough, state.step == .uitrollen { shapeDough(dough, roll: state.roll) }
        refreshTinBase()

        tin.batter.isEnabled = state.step == .inOven || state.step == .bakken
        tin.batter.model?.materials = [Palette.material(state.bowlSpec.batterColour)]
        tin.root.isEnabled = state.step != .bakken && state.step != .klaar
        if tin.root.isEnabled { tin.root.scale = SIMD3<Float>(repeating: 1) }
        // **It is not sent home on every step change any more.** It used to be,
        // and that was invisible while the tin could only be dragged during one
        // step; now that she can move it whenever she likes, resetting its
        // position on the next step change would be the room quietly tidying up
        // after her. `build` places it, and nothing else moves it but her.

        // Otto's door: open except while he is actually baking. The dark
        // mouth is most of his depth — shut, he flattens into a disc (owner's
        // note on the 2026-08-15 build). The shut door still gets its moment:
        // closing on the tin is what makes the bake an event.
        setDoor(open: state.step != .bakken, animated: animated, oven: oven)

        // The cake, if she came back to a finished round.
        if state.step == .klaar, cake == nil, let spec = state.cake {
            let node = KitchenProps.cake(spec, flat: flat)
            node.position = Layout.cakeSpot
            root.addChild(node)
            cake = node
            ContactShadows.attach(to: node, radius: 0.026, settings: settings)
            if spec.sparkles { startCakeSparkle(node) }
        }

        setPlankInviting(state.step == .klaar)
        refreshDoorInvitation()
        refreshBowlBatter(animated: false)
        refreshInteractivity()
        bakerAttends()
    }

    /// Nina leans towards whatever the step is about. It costs one call per
    /// step change and it is most of what makes her look like she is baking
    /// rather than standing near a table.
    private func bakerAttends() {
        guard let baker else { return }
        if let focus = haloTarget()?.position(relativeTo: nil) {
            baker.set(.busy(focus))
        } else {
            baker.set(.idle)
        }
    }

    /// The base in the tin: absent until she has rolled it, then always there.
    private func refreshTinBase() {
        let wanted = state.step != .uitrollen
        if wanted, tinBase == nil, let tin {
            let base = KitchenProps.doughBase(flat: flat)
            base.position = [0, 0.003, 0]
            tin.root.addChild(base)
            tinBase = base
        } else if !wanted {
            tinBase?.removeFromParent()
            tinBase = nil
        }
    }

    /// The dough, part way through being flattened. One call, so the shape is
    /// the same whether it is being rolled or restored from a save.
    private func shapeDough(_ dough: Entity, roll: Float) {
        let t = max(0, min(1, roll))
        dough.scale = SIMD3<Float>(1 + 0.9 * t, 1 - 0.72 * t, 1 + 0.9 * t)
        // No height to animate any more. The blob stands on its own base, so
        // squashing it down the Y axis keeps it on the table by construction —
        // where the old sphere, scaled about its centre, sank into the wood
        // unless its position was eased in the opposite direction at the same
        // time.
        dough.position = Layout.doughSpot
    }

    private func setDoor(open: Bool, animated: Bool, oven: KitchenProps.Oven) {
        // `Oven` is a struct, so the weak capture has to be the entity itself.
        let pivot = oven.doorPivot
        let angle: Float = open ? 1.45 : 0
        let rotation = simd_quatf(angle: angle, axis: [1, 0, 0])
        guard animated else {
            pivot.orientation = rotation
            return
        }
        let from = pivot.orientation
        ticker.tween(0.35, ease: Ease.out, step: { [weak pivot] t in
            pivot?.orientation = simd_slerp(from, rotation, t)
        })
        sound.play(.whoosh, volume: 0.5)
    }

    /// The batter in the bowl: how high it stands, and what colour it is.
    private func refreshBowlBatter(animated: Bool) {
        guard let bowl else { return }
        // Only while it is in the bowl. After she pours, `inBowl` is still the
        // recipe — it is what the cake is made of — but the bowl is empty.
        // `uitrollen` is in the list because nothing stops her dropping a berry
        // in before she has rolled the dough, and an ingredient that vanishes
        // on the way into the bowl is the one thing a drop must never do.
        let inTheBowl = state.step == .uitrollen || state.step == .vullen
            || state.step == .roeren || state.step == .gieten
        let count = inTheBowl ? state.inBowl.count : 0
        guard count > 0 else {
            bowlBatter?.removeFromParent()
            bowlBatter = nil
            lastBatterMix = -1
            lastBatterColour = nil
            return
        }

        // **The batter takes the colour, not a hint of it.**
        //
        // It used to be `0.35 + 0.65 × stir` — 35% of the way from cream towards
        // the ingredient's colour at the moment it went in, and the rest bought
        // by stirring. The intent was the batter "taking its colour as she goes"
        // (`GAMEPLAY.md` §6.3), and the effect was that dropping a toverbosbes
        // in turned cream into slightly-blue cream: an in-between hue that is
        // neither the thing she picked nor the thing that was there. It read as
        // nothing happening (owner, 2026-08-16: "sometimes it doesn't seem
        // like it").
        //
        // It now goes 82% of the way immediately and reaches the colour exactly
        // by the end of the stir. The first frame after the plop is the answer
        // to "what did that do", and it has to be legible from across the table
        // to somebody who is four; the remaining 18% is what stirring is still
        // visibly for.
        let mix = 0.82 + 0.18 * min(1, state.stir)
        let colour = Palette.mix(Palette.cream, state.bowlSpec.batterColour, mix)
        let level = 0.006 + 0.005 * Float(min(count, 3))

        var fresh = false
        if bowlBatter == nil {
            let disc = KitchenProps.batter(colour: colour, radius: 0.026, flat: flat)
            bowl.addChild(disc)
            bowlBatter = disc
            fresh = true
        }
        guard let disc = bowlBatter else { return }
        if animated && !fresh, let was = lastBatterColour {
            // An ingredient just went in. Bleed the old colour into the new one
            // over about a third of a second rather than cutting: a colour that
            // *arrives* is a colour she watches happen, and a cut is something
            // she can miss by blinking.
            lastBatterMix = mix
            lastBatterColour = colour
            ticker.tween(0.35, ease: Ease.out, step: { [weak disc] t in
                disc?.model?.materials = [Palette.material(Palette.mix(was, colour, t))]
            }, done: { [weak disc] in
                disc?.model?.materials = [Palette.material(colour)]
            })
        } else if fresh || abs(mix - lastBatterMix) > 0.02 {
            // Stirring calls this on every touch event. Rebuilding a material 60
            // times a second to move a colour by nothing is the kind of waste
            // that only shows up as a warm iPad, so it steps rather than slides.
            lastBatterMix = mix
            lastBatterColour = colour
            disc.model?.materials = [Palette.material(colour)]
        }
        let target = SIMD3<Float>(0, level, 0)
        if animated {
            ticker.move(disc, to: target, duration: 0.3, arc: 0)
        } else {
            disc.position = target
        }
    }

    // MARK: - Carrying

    /// **All of this moved to `Engine/CarryController.swift`.**
    ///
    /// The height rule, the ray that keeps a prop under her fingertip, the
    /// container rims, the settle rules and the one patch of floor a drop is not
    /// allowed to stick in — none of it was ever about a kitchen, and the garden
    /// needs every line of it. `ROOMS.md` §6 is the prose; the two bugs it cost
    /// are documented over `Surfaces.pointedAt` and `CarryController.pickUp`.
    ///
    /// These wrappers exist so that every call site in this file — four
    /// `pickUp`s, every `onDragMoved`, six `settle`s, five `endCarry`s and the
    /// halo's `surfaceUnder` — is spelled exactly as it was before the move.
    /// Moving the hardest code in the project should not also be a rename of
    /// twenty call sites.

    private var carried: Entity? { carrier.carried }

    private func pickUp(_ entity: Entity, at world: SIMD3<Float>) {
        carrier.pickUp(entity, at: world)
    }

    private func carry(to world: SIMD3<Float>) { carrier.move(to: world) }

    private func endCarry() { carrier.end() }

    /// A drop that did not do anything in particular. It stays where she put it.
    private func settle(_ entity: Entity, missed: Bool) {
        carrier.settle(entity, missed: missed)
    }

    /// What a prop that is standing somewhere is standing *on*. Position-based,
    /// where the drag's question is ray-based — the halo asks this one, because
    /// it follows a prop rather than a finger.
    private func surfaceUnder(_ point: SIMD3<Float>, for entity: Entity) -> Float {
        carrier.surfaceUnder(point, for: entity)
    }


    /// She tried the step and it did not take.
    ///
    /// Twice, Nina says something kind and nothing else. **The third time she
    /// says the instruction again** — the same line the step opened with, at
    /// normal priority so it is not dropped — because three misses in a row is
    /// the clearest signal available that the cue was heard once and has since
    /// been forgotten, and she cannot read a reminder.
    private func noteMiss() {
        if missStep != state.step {
            missStep = state.step
            missCount = 0
        }
        missCount += 1
        guard missCount >= 3 else {
            voice.say(Line.oeps)
            return
        }
        missCount = 0
        voice.say(nudgeLine(for: state.step))
        // And point at it again while she hears it, in case the glow has
        // become part of the furniture.
        if let target = haloTarget(), target.isEnabled {
            ticker.squash(target, amount: 0.18, duration: 0.5)
        }
    }

    /// Something worked. The miss counter only measures a run of failures, so
    /// any success clears it.
    private func noteHit() {
        missCount = 0
        missStep = state.step
    }

    // MARK: - Step 1: filling the bowl

    /// **A tap on an ingredient names it.**
    ///
    /// It used to answer with an instruction — "doe de toverdingetjes maar in de
    /// kom" for the lit one, "pak maar wat er glimt" for any other — and that
    /// was the wrong answer to the question a tap asks. She already has the
    /// instruction: the halo is on, Nina said the step out loud when it opened,
    /// the idle nudge repeats it after 45 seconds and three misses bring it back
    /// at full priority. What she did *not* have anywhere was the word for the
    /// thing under her finger, and an ingredient called toverbosbes is worth
    /// more to a 4-year-old than a fourth copy of the instruction.
    private func nudgeToken(_ index: Int) {
        guard index < tokens.count else { return }
        ticker.squash(tokens[index].entity, amount: 0.18)
        sound.playVaried(.plop, volume: 0.5)
        voice.say(tokens[index].ingredient.nameLineID, priority: .low)
    }

    /// A token released. In the bowl it counts; anywhere else it just stays
    /// where she put it.
    ///
    /// **Any token counts, not only the lit one.** The order is a suggestion
    /// now, so if she goes for the crate before the top shelf, the crate's
    /// ingredient goes in the cake and the halo moves on to whatever is left.
    private func dropToken(index: Int, at world: SIMD3<Float>) {
        guard index < tokens.count, let bowl else { return }
        let token = tokens[index]
        endCarry()

        guard Layout.distanceXZ(token.entity.position, bowl.position) <= snapRadius else {
            // Only a miss if the bowl is what she is meant to be filling. The
            // rest of the round she is simply moving a berry about, and being
            // told "oeps" for tidying up would be nonsense.
            settle(token.entity, missed: state.step == .vullen)
            return
        }

        // Into the bowl. The token is consumed; what is left is a colour.
        let into = bowl.position + [0, 0.014, 0]
        noteHit()
        ticker.move(token.entity, to: into, duration: 0.28, arc: 0.02, ease: Ease.inCurve) {
            [weak self] in
            guard let self else { return }
            token.entity.isEnabled = false
            ContactShadows.removeFrom(token.entity)
            self.sound.playVaried(.plop)
            Sparkles.ring(at: into, in: self.root, ticker: self.ticker,
                          colour: token.ingredient.tokenColour, radius: 0.045)

            // The basket is never mutated. `used` records which slot went in,
            // which is what lets her take them in any order and still have the
            // room know which shelf is empty.
            //
            // **Read the slots before appending, not after.** `usedSlots` falls
            // back to `0..<inBowl.count` for a round saved by the build that
            // had no `used` key, so reading it after the append would count the
            // ingredient that is going in right now as slot 0 — marking a shelf
            // she has not touched as empty, and ending the fetching an
            // ingredient early.
            let slots = self.state.usedSlots
            self.state.inBowl.append(token.ingredient)
            self.state.used = slots + [index]
            self.refreshBowlBatter(animated: true)
            self.voice.sayWhenQuiet(token.ingredient.lineID)
            self.baker?.set(.cheering)
            self.save()

            // An ingredient can be dropped in before the dough is rolled. It is
            // still her cake, so it counts — the round simply arrives at
            // `vullen` with the bowl already started.
            if self.state.step == .vullen || self.state.step == .uitrollen {
                self.refreshInteractivity()
                if self.state.allCollected && self.state.step == .vullen {
                    self.ticker.after(1.1) { [weak self] in self?.beginStirring() }
                } else {
                    // Point at the next place before she has to go looking.
                    self.ticker.after(1.8) { [weak self] in
                        guard let self, self.state.step == .vullen else { return }
                        self.sayNextSource()
                    }
                }
            } else {
                self.refreshInteractivity()
            }
        }
    }

    private func beginStirring() {
        state.step = .roeren
        saidGoodStirring = false
        applyStep(animated: true)
        save()
        voice.sayWhenQuiet(Line.roeren)
    }

    // MARK: - Step 2: stirring

    /// The bowl has two verbs, and which one she gets depends only on whether
    /// this is the stirring step. Everywhere else it is a thing she can pick up
    /// and move, like everything else in the room.
    private func bowlTouchBegan(_ world: SIMD3<Float>) {
        guard state.step != .roeren else {
            stirLastAngle = angleAroundBowl(world)
            stirLastPoint = world
            return
        }
        guard let bowl else { return }
        pickUp(bowl, at: world)
    }

    private func bowlTouchMoved(_ world: SIMD3<Float>) {
        guard state.step != .roeren else {
            stir(to: world)
            return
        }
        // The batter is a child of the bowl, so it rides along for free.
        carry(to: world)
    }

    private func bowlTouchEnded(_ world: SIMD3<Float>) {
        stirLastAngle = nil
        stirLastPoint = nil
        guard state.step != .roeren else { return }
        // **Only a drop if the bowl was actually picked up on this touch**, and
        // this is the fix for a failure that arrived unprompted.
        //
        // The stir finishes *under her finger*: the last degree of the third
        // turn sets `state.step` to `.gieten` mid-drag, and she is still holding
        // the bowl's target when it does. The rest of that same gesture then ran
        // down the pouring path — and because stirring never picks the bowl up,
        // the bowl was still sitting at its home position 70 mm from the tin, so
        // letting go counted as a failed pour. Nina said "oeps" a second after
        // congratulating her on the batter, and the miss counter started
        // climbing towards a reminder she had done nothing to earn.
        //
        // `carried` is the honest test: a drag that began as a stir never set
        // it, so there is nothing to drop and nothing to fail.
        guard carried === bowl else { return }
        dropBowl(at: world)
    }

    private func angleAroundBowl(_ world: SIMD3<Float>) -> Float {
        let centre = bowl?.position ?? Layout.bowlHome
        return atan2(world.z - centre.z, world.x - centre.x)
    }

    /// Three full turns finishes it — **or twice as much scrubbing**.
    ///
    /// This is the one mechanic in the room that had to bend to her hands.
    /// `GAMEPLAY.md` §6.3: a 4-year-old who cannot yet draw a circle still has
    /// to be able to make batter, so raw travel counts too, at half rate. The
    /// `max` rather than a sum is deliberate — a real circle should not also
    /// bank its own arc length and finish in one and a half turns.
    private func stir(to world: SIMD3<Float>) {
        guard let spoon else { return }
        let angle = angleAroundBowl(world)
        defer {
            stirLastAngle = angle
            stirLastPoint = world
        }
        guard let last = stirLastAngle, let lastPoint = stirLastPoint else { return }

        var delta = angle - last
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }

        let stirRadius: Float = 0.020
        let travel = Layout.distanceXZ(world, lastPoint)
        let gain = max(abs(delta), travel / stirRadius * 0.5)
        let turnsNeeded: Float = 6 * .pi   // three full turns

        state.stir = min(1, state.stir + gain / turnsNeeded)

        // The spoon follows her finger, held inside the bowl.
        let centre = bowl?.position ?? Layout.bowlHome
        var offset = SIMD3<Float>(world.x - centre.x, 0, world.z - centre.z)
        let reach = simd_length(SIMD2<Float>(offset.x, offset.z))
        if reach > 0.016 { offset *= 0.016 / reach }
        spoon.position = centre + offset + [0, 0.030, 0]

        // The batter turns with her, and the colour comes up as it mixes.
        if let disc = bowlBatter {
            disc.orientation = disc.orientation * simd_quatf(angle: delta * 1.6, axis: [0, 1, 0])
        }
        refreshBowlBatter(animated: false)

        stirTickAccumulator += abs(gain)
        if stirTickAccumulator > 0.7 {
            stirTickAccumulator = 0
            sound.play(.stirTick, volume: 0.35, rate: Float.random(in: 0.9...1.15))
        }

        if !saidGoodStirring && state.stir > 0.45 {
            saidGoodStirring = true
            voice.say(Line.roerenGoedZo, priority: .low)
        }
        // Saved as she goes, not just at the end: closing the app mid-stir has
        // to come back mid-stir (`GAMEPLAY.md` §7).
        if state.stir - lastSavedStir > 0.15 {
            lastSavedStir = state.stir
            save()
        }
        if state.stir >= 1 {
            finishStirring()
        }
    }

    private func finishStirring() {
        guard state.step == .roeren else { return }
        state.step = .gieten
        stirLastAngle = nil
        save()

        if let bowl {
            Sparkles.burst(at: bowl.position + [0, 0.03, 0], in: root, ticker: ticker,
                           colour: state.bowlSpec.batterColour, count: 14)
            ticker.squash(bowl, amount: 0.16)
        }
        sound.play(.sparkle)
        baker?.set(.cheering)
        applyStep(animated: true)
        voice.sayWhenQuiet(Line.beslagKlaar)
        ticker.after(2.6) { [weak self] in
            guard let self, self.state.step == .gieten else { return }
            self.voice.say(Line.gieten, priority: .low)
        }
    }

    // MARK: - Step 3: pouring

    private func dropBowl(at world: SIMD3<Float>) {
        guard let bowl, let tin else { return }
        endCarry()
        // Pouring only happens when there is something to pour. Carried over to
        // the tin during `vullen`, the bowl just gets set down next to it.
        guard state.step == .gieten,
              tin.root.isEnabled,
              Layout.distanceXZ(bowl.position, tin.root.position) <= snapRadius else {
            settle(bowl, missed: state.step == .gieten)
            return
        }
        noteHit()
        pour(bowl: bowl, tin: tin)
    }

    /// **Tip, pour, fill — in that order, with the pouring visible.**
    ///
    /// It used to be tip and cut: the bowl tilted over 0.45 s, and on the frame
    /// the tilt finished the bowl's batter was removed and the tin's began to
    /// grow. Both *ends* of the action were animated and the action itself was
    /// missing, so what she saw was batter teleporting between two containers
    /// (owner, 2026-08-16).
    ///
    /// There is now a stream between them, and the three things that have to
    /// happen together do: the stream runs, the bowl empties, and the tin fills,
    /// all over the same 0.7 seconds. Emptying the bowl is the half that is easy
    /// to forget — a source that pours forever while the destination fills is
    /// the same tell as water that never gathers in the basin, which is why the
    /// tap has a pool.
    ///
    /// The stream is a child of the room rather than of either container: it
    /// belongs to neither, it must not tip with the bowl, and it has to outlive
    /// the bowl's own batter.
    private func pour(bowl: ModelEntity, tin: KitchenProps.Tin) {
        // Entities, not the struct, because these get captured weakly below.
        let tinRoot = tin.root
        let tinBatter = tin.batter
        let above = tinRoot.position + [0, 0.030, 0]

        ticker.move(bowl, to: above, duration: 0.3, arc: 0.01, done: { [weak self] in
            guard let self else { return }
            self.sound.play(.pour)

            // Tip it. The batter goes with the bowl until the stream takes over.
            let tipped = simd_quatf(angle: -1.15, axis: [0, 0, 1])
            self.ticker.tween(0.45, ease: Ease.inOut, step: { [weak bowl] t in
                bowl?.orientation = simd_slerp(simd_quatf(angle: 0, axis: [0, 0, 1]), tipped, t)
            }, done: { [weak self] in
                self?.runPour(from: above, into: tinRoot, batter: tinBatter, tipped: tipped)
            })
        })
    }

    /// The pour itself, once the bowl is over the tin and tilted.
    private func runPour(from lip: SIMD3<Float>, into tinRoot: Entity,
                         batter tinBatter: ModelEntity, tipped: simd_quatf) {
        let colour = state.bowlSpec.batterColour
        // From the tipped rim down to the floor of the tin. The bowl pours off
        // its +X side — tipping about −Z carries its mouth that way — so the
        // stream stands just off the tin's centre rather than down its axis,
        // which is also what stops it z-fighting the batter rising to meet it.
        let length: Float = 0.026
        let stream = KitchenProps.pourStream(colour: colour, length: length, flat: flat)
        stream.position = lip + [0.010, -0.004, 0]
        stream.scale = [1, 0.001, 1]
        root.addChild(stream)

        // Growing down the Y axis is the stream arriving.
        ticker.tween(0.18, ease: Ease.out, step: { [weak stream] t in
            stream?.scale = SIMD3<Float>(1, max(0.001, t), 1)
        })

        // And it turns while it runs, so its six facets travel across the
        // surface. A fixed shape that does not move is a stick.
        var spin: Float = 0
        let spinJob = ticker.add { [weak stream] dt in
            guard let stream, stream.parent != nil else { return false }
            spin += dt
            stream.orientation = simd_quatf(angle: spin * 7.0, axis: [0, 1, 0])
            return true
        }
        bakeJobs.append(spinJob)

        // The tin fills and the bowl empties over the same stretch. Neither
        // reads as pouring on its own.
        tinBatter.isEnabled = true
        tinBatter.model?.materials = [Palette.material(colour)]
        tinBatter.scale = [1, 0.05, 1]
        ticker.tween(0.70, ease: Ease.inOut, step: { [weak tinBatter] t in
            tinBatter?.scale = SIMD3<Float>(1, 0.05 + 0.95 * t, 1)
        })
        if let bowlBatter {
            ticker.tween(0.70, ease: Ease.inOut, step: { [weak bowlBatter] t in
                bowlBatter?.scale = SIMD3<Float>(1, max(0.001, 1 - t), 1)
            }, done: { [weak self] in
                self?.bowlBatter?.removeFromParent()
                self?.bowlBatter = nil
            })
        }

        // A splash where it lands, twice, while it is running.
        for delay in [Float(0.24), 0.56] {
            ticker.after(delay) { [weak self] in
                guard let self else { return }
                Sparkles.burst(at: tinRoot.position + [0, 0.014, 0], in: self.root,
                               ticker: self.ticker, colour: colour,
                               count: 4, size: 0.0018, speed: 0.05,
                               gravity: 0.35, life: 0.45)
            }
        }

        ticker.after(0.72) { [weak self] in
            guard let self else { return }
            self.ticker.cancel(spinJob)
            // Shrinks from the bottom up — the tail of a pour leaves the rim
            // last, which is the opposite of how it arrived.
            self.ticker.tween(0.20, ease: Ease.inCurve, step: { [weak stream] t in
                stream?.scale = SIMD3<Float>(1, max(0.001, 1 - t), 1)
            }, done: { [weak stream] in stream?.removeFromParent() })

            Sparkles.ring(at: tinRoot.position + [0, 0.012, 0], in: self.root,
                          ticker: self.ticker, colour: colour, radius: 0.04)

            // And the bowl comes upright and goes back where it lives.
            self.ticker.after(0.10) { [weak self] in
                guard let self, let bowl = self.bowl else { return }
                self.ticker.tween(0.4, ease: Ease.out, step: { [weak bowl] t in
                    bowl?.orientation = simd_slerp(tipped,
                                                   simd_quatf(angle: 0, axis: [0, 0, 1]), t)
                })
                self.ticker.move(bowl, to: Layout.bowlHome, duration: 0.45, arc: 0.02)
            }

            self.state.step = .inOven
            self.save()
            self.applyStep(animated: true)
            self.voice.sayWhenQuiet([Line.gegoten, Line.ottoWacht])
        }
    }

    // MARK: - Step 4: into Otto

    private func dropTin(at world: SIMD3<Float>) {
        guard let tin, let oven else { return }
        endCarry()
        // Otto only takes it once it has batter in it. Before that she can
        // carry the tin around all she likes and put it down anywhere.
        guard state.step == .inOven,
              Layout.distanceXZ(tin.root.position, Layout.ovenMouth) <= 0.081 else {
            settle(tin.root, missed: state.step == .inOven)
            return
        }
        noteHit()

        // In it goes, and out of sight — an oven you can see into is not an
        // oven, and hiding it is what makes the door opening worth watching.
        let mouth = Layout.ovenMouth
        let tinRoot = tin.root
        ticker.move(tinRoot, to: mouth, duration: 0.3, arc: 0.01, done: { [weak self] in
            guard let self else { return }
            self.sound.play(.whoosh, volume: 0.7)
            ContactShadows.removeFrom(tinRoot)
            self.ticker.tween(0.35, ease: Ease.inCurve, step: { [weak tinRoot] t in
                tinRoot?.position = mouth + SIMD3<Float>(0, 0, -0.02 * t)
                tinRoot?.scale = SIMD3<Float>(repeating: 1 - 0.4 * t)
            }, done: { [weak self] in
                guard let self else { return }
                self.tin?.root.isEnabled = false
                self.state.step = .bakken
                self.save()
                self.setDoor(open: false, animated: true, oven: oven)
                self.refreshInteractivity()
                self.voice.sayWhenQuiet(Line.ottoVormErin)
                self.ticker.after(3.0) { [weak self] in
                    guard let self, self.state.step == .bakken else { return }
                    self.voice.say(Line.klopOpOtto, priority: .low)
                }
            })
        })
    }

    // MARK: - Step 5: baking

    private func tapOtto() {
        guard let oven else { return }
        // Not while he is baking: the bake owns the dome's scale, writing it
        // every frame, so a squash on top of it is a fight the squash loses and
        // then "restores" a scale it read out of the middle of.
        if !baking { ticker.squash(oven.dome, amount: 0.16) }
        blink(oven)
        googlyEyes(oven)
        guard state.step == .bakken, !baking else {
            // Otto is a toy the rest of the time — and while he bakes — and he
            // says something different every single time she pokes him.
            sound.playVaried(.thud, volume: 0.4)
            voice.say(Line.ottoTik)
            return
        }
        bake(oven: oven)
    }

    private func bake(oven: KitchenProps.Oven) {
        baking = true
        clearHalo()
        let spec = state.bowlSpec
        let dome = oven.dome
        let door = oven.door
        let chimneyTop = oven.chimneyTop
        voice.sayWhenQuiet(Line.ottoBakken)
        sound.play(.whoosh, volume: 0.6)

        // Four seconds of Otto being delighted. Nothing is being waited for —
        // he is performing, and she can poke anything in the room while he does.
        var elapsed: Float = 0
        let breathe = ticker.add { [weak dome] dt in
            guard let dome else { return false }
            elapsed += dt
            let pulse = 1 + sin(elapsed * 6.5) * 0.035
            dome.scale = SIMD3<Float>(1 / pulse, pulse, 1 / pulse)
            return elapsed < 4.0
        }
        bakeJobs.append(breathe)

        for step in 0..<5 {
            let job = ticker.after(0.55 + Float(step) * 0.7) { [weak self] in
                guard let self else { return }
                Sparkles.puff(at: chimneyTop, in: self.root, ticker: self.ticker,
                              colour: Palette.creamLight, count: 5)
            }
            bakeJobs.append(job)
        }
        let glow = ticker.after(0.2) { [weak door] in
            door?.model?.materials = [Palette.glowMaterial(Palette.butterYellow,
                                                           intensity: 0.6)]
        }
        bakeJobs.append(glow)

        let finish = ticker.after(4.0) { [weak self] in
            self?.cakeIsReady(spec: spec, oven: oven)
        }
        bakeJobs.append(finish)
    }

    private func cakeIsReady(spec: CakeSpec, oven: KitchenProps.Oven) {
        baking = false
        oven.dome.scale = SIMD3<Float>(repeating: 1)
        oven.door.model?.materials = [Palette.material(Palette.blushPinkDeep)]
        sound.play(.ovenPing)
        setDoor(open: true, animated: true, oven: oven)

        let node = KitchenProps.cake(spec, flat: flat)
        node.position = Layout.ovenMouth + [0, -0.004, 0]
        node.scale = SIMD3<Float>(repeating: 0.6)
        root.addChild(node)
        cake = node
        state.cake = spec
        state.step = .klaar
        save()

        ticker.tween(0.3, ease: Ease.out, step: { [weak node] t in
            node?.scale = SIMD3<Float>(repeating: 0.6 + 0.4 * t)
        })
        ticker.move(node, to: Layout.cakeSpot, duration: 0.9, arc: 0.05, ease: Ease.inOut) {
            [weak self] in
            guard let self else { return }
            self.sound.play(.reward)
            self.baker?.set(.cheering)
            Sparkles.burst(at: Layout.cakeSpot + [0, 0.03, 0], in: self.root,
                           ticker: self.ticker, colour: Palette.creamLight, count: 18)
            ContactShadows.attach(to: node, radius: 0.026, settings: self.settings)
            ContactShadows.update(for: node, surfaceY: Layout.tableTopY, settings: self.settings)
            if spec.sparkles { self.startCakeSparkle(node) }
            self.setPlankInviting(true)
            self.refreshInteractivity()
            // Otto first, then Nina on the colour and at most one effect, and
            // only then where it goes — the last step is not an interruption of
            // her looking at what she made.
            self.voice.sayWhenQuiet([Line.ottoKlaar] + spec.reactionLines + [Line.opDePlank])
        }
    }

    /// Star sugar: the cake keeps sparkling for as long as it is on the table.
    private func startCakeSparkle(_ node: Entity) {
        var next: Float = 0.9
        ticker.add { [weak self, weak node] dt in
            guard let self, let node, node.parent != nil else { return false }
            next -= dt
            guard next <= 0 else { return true }
            next = Float.random(in: 0.8...1.6)
            Sparkles.burst(at: node.position + [0, 0.045, 0], in: self.root,
                           ticker: self.ticker, colour: Palette.creamLight,
                           count: 4, size: 0.002, speed: 0.05, life: 0.6)
            return true
        }
    }

    // MARK: - Step 6: the cake, and the way out

    private func tapCake() {
        guard let cake else { return }
        ticker.squash(cake, amount: 0.15)
        sound.play(.sparkle, volume: 0.6)
        Sparkles.burst(at: cake.position + [0, 0.04, 0], in: root, ticker: ticker, count: 6)
        voice.say(Line.ditTaart, priority: .low)
    }

    /// **The last step of the round: she carries the cake up onto the plank.**
    ///
    /// It used to be a tap on the doorway, and that was the weakest moment in
    /// the round. Everything else she does is a thing with her hands on the
    /// object — roll it, fill it, stir it, pour it, push it into Otto — and
    /// then the cake she had just made was finished by tapping a completely
    /// different object across the room, which happened to be an arch. The
    /// cake went up on the plank by itself while she watched.
    ///
    /// Now she puts it there. It is the same verb as every other step, it ends
    /// on the object the whole round was about, and the plank — which is the
    /// stand-in for the wall of twelve frames, and therefore for the entire
    /// game (`GAMEPLAY.md` §2) — becomes somewhere she reaches rather than
    /// somewhere things appear.
    private func dropCake(at world: SIMD3<Float>) {
        guard let cake else { return }
        endCarry()
        guard state.step == .klaar, let spec = state.cake, Layout.nearPlank(cake.position) else {
            settle(cake, missed: state.step == .klaar)
            return
        }
        noteHit()
        placeOnPlank(cake, spec: spec)
    }

    /// Onto the plank, and — after a proper look at it — a fresh round.
    ///
    /// **The end of a round used to last three quarters of a second.** The cake
    /// landed on the plank, `startNewRound` fired from the same completion
    /// handler, and the room she had spent eleven minutes filling was torn down
    /// and rebuilt while Nina was still on the first syllable of saying well
    /// done. Owner, 2026-08-16: "it just kind of jumps too fast to the start
    /// again without much explanation."
    ///
    /// It is now the one moment in the round that is allowed to take its time.
    /// The cake climbs up and shrinks onto the plank, Nina says three things —
    /// what they made, that it is up there with the others, and what happens
    /// next — the plank throws sparkles between them, and **only when she has
    /// stopped talking does the room reset.** Nothing blocks: every prop still
    /// answers a touch throughout, and the whole thing is `whenQuiet`, so a
    /// missing mp3 or a muted iPad simply makes it shorter rather than
    /// stranding her in a finished kitchen.
    ///
    /// The three lines are deliberately in that order. She is looking at the
    /// cake, so the cake is first; the plank is what she just did, so it is
    /// second; and "shall we make another one" is last, because it is the only
    /// one of the three that is about a kitchen she has not yet got to.
    private func placeOnPlank(_ cake: Entity, spec: CakeSpec) {
        var shelf = state.shelf
        shelf.append(spec)
        if shelf.count > Layout.cakeShelfCapacity { shelf.removeFirst() }

        let slot = shelfSlot(min(shelf.count - 1, Layout.cakeShelfCapacity - 1))
        ContactShadows.removeFrom(cake)
        clearHalo()
        setPlankInviting(false)
        // Shrinks to plank size as it goes, which is what makes four of them
        // fit on the board.
        ticker.tween(0.7, ease: Ease.inOut, step: { [weak cake] t in
            cake?.scale = SIMD3<Float>(repeating: 1 - 0.38 * t)
        })
        ticker.move(cake, to: slot, duration: 0.7, arc: 0.03, ease: Ease.out) { [weak self] in
            guard let self else { return }
            self.sound.play(.sparkle, volume: 0.7)
            Sparkles.burst(at: slot + [0, 0.02, 0], in: self.root, ticker: self.ticker, count: 10)
            self.celebrate(shelf: shelf, at: slot)
        }
        baker?.set(.cheering)
        // **The third line is the one that changes.** The first two are about
        // the cake and the plank and are true every time; the last one is what
        // happens next, and what happens next is not the same after the third
        // cake as after the first. `shelf` already counts the one that has just
        // landed, so this asks about the plank she is looking at.
        let finishes = shelf.count >= Layout.cakesToFinish
        voice.sayWhenQuiet([Line.klaar, Line.plankGezet,
                            finishes ? Line.kamerKlaar : Line.plankNogEen], gap: 0.42)
        self.cake = nil
        touch.target(named: "cake")?.enabled = false
    }

    /// The cake is on the plank. Look at it for a bit.
    ///
    /// Three seconds of it would be a pause; what makes it a moment is that
    /// something happens on each beat — a shower over the new cake, then a
    /// smaller one over the whole row, and Nina hopping again in the middle of
    /// it. The rebuild waits on `whenQuiet` rather than on the length of this,
    /// so the two cannot drift apart when a line is re-recorded.
    private func celebrate(shelf: [CakeSpec], at slot: SIMD3<Float>) {
        for (i, delay) in [Float(1.1), 2.4, 3.9].enumerated() {
            ticker.after(delay) { [weak self] in
                guard let self else { return }
                let over = i == 1
                    ? SIMD3<Float>(Layout.cakePlankCentre.x, Layout.cakePlankY + 0.030,
                                   Layout.cakePlankCentre.y)
                    : slot + [0, 0.026, 0]
                Sparkles.burst(at: over, in: self.root, ticker: self.ticker,
                               colour: i == 1 ? Palette.creamLight : Halo.core,
                               count: i == 1 ? 12 : 7, size: 0.0024,
                               speed: 0.06, life: 1.0)
                self.sound.play(.sparkle, volume: 0.35, rate: 1.0 + Float(i) * 0.12)
                if i == 1 { self.baker?.set(.cheering) }
            }
        }
        voice.whenQuiet(after: 0.5) { [weak self] in
            self?.startNewRound(shelf: shelf)
        }
    }

    /// The door. It does not go anywhere yet — the decorating room does not
    /// exist, and the cake going up on the plank is what ends the round now —
    /// so tapping it opens it, shows the light on the other side, and lets it
    /// swing shut. **When the decorating room lands this is still the one
    /// function to change**, and the swing is already the first half of the
    /// transition.
    ///
    /// It used to squash the whole arch, which was the generic prop reaction
    /// applied to the one prop in the room that has a hinge. A door bending is
    /// a door made of rubber; a door opening is a door.
    /// **The door, which now has two answers.**
    ///
    /// Unfinished kitchen: it opens, shows the light, falls shut, and Nina says
    /// what it is. That is a toy, and it always was.
    ///
    /// Three cakes up: it is **the way out of the room**, and tapping it is what
    /// ends the kitchen (owner, 2026-08-16). Everything about the door has been
    /// telling her so since the third cake landed — it is standing ajar, the
    /// light behind it is on, and there is a ring on the floor at the threshold.
    private func tapDoorway() {
        guard let doorway else { return }
        sound.play(.whoosh)
        guard roomComplete else {
            swingDoor(doorway)
            voice.say(Line.ditDeur, priority: .low)
            return
        }
        endRoom(doorway)
    }

    /// **The end of the kitchen.**
    ///
    /// It is a ceremony rather than a transition, because there is nowhere yet
    /// to transition to: the door swings wide and holds there, the light behind
    /// it spills onto the threshold, and Nina says — carefully — that this is
    /// where they will carry on. *"Die komt gauw, hoor"* rather than a promise
    /// of a room this build cannot open, because a 4-year-old told she is going
    /// somewhere and then not taken there has been lied to.
    ///
    /// **This is the one function the decorating room replaces**, and by then
    /// the swing is already the first half of the transition. Until then it can
    /// be tapped as often as she likes: nothing is consumed, the plank keeps her
    /// cakes, and the leaf falls back to ajar rather than shut so the room stays
    /// finished and stays finishable.
    private func endRoom(_ doorway: KitchenProps.Doorway) {
        swingDoor(doorway, hold: 2.6)
        baker?.set(.cheering)
        sound.play(.reward, volume: 0.7)
        voice.sayWhenQuiet(Line.kamerDeur)

        // Light coming through the gap, twice, on the beat of the swing opening
        // and of it standing there.
        let threshold = Layout.doorHaloSpot
        for (i, delay) in [Float(0.45), 1.5].enumerated() {
            ticker.after(delay) { [weak self] in
                guard let self else { return }
                Sparkles.burst(at: threshold + [0, 0.030, 0], in: self.root,
                               ticker: self.ticker, colour: Palette.butterYellow,
                               count: i == 0 ? 12 : 8, size: 0.0026,
                               speed: 0.07, life: 1.1)
                self.sound.play(.sparkle, volume: 0.45, rate: 1.0 + Float(i) * 0.15)
            }
        }
    }

    /// Open, hold, fall back to `doorRest` — and re-tapping restarts it rather
    /// than stacking a second turn on top of the first, which would leave the
    /// leaf wherever the two disagreed.
    ///
    /// **It falls back to the rest angle, not to shut.** That is the whole of
    /// what keeps a finished kitchen finished-looking: once three cakes are up
    /// the leaf lives on the latch at `Layout.doorAjarAngle`, and a swing that
    /// ended by closing it would quietly undo the invitation every time she
    /// took it up.
    private func swingDoor(_ doorway: KitchenProps.Doorway, hold: Float = 1.5) {
        ticker.cancel(doorSwing)
        let hinge = doorway.hinge
        let rest = doorRest
        let open = Layout.doorOpenAngle
        doorSwing = ticker.tween(hold, ease: Ease.linear, step: { [weak hinge] t in
            guard let hinge else { return }
            let amount: Float
            switch t {
            case ..<0.3:  amount = Ease.out(t / 0.3)
            case ..<0.62: amount = 1
            default:      amount = 1 - Ease.inOut((t - 0.62) / 0.38)
            }
            hinge.orientation = simd_quatf(angle: rest + (open - rest) * amount,
                                           axis: [0, 1, 0])
        }, done: { [weak self, weak hinge] in
            hinge?.orientation = simd_quatf(angle: rest, axis: [0, 1, 0])
            // Cleared so `refreshDoorInvitation` knows the hinge is its own
            // again — otherwise a step change during a swing would either be
            // ignored forever or fight the tween for the same quaternion.
            self?.doorSwing = nil
        })
    }

    private func startNewRound(shelf: [CakeSpec]) {
        state = RoundState.fresh(keeping: shelf)
        RoundStore.save(state)
        build(flat: flat)
        // A beat so the new dough is on the table before she is told about it,
        // and `sayWhenQuiet` in case the celebration is still finishing — the
        // rebuild is triggered by Nina going quiet, but a re-recorded line or a
        // timeout could still put the two within a syllable of each other.
        ticker.after(0.8) { [weak self] in
            guard let self else { return }
            // **A finished kitchen does not announce another cake.** The last
            // thing Nina said was that three are up and the door is open, and
            // following it with "let's mix everything in the bowl" would be the
            // room arguing with itself. The dough is on the table if she wants
            // it and the halo is on the rolling pin; the idle nudge picks it up
            // if she stands still. Doing nothing here is the whole point — she
            // is being offered the door, not marched through it.
            guard !self.roomComplete else { return }
            self.voice.sayWhenQuiet([Line.opdracht, Line.uitrollen], gap: 0.35)
        }
    }

    /// **The restart button. It starts the whole kitchen over, plank and all.**
    ///
    /// It used to keep the cakes already on the plank, on the argument that
    /// nothing she has finished should ever be lost. That argument was right
    /// when the plank was only a trophy shelf — and it stopped being right the
    /// moment three cakes on it became the thing that *finishes the room*
    /// (owner, 2026-08-16: "when restarting via the button, the shelf must be
    /// cleared of cakes, you start over again").
    ///
    /// Keeping them now would make the button mean two different things
    /// depending on when it was pressed: on an empty plank, start again; on a
    /// full one, start again but stay finished, with the door still open behind
    /// her. A button that has to be explained is a button a 4-year-old cannot
    /// use. This one has one meaning — **everything back to the beginning** —
    /// and the room agrees with it: with the shelf empty `roomComplete` goes
    /// false, so `applyStep` closes the door, puts out its halo, and the kitchen
    /// is genuinely at the start again rather than at the start of a round.
    func restartRound() {
        sound.play(.whoosh, volume: 0.6)
        Sparkles.burst(at: Layout.bowlHome + [0, 0.04, 0], in: root, ticker: ticker,
                       colour: Palette.mintLight, count: 10)
        state = RoundState.fresh()
        RoundStore.save(state)
        build(flat: flat)
        voice.say(Line.opnieuw)
        ticker.after(2.0) { [weak self] in
            guard let self, self.state.step == .uitrollen else { return }
            self.voice.say(Line.uitrollen, priority: .low)
        }
    }

    // MARK: - Toys

    /// A poof of flour out of the open neck of the sack.
    ///
    /// **This went to a cloud and came back.** `references/ingredients/flour-cloud.png`
    /// showed a cluster of overlapping lit lobes, it was built, and on device
    /// it read as *photographic* — a real puff of real flour sitting in a room
    /// made of flat pastel facets. It was the one thing in the kitchen that
    /// looked like it came from somewhere else, which is exactly what the four
    /// style phrases in `CLAUDE.md` exist to prevent. The owner called it on
    /// sight and the stylised burst went back in.
    ///
    /// The plate was still worth its credit: the *sack* it was generated
    /// alongside is the version that shipped. Reference plates are briefs, and
    /// a brief can be right about one thing and wrong about another.
    private func tapFlour() {
        guard let flourSack else { return }
        ticker.squash(flourSack, amount: 0.16)
        sound.playVaried(.poof)
        // Out of the open collar, not out of the middle of the sack.
        Sparkles.puff(at: flourSack.position + [0, 0.050, 0], in: root,
                      ticker: ticker, count: 12)
        // A second, smaller one a beat later, so it billows twice the way a
        // slapped sack does. This much of the cloud version was worth keeping.
        ticker.after(0.22) { [weak self] in
            guard let self, let sack = self.flourSack else { return }
            Sparkles.puff(at: sack.position + [0, 0.044, 0], in: self.root,
                          ticker: self.ticker, count: 7)
        }
        dustFloor(near: flourSack.position)
        // Mostly the name; one time in three the joke. The sack is the room's
        // most pokeable toy, so it is the one prop where hearing the same
        // sentence every single time would wear out fastest — and "hihi, bloem
        // op je neus" is worth keeping for exactly that reason.
        voice.say(Int.random(in: 0..<3) == 0 ? Line.bloem : Line.ditBloem,
                  priority: .low)
    }

    /// The handprints from `GAMEPLAY.md` §6.3, as a fading patch of flour. It
    /// stays a while and then quietly stops being there. On the floor now,
    /// around the foot of the sack, which is where spilt flour goes.
    private func dustFloor(near position: SIMD3<Float>) {
        let patch = RoomBuilder.model(.prism(radius: Float.random(in: 0.012...0.020),
                                             height: 0.0007, sides: 9),
                                      Palette.creamLight, flat: flat, name: "Flour")
        patch.position = [position.x + Float.random(in: -0.026...0.026),
                          Layout.floorY + 0.0006,
                          position.z + Float.random(in: -0.018...0.018)]
        root.addChild(patch)
        flourPatches.append(patch)
        if flourPatches.count > 5 {
            flourPatches.removeFirst().removeFromParent()
        }
        ticker.after(14) { [weak self, weak patch] in
            guard let self, let patch else { return }
            self.ticker.tween(3.0, ease: Ease.linear, step: { [weak patch] t in
                patch?.scale = SIMD3<Float>(repeating: max(0.01, 1 - t))
            }, done: { [weak patch] in patch?.removeFromParent() })
        }
    }

    /// The tap runs for two and a half seconds, and four things happen at once.
    ///
    /// The old version scaled one blue prism up and back down again, which is
    /// why it read as a stick appearing rather than as water. What sells it is
    /// not any one of these, it is that they overlap:
    ///
    /// 1. **The stream grows down** from the spout, easing out — it arrives.
    /// 2. **It turns**, about a revolution a second, so its six big facets
    ///    travel across the surface and the thing looks like it is moving even
    ///    while it is a fixed shape.
    /// 3. **The basin fills**, and drains again after. Water that never
    ///    accumulates is the tell that it is not water.
    /// 4. **It splashes** — a ripple in the basin twice a second and a few
    ///    droplets bouncing back up out of it.
    private func tapSink() {
        guard let sink else { return }
        for job in sinkJobs { ticker.cancel(job) }
        sinkJobs.removeAll()

        let stream = sink.stream, pool = sink.pool
        let splash = sink.root.position + sink.splash
        let running: Float = 2.5

        stream.isEnabled = true
        pool.isEnabled = true
        sound.play(.water)
        voice.say(Line.ditKraan, priority: .low)

        sinkJobs.append(ticker.tween(0.22, ease: Ease.out, step: { [weak stream] t in
            stream?.scale = SIMD3<Float>(1, max(0.001, t), 1)
        }))

        // The turn, and a slight breathing of the stream's width — falling
        // water is never quite the same thickness two moments running.
        var spin: Float = 0
        sinkJobs.append(ticker.add { [weak stream] dt in
            guard let stream, stream.isEnabled else { return false }
            spin += dt
            let wobble = 1 + sin(spin * 11) * 0.10
            stream.orientation = simd_quatf(angle: spin * 6.0, axis: [0, 1, 0])
            stream.scale = SIMD3<Float>(wobble, stream.scale.y, wobble)
            return true
        })

        // Filling, then draining. Deliberately not linear: it fills fast and
        // then slows, the way a basin with a slow drain does.
        sinkJobs.append(ticker.tween(running * 0.9, ease: Ease.out, step: { [weak pool] t in
            pool?.scale = SIMD3<Float>(1, max(0.001, t), 1)
        }))

        // Ripples and droplets while it runs.
        var next: Float = 0.15
        var elapsed: Float = 0
        sinkJobs.append(ticker.add { [weak self] dt in
            guard let self else { return false }
            elapsed += dt
            guard elapsed < running else { return false }
            next -= dt
            guard next <= 0 else { return true }
            next = Float.random(in: 0.4...0.6)
            Sparkles.ring(at: splash + [0, 0.001, 0], in: self.root, ticker: self.ticker,
                          colour: Palette.mintLight, radius: 0.024)
            Sparkles.burst(at: splash, in: self.root, ticker: self.ticker,
                           colour: Palette.berryBlue, count: 4, size: 0.0016,
                           speed: 0.05, gravity: 0.35, life: 0.45)
            return true
        })

        sinkJobs.append(ticker.after(running) { [weak self] in
            guard let self else { return }
            self.sinkJobs.append(self.ticker.tween(0.28, ease: Ease.inCurve,
                                                   step: { [weak stream] t in
                stream?.scale = SIMD3<Float>(1, max(0.001, 1 - t), 1)
            }, done: { [weak stream] in stream?.isEnabled = false }))
            // The pool lingers a moment and then drains, which is what says the
            // water went somewhere rather than being switched off.
            self.sinkJobs.append(self.ticker.after(0.5) { [weak self] in
                guard let self else { return }
                self.sinkJobs.append(self.ticker.tween(0.9, ease: Ease.inOut,
                                                       step: { [weak pool] t in
                    pool?.scale = SIMD3<Float>(1, max(0.001, 1 - t), 1)
                }, done: { [weak pool] in pool?.isEnabled = false }))
            })
        })
    }

    private func tapScale() {
        guard let scaleProp else { return }
        sound.playVaried(.ding)
        voice.say(Line.ditWeegschaal, priority: .low)
        let pan = scaleProp.pan
        let home = pan.position
        ticker.tween(0.55, ease: Ease.linear, step: { [weak pan] t in
            let bounce = sin(t * .pi * 3) * (1 - t) * 0.006
            pan?.position = home - SIMD3<Float>(0, bounce, 0)
        }, done: { [weak pan] in pan?.position = home })
    }

    private func tapJar(_ jar: Entity) {
        ticker.wiggle(jar, angle: 0.12, duration: 0.45)
        sound.playVaried(.rattle, volume: 0.7)
        voice.say(Line.ditPotje, priority: .low)
    }

    private func rollBegan(at world: SIMD3<Float>) {
        guard let rollingPin else { return }
        rollLastPoint = world
        pickUp(rollingPin, at: world)
    }

    private func roll(to world: SIMD3<Float>) {
        guard let rollingPin, let last = rollLastPoint else { return }
        carry(to: world)
        // It lies along X, so travel in Z is what turns it.
        let dz = world.z - last.z
        rollingPin.orientation = rollingPin.orientation
            * simd_quatf(angle: dz / 0.008, axis: [1, 0, 0])
        if abs(dz) > 0.004 {
            sound.play(.roll, volume: 0.35, rate: Float.random(in: 0.9...1.2))
        }

        // **The rolling step.** Travel only counts while the pin is actually
        // over the dough, so waving it around the table does nothing — she has
        // to go back and forth across it, which is the motion the picture is
        // asking for. Roughly three passes.
        if state.step == .uitrollen, let dough, dough.isEnabled {
            let over = Layout.distanceXZ(rollingPin.position, dough.position) < 0.032
            if over {
                let travel = Layout.distanceXZ(world, last)
                state.roll = min(1, state.roll + travel / 0.11)
                shapeDough(dough, roll: state.roll)
                rollTickAccumulator += travel
                if rollTickAccumulator > 0.02 {
                    rollTickAccumulator = 0
                    sound.play(.stirTick, volume: 0.3, rate: Float.random(in: 0.8...1.0))
                    Sparkles.burst(at: dough.position + [0, 0.006, 0], in: root,
                                   ticker: ticker, colour: Palette.creamLight,
                                   count: 3, size: 0.0018, speed: 0.04, life: 0.5)
                }
                if state.roll >= 1 { finishRolling() }
            }
        }
        rollLastPoint = world
    }

    /// The base is flat. It hops into the tin, and the ingredients begin.
    private func finishRolling() {
        guard state.step == .uitrollen, let dough, let tin else { return }
        state.step = .vullen
        save()

        // The glow was on the pin, not on the dough — `refreshHalo` moves it on
        // when the step changes, and there is nothing on the dough to undo.
        ContactShadows.removeFrom(dough)
        sound.play(.sparkle, volume: 0.8)
        baker?.set(.cheering)

        let into = tin.root.position + [0, 0.006, 0]
        ticker.move(dough, to: into, duration: 0.55, arc: 0.035, ease: Ease.inOut) {
            [weak self] in
            guard let self else { return }
            self.dough?.isEnabled = false
            self.sound.play(.thud, volume: 0.5)
            Sparkles.ring(at: into, in: self.root, ticker: self.ticker,
                          colour: Palette.cream, radius: 0.035)
            self.refreshTinBase()
            self.applyStep(animated: true)
            self.voice.sayWhenQuiet(Line.deegKlaar)

            // **She may already have filled the bowl.** Nothing stops her
            // fetching ingredients before rolling — the halo suggests an order,
            // it does not impose one — so the round can arrive here with
            // everything already collected, and without this it would sit in
            // `vullen` with nothing left to collect and no way forward.
            guard !self.state.allCollected else {
                self.ticker.after(1.4) { [weak self] in self?.beginStirring() }
                return
            }
            // And then straight into where the next ingredient lives.
            self.ticker.after(2.2) { [weak self] in
                guard let self, self.state.step == .vullen else { return }
                self.sayNextSource()
            }
        }
    }

    /// Names the place the next ingredient is waiting, once, as its halo lights.
    private func sayNextSource() {
        guard let source = state.nextSource else { return }
        voice.say(source.lineID, priority: .low)
    }

    /// A tap on nothing. It still does something, because a dead tap reads as a
    /// broken iPad (`CONCEPT.md` §5).
    private func tapNothing(at world: SIMD3<Float>) {
        Sparkles.burst(at: world + [0, 0.004, 0], in: root, ticker: ticker,
                       colour: Palette.mintLight, count: 5, size: 0.002,
                       speed: 0.05, life: 0.5)
        sound.play(.sparkle, volume: 0.25, rate: 1.3)
    }

    /// **One blink at a time, and always off the same rest pose.**
    ///
    /// Both halves matter. `oven.eyeRest` rather than `eye.scale` means a blink
    /// landing on top of another one cannot take the squeezed eye as its
    /// starting point — which is how repeated taps left Otto permanently
    /// squinting (owner, 2026-08-16). And cancelling the running blink means
    /// two of them cannot write different scales to the same eye on alternate
    /// frames, which is a flicker rather than a blink.
    ///
    /// The reset before the tween is what a cancelled job's `done` would have
    /// done: `Ticker.cancel` drops the job without running it, so the eye is
    /// put back by hand here instead.
    private func blink(_ oven: KitchenProps.Oven) {
        for job in blinkJobs { ticker.cancel(job) }
        blinkJobs.removeAll()

        let base = oven.eyeRest
        for eye in oven.eyes {
            eye.scale = base
            let job = ticker.tween(0.22, ease: Ease.linear, step: { [weak eye] t in
                let squeeze = 1 - sin(t * .pi) * 0.85
                eye?.scale = SIMD3<Float>(base.x, base.y * squeeze, base.z)
            }, done: { [weak eye] in eye?.scale = base })
            blinkJobs.append(job)
        }
    }

    /// The pupils chase a small circle and come home — the googly wobble that
    /// makes a tap on Otto feel like poking someone rather than something.
    /// All offsets are from `pupilRest`, never from the current position, so
    /// this can safely land in the middle of a glance.
    private func googlyEyes(_ oven: KitchenProps.Oven) {
        let rest = oven.pupilRest
        for pupil in oven.pupils {
            ticker.tween(0.55, ease: Ease.linear, step: { [weak pupil] t in
                let a = t * 2 * Float.pi
                pupil?.position = rest + SIMD3<Float>(sin(a) * 0.0022,
                                                      (cos(a) - 1) * 0.0022, 0)
            }, done: { [weak pupil] in pupil?.position = rest })
        }
    }

    // MARK: - Otto's eyes are alive

    /// Every few seconds Otto blinks or glances somewhere. Purely cosmetic —
    /// it never gates anything — but still eyes are dead eyes, and he is the
    /// one prop with a face pointed at her for the whole round.
    private func startEyeLife() {
        ticker.cancel(eyeLifeJob)
        var wait = Float.random(in: 2.0...4.0)
        eyeLifeJob = ticker.add { [weak self] dt in
            guard let self else { return false }
            wait -= dt
            if wait <= 0 {
                wait = Float.random(in: 3.0...6.5)
                if let oven = self.oven {
                    Bool.random() ? self.blink(oven) : self.glance(oven)
                }
            }
            return true
        }
    }

    /// Both pupils drift to the same random spot, hold it for a beat, and
    /// come back. Small on purpose: the offset keeps the pupil well inside
    /// the eyeball (0.008 radius, pupil 0.004), so it reads as a look, not
    /// an escape attempt.
    private func glance(_ oven: KitchenProps.Oven) {
        let rest = oven.pupilRest
        let offset = SIMD3<Float>(Float.random(in: -0.0022...0.0022),
                                  Float.random(in: -0.0012...0.0012), 0)
        for pupil in oven.pupils {
            ticker.tween(0.15, ease: Ease.out, step: { [weak pupil] t in
                pupil?.position = rest + offset * t
            })
        }
        ticker.after(0.85) { [weak self] in
            guard let self, let oven = self.oven else { return }
            for pupil in oven.pupils {
                let from = pupil.position
                self.ticker.tween(0.15, ease: Ease.out, step: { [weak pupil] t in
                    pupil?.position = from + (rest - from) * t
                }, done: { [weak pupil] in pupil?.position = rest })
            }
        }
    }

    // MARK: - The idle nudge

    /// After ~25 s of nothing the thing she needs shimmers; after ~45 s Nina
    /// says one short line; then it goes quiet for a minute. It never nags, and
    /// it never blocks anything (`GAMEPLAY.md` §7).
    private func startIdleWatch() {
        ticker.cancel(idleJob)
        idleJob = ticker.add { [weak self] dt in
            guard let self else { return false }
            self.idleTime += dt
            if self.nudgeStage == 0 && self.idleTime > 25 {
                self.nudgeStage = 1
                self.showHint()
            } else if self.nudgeStage == 1 && self.idleTime > 45 {
                self.nudgeStage = 2
                // Alternating means the second time she goes quiet in the same
                // step she does not hear the same instruction again — she just
                // says she is still there. It never repeats twice in a row.
                self.voice.say(self.alternateNudge ? Line.stil
                                                   : self.nudgeLine(for: self.state.step),
                               priority: .low)
                self.alternateNudge.toggle()
            } else if self.nudgeStage == 2 && self.idleTime > 105 {
                // A minute of quiet, then it may start over.
                self.nudgeStage = 0
                self.idleTime = 0
                self.stopHint()
            }
            return true
        }
    }

    private func resetIdle() {
        idleTime = 0
        nudgeStage = 0
        stopHint()
    }

    private func showHint() {
        guard let entity = hintTarget(for: state.step) else { return }
        hintEntity = entity
        hintScale = entity.scale
        hintJob = ticker.shimmer(entity)
    }

    private func stopHint() {
        guard hintJob != nil else { return }
        ticker.stopShimmer(hintJob, on: hintEntity, restoring: hintScale)
        hintJob = nil
        hintEntity = nil
    }

    private func hintTarget(for step: KitchenStep) -> Entity? {
        switch step {
        case .uitrollen: return rollingPin
        case .vullen: return tokens.indices.contains(state.nextIndex)
            ? tokens[state.nextIndex].entity : nil
        case .roeren: return spoon
        case .gieten: return bowl
        case .inOven: return tin?.root
        case .bakken: return oven?.dome
        case .klaar: return cake
        }
    }

    private func nudgeLine(for step: KitchenStep) -> String {
        switch step {
        case .uitrollen: return Line.uitrollen
        case .vullen: return state.nextSource?.lineID ?? Line.doeInKom
        case .roeren: return Line.roeren
        case .gieten: return Line.gieten
        case .inOven: return Line.naarOtto
        case .bakken: return Line.klopOpOtto
        case .klaar: return Line.opDePlank
        }
    }

    /// **The plank brightens once there is a cake to put on it.**
    ///
    /// This is the destination half of the round's last instruction: the cake
    /// glows because it is what she picks up, and the plank glows because it is
    /// where it goes. Two lit things at once is the exception the rest of the
    /// game does not make — every other step lights exactly one prop — and it
    /// is allowed here because the step is a journey and a journey has two ends.
    ///
    /// It pulses in counter-phase to `Halo`'s 2.4 rad/s breathing, so the two
    /// take turns rather than beating against each other.
    private func setPlankInviting(_ inviting: Bool) {
        guard let plank = cakePlank else { return }
        ticker.cancel(plankGlowJob)
        plankGlowJob = nil
        guard inviting else {
            plank.model?.materials = [Palette.material(Palette.rose)]
            return
        }
        var elapsed: Float = .pi / 2.4    // half a cycle behind the cake's halo
        var lastStep = -1
        plankGlowJob = ticker.add { [weak plank] dt in
            guard let plank else { return false }
            elapsed += dt
            let wave = 0.5 + 0.5 * sin(elapsed * 2.4)
            let step = Int(wave * 10)
            guard step != lastStep else { return true }
            lastStep = step
            let t = Float(step) / 10
            plank.model?.materials = [
                Palette.glowMaterial(Palette.mix(Palette.rose, Palette.white, 0.30 * t),
                                     intensity: 1.0 + 3.0 * t)
            ]
            return true
        }
    }

    // MARK: - Housekeeping

    /// What she hears when the room appears.
    ///
    /// At the very top of a round that is: hello, then **what we are doing
    /// today** — "meng alle toverdingetjes in de kom, en zet de taart daarna in
    /// de oven" — and then the first step. Coming back to a round already in
    /// progress skips all that and just says where she was.
    func greet() {
        let atTheTop = state.step == .uitrollen && state.roll == 0
        // **Coming back to a finished kitchen is greeted as one.** Three cakes
        // are already on the plank and the door is already standing open with a
        // ring at its foot; opening on "let's mix everything in the bowl" would
        // ignore the room she is looking at. Mid-round it still says where she
        // was — a half-stirred bowl is a better thing to be reminded of than a
        // door.
        if roomComplete && atTheTop {
            voice.say([Line.hallo, Line.kamerKlaar], gap: 0.35)
            return
        }
        guard atTheTop else {
            voice.say(nudgeLine(for: state.step))
            return
        }
        voice.say([Line.hallo, Line.opdracht, Line.uitrollen], gap: 0.35)
    }

    func save() {
        RoundStore.save(state)
    }

    /// Debug panel. The player-facing version is `restartRound`, which also
    /// says so out loud — and clears the plank for the same reason this does.
    func resetRound() {
        state = RoundStore.reset()
        build(flat: flat)
    }

    func refreshContactShadows(settings: LightingSettings) {
        self.settings = settings
        carrier.update(settings: settings)
        let props: [Entity?] = [bowl, tin?.root, cake, rollingPin, basket, flourSack, crate]
            + tokens.map { $0.entity as Entity? }
        for prop in props.compactMap({ $0 }) {
            guard prop.isEnabled else { continue }
            let radius: Float
            if prop === bowl { radius = 0.030 }
            else if prop === flourSack { radius = 0.024 }
            else if prop === crate { radius = 0.026 }
            else { radius = 0.016 }
            ContactShadows.attach(to: prop, radius: radius, settings: settings)
            // Ask the room what is under it rather than guessing from height:
            // props now sit on four different surfaces and move between them.
            ContactShadows.update(for: prop, surfaceY: Layout.surfaceY(at: prop.position),
                                  settings: settings)
        }
    }

    private func cancelEverything() {
        for job in bakeJobs { ticker.cancel(job) }
        bakeJobs.removeAll()
        baking = false
        for job in blinkJobs { ticker.cancel(job) }
        blinkJobs.removeAll()
        for job in sinkJobs { ticker.cancel(job) }
        sinkJobs.removeAll()
        ticker.cancel(plankGlowJob)
        plankGlowJob = nil
        ticker.cancel(idleJob)
        idleJob = nil
        ticker.cancel(eyeLifeJob)
        eyeLifeJob = nil
        ticker.cancel(doorSwing)
        doorSwing = nil
        doorRest = 0
        doorMarker = nil
        doorTouchSpot = nil
        Halo.remove(doorHalo, ticker: ticker)
        doorHalo = nil
        clearHalo()
        baker?.stop()
        baker = nil
        stopHint()
        endCarry()
        missCount = 0
        missStep = nil
        stirLastAngle = nil
        stirLastPoint = nil
        rollLastPoint = nil
        rollTickAccumulator = 0
        dough = nil
        tinBase = nil
        ingredientPot = nil
        crate = nil
        cakePlank = nil
    }

    // MARK: - GameRoom

    /// **Give everything back**, so the room can be swapped for another one.
    ///
    /// `cancelEverything` was already the complete list of what this room holds
    /// on the `Ticker` — it had to be, because `build` calls it on every rebuild
    /// — so leaving is that list plus the two things a rebuild did not need to
    /// undo: the touch targets, and the entity tree itself.
    func teardown() {
        save()
        cancelEverything()
        touch.removeAll()
        touch.onEmptyTap = nil
        touch.onAnyTouch = nil
        root.children.removeAll()
        root.removeFromParent()
    }

    /// During a session with Nina, the step and what is in the bowl is the
    /// difference between "she ignored it" and "she never got there".
    var debugLines: [String] {
        ["Step: \(state.step.rawValue)",
         "Bowl: \(state.inBowl.map(\.rawValue).joined(separator: ", "))",
         "Stir: \(Int(state.stir * 100))%  ·  Plank: \(state.shelf.count)"]
    }
}
