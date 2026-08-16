import Foundation
import AVFoundation

/// Nina and Otto, speaking Dutch.
///
/// The app never calls a text-to-speech API (`CONCEPT.md` §7.3): it plays
/// bundled mp3s. What lines exist, and which files back them, comes from
/// `script-keuken.json` — the same file that is the production record — so
/// adding a line is a generation plus a JSON entry and no Swift change.
///
/// Two rules do most of the work in making her sound like a person:
///
/// - **Never the same variant twice running.** Nina has four ways to say hello
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
    /// The one line waiting for her to stop talking — see `sayWhenQuiet`.
    private var pendingJob: Int?
    private let ticker: Ticker

    /// What is on screen right now, for the debug panel and for tests with
    /// Nina — knowing which line was playing when she looked away is the
    /// difference between "she ignored it" and "she never heard it".
    private(set) var lastSpoken: String = ""

    var isSpeaking: Bool { player?.isPlaying ?? false }

    /// **Mid-sentence, or mid-breath between two of them.** A chain of lines
    /// goes quiet for a quarter of a second between each pair, and treating that
    /// gap as "she has finished" is how a two-line reaction gets talked over by
    /// its own follow-up.
    private var isTalking: Bool { isSpeaking || chainJob != nil }

    /// Talking, or holding something to say the moment she stops.
    var isBusy: Bool { isTalking || pendingJob != nil }

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

    // MARK: - Waiting for her to finish

    /// **Say this as soon as Nina stops talking, rather than over the top of
    /// her.**
    ///
    /// `say` at `.normal` interrupts, and that is right for a reaction to
    /// something Nina did *this instant* — but it is wrong for the line that
    /// opens the next step, which is exactly where it kept biting: drop the last
    /// ingredient in and 1.1 s later stirring begins and says so, straight
    /// through the four-second line about the ingredient (owner, 2026-08-16:
    /// "when moving from one action to another you MUST wait until the voiceover
    /// has completed"). Playing fast should not cost her the words.
    ///
    /// **Only one line can ever be waiting, and a newer one replaces it.** That
    /// is the whole reason this is not a queue: a queue would mean three quick
    /// drops earn a twelve-second monologue about things that have already
    /// happened, which is worse than the interruption it fixed. What she gets is
    /// the line she is speaking now, and then the most recent thing that is
    /// still true.
    ///
    /// The timeout is the escape hatch. Nothing in the game blocks on this — the
    /// step has already changed and the halo has already moved — so the worst
    /// case is a line that is dropped rather than a game that stops.
    func sayWhenQuiet(_ ids: [String], gap: Float = 0.3,
                      breath: Float = 0.3, timeout: Float = 12) {
        guard !ids.isEmpty else { return }
        ticker.cancel(pendingJob)
        var waited: Float = 0
        var quiet: Float = 0
        pendingJob = ticker.add { [weak self] dt in
            guard let self else { return false }
            waited += dt
            quiet = self.isTalking ? 0 : quiet + dt
            guard quiet >= breath || waited > timeout else { return true }
            self.pendingJob = nil
            self.say(ids, gap: gap)
            return false
        }
    }

    func sayWhenQuiet(_ id: String, breath: Float = 0.3, timeout: Float = 12) {
        sayWhenQuiet([id], breath: breath, timeout: timeout)
    }

    /// Run `body` once she has stopped talking — including through the gaps in a
    /// chain and through anything `sayWhenQuiet` is still holding.
    ///
    /// The end of a round uses it: the celebration is four sentences long, and
    /// the room must not rebuild itself underneath the third one.
    @discardableResult
    func whenQuiet(after breath: Float = 0.3, timeout: Float = 30,
                   then body: @escaping @MainActor () -> Void) -> Int {
        var waited: Float = 0
        var quiet: Float = 0
        return ticker.add { [weak self] dt in
            guard let self else { return false }
            waited += dt
            quiet = self.isBusy ? 0 : quiet + dt
            guard quiet >= breath || waited > timeout else { return true }
            body()
            return false
        }
    }

    func stop() {
        ticker.cancel(chainJob)
        chainJob = nil
        ticker.cancel(pendingJob)
        pendingJob = nil
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
    static let hallo = "nina.keuken.hallo"
    static let doeInKom = "nina.keuken.doeInKom"
    static let roeren = "nina.keuken.roeren"
    static let roerenGoedZo = "nina.keuken.roerenGoedZo"
    static let beslagKlaar = "nina.keuken.beslagKlaar"
    static let gieten = "nina.keuken.gieten"
    static let gegoten = "nina.keuken.gegoten"
    static let naarOtto = "nina.keuken.naarOtto"
    static let klopOpOtto = "nina.keuken.klopOpOtto"
    static let oeps = "nina.oeps"
    static let bloem = "nina.speel.bloem"
    static let stil = "nina.stil"

    /// **The three lines that end a round**, said in this order: what she made,
    /// where it is now, and what happens next. `KitchenRoom.placeOnPlank` has
    /// the argument for why the last one exists.
    static let klaar = "nina.klaar"
    static let plankGezet = "nina.plank.gezet"
    static let plankNogEen = "nina.plank.nogeen"

    /// **And the third line's other half.** `plankNogEen` is what she hears
    /// after cakes one and two — *shall we make another?* — and this is what
    /// replaces it after the third, when the plank is full enough to finish the
    /// room and the door is the next thing. `KitchenRoom.placeOnPlank` picks
    /// between them.
    static let kamerKlaar = "nina.kamer.klaar"
    /// Tapping the open door once the kitchen is finished. Deliberately promises
    /// a room *soon* rather than a room *now* — see `KitchenRoom.endRoom`.
    static let kamerDeur = "nina.kamer.deur"

    /// What we are doing today, said once at the top of every round.
    static let opdracht = "nina.keuken.opdracht"
    /// The rolling step, which comes before anything goes in the bowl.
    static let uitrollen = "nina.keuken.uitrollen"
    static let deegKlaar = "nina.keuken.deegKlaar"
    /// Generic "take the glowing one", and the five places it can be.
    static let pakGlimmend = "nina.keuken.pakGlimmend"
    static let bronPlankHoog = "nina.bron.plankHoog"
    static let bronPlankLaag = "nina.bron.plankLaag"
    static let bronAanrecht = "nina.bron.aanrecht"
    static let bronMandje = "nina.bron.mandje"
    static let bronKrat = "nina.bron.krat"
    /// The round's last step: carry the cake up onto the plank.
    static let opDePlank = "nina.keuken.opDePlank"
    static let opnieuw = "nina.keuken.opnieuw"

    static let ottoTik = "otto.tik"
    static let ottoVormErin = "otto.vormErin"
    static let ottoBakken = "otto.bakken"
    static let ottoKlaar = "otto.klaar"
    static let ottoWacht = "otto.wacht"

    /// The opening film, one line per shot, each written to that shot's length.
    static let introBuiten = "nina.intro.buiten"
    static let introKeuken = "nina.intro.keuken"

    // MARK: - The naming lines

    /// **What a prop is, said when she taps it.** `script-namen.json`.
    ///
    /// The game has exactly two verbs (`GAMEPLAY.md` §3) and until now only one
    /// of them meant anything: a drag was the round, and a tap was a wobble and
    /// a sound effect. These give the tap a job of its own — **drag to bake,
    /// tap to find out what a thing is called** — and they are the only place in
    /// the game that teaches a word rather than asking for an action.
    ///
    /// Every one is said at `.low` priority, which is what keeps them a layer
    /// rather than an interruption: a naming line is dropped outright if Nina is
    /// already saying anything, so it can never talk over the instruction it
    /// would be explaining.
    ///
    /// The six ingredient names are reached through `Ingredient.nameLineID`
    /// rather than listed here, for the same reason `lineID` is: the six ids are
    /// spelled once in the whole game, off the enum case.
    static let ditDeegroller = "nina.dit.deegroller"
    static let ditDeeg = "nina.dit.deeg"
    static let ditKom = "nina.dit.kom"
    static let ditLepel = "nina.dit.lepel"
    static let ditVorm = "nina.dit.vorm"
    static let ditBloem = "nina.dit.bloem"
    static let ditKraan = "nina.dit.kraan"
    static let ditWeegschaal = "nina.dit.weegschaal"
    static let ditMandje = "nina.dit.mandje"
    static let ditKist = "nina.dit.kist"
    static let ditPotje = "nina.dit.potje"
    static let ditTaartenplank = "nina.dit.taartenplank"
    static let ditDeur = "nina.dit.deur"
    static let ditTaart = "nina.dit.taart"
    static let ditPortret = "nina.dit.portret"

    // MARK: - De Tuin

    /// **The garden's round**, `script-tuin.json`.
    ///
    /// Same contract as the kitchen's (`ROOMS.md` §4): every constant here
    /// exists in the script and every id in the script is referenced from here.
    /// A typo is a silent tap, which in a game with no text is the hardest kind
    /// of bug to notice.
    ///
    /// Three of the kitchen's are reused rather than duplicated, because they
    /// say nothing about a kitchen: `oeps` when a drag does not land, `stil` for
    /// the alternating idle nudge, and `nina.ingredient.*` — which already names
    /// the colour each ingredient will give the cake, and is therefore exactly
    /// the right thing to hear as she picks one.
    enum Tuin {
        static let hallo = "nina.tuin.hallo"
        /// What we are doing today, said once at the top of a round.
        static let opdracht = "nina.tuin.opdracht"
        static let zaaien = "nina.tuin.zaaien"
        static let gezaaid = "nina.tuin.gezaaid"
        static let gieten = "nina.tuin.gieten"
        /// Halfway. Encouragement, never correction.
        static let groeit = "nina.tuin.groeit"
        static let rijp = "nina.tuin.rijp"
        static let mandjeVol = "nina.tuin.mandjeVol"
        static let opnieuw = "nina.tuin.opnieuw"
        /// The garden is finished — tap the gate. The garden's own half of
        /// `nina.kamer.klaar`, which names the kitchen.
        static let kamerKlaar = "nina.kamer.tuinKlaar"
        /// Tapping the open door. Promises the next room *soon*, never *now*.
        static let kamerDeur = "nina.kamer.tuinDeur"
    }

    /// The toys. Two variants each — enough that the sixth poke is not the first
    /// one again, and they are chatter rather than instruction.
    enum Speel {
        static let vlinder = "nina.speel.vlinder"
        static let bij = "nina.speel.bij"
        static let mol = "nina.speel.mol"
        static let bloemen = "nina.speel.bloemen"
        static let plas = "nina.speel.plas"
        static let regenboog = "nina.speel.regenboog"
    }

    /// The garden's slice of `script-namen.json`. One variant each, deliberately
    /// — a name is a thing you learn by hearing it the same way twice.
    ///
    /// The eight seed names are not here: a jar of `aardbei` seeds is named
    /// through `Ingredient.nameLineID`, the same line the kitchen says when she
    /// taps the berry, so the word she learns in the garden is the word she
    /// hears in the kitchen.
    enum Dit {
        static let zaadje = "nina.dit.zaadje"
        static let zaaibak = "nina.dit.zaaibak"
        static let gat = "nina.dit.gat"
        static let gieter = "nina.dit.gieter"
        static let plantje = "nina.dit.plantje"
        static let mandje = "nina.dit.mandje"     // the kitchen's, reused
        static let hek = "nina.dit.hek"
        static let bloemen = "nina.dit.bloemen"
        static let molshoop = "nina.dit.molshoop"
        static let vlinder = "nina.dit.vlinder"
        static let bij = "nina.dit.bij"
        static let plas = "nina.dit.plas"
        static let boom = "nina.dit.boom"
        static let struik = "nina.dit.struik"
        static let potje = "nina.dit.potje"       // the kitchen's, reused
    }
}
