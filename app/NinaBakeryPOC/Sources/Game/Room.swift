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
    /// **In the order a round runs**, which is what the picker shows and the one
    /// thing about this enum that is a decision rather than a list.
    ///
    /// **The bakery is first**, because it is where a round starts and ends.
    case bakkerij, tuin, keuken, versieren, feest

    var id: String { rawValue }

    /// Shown in the debug strip only. Nothing here is ever on screen for Nina —
    /// `CONCEPT.md` §5 rules out text she has to read.
    var title: String {
        switch self {
        case .bakkerij: return "BAKKERIJ"
        case .tuin: return "TUIN"
        case .keuken: return "KEUKEN"
        case .versieren: return "VERSIEREN"
        case .feest: return "FEEST"
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
    /// kitchen. `GameStore.round` now records which friend the round is for and
    /// which room she reached, so a relaunch resumes the round rather than only
    /// the room. The basket itself is still live-in-memory and still lost by a
    /// kill in the doorway.
    case keuken([Ingredient])
    /// **The friend of the day has been chosen and the round is starting.**
    ///
    /// The one exit that carries something which is not a cake. §6.2's
    /// shimmering seed jar reads `Friend.hintedIngredient` off this.
    case tuin(Friend)
    /// The kitchen's cake is baked and on the plank; it wants decorating.
    case versieren(CakeSpec)
    /// **The cake is decorated and there is a party waiting for it.**
    ///
    /// The same shape as `.versieren` and carrying the same struct, which is the
    /// tell that `CakeSpec` was the right contract: the decorating room adds
    /// stickers and strokes to it and hands on the identical type, and the party
    /// re-renders every one of them from the polar anchors `Sticker` stores.
    /// Nothing was added to the spec to get a cake across this doorway.
    case feest(CakeSpec)
    /// **Back to the bakery.** A round carries the party result so the wall can
    /// hang a photograph. Nil means a visit ended, with nothing to hang.
    case bakkerij(FeestResult?)
}
