import SwiftUI

/// **The button.** Every control Nina ever touches outside the room is one of
/// these, and it is the same object every time: an octagonal cap with a
/// chamfered rim, a flat pastel face, and one big white glyph.
///
/// The design is `references/buttons/G-faceon-mint.png`, which that folder's
/// README argues for over eight other candidates. Three things it settles:
///
/// - **Face-on, not three-quarter.** The room is drawn at a fixed isometric
///   angle; the overlay is not part of the room and pretending otherwise makes
///   a control that looks like a prop she can pick up. Straight on also means
///   the shape is eight straight lines, which is a thing SwiftUI can draw
///   exactly rather than approximate.
/// - **An octagon, not a circle.** `references/REFERENCES.md` bans smooth
///   curved surfaces, and a circle is the one shape that cannot be built from
///   flat facets. Eight sides reads as round at 72 pt and is still visibly
///   faceted.
/// - **The rim does the shading.** Eight chamfer facets, each taking its tone
///   from its own angle to one key light — the same trick the room uses, done
///   in 2D because the overlay has no renderer to do it. No gradients: a
///   gradient is a smooth curved surface with extra steps.
///
/// Nothing in here is ever disabled. She cannot lose and nothing is locked, so
/// a greyed-out control is a state the game does not have.
@MainActor
struct FacetButton<Label: View>: View {

    /// Spoken, never written — she cannot read. It reaches VoiceOver and
    /// nothing else, which is the only place a word on a button is allowed.
    var accessibilityLabel: String
    var tone: FacetTone = .sage
    var diameter: CGFloat = FacetSize.game
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
        }
        .buttonStyle(FacetButtonStyle(tone: tone, diameter: diameter))
        .accessibilityLabel(accessibilityLabel)
    }
}

/// The two sizes anything in this game is ever built at.
enum FacetSize {
    /// A target in the room: the age rules ask for ~120 pt.
    static let game: CGFloat = 120
    /// A control at the edge of the screen that a grown-up reaches for and she
    /// may hit by accident with no harm done. Skip is the one that exists.
    static let chrome: CGFloat = 72
}

extension FacetButton where Label == FacetGlyph {
    /// The common case: an SF Symbol, sized and coloured to the plate.
    init(symbol: String,
         accessibilityLabel: String,
         tone: FacetTone = .sage,
         diameter: CGFloat = FacetSize.game,
         action: @escaping () -> Void) {
        self.init(accessibilityLabel: accessibilityLabel,
                  tone: tone,
                  diameter: diameter,
                  action: action) {
            FacetGlyph(symbol: symbol, diameter: diameter)
        }
    }
}

/// A white SF Symbol at the plate's proportion. Plate G's glyph spans 46% of
/// the button's width, which is far bigger than a normal piece of iOS chrome
/// and is the right answer here: huge targets, one meaning per button, read
/// from across the room.
///
/// Solid white on every tone. The faces are pastels, and a pastel glyph on a
/// pastel face is the one way this stops reading at arm's length.
struct FacetGlyph: View {
    let symbol: String
    var diameter: CGFloat = FacetSize.game

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: diameter * 0.42, weight: .semibold))
            .foregroundStyle(.white)
    }
}

// MARK: - Tones

/// A button's colours. One value picks all three.
///
/// **The face is always a deep member of the palette**, and that is the one
/// place this departs from a literal reading of plate G. The plate's prompt
/// asked for a mint face; what came back measures `#ABB9AE`, because a lit
/// facet in a render is not its base colour. Translating the *name* rather than
/// the *pixels* would have put base mint behind the glyph, and white on base
/// mint is a contrast ratio of 1.43 — a glyph a 4-year-old has to hunt for.
/// The four faces here run 1.80 to 2.46 against white, and `REFERENCES.md` §4
/// says it outright: sample a mid-tone facet, never the brightest one.
///
/// The cream rim never changes. One cream chamfer on every button in the game
/// is what will make twelve different controls read as one family.
///
/// The outer edge is derived — the face taken to 80% — rather than picked, so
/// a new tone is one colour and cannot drift out of family. It is deeper than
/// plate G's outline on purpose: the plate is photographed on studio grey, and
/// this has to hold its silhouette over a bright pastel film.
struct FacetTone {
    var face: UIColorLike
    var rim: UIColorLike = Palette.creamLight

    var edge: UIColorLike { Palette.shade(face, 0.80) }

    /// Green. The default, and what the skip button wears.
    static let sage  = FacetTone(face: Palette.sage)
    /// Pink.
    static let rose  = FacetTone(face: Palette.rose)
    /// Warm — the wood end of the palette, for anything to do with the bakery
    /// itself.
    static let sandy = FacetTone(face: Palette.sandyWood)
    /// Blue. The one tone from outside the locked thirteen, for the same
    /// reason the berry is — see `Palette.berryBlue`.
    static let berry = FacetTone(face: Palette.berryBlueDeep)
}

// MARK: - The style

/// Draws the plate and puts the label on it.
///
/// Available on its own so anything that is already a `Button` can adopt the
/// look without being rewritten as a `FacetButton`.
struct FacetButtonStyle: ButtonStyle {
    var tone: FacetTone = .sage
    var diameter: CGFloat = 120

    func makeBody(configuration: Configuration) -> some View {
        FacetPlate(tone: tone, pressed: configuration.isPressed)
            .frame(width: diameter, height: diameter)
            .overlay { configuration.label }
            // The one shadow the style allows: a contact shadow, grounding the
            // button the way every prop in the room is grounded. It is also
            // what keeps a pastel cap legible over a pastel film.
            .shadow(color: .black.opacity(configuration.isPressed ? 0.18 : 0.28),
                    radius: configuration.isPressed ? 4 : 10,
                    y: configuration.isPressed ? 2 : 5)
            // It sinks into its socket, the way the pressed candidate
            // (`references/buttons/E-press-state.png`) does it. Small on
            // purpose: the target must not move out from under a 4-year-old's
            // finger mid-press.
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

// MARK: - The plate

/// The octagon itself: outer edge, eight chamfer facets, flat face.
///
/// A `Canvas` rather than stacked `Shape`s. Nine filled polygons is nine draw
/// calls either way, and the geometry is shared — every ring is the same eight
/// vertices scaled toward the centre, which is what makes the chamfer facets
/// come out as clean trapezoids with parallel edges.
private struct FacetPlate: View {
    let tone: FacetTone
    let pressed: Bool

    /// Where the key light is, in view coordinates (y down), pointing at it:
    /// 45° up and to the left. Not a guess — plate G's top and left chamfer
    /// facets come back at the same brightness as each other, and its bottom
    /// and right ones do too, which is what a light on the diagonal does and
    /// nothing else does.
    private static let light = CGVector(dx: -0.7071, dy: -0.7071)

    /// How far the chamfer tones spread either side of the base colour, also
    /// measured off plate G: its brightest facet is 1.11× the base cream and
    /// its darkest 0.86×.
    private static let spread: Double = 0.13

    /// Where the rings sit, as a fraction of the width. Both measured across
    /// plate G at mid-height: the deep outline eats 2.7% of the width per side
    /// and the chamfer band another 7%.
    private static let rimScale: CGFloat = 0.945
    private static let faceScale: CGFloat = 0.805

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let outer = Octagon.vertices(in: rect)
            let rim = Octagon.scaled(outer, by: Self.rimScale, in: rect)
            let face = Octagon.scaled(outer, by: Self.faceScale, in: rect)

            // 1. The deep outer edge, drawn full and covered by the rest, so
            //    what survives is an even outline all the way round.
            context.fill(Octagon.path(outer), with: .color(Color(tone.edge)))

            // 2. Eight chamfer facets. Each one faces outward along its own
            //    edge, so each one catches the light differently — that
            //    difference is the entire shading model.
            for i in 0..<8 {
                let quad = [rim[i], rim[(i + 1) % 8],
                            face[(i + 1) % 8], face[i]]
                context.fill(Octagon.path(quad),
                             with: .color(Color(Palette.shade(tone.rim,
                                                              facetShade(i, rim: rim,
                                                                         centre: rect.mid)))))
            }

            // 3. The face. One flat colour, no gradient, no vignette.
            context.fill(Octagon.path(face), with: .color(Color(faceColour)))
        }
    }

    /// The multiplier for facet `i`: brightest where it turns into the light,
    /// darkest where it turns away.
    ///
    /// Pressed, the cap is down in its socket and the chamfer is looking the
    /// other way, so the whole ring inverts and dims. That inversion is the
    /// press — it is what a sunk cap actually does, and it reads at a glance
    /// without the button having to move far.
    private func facetShade(_ i: Int, rim: [CGPoint], centre: CGPoint) -> Double {
        let a = rim[i], b = rim[(i + 1) % 8]
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        var n = CGVector(dx: mid.x - centre.x, dy: mid.y - centre.y)
        let length = max(0.0001, sqrt(n.dx * n.dx + n.dy * n.dy))
        n = CGVector(dx: n.dx / length, dy: n.dy / length)
        let facing = Double(n.dx * Self.light.dx + n.dy * Self.light.dy)
        let lit = 1 + Self.spread * facing
        return pressed ? (2 - lit) * 0.94 : lit
    }

    /// The face dims in shadow when the cap is down, and by more than the rim
    /// does — a recessed face catches less of the fill.
    private var faceColour: UIColorLike {
        pressed ? Palette.shade(tone.face, 0.90) : tone.face
    }
}

// MARK: - Geometry

/// The regular octagon, and the two things ever done to one.
enum Octagon {

    /// The corner cut that makes the eight sides equal: `(2 - √2) / 2` of the
    /// width. Any other value is a square with the corners knocked off.
    static let chamfer: CGFloat = (2 - 1.4142135623730951) / 2

    /// Eight vertices, clockwise from the left end of the top edge.
    static func vertices(in rect: CGRect) -> [CGPoint] {
        let c = min(rect.width, rect.height) * chamfer
        return [
            CGPoint(x: rect.minX + c, y: rect.minY),
            CGPoint(x: rect.maxX - c, y: rect.minY),
            CGPoint(x: rect.maxX,     y: rect.minY + c),
            CGPoint(x: rect.maxX,     y: rect.maxY - c),
            CGPoint(x: rect.maxX - c, y: rect.maxY),
            CGPoint(x: rect.minX + c, y: rect.maxY),
            CGPoint(x: rect.minX,     y: rect.maxY - c),
            CGPoint(x: rect.minX,     y: rect.minY + c),
        ]
    }

    /// A smaller, concentric copy. Scaling the vertices toward the centre keeps
    /// every edge parallel to the one it came from, which is why the ring
    /// between two of these is eight trapezoids and not eight guesses.
    static func scaled(_ points: [CGPoint], by k: CGFloat, in rect: CGRect) -> [CGPoint] {
        let c = rect.mid
        return points.map {
            CGPoint(x: c.x + ($0.x - c.x) * k, y: c.y + ($0.y - c.y) * k)
        }
    }

    static func path(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }
}

private extension CGRect {
    var mid: CGPoint { CGPoint(x: midX, y: midY) }
}

#Preview("The family") {
    HStack(spacing: 28) {
        FacetButton(symbol: "forward.end.fill",
                    accessibilityLabel: "Overslaan",
                    tone: .sage,
                    diameter: FacetSize.chrome) {}
        FacetButton(symbol: "arrow.left",
                    accessibilityLabel: "Terug",
                    tone: .rose) {}
        FacetButton(symbol: "house.fill",
                    accessibilityLabel: "Naar de bakkerij",
                    tone: .sandy) {}
        FacetButton(symbol: "music.note",
                    accessibilityLabel: "Muziek",
                    tone: .berry) {}
    }
    .padding(48)
    .background(Color(Palette.creamLight))
}
