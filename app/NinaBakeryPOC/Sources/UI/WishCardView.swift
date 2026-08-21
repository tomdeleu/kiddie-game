import SwiftUI

/// **The wish card, pinned in the corner of the screen for the whole round.**
/// `GAMEPLAY.md` §4.
///
/// *"The wish card then pins itself to the top corner of the screen and stays
/// there for the whole round. Tapping it replays the line. It is the only
/// persistent interface element in the game, and it carries no text."*
///
/// Three things follow from that, and they are why this is a `FacetButton`
/// rather than a bespoke view:
///
/// - **It is a control she may tap**, so it has to look like the other things
///   she may tap. `references/buttons/README.md`'s whole argument is that one
///   octagon used everywhere is what makes twelve controls read as one family;
///   inventing a second shape for the one control that is always on screen would
///   be the worst possible place to break that.
/// - **It carries one glyph and no words**, which is what the button already is.
/// - **It is `chrome`-sized, not `game`-sized.** It sits at the edge of the
///   screen for eleven minutes at a stretch, and a 120 pt card in the corner of
///   the garden is a 120 pt hole in the garden.
///
/// The glyph is the friend's wish said as a picture. `references/bakkerij/`
/// records that this works with no text at all — *"one golden honey droplet,
/// legible at thumbnail size"* — reproduced across two art directions, which is
/// the evidence that a four-year-old reads the shape rather than the label.
@MainActor
struct WishCardView: View {
    let friend: Friend
    var action: () -> Void

    var body: some View {
        FacetButton(symbol: Self.symbol(for: friend.wish),
                    accessibilityLabel: "De wens van \(friend.dutchName)",
                    tone: Self.tone(for: friend),
                    diameter: FacetSize.chrome,
                    action: action)
    }

    /// **One shape per wish**, and every one of them is a thing rather than a
    /// word. Chosen from the symbols a 4-year-old already knows off her own
    /// cake: a heart is a heart, a candle is a flame, a cloud is a cloud.
    static func symbol(for wish: Wish) -> String {
        switch wish {
        case .kleur:
            // A colour wish has no object in it, so the shape is a blot of
            // paint and the colour does the talking — see `tone(for:)`.
            return "circle.fill"
        case .effect(let effect):
            switch effect {
            case .fonkelt, .glimt: return "sparkles"
            case .hoog: return "cloud.fill"
            }
        case .sprinkels:
            return "circle.grid.3x3.fill"
        case .stickers(let kind, _):
            switch kind {
            case .kaarsje: return "flame.fill"
            case .hartje: return "heart.fill"
            case .sterretje: return "star.fill"
            case .kroontje: return "crown.fill"
            case .fruitje: return "leaf.fill"
            case .roomtoefje: return "drop.fill"
            case .sprinkel: return "circle.grid.3x3.fill"
            }
        case .tweeKleuren:
            return "circle.lefthalf.filled"
        }
    }

    /// **A colour wish wears its own colour**, because for five of the eleven
    /// friends the colour *is* the wish and a sage card asking for a pink cake
    /// would be the one piece of chrome in the game that lies.
    ///
    /// Everything else wears the bakery's own wood tone — `FacetTone.sandy` is
    /// documented as *"for anything to do with the bakery itself"*, and the card
    /// is the bakery's errand carried into four other rooms.
    static func tone(for friend: Friend) -> FacetTone {
        guard let colour = friend.hintedColour else { return .sandy }
        switch colour {
        case .roze: return .rose
        case .blauw: return .berry
        case .groen: return .sage
        case .geel, .wit: return FacetTone(face: Palette.honeyAmber)
        }
    }
}
