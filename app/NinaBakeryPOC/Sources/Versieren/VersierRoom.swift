import RealityKit
import simd

/// **Versieren — the decorating room.** `GAMEPLAY.md` §6.4.
///
/// The cake sits on a turntable; trays around the edge hold sprinkles, candles,
/// hearts, stars, crowns, fruit and cream swirls; a piping bag draws a line of
/// cream and a shaker rains sprinkles. Drag a sticker anywhere on the cake and
/// it stays where she put it — no grid, no snapping, no correct answer, no limit.
///
/// **This room asks her for nothing.** It has no required action, which makes it
/// the one room where the halo has nothing to point at — so the door is lit from
/// the moment she arrives, which is the honest use of the cue: it says *you may
/// go when you like*, and here that is exactly true.
///
/// > **Stub.** This is the shell and the contract only — enough for the room
/// > switcher to enter and leave it without leaking targets or ticker jobs. The
/// > turntable, the trays, the two tools and the analytic cake surface land in
/// > the next commit.
@MainActor
final class VersierRoom: Room {

    let root = Entity()
    var onExit: ((RoomExit) -> Void)?

    let mode: RoomMode

    private let ticker: Ticker
    private let touch: TouchRouter
    private let voice: VoiceBank
    private let sound: SoundKit
    private var settings: LightingSettings
    private var flat = true

    /// **The cake she is here to decorate.**
    ///
    /// On a round it is the one the kitchen just baked and handed over. On a
    /// visit there is nothing to hand over, so one is dealt — owner's call,
    /// 2026-08-16: decorating with no cake in front of her is not a thing, and
    /// the answer is to give her a cake rather than to refuse her the room.
    private(set) var cake: CakeSpec

    init(ticker: Ticker, touch: TouchRouter, voice: VoiceBank,
         sound: SoundKit, settings: LightingSettings,
         mode: RoomMode = .bezoek, handedCake: CakeSpec? = nil) {
        self.ticker = ticker
        self.touch = touch
        self.voice = voice
        self.sound = sound
        self.settings = settings
        self.mode = mode
        self.cake = handedCake ?? CakeSpec.dealt()
        root.name = "Versieren"
    }

    func build(flat: Bool) {
        self.flat = flat
        cancelEverything()
        root.children.removeAll()
        touch.removeAll()

        root.addChild(RoomBox.shell(flat: flat))

        // A tap on nothing sparkles under her finger. Not optional — a screen
        // that eats a tap silently is where she decides the iPad is broken.
        touch.onEmptyTap = { [weak self] world in
            guard let self else { return }
            Sparkles.burst(at: world + [0, 0.004, 0], in: self.root, ticker: self.ticker,
                           colour: Palette.creamLight, count: 6, size: 0.0022,
                           speed: 0.06, life: 0.5)
        }
    }

    func greet() {}

    func save() {}

    func restartRound() {}

    func refreshContactShadows(settings: LightingSettings) {
        self.settings = settings
    }

    func leave() {
        cancelEverything()
        save()
    }

    var debugTitle: String { RoomID.versieren.title }

    var debugRows: [String] {
        ["Mode: \(mode == .ronde ? "ronde" : "bezoek")",
         "Cake: \(cake.kind.rawValue) · \(cake.colours.map(\.rawValue).joined(separator: ", "))",
         "Effects: \(cake.effects.map(\.rawValue).joined(separator: ", "))"]
    }

    var debugActions: [(String, @MainActor () -> Void)] { [] }

    private func cancelEverything() {
        touch.onEmptyTap = nil
    }
}
