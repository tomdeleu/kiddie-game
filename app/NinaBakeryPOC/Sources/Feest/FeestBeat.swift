import Foundation

/// **The beat, taken from her hands.**
///
/// `GAMEPLAY.md` §6.5: *"the animation clock follows the beat she is actually
/// making, so it is her rhythm they are dancing to, not a recording."* That
/// sentence is the whole party, and this is all of it: a tap interval, a running
/// average, and a phase that everything else in the room reads.
///
/// Nothing in the room owns a period of its own. The guests, the mirror ball,
/// the floor tiles, the lamps and the booth's panel all ask this object what
/// time it is, which is why they are visibly *together* rather than six things
/// that happen to be moving.
///
/// ## The three numbers, and why each one is there
///
/// - **`floor` and `ceiling`** are §6.5's own words — *"floored and capped so
///   that two taps a second apart do not put the guests into slow motion and a
///   burst does not shake them apart."* A 4-year-old hammering a pad produces
///   intervals of 60 ms; a 4-year-old who has wandered off produces one of nine
///   seconds. Neither is a tempo, and both arrive routinely.
/// - **`resting`** is what the room dances at before she has touched anything
///   and after she has stopped. A party that stands still until she taps reads
///   as broken, and `GAMEPLAY.md` §7's *nothing is driven by a clock* is about
///   **progress**, not about whether things move: nothing here advances the
///   round, so a default groove costs her nothing.
/// - **`memory`** — four taps. Fewer and one wild interval is the tempo; more
///   and speeding up takes so long she cannot tell she did it, which would make
///   the one thing the room is about invisible.
///
/// ## Why it is not a timestamp
///
/// The obvious build reads `CFAbsoluteTimeGetCurrent()` on each tap and
/// subtracts. This accumulates `dt` from `Ticker` instead, for the reason every
/// animation in the game does (`ROOMS.md` §7): the ticker's `dt` is **clamped**,
/// so coming back from the background cannot hand the party a 40-second interval
/// to average in. A wall clock would.
@MainActor
final class FeestBeat {

    /// Seconds per beat. Everything that moves reads this.
    private(set) var period: Float = resting

    /// 0…1 through the current beat. Read by anything that wants to be *on* the
    /// beat rather than merely at its speed — the floor tiles step on the wrap,
    /// the guests hop on the first half.
    private(set) var phase: Float = 0

    /// How many beats have gone by since the room was built. The floor and the
    /// lamps step their colour off it, so the pattern travels instead of
    /// flickering in place.
    private(set) var count = 0

    /// True on the frame a beat lands. `tick` sets it; the room reads it.
    private(set) var justLanded = false

    /// Whether she has ever tapped a pad. The room's first-beat line waits on it,
    /// and the resting groove is only "resting" once she has actually played.
    private(set) var hasPlayed = false

    static let resting: Float = 0.52
    private static let floor: Float = 0.26
    private static let ceiling: Float = 1.10
    private static let memory = 4
    /// Below this an interval is a double-tap rather than a beat — one press
    /// that bounced, or two fingers. Averaging it in halves the tempo on a
    /// misfire.
    private static let doubleTap: Float = 0.11
    /// Above this she stopped and started again rather than played slowly, so
    /// the gap is not an interval at all.
    private static let lostThread: Float = 2.2
    /// How long she has to be quiet before the room eases back to the resting
    /// groove. Long enough that thinking about which pad to hit next does not
    /// reset her tempo.
    private static let forgetAfter: Float = 6.0

    private var intervals: [Float] = []
    private var sinceLastTap: Float = 0

    // MARK: - Her hands

    /// One pad tapped. Returns the beat index it landed on, so the caller can
    /// colour what it does by where in the bar she is.
    @discardableResult
    func tap() -> Int {
        hasPlayed = true
        let gap = sinceLastTap
        sinceLastTap = 0

        if gap > Self.doubleTap && gap < Self.lostThread {
            intervals.append(gap)
            if intervals.count > Self.memory { intervals.removeFirst() }
            let mean = intervals.reduce(0, +) / Float(intervals.count)
            period = min(Self.ceiling, max(Self.floor, mean))
        }

        // **A tap is a beat, whatever the phase said.** Snapping the phase to
        // zero is what makes the room feel like it is following her rather than
        // running beside her: the tile she is standing on lights on the tap, not
        // up to half a beat later. It is also the only way a first tap can do
        // anything at all, since one tap carries no interval.
        phase = 0
        count += 1
        justLanded = true
        return count
    }

    // MARK: - The clock

    /// Called once a frame from the room's own `Ticker` job.
    func tick(_ dt: Float) {
        justLanded = false
        sinceLastTap += dt

        // She stopped. Ease back towards the groove rather than snapping, so a
        // pause reads as the room carrying on without her rather than as a
        // gear change.
        if sinceLastTap > Self.forgetAfter {
            intervals.removeAll()
            period += (Self.resting - period) * min(1, dt * 0.6)
        }

        phase += dt / max(0.05, period)
        while phase >= 1 {
            phase -= 1
            count += 1
            justLanded = true
        }
    }

    /// **A swing between 0 and 1 and back, once a beat.** The shape everything
    /// in the room bounces on, so nothing has to own a sine of its own.
    var swing: Float { sin(phase * .pi) }

    /// Sharper: up fast, down slow. What a hop wants, where `swing` is what a
    /// sway wants.
    var hop: Float {
        phase < 0.35 ? sin(phase / 0.35 * (.pi / 2))
                     : cos((phase - 0.35) / 0.65 * (.pi / 2))
    }

    /// Reset to the resting groove — the restart button, and a fresh party.
    func forget() {
        intervals.removeAll()
        period = Self.resting
        phase = 0
        count = 0
        sinceLastTap = 0
        hasPlayed = false
        justLanded = false
    }

    /// Beats per minute, for the debug strip only. Nothing in the game shows a
    /// number to anybody.
    var bpm: Int { Int((60 / max(0.05, period)).rounded()) }
}
