import RealityKit

/// **The rooms, and what a room is.**
///
/// `GAMEPLAY.md` §6 gives every room the same shape — one required action, four
/// to six toys, and a door that always works — and `ROOMS.md` §0 gives it the
/// same box and the same fixed chair. This is that shape as a type, so the app
/// can hold *a* room rather than *the kitchen*.
///
/// It exists for two reasons and only one of them is the garden. The other is
/// that until now the only way to reach a room was to play the game up to it,
/// which is fine with one room and useless with six: the developer panel's room
/// picker (`RoomDebugStrip`) drives `GameScene.go(to:)` directly.
enum RoomID: String, CaseIterable, Identifiable {
    case keuken
    case tuin

    var id: String { rawValue }

    /// What the picker shows. Dutch, like the step names, because the room *is*
    /// its Dutch name everywhere else in the project — the save file, the voice
    /// script, `GAMEPLAY.md`'s headings.
    var title: String {
        switch self {
        case .keuken: return "Keuken"
        case .tuin: return "Tuin"
        }
    }
}

/// One room, seen from outside.
///
/// Deliberately small. A room owns its entities, its game state and its save
/// file, and nothing out here knows what any of those are — `ContentView` needs
/// to put it on screen, greet her, save it when the iPad is taken away, restart
/// it when she presses the button, and take it down again.
@MainActor
protocol GameRoom: AnyObject {

    /// The room's entity tree, added to the scene root.
    var root: Entity { get }

    /// Rebuild everything from the saved state. Called on entry, and again
    /// whenever the debug panel flips flat shading — which is only possible
    /// because a room is a pure function of its own state (`ROOMS.md` §1).
    func build(flat: Bool)

    /// What she hears when the room appears.
    func greet()

    func save()

    /// The `FacetButton` bottom-left. **One meaning only** (`ROOMS.md` §8): all
    /// the way back to the beginning, and Nina says so.
    func restartRound()

    /// The debug panel's blunter version of the same thing.
    func resetRound()

    func refreshContactShadows(settings: LightingSettings)

    /// **Give everything back.**
    ///
    /// The failure mode this exists to prevent: a `Ticker` job a torn-down room
    /// still holds keeps animating a detached entity forever, and there is
    /// nothing on screen to say so. Every job id, every `Halo.Handle` and every
    /// registered touch target has to go here — the kitchen's
    /// `cancelEverything()` is the worked example of the list.
    func teardown()

    /// What the developer panel prints for this room. Two or three short lines:
    /// the step, and whatever the step is not enough to know.
    var debugLines: [String] { get }
}
