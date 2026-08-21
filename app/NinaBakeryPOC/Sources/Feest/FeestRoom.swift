import Foundation
import RealityKit
import simd
import CoreGraphics

/// **Het Feest — the party.** `GAMEPLAY.md` §6.5.
///
/// A discotheque: a mirror ball throwing pools of light across a lit floor, a
/// rig of coloured lamps, a stack of speakers, a DJ behind a booth with two
/// decks, six friends dancing, and her cake standing on a table under a light.
/// Six big pads along the open front edge, one per instrument.
///
/// **The whole room is one number, and the number is hers.** `FeestBeat` turns
/// the interval between her taps into a period, and the guests, the mirror ball,
/// the floor tiles, the lamps, the decks and the speaker cones all read it. Not
/// one of them owns a clock. That is what makes the room feel like it is
/// following her rather than running beside her, and it is the difference §6.5
/// draws between *her rhythm* and *a recording*.
///
/// Three things follow from this being a room that asks her for nothing:
///
/// - **The halo has one thing to point at, and it is the VIP rope** — which is
///   also the way out (`ROOMS.md` §9). Lit from the first frame, exactly as the
///   decorating room's door is, because *you may finish when you like* is a true
///   statement here. Owner's call, 2026-08-21: the cake is a toy, not an exit.
///   The rope is a different door from the kitchen's leaf and the garden's gate,
///   standing in the same place on the left wall.
/// - **The miss machinery is not wired.** `noteMiss` means *she dragged the prop
///   the current step is about and it did not land*, and nothing in this room is
///   dragged at all. Every interaction here is a tap.
/// - **The idle nudge is not an instruction.** *"Zullen we gaan?"*, never
///   *"tap a pad"*. There is nothing she is failing to do.
@MainActor
final class FeestRoom: Room {

    let root = Entity()
    var onExit: ((RoomExit) -> Void)?

    /// `ROOMS.md` §9: one flag, not two implementations.
    let mode: RoomMode

    private let ticker: Ticker
    private let touch: TouchRouter
    private let voice: VoiceBank
    private let sound: SoundKit
    private var settings: LightingSettings
    private var flat = true

    private(set) var state: FeestState
    private let beat = FeestBeat()

    // MARK: - Entities

    private var danceFloor: FeestProps.DanceFloor?
    private var pads: [FeestProps.Pad] = []
    private var mirrorBall: FeestProps.MirrorBall?
    private var ballSpots: Entity?
    private var lamps: [FeestProps.Lamp] = []
    private var lampMarker: Entity?
    private var booth: FeestProps.Booth?
    /// Both stacks, one per back corner. `[0]` is the tappable one.
    private var speakers: [FeestProps.Speakers] = []
    private var popper: Entity?
    private var balloon: Entity?
    private var table: Entity?
    private var cakeAnchor: Entity?
    private var cakeNode: Entity?
    private var stickerLayer: Entity?
    private var cakeTouchSpot: Entity?
    private var baker: BakerCharacter?
    private var doorway: Props.Doorway?
    private var doorTouchSpot: Entity?
    private var doorHalo: Halo.Handle?
    private var doorRest: Float = 0
    private var doorSwing: Int?

    /// The friend of the day is `guests[0]`. `GuestCharacter` holds its own
    /// `friend`, so nothing here has to keep the two lists in step.
    private var guests: [GuestCharacter] = []
    private var djCharacter: GuestCharacter?

    // MARK: - Interaction state

    /// **Which of `FeestLayout.floorLitColours` the whole floor is flashing**, and
    /// for how much longer. A pad tap paints every tile one colour for a beat,
    /// which is what ties her finger to the room.
    ///
    /// An *index* rather than a colour, so the repaint can reach straight into
    /// the cached materials instead of constructing one.
    private var flashColourIndex: Int?
    private var flashLeft: Float = 0
    private var lastLitStep = -1
    private var lastLampStep = -2
    /// **What each surface is currently wearing**, so a beat can assign only to
    /// the ones that changed. `-1` is unlit; otherwise an index into the cached
    /// glowing materials. See `repaintFloor`.
    private var floorWear: [Int] = []
    private var ballWear: [Bool] = []
    private var lampLens: [RealityKit.Material] = []
    private var lampBeam: [RealityKit.Material] = []

    /// Which of the DJ's three sounds is next. Rotates rather than shuffles —
    /// see `tapDJ`.
    private var djTurn = 0
    private var saidFirstBeat = false
    private var saidFaster = false
    private var balloonDrift: SIMD3<Float> = .zero

    private var idleJob: Int?
    private var idleTime: Float = 0
    private var nudgeStage = 0
    private var alternateNudge = false
    private var beatJob: Int?
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

        // **A cake arriving means a new party**, and the friend is dealt with it.
        // On a visit the saved one is resumed, and if there is none a cake and a
        // friend are dealt together — the decorating room's rule (`CakeSpec.dealt`,
        // owner's call 2026-08-16) applied to a second missing thing: supply it
        // rather than refuse her the room.
        var loaded = FeestStore.load(fallback: CakeSpec.dealt())
        if let handedCake {
            loaded = .fresh(cake: handedCake, friend: Friend.dealt())
        }
        self.state = loaded
        root.name = "Feest"
    }

    // MARK: - Building

    func build(flat: Bool) {
        self.flat = flat
        cancelEverything()
        root.children.removeAll()
        touch.removeAll()
        pads.removeAll()
        lamps.removeAll()
        guests.removeAll()

        FeestLayout.assertSpacing()

        root.addChild(RoomBox.shell(flat: flat))

        buildDanceFloor()
        buildPads()
        buildLightRig()
        buildMirrorBall()
        buildBooth()
        buildGuests()
        buildToys()
        buildCake()
        buildDoorway()
        buildBaker()

        registerTargets()
        applyStep(animated: false)
        // **After every lit thing exists**, not inside `buildDanceFloor` — the
        // first paint touches the floor, the ball and the lamps, and two of the
        // three are built later.
        repaintFloor(force: true)
        startBeat()
        startIdleWatch()
    }

    private func buildDanceFloor() {
        let floor = FeestProps.danceFloor(flat: flat)
        root.addChild(floor.root)
        danceFloor = floor
        lastLitStep = -1
        lastLampStep = -2
        floorWear.removeAll()
        ballWear.removeAll()
    }

    private func buildPads() {
        for index in 0..<FeestLayout.padCount {
            let pad = FeestProps.pad(colour: FeestLayout.discoColour(index), flat: flat)
            pad.root.position = FeestLayout.padSpot(index)
            root.addChild(pad.root)
            pads.append(pad)
        }
    }

    private func buildLightRig() {
        let cached = FeestProps.lampMaterials()
        lampLens = cached.lens
        lampBeam = cached.beam

        let aim = SIMD3<Float>(FeestLayout.floorCentre.x, FeestLayout.tileTopY,
                               FeestLayout.floorCentre.y)

        let backBar = FeestProps.lightBar(length: 0.280, flat: flat)
        backBar.position = [0, FeestLayout.backBarY, FeestLayout.backBarZ]
        root.addChild(backBar)

        let leftBar = FeestProps.lightBar(length: 0.230, flat: flat)
        leftBar.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        leftBar.position = [FeestLayout.leftBarX, FeestLayout.backBarY, -0.040]
        root.addChild(leftBar)

        var index = 0
        for x in FeestLayout.backLampX {
            let origin = SIMD3<Float>(x, FeestLayout.backBarY - 0.005, FeestLayout.backBarZ)
            let lamp = FeestProps.lamp(colour: FeestLayout.discoColour(index),
                                       aimedAt: aim, from: origin, flat: flat)
            root.addChild(lamp.root)
            lamps.append(lamp)
            index += 1
        }
        for z in FeestLayout.leftLampZ {
            let origin = SIMD3<Float>(FeestLayout.leftBarX, FeestLayout.backBarY - 0.005, z)
            let lamp = FeestProps.lamp(colour: FeestLayout.discoColour(index),
                                       aimedAt: aim, from: origin, flat: flat)
            root.addChild(lamp.root)
            lamps.append(lamp)
            index += 1
        }

        // One target for the whole rig — five lamps are five words for one thing,
        // and they hang 110 mm apart on a wall nobody needs to aim at precisely.
        let marker = Entity()
        marker.name = "LampMarker"
        marker.position = FeestLayout.lampTouchSpot
        root.addChild(marker)
        lampMarker = marker
    }

    private func buildMirrorBall() {
        let ball = FeestProps.mirrorBall(flat: flat)
        root.addChild(ball.root)
        mirrorBall = ball

        let spots = FeestProps.ballSpots(flat: flat)
        root.addChild(spots.root)
        ballSpots = spots.root
    }

    private func buildBooth() {
        let deck = FeestProps.booth(flat: flat)
        root.addChild(deck.root)
        booth = deck

        // **The DJ is a friend, not a twelfth character.** `GAMEPLAY.md` §1 has
        // eleven friends and a gold frame that is Nina's, and inventing a twelfth
        // animal to stand behind the decks would quietly reopen a decision the
        // owner closed. So the DJ is whoever is *not* at the party today — she
        // has eleven friends and six of them are on the floor.
        let onTheFloor = Set(state.everyone)
        let dj = Friend.allCases.first { !onTheFloor.contains($0) } ?? .bas

        let pedestal = FeestProps.djPedestal(flat: flat)
        pedestal.position = [
            FeestLayout.djSpot.x,
            RoomBox.floorY,
            FeestLayout.djSpot.z,
        ]
        root.addChild(pedestal)

        let character = GuestCharacter(friend: dj, role: .dj, at: FeestLayout.djSpot,
                                       phase: 0, ticker: ticker, flat: flat)
        // His arm pose and his motion are both `.dj`'s own — the style is only
        // here because the initialiser takes one, and `.dj` ignores it.
        root.addChild(character.root)
        djCharacter = character
    }

    /// **Six guests, six different dances, one each.**
    ///
    /// `DanceStyle.allCases` is exactly `FeestLayout.guestCount` long and the
    /// index picks straight off it, so every party has all six moves on screen
    /// and no two guests are doing the same one. That is deliberate rather than
    /// convenient: owner's call, 2026-08-17 — *"the dance is too much of the same.
    /// they should be hands in the air and each do a different little move."*
    ///
    /// **The phase offset came down to almost nothing** at the same time. It was
    /// a sixth of a beat, which was carrying all the variety when every guest had
    /// the identical move; on top of six different moves the same offset reads as
    /// six guests who cannot hear the music. The styles carry it now and the
    /// offset only takes the edge off the unison.
    private func buildGuests() {
        let styles = GuestCharacter.DanceStyle.allCases
        for (index, friend) in state.everyone.enumerated() {
            let phase = Float(index) / Float(FeestLayout.guestCount) / 22
            let character = GuestCharacter(friend: friend, role: .gast,
                                           style: styles[index % styles.count],
                                           at: FeestLayout.guestSpot(index),
                                           phase: phase, ticker: ticker, flat: flat)
            root.addChild(character.root)
            guests.append(character)
        }
    }

    private func buildToys() {
        // **A pair, one in each back corner.** A single stack made the back wall
        // lopsided, and a disco has two — owner's call, 2026-08-17.
        speakers = [FeestLayout.speakerSpot, FeestLayout.speakerSpotFar].map { spot in
            let stack = FeestProps.speakers(at: spot, flat: flat)
            root.addChild(stack.root)
            return stack
        }

        let knaller = FeestProps.popper(flat: flat)
        root.addChild(knaller)
        popper = knaller

        let ballon = FeestProps.balloon(flat: flat)
        root.addChild(ballon)
        balloon = ballon
        balloonDrift = .zero
    }

    /// **The cake, re-rendered from the spec.**
    ///
    /// This is the first thing in the game to collect on the promise `Sticker`
    /// was written for — *"the party and the wall can re-render the same cake
    /// later from the spec alone, at their own scale and their own angle"*. Every
    /// sticker she placed and every ribbon she piped is rebuilt here from polar
    /// anchors, at 1.8× instead of the decorating room's 2.5×, with no world or
    /// screen position stored anywhere.
    private func buildCake() {
        let stand = FeestProps.cakeTable(flat: flat)
        root.addChild(stand)
        table = stand

        let anchor = Entity()
        anchor.name = "TaartAnker"
        anchor.position = [FeestLayout.tableCentre.x, FeestLayout.tableTopY,
                           FeestLayout.tableCentre.y]
        root.addChild(anchor)
        cakeAnchor = anchor

        let cake = KitchenProps.cake(state.cake, flat: flat)
        cake.scale = SIMD3<Float>(repeating: FeestLayout.cakeScale)
            * (state.cake.isTall ? SIMD3<Float>(1, 1.5, 1) : SIMD3<Float>(repeating: 1))
        anchor.addChild(cake)
        cakeNode = cake

        // A sibling of the cake, not a child — `isTall` is a 1.5× Y scale on the
        // cake wrapper and a heart parented under it would come out stretched.
        // `CakeSurface` resolves `u` against the already-stretched heights, so
        // the sticker lands right and keeps its shape. Versieren's lesson,
        // inherited whole.
        let layer = Entity()
        layer.name = "Versiering"
        anchor.addChild(layer)
        stickerLayer = layer
        rebuildDecorations()

        let spot = Entity()
        spot.name = "TaartTouchSpot"
        spot.position = FeestLayout.cakeTouchSpot
        root.addChild(spot)
        cakeTouchSpot = spot
    }

    /// **The VIP rope**, in the same place every other room puts its door.
    ///
    /// `Props.vipRope` returns the same `Props.Doorway` the kitchen's leaf and
    /// the garden's gate do, so `refreshDoorInvitation`, `swingDoor` and
    /// `endRoom` are the same shape as Versieren's.
    private func buildDoorway() {
        let node = Props.vipRope(flat: flat, centre: FeestLayout.doorwayCentre)
        root.addChild(node.root)
        doorway = node

        let spot = Entity()
        spot.name = "DoorTouchSpot"
        spot.position = FeestLayout.doorTouchSpot
        root.addChild(spot)
        doorTouchSpot = spot
    }

    private func buildBaker() {
        baker?.stop()
        // **Her own spot, passed in.** `BakerCharacter` eases back to a hardcoded
        // home after a cheer, and three rooms build her somewhere that is not the
        // kitchen — this is the one that says where.
        let nina = BakerCharacter(ticker: ticker, flat: flat, home: FeestLayout.bakerSpot)
        root.addChild(nina.root)
        baker = nina
    }

    // MARK: - The cake's surface

    private var surface: CakeSurface {
        CakeSurface(origin: SIMD3<Float>(FeestLayout.tableCentre.x,
                                         FeestLayout.tableTopY,
                                         FeestLayout.tableCentre.y),
                    scale: FeestLayout.cakeScale,
                    turn: 0,
                    tall: state.cake.isTall)
    }

    private func rebuildDecorations() {
        guard let layer = stickerLayer else { return }
        layer.children.removeAll()
        let s = surface

        for sticker in state.cake.placed {
            let node = VersierProps.sticker(sticker.kind, flat: flat)
            let normal = s.localNormal(of: sticker.at)
            node.position = s.localPosition(of: sticker.at) + normal * (sticker.kind.size * 0.12)
            let up: SIMD3<Float> = sticker.kind == .kaarsje ? [0, 1, 0] : normal
            node.orientation = simd_quatf(from: [0, 1, 0], to: up)
                * simd_quatf(angle: sticker.spin, axis: [0, 1, 0])
            // **A candle she lit is still lit here.** It is the smallest thing in
            // the handover and the one most likely to be dropped, and a child who
            // lit four candles and walked into the party to find them out would
            // notice immediately.
            if sticker.kind == .kaarsje, sticker.lit == true,
               let flame = node.findEntity(named: VersierProps.flameName) as? ModelEntity {
                flame.model?.materials = [Palette.glowMaterial(Palette.butterYellow,
                                                               intensity: 2.2)]
            }
            layer.addChild(node)
        }

        for stroke in state.cake.piped {
            guard stroke.path.count >= 2 else { continue }
            let points = stroke.path.map {
                s.localPosition(of: $0) + s.localNormal(of: $0) * 0.0012
            }
            let normals = stroke.path.map { s.localNormal(of: $0) }
            let geometry = FacetedMesh.ribbon(points: points, normals: normals,
                                              width: stroke.width, thickness: stroke.width * 0.6)
            guard !geometry.positions.isEmpty else { continue }
            let colour = state.cake.colours == [.wit] || state.cake.colours.isEmpty
                ? Palette.cream : Palette.creamLight
            let material = state.cake.glows
                ? Palette.material(Palette.cream) : Palette.material(colour)
            let node = ModelEntity(mesh: FacetedMesh.mesh(geometry, flat: flat),
                                   materials: [material])
            node.name = "Roomsliert"
            layer.addChild(node)
        }
    }

    // MARK: - Step presentation

    /// One function rebuilds everything the step implies. There are two steps and
    /// what this mostly does is decide whether she can still leave — see the
    /// class comment on why the VIP rope carries the halo.
    private func applyStep(animated: Bool) {
        _ = animated
        touch.target(named: "taart")?.enabled = state.step == .dansen
        refreshDoorInvitation()
    }

    /// **The rope is inviting from the first frame, in both modes**, which is
    /// the whole of this function. `ROOMS.md` §9 has it as one of exactly two:
    /// in a room with no required action there is nothing for it to wait for.
    private func refreshDoorInvitation() {
        guard let doorway else { return }

        doorRest = KitchenLayout.doorAjarAngle
        if doorSwing == nil {
            doorway.hinge.orientation = simd_quatf(angle: doorRest, axis: [0, 1, 0])
        }
        doorway.glow?.isEnabled = true

        guard state.step == .dansen else {
            Halo.remove(doorHalo, ticker: ticker)
            doorHalo = nil
            return
        }
        guard doorHalo == nil else { return }
        let marker = Entity()
        marker.position = FeestLayout.doorHaloSpot
        root.addChild(marker)
        doorHalo = Halo.attach(to: marker, radius: FeestLayout.doorHaloRadius,
                               ticker: ticker) { _ in RoomBox.floorY }
    }

    // MARK: - Targets

    /// **Registrations are in metres here rather than in points**, and every one
    /// of them comes from `FeestLayout` where the arithmetic is done and asserted.
    /// Nothing needs the kitchen's 1.08 rescale: the box and the eye did not move.
    private func registerTargets() {
        for index in 0..<FeestLayout.padCount {
            touch.register("knop\(index)", entity: pads[index].root,
                           radius: FeestLayout.padRadius,
                           planeY: FeestLayout.padTopY) { target in
                // **A pad answers on the way down, not on the way up.** Every
                // other target in the game acts on `onTap`, which fires when she
                // lifts her finger — and a drum that sounds when you *stop*
                // hitting it is a drum whose rhythm is not yours. This is the one
                // place in the game where that distinction is audible.
                target.onDragBegan = { [weak self] _ in self?.hitPad(index) }
                target.onTap = { [weak self] in self?.namePad() }
            }
        }

        touch.register("taart", entity: cakeTouchSpot, radius: FeestLayout.cakeRadius,
                       planeY: FeestLayout.tableTopY) { target in
            target.onTap = { [weak self] in self?.tapCake() }
        }

        touch.register("deur", entity: doorTouchSpot, radius: FeestLayout.doorRadius,
                       planeY: RoomBox.floorY) { target in
            target.onTap = { [weak self] in self?.tapDoorway() }
        }

        for (index, guest) in guests.enumerated() {
            let marker = Entity()
            marker.name = "GastMarker\(index)"
            marker.position = FeestLayout.guestSpot(index)
                + SIMD3<Float>(0, FeestLayout.guestTouchY, 0)
            root.addChild(marker)
            touch.register("gast\(index)", entity: marker,
                           radius: FeestLayout.guestRadius,
                           planeY: RoomBox.floorY) { target in
                target.onTap = { [weak self] in self?.tapGuest(index) }
            }
        }

        let djMarker = Entity()
        djMarker.name = "DJMarker"
        djMarker.position = SIMD3<Float>(FeestLayout.djSpot.x, FeestLayout.djTouchY,
                                         FeestLayout.djSpot.z)
        root.addChild(djMarker)
        touch.register("dj", entity: djMarker, radius: FeestLayout.djRadius,
                       planeY: RoomBox.floorY) { target in
            target.onTap = { [weak self] in self?.tapDJ() }
        }

        registerToyTargets()

        touch.onEmptyTap = { [weak self] world in self?.tapNothing(at: world) }
        touch.onAnyTouch = { [weak self] in self?.resetIdle() }
    }

    private func registerToyTargets() {
        touch.register("discobal", entity: mirrorBall?.root,
                       radius: FeestLayout.ballTouchRadius,
                       planeY: FeestLayout.ballCentre.y) { target in
            target.onTap = { [weak self] in self?.tapMirrorBall() }
        }
        touch.register("lampen", entity: lampMarker, radius: FeestLayout.lampRadius,
                       planeY: FeestLayout.backBarY) { target in
            target.onTap = { [weak self] in self?.tapLamps() }
        }
        let speakerMarker = Entity()
        speakerMarker.name = "BoxenMarker"
        speakerMarker.position = SIMD3<Float>(FeestLayout.speakerSpot.x,
                                              FeestLayout.speakerTouchY,
                                              FeestLayout.speakerSpot.z)
        root.addChild(speakerMarker)
        touch.register("boxen", entity: speakerMarker, radius: FeestLayout.speakerRadius,
                       planeY: RoomBox.floorY) { target in
            target.onTap = { [weak self] in self?.tapSpeakers() }
        }
        touch.register("knaller", entity: popper, radius: FeestLayout.popperRadius,
                       planeY: RoomBox.floorY) { target in
            target.onTap = { [weak self] in self?.tapPopper() }
        }
        touch.register("ballon", entity: balloon, radius: FeestLayout.balloonRadius,
                       planeY: FeestLayout.balloonHome.y) { target in
            // It floats, so the plane has to come from where it actually is.
            target.tracksEntity = true
            target.onTap = { [weak self] in self?.tapBalloon() }
        }
    }

    // MARK: - The beat

    /// **One job drives the whole room**, and it steps `FeestBeat` first.
    ///
    /// Deliberately not one job per prop: `Ticker` makes no promise about the
    /// order jobs run in, and six guests reading a beat that some of them saw
    /// before it advanced and some after would be six guests very slightly out of
    /// time — which is the one flaw this room cannot have.
    private func startBeat() {
        ticker.cancel(beatJob)
        beatJob = ticker.add { [weak self] dt in
            guard let self else { return false }
            self.beat.tick(dt)
            self.stepRoom(dt)
            return true
        }
    }

    private func stepRoom(_ dt: Float) {
        for guest in guests { guest.tick(dt, beat: beat) }
        djCharacter?.tick(dt, beat: beat)

        // The ball turns once every eight beats, and its pools of light turn with
        // it — the pools are what a mirror ball is actually *for*, and they are
        // why the ball itself can be a plain faceted sphere in a style with no
        // reflections in it.
        let turn = dt / max(0.05, beat.period) * (2 * .pi / 8)
        if let ball = mirrorBall?.ball {
            ball.orientation = simd_quatf(angle: ball.orientation.angleAboutY + turn,
                                          axis: [0, 1, 0])
        }
        if let spots = ballSpots {
            spots.orientation = simd_quatf(angle: spots.orientation.angleAboutY + turn,
                                           axis: [0, 1, 0])
        }

        // The decks turn once a beat, which is fast enough to see the rim mark
        // travel and slow enough not to strobe.
        if let decks = booth?.decks {
            let deckTurn = dt / max(0.05, beat.period) * (2 * .pi)
            for deck in decks {
                deck.orientation = simd_quatf(angle: deck.orientation.angleAboutY + deckTurn,
                                              axis: [0, 1, 0])
            }
        }

        // The cones push out on the beat. A transform, not a material — this runs
        // every frame and the floor's repaint does not.
        let push = 1 + beat.swing * 0.22
        for stack in speakers {
            for cone in stack.cones { cone.scale = [1, 1, push] }
        }

        if flashLeft > 0 {
            flashLeft -= dt
            if flashLeft <= 0 { flashColourIndex = nil; repaintFloor(force: true) }
        }
        if beat.justLanded { repaintFloor(force: false) }

        floatBalloon(dt)
    }

    /// **Cached materials, twice a second — never rebuilt sixty times a second.**
    /// A changing set of lit tiles is stepped on the beat and repainted only
    /// then. Building a `PhysicallyBasedMaterial` per tile per frame is the one
    /// thing in this room that could cost a frame.
    /// **Only the tiles that changed are touched**, and that is the whole of why
    /// the room stopped stuttering.
    ///
    /// It used to rebuild every material on every beat: 36 floor tiles, 84 mirror
    /// ball tiles and 10 lamp surfaces, so **130 `PhysicallyBasedMaterial`s
    /// constructed twice a second**. Constructing one is not free, and 130 in a
    /// single frame is a spike — *a periodic one, landing exactly on the beat*,
    /// which is what the owner saw and described as a visible loop that stutters
    /// (2026-08-17).
    ///
    /// Two changes, and the second is the one that matters. Every material the
    /// room can ever need is now **built once at build time** and kept — there
    /// are only six three-step floor ladders, one lit ball colour and six lamp
    /// colours, so a few dozen materials cover every state the room has. And each surface
    /// **remembers what it is wearing**, so a beat assigns only to the handful
    /// that actually changed: about fourteen floor tiles, twelve ball tiles and
    /// nothing at all on the lamps unless the colour stepped.
    ///
    /// The general form, and it is not specific to a disco: **a thing that
    /// changes on a beat should cost the change, not the count.**
    private func repaintFloor(force: Bool) {
        guard force || beat.count != lastLitStep else { return }
        lastLitStep = beat.count

        // **Random, and coloured — both on the owner's call, 2026-08-17**:
        // *"the disco floor should be more coloured. now it just looks very
        // bright and white. and it should vary in time. random."*
        //
        // It was a diagonal band stepping one tile in four, painted in the pale
        // pad colours at `glowPeak`. Two things were wrong with that and they
        // compounded. The **pattern** was legible, so after two beats you could
        // see the rule and the floor stopped being a disco and became a
        // screensaver. And the **colour** was gone: a pale pastel at 2.34
        // emissive is above white by the time it is tonemapped, so all six came
        // back the same.
        if let floor = danceFloor {
            if floorWear.count != floor.tiles.count {
                floorWear = Array(repeating: -1, count: floor.tiles.count)
            }
            for (index, tile) in floor.tiles.enumerated() {
                // -1 is unlit; 0..<n is an index into `floor.glowing`.
                let wanted: Int
                if let flash = flashColourIndex {
                    // A pad tap paints the whole floor one colour for a beat,
                    // which is the one moment the floor is *not* random — because
                    // it is answering her finger, and an answer that looked like
                    // noise would not read as an answer at all.
                    wanted = flash
                } else if Float.random(in: 0..<1) < 0.4 {
                    wanted = Int.random(in: 0..<floor.glowing.count)
                } else {
                    wanted = -1
                }
                guard wanted != floorWear[index] else { continue }
                floorWear[index] = wanted
                // The shipping tile is one smoothly textured plane; the modelled
                // failure fallback is three bands. Either way, the cached material
                // at the part's step preserves the rectangular falloff.
                for part in tile {
                    part.mesh.model?.materials = [wanted < 0 ? part.dark
                                                             : floor.glowing[wanted][part.shadeStep]]
                }
            }
        }

        // **A handful of the ball's tiles catch the light on each beat.** The
        // ball itself is matte — that is what stopped it being a glowing blob —
        // so this is the only thing about it that is not, and it is what a mirror
        // ball actually does: a few tiles at a time are the ones facing a lamp.
        // Deterministic per beat rather than random, because the lit tiles should
        // travel as the ball turns rather than flicker in place.
        if let ball = mirrorBall {
            if ballWear.count != ball.tiles.count {
                ballWear = Array(repeating: false, count: ball.tiles.count)
            }
            let count = ball.tiles.count
            for (index, tile) in ball.tiles.enumerated() {
                let wanted = (index * 7 + beat.count * 5) % count < 6
                guard wanted != ballWear[index] else { continue }
                ballWear[index] = wanted
                tile.model?.materials = [wanted ? ball.glowing : ball.dark[index]]
            }
        }

        // The lamps step their colour with the floor, so the whole room changes
        // at once rather than in two conversations — and they only change when
        // the step does, which under a flash is not at all.
        let lampStep = flashColourIndex ?? beat.count
        if lampStep != lastLampStep || force {
            lastLampStep = lampStep
            for (index, lamp) in lamps.enumerated() {
                let slot = ((index + lampStep) % FeestLayout.discoColours.count
                            + FeestLayout.discoColours.count) % FeestLayout.discoColours.count
                lamp.lens.model?.materials = [lampLens[slot]]
                lamp.beam.model?.materials = [lampBeam[slot]]
            }
        }
    }

    // MARK: - The pads

    /// **The one required-feeling thing in a room with no requirement.**
    ///
    /// She hits a pad; the room answers on the beat she just made. Nothing is
    /// gated on it, nothing counts it, and there is no wrong pad — §6.5's *"six
    /// big pads, one per instrument"* and nothing more.
    private func hitPad(_ index: Int) {
        beat.tap()
        resetIdle()

        let colour = FeestLayout.discoColour(index)
        flashColourIndex = index % FeestLayout.floorLitColours.count
        flashLeft = min(0.28, beat.period * 0.55)
        repaintFloor(force: true)

        let pad = pads[index]
        ticker.squash(pad.cap, amount: 0.34, duration: 0.26)
        Sparkles.burst(at: pad.root.position + [0, FeestLayout.padHeight + 0.004, 0],
                       in: root, ticker: ticker, colour: colour,
                       count: 5, size: 0.0022, speed: 0.07, life: 0.5, glow: 1)
        sound.play(Self.padSounds[index], volume: 0.55,
                   rate: Float.random(in: 0.97...1.04))

        if !saidFirstBeat {
            saidFirstBeat = true
            voice.sayWhenQuiet(FeestLine.eersteBeat)
            return
        }
        // She has sped up a long way — worth one line, once. It is the only thing
        // in the room that notices what she is doing with the beat, and noticing
        // twice would be commenting on her playing.
        if !saidFaster, beat.period < 0.34 {
            saidFaster = true
            voice.say(FeestLine.sneller, priority: .low)
            return
        }
        if Int.random(in: 0..<7) == 0 {
            voice.say(FeestLine.dansen, priority: .low)
        }
    }

    /// **Six sounds, and the sixth is borrowed.** `ROOMS.md` §10: reuse the
    /// existing cases wherever a room can. A bell pad is `ding`, which is the
    /// scale in the kitchen and the flowers in the garden, and it is already the
    /// right sound.
    private static let padSounds: [Sound] = [.trom, .ding, .toeter, .klap, .fluit, .kras]

    /// The naming layer. A pad is a *knop* whichever one it is — six words for
    /// six identical objects would be six words she has no way to tell apart.
    private func namePad() {
        voice.say(FeestLine.ditKnop, priority: .low)
    }

    // MARK: - The cake, now a toy

    /// **Tapping the cake names it.** Owner's call, 2026-08-21: it is not the
    /// way out. The eating, the thanks and the handover all live on the VIP
    /// rope, which is the thing that means *we are leaving*.
    private func tapCake() {
        guard state.step == .dansen else { return }
        resetIdle()
        if let cake = cakeNode {
            ticker.squash(cake, amount: 0.18, duration: 0.28)
        }
        Sparkles.burst(at: FeestLayout.cakeTouchSpot + [0, 0.012, 0],
                       in: root, ticker: ticker,
                       colour: state.cake.colours.first?.base ?? Palette.cream,
                       count: 6, size: 0.0022, speed: 0.06, life: 0.5)
        sound.play(.plop, volume: 0.4, rate: Float.random(in: 0.95...1.08))
        voice.say(Line.ditTaart, priority: .low)
    }

    // MARK: - The way out

    /// **She tapped the VIP rope, and that is the only thing that ends the party.**
    ///
    /// Same contract as Versieren's door: inviting from the first frame, always
    /// the same meaning. The eating used to hang off the cake; it hangs off this
    /// tap now, because the party still ends with everyone eating — it just
    /// is not the cake that says *we are done*.
    private func tapDoorway() {
        guard let doorway else { return }
        sound.play(.whoosh)
        guard state.step == .dansen else {
            swingDoor(doorway)
            return
        }
        endRoom(doorway)
    }

    /// **The end of the party.** Eating, thanks, the rope swinging open, and
    /// then — because there is no bakery to go to — a fresh party laid out
    /// behind the celebration.
    private func endRoom(_ doorway: Props.Doorway) {
        guard state.step == .dansen else { return }
        state.step = .opeten

        let matched = state.friend.matches(state.cake)
        state.wishMatched = matched
        save()

        swingDoor(doorway, hold: 2.6)
        Halo.remove(doorHalo, ticker: ticker)
        doorHalo = nil
        touch.target(named: "taart")?.enabled = false

        for guest in guests { guest.eat(for: 1.6) }
        djCharacter?.eat(for: 1.6)
        baker?.set(.cheering)
        sound.play(.knabbel, volume: 0.85)
        sound.play(.reward, volume: 0.55)

        eatTheCake()

        jobs.append(ticker.after(1.7) { [weak self] in
            guard let self else { return }
            self.sound.play(.applaus, volume: 0.7)
            for guest in self.guests { guest.settle(); guest.jump() }
            self.djCharacter?.settle()
            FeestProps.confetti(at: SIMD3<Float>(FeestLayout.floorCentre.x, 0.150,
                                                 FeestLayout.floorCentre.y),
                                in: self.root, ticker: self.ticker, count: 30, flat: self.flat)
            if matched, let star = self.guests.first { star.celebrate() }
        })

        var lines = [FeestLine.opeten, state.friend.thanksLineID]
        if matched { lines.append(FeestLine.wensGelukt) }
        lines.append(FeestLine.muurKomt)
        voice.sayInstead(lines)

        let threshold = FeestLayout.doorHaloSpot
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

        jobs.append(ticker.after(0.9) { [weak self] in self?.onExit?(.bakkerij) })
        jobs.append(voice.whenQuiet(after: 0.5, timeout: 30) { [weak self] in
            self?.startFreshParty()
        })
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
                }, done: { [weak self] in
                    self?.doorSwing = nil
                })
            }
        })
    }

    /// The cake shrinking away under six sets of teeth. Three bites, each with a
    /// crumb burst, and then it is gone.
    private func eatTheCake() {
        guard let cake = cakeNode, let layer = stickerLayer else { return }
        let start = cake.scale
        let job = ticker.tween(1.6, ease: Ease.linear, step: { [weak cake, weak layer] t in
            // Steps rather than a smooth shrink: eating is bites.
            let bites = Float(Int(t * 3)) / 3
            let left = max(0.02, 1 - bites - (t * 3 - Float(Int(t * 3))) * 0.08)
            cake?.scale = start * left
            layer?.scale = SIMD3<Float>(repeating: left)
        }, done: { [weak cake, weak layer] in
            cake?.isEnabled = false
            layer?.isEnabled = false
        })
        jobs.append(job)

        for i in 0..<3 {
            jobs.append(ticker.after(Float(i) * 0.5 + 0.1) { [weak self] in
                guard let self else { return }
                Sparkles.puff(at: FeestLayout.cakeTouchSpot, in: self.root,
                              ticker: self.ticker,
                              colour: self.state.cake.colours.first?.base ?? Palette.cream,
                              count: 7)
                if i > 0 { self.sound.play(.knabbel, volume: 0.6, rate: 1.0 + Float(i) * 0.1) }
            })
        }
    }

    /// **A new friend, a new cake, and the room put back.**
    ///
    /// The kitchen's shape: a fresh round starts behind the third cake, so a
    /// finished room is still a room. In a round the cake she brought has been
    /// eaten, so there is nothing to put back but a dealt one — which is the same
    /// answer the decorating room gives to a visit with no cake.
    private func startFreshParty() {
        // A dealt cake in both modes, because the one she brought has been eaten
        // and there is no kitchen behind this room to bake another.
        state = .fresh(cake: CakeSpec.dealt(), friend: Friend.dealt())
        beat.forget()
        saidFirstBeat = false
        saidFaster = false
        save()
        build(flat: flat)
        voice.sayWhenQuiet(FeestLine.nogeen)
    }

    // MARK: - Toys

    private func tapGuest(_ index: Int) {
        guard index < guests.count else { return }
        let guest = guests[index]
        guest.jump()
        sound.play(.plop, volume: 0.45, rate: Float.random(in: 1.1...1.5))
        Sparkles.burst(at: guest.root.position + [0, 0.100, 0], in: root, ticker: ticker,
                       colour: guest.friend.colour, count: 5, size: 0.0022,
                       speed: 0.06, life: 0.5)
        // **Mostly the guest, now and then who the guest is.** The flour sack's
        // ratio (`ROOMS.md` §5): the word she gets is usually the general one,
        // and occasionally the specific one, so the specific one stays a small
        // event rather than becoming the thing every tap says.
        voice.say(Int.random(in: 0..<4) == 0 ? guest.friend.thanksLineID
                                             : FeestLine.ditVriendje,
                  priority: .low)
    }

    /// **Tapping the DJ cycles a beat, a scratch and a shout**, in that order and
    /// round again — owner's call, 2026-08-17: *"it should rotate between
    /// dj-esque sounds. a beat, a scratch, a vocal. but all with a kid theme."*
    ///
    /// It rotates rather than picking at random, and that is the one design
    /// decision in here. A random pick repeats — three items means a one-in-three
    /// chance of hearing the same thing twice running, which on the most tapped
    /// prop in the room reads as broken rather than as chance. It is the same
    /// argument `VoiceBank.choose` makes for never playing a line variant twice
    /// running, and the shout goes *through* `VoiceBank` so it gets that for free
    /// across the five of them.
    ///
    /// **The shout is `.low` priority**, so a DJ who is enthusiastic can never
    /// talk over Nina explaining something.
    private func tapDJ() {
        djCharacter?.jump()
        if let decks = booth?.decks {
            for deck in decks { ticker.squash(deck, amount: 0.20, duration: 0.3) }
        }
        if let panel = booth?.panel { ticker.squash(panel, amount: 0.10, duration: 0.3) }

        switch djTurn % 3 {
        case 0:
            // Four beats of the drum, on her own tempo — so even the DJ's own
            // sound is the beat she is making.
            for i in 0..<4 {
                let job = ticker.after(Float(i) * beat.period * 0.5) { [weak self] in
                    self?.sound.play(.trom, volume: 0.6, rate: i == 0 ? 0.9 : 1.05)
                }
                jobs.append(job)
            }
        case 1:
            sound.play(.kras, volume: 0.65)
        default:
            sound.play(.kras, volume: 0.35, rate: 1.5)
            voice.say(FeestLine.djRoep, priority: .low)
        }
        djTurn += 1

        // The booth has no target of its own — it is entirely covered by the DJ
        // standing behind it (`FeestLayout`, and `ROOMS.md` §5) — so its word is
        // folded in here at the flour sack's ratio. Not on the shout, though:
        // two voices on one tap is the thing `.low` priority exists to stop.
        if djTurn % 3 != 0 {
            voice.say(Int.random(in: 0..<4) == 0 ? FeestLine.ditDraaideck : FeestLine.ditDJ,
                      priority: .low)
        }
    }

    private func tapMirrorBall() {
        sound.play(.sparkle, volume: 0.6)
        if let ball = mirrorBall?.ball { ticker.squash(ball, amount: 0.16, duration: 0.5) }
        // A hard spin on top of the beat's own, which decays back into it.
        var spun: Float = 0
        let job = ticker.tween(1.4, ease: Ease.out, step: { [weak self] t in
            guard let ball = self?.mirrorBall?.ball else { return }
            let target = t * 5.4
            ball.orientation = simd_quatf(angle: ball.orientation.angleAboutY + (target - spun),
                                          axis: [0, 1, 0])
            spun = target
        })
        jobs.append(job)
        for i in 0..<3 {
            jobs.append(ticker.after(Float(i) * 0.16) { [weak self] in
                guard let self else { return }
                let angle = Float.random(in: 0..<(2 * .pi))
                Sparkles.burst(at: FeestLayout.ballCentre
                                + [cos(angle) * 0.03, -0.02, sin(angle) * 0.03],
                               in: self.root, ticker: self.ticker,
                               colour: FeestLayout.discoColour(i), count: 6,
                               size: 0.0026, speed: 0.10, gravity: 0.05, life: 1.0, glow: 1)
            })
        }
        voice.say(FeestLine.ditDiscobal, priority: .low)
    }

    private func tapLamps() {
        sound.play(.ding, volume: 0.45, rate: 1.5)
        for lamp in lamps { ticker.squash(lamp.lensPivot, amount: 0.30, duration: 0.35) }
        // A colour change now rather than on the next beat, which is the whole
        // response: five lamps all changing at once is a visible thing.
        lastLitStep = -1
        lastLampStep = -2
        repaintFloor(force: true)
        voice.say(FeestLine.ditLampen, priority: .low)
    }

    /// **Both stacks answer**, though only one of them can be tapped. A pair of
    /// speakers with one side silent would be a stereo that had lost a channel,
    /// and the far one is untappable for a reason about the *screen* rather than
    /// about what it is (`FeestLayout.speakerSpotFar`).
    private func tapSpeakers() {
        sound.play(.trom, volume: 0.7, rate: 0.85)
        for stack in speakers {
            ticker.squash(stack.root, amount: 0.10, duration: 0.4)
            for cone in stack.cones { ticker.squash(cone, amount: 0.30, duration: 0.35) }
        }
        voice.say(FeestLine.ditBoxen, priority: .low)
    }

    private func tapPopper() {
        guard let knaller = popper else { return }
        sound.play(.poof, volume: 0.75, rate: 0.8)
        ticker.squash(knaller, amount: 0.26, duration: 0.4)
        FeestProps.confetti(at: knaller.position + [0, 0.040, 0], in: root,
                            ticker: ticker, count: 24, flat: flat)
        voice.say(FeestLine.ditKnaller, priority: .low)
    }

    /// **It bobs away and comes back**, which is `GAMEPLAY.md` §6.5's own
    /// description of it, and the drift is bounded so it stays in the back-left
    /// air where nothing else is. `FeestLayout.assertSpacing` deliberately does
    /// not check it — a moving target's separation is a fact about a moment — so
    /// the bound is what keeps that honest.
    private func tapBalloon() {
        guard let ballon = balloon else { return }
        sound.play(.plop, volume: 0.4, rate: 1.6)
        ticker.squash(ballon, amount: 0.22, duration: 0.45)
        balloonDrift = SIMD3<Float>(Float.random(in: -0.030...0.030),
                                    Float.random(in: 0.010...0.028),
                                    Float.random(in: -0.024...0.024))
        voice.say(FeestLine.ditBallon, priority: .low)
    }

    private func floatBalloon(_ dt: Float) {
        guard let ballon = balloon else { return }
        // Drift decays, and the balloon eases home. Two lines, and it is the
        // whole toy.
        balloonDrift *= 1 - min(1, dt * 0.8)
        let target = FeestLayout.balloonHome + balloonDrift
        ballon.position += (target - ballon.position) * min(1, dt * 1.6)
        // And a slow sway on top, so it is never quite still.
        ballon.orientation = simd_quatf(angle: sin(beat.phase * 2 * .pi) * 0.10,
                                        axis: [0, 0, 1])
    }

    /// A tap on nothing sparkles under her finger. Not optional — a screen that
    /// eats a tap silently is where she decides the iPad is broken.
    ///
    /// **And it is where the dance floor gets its word.** Sixteen tiles cannot
    /// each be a target — they are 32 mm apart and they would swallow every tap
    /// meant for a guest standing on them — but a floor with no name is a floor
    /// she cannot learn. `ROOMS.md` §5's answer for a prop covered by what stands
    /// on it is to fold its word into the tap that actually lands, and the tap
    /// that lands on a dance floor with nothing on it is this one.
    private func tapNothing(at world: SIMD3<Float>) {
        Sparkles.burst(at: world + [0, 0.004, 0], in: root, ticker: ticker,
                       colour: FeestLayout.discoColour(beat.count), count: 6,
                       size: 0.0022, speed: 0.06, life: 0.5, glow: 1)
        sound.play(.sparkle, volume: 0.22, rate: 1.4)

        // **`tileGridCentre`, not `floorCentre`.** They were the same point until
        // the lit floor grew to fill the room, and this is the one place that
        // would have gone on quietly asking about the old, smaller square.
        let half = FeestLayout.danceFloorSize / 2
        let onTheFloor = abs(world.x - FeestLayout.tileGridCentre.x) <= half
            && abs(world.z - FeestLayout.tileGridCentre.y) <= half
        if onTheFloor, Int.random(in: 0..<3) == 0 {
            voice.say(FeestLine.ditDansvloer, priority: .low)
        }
    }

    // MARK: - Room

    func greet() {
        voice.say(FeestLine.hallo)
        jobs.append(ticker.after(2.6) { [weak self] in
            guard let self, !self.beat.hasPlayed else { return }
            self.voice.sayWhenQuiet(FeestLine.opdracht)
        })
    }

    func save() {
        FeestStore.save(state)
    }

    /// **Start the party again**, and it has exactly one meaning: the same cake
    /// and the same friends, back on their feet, with the beat forgotten.
    ///
    /// `ROOMS.md` §8 is strict about the one meaning and the kitchen paid for the
    /// lesson once. Note what it does *not* do: it does not deal a new friend or a
    /// new cake. She pressed a button that means *again*, and coming back to a
    /// party full of strangers would make one button mean two things depending on
    /// whether the cake had been eaten.
    func restartRound() {
        state.step = .dansen
        state.wishMatched = nil
        beat.forget()
        saidFirstBeat = false
        saidFaster = false
        sound.play(.poof, volume: 0.4)
        voice.say(FeestLine.opnieuw)
        save()
        build(flat: flat)
    }

    /// Measured against `references/feest/roombox.png`. The shared 1200 lx dome
    /// washes pastels on device the same way it did in De Tuin. Scale ambient
    /// so a debug-panel move still moves. `-no-feest-ao` leaves the approved rig.
    static func lighting(from settings: LightingSettings) -> LightingSettings {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-no-feest-ao") {
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
        // `ContactShadows` currently writes the requested opacity into both the
        // colour alpha and the transparent blend, so 0.22 arrives as 0.22²:
        // about five percent, effectively invisible across this luminous floor.
        // Compensate locally with √opacity so Het Feest lands at the setting's
        // intended final opacity without changing the approved shadows in the
        // other rooms.
        let feestShadows = LightingSettings()
        feestShadows.contactShadowsEnabled = settings.contactShadowsEnabled
        feestShadows.contactShadowOpacity = sqrt(settings.contactShadowOpacity)
        feestShadows.contactShadowScale = settings.contactShadowScale

        var props: [Entity?] = [table, popper, booth?.root]
        props.append(contentsOf: speakers.map { $0.root })
        props.append(contentsOf: pads.map { $0.root })
        props.append(contentsOf: guests.map { $0.root })
        props.append(djCharacter?.root)
        for prop in props.compactMap({ $0 }) {
            guard prop.isEnabled else { continue }
            ContactShadows.attach(to: prop, radius: 0.020, settings: feestShadows)
            ContactShadows.update(for: prop, surfaceY: surfaceY(at: prop.position),
                                  settings: feestShadows)
        }
        // **The balloon and the mirror ball deliberately get none.** Both hang in
        // the air, and `ContactShadows` assumes a horizontal plane underneath —
        // which for the balloon is the dance floor two hand-widths below it, and
        // a disc down there is not a shadow, it is a second pool of light in the
        // wrong colour.
    }

    /// **This room's surfaces, added the moment the surfaces existed.**
    /// `ROOMS.md` §3: every surface a prop can stand on must be in the lookup, or
    /// the cue lands somewhere else. There are four, including the DJ's riser.
    private func surfaceY(at point: SIMD3<Float>) -> Float {
        let toTable = SIMD2<Float>(point.x - FeestLayout.tableCentre.x,
                                   point.z - FeestLayout.tableCentre.y)
        if simd_length(toTable) <= FeestLayout.tableRadius + 0.006 {
            return FeestLayout.tableTopY
        }
        let toDJ = SIMD2<Float>(point.x - FeestLayout.djSpot.x,
                                point.z - FeestLayout.djSpot.z)
        if simd_length(toDJ) <= FeestLayout.djPedestalRadius + 0.004 {
            return RoomBox.floorY + FeestLayout.djPedestalHeight
        }
        if RoomBox.within(point, centre: FeestLayout.boothCentre,
                          size: FeestLayout.boothSize, margin: 0.006) {
            return FeestLayout.boothTopY
        }
        // The dance floor is 2.8 mm of tile on the floor, which is under the
        // resolution of a contact shadow — everything standing on it can take the
        // floor and be right to within a hair.
        return RoomBox.floorY
    }

    func leave() {
        cancelEverything()
        save()
    }

    var debugTitle: String { RoomID.feest.title }

    var debugRows: [String] {
        [
            "Mode: \(mode == .ronde ? "ronde" : "bezoek")  ·  Stap: \(state.step.rawValue)",
            "Vriend: \(state.friend.dutchName)  ·  wens: \(Self.describe(state.friend.wish))",
            "Match: \(state.wishMatched.map { $0 ? "ja" : "nee" } ?? "nog niet")",
            "Gasten: \(state.everyone.map(\.rawValue).joined(separator: ", "))",
            "Dansjes: \(guests.map { "\($0.style)" }.joined(separator: ", "))",
            "Beat: \(beat.bpm) bpm  ·  \(beat.count) tellen"
                + (beat.hasPlayed ? "" : "  (nog niet gespeeld)"),
            "Taart: \(state.cake.kind.rawValue) · \(state.cake.placed.count) stickers",
        ]
    }

    private static func describe(_ wish: Wish) -> String {
        switch wish {
        case .kleur(let colour): return "kleur \(colour.rawValue)"
        case .effect(let effect): return "effect \(effect.rawValue)"
        case .sprinkels(let count): return "\(count) sprinkels"
        case .stickers(let kind, let count): return "\(count)× \(kind.rawValue)"
        case .tweeKleuren: return "twee kleuren"
        }
    }

    var debugActions: [(String, @MainActor () -> Void)] {
        [("Nieuw feest", { [weak self] in self?.startFreshParty() }),
         ("Tik de uitgang", { [weak self] in self?.tapDoorway() }),
         ("Wens laten kloppen", { [weak self] in self?.forceWishForTesting() })]
    }

    /// Debug only: make today's cake match today's wish, so the special move and
    /// the extra line can be looked at without baking for one.
    private func forceWishForTesting() {
        switch state.friend.wish {
        case .kleur(let colour):
            let ingredient = Ingredient.allCases.first { $0.colour == colour }
            if let ingredient { state.cake.ingredients.append(ingredient) }
        case .effect(let effect):
            let ingredient = Ingredient.allCases.first { $0.effect == effect }
            if let ingredient { state.cake.ingredients.append(ingredient) }
        case .sprinkels(let count):
            addStickersForTesting(.sprinkel, count)
        case .stickers(let kind, let count):
            addStickersForTesting(kind, count)
        case .tweeKleuren:
            state.cake.ingredients.append(contentsOf: [.aardbei, .bosbes])
        }
        save()
        build(flat: flat)
    }

    private func addStickersForTesting(_ kind: StickerKind, _ count: Int) {
        var placed = state.cake.placed
        for i in 0..<count {
            placed.append(Sticker(kind: kind,
                                  at: StickerAnchor(tier: i % CakeGeometry.tierCount,
                                                    face: .zijkant,
                                                    theta: Float(i) * 0.9,
                                                    u: 0.5),
                                  spin: Float(i) * 0.4))
        }
        state.cake.stickers = placed
        state.cake.version = 2
    }

    // MARK: - Idle

    /// The kitchen's timings, tuned nothing — 25 s, 45 s, 105 s. What is this
    /// room's own is the line, and that it is **never an instruction**: there is
    /// nothing she is failing to do, so the nudge is an offer to finish rather
    /// than a reminder to play.
    private func startIdleWatch() {
        ticker.cancel(idleJob)
        idleTime = 0
        nudgeStage = 0
        idleJob = ticker.add { [weak self] dt in
            guard let self else { return false }
            self.idleTime += dt
            if self.nudgeStage == 0, self.idleTime > 45, self.state.step == .dansen {
                self.nudgeStage = 1
                self.voice.say(self.alternateNudge ? FeestLine.stil : FeestLine.zullenWeGaan,
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

    /// **Every job id and every halo.** `ROOMS.md` §11: a `Ticker` job a torn-down
    /// room still holds keeps animating a detached entity forever, and nothing on
    /// screen says so. The guests own jobs of their own, which is why each of them
    /// is stopped rather than merely dropped.
    private func cancelEverything() {
        for job in jobs { ticker.cancel(job) }
        jobs.removeAll()
        ticker.cancel(beatJob)
        beatJob = nil
        ticker.cancel(idleJob)
        idleJob = nil
        ticker.cancel(doorSwing)
        doorSwing = nil
        doorRest = 0
        Halo.remove(doorHalo, ticker: ticker)
        doorHalo = nil
        doorTouchSpot = nil
        doorway = nil
        for guest in guests { guest.stop() }
        djCharacter?.stop()
        djCharacter = nil
        baker?.stop()
        baker = nil
        flashColourIndex = nil
        flashLeft = 0
        floorWear.removeAll()
        ballWear.removeAll()
        touch.onEmptyTap = nil
        touch.onAnyTouch = nil
        touch.onMoved = nil
    }
}

// MARK: - Line ids

/// **The party's voice, spelled once.** `script-feest.json`.
///
/// `VoiceBank` loads every bundled `script-*.json` automatically, so the room's
/// script needed no Swift change beyond these constants. `ROOMS.md` §4's
/// contract: every id here exists in the script, and every id in the script is
/// referenced from here.
///
/// **Three of the game's existing lines are reused rather than duplicated**,
/// because none of them says anything about a kitchen: `nina.stil` for the
/// alternating idle nudge, and — through `Friend.thanksLineID` — the eleven
/// `nina.feest.dank.*` lines, which do double duty as the naming line for a
/// guest she taps.
enum FeestLine {
    static let hallo = "nina.feest.hallo"
    /// What we are doing today, said once at the top — and only if she has not
    /// already worked it out and started playing.
    static let opdracht = "nina.feest.opdracht"
    static let eersteBeat = "nina.feest.eersteBeat"
    static let sneller = "nina.feest.sneller"
    static let dansen = "nina.feest.dansen"
    static let opeten = "nina.feest.opeten"
    /// The wish matched. Said after the friend's thanks, never instead of them.
    static let wensGelukt = "nina.feest.wensGelukt"
    /// The wall is coming. **Soon, not now** — `ROOMS.md` §9, and it is the one
    /// line in this room that has to be careful, because §6.6 does not exist.
    static let muurKomt = "nina.feest.muurKomt"
    static let nogeen = "nina.feest.nogeen"
    static let opnieuw = "nina.feest.opnieuw"
    /// Idle. An offer to finish, NOT an instruction. Reuses Versieren's
    /// *zullen we gaan?* until the party has its own three variants — the old
    /// `zullenWeEten` told her to tap the cake, which is no longer the exit.
    static let zullenWeGaan = "nina.versieren.zullenWeGaan"
    static let zullenWeEten = "nina.feest.zullenWeEten"
    /// The kitchen's, reused: *"ik ben er nog, hoor"*.
    static let stil = "nina.stil"

    // The naming layer — one variant each, deliberately.
    static let ditDiscobal = "nina.dit.discobal"
    static let ditDJ = "nina.dit.dj"
    /// **The DJ's own voice, and the only line in the game that is not Nina's or
    /// Otto's.** Five shouts, rotated by `VoiceBank` so the same one never lands
    /// twice running. Cast as Benji in `audio/voices.json`.
    static let djRoep = "dj.feest.roep"
    static let ditDraaideck = "nina.dit.draaideck"
    static let ditKnop = "nina.dit.knop"
    static let ditLampen = "nina.dit.lampen"
    static let ditBoxen = "nina.dit.boxen"
    static let ditKnaller = "nina.dit.knaller"
    static let ditBallon = "nina.dit.ballon"
    static let ditVriendje = "nina.dit.vriendje"
    /// Said on a tap that lands on the empty dance floor — see
    /// `FeestRoom.tapNothing`.
    static let ditDansvloer = "nina.dit.dansvloer"
}

// MARK: -

private extension simd_quatf {
    /// The rotation about +Y, for a quaternion that only ever turns about it.
    /// The decorating room has the same extension for the same reason; it is
    /// `private` in both, which is the cheaper of the two ways to avoid a
    /// collision until a third room wants it.
    ///
    /// **The minus sign is load-bearing and it was missing.** A turn of θ about
    /// +Y sends (1, 0, 0) to (cos θ, 0, −sin θ) — the right-hand rule curls +Z
    /// towards +X — so `atan2(v.z, v.x)` is `atan2(−sin θ, cos θ)`, which is
    /// **−θ**. Reading the angle back therefore returned its negative.
    ///
    /// Everything in this room that spins accumulates by reading its own angle
    /// and adding to it (`stepRoom`, `celebrate`), and with the sign inverted
    /// that recurrence is `aₙ₊₁ = −aₙ + turn`, which does not rotate: it
    /// **alternates between 0 and `turn` on every frame**. The mirror ball, its
    /// pools of light on the floor and both of the DJ's platters were all
    /// vibrating in place at the frame rate rather than turning — owner,
    /// 2026-08-18: *"the disco ball seems like its spinning extremely fast.
    /// glitching."*
    ///
    /// Verified against `simd` rather than argued: with the sign the angle
    /// accumulates 0.1, 0.2, 0.3…; without it, 0.1, 0, 0.1, 0.
    var angleAboutY: Float {
        let v = act(SIMD3<Float>(1, 0, 0))
        return atan2(-v.z, v.x)
    }
}
