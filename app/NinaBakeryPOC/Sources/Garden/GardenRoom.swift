import Foundation
import RealityKit
import simd

/// De Tuin — the garden, `GAMEPLAY.md` §6.2.
///
/// **Required: plant, water, pick — five ingredients into the basket.** Eight
/// seed jars on a potting bench, five holes in a raised bed, a watering can that
/// grows whatever it sweeps over, and ripe plants that hop into the basket. Six
/// toys that gate nothing.
///
/// **It has a fence, not walls.** `references/REFERENCES.md` §1 gives every room
/// two walls and a floor; this one has a picket fence standing exactly where the
/// plaster stood, on the owner's call, because a garden with walls around it is
/// a garden indoors. The rule's purpose is untouched — the two near sides are
/// still open and nothing new is in a sightline. `app/README.md` records it.
///
/// Built to the contract De Keuken wrote down (`ROOMS.md`): same chair, same
/// step machine, same halo, same voice rules, same carrying — which is
/// `CarryController` rather than two hundred lines copied out of `KitchenRoom`.
///
/// Three things here are worth naming because the obvious implementation is the
/// wrong one:
///
/// - **The halo never lights a seed jar.** Every jar is a right answer, so
///   lighting one would be a lie. The *hole* is the instruction — which is what
///   `GAMEPLAY.md` §6.2 means by "the halo belongs to the required action and
///   the garden's required action is the bed". The jars get the idle shimmer.
/// - **A pass of the can grows what it crosses, once.** Waving it over one
///   plant does nothing; sweeping across five advances five. It is the rolling
///   pin's rule with two radii instead of a travel count.
/// - **A ripe plant answers a tap by being picked; an unripe one answers by
///   saying what it is.** That is the only place in the game where a tap is not
///   a naming line, and it is `GAMEPLAY.md` §6.2's explicit instruction.
@MainActor
final class GardenRoom: Room {

    let root = Entity()

    /// Set by `GameScene`. The garden says *the basket is picked* and hands back
    /// control; it does not know the kitchen exists.
    var onExit: ((RoomExit) -> Void)?

    /// Which way she came in. `ROOMS.md` §9: one flag, not two implementations.
    /// The garden reads it nowhere yet — sowing, watering and picking are the
    /// same either way, and a full basket is the completion rule in both modes
    /// (owner's call, 2026-08-16) — but it is stored so the room is spelled like
    /// the other two, and so the day the bakery hub lands the door has something
    /// to ask.
    let mode: RoomMode

    private let ticker: Ticker
    private let touch: TouchRouter
    private let voice: VoiceBank
    private let sound: SoundKit

    private(set) var state: GardenState
    private var settings: LightingSettings
    private var flat = true

    private var carrier: CarryController!

    // Props with state.
    private var jars: [Entity] = []
    private var plants: [Entity?] = []
    /// An empty marker at each hole, so the halo has something to sit on when
    /// the hole is empty — which is exactly when it needs one.
    private var plotMarkers: [Entity] = []
    private var can: GardenProps.WateringCan?
    private var basket: GardenProps.Basket?
    private var basketTokens: [Entity] = []
    private var flowers: [Entity] = []
    private var molehill: GardenProps.Molehill?
    private var butterfly: Entity?
    private var bee: Entity?
    private var pond: Entity?
    private var pondTouchSpot: Entity?
    private var doorway: Props.Doorway?
    private var doorMarker: Entity?
    private var doorTouchSpot: Entity?
    private var doorHalo: Halo.Handle?
    private var doorSwing: Int?
    private var doorRest: Float = 0
    private var halo: Halo.Handle?

    /// **The seed she is carrying**, which exists only while it is in the air.
    ///
    /// Unlike every prop in the kitchen, this one is *created* by the drag: a
    /// jar is a bottomless supply, so a grab makes a seed and a drop either
    /// plants it or leaves it lying on the ground. Repeats are allowed and
    /// wanted — `GAMEPLAY.md` §5: five rainbow strawberries make a very pink
    /// cake indeed.
    private var carriedSeed: (ingredient: Ingredient, entity: Entity)?
    /// Seeds she dropped somewhere that was not a hole. They stay where she put
    /// them (`ROOMS.md` §6) and they are cleared on a rebuild.
    private var strays: [Entity] = []
    /// Names the strays' touch targets apart. A stray picked up and put down
    /// again gets a fresh one and the old is left disabled with a nil weak
    /// entity, which `TouchRouter.hitTest` skips — bounded by how often she does
    /// it, and cleared outright by the next `build`.
    private var strayTargets = 0

    /// **Which holes this sweep of the can has already watered.**
    ///
    /// A hole goes in when the rose comes within `waterRadius` and comes out
    /// again only once the rose has left `waterReleaseRadius`. The gap between
    /// the two is what makes it a *pass*: without it a hand holding still over
    /// one plant would pump it to ripe, and with a single radius the jitter of a
    /// 4-year-old's finger on the boundary would do the same thing more slowly.
    private var wateredThisPass: Set<Int> = []
    private var wateringJob: Int?
    /// Whether this drag of the can has grown anything, and how far it has
    /// travelled. Together they are the rainbow toy — a long swing that watered
    /// nothing. See `dropCan`.
    private var wateredThisDrag = false
    private var canTravel: Float = 0
    private var canLastPoint: SIMD3<Float>?

    private var missCount = 0
    private var missStep: GardenStep?

    private var idleJob: Int?
    private var idleTime: Float = 0
    private var nudgeStage = 0
    private var alternateNudge = false
    private var hintJob: Int?
    private var hintEntity: Entity?
    private var hintScale = SIMD3<Float>(repeating: 1)

    private var flierJobs: [Int] = []
    private var moleJob: Int?
    /// Where her finger last was, so the butterfly has something to follow.
    private var lastTouchPoint: SIMD3<Float>?

    init(ticker: Ticker, touch: TouchRouter, voice: VoiceBank,
         sound: SoundKit, settings: LightingSettings, mode: RoomMode = .bezoek) {
        self.ticker = ticker
        self.touch = touch
        self.voice = voice
        self.sound = sound
        self.settings = settings
        self.mode = mode
        self.state = GardenStore.load()
        root.name = "Garden"

        let carrier = CarryController(ticker: ticker, sound: sound,
                                      surfaces: GardenLayout.surfaces, settings: settings)
        // The basket is the only thing in the room with an inside a carried prop
        // could clip. The bed is a `Surfaces.Rect` rather than a container,
        // because it is furniture that does not move.
        carrier.containers = { [weak self] in
            guard let self, let basket = self.basket else { return [] }
            return [(basket.root, GardenLayout.basketRimY, 0.030)]
        }
        // **A plant stands on the soil, not on the rim.**
        //
        // The bed is one `Surfaces.Rect` at `bedRimY`, which is right for a
        // *carried* prop — the rim is what a seed would otherwise clip on its
        // way across. It is wrong for the halo, which asks what a prop is
        // standing on: the holes are sunk 10 mm below the rim, so without this
        // the ring for a hole or a plant would float a centimetre above the bed
        // with the thing it is pointing at underneath it.
        //
        // It is the kitchen's shelf bug in miniature, and it is the reason
        // `CarryController` keeps the two questions apart at all: the halo's
        // exception and the drag's exception are not the same exception.
        carrier.restingExtra = { [weak self] _, entity in
            guard let self else { return nil }
            let isBedThing = self.plotMarkers.contains { $0 === entity }
                || self.plants.contains { $0 === entity }
            return isBedThing ? GardenLayout.bedSoilY : nil
        }
        carrier.onPickUp = { [weak self] _ in self?.stopHint() }
        carrier.onMiss = { [weak self] in self?.noteMiss() }
        self.carrier = carrier
    }

    // MARK: - Building

    /// Rebuild everything from `state`. Called on entry, on a flat-shading flip,
    /// and after a restart — which is only possible because the room is a pure
    /// function of the round (`ROOMS.md` §1).
    func build(flat: Bool) {
        self.flat = flat
        cancelEverything()
        root.children.removeAll()
        touch.removeAll()
        jars.removeAll()
        plants.removeAll()
        plotMarkers.removeAll()
        flowers.removeAll()
        pond = nil
        pondTouchSpot = nil
        basketTokens.removeAll()
        strays.removeAll()
        strayTargets = 0
        carriedSeed = nil

        root.addChild(GardenRoomBuilder.build(flat: flat))

        buildJars()
        buildPlots()
        buildCan()
        buildBasket()
        buildToys()
        buildGate()

        registerTargets()
        applyStep(animated: false)
        startIdleWatch()
        startFliers()
    }

    private func buildJars() {
        for (index, ingredient) in Ingredient.allCases.enumerated() {
            let jar = GardenProps.seedJar(ingredient, flat: flat)
            jar.position = GardenLayout.jarSpot(index)
            jar.name = "Jar\(index)_\(ingredient.rawValue)"
            root.addChild(jar)
            jars.append(jar)
        }
    }

    /// One marker per hole, plus whatever is growing in it.
    ///
    /// The marker is an empty entity at the soil, and it exists for the halo:
    /// during `zaaien` the lit thing is a *hole*, which is a ring cut into the
    /// bed rather than a prop, and `Halo.attach` needs something with a
    /// position. An empty entity rather than a hidden model, because the halo
    /// only ever reads one.
    private func buildPlots() {
        for index in 0..<GardenLayout.plotCount {
            let marker = Entity()
            marker.name = "Plot\(index)"
            marker.position = GardenLayout.plotSpot(index)
            root.addChild(marker)
            plotMarkers.append(marker)

            guard let seed = state.plots[index].seed else {
                plants.append(nil)
                continue
            }
            let plant = GardenProps.plant(seed, growth: state.plots[index].growth, flat: flat)
            plant.position = GardenLayout.plotSpot(index)
            root.addChild(plant)
            plants.append(plant)
        }
    }

    private func buildCan() {
        let node = GardenProps.wateringCan(flat: flat)
        node.root.position = GardenLayout.canHome
        root.addChild(node.root)
        can = node
        ContactShadows.attach(to: node.root, radius: 0.026, settings: settings)
        ContactShadows.update(for: node.root, surfaceY: GardenLayout.floorY, settings: settings)
    }

    private func buildBasket() {
        let node = GardenProps.basket(flat: flat)
        node.root.position = GardenLayout.basketHome
        root.addChild(node.root)
        basket = node
        ContactShadows.attach(to: node.root, radius: 0.030, settings: settings)
        ContactShadows.update(for: node.root, surfaceY: GardenLayout.floorY, settings: settings)
        refreshBasketContents(animated: false)
    }

    private func buildToys() {
        // **Five flowers, low to high, left to right.** The heights are the
        // scale made visible: she can see that the row goes somewhere before she
        // has heard it.
        let petals: [UIColorLike] = [Palette.blushPink, Palette.creamLight, Palette.rose,
                                     Palette.mintLight, Palette.blushPinkDeep]
        for index in 0..<GardenLayout.flowerCount {
            let height = 0.024 + Float(index) * 0.0055
            let flower = GardenProps.flower(petal: petals[index % petals.count],
                                            centre: Palette.butterYellow,
                                            height: height, flat: flat)
            flower.position = GardenLayout.flowerSpot(index)
            flower.name = "Flower\(index)"
            root.addChild(flower)
            flowers.append(flower)
        }

        let hill = GardenProps.molehill(flat: flat)
        hill.root.position = GardenLayout.molehillSpot
        // Mo starts under the earth. He only ever comes up when she taps.
        hill.mole.position = [0, -0.014, 0]
        root.addChild(hill.root)
        molehill = hill

        let flutter = GardenProps.butterfly(flat: flat)
        flutter.position = GardenLayout.butterflyHome
        root.addChild(flutter)
        butterfly = flutter

        let buzzer = GardenProps.bee(flat: flat)
        buzzer.position = GardenLayout.beeHome
        root.addChild(buzzer)
        bee = buzzer

        // **The pond, and nothing in it.** Two puddles stood out on this floor;
        // one pond replaces both, on the owner's call, and a second call made it
        // an oval across the whole front of the lawn. It is built last of the
        // toys for the same reason it is placed first in `GardenLayout`:
        // everything else in the near foreground is positioned around it, not
        // the other way about.
        //
        // **It is not turned, and that is the one thing to know about it.**
        // Every other prop that wants to face the camera is built round its own
        // axis and turned by `towardsCamera`; this one is built in the room's
        // own coordinates, because the thing that decides its shape is where the
        // lawn ends. `GardenProps.pond` lays the long axis on the X−Z diagonal
        // itself and clips the outline against `pondCut`.
        let pool = GardenProps.pond(long: GardenLayout.pondLong,
                                    short: GardenLayout.pondShort,
                                    cut: GardenLayout.pondCut, flat: flat)
        pool.position = SIMD3<Float>(GardenLayout.pondCentre.x,
                                     GardenLayout.floorY,
                                     GardenLayout.pondCentre.y)
        pool.name = "Pond"
        root.addChild(pool)
        pond = pool

        // The tap goes on a marker in the middle of the *visible* water rather
        // than on the pond's origin, which sits out under the clipped corner.
        // Same trick as the gate's `GateTouchSpot`, and for the same reason: a
        // sphere at a prop's origin is a sphere somewhere she is not aiming.
        let spot = Entity()
        spot.name = "PondTouchSpot"
        spot.position = GardenLayout.pondTouchSpot
        root.addChild(spot)
        pondTouchSpot = spot
    }

    /// **The gate**, which is what this room has instead of a door.
    ///
    /// `Props.gate` returns the same `Props.Doorway` the kitchen's door does, so
    /// everything downstream — `refreshDoorInvitation`, `swingDoor`, `endRoom`,
    /// the touch target, the halo — is unchanged.
    private func buildGate() {
        let node = Props.gate(flat: flat, centre: GardenLayout.gateCentre)
        root.addChild(node.root)
        doorway = node

        let marker = Entity()
        marker.name = "GateHaloSpot"
        marker.position = SIMD3<Float>(GardenLayout.gateCentre.x + 0.004,
                                       GardenLayout.floorY,
                                       GardenLayout.gateCentre.z)
        root.addChild(marker)
        doorMarker = marker

        // At the middle of the leaf, not at the gate's origin — which is on the
        // ground, so a sphere there covers the bottom of it and nothing else. A
        // 4-year-old aims at the middle; the kitchen paid for finding that out.
        let hit = Entity()
        hit.name = "GateTouchSpot"
        hit.position = SIMD3<Float>(GardenLayout.gateCentre.x + 0.010,
                                    GardenLayout.floorY + GardenLayout.fenceHeight / 2,
                                    GardenLayout.gateCentre.z)
        root.addChild(hit)
        doorTouchSpot = hit
    }

    // MARK: - Targets

    /// **Every radius is the kitchen's**, including the 1.08 the camera pull-back
    /// bought it. They are world-space spheres satisfying a rule about the
    /// screen (`CONCEPT.md` §5's ~120 pt targets), the box has not changed and
    /// the chair has not moved, so nothing here is any harder to hit than it is
    /// in the kitchen. **If the camera moves, these move with it.**
    private func registerTargets() {
        for (index, jar) in jars.enumerated() {
            let ingredient = Ingredient.allCases[index]
            touch.register("jar\(index)", entity: jar, radius: 0.026,
                           planeY: GardenLayout.jarSpot(index).y) { target in
                target.onDragBegan = { [weak self] world in
                    self?.takeSeed(ingredient, from: jar, at: world)
                }
                target.onDragMoved = { [weak self] world in self?.carrier.move(to: world) }
                target.onDragEnded = { [weak self] world in self?.dropSeed(at: world) }
                // A jar names its *ingredient*, through the same line the
                // kitchen says when she taps the berry — so the word she learns
                // here is the word she hears there. One tap in four names the
                // bench instead, which is the only place `werkbank` can be
                // said: the bench is covered in these eight jars, so a target of
                // its own would never win one.
                target.onTap = { [weak self] in
                    self?.sayName(Int.random(in: 0..<4) == 0 ? Line.Dit.werkbank
                                                             : ingredient.nameLineID,
                                  wobbling: jar)
                }
            }
        }

        // **One target per hole**, live whether or not something is growing in
        // it, because it always answers: a ripe plant is picked, an unripe one
        // says what it is, and an empty hole says it is a hole.
        for index in 0..<GardenLayout.plotCount {
            touch.register("plot\(index)", entity: plotMarkers[index], radius: 0.030,
                           planeY: GardenLayout.bedSoilY) { target in
                target.onTap = { [weak self] in self?.tapPlot(index) }
            }
        }

        touch.register("can", entity: can?.root, radius: 0.040,
                       planeY: GardenLayout.floorY) { target in
            target.tracksEntity = true
            target.onDragBegan = { [weak self] world in self?.takeCan(at: world) }
            target.onDragMoved = { [weak self] world in self?.sweepCan(to: world) }
            target.onDragEnded = { [weak self] _ in self?.dropCan() }
            target.onTap = { [weak self] in
                self?.sayName(Line.Dit.gieter, wobbling: self?.can?.root)
            }
        }

        touch.register("basket", entity: basket?.root, radius: 0.038,
                       planeY: GardenLayout.floorY) { target in
            target.onTap = { [weak self] in
                self?.sayName(Line.Dit.mandje, wobbling: self?.basket?.root)
            }
        }

        touch.register("doorway", entity: doorTouchSpot, radius: 0.056,
                       planeY: GardenLayout.floorY) { target in
            target.onTap = { [weak self] in self?.tapDoorway() }
        }

        registerToyTargets()

        touch.onEmptyTap = { [weak self] world in self?.tapNothing(at: world) }
        touch.onAnyTouch = { [weak self] in self?.resetIdle() }
        // The butterfly follows her finger wherever it goes, which is the one
        // toy in the game that answers a touch that was not aimed at it.
        touch.onMoved = { [weak self] world in self?.lastTouchPoint = world }
    }

    private func registerToyTargets() {
        for (index, flower) in flowers.enumerated() {
            touch.register("flower\(index)", entity: flower, radius: 0.024,
                           planeY: GardenLayout.floorY) { target in
                target.onTap = { [weak self] in self?.tapFlower(index) }
            }
        }
        touch.register("molehill", entity: molehill?.root, radius: 0.038,
                       planeY: GardenLayout.floorY) { target in
            target.onTap = { [weak self] in self?.tapMolehill() }
        }
        touch.register("butterfly", entity: butterfly, radius: 0.030,
                       planeY: GardenLayout.butterflyHome.y) { target in
            target.tracksEntity = true
            target.onTap = { [weak self] in self?.tapButterfly() }
        }
        touch.register("bee", entity: bee, radius: 0.028,
                       planeY: GardenLayout.beeHome.y) { target in
            target.tracksEntity = true
            target.onTap = { [weak self] in self?.tapBee() }
        }
        // **45 mm, which is far smaller than the prop and deliberately so.** The
        // pond is 258 mm across, and a target that matched it would swallow the
        // basket and the flower row's near end; a target only has to be big
        // enough to hit (`CONCEPT.md` §5's ~120 pt), and the *visible* pond is
        // what she aims at. It clears the basket by 108 mm on screen against the
        // 83 the two radii need, and the nearest flower by 114 against 69.
        touch.register("pond", entity: pondTouchSpot, radius: 0.045,
                       planeY: GardenLayout.floorY) { target in
            target.onTap = { [weak self] in self?.tapPond() }
        }
        // **The marker rides the canopy, not the base.** Both of these name a
        // thing whose mass is in the air, and she taps the leaves. The tree's
        // lift tracks its canopy every time it grows (`GardenProps.tree`):
        // 160 mm is the middle of the 225 mm tree, where 75 mm was the middle
        // of the 110 mm one and is now bare trunk. Its radius tracks the canopy
        // too — 50 mm against a canopy 139 mm across, where every other prop
        // gets 36: a target a third of the prop's width inside a prop that big
        // reads as a dead zone, and `CONCEPT.md` §5's floor is a minimum rather
        // than a cap. The bush keeps its 36.
        //
        // **Its two nearest rivals both clear it comfortably**, measured as the
        // camera sees them (`RoomBox.screenSeparation`, not `distanceXZ` — this
        // is a question about telling targets apart). The bush sits 169 mm away
        // against 86 mm of combined radius; the top-left seed jar, the tighter
        // of the two and the one worth naming, sits 116 mm away against 76 mm.
        // Growing the canopy pushed this marker *up* the screen and away from
        // both, so it is looser here than it was at half the height.
        for (index, spot) in [GardenLayout.treeSpot, GardenLayout.bushSpots[0]].enumerated() {
            let marker = Entity()
            marker.name = "Greenery\(index)"
            marker.position = spot + [0, index == 0 ? 0.160 : 0.020, 0]
            root.addChild(marker)
            touch.register("greenery\(index)", entity: marker,
                           radius: index == 0 ? 0.050 : 0.036,
                           planeY: spot.y) { target in
                target.onTap = { [weak self] in
                    self?.sayName(index == 0 ? Line.Dit.boom : Line.Dit.struik,
                                  wobbling: nil)
                }
            }
        }
        // **The fence has no single entity to hang a target on**, so it gets a
        // marker at a clear stretch of the back run. Small on purpose — 22 mm
        // rather than the 30 a prop gets: it is a bonus word rather than a
        // gameplay target, and every neighbour it might lose a tap to answers
        // with a word of its own.
        //
        // **The bench and the bed do not get one, and that is not an
        // oversight.** Both are large props entirely covered by smaller targets
        // — eight jars, five holes — and `TouchRouter` picks the nearest centre,
        // so a marker anywhere on either of them loses every tap it would ever
        // be offered. Their words are folded into the things standing on them
        // instead: see `tapPlot` for `zaaibak` and the jar targets for
        // `werkbank`. Same trick as `sayToy`, and the same one the kitchen's
        // flour sack has always used.
        let fenceMarker = Entity()
        fenceMarker.name = "FenceSpot"
        fenceMarker.position = [0.100,
                                GardenLayout.floorY + GardenLayout.fenceHeight / 2,
                                GardenLayout.fenceLineZ]
        root.addChild(fenceMarker)
        touch.register("fence", entity: fenceMarker, radius: 0.022,
                       planeY: fenceMarker.position.y) { target in
            target.onTap = { [weak self] in self?.sayName(Line.Dit.hek, wobbling: nil) }
        }
    }

    /// **A tap said what the thing is.** `.low` priority, so a name can never
    /// talk over the instruction it would be explaining, and a burst of taps
    /// gets one name rather than a pile-up. `ROOMS.md` §4.
    private func sayName(_ lineID: String, wobbling entity: Entity?) {
        if let entity, entity.isEnabled { ticker.squash(entity, amount: 0.13) }
        sound.play(.stirTick, volume: 0.3, rate: 1.25)
        voice.say(lineID, priority: .low)
    }

    // MARK: - Step presentation

    private func applyStep(animated: Bool) {
        refreshDoorInvitation()
        refreshInteractivity()
    }

    /// Which targets are live right now.
    ///
    /// Note what this does *not* do: it never disables a toy, never disables the
    /// door, and never disables a hole. The one thing that goes quiet is a seed
    /// jar while she is already holding a seed — a second seed mid-carry is a
    /// drag with no meaning, and the kitchen's rule is that only what is
    /// genuinely not there gets switched off.
    private func refreshInteractivity() {
        let holding = carriedSeed != nil
        for index in jars.indices {
            touch.target(named: "jar\(index)")?.enabled = !holding
        }
        refreshHalo()
    }

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
            guard let self, let target else { return GardenLayout.surfaces.y(at: point) }
            return self.carrier.surfaceUnder(point, for: target)
        })
    }

    /// **The one thing the current step is about.**
    ///
    /// `zaaien` lights **the hole**, not a jar, and that is the room's one
    /// interesting cue decision. It looks like a journey — pick a seed up, put
    /// it in a hole — and a journey is one of `ROOMS.md` §3's two sanctioned
    /// reasons to light two things at once. It is not one, because the two ends
    /// are not the same kind of thing: the destination is a fact, and the source
    /// is *her choice between eight equally right answers*. Lighting one jar
    /// would say that jar is the one, which is false; lighting all eight is not
    /// an instruction. So the bed carries it, Nina says where the seeds are, and
    /// the idle shimmer picks a jar if she stands still — which is exactly the
    /// split `GAMEPLAY.md` §6.2 describes for the wish hint.
    private func haloTarget() -> Entity? {
        switch state.step {
        case .zaaien:
            guard let index = state.nextEmptyPlot else { return nil }
            return plotMarkers.indices.contains(index) ? plotMarkers[index] : nil
        case .gieten:
            return can?.root
        case .plukken:
            guard let index = state.nextRipePlot else { return nil }
            return plants.indices.contains(index) ? plants[index] : nil
        case .klaar:
            return doorMarker
        }
    }

    /// Roughly how big the prop is — it sets how far the sparkles lift off it.
    private func haloRadius(for entity: Entity) -> Float {
        if entity === can?.root { return 0.030 }
        if entity === doorMarker { return KitchenLayout.doorHaloRadius }
        if plotMarkers.contains(where: { $0 === entity }) { return GardenLayout.plotRadius }
        return 0.022
    }

    /// **The garden is finished** — the basket is full.
    ///
    /// `ROOMS.md` §9 asks for a completion rule and one flag, not two
    /// implementations. The kitchen's visit rule is three cakes, which is more
    /// than its round rule of one; the garden's is the same in both, because a
    /// full basket *is* the garden's verb done once and there is no honest
    /// second helping of it — a sixth ingredient has nowhere to go.
    var gardenComplete: Bool { state.isFull }

    /// Put the door in the state the basket has earned. Three cues at once, and
    /// they are three ways of saying the same sentence to somebody who cannot
    /// read (`ROOMS.md` §9).
    private func refreshDoorInvitation() {
        guard let doorway else { return }
        let done = gardenComplete

        doorRest = done ? KitchenLayout.doorAjarAngle : 0
        if doorSwing == nil {
            doorway.hinge.orientation = simd_quatf(angle: doorRest, axis: [0, 1, 0])
        }

        // **The third cue is deliberately missing here**, and `doorway.glow` is
        // nil to say so rather than being switched off.
        //
        // `ROOMS.md` §9 has the way out saying the same thing three ways: the
        // leaf off the latch, a ring at the threshold, and light behind it. The
        // kitchen's light is a plate inside the wall opening. A gate in a picket
        // fence has no wall to hold one, and she can already see straight
        // through it — so the garden says it twice, on the owner's call.
        //
        // What partly stands in for it is not lit at all: the sandy path leading
        // out through the gate (`GardenLayout.pathCentre`). Ground people have
        // walked on is the one way left to say *there is somewhere to go*.

        guard done else {
            Halo.remove(doorHalo, ticker: ticker)
            doorHalo = nil
            return
        }
        // The step's own halo is already on the door at `.klaar`, so a second
        // one would be the same ring twice. It is here for the case the kitchen
        // has and this room does not yet — two right answers at once — and it is
        // kept switched off rather than deleted so the two rooms stay the same
        // shape.
        Halo.remove(doorHalo, ticker: ticker)
        doorHalo = nil
    }

    // MARK: - Zaaien

    /// **A grab on a jar makes a seed.**
    ///
    /// The jar is a bottomless supply, which is the one place this room departs
    /// from the kitchen's model of props that exist and get moved. It has to:
    /// `GAMEPLAY.md` §5 wants repeats — five rainbow strawberries make a very
    /// pink cake indeed — so a jar that could be emptied would be a rule she
    /// could break by accident.
    private func takeSeed(_ ingredient: Ingredient, from jar: Entity, at world: SIMD3<Float>) {
        guard carriedSeed == nil else { return }
        let seed = GardenProps.seedToken(ingredient, flat: flat)
        seed.position = jar.position + [0, 0.024, 0]
        root.addChild(seed)
        ContactShadows.attach(to: seed, radius: 0.008, settings: settings)
        carriedSeed = (ingredient, seed)
        ticker.squash(jar, amount: 0.10)
        refreshInteractivity()
        carrier.pickUp(seed, at: world)
    }

    /// Into a hole, or onto the ground.
    private func dropSeed(at world: SIMD3<Float>) {
        guard let (ingredient, seed) = carriedSeed else { return }
        carriedSeed = nil

        // **Nearest hole wins**, which is what makes the snap radius safe to set
        // wider than the gap between two holes: an imprecise drop always lands
        // somewhere rather than nowhere.
        var best: (index: Int, distance: Float)?
        for index in 0..<GardenLayout.plotCount where state.plots[index].isEmpty {
            let distance = GardenLayout.distanceXZ(seed.position, GardenLayout.plotSpot(index))
            if best == nil || distance < best!.distance { best = (index, distance) }
        }

        guard let hit = best, hit.distance <= GardenLayout.plotSnapRadius else {
            // **It stays where she put it.** A seed on the ground is a seed on
            // the ground; nothing is undone and nobody apologises. `ROOMS.md` §6.
            refreshInteractivity()
            strays.append(seed)
            registerStray(seed, ingredient)
            carrier.settle(seed, missed: state.step == .zaaien)
            return
        }

        carrier.end()
        seed.removeFromParent()
        plant(ingredient, in: hit.index)
        refreshInteractivity()
    }

    /// **A seed she put down somewhere is still a thing she can touch.**
    ///
    /// Without this it is not: a stray is created mid-drag, so it never went
    /// through `registerTargets`, and a seed lying on the grass answered
    /// nothing at all. `GAMEPLAY.md` §7 is blunt about it — *every tap does
    /// something; if it is on screen, it responds* — and a dead prop is the one
    /// thing that reads as a broken iPad.
    ///
    /// It can be picked up again and it says what it is, which is also the only
    /// place `nina.dit.zaadje` gets to play.
    private func registerStray(_ seed: Entity, _ ingredient: Ingredient) {
        let name = "stray\(strayTargets)"
        strayTargets += 1
        touch.register(name, entity: seed, radius: 0.024,
                       planeY: GardenLayout.floorY) { target in
            target.tracksEntity = true
            // Looked up by name rather than captured: a `Target` whose own
            // closure holds it is a retain cycle, and `TouchRouter.removeAll`
            // dropping the array would not break it.
            target.onDragBegan = { [weak self, weak seed] world in
                guard let self, let seed, self.carriedSeed == nil else { return }
                self.carriedSeed = (ingredient, seed)
                self.strays.removeAll { $0 === seed }
                self.touch.target(named: name)?.enabled = false
                self.refreshInteractivity()
                self.carrier.pickUp(seed, at: world)
            }
            target.onDragMoved = { [weak self] world in self?.carrier.move(to: world) }
            target.onDragEnded = { [weak self] world in self?.dropSeed(at: world) }
            target.onTap = { [weak self, weak seed] in
                self?.sayName(Line.Dit.zaadje, wobbling: seed)
            }
        }
    }

    private func plant(_ ingredient: Ingredient, in index: Int) {
        state.plots[index].seed = ingredient
        state.plots[index].growth = 0
        state.refreshStep()
        save()
        noteHit()

        let spot = GardenLayout.plotSpot(index)
        let sprout = GardenProps.plant(ingredient, growth: 0, flat: flat)
        sprout.position = spot
        root.addChild(sprout)
        plants[index] = sprout
        ticker.squash(sprout, amount: 0.30, duration: 0.5)

        sound.playVaried(.plop)
        Sparkles.burst(at: spot + [0, 0.014, 0], in: root, ticker: ticker,
                       colour: ingredient.tokenColour, count: 8, size: 0.0020,
                       speed: 0.055, life: 0.7)

        applyStep(animated: true)
        // The reaction interrupts, because it is about something that happened
        // this instant; the next step's line waits for it. `ROOMS.md` §4.
        voice.say(Line.Tuin.gezaaid)
        announceStep()
    }

    // MARK: - Gieten

    private func takeCan(at world: SIMD3<Float>) {
        guard let can else { return }
        // `WateringCan` is a value, so the ticker closures hold its entities
        // rather than it — the entities are what they have to be able to let go
        // of.
        let canRoot = can.root
        let stream = can.stream
        wateredThisPass.removeAll()
        wateredThisDrag = false
        canTravel = 0
        canLastPoint = world
        carrier.pickUp(canRoot, at: world)

        // The can tips as it is lifted and the water starts. Growth is driven by
        // her hand and never by a clock (`GAMEPLAY.md` §7), so the stream is
        // *feedback* rather than a timer — it says the can is pouring, and where.
        ticker.tween(0.28, ease: Ease.out, step: { [weak canRoot] t in
            canRoot?.orientation = simd_quatf(angle: -0.42 * t, axis: [0, 0, 1])
        })
        stream.isEnabled = true
        stream.scale = [1, 0.05, 1]
        ticker.tween(0.30, ease: Ease.out, step: { [weak stream] t in
            stream?.scale = [1, 0.05 + 0.95 * t, 1]
        })
        // The stream turns about its own axis so its six facets travel, which is
        // the whole of what makes it read as running rather than as a blue
        // stick — the tap's lesson, `app/README.md`.
        var spin: Float = 0
        wateringJob = ticker.add { [weak stream] dt in
            guard let stream, stream.isEnabled else { return false }
            spin += dt * 6.2
            stream.orientation = simd_quatf(angle: spin, axis: [0, 1, 0])
            return true
        }
    }

    /// **A pass of the can grows what it crosses by one stage.**
    ///
    /// `GAMEPLAY.md` §6.2: one sweep across the bed advances every plant under
    /// it, three sweeps and the bed is ripe. The rule is unchanged from a single
    /// plant — a pass grows a plant a stage — it is only that a pass can cross
    /// five of them.
    ///
    /// It is measured from the **rose**, not from the can, because the two are
    /// 45 mm apart and that is more than the gap between one hole and the next.
    /// Watering from where the handle is would water the wrong plant.
    private func sweepCan(to world: SIMD3<Float>) {
        carrier.move(to: world)
        if let last = canLastPoint { canTravel += GardenLayout.distanceXZ(world, last) }
        canLastPoint = world
        guard let rose = can?.rose else { return }
        let tip = rose.position(relativeTo: nil)

        for index in 0..<GardenLayout.plotCount {
            let distance = GardenLayout.distanceXZ(tip, GardenLayout.plotSpot(index))
            if distance > GardenLayout.waterReleaseRadius {
                // Left it. The hole can be watered again on the next pass — and
                // the release radius being wider than the water radius is what
                // stops a jittering finger on the boundary from pumping it.
                wateredThisPass.remove(index)
                continue
            }
            guard distance <= GardenLayout.waterRadius,
                  !wateredThisPass.contains(index) else { continue }
            wateredThisPass.insert(index)
            wateredThisDrag = true
            water(index)
        }
    }

    private func water(_ index: Int) {
        guard let seed = state.plots[index].seed,
              state.plots[index].growth < GardenLayout.ripeStage else { return }
        state.plots[index].growth += 1
        let grown = state.plots[index].growth
        state.refreshStep()
        save()
        noteHit()

        let spot = GardenLayout.plotSpot(index)
        plants[index]?.removeFromParent()
        let plant = GardenProps.plant(seed, growth: grown, flat: flat)
        plant.position = spot
        root.addChild(plant)
        plants[index] = plant

        // It springs up rather than appearing: the growth is the reward, so it
        // has to be something she watches.
        plant.scale = [0.55, 0.35, 0.55]
        ticker.tween(0.45, ease: Ease.back, step: { [weak plant] t in
            plant?.scale = SIMD3<Float>(0.55 + 0.45 * t, 0.35 + 0.65 * t, 0.55 + 0.45 * t)
        }, done: { [weak plant] in plant?.scale = SIMD3<Float>(repeating: 1) })

        sound.play(.sparkle, volume: 0.4, rate: 0.9 + 0.18 * Float(grown))
        Sparkles.burst(at: spot + [0, 0.020, 0], in: root, ticker: ticker,
                       colour: Palette.mintLight, count: 5, size: 0.0018,
                       speed: 0.05, life: 0.6)

        if grown >= GardenLayout.ripeStage {
            Sparkles.burst(at: spot + [0, 0.032, 0], in: root, ticker: ticker,
                           colour: seed.tokenColour, count: 9, size: 0.0024,
                           speed: 0.07, life: 0.9)
            sound.play(.ovenPing, volume: 0.45)
        } else if grown == GardenLayout.ripeStage - 1 {
            // Halfway. Encouragement, never correction — the kitchen's
            // `roerenGoedZo`, and `.low` so it is dropped rather than said five
            // times over when one sweep advances the whole bed at once.
            voice.say(Line.Tuin.groeit, priority: .low)
        }
        applyStep(animated: true)
        announceStep()
    }

    private func dropCan() {
        guard let can else { return }
        // **Waving it about makes a rainbow.** `GAMEPLAY.md` §6.2's toy, and it
        // is discovered rather than explained: a long swing that watered nothing
        // is exactly what a 4-year-old does with a watering can before she
        // works out what it is for, and answering that with a rainbow is worth
        // more than answering it with nothing.
        //
        // Both conditions matter. Without the travel it would fire every time
        // she picked the can up and put it down again; without "watered
        // nothing" it would fire on the sweep that ripens the bed, which
        // already has its own answer.
        if !wateredThisDrag && canTravel > 0.14 { makeRainbow(from: can) }

        wateredThisPass.removeAll()
        canLastPoint = nil
        canTravel = 0
        ticker.cancel(wateringJob)
        wateringJob = nil
        can.stream.isEnabled = false
        let canRoot = can.root
        ticker.tween(0.25, ease: Ease.out, step: { [weak canRoot] t in
            canRoot?.orientation = simd_quatf(angle: -0.42 * (1 - t), axis: [0, 0, 1])
        }, done: { [weak canRoot] in
            canRoot?.orientation = simd_quatf(angle: 0, axis: [0, 0, 1])
        })
        // Never a miss. Sweeping the can is the step, and a sweep that grew
        // nothing is a sweep that missed the bed — which is a thing she can see
        // and fix, not a failed attempt at a target.
        carrier.settle(can.root, missed: false)
    }

    /// An arc of seven faceted bands standing over the can, which fades away.
    ///
    /// Built from the palette rather than from spectrum colours: a real rainbow
    /// in a room of six pastels is the flour-cloud mistake again — the one thing
    /// on screen that came from somewhere else (`app/README.md`). These are the
    /// room's own hues in rainbow *order*, which reads as a rainbow without
    /// leaving the palette.
    private func makeRainbow(from can: GardenProps.WateringCan) {
        let bands: [UIColorLike] = [Palette.rose, Palette.blushPink, Palette.butterYellow,
                                    Palette.sage, Palette.mint, Palette.berryBlue,
                                    Palette.lilac]
        let arc = Entity()
        arc.name = "Rainbow"
        arc.position = can.root.position + [0, 0.010, 0]
        // Turned to face the camera, like the clover and the star — an arc seen
        // edge-on is a line.
        arc.orientation = GardenProps.towardsCamera
        root.addChild(arc)

        for (i, colour) in bands.enumerated() {
            let radius = 0.070 - Float(i) * 0.0072
            // Half a ring: eleven short boxes on an arc, because `FacetedMesh`
            // has no torus and at this size straight pieces read as a curve.
            for step in 0..<11 {
                let angle = .pi * Float(step) / 10
                let piece = RoomBuilder.model(.box([0.0125, 0.0070, 0.0055]),
                                              colour, flat: flat, name: "RainbowBand\(i)")
                piece.position = [cos(angle) * radius, sin(angle) * radius, 0]
                piece.orientation = simd_quatf(angle: angle + .pi / 2, axis: [0, 0, 1])
                arc.addChild(piece)
            }
        }

        arc.scale = [0.2, 0.2, 0.2]
        ticker.tween(0.45, ease: Ease.back, step: { [weak arc] t in
            arc?.scale = SIMD3<Float>(repeating: 0.2 + 0.8 * t)
        })
        ticker.after(1.9) { [weak arc, weak self] in
            guard let self, let arc else { return }
            self.ticker.tween(0.7, ease: Ease.inCurve, step: { [weak arc] t in
                arc?.scale = SIMD3<Float>(repeating: 1 - t)
            }, done: { [weak arc] in arc?.removeFromParent() })
        }

        sound.play(.sparkle, volume: 0.5, rate: 1.15)
        Sparkles.burst(at: arc.position + [0, 0.070, 0], in: root, ticker: ticker,
                       colour: Palette.butterYellow, count: 10, size: 0.0024,
                       speed: 0.06, life: 0.9)
        voice.say(Line.Speel.regenboog, priority: .low)
    }

    // MARK: - Plukken

    /// **A tap on a hole.**
    ///
    /// Ripe: it hops into the basket, which is `GAMEPLAY.md` §6.2's own
    /// instruction and the one place in the game where a tap is not a naming
    /// line. Anything else: it says what it is, which is what a tap means
    /// everywhere else.
    private func tapPlot(_ index: Int) {
        guard state.plots.indices.contains(index) else { return }
        let plot = state.plots[index]
        guard plot.isRipe, let seed = plot.seed else {
            // An empty hole is also the one part of the bed with nothing
            // standing in it, so it is where the bed gets named — mostly "a
            // hole in the earth", one time in three "the seed tray". Both are
            // true of what her finger is on, and the tray has no target of its
            // own for the reason `registerToyTargets` gives.
            let line = plot.isEmpty
                ? (Int.random(in: 0..<3) == 0 ? Line.Dit.zaaibak : Line.Dit.gat)
                : Line.Dit.plantje
            sayName(line, wobbling: plants[index])
            return
        }
        pick(seed, from: index)
    }

    private func pick(_ ingredient: Ingredient, from index: Int) {
        guard let basket, let plant = plants[index] else { return }
        state.plots[index] = Plot()
        state.basket.append(ingredient)
        state.refreshStep()
        save()
        noteHit()
        plants[index] = nil

        // **The fruit flies, the plant does not.** She picked a strawberry, not
        // a strawberry plant, so what travels is the head and what stays behind
        // is the rosette collapsing back into the earth.
        let spot = GardenLayout.plotSpot(index)
        let flying = KitchenProps.token(ingredient, flat: flat)
        flying.position = plant.position + [0, 0.030, 0]
        root.addChild(flying)

        ticker.tween(0.42, ease: Ease.out, step: { [weak plant] t in
            plant?.scale = SIMD3<Float>(repeating: max(0.001, 1 - t))
        }, done: { [weak plant] in plant?.removeFromParent() })

        let target = basket.root.position + [0, GardenLayout.basketRimY + 0.010, 0]
        ticker.move(flying, to: target, duration: 0.55, arc: 0.055, ease: Ease.inOut) {
            [weak self, weak flying] in
            flying?.removeFromParent()
            guard let self else { return }
            self.sound.playVaried(.plop)
            self.refreshBasketContents(animated: true)
            Sparkles.burst(at: target, in: self.root, ticker: self.ticker,
                           colour: ingredient.tokenColour, count: 7, size: 0.0022,
                           speed: 0.05, life: 0.7)
        }

        sound.play(.sparkle, volume: 0.5)
        Sparkles.burst(at: spot + [0, 0.026, 0], in: root, ticker: ticker,
                       colour: ingredient.tokenColour, count: 6, size: 0.0020,
                       speed: 0.05, life: 0.6)

        applyStep(animated: true)
        // What it will do to the cake — the kitchen's own line, which is exactly
        // what she wants to know at the moment she picks it.
        voice.say(ingredient.lineID)
        announceStep()
    }

    /// What is standing in the basket. Rebuilt from `state.basket` rather than
    /// appended to, so coming back to a half-filled basket is the same code path
    /// as filling it.
    private func refreshBasketContents(animated: Bool) {
        guard let basket else { return }
        for token in basketTokens { token.removeFromParent() }
        basketTokens.removeAll()

        for (index, ingredient) in state.basket.enumerated() {
            let token = KitchenProps.token(ingredient, flat: flat)
            // Two rows of up to three, leaning in — a heap rather than a grid,
            // because a grid of five in a basket reads as a shop display.
            let row = index / 3
            let along = Float(index % 3) - 1
            token.position = [along * 0.0135 + Float(row) * 0.0065,
                              Float(row) * 0.0110,
                              Float(row) * 0.0120 - 0.0055]
            token.scale = SIMD3<Float>(repeating: 0.78)
            basket.contents.addChild(token)
            basketTokens.append(token)
            if animated, index == state.basket.count - 1 {
                ticker.squash(token, amount: 0.28, duration: 0.5)
            }
        }
    }

    // MARK: - The door

    /// Unfinished garden: it opens, shows the light, falls shut, and Nina says
    /// what it is. Basket full: it is the way out.
    private func tapDoorway() {
        guard let doorway else { return }
        sound.play(.whoosh)
        guard gardenComplete else {
            swingDoor(doorway)
            voice.say(Line.Dit.poort, priority: .low)
            return
        }
        endRoom(doorway)
    }

    /// **The end of the garden.**
    ///
    /// A ceremony rather than a transition, for the same reason the kitchen's
    /// is: there is nowhere to be taken. The bakery hub does not exist, so the
    /// round has no next room to hand to — and **a 4-year-old told she is going
    /// somewhere and then not taken there has been lied to** (`ROOMS.md` §9).
    ///
    /// What it does do is real: the basket goes out through `onExit`, so the
    /// round the kitchen starts next is baked from **what she actually grew**.
    /// She will not see the handover happen and that is fine; she will see five
    /// familiar things waiting in the kitchen's five places.
    ///
    /// **This is the one function the bakery hub replaces**, exactly as
    /// `KitchenRoom.endRoom` is the one the decorating room replaces.
    private func endRoom(_ doorway: Props.Doorway) {
        swingDoor(doorway, hold: 2.6)
        sound.play(.reward, volume: 0.7)
        save()
        voice.sayInstead(Line.Tuin.kamerDeur)

        let threshold = doorMarker?.position ?? GardenLayout.gateCentre
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

        // **Handed over on the beat the leaf reaches full open**, the same beat
        // the kitchen uses, so the swing reads as the way through rather than as
        // something that happened first. An empty basket is not a handover —
        // she opened the gate on a garden she had not picked — so that ends the
        // visit instead, which today means staying exactly where she is.
        let basket = state.basket
        ticker.after(0.9) { [weak self] in
            self?.onExit?(basket.isEmpty ? .bakkerij : .keuken(basket))
        }
    }

    /// Open, hold, fall back to `doorRest` — and re-tapping restarts it rather
    /// than stacking a second turn on top of the first.
    private func swingDoor(_ doorway: Props.Doorway, hold: Float = 1.5) {
        ticker.cancel(doorSwing)
        let hinge = doorway.hinge
        let rest = doorRest
        let open = KitchenLayout.doorOpenAngle
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
            self?.doorSwing = nil
        })
    }

    // MARK: - Toys

    /// **A toy says its name, and now and then says something silly instead.**
    ///
    /// `GAMEPLAY.md` §3 is unconditional — *every prop in every room says what
    /// it is when tapped* — and the garden's six toys were breaking it: each
    /// answered with its `Speel` chatter and never with its `Dit` name, so five
    /// Dutch words she could have learned were sitting in the script with
    /// nothing able to play them.
    ///
    /// The kitchen already had the answer and it is the flour sack: mostly the
    /// name, one time in three the joke. The name is the part that teaches, so
    /// it gets the majority; the chatter is what stops the sixth poke being the
    /// first one again.
    private func sayToy(_ name: String, _ chatter: String) {
        voice.say(Int.random(in: 0..<3) == 0 ? chatter : name, priority: .low)
    }

    /// **The flowers chime in a scale, low to high.**
    ///
    /// One `SoundKit.ding` at five rates — a pentatonic run, so any order she
    /// taps them in still sounds like music rather than like a mistake. It is a
    /// quiet rehearsal for the party's six instrument pads (`GAMEPLAY.md` §6.5),
    /// and it cost one array.
    private func tapFlower(_ index: Int) {
        guard flowers.indices.contains(index) else { return }
        // Major pentatonic: do, re, mi, so, la. No semitone in it, so there is
        // no wrong pair.
        let rates: [Float] = [1.0, 1.122, 1.260, 1.498, 1.682]
        sound.play(.ding, volume: 0.55, rate: rates[index % rates.count])
        ticker.squash(flowers[index], amount: 0.20, duration: 0.5)
        Sparkles.burst(at: flowers[index].position + [0, 0.034, 0], in: root,
                       ticker: ticker, colour: Palette.butterYellow,
                       count: 4, size: 0.0018, speed: 0.04, life: 0.5)
        sayToy(Line.Dit.bloemen, Line.Speel.bloemen)
    }

    /// Mo pops out, looks about, and goes back down.
    private func tapMolehill() {
        guard let hill = molehill else { return }
        ticker.cancel(moleJob)
        sound.playVaried(.dig)
        ticker.squash(hill.root, amount: 0.14)

        let mole = hill.mole
        let down = SIMD3<Float>(0, -0.014, 0)
        let up = SIMD3<Float>(0, 0.0135, 0)
        moleJob = ticker.tween(1.9, ease: Ease.linear, step: { [weak mole] t in
            guard let mole else { return }
            // Up fast, hold, down slower — a mole is startled on the way out and
            // unhurried on the way back.
            let amount: Float
            switch t {
            case ..<0.16: amount = Ease.back(t / 0.16)
            case ..<0.70: amount = 1
            default:      amount = 1 - Ease.inOut((t - 0.70) / 0.30)
            }
            mole.position = down + (up - down) * amount
        }, done: { [weak mole] in mole?.position = down })

        sayToy(Line.Dit.molshoop, Line.Speel.mol)
    }

    private func tapButterfly() {
        guard let butterfly else { return }
        ticker.squash(butterfly, amount: 0.22, duration: 0.4)
        sound.play(.sparkle, volume: 0.35, rate: 1.3)
        sayToy(Line.Dit.vlinder, Line.Speel.vlinder)
    }

    private func tapBee() {
        guard let bee else { return }
        sound.playVaried(.buzz)
        ticker.wiggle(bee, angle: 0.35, duration: 0.7)
        sayToy(Line.Dit.bij, Line.Speel.bij)
    }

    /// **A tap on the pond.** The puddle's splash, scaled to a pond.
    ///
    /// Squashing the whole prop would bounce the stone rim, which is a rim of
    /// stones and does not bounce, so only the water moves — and the droplets
    /// are thrown from the middle of the pool rather than from its edge.
    private func tapPond() {
        guard let pond else { return }
        sound.playVaried(.water, volume: 0.6)
        for band in pond.children where band.name.hasPrefix("PondBand")
                                     || band.name == "PondDeep" {
            ticker.squash(band, amount: 0.30, duration: 0.55)
        }
        // Thrown from the middle of the visible water rather than from the
        // pond's origin, which is out under the clipped corner.
        Sparkles.burst(at: GardenLayout.pondTouchSpot + [0, 0.010, 0], in: root,
                       ticker: ticker, colour: Palette.berryBlue, count: 12,
                       size: 0.0024, speed: 0.090, life: 0.70)
        sayToy(Line.Dit.vijver, Line.Speel.vijver)
    }

    /// **The butterfly follows her finger and the bee hovers over the flowers.**
    ///
    /// Both on the one `Ticker`, both interruptible, and neither of them ever in
    /// the way: they fly above everything and they answer a tap wherever they
    /// happen to be, which is what `tracksEntity` on their targets is for.
    private func startFliers() {
        var elapsed: Float = 0
        if let butterfly {
            flierJobs.append(ticker.add { [weak self, weak butterfly] dt in
                guard let self, let butterfly else { return false }
                elapsed += dt
                // It chases the last place she touched, slowly, and drifts on a
                // figure of eight when she is not touching anything. Slowly is
                // the whole trick: a butterfly that arrives is a cursor.
                let home = GardenLayout.butterflyHome
                let drift = SIMD3<Float>(sin(elapsed * 0.7) * 0.035, sin(elapsed * 1.9) * 0.010,
                                         sin(elapsed * 0.35) * 0.030)
                var goal = home + drift
                if let finger = self.lastTouchPoint {
                    goal = SIMD3<Float>(finger.x, home.y + sin(elapsed * 2.4) * 0.008,
                                        finger.z) + drift * 0.35
                }
                goal = GardenLayout.surfaces.clamp(goal)
                butterfly.position += (goal - butterfly.position) * (1 - exp(-dt * 1.1))
                // Wings beat by scaling across, which is one axis and reads at
                // this size better than a hinge would.
                butterfly.scale = [1, 1, 0.72 + 0.28 * abs(sin(elapsed * 9))]
                return true
            })
        }
        if let bee {
            var beeTime: Float = 0
            flierJobs.append(ticker.add { [weak bee] dt in
                guard let bee else { return false }
                beeTime += dt
                let home = GardenLayout.beeHome
                bee.position = home + [sin(beeTime * 1.3) * 0.014,
                                       sin(beeTime * 2.7) * 0.009,
                                       cos(beeTime * 0.9) * 0.042]
                return true
            })
        }
    }

    // MARK: - A tap on nothing

    /// Not optional. A screen that eats a tap silently is where she decides the
    /// iPad is broken (`GAMEPLAY.md` §7).
    private func tapNothing(at world: SIMD3<Float>) {
        sound.play(.sparkle, volume: 0.28, rate: 1.4)
        Sparkles.burst(at: world + [0, 0.006, 0], in: root, ticker: ticker,
                       colour: Palette.mintLight, count: 5, size: 0.0018,
                       speed: 0.045, life: 0.5)
    }

    // MARK: - Misses

    /// She dragged the prop the step is about and it did not land. Twice, Nina
    /// says something kind; the **third** time she says the step's own line
    /// again at full priority, and the lit prop squashes while she does.
    /// `ROOMS.md` §8 — copied from the kitchen, tuned not at all.
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
        if let target = haloTarget(), target.isEnabled {
            ticker.squash(target, amount: 0.18, duration: 0.5)
        }
    }

    private func noteHit() {
        missCount = 0
        missStep = state.step
    }

    // MARK: - Idle

    /// After ~25 s the thing she needs shimmers; after ~45 s Nina says one short
    /// line; after ~105 s it resets and may start over. It never nags and it
    /// never blocks. `ROOMS.md` §8.
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
                self.voice.say(self.alternateNudge ? Line.stil
                                                   : self.nudgeLine(for: self.state.step),
                               priority: .low)
                self.alternateNudge.toggle()
            } else if self.nudgeStage == 2 && self.idleTime > 105 {
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

    /// **The shimmer is where the seed jars get their turn.**
    ///
    /// The halo cannot point at one of eight equally right answers, but a shimmer
    /// can: it is the *idle* cue, it says "there is something over here" rather
    /// than "this one", and `GAMEPLAY.md` §6.2 asks for exactly this — the wish
    /// hint is `Ticker.shimmer` on a jar, not a halo on one. Which jar shimmers
    /// is arbitrary now and will be the wish's colour once the friends exist.
    private func hintTarget(for step: GardenStep) -> Entity? {
        switch step {
        case .zaaien: return jars.first
        case .gieten: return can?.root
        case .plukken:
            guard let index = state.nextRipePlot else { return nil }
            return plants.indices.contains(index) ? plants[index] : nil
        case .klaar: return doorTouchSpot
        }
    }

    private func nudgeLine(for step: GardenStep) -> String {
        switch step {
        case .zaaien: return Line.Tuin.zaaien
        case .gieten: return Line.Tuin.gieten
        case .plukken: return Line.Tuin.rijp
        case .klaar: return Line.Tuin.kamerKlaar
        }
    }

    /// **A step transition never opens its mouth while the last line is still
    /// going.** Never bare `say` — `ROOMS.md` §4, and the reason is that playing
    /// fast should not cost her the words.
    ///
    /// Only one line can ever be waiting and a newer one replaces it, so five
    /// quick drops earn the most recent thing that is still true rather than a
    /// monologue about things that have already happened.
    ///
    /// **`sayInstead` rather than `sayWhenQuiet`, because a step transition is
    /// not an extra remark — it is the room moving on, and everything queued
    /// behind the sentence in the air is about where she just was.** The
    /// greeting is three lines long and she can have the bed sown before it
    /// finishes; joining that queue means being told to sow, then told the
    /// basket is full. The sentence sounding now still finishes: this drops the
    /// queue, never the voice.
    private var lastAnnounced: GardenStep?
    private func announceStep() {
        guard state.step != lastAnnounced else { return }
        lastAnnounced = state.step
        switch state.step {
        case .zaaien: voice.sayInstead(Line.Tuin.zaaien)
        case .gieten: voice.sayInstead(Line.Tuin.gieten)
        case .plukken: voice.sayInstead(Line.Tuin.rijp)
        case .klaar:
            voice.sayInstead([Line.Tuin.mandjeVol, Line.Tuin.kamerKlaar], gap: 0.35)
        }
    }

    // MARK: - Room

    /// What she hears when the room appears.
    ///
    /// At the top of a round: hello, then what we are doing today, then the
    /// first step. Coming back to a bed she has already sown skips all that and
    /// says where she was — a half-grown bed is a better thing to be reminded of
    /// than an instruction she is past.
    func greet() {
        let atTheTop = state.step == .zaaien && state.plantedCount == 0
            && state.basket.isEmpty
        if gardenComplete {
            voice.say([Line.Tuin.hallo, Line.Tuin.kamerKlaar], gap: 0.35)
            return
        }
        guard atTheTop else {
            voice.say(nudgeLine(for: state.step))
            lastAnnounced = state.step
            return
        }
        voice.say([Line.Tuin.hallo, Line.Tuin.opdracht, Line.Tuin.zaaien], gap: 0.35)
        lastAnnounced = state.step
    }

    func save() {
        GardenStore.save(state)
    }

    /// **The whole garden back to the beginning — bed, basket and all.**
    ///
    /// One meaning, which is the rule `KitchenRoom.restartRound` argues at
    /// length: a button that keeps some things and clears others has to be
    /// explained, and a button that has to be explained is one a 4-year-old
    /// cannot use.
    func restartRound() {
        sound.play(.whoosh, volume: 0.6)
        Sparkles.burst(at: GardenLayout.plotSpot(GardenLayout.plotCount / 2) + [0, 0.04, 0],
                       in: root, ticker: ticker, colour: Palette.mintLight, count: 10)
        state = GardenState.fresh()
        GardenStore.save(state)
        build(flat: flat)
        voice.say(Line.Tuin.opnieuw)
        lastAnnounced = nil
        ticker.after(2.0) { [weak self] in
            guard let self, self.state.step == .zaaien else { return }
            self.voice.say(Line.Tuin.zaaien, priority: .low)
        }
    }

    func resetRound() {
        state = GardenStore.reset()
        lastAnnounced = nil
        build(flat: flat)
    }

    func refreshContactShadows(settings: LightingSettings) {
        self.settings = settings
        carrier.update(settings: settings)
        let props: [Entity?] = [can?.root, basket?.root] + strays.map { $0 as Entity? }
        for prop in props.compactMap({ $0 }) where prop.isEnabled {
            let radius: Float = prop === can?.root ? 0.026
                : (prop === basket?.root ? 0.030 : 0.008)
            ContactShadows.attach(to: prop, radius: radius, settings: settings)
            ContactShadows.update(for: prop,
                                  surfaceY: GardenLayout.surfaces.y(at: prop.position),
                                  settings: settings)
        }
    }

    /// Everything stops, then the bed is written down. `GameScene` calls this
    /// before it swaps the room out — a ticker job left running would go on
    /// watering a garden nobody is in. It clears the touch callbacks the garden
    /// sets beyond its targets: `onMoved` is the butterfly's, and a stale one
    /// would follow her finger around the kitchen.
    func leave() {
        cancelEverything()
        save()
        touch.onEmptyTap = nil
        touch.onAnyTouch = nil
        touch.onMoved = nil
    }

    var debugTitle: String { RoomID.tuin.title }

    var debugRows: [String] {
        let bed = state.plots.map { plot in
            guard let seed = plot.seed else { return "·" }
            return "\(seed.rawValue.prefix(3))\(plot.growth)"
        }.joined(separator: " ")
        return ["Step: \(state.step.rawValue)",
                "Bed: \(bed)",
                "Mandje: \(state.basket.map(\.rawValue).joined(separator: ", "))"]
    }

    var debugActions: [(String, @MainActor () -> Void)] {
        [("New round", { [weak self] in self?.resetRound() })]
    }

    /// **Every job this room holds, in one place.**
    ///
    /// The failure mode it exists to stop: a `Ticker` job a torn-down room still
    /// holds keeps animating a detached entity forever, and nothing on screen
    /// says so. `build` calls it too, so it has to be complete for a rebuild as
    /// well as for leaving.
    private func cancelEverything() {
        for job in flierJobs { ticker.cancel(job) }
        flierJobs.removeAll()
        ticker.cancel(wateringJob)
        wateringJob = nil
        ticker.cancel(moleJob)
        moleJob = nil
        ticker.cancel(idleJob)
        idleJob = nil
        ticker.cancel(doorSwing)
        doorSwing = nil
        doorRest = 0
        Halo.remove(doorHalo, ticker: ticker)
        doorHalo = nil
        clearHalo()
        stopHint()
        carrier.end()
        doorMarker = nil
        doorTouchSpot = nil
        doorway = nil
        can = nil
        basket = nil
        molehill = nil
        butterfly = nil
        bee = nil
        carriedSeed = nil
        wateredThisPass.removeAll()
        wateredThisDrag = false
        canTravel = 0
        canLastPoint = nil
        lastTouchPoint = nil
        missCount = 0
        missStep = nil
    }
}
