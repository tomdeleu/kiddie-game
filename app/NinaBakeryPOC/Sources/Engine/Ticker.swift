import Foundation
import RealityKit
import simd

/// The one clock in the game.
///
/// Every animation in the kitchen — a token arcing into the bowl, Otto
/// squashing, the batter changing colour, a sparkle dying — is a closure ticked
/// from here. That is deliberate over `entity.move(to:…)`:
///
/// - it is **interruptible**, and a 4-year-old interrupts everything;
/// - it composes with the game state, so nothing animates itself into a state
///   the round has already left;
/// - squash-and-stretch (`CONCEPT.md` §9.7) is a curve on a scale, which is
///   easier to write as three lines of maths than as a keyframe asset.
///
/// It runs on a run-loop timer rather than `SceneEvents.Update` so it is
/// independent of the render loop's plumbing, and so it keeps ticking while a
/// finger is down — `.common` mode is load-bearing for that.
@MainActor
final class Ticker {

    /// A frame of work. Receives seconds since the last frame; returns `false`
    /// when it is finished and wants removing.
    ///
    /// Explicitly `@MainActor`: every job touches entities and game state from
    /// a main-actor context, and spelling it in the type is what lets those
    /// closures be stored here without laundering their isolation away.
    typealias Job = @MainActor (Float) -> Bool

    private struct Entry {
        let id: Int
        let run: Job
    }

    private var entries: [Entry] = []
    private var pending: [Entry] = []
    private var cancelled: Set<Int> = []
    private var nextID = 1
    private var timer: Timer?
    private var lastTime = CFAbsoluteTimeGetCurrent()
    private var ticking = false

    // MARK: - Lifecycle

    func start() {
        guard timer == nil else { return }
        lastTime = CFAbsoluteTimeGetCurrent()
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // `.common` so animation does not freeze while she is dragging.
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = CFAbsoluteTimeGetCurrent()
        // Clamp: coming back from the background must not teleport everything.
        let dt = Float(min(0.1, max(0, now - lastTime)))
        lastTime = now
        guard dt > 0 else { return }

        ticking = true
        var survivors: [Entry] = []
        survivors.reserveCapacity(entries.count)
        for entry in entries {
            if cancelled.contains(entry.id) { continue }
            if entry.run(dt) { survivors.append(entry) }
        }
        ticking = false

        // **`survivors` is filtered too, and that is load-bearing.**
        //
        // A job cancelled from inside this very loop — which is the normal case,
        // because a finished animation's `done` closure is what cancels things —
        // is only skipped by the `cancelled` check above if it had not already
        // run this frame. Jobs run in creation order, so a long-lived job like a
        // halo is always earlier in the array than the short move that ends it:
        // the halo ran, returned true, and landed in `survivors` a few
        // microseconds before `clearHalo` asked for it to go away.
        //
        // Without this filter that cancellation is simply lost — `cancelled` is
        // emptied at the end of the frame and the job runs forever. It is how
        // the halo stayed lit on ingredients that were already in the bowl, and
        // it would have leaked one more job per ingredient, per round, for as
        // long as the app was open.
        entries = (survivors + pending).filter { !cancelled.contains($0.id) }
        pending.removeAll()
        cancelled.removeAll()
    }

    // MARK: - Scheduling

    @discardableResult
    func add(_ job: @escaping Job) -> Int {
        let entry = Entry(id: nextID, run: job)
        nextID += 1
        // Adding from inside a tick is normal — a finished animation starts the
        // next one — so new work waits for the end of the frame.
        if ticking { pending.append(entry) } else { entries.append(entry) }
        return entry.id
    }

    func cancel(_ id: Int?) {
        guard let id else { return }
        cancelled.insert(id)
        if !ticking {
            entries.removeAll { $0.id == id }
            pending.removeAll { $0.id == id }
        }
    }

    /// Run `body` once, `delay` seconds from now.
    @discardableResult
    func after(_ delay: Float, _ body: @escaping @MainActor () -> Void) -> Int {
        var elapsed: Float = 0
        return add { dt in
            elapsed += dt
            guard elapsed >= delay else { return true }
            body()
            return false
        }
    }

    /// Drive `step` with 0…1 over `duration`, then call `done`.
    @discardableResult
    func tween(_ duration: Float,
               ease: @escaping (Float) -> Float = Ease.inOut,
               step: @escaping @MainActor (Float) -> Void,
               done: (@MainActor () -> Void)? = nil) -> Int {
        var elapsed: Float = 0
        return add { dt in
            elapsed += dt
            let t = duration <= 0 ? 1 : min(1, elapsed / duration)
            step(ease(t))
            guard t >= 1 else { return true }
            done?()
            return false
        }
    }

    // MARK: - Rest poses

    /// Where a prop goes back to when a wobble finishes.
    ///
    /// It exists because every reaction in the game is "nudge this prop away
    /// from where it is and let it spring back", and *where it is* is the wrong
    /// reference point the moment she taps twice in a row. Captured once, held
    /// until the prop has settled, then forgotten — so a prop the game itself
    /// rescales later (a cake shrinking onto the plank) picks up its new rest
    /// pose the next time it is touched.
    private final class Pose {
        weak var entity: Entity?
        let scale: SIMD3<Float>
        let orientation: simd_quatf
        var squashJob: Int?
        var wiggleJob: Int?
        init(_ entity: Entity) {
            self.entity = entity
            scale = entity.scale
            orientation = entity.orientation
        }
    }

    private var poses: [ObjectIdentifier: Pose] = [:]

    private func pose(for entity: Entity) -> Pose {
        let key = ObjectIdentifier(entity)
        if let existing = poses[key], existing.entity === entity { return existing }
        // A stale key means the old entity was deallocated and a new one landed
        // on its address; either way the entry is worthless. Sweep the rest of
        // the table while we are here, since it is only ever a handful of props.
        poses = poses.filter { $0.value.entity != nil }
        let fresh = Pose(entity)
        poses[key] = fresh
        return fresh
    }

    /// A wobble ended. Drop the pose once nothing is still using it, so the
    /// next touch re-reads the prop rather than trusting a stale snapshot.
    private func finish(_ pose: Pose, scale: Bool) {
        if scale { pose.squashJob = nil } else { pose.wiggleJob = nil }
        guard pose.squashJob == nil, pose.wiggleJob == nil,
              let entity = pose.entity else { return }
        poses.removeValue(forKey: ObjectIdentifier(entity))
    }

    // MARK: - Ready-made moves

    /// Straight move with a little arc, so a token dropped in the bowl travels
    /// like a thrown thing rather than sliding through the air.
    @discardableResult
    func move(_ entity: Entity, to destination: SIMD3<Float>,
              duration: Float = 0.45, arc: Float = 0.03,
              ease: @escaping (Float) -> Float = Ease.inOut,
              done: (@MainActor () -> Void)? = nil) -> Int {
        let start = entity.position
        return tween(duration, ease: ease, step: { [weak entity] t in
            guard let entity else { return }
            var p = start + (destination - start) * t
            p.y += sin(t * .pi) * arc
            entity.position = p
        }, done: done)
    }

    /// The workhorse reaction: compress, overshoot, settle. One non-uniform
    /// scale on one entity — `CONCEPT.md` §9.7's whole animation budget.
    ///
    /// **Re-tapping does not compound.** It used to capture `entity.scale` at
    /// the moment of the call, so tapping a prop again while it was still
    /// wobbling took the *deformed* scale as the new rest pose and multiplied
    /// the next wobble on top of it. Ten taps on the cake and it was a
    /// pancake, which is what `Pose` exists to stop: the rest pose is captured
    /// once, reused by every wobble until the prop settles, and the running
    /// job is cancelled rather than stacked.
    @discardableResult
    func squash(_ entity: Entity, amount: Float = 0.22, duration: Float = 0.45) -> Int {
        let pose = pose(for: entity)
        cancel(pose.squashJob)
        let base = pose.scale
        let job = tween(duration, ease: { $0 }, step: { [weak entity] t in
            guard let entity else { return }
            // Damped wobble: down hard, up, settle.
            let wobble = sin(t * .pi * 2.4) * (1 - t) * amount
            entity.scale = SIMD3<Float>(base.x * (1 - wobble * 0.6),
                                        base.y * (1 + wobble),
                                        base.z * (1 - wobble * 0.6))
        }, done: { [weak self, weak entity] in
            entity?.scale = base
            self?.finish(pose, scale: true)
        })
        pose.squashJob = job
        return job
    }

    /// A quick side-to-side waggle. Every toy in the room uses it.
    ///
    /// Same anti-compounding rule as `squash`: repeated taps rock the prop from
    /// its rest orientation every time rather than winding it further round.
    @discardableResult
    func wiggle(_ entity: Entity, angle: Float = 0.16, duration: Float = 0.5) -> Int {
        let pose = pose(for: entity)
        cancel(pose.wiggleJob)
        let base = pose.orientation
        let job = tween(duration, ease: { $0 }, step: { [weak entity] t in
            guard let entity else { return }
            let a = sin(t * .pi * 3) * (1 - t) * angle
            entity.orientation = base * simd_quatf(angle: a, axis: SIMD3<Float>(0, 0, 1))
        }, done: { [weak self, weak entity] in
            entity?.orientation = base
            self?.finish(pose, scale: false)
        })
        pose.wiggleJob = job
        return job
    }

    /// A slow breathing pulse — the 25-second hint from `GAMEPLAY.md` §7.
    /// Hints shimmer; they never block, and they never disable anything.
    @discardableResult
    func shimmer(_ entity: Entity, amount: Float = 0.06) -> Int {
        let base = entity.scale
        var elapsed: Float = 0
        let id = add { [weak entity] dt in
            guard let entity else { return false }
            elapsed += dt
            let pulse = 1 + sin(elapsed * 4.2) * amount
            entity.scale = base * pulse
            return true
        }
        return id
    }

    /// Undo a shimmer, restoring the scale it was interrupting.
    func stopShimmer(_ id: Int?, on entity: Entity?, restoring scale: SIMD3<Float>) {
        cancel(id)
        entity?.scale = scale
    }
}

/// Easing curves, named for what they feel like rather than their exponents.
enum Ease {
    static let linear: (Float) -> Float = { $0 }
    static let out: (Float) -> Float = { 1 - pow(1 - $0, 3) }
    static let inCurve: (Float) -> Float = { $0 * $0 * $0 }
    static let inOut: (Float) -> Float = { t in
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
    /// Overshoots and comes back. For anything that should look pleased.
    static let back: (Float) -> Float = { t in
        let c1: Float = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }
}
