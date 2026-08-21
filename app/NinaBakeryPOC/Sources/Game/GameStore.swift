import Foundation

/// **The wall of twelve frames, which is the only thing in this game that is
/// progress.** `GAMEPLAY.md` §2 and §8.
///
/// Every other save in the project is a room's own — `keuken.json`, `tuin.json`,
/// `versieren.json`, `feest.json` — and `RoomStore`'s own comment gives the
/// reason: *"a room's state is only ever read by that room… adding a room cannot
/// corrupt another room's save."* That argument is still right, and this file is
/// the exception it always implied. The wall is not the bakery's state. It is
/// **the game's**, written by one room and read by that same room a whole round
/// later, and there is nowhere else it could live.
///
/// So: one more file, `muur.json`, and it holds exactly three things — which
/// frames are filled, the round that is in progress, and whether the finale has
/// played.
///
/// **Frames are a dictionary keyed by `Friend.rawValue`, not a twelve-slot
/// array**, and that is the load-bearing decision in here. An array couples the
/// wall to an index — insert a friend, reorder the enum, and every stored cake
/// moves to a different frame, silently, in a file that cannot be re-derived
/// because the cakes it names no longer exist anywhere else. A dictionary keyed
/// by the friend's own name cannot do that. Absent means *still a grey ghost*,
/// which is also the state the game starts in, so an empty file and a fresh game
/// are the same thing rather than two things that have to agree.
///
/// **The gold frame is derived and never stored.** `GAMEPLAY.md` §2 says it stays
/// grey until the other eleven are in colour, which is a fact about the other
/// eleven — `filledCount == Friend.allCases.count` is the whole of it. Storing it
/// would be storing a second copy of something already written down, and the two
/// copies would eventually disagree.
///
/// `ROOMS.md` §2's rules hold here as they do for a room: every struct carries a
/// `version`, every field added after this build is `Optional`, and a decode
/// failure falls back to fresh — which for this file means **losing her wall**,
/// so it is the path to keep exceptional. `GAMEPLAY.md` §8: *"getting this wrong
/// costs a child her wall."*

// MARK: - What a filled frame holds

/// One photograph on the wall.
///
/// **It stores the cake, not a picture of it.** `GAMEPLAY.md` §6.1 is explicit:
/// *"a render of a stored `CakeSpec` + stickers, not a screenshot — a screenshot
/// ties the wall to the resolution it was taken at and to whatever the camera was
/// doing that day."* `Sticker` already anchors itself in cake-local polar
/// coordinates for exactly this, so `FrameWall` can rebuild the cake she decorated
/// at any size, on any device, years later.
struct FrameFill: Codable {
    var version = 1
    /// The finished cake, stickers and piping included.
    var cake: CakeSpec
    /// Whether the friend's wish was met, as the party judged it. Optional
    /// because the day a frame is filled by something that never went to a party
    /// — the finale, a debug action — there is no verdict to record.
    var wishMatched: Bool?
    var when: Date
}

// MARK: - What the party hands back

/// **What just happened at the party**, carried home to the bakery inside
/// `RoomExit.bakkerij`.
///
/// This is the one payload in the game that crosses a doorway carrying more than
/// a cake, and it exists because the wall needs three things the party is the
/// last holder of: which friend it was for, the cake as it ended up after
/// decorating, and whether the wish was met. Before the hub, `FeestRoom.tapCake`
/// evaluated the wish, said so out loud, and let all three die with the room —
/// `feest.json` keeps them only until the next party overwrites it.
struct FeestResult: Codable {
    var version = 1
    var friend: Friend
    var cake: CakeSpec
    var matched: Bool

    init(friend: Friend, cake: CakeSpec, matched: Bool) {
        self.friend = friend
        self.cake = cake
        self.matched = matched
    }
}

// MARK: - The round that is in progress

/// **Where she is in today's round**, so closing the app in the garden does not
/// lose who she is baking for.
///
/// `RoomExit`'s own comment already flagged this: handing a basket between rooms
/// as a live enum rather than a file *"is the right call only because there is no
/// bakery hub yet to be interrupted in… worth reopening when the hub lands."*
/// This is that reopening, at the level that matters — the rooms still keep their
/// own contents in their own files, and what this adds is the one fact none of
/// them could hold, which is that all of it is for Pip.
struct RoundInProgress: Codable {
    var version = 1
    var friend: Friend
    /// `RoomID.rawValue` of the room she reached. Optional so a round can exist
    /// for the beat between being chosen and arriving anywhere.
    var room: String?
    /// Set when the party ends, cleared when the photo is hung. Its presence is
    /// what makes a relaunch resume into the return leg rather than the outbound
    /// one.
    var result: FeestResult?

    init(friend: Friend, room: String? = nil, result: FeestResult? = nil) {
        self.friend = friend
        self.room = room
        self.result = result
    }
}

// MARK: - The file

struct GameState: Codable {
    var version = 1
    /// Keyed by `Friend.rawValue`. **Absent means a grey ghost.**
    var frames: [String: FrameFill]?
    var round: RoundInProgress?
    var finalePlayed: Bool?

    static func fresh() -> GameState {
        GameState(frames: [:], round: nil, finalePlayed: false)
    }

    // MARK: Reading the wall

    func fill(for friend: Friend) -> FrameFill? { frames?[friend.rawValue] }

    func isFilled(_ friend: Friend) -> Bool { frames?[friend.rawValue] != nil }

    var filledCount: Int { frames?.count ?? 0 }

    /// Everyone still waiting for a cake — the ghosts `kiezen` chooses between.
    var waiting: [Friend] { Friend.allCases.filter { !isFilled($0) } }

    /// **The twelfth frame, which is Nina's own.** Owner's call, 2026-08-16.
    /// Derived rather than stored — see the note at the top of this file.
    var goldIsEarned: Bool { filledCount >= Friend.allCases.count }

    // MARK: Writing it

    mutating func fill(_ friend: Friend, with cake: CakeSpec, matched: Bool?, when: Date) {
        var all = frames ?? [:]
        all[friend.rawValue] = FrameFill(version: 1, cake: cake,
                                         wishMatched: matched, when: when)
        frames = all
    }
}

/// A thin name over `RoomStore`, matching `RoundStore`'s shape so the call sites
/// read the same as every other save in the project.
enum GameStore {

    private static let fileName = "muur.json"

    static func load() -> GameState {
        RoomStore.load(fileName) { .fresh() }
    }

    static func save(_ state: GameState) {
        RoomStore.save(state, to: fileName)
    }

    /// For the debug strip: the wall back to twelve ghosts. **Nothing in the game
    /// reaches this** — `ROOMS.md` §8's restart button is about the round she is
    /// in, and a button that could quietly empty a fortnight of baking is not one
    /// a 4-year-old should be able to find.
    static func reset() -> GameState {
        let state = GameState.fresh()
        save(state)
        return state
    }
}
