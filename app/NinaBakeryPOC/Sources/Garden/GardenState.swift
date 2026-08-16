import Foundation

/// Where the garden round is. One value, saved after every action.
///
/// `GAMEPLAY.md` §7: interruptions are free. The iPad gets taken away
/// mid-watering and has to come back mid-watering, with the same five plants at
/// the same heights. Everything the garden draws is rebuilt from this struct,
/// which is what makes it a save rather than a restore mechanism (`ROOMS.md`
/// §2).
enum GardenStep: String, Codable {
    case zaaien   // a seed from a jar into a hole in the bed
    case gieten   // sweep the can across the bed; a pass grows what it crosses
    case plukken  // tap a ripe plant and it hops into the basket
    case klaar    // the basket is full
}

/// One hole in the bed.
///
/// **Picking empties it rather than marking it**, which is why there is no
/// `picked` flag: an empty hole is one she can sow again, and that is exactly
/// what should happen after a harvest. The kitchen's `RoundState.used` needed a
/// flag because its five sources are places rather than slots; a hole is a slot.
struct Plot: Codable, Equatable {
    var seed: Ingredient?
    /// 0…3. 0 is sown, 3 is ripe. One watering pass per stage.
    var growth: Int = 0

    var isEmpty: Bool { seed == nil }
    var isRipe: Bool { seed != nil && growth >= GardenLayout.ripeStage }
}

struct GardenState: Codable {
    var version = 1
    var plots: [Plot] = []
    /// What she has picked, in the order she picked it. **This is the basket the
    /// kitchen will be handed** — `CakeSpec` reads the order, so it is not a set
    /// and must never be sorted.
    var basket: [Ingredient] = []
    var step: GardenStep = .zaaien

    /// How many the basket holds. The kitchen's number, so the two rooms cannot
    /// disagree about what a round is.
    static var capacity: Int { KitchenLayout.ingredientsPerRound }

    var isFull: Bool { basket.count >= Self.capacity }
    var plantedCount: Int { plots.filter { !$0.isEmpty }.count }
    var ripeCount: Int { plots.filter(\.isRipe).count }

    /// **The step, derived from the bed.**
    ///
    /// Stored so the room can be entered at any step cold, and recomputed after
    /// every action so it can never disagree with what is actually growing.
    /// `ROOMS.md` §1 asks for a step machine; it does not ask for the step to be
    /// a fact independent of the room, and here it would only be a second place
    /// for the truth to live.
    ///
    /// **Nothing is gated by it.** She can water a half-sown bed, pick before
    /// the bed is full, and leave at any time — the step only decides what
    /// glows and what Nina says next.
    ///
    /// The second clause of the sowing rule is the one that is easy to get
    /// wrong: once the basket plus what is still in the ground can reach five,
    /// stop asking her to sow. Without it, harvesting the fourth plant empties a
    /// hole and the room turns round and asks for a sixth seed.
    static func step(plots: [Plot], basket: [Ingredient]) -> GardenStep {
        if basket.count >= capacity { return .klaar }
        let planted = plots.filter { !$0.isEmpty }.count
        if basket.count + planted < capacity, plots.contains(where: \.isEmpty) {
            return .zaaien
        }
        if plots.contains(where: { !$0.isEmpty && $0.growth < GardenLayout.ripeStage }) {
            return .gieten
        }
        return .plukken
    }

    mutating func refreshStep() {
        step = Self.step(plots: plots, basket: basket)
    }

    /// The hole the halo points at: the lowest empty one, left to right, so the
    /// bed fills in the order it is read.
    var nextEmptyPlot: Int? { plots.firstIndex(where: \.isEmpty) }
    /// And the first ripe one, same order.
    var nextRipePlot: Int? { plots.firstIndex(where: \.isRipe) }

    static func fresh() -> GardenState {
        var state = GardenState()
        state.plots = Array(repeating: Plot(), count: GardenLayout.plotCount)
        state.refreshStep()
        return state
    }
}

/// JSON in Application Support, beside the kitchen's `keuken.json`.
///
/// **One file per room** (`ROOMS.md` §2), so adding a room cannot corrupt
/// another one's save. A save that fails to decode falls back to `.fresh()`,
/// which costs her a bed of plants — do not let that be the ordinary path.
enum GardenStore {

    private static let fileName = "tuin.json"

    private static var directory: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("NinasToverbakkerij", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder,
                                                 withIntermediateDirectories: true)
        return folder
    }

    static func load() -> GardenState {
        guard let url = directory?.appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url),
              var state = try? JSONDecoder().decode(GardenState.self, from: data) else {
            return .fresh()
        }
        // **A bed that is the wrong length is a save from a different build.**
        // `plotCount` follows `KitchenLayout.ingredientsPerRound`, which `GAMEPLAY.md`
        // §10 explicitly leaves open, so this will happen the day that number
        // moves. Growing the bed keeps her plants; shrinking it keeps the ones
        // that still fit, which is the best answer available and better than
        // dropping the whole save on the floor.
        if state.plots.count != GardenLayout.plotCount {
            state.plots = Array(state.plots.prefix(GardenLayout.plotCount))
            while state.plots.count < GardenLayout.plotCount { state.plots.append(Plot()) }
        }
        state.refreshStep()
        return state
    }

    static func save(_ state: GardenState) {
        guard let url = directory?.appendingPathComponent(fileName),
              let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func reset() -> GardenState {
        let state = GardenState.fresh()
        save(state)
        return state
    }
}
