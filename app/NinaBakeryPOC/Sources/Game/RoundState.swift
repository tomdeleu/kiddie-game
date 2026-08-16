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
    /// ## What it cost, and what got it back
    ///
    /// Dealing five distinct ingredients out of **six** meant at least four
    /// coloured ones in every bowl, and `CakeSpec.kind` calls three colours or
    /// more a rainbow — so `.effen` and `.gemengd`, the one-colour and
    /// two-colour cakes in `GAMEPLAY.md` §5, became unreachable overnight, and
    /// Nina's per-colour lines with them. Ingredient variety had been bought
    /// with cake variety.
    ///
    /// **Two more colourless ingredients** — `maanstof` and `veertje` — change
    /// the arithmetic rather than working around it. The deck is now five
    /// coloured and three colourless, and five draws from that gives:
    ///
    /// | colours drawn | chance | cake |
    /// |---|---|---|
    /// | 2 | 17.9% | `gemengd` — two colours, marbled |
    /// | 3 | 53.6% | `regenboog` |
    /// | 4 | 26.8% | `regenboog` |
    /// | 5 | 1.8% | `regenboog` |
    ///
    /// So a two-colour cake is back, about one round in six. **`.effen` is
    /// still out of reach** and honestly cannot be bought this way: one colour
    /// from five draws needs four colourless ingredients in the hand, which
    /// needs at least four in the deck, which is most of it. The remaining
    /// lever is `Layout.ingredientsPerRound` — at three, the colour count is
    /// free to be one, two or three and every cake in §5 comes back. That is
    /// the change to make when the garden lands and starts choosing what goes
    /// in the basket, because an interesting three beats an exhaustive five.
    ///
    /// ## And the garden fills it, when she has been there
    ///
    /// `HarvestStore` is the handover (`app/.../Game/Harvest.swift`): De Tuin
    /// writes the five things she actually picked, and the next round started in
    /// the kitchen bakes those instead of five dealt off a deck. The order is
    /// hers and is not sorted — `CakeSpec.colours` reads it and paints the tiers
    /// from it, which is what makes two identical baskets come out as two
    /// different cakes.
    ///
    /// **The deck stays as the fallback rather than being replaced**, because
    /// the garden is one room of six and she is allowed to walk into the kitchen
    /// without having been anywhere first. Taking the harvest also clears it, so
    /// a basket is baked once — otherwise every restart for the rest of the week
    /// would deal the same five things she picked on Tuesday.
    static func fresh(keeping shelf: [CakeSpec] = []) -> RoundState {
        var state = RoundState()
        state.used = []
        state.shelf = shelf

        // **A harvest is used exactly as it came**, short or not. `GAMEPLAY.md`
        // §6.2: she may leave the garden with one ingredient or with five, and
        // fewer is a plainer cake rather than a broken round — the kitchen lays
        // its sources out from the basket it is handed, so three ingredients is
        // three places to visit. Topping it up to five would quietly overrule
        // her.
        if let picked = HarvestStore.take(), !picked.isEmpty {
            state.basket = Array(picked.prefix(Layout.ingredientsPerRound))
            return state
        }

        var deck: [Ingredient] = []
        state.basket = (0..<Layout.ingredientsPerRound).map { _ in
            if deck.isEmpty { deck = Ingredient.allCases.shuffled() }
            return deck.removeLast()
        }
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
