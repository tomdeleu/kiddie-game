import RealityKit
import simd

/// **Carrying things.** The hardest part of the kitchen, and it is solved —
/// `ROOMS.md` §6 says inherit it rather than rediscover it, so this is where it
/// lives now instead of inside `KitchenRoom`.
///
/// A carried prop **rides just above whatever is underneath it** — table,
/// counter, floor — easing there over about a third of a second rather than
/// snapping. Pick a berry off the top shelf and it swoops down as she brings it
/// to the bowl; carry it back over the table and it lifts again.
///
/// The whole model is two questions, and `Surfaces` answers both: what is under
/// a point, and what her finger is pointing at. The distinction is load-bearing
/// and cost two failed attempts — the argument is written out over
/// `Surfaces.pointedAt`.
///
/// A room supplies its own `Surfaces` and its own hooks; nothing in here knows
/// what a kitchen or a garden is.
@MainActor
final class CarryController {

    /// Something with an inside, and how high its rim stands above its own
    /// origin.
    typealias Container = (entity: Entity, rimHeight: Float, radius: Float)

    private let ticker: Ticker
    private let sound: SoundKit
    let surfaces: Surfaces
    private var settings: LightingSettings

    /// **Everything with an inside**, read fresh every frame of a drag.
    ///
    /// A closure rather than a stored array, because unlike the table and the
    /// counter these **move**: she can pick the bowl up and put it anywhere, so
    /// their footprints are a fact about the current state of the room and not
    /// about its plan — and a stored list is one a rebuild could leave dangling.
    var containers: () -> [Container] = { [] }

    /// **A surface only one prop, in one step, can reach.**
    ///
    /// The kitchen's cake plank is the worked example: it hangs on the wall
    /// directly above the back of the counter, so as a real surface it would
    /// shadow the counter and fling the sink shelf-high. It is checked here
    /// instead, for the one prop that can reach it. Ray-based — this is the
    /// drag's question.
    var pointedExtra: ((_ anchor: SIMD3<Float>, _ carried: Entity) -> Float?)?

    /// The same exception, asked position-based, for a prop nobody is holding —
    /// which is what the halo needs. See `surfaceUnder`.
    var restingExtra: ((_ point: SIMD3<Float>, _ prop: Entity) -> Float?)?

    /// Fired as something is picked up, before the drag begins. The rooms use it
    /// to stop the idle shimmer.
    var onPickUp: ((Entity) -> Void)?

    /// Fired when a settle counted as a miss — she dragged the prop the current
    /// step is about and it did not land. `ROOMS.md` §8.
    var onMiss: (() -> Void)?

    /// What she is holding, or nil. The honest test for "did this drag begin as
    /// a carry": the kitchen's stir never sets it, which is what stops a stir
    /// that finishes mid-drag from running the rest of that gesture down the
    /// pouring path and failing a pour she never attempted.
    private(set) var carried: Entity?

    private var offset = SIMD3<Float>.zero
    private var job: Int?
    /// Where the prop is now, and where it wants to be. The gap between them,
    /// closed a little every frame, is the whole height animation.
    private var currentY: Float = 0
    private var goalY: Float = 0
    /// What it is currently over, for the contact shadow.
    private var surfaceY: Float = 0
    /// The last place her finger reported, on the drag's fixed plane. Kept
    /// because the ray through it is what the prop's position is read off, and
    /// that has to be recomputed on frames where no touch arrived.
    private var anchor = SIMD3<Float>.zero
    /// Exactly where the prop was when she took hold of it, so a touch that went
    /// nowhere can put it back exactly — see `settle`.
    private var origin = SIMD3<Float>.zero

    init(ticker: Ticker, sound: SoundKit, surfaces: Surfaces,
         settings: LightingSettings) {
        self.ticker = ticker
        self.sound = sound
        self.surfaces = surfaces
        self.settings = settings
        self.surfaceY = surfaces.floorY
    }

    func update(settings: LightingSettings) { self.settings = settings }

    // MARK: - Picking up

    /// Pick something up.
    func pickUp(_ entity: Entity, at world: SIMD3<Float>) {
        end()
        carried = entity
        anchor = world
        // **Measured against the ray at the prop's own height, not against the
        // touch point.** For most props those are the same thing, because the
        // drag plane starts at the prop's height — but the kitchen's bowl
        // carries a 20 mm `planeOffset` so that stirring happens on the plane of
        // its rim, and reading the offset off a point 20 mm higher would put a
        // 23 mm step into the very first frame of the drag.
        offset = entity.position
            - Surfaces.pointOnRay(through: world, atHeight: entity.position.y)
        offset.y = 0
        origin = entity.position
        currentY = entity.position.y
        surfaceY = surfaces.y(at: entity.position)
        goalY = currentY
        onPickUp?(entity)
        ticker.squash(entity, amount: 0.14, duration: 0.25)
        sound.play(.stirTick, volume: 0.4)

        // **One job for the whole drag, rather than easing inside the touch
        // callback.** Touch events stop arriving the moment her finger stops
        // moving, and a prop halfway down to the floor has to keep going *and*
        // stay under the finger that is holding still.
        //
        // **The drag plane is fixed for the whole drag**, and that is the fix
        // for a bug worth remembering. It used to be written down here every
        // frame so the prop stayed pinned under her fingertip as it changed
        // height. That is a feedback loop — the height depends on the XZ and the
        // XZ depends on the plane — and the kitchen's cake going onto the plank
        // is where it bit: reaching the plank zone lifted it 67 mm, which slid
        // the mapped point out of the zone, so it dropped to the counter, which
        // slid it back in, and it juddered between the two.
        //
        // What breaks the loop for good is `Surfaces.pointedAt` deciding the
        // surface from the *ray* rather than from the prop, so height can no
        // longer feed back into the choice. With that settled the prop's XZ can
        // safely be read off the same ray at whatever height it has reached,
        // which is what `place` does.
        job = ticker.add { [weak self] dt in
            guard let self, let held = self.carried else { return false }
            // Exponential ease — about 90% of the remaining gap in a third of a
            // second, whatever the frame rate, and no overshoot.
            self.currentY += (self.goalY - self.currentY) * (1 - exp(-dt * 7.5))
            self.place()
            ContactShadows.update(for: held, surfaceY: self.surfaceY,
                                  settings: self.settings)
            return true
        }
    }

    /// **The height rule.** A carried prop rides just above whatever is
    /// underneath it, and eases there rather than jumping.
    ///
    /// Everything used to be carried at table height regardless of where it was,
    /// which is why the room read flat: drag the rolling pin off the table and
    /// it stayed at table height, hanging in mid-air over the floor with nothing
    /// to say it was up there.
    func move(to world: SIMD3<Float>) {
        guard let carried else { return }
        anchor = world
        surfaceY = pointedSurface(from: world, for: carried)
        goalY = surfaceY + surfaces.lift
        place()
    }

    /// **Put the carried prop back under her fingertip.**
    ///
    /// One line of arithmetic, and it is the whole of the drag: the prop goes on
    /// the ray she is pointing along, read at whatever height it has eased to.
    /// Height moves, the finger does not, and the prop stays where the finger
    /// is — which is what a drag has to feel like.
    private func place() {
        guard let carried else { return }
        var next = surfaces.clamp(
            Surfaces.pointOnRay(through: anchor, atHeight: currentY) + offset)
        // Y is owned by the carry job; the touch only ever moves it about.
        next.y = currentY
        carried.position = next
    }

    // MARK: - What it is over

    /// **What she is pointing at**, for a prop being carried.
    private func pointedSurface(from anchor: SIMD3<Float>, for entity: Entity) -> Float {
        if let extra = pointedExtra?(anchor, entity) { return extra }
        if let rim = containerRim(from: anchor, carrying: entity) { return rim }
        return surfaces.pointedAt(from: anchor)
    }

    /// **The rim of a container she is holding something over.**
    ///
    /// `Surfaces` knows about the room's flat surfaces, and a bowl standing on
    /// the table is not one of them — so a berry carried over the kitchen's
    /// mixing bowl rode at table height, which is 26 mm *below* the bowl's rim.
    /// It went straight through the side of it.
    ///
    /// Tallest wins, and the carried prop never rides on itself — otherwise
    /// picking up the bowl would launch it up its own rim, every frame.
    ///
    /// This is safe for every drop in the game because **every snap test is
    /// XZ-only**: riding higher cannot make a drop harder to land. It only
    /// changes what she sees on the way there.
    private func containerRim(from anchor: SIMD3<Float>, carrying entity: Entity) -> Float? {
        var best: Float?
        for container in containers() where container.entity !== entity {
            guard container.entity.isEnabled, container.entity.parent != nil else { continue }
            let top = container.entity.position.y + container.rimHeight
            let over = Surfaces.pointOnRay(through: anchor, atHeight: top)
            guard Surfaces.distanceXZ(over, container.entity.position) <= container.radius
            else { continue }
            if best == nil || top > best! { best = top }
        }
        return best
    }

    /// **What a prop that is standing somewhere is standing on.**
    ///
    /// Position-based, where `pointedSurface` is ray-based — the halo asks this
    /// one, because it follows a prop rather than a finger and has to be right
    /// for a prop nobody is holding.
    func surfaceUnder(_ point: SIMD3<Float>, for entity: Entity) -> Float {
        if let extra = restingExtra?(point, entity) { return extra }
        if let shelf = surfaces.shelfY(at: point) { return shelf }
        return surfaces.y(at: point)
    }

    // MARK: - Letting go

    func end() {
        ticker.cancel(job)
        job = nil
        carried = nil
    }

    /// **A drop that did not do anything in particular. It stays where she put
    /// it.**
    ///
    /// This replaced `floatHome`, which sent a missed drop back where it came
    /// from and had Nina apologise for it. That was wrong twice over. It took
    /// the room away from her — the one thing she can do with a room full of
    /// objects is move them around, and every attempt was being undone half a
    /// second later. And it made a miss into an *event*, with a sound and a line
    /// about it, when most misses are not attempts at anything: she picked up
    /// the rolling pin and put it on the floor, which is a thing a 4-year-old
    /// does to a rolling pin.
    ///
    /// So a prop settles onto whatever is beneath it and simply stays there.
    /// `missed` is the narrow case still worth answering: she was working on the
    /// current step and it did not take.
    func settle(_ entity: Entity, missed: Bool) {
        let from = origin
        end()

        // **A touch that went nowhere puts it back exactly.** This is what stops
        // a tap on the top shelf knocking the berry off it: every tap is also a
        // zero-length drag (`TouchRouter.ended`), and without this the berry
        // would obediently fall to the floor because that is what is under a
        // shelf. A grab she thought better of gets the same answer.
        guard Surfaces.distanceXZ(entity.position, from) > 0.010 else {
            ticker.move(entity, to: from, duration: 0.16, arc: 0, ease: Ease.out) {
                [weak self] in
                guard let self else { return }
                ContactShadows.update(for: entity, surfaceY: self.surfaces.y(at: from),
                                      settings: self.settings)
            }
            return
        }

        // **Out of sight is the one place a drop is not allowed to stick.** The
        // camera is fixed, so the floor behind the furniture is a patch she
        // could put something into and never get back out of — and she has no
        // way to look round it. It floats back to where she picked it up, which
        // is the one case the old float-home behaviour was right about.
        // Everywhere else on the floor is hers.
        guard !surfaces.isOutOfSight(entity.position) else {
            sound.play(.whoosh, volume: 0.35)
            ticker.move(entity, to: from, duration: 0.4, arc: 0.014, ease: Ease.out) {
                [weak self] in
                guard let self else { return }
                ContactShadows.update(for: entity, surfaceY: self.surfaces.y(at: from),
                                      settings: self.settings)
            }
            if missed { onMiss?() }
            return
        }

        let resting = SIMD3<Float>(entity.position.x,
                                   surfaces.y(at: entity.position),
                                   entity.position.z)
        ticker.move(entity, to: resting, duration: 0.20, arc: 0, ease: Ease.out) {
            [weak self] in
            guard let self else { return }
            self.sound.play(.thud, volume: 0.42)
            ContactShadows.update(for: entity, surfaceY: resting.y, settings: self.settings)
        }
        if missed { onMiss?() }
    }
}
