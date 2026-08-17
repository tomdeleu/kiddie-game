import Foundation
import RealityKit
import simd
import CoreGraphics

/// **Versieren — the decorating room.** `GAMEPLAY.md` §6.4.
///
/// The cake sits on a turntable; seven trays wrap the two open edges of the
/// floor; a piping bag draws a line of cream and a shaker rains sprinkles. Drag
/// a sticker anywhere on the cake and it stays where she put it — no grid, no
/// snapping, no correct answer, no limit on how many.
///
/// **This room asks her for nothing**, and three things follow from that:
///
/// - **The halo has nothing to point at.** The kitchen's grammar is *one lit
///   prop, which is the next thing to do*, and a room with no required action
///   breaks it. The answer is not to invent one: the **door is lit from the
///   moment she arrives**, which says *you may go when you like* — exactly true
///   here and nowhere else in the game.
/// - **The miss machinery is not wired.** `noteMiss` is defined as *she dragged
///   the prop the current step is about and it did not land*, and there is no
///   such prop. A sticker dropped off the cake is a removal, not a failure.
/// - **The idle nudge is not an instruction.** *"Het is al zo mooi — zullen we
///   gaan?"*, never *"put something on the cake"*. There is nothing she is
///   failing to do.
@MainActor
final class VersierRoom: Room {

    let root = Entity()
    var onExit: ((RoomExit) -> Void)?

    /// `ROOMS.md` §9: one flag, not two implementations. Only the completion
    /// rule and what the door does differ.
    let mode: RoomMode

    private let ticker: Ticker
    private let touch: TouchRouter
    private let voice: VoiceBank
    private let sound: SoundKit
    private var settings: LightingSettings
    private var flat = true

    private(set) var state: VersierState

    // MARK: - Entities

    private var turntable: VersierProps.Turntable?
    /// Sibling of the cake under the spinner, **not its child** — `CakeSpec.isTall`
    /// is a 1.5× Y scale on the cake wrapper and would come out as stretched
    /// hearts. `CakeSurface` resolves `u` against the already-stretched heights,
    /// so the sticker lands right and keeps its own shape.
    private var stickerLayer: Entity?
    private var cakeNode: Entity?
    private var trays: [StickerKind: Entity] = [:]
    private var spuitzak: VersierProps.Spuitzak?
    private var strooibus: Entity?
    private var doorway: Props.Doorway?
    private var doorTouchSpot: Entity?
    private var doorHalo: Halo.Handle?
    private var doorRest: Float = 0
    private var doorSwing: Int?
    private var baker: BakerCharacter?
    private var jars: [Entity] = []
    private var glitterpot: Entity?
    private var taartborden: Entity?
    private var kwastje: Entity?
    private var krukje: Entity?

    /// One entity per placed sticker, keyed by the sticker's id so the entity
    /// and the spec never drift.
    private var stickerNodes: [UUID: Entity] = [:]
    /// One baked mesh per finished stroke.
    private var strokeNodes: [UUID: Entity] = [:]

    // MARK: - Interaction state

    /// What she is dragging out of a tray, before it lands.
    private var dragging: (kind: StickerKind, node: Entity)?
    /// Which already-placed sticker she has hold of.
    private var movingSticker: UUID?

    private var turnGrabAngle: Float?
    private var turnStartAngle: Float?
    private var turnedSoFar: Float = 0
    private var saidFullTurn = false

    /// The stroke being drawn. Live segments are cheap boxes; on release the
    /// whole thing is baked into one mesh.
    private var strokeInProgress: [StickerAnchor] = []
    private var strokeLiveNodes: [Entity] = []
    /// Metres of surface arc left in the bag.
    private var pipingLeft: Float = VersierLayout.pipingCapacity
    private var sprinkleTrail: SIMD3<Float>?
    /// Set while the shaker is sweeping, so target registration happens once at
    /// the end rather than once per grain.
    private var deferTargets = false

    private var saidFirstSticker = false
    private var saidFirstCandle = false
    private var saidManySprinkles = false

    private var idleJob: Int?
    private var idleTime: Float = 0
    private var nudgeStage = 0
    private var alternateNudge = false
    private var jobs: [Int] = []

    // MARK: - Life

    init(ticker: Ticker, touch: TouchRouter, voice: VoiceBank,
         sound: SoundKit, settings: LightingSettings,
         mode: RoomMode = .bezoek, handedCake: CakeSpec? = nil) {
        self.ticker = ticker
        self.touch = touch
        self.voice = voice
        self.sound = sound
        self.settings = settings
        self.mode = mode

        // **On a round the kitchen's cake arrives and replaces whatever was
        // here.** On a visit there is nothing to hand over, so the saved state
        // is resumed — and if there is none, one is dealt. Owner's call,
        // 2026-08-16: decorating with no cake in front of her is not a thing,
        // and the answer is to give her a cake rather than to refuse the room.
        var loaded = VersierStore.load(fallback: CakeSpec.dealt())
        if let handedCake {
            loaded.cake = handedCake
            loaded.turn = 0
        }
        self.state = loaded
        root.name = "Versieren"
    }

    // MARK: - Building

    func build(flat: Bool) {
        self.flat = flat
        cancelEverything()
        root.children.removeAll()
        touch.removeAll()
        stickerNodes.removeAll()
        strokeNodes.removeAll()
        trays.removeAll()
        jars.removeAll()

        VersierLayout.assertSpacing()

        root.addChild(RoomBox.shell(flat: flat))
        root.addChild(VersierProps.counter(flat: flat))

        buildTurntable()
        buildTrays()
        buildTools()
        buildToys()
        buildDoorway()
        buildBaker()

        rebuildDecorations()
        registerTargets()
        applyStep(animated: false)
        startIdleWatch()
    }

    private func buildTurntable() {
        let table = VersierProps.turntable(flat: flat)
        root.addChild(table.root)
        turntable = table
        table.spinner.orientation = simd_quatf(angle: state.turn, axis: [0, 1, 0])

        let cake = KitchenProps.cake(state.cake, flat: flat)
        cake.position = [0, VersierLayout.plateThickness, 0]
        cake.scale = SIMD3<Float>(repeating: VersierLayout.cakeScale)
            * (state.cake.isTall ? SIMD3<Float>(1, 1.5, 1) : SIMD3<Float>(repeating: 1))
        table.spinner.addChild(cake)
        cakeNode = cake

        let layer = Entity()
        layer.name = "Versiering"
        layer.position = [0, VersierLayout.plateThickness, 0]
        table.spinner.addChild(layer)
        stickerLayer = layer
    }

    private func buildTrays() {
        for (index, kind) in VersierLayout.trayOrder.enumerated() {
            let tray = VersierProps.tray(kind, flat: flat)
            tray.position = VersierLayout.traySpot(index)
            root.addChild(tray)
            trays[kind] = tray
        }
    }

    private func buildTools() {
        let bag = VersierProps.spuitzak(flat: flat)
        bag.root.position = VersierLayout.spuitzakSpot
        root.addChild(bag.root)
        spuitzak = bag
        refreshCreamLevel()

        let shaker = VersierProps.strooibus(flat: flat)
        shaker.position = VersierLayout.strooibusSpot
        root.addChild(shaker)
        strooibus = shaker
    }

    private func buildToys() {
        let pot = VersierProps.glitterpot(flat: flat)
        pot.position = VersierLayout.glitterpotSpot
        root.addChild(pot)
        glitterpot = pot

        let boards = VersierProps.taartborden(flat: flat)
        boards.position = VersierLayout.taartbordenSpot
        root.addChild(boards)
        taartborden = boards

        let brush = VersierProps.kwastje(flat: flat)
        brush.position = VersierLayout.kwastjeSpot
        root.addChild(brush)
        kwastje = brush

        let stool = VersierProps.krukje(flat: flat)
        stool.position = VersierLayout.krukjeSpot
        root.addChild(stool)
        krukje = stool

        let shelf = VersierProps.wandplank(flat: flat)
        root.addChild(shelf.root)
        jars = shelf.jars
    }

    /// The same door as the kitchen's, in the same place. It is the same door —
    /// she walks through one and arrives at the other.
    private func buildDoorway() {
        let node = Props.doorway(flat: flat)
        root.addChild(node.root)
        doorway = node

        let spot = Entity()
        spot.name = "DoorTouchSpot"
        spot.position = VersierLayout.doorwayCentre
            + SIMD3<Float>(0, KitchenLayout.doorOpening.y / 2, 0)
        root.addChild(spot)
        doorTouchSpot = spot
    }

    private func buildBaker() {
        baker?.stop()
        let nina = BakerCharacter(ticker: ticker, flat: flat)
        nina.root.position = VersierLayout.bakerSpot
        root.addChild(nina.root)
        baker = nina
    }

    // MARK: - Step presentation

    /// One function rebuilds everything the step implies. There is one step, so
    /// what it mostly does is light the door — see the class comment.
    private func applyStep(animated: Bool) {
        refreshDoorInvitation(animated: animated)
    }

    /// **The door is inviting from the first frame, in both modes**, which is
    /// the whole of this function. `ROOMS.md` §9 has it as one of exactly two;
    /// in a room with no required action there is nothing for it to wait for.
    private func refreshDoorInvitation(animated: Bool) {
        guard let doorway else { return }

        doorRest = KitchenLayout.doorAjarAngle
        doorway.hinge.orientation = simd_quatf(angle: doorRest, axis: [0, 1, 0])
        doorway.glow?.isEnabled = true

        if doorHalo == nil {
            let marker = Entity()
            marker.position = VersierLayout.doorHaloSpot
            root.addChild(marker)
            doorHalo = Halo.attach(to: marker, radius: VersierLayout.doorHaloRadius,
                                   ticker: ticker) { _ in RoomBox.floorY }
        }
    }

    // MARK: - Targets

    /// **Registrations are in points**, converted by `TouchRouter.radius(points:)`,
    /// because they are world-space spheres satisfying a rule about the screen.
    /// Read them straight against the kitchen's: nothing here needs the 1.08
    /// rescale, because the box and the eye did not move.
    private func registerTargets() {
        for (index, kind) in VersierLayout.trayOrder.enumerated() {
            let spot = VersierLayout.traySpot(index)
            touch.register("tray-\(kind.rawValue)", entity: trays[kind],
                           radius: VersierLayout.trayRadius,
                           planeY: VersierLayout.trayTopY) { target in
                target.onTap = { [weak self] in
                    self?.sayName(kind.nameLineID, wobbling: self?.trays[kind])
                }
                target.onDragBegan = { [weak self] world in
                    self?.beginDispensing(kind, at: world)
                }
                target.onDragMoved = { [weak self] world in self?.dragSticker(to: world) }
                target.onDragEnded = { [weak self] world in self?.dropSticker(at: world) }
            }
            _ = spot
        }

        touch.register("spuitzak", entity: spuitzak?.root,
                       radius: VersierLayout.toolRadius,
                       planeY: VersierLayout.trayTopY) { target in
            target.onTap = { [weak self] in
                self?.sayName(VersierLine.ditSpuitzak, wobbling: self?.spuitzak?.root)
            }
            target.onDragBegan = { [weak self] world in self?.pipeBegan(at: world) }
            target.onDragMoved = { [weak self] world in self?.pipeMoved(to: world) }
            target.onDragEnded = { [weak self] _ in self?.pipeEnded() }
        }

        touch.register("strooibus", entity: strooibus,
                       radius: VersierLayout.toolRadius,
                       planeY: VersierLayout.trayTopY) { target in
            target.onTap = { [weak self] in
                self?.sayName(VersierLine.ditStrooibus, wobbling: self?.strooibus)
            }
            target.onDragBegan = { [weak self] world in
                self?.deferTargets = true
                self?.shakeMoved(to: world)
            }
            target.onDragMoved = { [weak self] world in self?.shakeMoved(to: world) }
            target.onDragEnded = { [weak self] _ in
                guard let self else { return }
                self.sprinkleTrail = nil
                self.deferTargets = false
                self.registerStickerTargets()
            }
        }

        // The handle, not the plate. Turning is a thing you do to a handle, and
        // a handle that has moved is a readout of how far she has turned it.
        touch.register("draaitafel", entity: turntable?.handle,
                       radius: 0.042, planeY: VersierLayout.plateY) { target in
            target.tracksEntity = true
            target.onTap = { [weak self] in
                self?.sayName(VersierLine.ditDraaitafel, wobbling: self?.turntable?.handle)
            }
            target.onDragBegan = { [weak self] world in self?.turnBegan(at: world) }
            target.onDragMoved = { [weak self] world in self?.turnMoved(to: world) }
            target.onDragEnded = { [weak self] _ in self?.turnEnded() }
        }

        // **The cake itself is deliberately not a target.** `TouchRouter` picks
        // the nearest centre, so one generous sphere on the axis would swallow
        // every sticker near it — the spoon-in-the-bowl problem with forty
        // spoons. The only spheres on the cake are the placed stickers, and the
        // drop position comes from the analytic ray instead. This is exactly
        // what owning the ray buys.

        touch.register("deur", entity: doorTouchSpot, radius: 0.056,
                       planeY: RoomBox.floorY) { target in
            target.onTap = { [weak self] in self?.tapDoorway() }
        }

        registerToyTargets()
        registerStickerTargets()

        touch.onEmptyTap = { [weak self] world in self?.tapNothing(at: world) }
        touch.onAnyTouch = { [weak self] in self?.resetIdle() }
    }

    private func registerToyTargets() {
        touch.register("glitterpot", entity: glitterpot, radius: 0.030,
                       planeY: VersierLayout.counterTopY) { target in
            target.onTap = { [weak self] in self?.tapGlitter() }
        }
        touch.register("taartborden", entity: taartborden, radius: 0.030,
                       planeY: VersierLayout.counterTopY) { target in
            target.onTap = { [weak self] in
                guard let self else { return }
                self.sound.playVaried(.ding, volume: 0.5)
                if let boards = self.taartborden { self.ticker.wiggle(boards, angle: 0.10) }
                self.voice.say(VersierLine.ditTaartborden, priority: .low)
            }
        }
        touch.register("kwastje", entity: kwastje, radius: 0.028,
                       planeY: VersierLayout.counterTopY) { target in
            target.onTap = { [weak self] in
                guard let self else { return }
                self.sound.play(.stirTick, volume: 0.35, rate: 1.4)
                if let brush = self.kwastje { self.ticker.wiggle(brush, angle: 0.30) }
                self.voice.say(VersierLine.ditKwastje, priority: .low)
            }
        }
        touch.register("krukje", entity: krukje, radius: 0.034,
                       planeY: RoomBox.floorY) { target in
            target.onTap = { [weak self] in
                guard let self else { return }
                self.sound.play(.thud, volume: 0.4)
                if let stool = self.krukje { self.ticker.squash(stool, amount: 0.14) }
                self.voice.say(VersierLine.ditKrukje, priority: .low)
            }
        }
        for (i, jar) in jars.enumerated() {
            touch.register("pot\(i)", entity: jar, radius: 0.024,
                           planeY: VersierLayout.shelfTopY) { target in
                target.onTap = { [weak self] in
                    guard let self else { return }
                    self.sound.playVaried(.rattle, volume: 0.5)
                    self.ticker.wiggle(jar, angle: 0.14)
                    self.voice.say(VersierLine.ditPotjes, priority: .low)
                }
            }
        }
    }

    /// **One target per placed sticker**, all at the same generous radius.
    ///
    /// They overlap, and that is fine: nearest-centre-wins picks one, and *any*
    /// sticker wiggling is the response she wanted. There is no wrong answer to
    /// a tap on a decorated cake, which is what lets these be forgiving rather
    /// than precise.
    private func registerStickerTargets() {
        // **Clear the family first.** `TouchRouter.register` appends, so without
        // this every grain of sprinkle would leave a dead target behind that
        // still won hit tests near where it used to be.
        touch.remove(prefixed: "sticker-")
        for sticker in state.cake.placed {
            guard let node = stickerNodes[sticker.id] else { continue }
            let id = sticker.id
            touch.register("sticker-\(id.uuidString)", entity: node,
                           radius: touch.radius(points: VersierLayout.stickerTapPoints),
                           planeY: VersierLayout.plateY) { target in
                target.tracksEntity = true
                target.onTap = { [weak self] in self?.tapSticker(id) }
                target.onDragBegan = { [weak self] world in self?.grabSticker(id, at: world) }
                target.onDragMoved = { [weak self] world in self?.dragSticker(to: world) }
                target.onDragEnded = { [weak self] world in self?.dropSticker(at: world) }
            }
        }
    }

    // MARK: - The cake's surface

    private var surface: CakeSurface {
        let table = turntable
        return CakeSurface(
            origin: SIMD3<Float>(VersierLayout.turntableCentre.x,
                                 VersierLayout.plateY,
                                 VersierLayout.turntableCentre.y),
            scale: VersierLayout.cakeScale,
            turn: table.map { $0.spinner.orientation.angleAboutY } ?? state.turn,
            tall: state.cake.isTall)
    }

    private var stickerSlop: Float { touch.radius(points: VersierLayout.stickerSlopPoints) }
    private var removeSlop: Float { touch.radius(points: VersierLayout.removeSlopPoints) }

    // MARK: - Placing a sticker

    private func beginDispensing(_ kind: StickerKind, at world: SIMD3<Float>) {
        cancelDrag()
        let node = VersierProps.sticker(kind, flat: flat)
        root.addChild(node)
        dragging = (kind, node)
        sound.play(.plop, volume: 0.35, rate: 1.3)
        dragSticker(to: world)
    }

    private func grabSticker(_ id: UUID, at world: SIMD3<Float>) {
        guard let sticker = state.cake.placed.first(where: { $0.id == id }) else { return }
        cancelDrag()
        movingSticker = id
        // Reuse the placed node rather than making a second one, so it does not
        // read as leaving a copy behind.
        if let node = stickerNodes[id] {
            node.removeFromParent()
            root.addChild(node)
            dragging = (sticker.kind, node)
        }
        dragSticker(to: world)
    }

    /// **The sticker rides the cake's surface the whole way**, so she can see
    /// where it will land before she lets go. Committing on release would make
    /// the landing a surprise, and this is a room with no surprises in it.
    private func dragSticker(to world: SIMD3<Float>) {
        guard let dragging else { return }
        if let anchor = surface.anchor(pointingAt: world, slop: stickerSlop) {
            place(dragging.node, at: anchor, kind: dragging.kind, inLayer: false)
        } else {
            // Off the cake — follow her finger at plate height so it never
            // disappears while she is holding it.
            dragging.node.position = RoomBox.pointOnRay(through: world,
                                                        atHeight: VersierLayout.plateY + 0.010)
            dragging.node.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        }
    }

    private func dropSticker(at world: SIMD3<Float>) {
        guard let dragging else { return }
        defer { self.dragging = nil }

        if let anchor = surface.anchor(pointingAt: world, slop: stickerSlop) {
            commit(dragging.kind, at: anchor, replacing: movingSticker)
            movingSticker = nil
            return
        }

        // **She let go off the cake.** If it was already on it, that is the
        // remove gesture — but only decisively off, because the same drag nudges
        // one two millimetres and the game taking something away from her is the
        // outcome the design forbids outright.
        if let id = movingSticker {
            if surface.anchor(pointingAt: world, slop: removeSlop) == nil {
                remove(id)
            } else if let sticker = state.cake.placed.first(where: { $0.id == id }) {
                place(dragging.node, at: sticker.at, kind: sticker.kind, inLayer: true)
                stickerNodes[id] = dragging.node
            }
            movingSticker = nil
            return
        }

        // It came from a tray, so nothing is lost: a tray holds an endless
        // supply and the drag simply dispensed nothing. No sound of failure, no
        // `noteMiss` — §6.4 is explicit that there is nothing here she can fail.
        Sparkles.puff(at: dragging.node.position, in: root, ticker: ticker,
                      colour: Palette.creamLight, count: 5)
        dragging.node.removeFromParent()
    }

    private func cancelDrag() {
        if let dragging, movingSticker == nil { dragging.node.removeFromParent() }
        dragging = nil
        movingSticker = nil
    }

    /// Put a node on the surface: position, and orient it to the outward normal
    /// so a heart does not lie flat on a vertical wall.
    private func place(_ node: Entity, at anchor: StickerAnchor,
                       kind: StickerKind, inLayer: Bool, spin: Float = 0) {
        let normal = inLayer ? surface.localNormal(of: anchor) : surface.normal(of: anchor)
        let base = inLayer ? surface.localPosition(of: anchor) : surface.position(of: anchor)
        // Half a thickness proud, so it sits *on* the icing rather than in it.
        node.position = base + normal * (kind.size * 0.12)

        // A candle is vertical whatever face it landed on — the one exception,
        // and it prevents the silliest outcome in the room.
        let up: SIMD3<Float> = kind == .kaarsje ? [0, 1, 0] : normal
        node.orientation = simd_quatf(from: [0, 1, 0], to: up)
            * simd_quatf(angle: spin, axis: [0, 1, 0])
        if inLayer, let layer = stickerLayer, node.parent !== layer {
            node.removeFromParent()
            layer.addChild(node)
        }
    }

    private func commit(_ kind: StickerKind, at anchor: StickerAnchor, replacing id: UUID?) {
        var stickers = state.cake.placed
        let spin = Float.random(in: 0..<(2 * .pi))

        if let id, let index = stickers.firstIndex(where: { $0.id == id }) {
            stickers[index].at = anchor
            state.cake.stickers = stickers
            if let node = dragging?.node {
                place(node, at: anchor, kind: kind, inLayer: true, spin: stickers[index].spin)
                stickerNodes[id] = node
            }
            sound.play(.plop, volume: 0.4)
            save()
            return
        }

        var sticker = Sticker(kind: kind, at: anchor, spin: spin)
        if kind == .kaarsje { sticker.lit = false }
        stickers.append(sticker)

        // **The one silent cap in the room, and it is honest.** 120 grains
        // already cover the cake, so dropping the oldest is invisible — and it
        // can never put Pip's wish of eight sprinkles out of reach.
        if kind == .sprinkel {
            let sprinkles = stickers.filter { $0.kind == .sprinkel }
            if sprinkles.count > VersierLayout.maxSprinkles,
               let oldest = sprinkles.first {
                stickers.removeAll { $0.id == oldest.id }
                stickerNodes[oldest.id]?.removeFromParent()
                stickerNodes[oldest.id] = nil
            }
        }
        state.cake.stickers = stickers
        state.cake.version = 2

        if let node = dragging?.node {
            place(node, at: anchor, kind: kind, inLayer: true, spin: spin)
            stickerNodes[sticker.id] = node
            ticker.squash(node, amount: 0.30, duration: 0.32)
        }
        sound.play(.plop, volume: 0.45)
        Sparkles.burst(at: surface.position(of: anchor), in: root, ticker: ticker,
                       colour: kind.colour, count: 5, size: 0.0018, speed: 0.05, life: 0.5)

        react(to: kind)
        // A shaker sweep lands a grain every few millimetres, and rebuilding a
        // hundred-odd targets per grain is the one thing in here that could cost
        // a frame. The sweep re-registers once when she lifts her finger.
        if !deferTargets { registerStickerTargets() }
        save()
    }

    private func remove(_ id: UUID) {
        guard let index = state.cake.placed.firstIndex(where: { $0.id == id }) else { return }
        var stickers = state.cake.placed
        stickers.remove(at: index)
        state.cake.stickers = stickers

        if let node = stickerNodes[id] {
            Sparkles.puff(at: node.position, in: root, ticker: ticker,
                          colour: Palette.creamLight, count: 6)
            node.removeFromParent()
        }
        stickerNodes[id] = nil
        dragging = nil
        sound.play(.poof, volume: 0.3)
        registerStickerTargets()
        save()
    }

    /// The reactions `GAMEPLAY.md` §6.4 names: a sticker placed, the first
    /// candle lit, the tenth sprinkle. The fourth — the cake turned all the way
    /// round — is in `turnMoved`.
    private func react(to kind: StickerKind) {
        if !saidFirstSticker {
            saidFirstSticker = true
            voice.sayWhenQuiet(VersierLine.eerste)
            return
        }
        if kind == .sprinkel, !saidManySprinkles,
           state.cake.count(of: .sprinkel) >= 10 {
            saidManySprinkles = true
            voice.sayWhenQuiet(VersierLine.veelSprinkels)
            return
        }
        // Otherwise, occasionally — she is placing dozens of these and a line
        // for each would be a lift announcement.
        if Int.random(in: 0..<5) == 0 {
            voice.say(VersierLine.mooi, priority: .low)
        }
    }

    // MARK: - Tapping what is already on it

    private func tapSticker(_ id: UUID) {
        guard let sticker = state.cake.placed.first(where: { $0.id == id }),
              let node = stickerNodes[id] else { return }

        if sticker.kind == .kaarsje, sticker.lit != true {
            lightCandle(id, node: node)
            return
        }
        // Through `Ticker.wiggle`, which owns its own rest pose — Otto's blink
        // is the standing lesson about a transform animation that restores what
        // it found, and forty tappable stickers is that bug forty times over.
        ticker.wiggle(node, angle: 0.30, duration: 0.45)
        sound.play(.stirTick, volume: 0.28, rate: 1.5)
        voice.say(sticker.kind.nameLineID, priority: .low)
    }

    private func lightCandle(_ id: UUID, node: Entity) {
        guard let index = state.cake.placed.firstIndex(where: { $0.id == id }) else { return }
        var stickers = state.cake.placed
        stickers[index].lit = true
        state.cake.stickers = stickers

        if let flame = node.findEntity(named: VersierProps.flameName) as? ModelEntity {
            flame.model?.materials = [Palette.glowMaterial(Palette.butterYellow, intensity: 2.2)]
            ticker.squash(flame, amount: 0.35, duration: 0.4)
        }
        Sparkles.burst(at: node.position(relativeTo: nil) + [0, 0.006, 0], in: root,
                       ticker: ticker, colour: Palette.butterYellow,
                       count: 6, size: 0.0018, speed: 0.05, life: 0.6, glow: 1)
        sound.play(.sparkle, volume: 0.5, rate: 1.2)

        if !saidFirstCandle {
            saidFirstCandle = true
            voice.sayWhenQuiet(VersierLine.kaarsAan)
        }
        save()
    }

    // MARK: - The turntable

    private func turnBegan(at world: SIMD3<Float>) {
        turnGrabAngle = angleAroundAxis(world)
        turnStartAngle = turntable?.spinner.orientation.angleAboutY
    }

    private func turnMoved(to world: SIMD3<Float>) {
        guard let spinner = turntable?.spinner,
              let grab = turnGrabAngle, let start = turnStartAngle else { return }
        let now = angleAroundAxis(world)
        var delta = now - grab
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }

        spinner.orientation = simd_quatf(angle: start + delta, axis: [0, 1, 0])
        turnGrabAngle = now
        turnStartAngle = start + delta
        // Total travel, not net angle: turning back and forth is still turning,
        // and a full circle is a full circle whichever way she went round.
        turnedSoFar += abs(delta)

        sound.play(.roll, volume: 0.16, rate: 1.6)

        // The fourth reaction §6.4 names: the cake turned all the way round.
        if !saidFullTurn, turnedSoFar >= 2 * .pi {
            saidFullTurn = true
            voice.sayWhenQuiet(VersierLine.rondje)
        }
    }

    private func turnEnded() {
        turnGrabAngle = nil
        turnStartAngle = nil
        state.turn = turntable?.spinner.orientation.angleAboutY ?? state.turn
        save()
    }

    private func angleAroundAxis(_ world: SIMD3<Float>) -> Float {
        let p = RoomBox.pointOnRay(through: world, atHeight: VersierLayout.plateY)
        return atan2(p.z - VersierLayout.turntableCentre.y,
                     p.x - VersierLayout.turntableCentre.x)
    }

    // MARK: - The piping bag

    private func pipeBegan(at world: SIMD3<Float>) {
        strokeInProgress.removeAll()
        for node in strokeLiveNodes { node.removeFromParent() }
        strokeLiveNodes.removeAll()
        pipeMoved(to: world)
    }

    private func pipeMoved(to world: SIMD3<Float>) {
        guard pipingLeft > 0 else { return }
        guard let anchor = surface.anchor(pointingAt: world, slop: stickerSlop) else { return }

        guard let last = strokeInProgress.last else {
            strokeInProgress.append(anchor)
            return
        }
        let step = surface.arc(from: last, to: anchor)
        guard step.isFinite else {
            // She crossed onto a different tier or face. Break the ribbon there
            // rather than chording across the gap, but keep it one stroke.
            strokeInProgress.append(anchor)
            return
        }
        guard step >= VersierLayout.strokeStep else { return }

        // A flick. Fill the gap **in polar** — lerping world XYZ would chord
        // straight through the cake instead of hugging it.
        if step > VersierLayout.strokeMaxStep {
            let steps = Int(step / VersierLayout.strokeStep)
            for i in 1..<max(steps, 2) {
                let t = Float(i) / Float(max(steps, 2))
                strokeInProgress.append(lerp(last, anchor, t))
            }
        }
        strokeInProgress.append(anchor)
        pipingLeft = max(0, pipingLeft - step)
        refreshCreamLevel()
        redrawLiveStroke()

        if pipingLeft <= 0 { bagRanOut() }
    }

    /// Polar interpolation between two anchors on the same tier and face.
    private func lerp(_ a: StickerAnchor, _ b: StickerAnchor, _ t: Float) -> StickerAnchor {
        var dTheta = b.theta - a.theta
        while dTheta > .pi { dTheta -= 2 * .pi }
        while dTheta < -.pi { dTheta += 2 * .pi }
        return StickerAnchor(tier: a.tier, face: a.face,
                             theta: a.theta + dTheta * t,
                             u: a.u + (b.u - a.u) * t)
    }

    /// While she draws, the stroke is redrawn as one mesh every few points
    /// rather than every frame — building a `MeshResource` per millimetre is
    /// what would drop frames.
    private func redrawLiveStroke() {
        guard strokeInProgress.count >= 2, strokeInProgress.count % 3 == 0 else { return }
        for node in strokeLiveNodes { node.removeFromParent() }
        strokeLiveNodes.removeAll()
        if let node = strokeEntity(Stroke(path: strokeInProgress, width: currentRibbonWidth)) {
            stickerLayer?.addChild(node)
            strokeLiveNodes = [node]
        }
    }

    /// **The ribbon thins as the bag empties**, so the ending is legible in the
    /// drawing itself rather than arriving as a stop.
    private var currentRibbonWidth: Float {
        let fraction = pipingLeft / VersierLayout.pipingCapacity
        guard fraction < VersierLayout.pipingThinsBelow else { return 0.0035 }
        let t = max(0, fraction) / VersierLayout.pipingThinsBelow
        return 0.0014 + (0.0035 - 0.0014) * t
    }

    private func pipeEnded() {
        defer {
            strokeInProgress.removeAll()
            for node in strokeLiveNodes { node.removeFromParent() }
            strokeLiveNodes.removeAll()
        }
        guard strokeInProgress.count >= 2 else { return }

        var strokes = state.cake.piped
        strokes.append(Stroke(path: strokeInProgress, width: currentRibbonWidth))
        // A cake piped forty times over is a cake whose first stroke is already
        // buried. This is the one place a silent limit is honest, and it is what
        // keeps the party and the wall from re-rendering an unbounded array.
        if strokes.count > VersierLayout.maxStrokes {
            let dropped = strokes.removeFirst()
            strokeNodes[dropped.id]?.removeFromParent()
            strokeNodes[dropped.id] = nil
        }
        state.cake.strokes = strokes
        state.cake.version = 2
        rebuildStrokes()
        sound.play(.pour, volume: 0.3, rate: 1.4)

        // **Letting go refills it.** The cap is a property of one squeeze, never
        // of the room: a bag that stayed empty would be the game refusing her,
        // which is exactly what §6.4 forbids.
        refillBag()
        save()
    }

    private func bagRanOut() {
        sound.play(.poof, volume: 0.25, rate: 1.3)
        if let bag = spuitzak?.root { ticker.squash(bag, amount: 0.18, duration: 0.3) }
        voice.say(VersierLine.spuitzakLeeg, priority: .low)
    }

    private func refillBag() {
        let from = pipingLeft
        guard from < VersierLayout.pipingCapacity else { return }
        let job = ticker.tween(1.2, step: { [weak self] t in
            guard let self else { return }
            self.pipingLeft = from + (VersierLayout.pipingCapacity - from) * t
            self.refreshCreamLevel()
        })
        jobs.append(job)
    }

    /// The cream inside the bag, Y-scaled to what is left. **A cap you can watch
    /// approaching is not a refusal** — the same argument as the door saying
    /// *openable* three ways at once.
    private func refreshCreamLevel() {
        guard let cream = spuitzak?.cream else { return }
        let fraction = max(0.05, pipingLeft / VersierLayout.pipingCapacity)
        cream.scale = [1, fraction, 1]
    }

    // MARK: - The shaker

    /// Rains **individual sprinkles**, not a texture and not a particle effect.
    /// Pip's wish is *eight sprinkles*, so they have to be countable — a patch
    /// with a density would make that number a fiction.
    private func shakeMoved(to world: SIMD3<Float>) {
        guard let anchor = surface.anchor(pointingAt: world, slop: stickerSlop) else { return }
        let here = surface.position(of: anchor)
        if let last = sprinkleTrail, simd_distance(last, here) < 0.006 { return }
        sprinkleTrail = here

        var scattered = anchor
        scattered.theta += Float.random(in: -0.10...0.10)
        scattered.u = min(max(anchor.u + Float.random(in: -0.10...0.10), 0.04), 0.96)

        dragging = nil
        let node = VersierProps.sticker(.sprinkel, flat: flat)
        root.addChild(node)
        dragging = (.sprinkel, node)
        commit(.sprinkel, at: scattered, replacing: nil)
        dragging = nil

        sound.play(.rattle, volume: 0.18, rate: Float.random(in: 1.3...1.7))
    }

    // MARK: - Rendering what is stored

    private func rebuildDecorations() {
        for node in stickerNodes.values { node.removeFromParent() }
        stickerNodes.removeAll()
        for sticker in state.cake.placed {
            let node = VersierProps.sticker(sticker.kind, flat: flat)
            stickerLayer?.addChild(node)
            place(node, at: sticker.at, kind: sticker.kind, inLayer: true, spin: sticker.spin)
            if sticker.kind == .kaarsje, sticker.lit == true,
               let flame = node.findEntity(named: VersierProps.flameName) as? ModelEntity {
                flame.model?.materials = [Palette.glowMaterial(Palette.butterYellow,
                                                               intensity: 2.2)]
            }
            stickerNodes[sticker.id] = node
        }
        rebuildStrokes()
    }

    private func rebuildStrokes() {
        for node in strokeNodes.values { node.removeFromParent() }
        strokeNodes.removeAll()
        for stroke in state.cake.piped {
            guard let node = strokeEntity(stroke) else { continue }
            stickerLayer?.addChild(node)
            strokeNodes[stroke.id] = node
        }
    }

    /// **One entity per stroke**, whatever its length. `FacetedMesh.ribbon`
    /// sweeps the whole path into a single geometry, which is the answer to
    /// §6.4's *"the number of entities is decided by how long she drags"*.
    private func strokeEntity(_ stroke: Stroke) -> Entity? {
        guard stroke.path.count >= 2 else { return nil }
        let s = surface
        let points = stroke.path.map { s.localPosition(of: $0) + s.localNormal(of: $0) * 0.0012 }
        let normals = stroke.path.map { s.localNormal(of: $0) }
        let geometry = FacetedMesh.ribbon(points: points, normals: normals,
                                          width: stroke.width, thickness: stroke.width * 0.6)
        guard !geometry.positions.isEmpty else { return nil }

        // **Cream against the tier it lies on, not against white.** A cream
        // ribbon on a `wolkenroom` cake is invisible for the same arithmetic the
        // halo took four goes to learn — so on a white or glowing cake it goes a
        // shade down rather than a shade up.
        let colour = state.cake.colours == [.wit] || state.cake.colours.isEmpty
            ? Palette.cream : Palette.creamLight
        let material = state.cake.glows
            ? Palette.material(Palette.cream)
            : Palette.material(colour)
        return ModelEntity(mesh: FacetedMesh.mesh(geometry, flat: flat), materials: [material])
    }

    // MARK: - Toys

    private func tapGlitter() {
        guard let pot = glitterpot else { return }
        sound.play(.sparkle, volume: 0.55)
        ticker.squash(pot, amount: 0.18)
        Sparkles.burst(at: pot.position + [0, 0.024, 0], in: root, ticker: ticker,
                       colour: Palette.butterYellow, count: 14, size: 0.0022,
                       speed: 0.08, life: 0.9, glow: 1)
        voice.say(VersierLine.ditGlitterpot, priority: .low)
    }

    private func sayName(_ lineID: String, wobbling entity: Entity?) {
        if let entity, entity.isEnabled { ticker.squash(entity, amount: 0.13) }
        sound.play(.stirTick, volume: 0.3, rate: 1.25)
        voice.say(lineID, priority: .low)
    }

    /// A tap on nothing sparkles under her finger. Not optional — a screen that
    /// eats a tap silently is where she decides the iPad is broken.
    private func tapNothing(at world: SIMD3<Float>) {
        Sparkles.burst(at: world + [0, 0.004, 0], in: root, ticker: ticker,
                       colour: Palette.creamLight, count: 6, size: 0.0022,
                       speed: 0.06, life: 0.5)
        sound.play(.sparkle, volume: 0.22, rate: 1.4)
    }

    // MARK: - The way out

    private func tapDoorway() {
        guard let doorway else { return }
        sound.play(.whoosh)
        endRoom(doorway)
    }

    /// **The door works from the first frame and always means the same thing.**
    /// There is no required action to gate it on — §6.4: *the door works
    /// immediately, and this room must never ask her for anything.*
    private func endRoom(_ doorway: Props.Doorway) {
        swingDoor(doorway, hold: 2.6)
        baker?.set(.cheering)
        sound.play(.reward, volume: 0.7)
        save()

        // The party does not exist, so this is a ceremony rather than a
        // transition, and Nina says the next room is coming *soon* rather than
        // *now*. `ROOMS.md` §9: a 4-year-old told she is going somewhere and
        // then not taken there has been lied to.
        voice.sayInstead(mode == .ronde ? VersierLine.deurRonde : VersierLine.deurBezoek)

        let threshold = VersierLayout.doorHaloSpot
        for (i, delay) in [Float(0.45), 1.5].enumerated() {
            let job = ticker.after(delay) { [weak self] in
                guard let self else { return }
                Sparkles.burst(at: threshold + [0, 0.030, 0], in: self.root,
                               ticker: self.ticker, colour: Palette.butterYellow,
                               count: i == 0 ? 12 : 8, size: 0.0026,
                               speed: 0.07, life: 1.1)
                self.sound.play(.sparkle, volume: 0.45, rate: 1.0 + Float(i) * 0.15)
            }
            jobs.append(job)
        }
    }

    private func swingDoor(_ doorway: Props.Doorway, hold: Float = 1.5) {
        ticker.cancel(doorSwing)
        let hinge = doorway.hinge
        let rest = doorRest
        let open = KitchenLayout.doorOpenAngle
        doorSwing = ticker.tween(0.45, step: { t in
            hinge.orientation = simd_quatf(angle: rest + (open - rest) * t, axis: [0, 1, 0])
        }, done: { [weak self] in
            guard let self else { return }
            self.doorSwing = self.ticker.after(hold) { [weak self] in
                guard let self else { return }
                self.doorSwing = self.ticker.tween(0.5, step: { t in
                    hinge.orientation = simd_quatf(angle: open + (rest - open) * t,
                                                   axis: [0, 1, 0])
                })
            }
        })
    }

    // MARK: - Room

    func greet() {
        voice.say(VersierLine.hallo)
    }

    func save() {
        VersierStore.save(state)
    }

    /// **Bare cake, not no cake.**
    ///
    /// `ROOMS.md` §8 is strict that this button has exactly one meaning, and the
    /// kitchen paid for the lesson once. Here it means *take everything off the
    /// cake* — never *throw the cake away*. The cake came from the kitchen and
    /// she cannot get another without baking one, so clearing it would make one
    /// button mean two things depending on how she arrived.
    func restartRound() {
        state.cake.stickers = []
        state.cake.strokes = []
        saidFirstSticker = false
        saidFirstCandle = false
        saidManySprinkles = false
        saidFullTurn = false
        turnedSoFar = 0
        pipingLeft = VersierLayout.pipingCapacity
        refreshCreamLevel()
        rebuildDecorations()
        registerStickerTargets()
        sound.play(.poof, volume: 0.4)
        voice.say(VersierLine.opnieuw)
        save()
    }

    func refreshContactShadows(settings: LightingSettings) {
        self.settings = settings
        // **Nothing on the cake gets one.** `ContactShadows` assumes a
        // horizontal plane underneath, and on a stack of cylinders there is not
        // one — a blob under a heart on a vertical wall would land on the floor.
        let props: [Entity?] = [spuitzak?.root, strooibus, glitterpot, taartborden,
                                kwastje, krukje]
            + VersierLayout.trayOrder.map { trays[$0] }
        for prop in props.compactMap({ $0 }) {
            guard prop.isEnabled else { continue }
            ContactShadows.attach(to: prop, radius: 0.020, settings: settings)
            ContactShadows.update(for: prop, surfaceY: surfaceY(at: prop.position),
                                  settings: settings)
        }
    }

    /// **This room's surfaces, added the moment the surfaces existed.**
    ///
    /// `ROOMS.md` §3 is emphatic: every surface a prop can stand on must be in
    /// the lookup, or the cue lands somewhere else. In the kitchen that was
    /// learned by putting a halo 150 mm below the berry it was pointing at, for
    /// two of five steps.
    private func surfaceY(at point: SIMD3<Float>) -> Float {
        if RoomBox.within(point, centre: VersierLayout.counterCentre,
                          size: VersierLayout.counterSize, margin: 0.006) {
            return VersierLayout.counterTopY
        }
        return RoomBox.floorY
    }

    func leave() {
        cancelEverything()
        save()
    }

    var debugTitle: String { RoomID.versieren.title }

    var debugRows: [String] {
        ["Mode: \(mode == .ronde ? "ronde" : "bezoek")  ·  Turn: \(Int(state.turn * 180 / .pi))°",
         "Cake: \(state.cake.kind.rawValue) · \(state.cake.colours.map(\.rawValue).joined(separator: ", "))",
         "Stickers: \(state.cake.placed.count)  ·  Strokes: \(state.cake.piped.count)",
         "Sprinkels: \(state.cake.count(of: .sprinkel))  ·  Kaarsjes: \(state.cake.count(of: .kaarsje))",
         "Spuitzak: \(Int(pipingLeft / VersierLayout.pipingCapacity * 100))%"]
    }

    var debugActions: [(String, @MainActor () -> Void)] {
        [("Bare cake", { [weak self] in self?.restartRound() }),
         ("Fill it up", { [weak self] in self?.fillForTesting() })]
    }

    /// Debug only: forty stickers and three strokes, to look at a busy cake
    /// without placing them all by hand. This is the state the room has to hold
    /// its frame rate at.
    private func fillForTesting() {
        for i in 0..<40 {
            let kind = StickerKind.allCases[i % StickerKind.allCases.count]
            let anchor = StickerAnchor(tier: i % CakeGeometry.tierCount,
                                       face: i % 3 == 0 ? .boven : .zijkant,
                                       theta: Float(i) * 0.63,
                                       u: 0.2 + Float(i % 4) * 0.2)
            var sticker = Sticker(kind: kind, at: anchor,
                                  spin: Float(i) * 0.4)
            if kind == .kaarsje { sticker.lit = i % 2 == 0 }
            state.cake.stickers = state.cake.placed + [sticker]
        }
        state.cake.version = 2
        rebuildDecorations()
        registerStickerTargets()
        save()
    }

    // MARK: - Idle

    /// Copied from the kitchen and **tuned nothing** — 25 s, 45 s, 105 s.
    /// The one thing that is this room's own is the line.
    private func startIdleWatch() {
        ticker.cancel(idleJob)
        idleTime = 0
        nudgeStage = 0
        idleJob = ticker.add { [weak self] dt in
            guard let self else { return false }
            self.idleTime += dt
            if self.nudgeStage == 0, self.idleTime > 45 {
                self.nudgeStage = 1
                // **Never an instruction.** There is nothing she is failing to
                // do, so a nudge that implied otherwise would turn the one room
                // with no required action into a room with a soft one.
                self.voice.say(self.alternateNudge ? VersierLine.stil : VersierLine.zullenWeGaan,
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

    // MARK: - Housekeeping

    private func cancelEverything() {
        for job in jobs { ticker.cancel(job) }
        jobs.removeAll()
        ticker.cancel(idleJob)
        idleJob = nil
        ticker.cancel(doorSwing)
        doorSwing = nil
        doorRest = 0
        doorTouchSpot = nil
        Halo.remove(doorHalo, ticker: ticker)
        doorHalo = nil
        baker?.stop()
        baker = nil
        cancelDrag()
        strokeInProgress.removeAll()
        strokeLiveNodes.removeAll()
        turnGrabAngle = nil
        turnStartAngle = nil
        sprinkleTrail = nil
        touch.onEmptyTap = nil
        touch.onAnyTouch = nil
    }
}

// MARK: - Line ids

/// The decorating room's voice, spelled once. `enum Line` is documented as the
/// kitchen's, so this sits beside its own room — and `VoiceBank` loads every
/// bundled `script-*.json` automatically, so `script-versieren.json` needs no
/// Swift change beyond these constants.
enum VersierLine {
    static let hallo = "nina.versieren.hallo"
    static let eerste = "nina.versieren.eerste"
    static let mooi = "nina.versieren.mooi"
    static let kaarsAan = "nina.versieren.kaarsAan"
    static let veelSprinkels = "nina.versieren.veelSprinkels"
    static let rondje = "nina.versieren.rondje"
    static let spuitzakLeeg = "nina.versieren.spuitzakLeeg"
    static let opnieuw = "nina.versieren.opnieuw"
    static let stil = "nina.versieren.stil"
    static let zullenWeGaan = "nina.versieren.zullenWeGaan"
    static let deurRonde = "nina.versieren.deurRonde"
    static let deurBezoek = "nina.versieren.deurBezoek"

    // The naming layer — one variant each, deliberately.
    static let ditDraaitafel = "nina.dit.draaitafel"
    static let ditSpuitzak = "nina.dit.spuitzak"
    static let ditStrooibus = "nina.dit.strooibus"
    static let ditGlitterpot = "nina.dit.glitterpot"
    static let ditTaartborden = "nina.dit.taartborden"
    static let ditKwastje = "nina.dit.kwastje"
    static let ditKrukje = "nina.dit.krukje"
    static let ditPotjes = "nina.dit.sprinkelpotjes"
}

// MARK: -

private extension simd_quatf {
    /// The rotation about +Y, for a quaternion that only ever turns about it.
    var angleAboutY: Float {
        let v = act(SIMD3<Float>(1, 0, 0))
        return atan2(v.z, v.x)
    }
}
