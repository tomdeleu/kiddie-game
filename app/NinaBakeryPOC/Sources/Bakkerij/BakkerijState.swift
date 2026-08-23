import Foundation

/// **The hub's working memory.** `GAMEPLAY.md` §6.1.
///
/// Outbound is a sitting-open and a pick, not a kitchen-shaped spine. The shop
/// door and the order hook are toys; the wall is how a round starts; hanging
/// the photograph is how it ends. She still passes through twice — out through
/// `kiezen` / `naarTuin`, home through `ophangen` — but the outbound leg is
/// no longer four fetches.
///
/// One enum rather than a phase-and-step pair. The room is never on an outbound
/// step and a return step at once — which leg she is on is decided before the
/// room is built, by whether the party handed anything back — so splitting it
/// would be two things to keep in agreement where one will do, and `applyStep`
/// stays a single switch.
enum BakkerijStep: String, Codable {
    /// Drag the shutter cord. Once per sitting: the blind goes up, daylight
    /// comes in, the wall of frames is revealed. Not a gate on every round.
    case opendoen
    /// Tap a grey ghost. **The first step in the game with no halo at all** —
    /// see `BakkerijRoom.applyStep`.
    case kiezen
    /// The friend is here, the back door is lit. She taps it when she is
    /// ready to go to the garden.
    case naarTuin

    /// The return leg (`GAMEPLAY.md` §6.6): drag the photograph into that
    /// friend's frame.
    case ophangen
    /// The curtain closes. The most complete moment in the game.
    case klaar

    var isReturnLeg: Bool { self == .ophangen || self == .klaar }
}

/// **Deliberately not `Codable`, and deliberately not a save file.**
///
/// Every other room owns a JSON file. This one does not, because everything
/// about the bakery that outlives the moment is the *wall*, and the wall is
/// `GameStore`'s. A `bakkerij.json` holding a chosen friend beside `muur.json`
/// holding the round in progress would be two homes for one fact, which is the
/// trap `ROOMS.md` §11 records as *"a number two rooms depend on belongs to
/// neither of them"* — here, two files inside one room.
///
/// So this struct is the room's working memory for as long as it is on screen,
/// and `save()` writes through to `GameStore`.
struct BakkerijState {
    var step: BakkerijStep
    /// Who today is for. Nil until `kiezen` is done — and on the return leg it
    /// is whoever the party sent home.
    var friend: Friend?
    /// Non-nil means she is on the return leg holding a photograph.
    var result: FeestResult?

    /// The wall, as of the last read. Held here so the twelve frames can be
    /// built without hitting the disk twelve times.
    var wall: GameState

    static func outbound(wall: GameState, shopOpen: Bool) -> BakkerijState {
        // **Free play skips `kiezen` entirely.** `GAMEPLAY.md` §6.1: once the
        // eleven are filled there is no ghost left to pick, so a friend turns up
        // at random and the back door lights.
        if wall.goldIsEarned {
            return BakkerijState(step: shopOpen ? .naarTuin : .opendoen,
                                 friend: Friend.dealt(), result: nil, wall: wall)
        }
        return BakkerijState(step: shopOpen ? .kiezen : .opendoen,
                             friend: nil, result: nil, wall: wall)
    }

    static func returning(wall: GameState, result: FeestResult) -> BakkerijState {
        BakkerijState(step: .ophangen, friend: result.friend, result: result, wall: wall)
    }
}
