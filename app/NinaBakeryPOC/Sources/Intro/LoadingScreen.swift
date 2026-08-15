import SwiftUI

/// The first thing on screen: the title plate, held over the room while the
/// room is being built behind it.
///
/// It exists for two reasons, and only the second one is about waiting:
///
/// - **The game needs a face.** Until now the app opened on the film, and if
///   `intro-*.mp4` were ever removed it opened on a half-lit kitchen. The plate
///   is where *Nina's Toverbakkerij* is actually written down.
/// - **Building the kitchen takes a moment.** `KitchenRoom.build` makes every
///   mesh from scratch and `LightingRig.loadOptionalAssets` may go to disk.
///   That work happens under this screen instead of in front of her.
///
/// It carries **the only text in the game** — the title, which is the game's
/// own name and not something she is asked to read. `CONCEPT.md` §5 rules out
/// text she needs; a name on a cover is not that. Everything else here is
/// spoken or shown.
///
/// The plate is a generated image that ships as-is, which `CLAUDE.md` allows
/// for assets with no second form: the opening film, the app icon, and now
/// this. See `references/loading-screen/README.md` for the job ID and prompt.
///
/// The asset is padded to 16:9 so that filling the screen crops the **sides**
/// and never the top — the title sits 3.5% down from the top edge, and every
/// iPad is narrower than 16:9. That padding is the whole reason the title is
/// safe on an iPad mini; see `references/loading-screen/pad-to-16x9.py`.
@MainActor
struct LoadingScreen: View {

    /// Set once the room is built, lit, and ready to be uncovered.
    var ready: Bool

    /// Called when the screen has done its job. Exactly once.
    var onFinish: @MainActor () -> Void

    /// **A floor, not a delay.** Building the kitchen on an iPad is quick, and
    /// without a floor the title would flash past in three frames, which reads
    /// as a glitch rather than as an opening. It is short enough that a grown-up
    /// re-launching for the fourth time does not sigh — and a tap cuts it short.
    private static let floor: Double = 1.4

    /// **The plate lifts after this whether the room is ready or not.**
    /// `ready` is set at the end of an `async` closure that touches the disk,
    /// and "she cannot lose" has to cover the case where that closure never
    /// comes back — a 4-year-old handed a title screen that never opens has no
    /// move left. An unlit kitchen she can still poke is a better failure than
    /// a picture she is stuck behind.
    private static let patience: Double = 6

    @State private var scale: CGFloat = 1
    @State private var floorPassed = false
    @State private var finished = false
    @State private var sparkles: [Sparkle] = []

    var body: some View {
        ZStack {
            // Behind the plate, and the same colour as the launch screen, so
            // the hand-off from the static launch image is one continuous field
            // of mint rather than a flash.
            Color("LaunchBackground")

            Image("LoadingScreen")
                .resizable()
                .scaledToFill()
                .scaleEffect(scale)

            ForEach(sparkles) { sparkle in
                SparkleBurst(colour: sparkle.colour)
                    .position(sparkle.at)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .gesture(
            // `DragGesture(minimumDistance: 0)` rather than `onTapGesture`,
            // because only this one reports *where* she touched.
            DragGesture(minimumDistance: 0)
                .onEnded { value in touched(at: value.location) }
        )
        .onAppear {
            // A slow breath. The plate is a still image, and a still image with
            // nothing moving on it looks like an app that has hung.
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                scale = 1.03
            }
            // `Task { @MainActor in }` rather than `.task { }`: the latter takes
            // a `@Sendable` closure, which would not inherit this view's
            // isolation. Same reasoning as `IntroMovie`.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(Self.floor * 1_000_000_000))
                floorPassed = true
                finishIfReady()
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(Self.patience * 1_000_000_000))
                finish()
            }
        }
        .onChange(of: ready) { _, _ in finishIfReady() }
    }

    /// Every tap does something — `CLAUDE.md` is explicit, and a screen that
    /// eats a tap silently is the one place she decides the iPad is broken. A
    /// sparkle under her finger; and if the room is already waiting behind the
    /// plate, her tap is also what lets it through.
    private func touched(at point: CGPoint) {
        let sparkle = Sparkle(at: point)
        sparkles.append(sparkle)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 550_000_000)
            sparkles.removeAll { $0.id == sparkle.id }
        }
        if ready { finish() }
    }

    private func finishIfReady() {
        guard ready, floorPassed else { return }
        finish()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinish()
    }

    private struct Sparkle: Identifiable {
        let id = UUID()
        let at: CGPoint
        let colour: Color = [Color(Palette.blushPinkDeep),
                             Color(Palette.creamLight),
                             Color(Palette.butterYellow)].randomElement()!
    }
}

/// One sparkle, animating itself.
///
/// Self-animating on `onAppear` rather than driven from the parent's array: a
/// value inserted and animated in the same update can be laid out already
/// finished, and then nothing is seen at all.
private struct SparkleBurst: View {
    let colour: Color

    @State private var grown = false

    var body: some View {
        SparkleMark()
            .fill(colour)
            .frame(width: 64, height: 64)
            .scaleEffect(grown ? 1.7 : 0.2)
            .opacity(grown ? 0 : 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { grown = true }
            }
    }
}

/// A four-pointed sparkle with straight edges — the same vocabulary as
/// `Engine/Sparkles.swift` in the room, and faceted for the same reason: a soft
/// round glow belongs to a different art direction.
struct SparkleMark: Shape {
    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let waist = r * 0.26                    // how pinched the arms are
        var path = Path()
        path.move(to: CGPoint(x: centre.x, y: centre.y - r))
        path.addLine(to: CGPoint(x: centre.x + waist, y: centre.y - waist))
        path.addLine(to: CGPoint(x: centre.x + r, y: centre.y))
        path.addLine(to: CGPoint(x: centre.x + waist, y: centre.y + waist))
        path.addLine(to: CGPoint(x: centre.x, y: centre.y + r))
        path.addLine(to: CGPoint(x: centre.x - waist, y: centre.y + waist))
        path.addLine(to: CGPoint(x: centre.x - r, y: centre.y))
        path.addLine(to: CGPoint(x: centre.x - waist, y: centre.y - waist))
        path.closeSubpath()
        return path
    }
}
