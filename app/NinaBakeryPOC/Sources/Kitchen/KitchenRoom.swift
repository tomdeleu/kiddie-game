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
final class KitchenRoom {

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
    private var whisk: Entity?
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
    private var cakePlank: ModelEntity?
    private var flourPatches: [Entity] = []
    private var baker: BakerCharacter?
    private var dough: ModelEntity?
    private var tinBase: ModelEntity?
    private var ingredientPot: ModelEntity?
    /// The glow on whatever she needs next: the job driving it, the prop it is
    /// on, and that prop's own materials so they can be put back exactly.
    private var haloJob: Int?
    private weak var haloed: Entity?
    private var haloedMaterials: [[RealityKit.Material]] = []

    // Interaction. Carrying is four numbers rather than one because a carried
    // prop now has a height of its own — see `carry(to:)`.
    private var carried: Entity?
    private var carryOffset = SIMD3<Float>.zero
    private var carryJob: Int?
    /// Where the prop is now, and where it wants to be. The gap between them,
    /// closed a little every frame, is the whole height animation.
    private var carryY: Float = 0
    private var carryGoalY: Float = 0
    /// What it is currently over, for the contact shadow.
    private var carrySurfaceY: Float = Layout.tableTopY
    /// Exactly where the prop was when she took hold of it, so a touch that
    /// went nowhere can put it back exactly — see `settle`.
    private var carryOrigin = SIMD3<Float>.zero

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
    private var bakeJobs: [Int] = []
    private var lastSavedStir: Float = 0
    private var lastBatterMix: Float = -1
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
    /// goes in the bowl. 0.06 m is about a third of the table.
    private let snapRadius: Float = 0.062

    init(ticker: Ticker, touch: TouchRouter, voice: VoiceBank,
         sound: SoundKit, settings: LightingSettings) {
        self.ticker = ticker
        self.touch = touch
        self.voice = voice
        self.sound = sound
        self.settings = settings
        self.state = RoundStore.load()
        root.name = "Kitchen"
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
        ball.position = Layout.doughSpot + [0, 0.012, 0]
        root.addChild(ball)
        dough = ball
        ContactShadows.attach(to: ball, radius: 0.014, settings: settings)

        let bowlNode = KitchenProps.mixingBowl(flat: flat)
        bowlNode.position = Layout.bowlHome
        root.addChild(bowlNode)
        bowl = bowlNode
        ContactShadows.attach(to: bowlNode, radius: 0.030, settings: settings)
        refreshBowlBatter(animated: false)

        let whiskNode = KitchenProps.whisk(flat: flat)
        whiskNode.position = Layout.whiskHome + [0, 0.006, 0]
        // Resting on the table it lies over; standing in the bowl it is upright.
        whiskNode.orientation = simd_quatf(angle: .pi / 2.2, axis: [1, 0, 0])
        root.addChild(whiskNode)
        whisk = whiskNode

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
        ContactShadows.attach(to: box, radius: 0.026, settings: settings)
        ContactShadows.update(for: box, surfaceY: Layout.floorY, settings: settings)

        cakePlank = root.findEntity(named: "CakePlankBoard") as? ModelEntity
    }

    private func buildDoorway() {
        let node = KitchenProps.doorway(flat: flat)
        root.addChild(node.root)
        doorway = node
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

    private func registerTargets() {
        for (index, token) in tokens.enumerated() {
            let source = Layout.Source(rawValue: index) ?? .mandje
            touch.register("token\(index)", entity: token.entity,
                           radius: 0.030, planeY: source.planeY) { target in
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

        touch.register("bowl", entity: bowl, radius: 0.045,
                       planeY: Layout.tableTopY + 0.020) { target in
            target.tracksEntity = true
            target.planeOffset = 0.020
            target.onDragBegan = { [weak self] world in self?.bowlTouchBegan(world) }
            target.onDragMoved = { [weak self] world in self?.bowlTouchMoved(world) }
            target.onDragEnded = { [weak self] world in self?.bowlTouchEnded(world) }
        }

        touch.register("tin", entity: tin?.root, radius: 0.034,
                       planeY: Layout.tableTopY) { target in
            target.tracksEntity = true
            target.onDragBegan = { [weak self] world in
                guard let self, let tin = self.tin else { return }
                self.pickUp(tin.root, at: world)
            }
            target.onDragMoved = { [weak self] world in self?.carry(to: world) }
            target.onDragEnded = { [weak self] world in self?.dropTin(at: world) }
        }

        touch.register("otto", entity: oven?.root, radius: 0.070,
                       planeY: Layout.floorY) { target in
            target.onTap = { [weak self] in self?.tapOtto() }
        }

        touch.register("doorway", entity: doorway?.root, radius: 0.050,
                       planeY: Layout.floorY) { target in
            target.onTap = { [weak self] in self?.tapDoorway() }
        }

        touch.register("cake", entity: nil, radius: 0.040,
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
        // The sack is on the floor now, and big — a 60 mm target on a prop she
        // has to reach down for.
        touch.register("flour", entity: flourSack, radius: 0.045,
                       planeY: Layout.floorY) { target in
            target.onTap = { [weak self] in self?.tapFlour() }
        }
        touch.register("sink", entity: sink?.root, radius: 0.030,
                       planeY: Layout.counterTopY) { target in
            target.onTap = { [weak self] in self?.tapSink() }
        }
        touch.register("scale", entity: scaleProp?.root, radius: 0.030,
                       planeY: Layout.counterTopY) { target in
            target.onTap = { [weak self] in self?.tapScale() }
        }
        touch.register("crate", entity: crate, radius: 0.034,
                       planeY: Layout.floorY) { target in
            target.onTap = { [weak self] in
                guard let self, let crate = self.crate else { return }
                self.ticker.squash(crate, amount: 0.12)
                self.sound.playVaried(.thud, volume: 0.5)
            }
        }
        touch.register("rollingPin", entity: rollingPin, radius: 0.032,
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
            }
        }
        // The six jars on the two wall shelves.
        for height in [150, 105] {
            for i in 0..<3 {
                let name = "Jar\(height)_\(i)"
                guard let jar = root.findEntity(named: name) else { continue }
                touch.register(name, entity: jar, radius: 0.022,
                               planeY: Float(height) / 1000) { target in
                    target.onTap = { [weak self] in self?.tapJar(jar) }
                }
            }
        }
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
        refreshHalo()
    }

    /// Put the currently lit prop back to its own colours.
    ///
    /// Called before lighting anything else, and directly by `bake()` — once
    /// she has tapped Otto the cue has done its job, and two things writing to
    /// the same material every frame is a fight nobody wins.
    private func clearHalo() {
        ticker.cancel(haloJob)
        haloJob = nil
        if let haloed {
            Halo.remove(from: haloed, restoring: haloedMaterials)
        }
        haloed = nil
        haloedMaterials = []
    }

    /// Light up whatever she needs next, and nothing else.
    private func refreshHalo() {
        clearHalo()
        guard let target = haloTarget(), target.isEnabled else { return }
        haloed = target
        haloedMaterials = Halo.materials(of: target)
        haloJob = Halo.attach(to: target, radius: haloRadius(for: target), ticker: ticker)
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
        if entity === doorway?.root { return 0.055 }
        if entity === cake { return 0.030 }
        return 0.018
    }

    // MARK: - Step presentation

    private func applyStep(animated: Bool) {
        guard let oven, let whisk, let tin else { return }

        // The whisk: on the table until she needs it, standing in the bowl
        // while she stirs, back on the table once the batter is done.
        // Off the bowl's *live* position, not `Layout.bowlHome`: the bowl can be
        // carried anywhere now, and a whisk that stands where the bowl used to
        // be is a whisk standing in mid-air.
        let stirring = state.step == .roeren
        let whiskTarget = stirring
            ? (bowl?.position ?? Layout.bowlHome) + [0, 0.030, 0]
            : Layout.whiskHome + [0, 0.006, 0]
        let whiskTilt = stirring ? simd_quatf(angle: 0, axis: [0, 1, 0])
                                 : simd_quatf(angle: .pi / 2.2, axis: [1, 0, 0])
        if animated {
            ticker.move(whisk, to: whiskTarget, duration: 0.4)
            whisk.orientation = whiskTilt
        } else {
            whisk.position = whiskTarget
            whisk.orientation = whiskTilt
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

        // Otto's door: open when he is waiting to be loaded, shut otherwise.
        setDoor(open: state.step == .inOven, animated: animated, oven: oven)

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
        dough.position = Layout.doughSpot + [0, 0.012 * (1 - 0.6 * t), 0]
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
            return
        }

        // Cream at first and her colour by the end of stirring — the batter
        // "takes its colour as she goes" (GAMEPLAY.md §6.3).
        let mix = 0.35 + 0.65 * min(1, state.stir)
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
        // Stirring calls this on every touch event. Rebuilding a material 60
        // times a second to move a colour by nothing is the kind of waste that
        // only shows up as a warm iPad, so it steps rather than slides.
        if fresh || abs(mix - lastBatterMix) > 0.02 {
            lastBatterMix = mix
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

    /// Pick something up.
    private func pickUp(_ entity: Entity, at world: SIMD3<Float>) {
        endCarry()
        carried = entity
        carryOffset = entity.position - world
        carryOffset.y = 0
        carryOrigin = entity.position
        carryY = entity.position.y
        carrySurfaceY = Layout.surfaceY(at: entity.position)
        carryGoalY = carryY
        stopHint()
        ticker.squash(entity, amount: 0.14, duration: 0.25)
        sound.play(.stirTick, volume: 0.4)

        // One job for the whole drag, rather than easing inside the touch
        // callback: touch events stop arriving the moment her finger stops
        // moving, and a prop halfway down to the floor has to keep going.
        //
        // **The drag plane is fixed for the whole drag, and that is the fix for
        // a bug worth remembering.** It used to be written down here every
        // frame — `carryTarget.planeY = carryY` — so that the prop stayed
        // pinned under her fingertip as it changed height. That is a feedback
        // loop, because the height depends on the XZ and the XZ depends on the
        // plane: raising the plane by Δ moves the ray's intersection about
        // 1.7Δ towards the camera at this camera angle, which can move the prop
        // straight back out of the region that raised it.
        //
        // The cake going up onto the plank is where it bit. Reaching the plank
        // zone lifted the cake 67 mm, which slid the mapped point ~70 mm
        // forwards, out of the zone; it dropped back to the counter, which slid
        // the point back in, and it juddered between the two. It could not be
        // put on the plank at all — it stuck on the counter underneath it.
        //
        // With the plane fixed, XZ is a pure function of her finger and cannot
        // oscillate. The prop drifts up or down *on screen* relative to her
        // finger as it changes surface, which turns out to read better anyway:
        // vertical movement against a still fingertip is the clearest possible
        // way of saying "this is on the floor now".
        carryJob = ticker.add { [weak self] dt in
            guard let self, let held = self.carried else { return false }
            // Exponential ease — about 90% of the remaining gap in a third of
            // a second, whatever the frame rate, and no overshoot.
            self.carryY += (self.carryGoalY - self.carryY) * (1 - exp(-dt * 7.5))
            held.position.y = self.carryY
            ContactShadows.update(for: held, surfaceY: self.carrySurfaceY,
                                  settings: self.settings)
            return true
        }
    }

    /// **The height rule.** A carried prop rides just above whatever is
    /// underneath it, and eases there rather than jumping.
    ///
    /// Everything used to be carried at table height regardless of where it
    /// was, which is why the room read flat: drag the rolling pin off the table
    /// and it stayed at table height, hanging in mid-air over the floor with
    /// nothing to say it was up there. Now it comes down, over about a third of
    /// a second, and going back up onto the table lifts it again.
    private func carry(to world: SIMD3<Float>) {
        guard let carried else { return }
        var next = Layout.clampToPlayArea(world + carryOffset)
        carrySurfaceY = surfaceUnder(next, for: carried)
        carryGoalY = carrySurfaceY + Layout.carryLift
        // Y is owned by the carry job; the touch only ever moves it about.
        next.y = carryY
        carried.position = next
    }

    /// What the carried prop is over. The cake is the one prop that can also be
    /// over the wall plank, which is where the round now ends.
    private func surfaceUnder(_ point: SIMD3<Float>, for entity: Entity) -> Float {
        if entity === cake, Layout.nearPlank(point) { return Layout.cakePlankY + 0.004 }
        return Layout.surfaceY(at: point)
    }

    private func endCarry() {
        ticker.cancel(carryJob)
        carryJob = nil
        carried = nil
    }

    /// **A drop that did not do anything in particular. It stays where she put
    /// it.**
    ///
    /// This replaced `floatHome`, which sent a missed drop back to where it
    /// came from and had Nina apologise for it. That was wrong twice over. It
    /// took the room away from her — the one thing she can do with a kitchen
    /// full of objects is move them around, and every attempt was being undone
    /// half a second later. And it made a miss into an *event*, with a sound
    /// and a line about it, when most misses are not attempts at anything: she
    /// picked up the rolling pin and put it on the floor, which is a thing a
    /// 4-year-old does to a rolling pin.
    ///
    /// So a prop now settles onto whatever is beneath it and simply stays
    /// there. `missed` is the narrow case that is still worth answering: she
    /// was working on the current step and it did not take.
    private func settle(_ entity: Entity, missed: Bool) {
        let origin = carryOrigin
        endCarry()

        // **A touch that went nowhere puts it back exactly.** This is what
        // stops a tap on the top shelf knocking the berry off it: every tap is
        // also a zero-length drag (`TouchRouter.ended`), and without this the
        // berry would obediently fall to the floor because that is what is
        // under the shelf. A grab she thought better of gets the same answer.
        guard Layout.distanceXZ(entity.position, origin) > 0.010 else {
            ticker.move(entity, to: origin, duration: 0.16, arc: 0, ease: Ease.out) {
                [weak self] in
                guard let self else { return }
                ContactShadows.update(for: entity, surfaceY: Layout.surfaceY(at: origin),
                                      settings: self.settings)
            }
            return
        }

        let resting = SIMD3<Float>(entity.position.x,
                                   Layout.surfaceY(at: entity.position),
                                   entity.position.z)
        ticker.move(entity, to: resting, duration: 0.20, arc: 0, ease: Ease.out) {
            [weak self] in
            guard let self else { return }
            self.sound.play(.thud, volume: 0.42)
            ContactShadows.update(for: entity, surfaceY: resting.y, settings: self.settings)
        }
        if missed { noteMiss() }
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

    private func nudgeToken(_ index: Int) {
        guard index < tokens.count else { return }
        ticker.squash(tokens[index].entity, amount: 0.25)
        sound.playVaried(.plop, volume: 0.5)
        // Tapping one whose turn it is not still does something, and what it
        // says is where to look instead.
        voice.say(index == state.nextIndex ? Line.doeInKom : Line.pakGlimmend,
                  priority: .low)
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
            self.voice.say(token.ingredient.lineID)
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
        voice.say(Line.roeren)
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
        guard state.step != .roeren else {
            stirLastAngle = nil
            stirLastPoint = nil
            return
        }
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
        guard let whisk else { return }
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

        // The whisk follows her finger, held inside the bowl.
        let centre = bowl?.position ?? Layout.bowlHome
        var offset = SIMD3<Float>(world.x - centre.x, 0, world.z - centre.z)
        let reach = simd_length(SIMD2<Float>(offset.x, offset.z))
        if reach > 0.016 { offset *= 0.016 / reach }
        whisk.position = centre + offset + [0, 0.030, 0]

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
        voice.say(Line.beslagKlaar)
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

    private func pour(bowl: ModelEntity, tin: KitchenProps.Tin) {
        // Entities, not the struct, because these get captured weakly below.
        let tinRoot = tin.root
        let tinBatter = tin.batter
        let above = tinRoot.position + [0, 0.030, 0]

        ticker.move(bowl, to: above, duration: 0.3, arc: 0.01) { [weak self] in
            guard let self else { return }
            self.sound.play(.pour)

            // Tip it. The batter goes with the bowl until it is gone.
            let tipped = simd_quatf(angle: -1.15, axis: [0, 0, 1])
            self.ticker.tween(0.45, ease: Ease.inOut, step: { [weak bowl] t in
                bowl?.orientation = simd_slerp(simd_quatf(angle: 0, axis: [0, 0, 1]), tipped, t)
            }, done: { [weak self] in
                guard let self else { return }
                self.bowlBatter?.removeFromParent()
                self.bowlBatter = nil

                // The tin fills.
                tinBatter.isEnabled = true
                tinBatter.model?.materials = [Palette.material(self.state.bowlSpec.batterColour)]
                tinBatter.scale = [1, 0.05, 1]
                self.ticker.tween(0.5, ease: Ease.out, step: { [weak tinBatter] t in
                    tinBatter?.scale = SIMD3<Float>(1, 0.05 + 0.95 * t, 1)
                })
                Sparkles.ring(at: tinRoot.position + [0, 0.012, 0], in: self.root,
                              ticker: self.ticker,
                              colour: self.state.bowlSpec.batterColour, radius: 0.04)

                // And the bowl goes back where it lives.
                self.ticker.after(0.35) { [weak self] in
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
                self.voice.say([Line.gegoten, Line.ottoWacht])
            })
        }
    }

    // MARK: - Step 4: into Otto

    private func dropTin(at world: SIMD3<Float>) {
        guard let tin, let oven else { return }
        endCarry()
        // Otto only takes it once it has batter in it. Before that she can
        // carry the tin around all she likes and put it down anywhere.
        guard state.step == .inOven,
              Layout.distanceXZ(tin.root.position, Layout.ovenMouth) <= 0.075 else {
            settle(tin.root, missed: state.step == .inOven)
            return
        }
        noteHit()

        // In it goes, and out of sight — an oven you can see into is not an
        // oven, and hiding it is what makes the door opening worth watching.
        let mouth = Layout.ovenMouth
        let tinRoot = tin.root
        ticker.move(tinRoot, to: mouth, duration: 0.3, arc: 0.01) { [weak self] in
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
                self.voice.say(Line.ottoVormErin)
                self.ticker.after(3.0) { [weak self] in
                    guard let self, self.state.step == .bakken else { return }
                    self.voice.say(Line.klopOpOtto, priority: .low)
                }
            })
        }
    }

    // MARK: - Step 5: baking

    private func tapOtto() {
        guard let oven else { return }
        ticker.squash(oven.dome, amount: 0.16)
        blink(oven)
        guard state.step == .bakken else {
            // Otto is a toy the rest of the time, and says something different
            // every single time she pokes him.
            sound.playVaried(.thud, volume: 0.4)
            voice.say(Line.ottoTik)
            return
        }
        bake(oven: oven)
    }

    private func bake(oven: KitchenProps.Oven) {
        clearHalo()
        let spec = state.bowlSpec
        let dome = oven.dome
        let door = oven.door
        let chimneyTop = oven.chimneyTop
        voice.say(Line.ottoBakken)
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
            self.voice.say([Line.ottoKlaar] + spec.reactionLines + [Line.opDePlank])
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
        ticker.squash(cake, amount: 0.20)
        sound.play(.sparkle, volume: 0.6)
        Sparkles.burst(at: cake.position + [0, 0.04, 0], in: root, ticker: ticker, count: 6)
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

    /// Onto the plank, and a fresh round behind it.
    private func placeOnPlank(_ cake: Entity, spec: CakeSpec) {
        var shelf = state.shelf
        shelf.append(spec)
        if shelf.count > Layout.cakeShelfCapacity { shelf.removeFirst() }

        let slot = shelfSlot(min(shelf.count - 1, Layout.cakeShelfCapacity - 1))
        ContactShadows.removeFrom(cake)
        clearHalo()
        setPlankInviting(false)
        // Shrinks to plank size as it goes, which is what makes four of them
        // fit on a 13 cm board.
        ticker.tween(0.7, ease: Ease.inOut, step: { [weak cake] t in
            cake?.scale = SIMD3<Float>(repeating: 1 - 0.38 * t)
        })
        ticker.move(cake, to: slot, duration: 0.7, arc: 0.03, ease: Ease.out) { [weak self] in
            guard let self else { return }
            self.sound.play(.sparkle, volume: 0.7)
            Sparkles.burst(at: slot + [0, 0.02, 0], in: self.root, ticker: self.ticker, count: 10)
            self.startNewRound(shelf: shelf)
        }
        baker?.set(.cheering)
        voice.say(Line.klaar)
        self.cake = nil
        touch.target(named: "cake")?.enabled = false
    }

    /// The doorway. **Still not a door** — see `app/README.md`. It no longer
    /// ends the round either, now that the cake going up on the plank does
    /// that, so it is a prop that whooshes and says what is happening. When the
    /// decorating room lands this is still the one function to change.
    private func tapDoorway() {
        guard let doorway else { return }
        sound.play(.whoosh)
        ticker.squash(doorway.root, amount: 0.10, duration: 0.35)
        voice.say(nudgeLine(for: state.step), priority: .low)
    }

    private func startNewRound(shelf: [CakeSpec]) {
        state = RoundState.fresh(keeping: shelf)
        RoundStore.save(state)
        build(flat: flat)
        ticker.after(0.8) { [weak self] in
            self?.voice.say([Line.opdracht, Line.uitrollen], gap: 0.35)
        }
    }

    /// The restart button. Throws this round away and starts a fresh one,
    /// keeping the cakes already on the plank — nothing she has finished is
    /// ever lost, so pressing it can never be a disaster.
    func restartRound() {
        let shelf = state.shelf
        sound.play(.whoosh, volume: 0.6)
        Sparkles.burst(at: Layout.bowlHome + [0, 0.04, 0], in: root, ticker: ticker,
                       colour: Palette.mintLight, count: 10)
        state = RoundState.fresh(keeping: shelf)
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
        ticker.squash(flourSack, amount: 0.24)
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
        if Int.random(in: 0..<3) == 0 { voice.say(Line.bloem, priority: .low) }
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
            let over = Layout.distanceXZ(rollingPin.position, dough.position) < 0.030
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
            self.voice.say(Line.deegKlaar)

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

    private func blink(_ oven: KitchenProps.Oven) {
        for eye in oven.eyes {
            let base = eye.scale
            ticker.tween(0.22, ease: Ease.linear, step: { [weak eye] t in
                let squeeze = 1 - sin(t * .pi) * 0.85
                eye?.scale = SIMD3<Float>(base.x, base.y * squeeze, base.z)
            }, done: { [weak eye] in eye?.scale = base })
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
        case .roeren: return whisk
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
        guard state.step == .uitrollen, state.roll == 0 else {
            voice.say(nudgeLine(for: state.step))
            return
        }
        voice.say([Line.hallo, Line.opdracht, Line.uitrollen], gap: 0.35)
    }

    func save() {
        RoundStore.save(state)
    }

    /// Debug panel. The player-facing version is `restartRound`, which also
    /// says so out loud.
    func resetRound() {
        state = RoundStore.reset(keepingShelf: state.shelf)
        build(flat: flat)
    }

    func refreshContactShadows(settings: LightingSettings) {
        self.settings = settings
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
        for job in sinkJobs { ticker.cancel(job) }
        sinkJobs.removeAll()
        ticker.cancel(plankGlowJob)
        plankGlowJob = nil
        ticker.cancel(idleJob)
        idleJob = nil
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
}
