import Foundation

/// **The eleven friends, and the one function that decides whether a cake
/// matched.**
///
/// Straight out of `GAMEPLAY.md` §4, and it lives here rather than beside
/// `CakeSpec` for the reason §4 gives: *"matching is a pure function of the
/// finished `CakeSpec` plus its stickers, and it is evaluated once, at the
/// party. Nothing anywhere else in the game looks at it — not the garden's hint,
/// not the kitchen, not the decorating room."* Putting it in `Game/` would make
/// it look like something four rooms share. One room reads it.
///
/// **All eleven are animals**, because animals are cheap in this style — one
/// body plus a swapped head and colour — and a 4-year-old reads them instantly.
/// `references/feest/gasten.png` is the plate that settled it: five faceted
/// animals told apart by **ears and muzzle alone** on one shared blocky body,
/// which is exactly what `GuestCharacter` builds.
enum Friend: String, Codable, CaseIterable, Identifiable {
    case pip, bella, bas, kiki, bram, bo, wolkje, mo, roos, tobi, nel

    var id: String { rawValue }

    /// What Nina calls them. Used in the debug strip and nowhere on screen —
    /// `CONCEPT.md` §5 rules out text she has to read. The *spoken* name is
    /// `thanksLineID`.
    var dutchName: String {
        switch self {
        case .pip: return "Pip de muis"
        case .bella: return "Bella de vlinder"
        case .bas: return "Bas de beer"
        case .kiki: return "Kiki de kat"
        case .bram: return "Bram de kikker"
        case .bo: return "Bo de vogel"
        case .wolkje: return "Wolkje het schaap"
        case .mo: return "Mo de mol"
        case .roos: return "Roos de egel"
        case .tobi: return "Tobi de hond"
        case .nel: return "Nel de slak"
        }
    }

    /// **What the head is made of.** The body is identical for all eleven; this
    /// is the only thing `GuestCharacter` branches on.
    var soort: Soort {
        switch self {
        case .pip: return .muis
        case .bella: return .vlinder
        case .bas: return .beer
        case .kiki: return .kat
        case .bram: return .kikker
        case .bo: return .vogel
        case .wolkje: return .schaap
        case .mo: return .mol
        case .roos: return .egel
        case .tobi: return .hond
        case .nel: return .slak
        }
    }

    /// **One palette colour each, and no two the same.**
    ///
    /// `references/REFERENCES.md` §3's finding from the twelve-friends cast
    /// sheet — *"bear, cat and dog all came back the same brown"* — is a note
    /// about generating a plate, and it is just as true of building the room:
    /// six animals in three shades of one hue is six animals nobody can tell
    /// apart at 30 mm tall. These are eleven distinct entries from the locked
    /// palette plus the three the kitchen derived.
    var colour: UIColorLike {
        switch self {
        case .pip: return Palette.creamLight
        case .bella: return Palette.lilac
        case .bas: return Palette.honeyAmber
        case .kiki: return Palette.blushPink
        case .bram: return Palette.sage
        case .bo: return Palette.berryBlue
        case .wolkje: return Palette.cream
        case .mo: return Palette.woodBrown
        case .roos: return Palette.rose
        case .tobi: return Palette.sandyWood
        case .nel: return Palette.mint
        }
    }

    /// A shade for the ears, the muzzle and the feet, so the head reads against
    /// the body rather than being one silhouette.
    var accent: UIColorLike {
        switch self {
        case .pip: return Palette.blushPink
        case .bella: return Palette.lilacDeep
        case .bas: return Palette.butterYellow
        case .kiki: return Palette.blushPinkDeep
        case .bram: return Palette.sageDeep
        case .bo: return Palette.berryBlueDeep
        case .wolkje: return Palette.creamLight
        case .mo: return Palette.blushPinkDeep
        case .roos: return Palette.blushPinkDeep
        case .tobi: return Palette.creamLight
        case .nel: return Palette.mintLight
        }
    }

    /// What they love. `GAMEPLAY.md` §4's table, one case per row.
    var wish: Wish {
        switch self {
        case .pip: return .sprinkels(8)
        case .bella: return .kleur(.roze)
        case .bas: return .kleur(.geel)
        case .kiki: return .effect(.fonkelt)
        case .bram: return .kleur(.groen)
        case .bo: return .kleur(.blauw)
        case .wolkje: return .effect(.hoog)
        case .mo: return .stickers(.kaarsje, 3)
        case .roos: return .stickers(.hartje, 3)
        case .tobi: return .stickers(.sterretje, 3)
        case .nel: return .tweeKleuren
        }
    }

    /// **Nina relaying the thanks, by name.**
    ///
    /// `GAMEPLAY.md` §6.5 asks for the friend of the day to thank her *by name*,
    /// in their own voice. Eleven friend voices do not exist and are most of the
    /// game's remaining dialogue, so until they do, Nina says it for them —
    /// *"Pip zegt: dankjewel, Nina!"* — one variant each, in `script-feest.json`.
    ///
    /// It is the honest half of the design rather than a placeholder for it: the
    /// friend is still named, the name is still spoken, and the day the eleven
    /// are cast this id is what gets re-pointed. Derived off the case name for
    /// the `Ingredient.nameLineID` reason — a typo in a line id is silence.
    var thanksLineID: String { "nina.feest.dank.\(rawValue)" }

    /// **The wish, evaluated.** Pure, total, and read exactly once per party.
    ///
    /// Note what it does *not* do: there is no "almost", no score and no second
    /// outcome. `GAMEPLAY.md` §4 is explicit that a friend who did not get their
    /// wish is exactly as delighted, in a different line — so all this decides is
    /// **which happy thing happens**, never whether one does.
    func matches(_ cake: CakeSpec) -> Bool {
        switch wish {
        case .kleur(let colour):
            return cake.colours.contains(colour)
        case .effect(let effect):
            return cake.effects.contains(effect)
        case .sprinkels(let count):
            return cake.count(of: .sprinkel) >= count
        case .stickers(let kind, let count):
            return cake.count(of: kind) >= count
        case .tweeKleuren:
            return cake.colours.count >= 2
        }
    }

    /// **Which tray or jar shimmers.** `GAMEPLAY.md` §6.2 and §6.4 both put a
    /// hint on the wish, and both ask the wish what it is about without knowing
    /// the eleven. The garden and the decorating room read this off the friend
    /// rather than re-deriving the table.
    var hintedSticker: StickerKind? {
        if case .stickers(let kind, _) = wish { return kind }
        if case .sprinkels = wish { return .sprinkel }
        return nil
    }

    var hintedColour: CakeColour? {
        if case .kleur(let colour) = wish { return colour }
        return nil
    }

    /// **Which seed jar shimmers**, for a colour or effect wish. Decoration
    /// wishes have no jar. Derived here so the garden does not re-walk §4.
    var hintedIngredient: Ingredient? {
        if let colour = hintedColour {
            return Ingredient.allCases.first { $0.colour == colour }
        }
        switch wish {
        case .effect(.fonkelt): return .sterrensuiker
        case .effect(.hoog): return .wolkenroom
        case .effect(.glimt): return .honing
        default: return nil
        }
    }

    /// **A friend nobody chose**, for a party entered without one.
    ///
    /// A visit to the disco has no bakery order behind it. The room deals one,
    /// which is exactly what the decorating room does with a cake on a visit
    /// (`CakeSpec.dealt`, owner's call 2026-08-16) and for the same reason. The
    /// answer to a missing thing is to supply it rather than to refuse her the
    /// room.
    static func dealt() -> Friend {
        allCases.randomElement() ?? .pip
    }

    /// **The other guests at the party, excluding the friend of the day.**
    ///
    /// §6.5 says *everyone she has baked for so far*. The wall can say who that
    /// is, and this still deals a shuffled handful so a first-round party is not
    /// five empty spots. The count is `FeestLayout.guestCount - 1` and it is
    /// decided by the floor, not by this. See `FeestLayout.guestSpots`.
    static func others(besides friend: Friend, count: Int) -> [Friend] {
        allCases.filter { $0 != friend }.shuffled().prefix(count).map { $0 }
    }

    /// The eleven heads, and the only thing that differs between two guests
    /// beyond colour.
    /// **The raw value is the model's filename**, so a friend's species and the
    /// USDZ that draws it cannot drift apart: `models/beertje.py` writes one file
    /// per case as `beertje-<raw>.usdz`.
    enum Soort: String {
        case muis, vlinder, beer, kat, kikker, vogel, schaap, mol, egel, hond, slak
    }
}

/// What a friend loves, in the terms the cake is actually made of.
///
/// It is an enum rather than a closure so that a wish can be *asked what it is
/// about* — which is what the garden's shimmering seed jar and the decorating
/// room's shimmering tray both need, and neither of them can call a predicate.
enum Wish: Equatable {
    /// The cake's colours include this one.
    case kleur(CakeColour)
    /// The cake carries this effect — Kiki's glitter, Wolkje's height.
    case effect(CakeEffect)
    /// At least this many sprinkles. Pip's, and the reason the decorating room
    /// places sprinkles as countable objects rather than as a density.
    case sprinkels(Int)
    /// At least this many of one sticker. **Placed, not lit** — `CakeSpec`
    /// documents why Mo's three candles must not depend on lighting them.
    case stickers(StickerKind, Int)
    /// Nel's shell: two colours through each other.
    case tweeKleuren
}
