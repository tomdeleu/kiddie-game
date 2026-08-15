import SwiftUI
import AVFoundation
import Combine

/// The opening film: a slow push-in on the bakery before the kitchen appears.
///
/// Three rules shape it, all from `CONCEPT.md` §5:
///
/// - **One tap skips it.** Anywhere on the screen. A film a 4-year-old cannot
///   get out of is a film she will learn to dread, and the second launch of the
///   day should not cost her eight seconds.
/// - **No player chrome.** `VideoPlayer` from AVKit puts a scrubber on screen
///   the moment it is touched, so this drives an `AVPlayerLayer` directly.
///   There is nothing to press, which is the point.
/// - **Luna speaks over it**, in her own voice, rather than whatever the video
///   model would have invented. The film itself is silent.
///
/// If `intro.mp4` is not bundled the whole thing is skipped and the game starts
/// as it always did — the movie is a nicety, not a dependency.
@MainActor
struct IntroMovie: View {

    /// Called when the film ends, or when she taps to skip it.
    var onFinish: @MainActor () -> Void

    @State private var player: AVPlayer?
    @State private var finished = false

    /// `nonisolated` because it only asks the bundle a question, and it is
    /// read while a `@State` default is being set up.
    nonisolated static var url: URL? {
        Bundle.main.url(forResource: "intro", withExtension: "mp4", subdirectory: "Movies")
            ?? Bundle.main.url(forResource: "intro", withExtension: "mp4")
    }

    nonisolated static var isAvailable: Bool { url != nil }

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
        .onTapGesture { finish() }
        .onAppear(perform: start)
        .onReceive(NotificationCenter.default.publisher(
            for: AVPlayerItem.didPlayToEndTimeNotification)) { _ in
            finish()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func start() {
        guard let url = Self.url else {
            finish()
            return
        }
        let player = AVPlayer(url: url)
        // Silent by construction — the film was generated without an audio
        // track. Muted anyway, so a model that ignored that flag one day cannot
        // talk over Luna in a language Nina does not speak.
        player.isMuted = true
        player.actionAtItemEnd = .pause
        self.player = player
        player.play()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        player?.pause()
        onFinish()
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
