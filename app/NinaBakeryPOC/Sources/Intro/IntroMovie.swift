import SwiftUI
import AVFoundation
import Combine

/// The opening film: outside the bakery, then inside the kitchen, and then the
/// game.
///
/// It is **one shot per file**, played back to back by an `AVQueuePlayer`.
/// Cutting between shots is a thing a video model does badly and a queue does
/// for free, so each shot is generated on its own and named `intro-1.mp4`,
/// `intro-2.mp4`, … Adding a third shot is dropping in `intro-3.mp4`; the queue
/// picks it up by name and nothing here changes.
///
/// Three rules shape it, all from `CONCEPT.md` §5:
///
/// - **It is skippable two ways.** A visible button, and a tap anywhere else on
///   the screen. A film a 4-year-old cannot get out of is a film she will learn
///   to dread, and the fourth launch of the day should not cost her fourteen
///   seconds. The button exists because tap-anywhere is invisible: a grown-up
///   handed the iPad has no way to guess it, and neither does she.
/// - **The button carries no text**, because she cannot read one. It is the
///   skip-to-end glyph everybody already knows from a music player, big enough
///   to hit and dim enough not to compete with the film.
/// - **No player chrome otherwise.** `VideoPlayer` from AVKit puts a scrubber on
///   screen the moment it is touched, so this drives an `AVPlayerLayer`
///   directly. The skip button is the only thing on top of the picture.
/// - **Nina speaks over it**, in her own voice, rather than whatever the video
///   model would have invented. The film itself is silent.
///
/// If no `intro-*.mp4` is bundled the whole thing is skipped and the game starts
/// as it always did — the movie is a nicety, not a dependency.
@MainActor
struct IntroMovie: View {

    /// Called when the film ends, or when she taps to skip it. The flag says
    /// which — the caller cuts the narration short only on a tap.
    var onFinish: @MainActor (_ skipped: Bool) -> Void

    /// Called with the index of each shot as it ends, so the voice-over can be
    /// hung off the cut rather than off a stopwatch. Re-cutting a shot to a
    /// different length then keeps the lines in the right places by itself.
    var onShotFinished: (@MainActor (Int) -> Void)?

    @State private var items: [AVPlayerItem] = []
    @State private var player: AVQueuePlayer?
    /// The end of *this* item is the end of the film. Every other item's end
    /// notification is just the cut to the next shot.
    @State private var lastItem: AVPlayerItem?
    @State private var finished = false
    /// The skip button fades in a beat late, so the first second of the film is
    /// the film. After that it stays put — it never fades out again, because a
    /// control that comes and goes is one she cannot rely on.
    @State private var showSkip = false

    /// Every shot, in order. `nonisolated` because it only asks the bundle a
    /// question, and it is read while a `@State` default is being set up.
    ///
    /// Sorted by filename, so the numbering is the running order. Past nine
    /// shots that would need zero-padding, which is a problem an opening film
    /// for a 4-year-old will never have.
    nonisolated static var urls: [URL] {
        let inFolder = Bundle.main.urls(forResourcesWithExtension: "mp4",
                                        subdirectory: "Movies") ?? []
        let inRoot = Bundle.main.urls(forResourcesWithExtension: "mp4",
                                      subdirectory: nil) ?? []
        var seen: Set<String> = []
        return (inFolder + inRoot)
            .filter { $0.lastPathComponent.hasPrefix("intro") }
            .filter { seen.insert($0.lastPathComponent).inserted }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    nonisolated static var isAvailable: Bool { !urls.isEmpty }

    var body: some View {
        ZStack {
            // Black behind, so the film's letterbox on a 4:3 iPad reads as
            // deliberate rather than as the room showing through.
            Color.black
            if let player {
                MoviePlayerView(player: player)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { finish(skipped: true) }
        .overlay(alignment: .bottomTrailing) { skipButton }
        .onAppear {
            start()
            // `Task { @MainActor in }` rather than `.task { }`: the latter takes
            // a `@Sendable` closure, which does not inherit the view's
            // main-actor isolation, and everything in here is main-actor work.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                withAnimation(.easeOut(duration: 0.45)) { showSkip = true }
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: AVPlayerItem.didPlayToEndTimeNotification)) { note in
            // Fires at the end of every shot; only the last one ends the film.
            guard let item = note.object as? AVPlayerItem else { return }
            if let index = items.firstIndex(where: { $0 === item }) {
                onShotFinished?(index)
            }
            guard item === lastItem else { return }
            finish(skipped: false)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    /// Skip. Bottom-right, deliberately away from the top-right corner, which
    /// is where the developer panel's hidden triple-tap lives.
    ///
    /// 72 pt across: the age rules ask for ~120 pt game targets, and this is
    /// not a game target — it is a control a grown-up reaches for and she can
    /// hit by accident with no harm done, since skipping costs her nothing.
    private var skipButton: some View {
        Button {
            finish(skipped: true)
        } label: {
            Image(systemName: "forward.end.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(.black.opacity(0.35), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 2))
                // The film is pastel and bright; a shadow is what keeps the
                // glyph readable over a cream wall.
                .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .padding(32)
        .opacity(showSkip ? 1 : 0)
        // Spoken, not written: the only place a word is allowed is somewhere
        // she will never see it.
        .accessibilityLabel("Overslaan")
    }

    private func start() {
        let urls = Self.urls
        guard !urls.isEmpty else {
            finish(skipped: false)
            return
        }
        let items = urls.map { AVPlayerItem(url: $0) }
        // A queue rather than one player per shot: it preloads the next item,
        // so the cut between outside and inside lands tight instead of on a
        // black frame while the second file opens.
        let player = AVQueuePlayer(items: items)
        // Silent by construction — the shots were generated without an audio
        // track. Muted anyway, so a model that ignored that flag one day cannot
        // talk over Nina in a language she does not speak.
        player.isMuted = true
        self.items = items
        lastItem = items.last
        self.player = player
        player.play()
    }

    private func finish(skipped: Bool) {
        guard !finished else { return }
        finished = true
        player?.pause()
        onFinish(skipped)
    }
}

/// `AVPlayerLayer` in a SwiftUI view, on both platforms.
///
/// The two halves are the same picture with different spelling; the iOS one
/// gets the layer for free through `layerClass`, and the Mac one has to host it.
@MainActor
struct MoviePlayerView {
    let player: AVPlayer
}

#if os(macOS)
extension MoviePlayerView: NSViewRepresentable {
    func makeNSView(context: Context) -> MoviePlayerHostView {
        MoviePlayerHostView(player: player)
    }
    func updateNSView(_ view: MoviePlayerHostView, context: Context) {}
}

final class MoviePlayerHostView: NSView {
    private let playerLayer = AVPlayerLayer()

    init(player: AVPlayer) {
        super.init(frame: .zero)
        wantsLayer = true
        layer = CALayer()
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}
#else
extension MoviePlayerView: UIViewRepresentable {
    func makeUIView(context: Context) -> MoviePlayerHostView {
        MoviePlayerHostView(player: player)
    }
    func updateUIView(_ view: MoviePlayerHostView, context: Context) {}
}

final class MoviePlayerHostView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        // Aspect fit, not fill: the film is 16:9 and the iPad is not, and
        // cropping the cottage out of its own establishing shot would be a
        // strange way to open.
        playerLayer.videoGravity = .resizeAspect
        backgroundColor = .black
    }

    required init?(coder: NSCoder) { fatalError("not used") }
}
#endif
