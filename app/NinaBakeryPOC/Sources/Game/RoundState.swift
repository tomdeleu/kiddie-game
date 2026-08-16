import Foundation

/// Where the round is. One value, saved after every step.
///
/// `GAMEPLAY.md` §7: interruptions are free. Closing the app mid-stir has to
/// come back mid-stir with the same batter — an iPad gets taken away
/// mid-sentence, and losing her cake to that would be the game's cruellest
/// moment. Everything the kitchen draws is rebuilt from this struct, which is
/// what makes that a save rather than a restore mechanism.
enum KitchenStep: String, Codable {
    case uitrollen // roll the dough out into a base for the tin
    case vullen    // five ingredients, from five places
    case roeren    // stirring
    case gieten    // pour the bowl into the tin
    case inOven    // carry the tin to Otto
    case bakken    // Otto is loaded, waiting to be tapped
    case klaar     // the cake is out, and wants to go up on the plank
}

struct RoundState: Codable {
    var version = 1
    /// The round's five ingredients, one per source. Slot *i* is always the
    /// ingredient waiting at source *i*, and it is **never mutated during a
    /// round** — `used` is what records how far she has got.
    var basket: [Ingredient] = []
    /// What has gone into the bowl, in the order it went. This is the cake
    /// being made.
    var inBowl: [Ingredient] = []
    /// **Which slots have been used**, which is not the same as how many.
    ///
    /// The order used to be enforced — only the next token could be dragged —
    /// so `inBowl.count` was enough to say where she was. Now every ingredient
    /// can be picked up whenever she likes and the halo only *suggests* an
    /// order, so which ones are gone has to be recorded rather than counted.
    ///
    /// Optional purely so a round saved by the previous build still loads: an
    /// old save has no such key, and the fallback below reconstructs exactly
    /// what the old fixed order meant.
    var used: [Int]?
    var usedSlots: [Int] { used ?? Array(0..<inBowl.count) }
    /// 0…1. Three full turns, or twice that in scrubbing.
    var stir: Float = 0
    /// 0…1. How flat the dough is. Advances on travel of the pin across it.
    var roll: Float = 0
    var step: KitchenStep = .uitrollen
    /// Cakes already baked, oldest first — they stand on the plank on the back
    /// wall. A stand-in for the wall of twelve frames until the bakery exists.
    var shelf: [CakeSpec] = []
    /// The cake currently out of the oven, if any.
    var cake: CakeSpec?

    var bowlSpec: CakeSpec { CakeSpec(ingredients: inBowl) }

    /// The lowest slot she has not used yet — the one the halo lights.
    ///
    /// It is a *suggestion*, not a gate. She can take any of them in any order;
    /// this is only what gets pointed at, and it walks the room in a sensible
    /// route: top shelf, lower shelf, counter, table, floor.
    var nextIndex: Int {
        let used = usedSlots
        for slot in 0..<basket.count where !used.contains(slot) { return slot }
        return basket.count
    }
    var allCollected: Bool { usedSlots.count >= basket.count && !basket.isEmpty }

    /// Which of the five places the next ingredient is waiting in.
    var nextSource: Layout.Source? {
        guard !allCollected else { return nil }
        return Layout.Source(rawValue: min(nextIndex, Layout.Source.allCases.count - 1))
    }

    /// A fresh basket, one ingredient per source.
    ///
    /// Hardcoded here because the garden does not exist yet — `GAMEPLAY.md` §9
    /// puts the kitchen first for exactly this reason. When it does, the garden
    /// fills `basket` and nothing else in the kitchen changes.
    ///
    /// **Five rather than three.** The round was short on the one thing it is
    /// actually about: three drags of an ingredient, and the middle of the
    /// round was over. Five spreads the fetching across the whole room without
    /// adding a rule, since every one of them is the same verb she already
    /// knows.
    ///
    /// ## Dealt from a shuffled deck, not rolled five times
    ///
    /// Each slot used to take its own `randomElement()`, which is five
    /// independent rolls of a six-sided die: the chance that all five came up
    /// different was only about 9%, so a round with two toverbosbessen and no
    /// toverklaver anywhere was the *normal* outcome rather than bad luck
    /// (owner, 2026-08-16). The room has five places to visit and it was
    /// routinely sending her to two of them for the same thing.
    ///
    /// Dealing takes cards off a shuffled deck and only reshuffles when the deck
    /// runs out, so a repeat is impossible until every type has been seen once.
    /// With six ingredients and five slots the deck never runs out, so in
    /// practice every round is five different things — but the rule is written
    /// as dealing rather than as `prefix(5)` because it stays correct if either
    /// number ever moves.
    ///
    /// ## What this costs, and it is not nothing
    ///
    /// **Every cake is now a regenboogtaart.** Five of the six ingredients means
    /// at least four coloured ones in every bowl, and `CakeSpec.kind` calls
    /// three or more colours a rainbow — so `.effen` and `.gemengd`, the
    /// one-colour and two-colour cakes `GAMEPLAY.md` §5 describes, have become
    /// unreachable, and with them the lines Nina has for each colour.
    ///
    /// That is a straight trade of *ingredient* variety for *cake* variety, and
    /// it was made deliberately on the owner's call: being sent to two of the
    /// five places for the same berry is a thing she notices every round, and
    /// which of four cake shapes she got is not.
    ///
    /// It is worth undoing when the garden lands, because the garden is what
    /// fills `basket` and can fill it with an interesting *three* rather than an
    /// exhaustive five. Until then the lever is `Layout.ingredientsPerRound`:
    /// at three, dealing still guarantees no repeats and the colour count is
    /// free to be one, two or three again.
    static func fresh(keeping shelf: [CakeSpec] = []) -> RoundState {
        var state = RoundState()
        var deck: [Ingredient] = []
        state.basket = (0..<Layout.ingredientsPerRound).map { _ in
            if deck.isEmpty { deck = Ingredient.allCases.shuffled() }
            return deck.removeLast()
        }
        state.used = []
        state.shelf = shelf
        return state
    }
}

/// JSON in Application Support, as `CONCEPT.md` §10 asks. SwiftData is more
/// machinery than one small struct needs.
enum RoundStore {

    private static let fileName = "keuken.json"

    private static var directory: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("NinasToverbakkerij", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder,
                                                 withIntermediateDirectories: true)
        return folder
    }

    static func load() -> RoundState {
        guard let url = directory?.appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(RoundState.self, from: data) else {
            return .fresh()
        }
        return state
    }

    static func save(_ state: RoundState) {
        guard let url = directory?.appendingPathComponent(fileName),
              let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// For the debug panel — the whole kitchen back to the beginning, plank
    /// included. It used to keep the shelf; `KitchenRoom.restartRound` has the
    /// argument for why nothing does any more, now that what is on the plank is
    /// what finishes the room.
    static func reset() -> RoundState {
        let state = RoundState.fresh()
        save(state)
        return state
    }
}
