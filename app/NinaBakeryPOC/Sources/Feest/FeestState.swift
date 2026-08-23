import Foundation

/// **The party's two steps.**
///
/// `GAMEPLAY.md` §6.5 asks the room for nothing until she decides it is over, so
/// there is exactly one thing to distinguish: whether she has decided. Versieren
/// makes the same argument for a *one*-case enum and it is right there — that
/// room genuinely never changes state. This one does, once, and it changes
/// everything about what the room is doing, so it is two.
///
/// `.opeten` is not a second required action. It is a **celebration that is
/// already running**, and the enum exists so that a party interrupted halfway
/// through the eating comes back knowing that the cake has been eaten rather than
/// putting an uneaten one back on the table.
enum FeestStep: String, Codable {
    /// The party. Six pads, a beat, and a cake standing on its table.
    case dansen
    /// She tapped the VIP rope. Everybody is eating the cake, and then thanking her.
    case opeten
}

/// What the room is in the middle of.
///
/// **Small on purpose.** Almost nothing here is worth remembering: the beat is
/// hers and belongs to the moment, the dancing is a function of the clock, and a
/// party resumed at exactly the tempo she left it at would be a party that
/// remembered something she did not. What *is* worth remembering is who is here
/// and what they are eating.
struct FeestState: Codable {
    var version = 1

    /// **The cake, as it left the decorating room.** Colours, effects, stickers
    /// and piped strokes — the party re-renders all of it from the spec, which is
    /// what `Sticker`'s cake-local polar anchors were for: *"the party and the
    /// wall can re-render the same cake later from the spec alone, at their own
    /// scale and their own angle."* This room is the first thing to actually
    /// collect on that promise.
    var cake: CakeSpec = CakeSpec()

    /// Who is at the door today. There is no bakery hub to say, so the room deals
    /// one — see `Friend.dealt`.
    var friend: Friend = .pip

    /// The other five. Stored rather than re-dealt on every build, so the
    /// flat/smooth debug toggle does not swap out her guests mid-party.
    var guests: [Friend] = []

    var step: FeestStep = .dansen

    /// **Whether the wish matched, worked out once.** `GAMEPLAY.md` §4: matching
    /// is a pure function of the finished cake, evaluated once, at the party, and
    /// nothing else in the game looks at it. This is that once — computed when
    /// the cake is tapped and then kept, so a friend who got her wish is still
    /// celebrating it after the app was closed mid-mouthful.
    ///
    /// `Optional` because *not yet asked* and *asked, and no* are different
    /// things, and because a field added later has to be optional anyway
    /// (`ROOMS.md` §2).
    var wishMatched: Bool?

    static func fresh(cake: CakeSpec, friend: Friend) -> FeestState {
        FeestState(cake: cake,
                   friend: friend,
                   guests: Friend.others(besides: friend,
                                         count: FeestLayout.guestCount - 1))
    }

    /// The friend of the day plus her guests, in the order they stand.
    /// **The friend of the day is first**, and `FeestLayout.guestSpot(0)` is the
    /// front-left place — nearest the camera on the open side, which is where the
    /// one guest who matters today belongs.
    var everyone: [Friend] {
        var all = [friend]
        all.append(contentsOf: guests.prefix(FeestLayout.guestCount - 1))
        // A save written before a layout change could be short. Top it up rather
        // than leaving a hole in the room.
        while all.count < FeestLayout.guestCount {
            guard let extra = Friend.allCases.first(where: { !all.contains($0) }) else { break }
            all.append(extra)
        }
        return all
    }
}

enum FeestStore {

    private static let fileName = "feest.json"

    static func load(fallback cake: @autoclosure () -> CakeSpec) -> FeestState {
        RoomStore.load(fileName) { .fresh(cake: cake(), friend: Friend.dealt()) }
    }

    static func save(_ state: FeestState) {
        RoomStore.save(state, to: fileName)
    }
}
