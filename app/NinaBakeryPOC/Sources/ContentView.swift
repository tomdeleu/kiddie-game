import SwiftUI
import RealityKit

/// `@MainActor` on the whole view, not just `body`: the gesture closures and
/// the helpers below all reach into `Ticker`, `TouchRouter` and `SoundKit`,
/// which are main-actor isolated. Annotating the type is what lets those
/// closures inherit that isolation instead of each one needing a hop.
@MainActor
struct ContentView: View {
    @StateObject private var settings = LightingSettings()
    @StateObject private var scene = GameScene()
    @Environment(\.scenePhase) private var scenePhase

    /// Off by default and hard to reach on purpose. Nothing in the panel is
    /// for Nina, and a visible gear is a thing she will press.
    @State private var showDeveloperPanel = false
    @State private var dragging = false

    /// The opening film, if one is bundled. It runs over the room, which is
    /// already built and lit behind it — so when she skips two seconds in, the
    /// kitchen is simply there rather than loading.
    @State private var showIntro = IntroMovie.isAvailable

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                backdrop
                roomView
                restartButton
                developerLayer
                if showIntro {
                    IntroMovie(onFinish: finishIntro, onShotFinished: introShotFinished)
                        .transition(.opacity)
                }
            }
            .coordinateSpace(.named("room"))
            .onAppear {
                scene.cameraRig.setViewport(geometry.size)
                keepTheScreenAwake()
            }
            .onChange(of: geometry.size) { _, size in
                scene.cameraRig.setViewport(size)
            }
        }
        .ignoresSafeArea()
        .onChange(of: scenePhase) { _, phase in
            // The round survives the iPad being taken away mid-stir.
            if phase != .active { scene.kitchen?.save() }
        }
    }

    private var backdrop: some View {
        // Matches the plates' studio grey. Toggleable, because a backdrop that
        // flatters the room is exactly the kind of thing that hides a problem.
        Group {
            if settings.showBackdrop {
                Color(Palette.backdropGrey)
            } else {
                Color.black
            }
        }
    }

    private var roomView: some View {
        RealityView { content in
            content.add(scene.root)
            scene.start(settings: settings, greeting: !showIntro)
            await scene.rig.loadOptionalAssets()
            scene.rig.apply(settings, to: scene.sceneRoot)
            if showIntro { scene.sayIntroLines() }
        } update: { _ in
            scene.update(settings: settings)
        }
        .gesture(finger)
    }

    /// The cut inside is where Nina names the kitchen. Hung off the cut rather
    /// than off a timer, so re-cutting a shot cannot leave her talking about
    /// the wrong picture.
    private func introShotFinished(_ index: Int) {
        guard index == 0 else { return }
        scene.voice?.say(Line.introKeuken)
    }

    /// The film ended, or she tapped through it. Nina greets her either way —
    /// skipping the film must not cost her the hello.
    ///
    /// The two cases differ in one thing, and it matters: **a tap cuts Nina
    /// off, the end of the film does not.** She skipped because she wants to
    /// bake, so holding her at the door for the rest of a sentence would be
    /// exactly backwards; but letting the last line finish over the first
    /// second of the kitchen is how a film ends, not a bug.
    private func finishIntro(skipped: Bool) {
        guard showIntro else { return }
        if skipped { scene.voice?.stop() }
        withAnimation(.easeInOut(duration: 0.45)) { showIntro = false }
        scene.greetWhenQuiet()
    }

    /// One finger, one gesture. A press that barely moves is a tap; anything
    /// else is a drag. There is no third verb anywhere in the game.
    private var finger: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("room"))
            .onChanged { value in
                if !dragging {
                    dragging = true
                    scene.touch.began(at: value.startLocation)
                }
                scene.touch.moved(to: value.location)
            }
            .onEnded { value in
                dragging = false
                scene.touch.ended(at: value.location)
            }
    }

    /// Start this cake again.
    ///
    /// Bottom-left, out of the way of both the skip button (bottom-right) and
    /// the developer corner (top-right). No text on it — the going-round arrow
    /// everyone knows, the same size and weight as the skip button so the two
    /// read as the same kind of thing.
    ///
    /// **She can press it, and that is fine.** `GAMEPLAY.md` §7 says she cannot
    /// lose: restarting keeps every cake already on the plank and costs her
    /// only the one she is holding, and Nina says out loud what just happened
    /// so it is never a mystery. If she turns out to press it constantly, the
    /// fix is to move it behind the parent gate, not to add a confirmation —
    /// a "are you sure?" is unreadable to her by definition.
    private var restartButton: some View {
        VStack {
            Spacer()
            HStack {
                Button {
                    scene.kitchen?.restartRound()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(.black.opacity(0.28), in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2))
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
                .padding(32)
                .accessibilityLabel("Opnieuw beginnen")
                Spacer()
            }
        }
    }

    // MARK: - Developer access

    private var developerLayer: some View {
        ZStack(alignment: .topTrailing) {
            if showDeveloperPanel {
                VStack(alignment: .trailing, spacing: 8) {
                    KitchenDebugStrip(scene: scene, settings: settings) {
                        showDeveloperPanel = false
                    }
                    DebugPanel(settings: settings,
                               iblAvailable: scene.rig.iblAvailable,
                               lightmapsAvailable: scene.rig.lightmapsAvailable)
                }
            } else {
                developerHotspot
            }
        }
    }

    /// Three taps in the top-right corner. `CONCEPT.md` §5 asks for a parent
    /// gate she will not find; this is that, and it costs no on-screen pixels.
    private var developerHotspot: some View {
        Color.black.opacity(0.001)
            .frame(width: 64, height: 64)
            .contentShape(Rectangle())
            .onTapGesture(count: 3) { showDeveloperPanel = true }
    }

    private func keepTheScreenAwake() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif
    }
}

/// Everything the scene owns, kept out of the view so a slider drag does not
/// rebuild the room.
@MainActor
final class GameScene: ObservableObject {

    let root = Entity()
    let sceneRoot = Entity()
    let cameraRig = CameraRig()
    let ticker = Ticker()
    let rig = LightingRig()
    let sound = SoundKit()

    private(set) var touch: TouchRouter!
    private(set) var voice: VoiceBank!
    private(set) var kitchen: KitchenRoom?

    private var builtFlat: Bool?
    private var started = false

    init() {
        root.addChild(sceneRoot)
        rig.install(in: root)
        root.addChild(cameraRig.camera)
        touch = TouchRouter(camera: cameraRig)
        voice = VoiceBank(ticker: ticker)
    }

    /// `greeting` is false when the opening film is about to cover the room:
    /// Nina talks over the film instead, and greets her when it ends.
    func start(settings: LightingSettings, greeting: Bool = true) {
        guard !started else { return }
        started = true

        sound.prepare()
        voice.load()
        ticker.start()

        let room = KitchenRoom(ticker: ticker, touch: touch, voice: voice,
                               sound: sound, settings: settings)
        kitchen = room
        sceneRoot.addChild(room.root)
        room.build(flat: settings.flatShading)
        builtFlat = settings.flatShading

        // A beat before she is greeted, so the room is on screen first.
        if greeting {
            ticker.after(0.9) { [weak room] in room?.greet() }
        }
    }

    /// Nina's narration over the opening film's first shot. The second shot's
    /// line is fired by the cut — see `ContentView.introShotFinished`.
    func sayIntroLines() {
        ticker.after(0.4) { [weak self] in
            self?.voice.say(Line.introBuiten)
        }
    }

    /// Greet her once Nina has finished the film's narration, rather than a
    /// fixed beat later. The lines are written to fit the shots, but a re-cut
    /// line should not end up talking over its own greeting.
    func greetWhenQuiet(after delay: Float = 0.35, timeout: Float = 6) {
        var waited: Float = 0
        ticker.add { [weak self] dt in
            guard let self else { return false }
            waited += dt
            guard waited > delay else { return true }
            guard !self.voice.isSpeaking || waited > timeout else { return true }
            self.kitchen?.greet()
            return false
        }
    }

    /// Called on every SwiftUI update. Only the flat/smooth toggle rebuilds
    /// anything; the rest is lights and shadows, which are cheap.
    func update(settings: LightingSettings) {
        if let builtFlat, builtFlat != settings.flatShading {
            kitchen?.build(flat: settings.flatShading)
            self.builtFlat = settings.flatShading
        }
        rig.apply(settings, to: sceneRoot)
        kitchen?.refreshContactShadows(settings: settings)
    }
}

/// The game half of the debug overlay. The lighting half is `DebugPanel`,
/// unchanged from the POC.
@MainActor
struct KitchenDebugStrip: View {
    @ObservedObject var scene: GameScene
    @ObservedObject var settings: LightingSettings
    var onClose: () -> Void

    @State private var muted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("KITCHEN")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Hide") { onClose() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            if let kitchen = scene.kitchen {
                Text("Step: \(kitchen.state.step.rawValue)")
                Text("Bowl: \(kitchen.state.inBowl.map(\.rawValue).joined(separator: ", "))")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Stir: \(Int(kitchen.state.stir * 100))%  ·  Shelf: \(kitchen.state.shelf.count)")
                    .foregroundStyle(.secondary)
            }

            // Which line just played. During a session with Nina this is the
            // difference between "she ignored it" and "she never heard it".
            Text(scene.voice?.lastSpoken ?? "")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("New round") { scene.kitchen?.resetRound() }
                Toggle("Mute", isOn: $muted)
                    .onChange(of: muted) { _, value in scene.sound.enabled = !value }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
        .frame(width: 290, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}
