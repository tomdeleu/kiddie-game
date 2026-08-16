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

    /// **Title plate, then film, then the game.** Each layer uncovers the next,
    /// and the room is built and lit under all of them — so whichever way she
    /// gets through, the kitchen is simply there rather than loading.
    ///
    /// The film is skipped entirely when no `intro-*.mp4` is bundled, which is
    /// the one thing that changes the order.
    private enum Opening { case loading, film, playing }
    @State private var opening: Opening = .loading

    /// **Whether the title plate is still up, kept separate from `opening`.**
    ///
    /// The two used to be the same thing, and that is what made the room flash
    /// between the plate and the film (owner, 2026-08-16). Swapping `.loading`
    /// for `.film` inside a `withAnimation` crossfades the plate *out* while the
    /// film fades *in*, and for that half second neither cover is opaque — so
    /// what she sees through the two of them is the lit kitchen, a third of a
    /// second before a film that is about walking into it. The player needing a
    /// moment to produce its first frame only widens the gap.
    ///
    /// With the plate on a flag of its own, the film can be inserted *underneath
    /// it* with no animation at all and the plate lifted separately, once the
    /// film reports it is actually playing. There is never a frame with a
    /// transparent cover on it.
    @State private var plateUp = true

    /// Set from the `RealityView` make closure, once the room exists and the
    /// lights are on it. This is what the loading screen waits for.
    @State private var sceneReady = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                backdrop
                roomView
                restartButton
                // **Order and transitions are both load-bearing here.** The
                // plate is last, so it is on top of the film; and each cover
                // appears with no animation and leaves with a fade, so there is
                // never a moment when the thing covering the room is
                // semi-transparent. A cover that fades *in* is a peep-hole.
                if opening == .film {
                    IntroMovie(onFinish: finishIntro,
                               onShotFinished: introShotFinished,
                               onStarted: filmStarted)
                        .transition(.asymmetric(insertion: .identity, removal: .opacity))
                }
                if plateUp {
                    LoadingScreen(ready: sceneReady, onFinish: finishLoading)
                        .transition(.asymmetric(insertion: .identity, removal: .opacity))
                }
                // **Last, so it is above the covers.** It used to sit under
                // them, which meant the one moment a grown-up most wants the
                // room picker — the app has just started and the film is
                // playing — was the one moment nothing could be tapped. A
                // developer control that is only reachable once the game has
                // already got where you were trying to skip to is not a
                // developer control.
                developerLayer
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
            if phase != .active { scene.room?.save() }
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
            // `greeting: false` unconditionally — nobody greets a covered
            // room. Whoever takes the last cover off is the one who starts
            // Nina talking: `finishLoading` when there is no film,
            // `finishIntro` when there is.
            scene.start(settings: settings, greeting: false)
            await scene.rig.loadOptionalAssets()
            scene.rig.apply(settings, to: scene.sceneRoot)
            sceneReady = true
        } update: { _ in
            scene.update(settings: settings)
        }
        .gesture(finger)
    }

    /// The title plate has done its waiting. Either the film follows, or the
    /// kitchen does — and the two are uncovered differently on purpose.
    ///
    /// **With a film, nothing fades yet.** The film is inserted underneath the
    /// plate with no animation, so the plate is still the only thing on screen;
    /// `filmStarted` lifts it once there is a first frame under it. Fading the
    /// plate out here instead is what let the room flash through between the two
    /// covers.
    ///
    /// **Without one, this is the reveal**, and the crossfade is the point: the
    /// plate is the only cover and the kitchen is what is behind it.
    private func finishLoading() {
        guard opening == .loading else { return }
        guard IntroMovie.isAvailable else {
            opening = .playing
            withAnimation(.easeInOut(duration: 0.5)) { plateUp = false }
            // The beat that `GameScene.start` used to schedule, now that the
            // room appears here rather than at launch.
            scene.greetWhenQuiet(after: 0.9)
            return
        }
        opening = .film
        // **And a way out if the first frame never comes.** `IntroMovie` calls
        // back off the player's own clock, which is the honest signal and also
        // one that a corrupt file or a decoder that gives up would never send.
        // "She cannot lose" has to cover a title plate too, so after three
        // seconds it lifts anyway — onto the film's own black, which is a worse
        // opening than the film and a far better one than a picture with no way
        // out of it.
        scene.ticker.after(3.0) { filmStarted() }
    }

    /// The film's first frame is on screen. Lift the plate off it, and start
    /// Nina — both from the picture rather than from a stopwatch, which is what
    /// gives shot 1's line its full 8 seconds instead of 7.5 of a moving target.
    private func filmStarted() {
        guard opening == .film, plateUp else { return }
        withAnimation(.easeInOut(duration: 0.45)) { plateUp = false }
        scene.sayIntroLines()
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
        guard opening == .film else { return }
        if skipped { scene.voice?.stop() }
        withAnimation(.easeInOut(duration: 0.45)) { opening = .playing }
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
    /// everyone knows, on the same `FacetButton` at the same 72 pt as skip, so
    /// the two read as the same kind of thing.
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
                FacetButton(symbol: "arrow.counterclockwise",
                            accessibilityLabel: "Opnieuw beginnen",
                            // Rose against skip's sage. Same object, same size,
                            // different colour: the family is what makes them
                            // read as the same kind of thing, and the colour is
                            // what lets her tell them apart across the screen
                            // without reading anything.
                            tone: .rose,
                            diameter: FacetSize.chrome) {
                    scene.room?.restartRound()
                }
                .padding(32)
                Spacer()
            }
        }
    }

    // MARK: - Developer access

    private var developerLayer: some View {
        ZStack(alignment: .topTrailing) {
            if showDeveloperPanel {
                VStack(alignment: .trailing, spacing: 8) {
                    RoomDebugStrip(scene: scene, settings: settings) {
                        showDeveloperPanel = false
                    }
                    DebugPanel(settings: settings,
                               iblAvailable: scene.rig.iblAvailable,
                               lightmapsAvailable: scene.rig.lightmapsAvailable)
                }
            } else {
                developerButton
            }
        }
    }

    /// The way in to the developer panel: a small wrench in the top-right.
    ///
    /// **This replaces the triple-tap, on the owner's call, 2026-08-16.** The
    /// invisible corner satisfied `CONCEPT.md` §5's parent gate at no cost in
    /// pixels, and the cost it did carry was worse: an invisible control that
    /// silently does nothing is indistinguishable from a broken one, and it was
    /// in fact broken — it sat under the film and the loading plate. A control
    /// you cannot see is a control you cannot debug.
    ///
    /// So it is visible, and it is deliberately dull about it: 28 pt of grey
    /// glyph at half opacity, against 72 pt of saturated `FacetButton` for the
    /// two controls that are hers. Everything the game wants her to press is
    /// big, coloured and faceted; this is small, grey and flat, in the one
    /// corner neither of hers uses. **It is still the most pressable thing on
    /// the screen that is not meant for her** — if she finds it and starts
    /// teleporting between rooms, the fix is to put it back behind a gesture
    /// she cannot make, not to shrink it further.
    ///
    /// The triple-tap stays alongside it, because a gate that costs nothing to
    /// keep is worth keeping: if this button ever does go away again, the
    /// corner still opens.
    private var developerButton: some View {
        Button {
            showDeveloperPanel = true
        } label: {
            Image(systemName: "wrench.adjustable")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                // The 44 pt frame is the tap target; the 28 pt circle is all
                // that shows. A grown-up thumb gets the whole of Apple's
                // minimum, and the screen only pays for a third of it.
                .frame(width: 28, height: 28)
                .background(.ultraThinMaterial, in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(0.5)
        .padding(.top, 8)
        .padding(.trailing, 8)
        .accessibilityLabel("Developer panel")
        // The old gate, kept. `count: 3` on the same view a single tap already
        // opens is harmless — the first tap has opened the panel and swapped
        // this view out long before a third could land.
        .simultaneousGesture(TapGesture(count: 3).onEnded { showDeveloperPanel = true })
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

    /// **The room she is in**, rather than *the kitchen*. There are two now.
    @Published private(set) var roomID: RoomID = .keuken
    private(set) var room: GameRoom?

    private var builtFlat: Bool?
    private var started = false

    init() {
        root.addChild(sceneRoot)
        rig.install(in: root)
        root.addChild(cameraRig.camera)
        touch = TouchRouter(camera: cameraRig)
        voice = VoiceBank(ticker: ticker)
    }

    /// `greeting` is false whenever anything is about to cover the room — which
    /// since the title plate landed is *always*, because the room is now built
    /// underneath at least one cover. `ContentView` has Nina greet her as the
    /// last one lifts. The parameter stays because "build the room and say
    /// hello" is still what this method means when nothing is in the way.
    func start(settings: LightingSettings, greeting: Bool = true) {
        guard !started else { return }
        started = true

        sound.prepare()
        voice.load()
        ticker.start()

        self.settings = settings
        let built = install(roomID, settings: settings)
        builtFlat = settings.flatShading

        // A beat before she is greeted, so the room is on screen first.
        if greeting {
            ticker.after(0.9) { [weak built] in built?.greet() }
        }
    }

    /// **Go to another room.**
    ///
    /// One entry point, so the order can only be got right: save what she was
    /// doing, take the old room down — every `Ticker` job, every touch target,
    /// the entity tree — stop anyone mid-sentence, then build the new one and
    /// greet her in it.
    ///
    /// Stopping the voice is not tidiness. Nina saying "put the tin in Otto"
    /// over a garden is worse than silence, and `VoiceBank` holds at most one
    /// pending line which would otherwise arrive after the room had changed
    /// underneath it.
    func go(to id: RoomID) {
        guard started, id != roomID, let settings else { return }
        voice.stop()
        room?.teardown()
        room = nil
        roomID = id
        let built = install(id, settings: settings)
        builtFlat = settings.flatShading
        ticker.after(0.5) { [weak built] in built?.greet() }
    }

    @discardableResult
    private func install(_ id: RoomID, settings: LightingSettings) -> GameRoom {
        let built: GameRoom
        switch id {
        case .keuken:
            built = KitchenRoom(ticker: ticker, touch: touch, voice: voice,
                                sound: sound, settings: settings)
        case .tuin:
            built = GardenRoom(ticker: ticker, touch: touch, voice: voice,
                               sound: sound, settings: settings)
        }
        room = built
        sceneRoot.addChild(built.root)
        built.build(flat: settings.flatShading)
        // The lights belong to the scene, not to the room, but a room that has
        // just been built has never been through `apply` — without this its
        // props keep the default material response until the next SwiftUI
        // update, which on a still screen may be a while.
        rig.apply(settings, to: sceneRoot)
        return built
    }

    /// Held so `go(to:)` can build a room without being handed them again. It
    /// is the same object `ContentView` owns — `LightingSettings` is a class.
    private var settings: LightingSettings?

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
            self.room?.greet()
            return false
        }
    }

    /// Called on every SwiftUI update. Only the flat/smooth toggle rebuilds
    /// anything; the rest is lights and shadows, which are cheap.
    func update(settings: LightingSettings) {
        self.settings = settings
        if let builtFlat, builtFlat != settings.flatShading {
            room?.build(flat: settings.flatShading)
            self.builtFlat = settings.flatShading
        }
        rig.apply(settings, to: sceneRoot)
        room?.refreshContactShadows(settings: settings)
    }
}

/// The game half of the debug overlay. The lighting half is `DebugPanel`,
/// unchanged from the POC.
///
/// **The strip itself stays hidden until it is asked for**, and that much of
/// `CONCEPT.md` §5's parent gate is intact: a visible row of buttons that
/// teleports her out of the room she is playing is the most pressable thing
/// that could be put on this screen, so it is not on the screen.
///
/// What opens it is no longer a gesture she cannot make. `developerButton` has
/// the argument for why the invisible corner had to go — briefly, it was
/// unreachable under the film and there was no way to see that it was.
@MainActor
struct RoomDebugStrip: View {
    @ObservedObject var scene: GameScene
    @ObservedObject var settings: LightingSettings
    var onClose: () -> Void

    @State private var muted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ROOM")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Hide") { onClose() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            // **Visit any room, without playing the game up to it.** The whole
            // reason `GameRoom` exists: with one room the only way in was the
            // front door, and with six that is a five-minute walk to check a
            // touch radius.
            Picker("Room", selection: Binding(
                get: { scene.roomID },
                set: { scene.go(to: $0) }
            )) {
                ForEach(RoomID.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            ForEach(Array((scene.room?.debugLines ?? []).enumerated()), id: \.offset) {
                index, line in
                Text(line)
                    .foregroundStyle(index == 0 ? .primary : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Which line just played. During a session with Nina this is the
            // difference between "she ignored it" and "she never heard it".
            Text(scene.voice?.lastSpoken ?? "")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("New round") { scene.room?.resetRound() }
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
