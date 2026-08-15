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
    private var tokens: [(ingredient: Ingredient, entity: ModelEntity, home: SIMD3<Float>)] = []
    private var cake: Entity?
    private var shelfCakes: [Entity] = []
    private var sink: KitchenProps.Sink?
    private var scaleProp: KitchenProps.Scale?
    private var flourSack: Entity?
    private var rollingPin: Entity?
    private var doorway: KitchenProps.Doorway?
    private var flourPatches: [Entity] = []
    private var baker: BakerCharacter?
    private var dough: ModelEntity?
    private var tinBase: ModelEntity?
    private var ingredientPot: ModelEntity?
    /// The glowing ring on whatever she needs next, and what it is on.
    private var haloJob: Int?
    private weak var haloed: Entity?

    // Interaction.
    private var carried: Entity?
    private var carryOffset = SIMD3<Float>.zero
    private var stirLastAngle: Float?
    private var stirLastPoint: SIMD3<Float>?
    private var stirTickAccumulator: Float = 0
    private var saidGoodStirring = false
    private var doorGlowJob: Int?
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

        // **One ingredient per source, in order.** Token *i* stands where
        // source *i* is — shelf, then counter, then basket — and the ones she
        // has already used are simply not built.
        for (i, ingredient) in state.basket.enumerated() {
            guard let source = Layout.Source(rawValue: i) else { continue }
            let token = KitchenProps.token(ingredient, flat: flat)
            let home = source.spot
            token.position = home
            token.name = "Token\(i)_\(ingredient.rawValue)"
            token.isEnabled = i >= state.nextIndex
            root.addChild(token)
            tokens.append((ingredient, token, home))
            if source == .mandje {
                ContactShadows.attach(to: token, radius: 0.011, settings: settings)
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

        let sack = KitchenProps.flourSack(flat: flat)
        sack.position = Layout.flourSpot
        root.addChild(sack)
        flourSack = sack
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
                target.onDragBegan = { [weak self] world in self?.pickUp(token.entity, at: world) }
                target.onDragMoved = { [weak self] world in self?.carry(to: world) }
                target.onDragEnded = { [weak self] world in
                    self?.dropToken(index: index, at: world)
                }
                target.onTap = { [weak self] in self?.nudgeToken(index) }
            }
        }

        touch.register("bowl", entity: bowl, radius: 0.045,
                       planeY: Layout.tableTopY + 0.020) { target in
            target.onDragBegan = { [weak self] world in self?.bowlTouchBegan(world) }
            target.onDragMoved = { [weak self] world in self?.bowlTouchMoved(world) }
            target.onDragEnded = { [weak self] world in self?.bowlTouchEnded(world) }
        }

        touch.register("tin", entity: tin?.root, radius: 0.034,
                       planeY: Layout.tableTopY) { target in
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
        touch.register("flour", entity: flourSack, radius: 0.030,
                       planeY: Layout.counterTopY) { target in
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
        touch.register("rollingPin", entity: rollingPin, radius: 0.032,
                       planeY: Layout.tableTopY) { target in
            target.onDragBegan = { [weak self] world in self?.rollBegan(at: world) }
            target.onDragMoved = { [weak self] world in self?.roll(to: world) }
            target.onDragEnded = { [weak self] _ in
                self?.carried = nil
                self?.rollLastPoint = nil
                self?.sound.play(.thud, volume: 0.35)
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
        // Only the ingredient whose turn it is can be dragged. The others are
        // still there, still tappable, still answer with a wobble — they just
        // do not travel out of turn, which is what makes "in a specific order"
        // a rule she can feel rather than one she can break.
        for index in tokens.indices {
            touch.target(named: "token\(index)")?.enabled =
                state.step == .vullen && index == state.nextIndex
        }
        touch.target(named: "bowl")?.enabled = state.step == .roeren || state.step == .gieten
        touch.target(named: "tin")?.enabled = state.step == .inOven
        touch.target(named: "cake")?.entity = cake
        touch.target(named: "cake")?.enabled = cake != nil
        refreshHalo()
    }

    /// Light up whatever she needs next, and nothing else.
    private func refreshHalo() {
        ticker.cancel(haloJob)
        haloJob = nil
        if let haloed { Halo.remove(from: haloed) }
        haloed = nil

        guard let target = haloTarget(), target.isEnabled else { return }
        haloed = target
        haloJob = Halo.attach(to: target, radius: haloRadius(for: target),
                              ticker: ticker, yOffset: haloOffset(for: target))
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
        case .klaar: return doorway?.root
        }
    }

    private func haloRadius(for entity: Entity) -> Float {
        if entity === rollingPin { return 0.030 }
        if entity === bowl { return 0.038 }
        if entity === tin?.root { return 0.028 }
        if entity === oven?.root { return 0.070 }
        if entity === doorway?.root { return 0.045 }
        return 0.018
    }

    /// Where each prop meets the thing it is standing on, in its own space.
    private func haloOffset(for entity: Entity) -> Float {
        // The pin's origin is on its axis, and a token is an icosphere centred
        // on its own middle. Everything else is built standing on its origin.
        if entity === rollingPin { return -0.008 }
        if tokens.contains(where: { $0.entity === entity }) { return -0.0095 }
        return 0.0008
    }

    // MARK: - Step presentation

    private func applyStep(animated: Bool) {
        guard let oven, let whisk, let tin else { return }

        // The whisk: on the table until she needs it, standing in the bowl
        // while she stirs, back on the table once the batter is done.
        let stirring = state.step == .roeren
        let whiskTarget = stirring
            ? Layout.bowlHome + [0, 0.030, 0]
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
        if tin.root.isEnabled {
            tin.root.scale = SIMD3<Float>(repeating: 1)
            if carried !== tin.root { tin.root.position = Layout.tinHome }
        }

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

        setDoorwayInviting(state.step == .klaar)
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
        let inTheBowl = state.step == .vullen || state.step == .roeren || state.step == .gieten
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

    private func pickUp(_ entity: Entity, at world: SIMD3<Float>) {
        carried = entity
        carryOffset = entity.position - world
        carryOffset.y = 0
        stopHint()
        ticker.squash(entity, amount: 0.14, duration: 0.25)
        sound.play(.stirTick, volume: 0.4)
    }

    private func carry(to world: SIMD3<Float>) {
        guard let carried else { return }
        var next = world + carryOffset
        // Lifted a little, so it reads as held rather than shoved.
        next.y = Layout.tableTopY + 0.012
        carried.position = Layout.clampToPlayArea(next)
        ContactShadows.update(for: carried, surfaceY: Layout.tableTopY, settings: settings)
    }

    /// A drag that landed nowhere. It floats home, and Nina is nice about it.
    private func floatHome(_ entity: Entity, to home: SIMD3<Float>, speak: Bool = true) {
        carried = nil
        ticker.move(entity, to: home, duration: 0.45, arc: 0.012, ease: Ease.out) { [weak self] in
            guard let self else { return }
            self.sound.play(.thud, volume: 0.5)
            ContactShadows.update(for: entity, surfaceY: home.y, settings: self.settings)
        }
        if speak { voice.say(Line.oeps) }
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

    private func dropToken(index: Int, at world: SIMD3<Float>) {
        guard index < tokens.count, let bowl else { return }
        let token = tokens[index]
        carried = nil

        guard Layout.distanceXZ(token.entity.position, bowl.position) <= snapRadius else {
            floatHome(token.entity, to: token.home)
            return
        }

        // Into the bowl. The token is consumed; what is left is a colour.
        let into = bowl.position + [0, 0.014, 0]
        ticker.move(token.entity, to: into, duration: 0.28, arc: 0.02, ease: Ease.inCurve) {
            [weak self] in
            guard let self else { return }
            token.entity.isEnabled = false
            ContactShadows.removeFrom(token.entity)
            self.sound.playVaried(.plop)
            Sparkles.ring(at: into, in: self.root, ticker: self.ticker,
                          colour: token.ingredient.tokenColour, radius: 0.045)

            // The basket is never mutated — `inBowl.count` is how far she has
            // got, and it is what moves the halo to the next shelf.
            self.state.inBowl.append(token.ingredient)
            self.refreshBowlBatter(animated: true)
            self.voice.say(token.ingredient.lineID)
            self.baker?.set(.cheering)
            self.save()
            self.refreshInteractivity()

            if self.state.allCollected {
                self.ticker.after(1.1) { [weak self] in self?.beginStirring() }
            } else {
                // Point at the next place before she has to go looking.
                self.ticker.after(1.8) { [weak self] in
                    guard let self, self.state.step == .vullen else { return }
                    self.sayNextSource()
                }
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

    private func bowlTouchBegan(_ world: SIMD3<Float>) {
        switch state.step {
        case .roeren:
            stirLastAngle = angleAroundBowl(world)
            stirLastPoint = world
        case .gieten:
            guard let bowl else { return }
            pickUp(bowl, at: world)
        default:
            break
        }
    }

    private func bowlTouchMoved(_ world: SIMD3<Float>) {
        switch state.step {
        case .roeren:
            stir(to: world)
        case .gieten:
            // The batter is a child of the bowl, so it rides along for free.
            carry(to: world)
        default:
            break
        }
    }

    private func bowlTouchEnded(_ world: SIMD3<Float>) {
        switch state.step {
        case .roeren:
            stirLastAngle = nil
            stirLastPoint = nil
        case .gieten:
            dropBowl(at: world)
        default:
            break
        }
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
        carried = nil
        guard Layout.distanceXZ(bowl.position, tin.root.position) <= snapRadius else {
            floatHome(bowl, to: Layout.bowlHome)
            return
        }
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
        carried = nil
        guard Layout.distanceXZ(tin.root.position, Layout.ovenMouth) <= 0.075 else {
            floatHome(tin.root, to: Layout.tinHome)
            return
        }

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
            self.setDoorwayInviting(true)
            self.refreshInteractivity()
            // Otto first, then Nina on the colour and at most one effect.
            self.voice.say([Line.ottoKlaar] + spec.reactionLines)
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

    private func dropCake(at world: SIMD3<Float>) {
        guard let cake else { return }
        carried = nil
        ContactShadows.update(for: cake, surfaceY: Layout.tableTopY, settings: settings)
        sound.play(.thud, volume: 0.4)
    }

    /// The doorway. **Not yet a door** — see `app/README.md`. Until the
    /// decorating room exists it closes the round: the cake goes up on the
    /// plank and a fresh basket arrives.
    private func tapDoorway() {
        guard let doorway else { return }
        sound.play(.whoosh)
        ticker.squash(doorway.root, amount: 0.10, duration: 0.35)

        guard state.step == .klaar, let cake, let spec = state.cake else {
            // Mid-round: she gets told what is happening, not refused.
            voice.say(nudgeLine(for: state.step), priority: .low)
            return
        }

        var shelf = state.shelf
        shelf.append(spec)
        if shelf.count > Layout.cakeShelfCapacity { shelf.removeFirst() }

        let slot = shelfSlot(min(shelf.count - 1, Layout.cakeShelfCapacity - 1))
        ContactShadows.removeFrom(cake)
        ticker.tween(1.0, ease: Ease.inOut, step: { [weak cake] t in
            cake?.scale = SIMD3<Float>(repeating: 1 - 0.38 * t)
        })
        ticker.move(cake, to: slot, duration: 1.0, arc: 0.06) { [weak self] in
            guard let self else { return }
            self.sound.play(.sparkle, volume: 0.7)
            Sparkles.burst(at: slot + [0, 0.02, 0], in: self.root, ticker: self.ticker, count: 8)
            self.startNewRound(shelf: shelf)
        }
        voice.say(Line.klaar)
        self.cake = nil
        touch.target(named: "cake")?.enabled = false
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

    private func tapFlour() {
        guard let flourSack else { return }
        ticker.squash(flourSack, amount: 0.30)
        sound.playVaried(.poof)
        Sparkles.puff(at: flourSack.position + [0, 0.036, 0], in: root, ticker: ticker, count: 12)
        dustCounter(near: flourSack.position)
        if Int.random(in: 0..<3) == 0 { voice.say(Line.bloem, priority: .low) }
    }

    /// The handprints from `GAMEPLAY.md` §6.3, as a fading patch of flour. It
    /// stays a while and then quietly stops being there.
    private func dustCounter(near position: SIMD3<Float>) {
        let patch = RoomBuilder.model(.prism(radius: Float.random(in: 0.010...0.016),
                                             height: 0.0007, sides: 9),
                                      Palette.creamLight, flat: flat, name: "Flour")
        patch.position = [position.x + Float.random(in: -0.020...0.020),
                          Layout.counterTopY + 0.0006,
                          position.z + Float.random(in: -0.014...0.014)]
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

    private func tapSink() {
        guard let sink else { return }
        let water = sink.water
        let basinTop = sink.root.position + [0, 0.014, 0]
        water.isEnabled = true
        sound.play(.water)
        ticker.tween(0.18, ease: Ease.out, step: { [weak water] t in
            water?.scale = SIMD3<Float>(1, max(0.001, t), 1)
        })
        ticker.after(0.35) { [weak self] in
            guard let self else { return }
            Sparkles.ring(at: basinTop, in: self.root, ticker: self.ticker,
                          colour: Palette.berryBlue, radius: 0.03)
        }
        ticker.after(2.1) { [weak self] in
            guard let self else { return }
            self.ticker.tween(0.25, ease: Ease.inCurve, step: { [weak water] t in
                water?.scale = SIMD3<Float>(1, max(0.001, 1 - t), 1)
            }, done: { [weak water] in water?.isEnabled = false })
        }
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

        Halo.remove(from: dough)
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
            // And then straight into where the first ingredient lives.
            self.ticker.after(2.2) { [weak self] in
                guard let self, self.state.step == .vullen, self.state.inBowl.isEmpty else { return }
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
        case .klaar: return doorway?.root
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
        case .klaar: return Line.klaar
        }
    }

    /// The doorway brightens once the round is done. It works either way.
    private func setDoorwayInviting(_ inviting: Bool) {
        guard let doorway else { return }
        let glow = doorway.glow
        ticker.cancel(doorGlowJob)
        doorGlowJob = nil
        guard inviting else {
            glow.model?.materials = [Palette.material(Palette.cream)]
            return
        }
        var elapsed: Float = 0
        doorGlowJob = ticker.add { [weak glow] dt in
            guard let glow else { return false }
            elapsed += dt
            let pulse = 0.45 + 0.35 * (0.5 + 0.5 * sin(elapsed * 2.2))
            glow.model?.materials = [
                Palette.glowMaterial(Palette.butterYellow, intensity: pulse)
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
        let props: [Entity?] = [bowl, tin?.root, cake, rollingPin, basket]
            + tokens.map { $0.entity as Entity? }
        for prop in props.compactMap({ $0 }) {
            guard prop.isEnabled else { continue }
            let radius: Float = prop === bowl ? 0.030 : 0.016
            ContactShadows.attach(to: prop, radius: radius, settings: settings)
            let surface = prop.position.y > Layout.counterTopY + 0.004
                ? Layout.tableTopY : Layout.floorY
            ContactShadows.update(for: prop, surfaceY: surface, settings: settings)
        }
    }

    private func cancelEverything() {
        for job in bakeJobs { ticker.cancel(job) }
        bakeJobs.removeAll()
        ticker.cancel(doorGlowJob)
        doorGlowJob = nil
        ticker.cancel(idleJob)
        idleJob = nil
        ticker.cancel(haloJob)
        haloJob = nil
        haloed = nil
        baker?.stop()
        baker = nil
        stopHint()
        carried = nil
        stirLastAngle = nil
        stirLastPoint = nil
        rollLastPoint = nil
        rollTickAccumulator = 0
        dough = nil
        tinBase = nil
        ingredientPot = nil
    }
}
