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
    // **The two colourless ones, added 2026-08-16 to get the cake rules back.**
    // See the note over `RoundState.fresh`: five distinct ingredients drawn
    // from six meant at least four coloured ones in every bowl, so every cake
    // was a regenboogtaart and `.effen` and `.gemengd` had quietly become
    // unreachable. Two more *colourless* ones change the arithmetic — the draw
    // can now come up two-coloured about one round in six.
    //
    // They earn their place beyond the arithmetic. Both carry an effect that
    // until now only a coloured ingredient could give, so `glimt` and `hoog`
    // stop being tied to yellow and white and can land on a cake of any colour.
    case maanstof        // moon dust — makes it glow, no colour of its own
    case veertje         // a magic feather — makes it rise, no colour of its own

    var dutchName: String {
        switch self {
        case .aardbei: return "regenboogaardbei"
        case .bosbes: return "toverbosbes"
        case .honing: return "zonnehoning"
        case .klaver: return "toverklaver"
        case .wolkenroom: return "wolkenroom"
        case .sterrensuiker: return "sterrensuiker"
        case .maanstof: return "maanstof"
        case .veertje: return "toverveertje"
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
        // **Three colourless ingredients now, and that is the point of them.**
        // `GAMEPLAY.md` §5 always allowed "no colours" as a real outcome; what
        // it did not survive was five draws from a deck that was five-sixths
        // coloured.
        case .sterrensuiker, .maanstof, .veertje: return nil
        }
    }

    var effect: CakeEffect? {
        switch self {
        case .honing, .maanstof: return .glimt
        case .wolkenroom, .veertje: return .hoog
        case .sterrensuiker: return .fonkelt
        default: return nil
        }
    }

    /// Nina's reaction as it lands in the bowl.
    var lineID: String { "nina.ingredient.\(rawValue)" }

    /// **What it is called, said when she taps it instead of dragging it.**
    ///
    /// The pair is the whole idea: `lineID` is what an ingredient *does* to the
    /// cake and fires when it goes in the bowl; this is what it *is*, and fires
    /// on a tap. Six cases, one id each, derived off the case name so the six
    /// are spelled once — a typo here is a silent tap, which is the hardest kind
    /// of bug to notice in a game with no text in it.
    var nameLineID: String { "nina.dit.\(rawValue)" }

    /// The colour of the token she drags. Reads as the fruit, not as the cake.
    var tokenColour: UIColorLike {
        switch self {
        case .aardbei: return Palette.rose
        case .bosbes: return Palette.berryBlueDeep
        case .honing: return Palette.butterYellow
        case .klaver: return Palette.sageDeep
        case .wolkenroom: return Palette.creamLight
        case .sterrensuiker: return Palette.mintLight
        case .maanstof: return Palette.lilac
        case .veertje: return Palette.creamLight
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

    /// **What the batter turns when this colour goes in**, which is not `base`
    /// and not `deep` either.
    ///
    /// A cake tier is seen against a room; batter is seen against the inside of
    /// a cream bowl, from across the table, by someone who is four. The job is
    /// separation from cream, and the two existing values are each wrong for it
    /// in one case: `geel`'s `deep` is `sandyWood`, which next to cream reads as
    /// *browner* rather than yellower, and `base` for pink and blue is only a
    /// step or two off the cream it is replacing.
    ///
    /// So this is a third value picked for one job — the most saturated member
    /// of each family that is still unmistakably that colour. Owner's note,
    /// 2026-08-16: "the colour change should be quite visible."
    ///
    /// White is the honest exception. `wolkenroom` makes a *white* cake, so its
    /// batter goes to the lightest cream there is and the change is a brightening
    /// rather than a hue — and `sterrensuiker` changes nothing at all, which is
    /// the point of it (`GAMEPLAY.md` §5: "no colours" is a real outcome).
    var batter: UIColorLike {
        switch self {
        case .roze: return Palette.blushPinkDeep
        case .blauw: return Palette.berryBlueDeep
        case .geel: return Palette.honeyAmber
        case .groen: return Palette.sageDeep
        case .wit: return Palette.creamLight
        }
    }

    var lineID: String { "nina.taart.\(rawValue)" }
}

enum CakeEffect: String, Codable {
    case fonkelt   // star sugar: it sparkles
    case glimt     // sun honey: a soft glow
    case hoog      // cloud cream: a tall cake

    var lineID: String { "nina.effect.\(rawValue)" }
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

    // MARK: - What the decorating room adds
    //
    // **Every one of these is `Optional`, and that is not a style choice.**
    //
    // `CakeSpec` had no `version` field before this, and Swift's synthesised
    // `init(from:)` does *not* fall back to a memberwise default for a missing
    // key — it throws `keyNotFound`. Every cake already sitting in the `shelf`
    // array of somebody's `keuken.json` was written without these keys, so a
    // non-optional field here would fail to decode all of them, `RoomStore.load`
    // would fall back to `.fresh()`, and her plank would silently empty.
    //
    // `GAMEPLAY.md` §8 is blunt about the stakes: "getting this wrong costs a
    // child her wall." `RoundState.used` is the pattern, accessors and all.

    /// Bumped when the shape changes in a way a reader needs to know about.
    /// Absent means 1 — the kitchen-only build.
    var version: Int?

    var stickers: [Sticker]?
    var strokes: [Stroke]?

    var specVersion: Int { version ?? 1 }
    /// **Read through these, never through the optionals.** Same reason
    /// `RoundState.usedSlots` exists.
    var placed: [Sticker] { stickers ?? [] }
    var piped: [Stroke] { strokes ?? [] }

    var isDecorated: Bool { !placed.isEmpty || !piped.isEmpty }

    /// **The counts the wishes are made of** (`GAMEPLAY.md` §4).
    ///
    /// They live here rather than in the decorating room because §4 is explicit
    /// that matching is evaluated **once, at the party**, and that nothing else
    /// in the game looks at it — not the garden's hint, not the kitchen, and not
    /// the decorating room. The room fills the array; only the party reads it.
    func count(of kind: StickerKind) -> Int {
        placed.filter { $0.kind == kind }.count
    }

    /// Mo's wish is *three candles*, and it is **placed, not lit**. Lighting one
    /// is a toy; making the wish depend on it would smuggle a required action
    /// into the one room that must never ask her for anything.
    var litCandles: Int {
        placed.filter { $0.kind == .kaarsje && $0.lit == true }.count
    }

    /// **A cake nobody baked**, for a room entered on a visit rather than
    /// mid-round.
    ///
    /// `GAMEPLAY.md` §6.4 left it open whether the decorating room has a visit
    /// mode at all, on the grounds that decorating with no cake in front of her
    /// is not a thing. The owner's call (2026-08-16) is that it does, and that
    /// the answer to the missing cake is to deal one rather than to refuse her
    /// the room.
    ///
    /// Dealt off a shuffled deck, the same rule as `RoundState.fresh` and for
    /// the same reason: five independent rolls of a six-sided die come up all
    /// different only about 9% of the time, and a visit cake that is two of the
    /// same berry is a duller cake than the room deserves.
    ///
    /// Five is spelled here rather than read off `KitchenLayout` on purpose:
    /// this struct is the one thing that crosses rooms (`ROOMS.md` §2) and must
    /// not depend on any of them. The lever that will change the real number is
    /// `KitchenLayout.ingredientsPerRound`, when the garden lands and starts
    /// filling the basket with an interesting three rather than an exhaustive
    /// five — and this default should follow it then.
    static func dealt(_ count: Int = 5) -> CakeSpec {
        var deck: [Ingredient] = []
        let picks = (0..<count).map { _ -> Ingredient in
            if deck.isEmpty { deck = Ingredient.allCases.shuffled() }
            return deck.removeLast()
        }
        return CakeSpec(ingredients: picks)
    }

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
    ///
    /// **Through `CakeColour.batter`, not `base`.** `base` is a tier colour, and
    /// a tier colour inside a cream bowl seen from across the room is a tint
    /// rather than a colour — which is why the change sometimes did not land at
    /// all (owner, 2026-08-16).
    var batterColour: UIColorLike {
        for ingredient in ingredients.reversed() {
            if let colour = ingredient.colour { return colour.batter }
        }
        return Palette.cream
    }

    /// What Nina says when it comes out of the oven: the colour, then at most
    /// one effect. Two would be a monologue, and she is four.
    var reactionLines: [String] {
        var ids: [String] = []
        switch kind {
        case .room: ids.append("nina.taart.room")
        case .effen: ids.append(colours[0].lineID)
        case .gemengd: ids.append("nina.taart.gemengd")
        case .regenboog: ids.append("nina.taart.regenboog")
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
