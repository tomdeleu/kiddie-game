import Foundation

/// **What the garden picked, waiting for the kitchen.**
///
/// The one thing that crosses between these two rooms, and it is deliberately
/// the smallest possible thing: a list of ingredients in the order she picked
/// them. `ROOMS.md` §2 says anything a room invents that another room needs
/// belongs outside that room's own save, and this is the first case of it.
///
/// **The order is not incidental.** `CakeSpec.colours` reads the order she added
/// them and paints the tiers from it, which is what makes two identical baskets
/// come out as two different cakes. Never sort this.
///
/// It is a *handover*, not a shared state: the garden writes it when the basket
/// fills and the kitchen consumes it — reads it, uses it, and clears it — so a
/// basket can only ever be baked once. Without the clear, every restart in the
/// kitchen for the rest of the week would deal the same five things she picked
/// on Tuesday.
struct Harvest: Codable {
    var version = 1
    var basket: [Ingredient] = []
}

enum HarvestStore {

    private static let fileName = "harvest.json"

    private static var directory: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("NinasToverbakkerij", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder,
                                                 withIntermediateDirectories: true)
        return folder
    }

    static func load() -> Harvest {
        guard let url = directory?.appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url),
              let harvest = try? JSONDecoder().decode(Harvest.self, from: data) else {
            return Harvest()
        }
        return harvest
    }

    static func save(_ harvest: Harvest) {
        guard let url = directory?.appendingPathComponent(fileName),
              let data = try? JSONEncoder().encode(harvest) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// **Take the basket, and leave nothing behind.**
    ///
    /// Returns nil when there is nothing waiting, which is the ordinary case
    /// and is why the kitchen still deals its own deck — the garden is one room
    /// of six and she is allowed to walk into the kitchen without having been
    /// anywhere first.
    static func take() -> [Ingredient]? {
        let harvest = load()
        guard !harvest.basket.isEmpty else { return nil }
        save(Harvest())
        return harvest.basket
    }

    static func put(_ basket: [Ingredient]) {
        save(Harvest(basket: basket))
    }
}
