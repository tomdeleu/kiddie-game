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
    case vullen    // three ingredients, from three places, in order
    case roeren    // stirring
    case gieten    // pour the bowl into the tin
    case inOven    // carry the tin to Otto
    case bakken    // Otto is loaded, waiting to be tapped
    case klaar     // the cake is out
}

struct RoundState: Codable {
    var version = 1
    /// The round's three ingredients, in the order she collects them. Fixed for
    /// the whole round; see `nextIndex`.
    var basket: [Ingredient] = []
    /// What has gone into the bowl. This is the cake being made.
    var inBowl: [Ingredient] = []
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

    /// The three ingredients in collection order. **Never mutated during a
    /// round** — `inBowl.count` is how far she has got, and index *i* of the
    /// basket is always the ingredient waiting at source *i*. Consuming by
    /// removal made the two lists disagree about which shelf a token came from.
    var nextIndex: Int { inBowl.count }
    var allCollected: Bool { inBowl.count >= basket.count }

    /// Which of the three places the next ingredient is waiting in.
    var nextSource: Layout.Source? {
        guard !allCollected else { return nil }
        return Layout.Source(rawValue: min(nextIndex, Layout.Source.allCases.count - 1))
    }

    /// A fresh basket of three.
    ///
    /// Hardcoded here because the garden does not exist yet — `GAMEPLAY.md` §9
    /// puts the kitchen first for exactly this reason. When it does, the garden
    /// fills `basket` and nothing else in the kitchen changes.
    static func fresh(keeping shelf: [CakeSpec] = []) -> RoundState {
        var state = RoundState()
        state.basket = (0..<3).map { _ in Ingredient.allCases.randomElement() ?? .aardbei }
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

    /// For the debug panel — start the round over without deleting her shelf.
    static func reset(keepingShelf shelf: [CakeSpec]) -> RoundState {
        let state = RoundState.fresh(keeping: shelf)
        save(state)
        return state
    }
}
