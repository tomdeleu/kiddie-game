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

        entries = survivors + pending.filter { !cancelled.contains($0.id) }
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
    @discardableResult
    func squash(_ entity: Entity, amount: Float = 0.22, duration: Float = 0.45) -> Int {
        let base = entity.scale
        return tween(duration, ease: { $0 }, step: { [weak entity] t in
            guard let entity else { return }
            // Damped wobble: down hard, up, settle.
            let wobble = sin(t * .pi * 2.4) * (1 - t) * amount
            entity.scale = SIMD3<Float>(base.x * (1 - wobble * 0.6),
                                        base.y * (1 + wobble),
                                        base.z * (1 - wobble * 0.6))
        }, done: { [weak entity] in entity?.scale = base })
    }

    /// A quick side-to-side waggle. Every toy in the room uses it.
    @discardableResult
    func wiggle(_ entity: Entity, angle: Float = 0.16, duration: Float = 0.5) -> Int {
        let base = entity.orientation
        return tween(duration, ease: { $0 }, step: { [weak entity] t in
            guard let entity else { return }
            let a = sin(t * .pi * 3) * (1 - t) * angle
            entity.orientation = base * simd_quatf(angle: a, axis: SIMD3<Float>(0, 0, 1))
        }, done: { [weak entity] in entity?.orientation = base })
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
