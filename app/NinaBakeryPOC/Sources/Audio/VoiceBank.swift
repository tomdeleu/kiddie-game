import Foundation
import AVFoundation

/// Luna and Otto, speaking Dutch.
///
/// The app never calls a text-to-speech API (`CONCEPT.md` §7.3): it plays
/// bundled mp3s. What lines exist, and which files back them, comes from
/// `script-keuken.json` — the same file that is the production record — so
/// adding a line is a generation plus a JSON entry and no Swift change.
///
/// Two rules do most of the work in making her sound like a person:
///
/// - **Never the same variant twice running.** Luna has four ways to say hello
///   and three ways to nudge; picking at random would still repeat, so the
///   previous pick is excluded outright.
/// - **Nobody talks over anybody.** One line at a time, and an idle nudge
///   simply does not fire while someone is speaking.
@MainActor
final class VoiceBank {

    enum Priority {
        /// Reactions to something she did. Interrupts whatever is speaking.
        case normal
        /// Idle nudges and toy chatter. Dropped if anyone is already talking.
        case low
    }

    private struct Script: Decodable {
        struct Variant: Decodable {
            let file: String
            let text: String
        }
        struct Line: Decodable {
            let id: String
            let character: String
            let variants: [Variant]
        }
        let lines: [Line]
    }

    private var lines: [String: [Script.Variant]] = [:]
    private var lastPick: [String: Int] = [:]
    private var player: AVAudioPlayer?
    private var chainJob: Int?
    private let ticker: Ticker

    /// What is on screen right now, for the debug panel and for tests with
    /// Nina — knowing which line was playing when she looked away is the
    /// difference between "she ignored it" and "she never heard it".
    private(set) var lastSpoken: String = ""

    var isSpeaking: Bool { player?.isPlaying ?? false }

    init(ticker: Ticker) {
        self.ticker = ticker
    }

    // MARK: - Loading

    /// Load every bundled `script-*.json`.
    ///
    /// Plural on purpose: the kitchen has one, the opening film has one, and
    /// each room added later brings its own. Merging them here means a new
    /// scene is a new file rather than an edit to a file the whole game shares.
    func load() {
        var seen: Set<String> = []
        var loaded = 0

        for url in Self.scriptURLs() where seen.insert(url.lastPathComponent).inserted {
            guard let data = try? Data(contentsOf: url),
                  let script = try? JSONDecoder().decode(Script.self, from: data) else {
                print("[VoiceBank] could not read \(url.lastPathComponent)")
                continue
            }
            for line in script.lines {
                lines[line.id] = line.variants
            }
            loaded += 1
        }

        if loaded == 0 {
            // Not fatal. The room is playable in silence, and saying so beats
            // a crash on a device with a half-populated bundle.
            print("[VoiceBank] no script-*.json found — the game will be mute.")
        }
    }

    private static func scriptURLs() -> [URL] {
        let inFolder = Bundle.main.urls(forResourcesWithExtension: "json",
                                        subdirectory: "Voice") ?? []
        let inRoot = Bundle.main.urls(forResourcesWithExtension: "json",
                                      subdirectory: nil) ?? []
        return (inFolder + inRoot).filter { $0.lastPathComponent.hasPrefix("script-") }
    }

    /// Bundle lookup that works whether Xcode flattened `Resources/Voice` into
    /// the bundle root or preserved it as a folder. Which of the two you get
    /// depends on how the synchronized group resolves, and it is not worth
    /// caring about at every call site.
    static func resourceURL(named name: String, extension ext: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Voice")
            ?? Bundle.main.url(forResource: name, withExtension: ext)
    }

    // MARK: - Speaking

    /// Say one line. Returns how long it will take, so a caller can time what
    /// happens next to the voice rather than to a guess.
    @discardableResult
    func say(_ id: String, priority: Priority = .normal) -> Float {
        guard let variants = lines[id], !variants.isEmpty else { return 0 }
        if priority == .low && isSpeaking { return 0 }

        let pick = choose(variants.count, for: id)
        let variant = variants[pick]
        lastSpoken = "\(id) → \(variant.text)"

        guard let url = Self.resourceURL(named: (variant.file as NSString).deletingPathExtension,
                                         extension: "mp3"),
              let next = try? AVAudioPlayer(contentsOf: url) else {
            return 0
        }

        ticker.cancel(chainJob)
        chainJob = nil
        player?.stop()
        next.prepareToPlay()
        next.play()
        player = next
        return Float(next.duration)
    }

    /// Say lines one after another, with a breath between them. The cake
    /// reaction uses it: colour first, then the effect that stacked on top.
    func say(_ ids: [String], gap: Float = 0.25) {
        guard let first = ids.first else { return }
        let duration = say(first)
        let rest = Array(ids.dropFirst())
        guard !rest.isEmpty else { return }
        chainJob = ticker.after(duration + gap) { [weak self] in
            self?.say(rest, gap: gap)
        }
    }

    func stop() {
        ticker.cancel(chainJob)
        chainJob = nil
        player?.stop()
        player = nil
    }

    /// Random, but never the one just heard.
    private func choose(_ count: Int, for id: String) -> Int {
        guard count > 1 else { return 0 }
        let last = lastPick[id]
        var pick = Int.random(in: 0..<count)
        if pick == last { pick = (pick + 1 + Int.random(in: 0..<(count - 1))) % count }
        lastPick[id] = pick
        return pick
    }
}

/// The line ids the kitchen uses, spelled once.
///
/// Every constant here exists in `script-keuken.json`; a typo is a silent line
/// rather than a crash, which is why they are not scattered as string literals.
enum Line {
    static let hallo = "luna.keuken.hallo"
    static let doeInKom = "luna.keuken.doeInKom"
    static let roeren = "luna.keuken.roeren"
    static let roerenGoedZo = "luna.keuken.roerenGoedZo"
    static let beslagKlaar = "luna.keuken.beslagKlaar"
    static let gieten = "luna.keuken.gieten"
    static let gegoten = "luna.keuken.gegoten"
    static let naarOtto = "luna.keuken.naarOtto"
    static let klopOpOtto = "luna.keuken.klopOpOtto"
    static let oeps = "luna.oeps"
    static let bloem = "luna.speel.bloem"
    static let stil = "luna.stil"
    static let klaar = "luna.klaar"

    static let ottoTik = "otto.tik"
    static let ottoVormErin = "otto.vormErin"
    static let ottoBakken = "otto.bakken"
    static let ottoKlaar = "otto.klaar"
    static let ottoWacht = "otto.wacht"

    /// The opening film. Chained, over silent video — two lines over the
    /// exterior shot and one over the cut inside.
    static let introWelkom = "luna.intro.welkom"
    static let introBinnen = "luna.intro.binnen"
    static let introKeuken = "luna.intro.keuken"
}
