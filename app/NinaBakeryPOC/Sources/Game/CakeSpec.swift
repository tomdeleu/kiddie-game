import Foundation

/// The six seeds, and the rule that turns three of them into a cake.
///
/// Straight out of `GAMEPLAY.md` §5, and deliberately kept as data rather than
/// as branches in the kitchen: the garden will fill the basket later, the
/// decorating room and the party will read the same `CakeSpec`, and the wall of
/// frames will store it. It is the one thing a round actually produces.
enum Ingredient: String, Codable, CaseIterable {
    case aardbei         // regenboogaardbei
    case bosbes          // toverbosbes
    case honing          // zonnehoning
    case klaver          // toverklaver
    case wolkenroom      // wolkenroom
    case sterrensuiker   // sterrensuiker

    var dutchName: String {
        switch self {
        case .aardbei: return "regenboogaardbei"
        case .bosbes: return "toverbosbes"
        case .honing: return "zonnehoning"
        case .klaver: return "toverklaver"
        case .wolkenroom: return "wolkenroom"
        case .sterrensuiker: return "sterrensuiker"
        }
    }

    /// What it gives the cake. Star sugar gives no colour at all — that is the
    /// point of it, and it is why "no colours" is a real outcome.
    var colour: CakeColour? {
        switch self {
        case .aardbei: return .roze
        case .bosbes: return .blauw
        case .honing: return .geel
        case .klaver: return .groen
        case .wolkenroom: return .wit
        case .sterrensuiker: return nil
        }
    }

    var effect: CakeEffect? {
        switch self {
        case .honing: return .glimt
        case .wolkenroom: return .hoog
        case .sterrensuiker: return .fonkelt
        default: return nil
        }
    }

    /// Luna's reaction as it lands in the bowl.
    var lineID: String { "luna.ingredient.\(rawValue)" }

    /// The colour of the token she drags. Reads as the fruit, not as the cake.
    var tokenColour: UIColorLike {
        switch self {
        case .aardbei: return Palette.rose
        case .bosbes: return Palette.berryBlueDeep
        case .honing: return Palette.butterYellow
        case .klaver: return Palette.sageDeep
        case .wolkenroom: return Palette.creamLight
        case .sterrensuiker: return Palette.mintLight
        }
    }
}

enum CakeColour: String, Codable, CaseIterable {
    case roze, blauw, geel, groen, wit

    var base: UIColorLike {
        switch self {
        case .roze: return Palette.blushPink
        case .blauw: return Palette.berryBlue
        case .geel: return Palette.butterYellow
        case .groen: return Palette.sage
        case .wit: return Palette.creamLight
        }
    }

    /// A shade down, for the bottom tier. One colour "deep and strong" needs
    /// two values or the cake reads as a flat cylinder.
    var deep: UIColorLike {
        switch self {
        case .roze: return Palette.blushPinkDeep
        case .blauw: return Palette.berryBlueDeep
        case .geel: return Palette.sandyWood
        case .groen: return Palette.sageDeep
        case .wit: return Palette.cream
        }
    }

    var lineID: String { "luna.taart.\(rawValue)" }
}

enum CakeEffect: String, Codable {
    case fonkelt   // star sugar: it sparkles
    case glimt     // sun honey: a soft glow
    case hoog      // cloud cream: a tall cake

    var lineID: String { "luna.effect.\(rawValue)" }
}

/// A finished cake. Everything downstream — decorating, the party, the frame on
/// the wall — is this struct plus stickers.
struct CakeSpec: Codable, Equatable {

    enum Kind: String, Codable {
        case room        // nothing coloured went in
        case effen       // one colour, deep and strong
        case gemengd     // two colours, marbled
        case regenboog   // three or more
    }

    var ingredients: [Ingredient] = []

    /// Distinct colours, in the order she added them. Order matters: the tiers
    /// are painted from it, so two identical baskets stirred in a different
    /// order still look like her cake.
    var colours: [CakeColour] {
        var seen: [CakeColour] = []
        for ingredient in ingredients {
            guard let colour = ingredient.colour, !seen.contains(colour) else { continue }
            seen.append(colour)
        }
        return seen
    }

    var kind: Kind {
        switch colours.count {
        case 0: return .room
        case 1: return .effen
        case 2: return .gemengd
        default: return .regenboog
        }
    }

    var effects: [CakeEffect] {
        var found: [CakeEffect] = []
        for ingredient in ingredients {
            guard let effect = ingredient.effect, !found.contains(effect) else { continue }
            found.append(effect)
        }
        return found
    }

    var sparkles: Bool { effects.contains(.fonkelt) }
    var glows: Bool { effects.contains(.glimt) }
    var isTall: Bool { effects.contains(.hoog) }

    /// Colour per tier, bottom first. A cake is three tiers, so this is where
    /// "swirled" and "rainbow" actually become visible.
    func tierColours(_ tiers: Int = 3) -> [UIColorLike] {
        let palette = colours
        guard !palette.isEmpty else {
            return [Palette.cream, Palette.creamLight, Palette.cream]
        }
        if palette.count == 1 {
            let colour = palette[0]
            return [colour.deep, colour.base, colour.deep]
        }
        return (0..<tiers).map { index in
            let colour = palette[index % palette.count]
            return index == 0 ? colour.deep : colour.base
        }
    }

    /// What the batter looks like right now — the colour of the last coloured
    /// thing she dropped in. It changes under her hands as she fills the bowl,
    /// which is the only feedback that the choice is doing anything.
    var batterColour: UIColorLike {
        for ingredient in ingredients.reversed() {
            if let colour = ingredient.colour { return colour.base }
        }
        return Palette.cream
    }

    /// What Luna says when it comes out of the oven: the colour, then at most
    /// one effect. Two would be a monologue, and she is four.
    var reactionLines: [String] {
        var ids: [String] = []
        switch kind {
        case .room: ids.append("luna.taart.room")
        case .effen: ids.append(colours[0].lineID)
        case .gemengd: ids.append("luna.taart.gemengd")
        case .regenboog: ids.append("luna.taart.regenboog")
        }
        // Height is the most visible, sparkle the most exciting; glow reads
        // last, so it only gets a line when it is the only thing to say.
        if let effect = effects.first(where: { $0 == .fonkelt })
            ?? effects.first(where: { $0 == .hoog })
            ?? effects.first {
            ids.append(effect.lineID)
        }
        return ids
    }
}
