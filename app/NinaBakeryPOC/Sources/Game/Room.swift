import RealityKit

/// **What every room is, from outside.**
///
/// Derived from what actually crossed the boundary rather than from what a room
/// might one day want: before the decorating room existed, `ContentView` and
/// `GameScene` called exactly seven methods on `KitchenRoom` and read four
/// fields off its state. That is this protocol, and nothing else belongs in it.
///
/// Deliberately **not** in here: the step enum, the state struct, the save file,
/// the layout, the touch registration. None of those cross the boundary, and
/// `ROOMS.md` §1 wants each room to spell its step machine in its own language.
/// This codebase reuses by convention and shared free functions, not by
/// abstraction — one protocol is the whole of the abstraction the second room
/// needs, and a second one would already be too many.
@MainActor
protocol Room: AnyObject {

    /// The room's own subtree. `GameScene` parents this under `sceneRoot`.
    var root: Entity { get }

    /// Rebuild everything from the room's state. Must be callable at any time —
    /// the debug panel's flat/smooth toggle calls it mid-round, and a room
    /// entered from a save has to arrive at any step cold (`ROOMS.md` §1).
    func build(flat: Bool)

    /// Nina says hello. Called once the room is on screen, never before.
    func greet()

    func save()

    /// The bottom-left button. **It must have exactly one meaning** in each room
    /// (`ROOMS.md` §8), and what that meaning is, is the room's business.
    func restartRound()

    func refreshContactShadows(settings: LightingSettings)

    /// **Cancel every ticker job, then save.** Called before the room is swapped
    /// out. `KitchenRoom.cancelEverything` is the worked example of the
    /// discipline: every stored job id cancelled, halos removed, carry ended. A
    /// room that leaves a job running keeps animating a scene it is no longer in.
    func leave()

    /// What the debug strip shows, so `ContentView` never learns a concrete
    /// type. It used to read `kitchen.state.step` and three more fields
    /// directly; now the room writes its own readout and the strip renders
    /// whatever it is handed.
    var debugTitle: String { get }
    var debugRows: [String] { get }

    /// Extra buttons for the debug strip — the kitchen's "New round", and
    /// whatever the next room wants. Same reasoning as `debugRows`.
    var debugActions: [(String, @MainActor () -> Void)] { get }

    /// Set by `GameScene`. **The room never knows what comes next** — it says
    /// what just finished and hands back control, which is what keeps the door
    /// in `ROOMS.md` §9 to two functions rather than a routing table per room.
    var onExit: ((RoomExit) -> Void)? { get set }
}

/// Which rooms exist. Also the debug switcher's picker.
enum RoomID: String, CaseIterable, Identifiable {
    case tuin, keuken, versieren

    var id: String { rawValue }

    /// Shown in the debug strip only. Nothing here is ever on screen for Nina —
    /// `CONCEPT.md` §5 rules out text she has to read.
    var title: String {
        switch self {
        case .tuin: return "TUIN"
        case .keuken: return "KEUKEN"
        case .versieren: return "VERSIEREN"
        }
    }
}

/// **The one flag `GAMEPLAY.md` §3 asks for**, and it is one flag rather than
/// two implementations: the required action, the toys, the halo, the voice and
/// the save are identical in both. What differs is the completion rule and what
/// the door does.
enum RoomMode: Equatable {
    /// Entered from the previous room, mid-round, carrying the day's cake.
    case ronde
    /// Entered from the wall or the bakery floor, for the room's own sake.
    case bezoek
}

/// Why a room ended, said in terms of what just happened rather than of where to
/// go next.
enum RoomExit {
    /// The garden's basket is full; five ingredients want baking. **The order
    /// is the order she picked them in** and `CakeSpec` reads it, so this is a
    /// list rather than a set and must never be sorted.
    ///
    /// This replaced a `harvest.json` file written by the garden and read by the
    /// kitchen, and **one thing was genuinely traded away**: an exit is live and
    /// in memory, so a basket picked just before the app is closed no longer
    /// survives to the next launch. That is the right call only because there is
    /// no bakery hub yet to be interrupted *in* — the garden's own `tuin.json`
    /// still holds the bed and the basket, so nothing she grew is lost, only the
    /// fact that she was on her way to the kitchen with it. Worth reopening when
    /// the hub lands.
    case keuken([Ingredient])
    /// The kitchen's cake is baked and on the plank; it wants decorating.
    case versieren(CakeSpec)
    /// A visit is over, or a round has run out of rooms that exist yet.
    case bakkerij
}
