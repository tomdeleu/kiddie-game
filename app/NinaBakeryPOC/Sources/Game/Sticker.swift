import Foundation

/// **What she puts on the cake.** `GAMEPLAY.md` §6.4's seven trays.
///
/// Seven cases and no more: `GAMEPLAY.md` §8 budgets seven sticker types, and
/// each is one tray on the floor.
enum StickerKind: String, Codable, CaseIterable, Identifiable {
    case sprinkel      // hundreds-and-thousands, from the shaker and the tray
    case kaarsje       // a candle, which lights when tapped
    case hartje
    case sterretje
    case kroontje
    case fruitje
    case roomtoefje    // a swirl of cream

    var id: String { rawValue }

    /// **What it is called, said when she taps it.** Spelled once and derived
    /// off the case name, the `Ingredient.nameLineID` rule — a typo in a line id
    /// is a silent tap, which is the hardest kind of bug to notice in a game
    /// with no text in it.
    var nameLineID: String { "nina.dit.\(rawValue)" }

    var colour: UIColorLike {
        switch self {
        case .sprinkel: return Palette.blushPinkDeep
        case .kaarsje: return Palette.mint
        case .hartje: return Palette.blushPink
        case .sterretje: return Palette.butterYellow
        case .kroontje: return Palette.butterYellow
        case .fruitje: return Palette.rose
        case .roomtoefje: return Palette.creamLight
        }
    }

    /// Roughly how big it is on the cake, in metres at the cake's own scale.
    /// A seventh of the bottom tier's width or less, so fifteen of them read as
    /// a decorated cake rather than as confetti.
    var size: Float {
        switch self {
        case .sprinkel: return 0.0036
        case .kaarsje: return 0.011
        case .hartje, .sterretje, .kroontje, .fruitje: return 0.0085
        case .roomtoefje: return 0.0090
        }
    }
}

/// **Where something sits on the cake, in the cake's own terms.**
///
/// Tier, which face of it, the angle round the axis, and how far along that
/// face — never a world or screen position. Three things fall out of that and
/// all three are the reason for it:
///
/// - **turning the turntable is free.** The angle is measured in the cake's
///   frame, so spinning the plate moves nothing and re-derives nothing.
/// - **the party and the wall can re-render the same cake later from the spec
///   alone**, at their own scale and their own angle. A world-space position
///   would tie a permanent trophy to one camera and one turntable angle.
/// - **`isTall` cannot stretch a heart.** `u` is a fraction of its tier, so a
///   sticker on a 1.5× cake sits at the same *place on its tier* rather than
///   floating above it.
struct StickerAnchor: Codable, Equatable {

    enum Face: String, Codable {
        /// The wall of a tier.
        case zijkant
        /// The exposed top ring of a tier, or the top of the cake.
        case boven
    }

    var tier: Int
    var face: Face
    /// Radians about the cake's axis, in the cake's own frame, wrapped to
    /// `[-π, π)`. The turntable's angle is deliberately not in here.
    var theta: Float
    /// `zijkant`: fraction of the way up this tier's wall.
    /// `boven`: fraction of this tier's radius out from the axis.
    /// Both `0…1`.
    var u: Float
}

/// One placed decoration.
struct Sticker: Codable, Equatable, Identifiable {
    var id = UUID()
    var kind: StickerKind
    var at: StickerAnchor
    /// About the surface normal, so twelve sprinkles are not twelve identical
    /// sprinkles.
    var spin: Float = 0
    /// **Candles only.** Optional so this struct can grow the same way again —
    /// and `nil` for everything else says "not a candle" rather than
    /// "an unlit candle".
    var lit: Bool?
}

/// A line of cream from the piping bag.
///
/// The points are the same anchors a sticker uses, so **one function renders
/// both** — which is what makes a stroke re-drawable by the party and the wall
/// at their own scale, exactly like a sticker.
struct Stroke: Codable, Equatable, Identifiable {
    var id = UUID()
    var path: [StickerAnchor]
    var width: Float = 0.0035
}
