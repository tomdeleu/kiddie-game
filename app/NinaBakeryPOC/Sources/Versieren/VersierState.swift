import Foundation

/// **The decorating room has one step, and that is not an oversight.**
///
/// `ROOMS.md` §1 wants a step enum; `GAMEPLAY.md` §6.4 says this room has no
/// required action and must never ask her for anything. A one-case enum is the
/// honest resolution: it keeps `applyStep`, the save shape and the debug readout
/// identical to the kitchen's, and it says truthfully that there is only ever
/// one thing going on. Inventing a second step to make the machinery look busy
/// would be inventing the required action the design forbids.
enum VersierStep: String, Codable {
    case versieren
}

/// What the room is in the middle of. Written after every change she makes,
/// because `GAMEPLAY.md` §7 says interruptions are free and an iPad gets taken
/// away mid-sticker.
struct VersierState: Codable {
    var version = 1

    /// **The cake, and everything on it.** It lives here rather than in the
    /// kitchen's save for one specific reason: a visit deals its own cake, and
    /// writing that back into `RoundState` would mean one idle afternoon of
    /// decorating overwrote the cake she actually baked in a round.
    var cake: CakeSpec = CakeSpec()

    /// The turntable's angle, radians. Saved so coming back finds the cake
    /// facing the way she left it — every sticker rides it for free, since
    /// anchors are stored in the cake's own frame.
    var turn: Float = 0

    var step: VersierStep = .versieren

    static func fresh(cake: CakeSpec) -> VersierState {
        VersierState(cake: cake)
    }
}

enum VersierStore {

    private static let fileName = "versieren.json"

    static func load(fallback cake: @autoclosure () -> CakeSpec) -> VersierState {
        RoomStore.load(fileName) { .fresh(cake: cake()) }
    }

    static func save(_ state: VersierState) {
        RoomStore.save(state, to: fileName)
    }
}
