import Foundation
import AVFoundation

/// Every sound effect in the kitchen, synthesised at launch.
///
/// `CONCEPT.md` §7.4 records that the connector cannot supply sound effects —
/// its SFX model refuses standalone use — and points at Freesound or a bought
/// pack. Neither is reachable from here, and a silent kitchen is not a kitchen:
/// the reward *is* the sound (`CONCEPT.md` §5), and `POC.md` says the reward
/// sound has to be in or the engagement signal from testing is misleading.
///
/// So these are generated: a few hundred lines of oscillators and envelopes,
/// rendered to PCM at startup in a few milliseconds and played through pooled
/// `AVAudioPlayer`s. They are honest placeholders — small, warm, and consistent
/// — and every one of them is a parameter change away from being retuned.
///
/// **Replace them when a CC0 pack arrives.** Drop the files in `Resources/SFX`
/// and give `Sound.fileName` a non-nil case; `SoundKit` prefers a bundled file
/// over the synthesised one, so the swap is per-sound and needs no other edit.
enum Sound: String, CaseIterable {
    case plop        // something lands in the bowl
    case ding        // the scale
    case rattle      // shelf jars
    case poof        // the flour sack
    case water       // the tap
    case pour        // batter into the tin
    case ovenPing    // Otto is finished
    case sparkle     // a small good thing happened
    case reward      // the cake is out
    case whoosh      // the oven door, the doorway
    case roll        // the rolling pin
    case stirTick    // one soft blip per stir, quiet by design
    case thud        // a prop set down

    /// Filename in `Resources/SFX` to use instead of the synth, once one
    /// exists. Nothing has one yet — see the type doc.
    var fileName: String? { nil }
}

@MainActor
final class SoundKit {

    private var pools: [Sound: [AVAudioPlayer]] = [:]
    private var cursors: [Sound: Int] = [:]
    private let voicesPerSound = 3

    /// Muted only by the debug panel. There is no in-game mute: a silent game
    /// reads as a broken game to her.
    var enabled = true

    func prepare() {
        configureSession()
        for sound in Sound.allCases {
            guard let data = audioData(for: sound) else { continue }
            var players: [AVAudioPlayer] = []
            for _ in 0..<voicesPerSound {
                guard let player = try? AVAudioPlayer(data: data) else { continue }
                player.enableRate = true
                player.prepareToPlay()
                players.append(player)
            }
            pools[sound] = players
            cursors[sound] = 0
        }
    }

    /// Play, stealing the oldest voice if she is hammering something.
    /// `CONCEPT.md` §10 asks for a pool rather than a player per hit, because
    /// overlapping sounds are guaranteed.
    func play(_ sound: Sound, volume: Float = 1, rate: Float = 1) {
        guard enabled, let players = pools[sound], !players.isEmpty else { return }
        let index = (cursors[sound] ?? 0) % players.count
        cursors[sound] = index + 1
        let player = players[index]
        player.currentTime = 0
        player.volume = volume
        player.rate = max(0.5, min(2, rate))
        player.play()
    }

    /// A tiny random detune, so the twentieth tap on the same jar is not the
    /// literal same sound.
    func playVaried(_ sound: Sound, volume: Float = 1) {
        play(sound, volume: volume, rate: Float.random(in: 0.92...1.09))
    }

    private func configureSession() {
        #if os(iOS)
        // `.playback` so the game still speaks with the ring switch flicked.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
        #endif
    }

    private func audioData(for sound: Sound) -> Data? {
        if let name = sound.fileName,
           let url = Bundle.main.url(forResource: name, withExtension: nil,
                                     subdirectory: "SFX")
            ?? Bundle.main.url(forResource: name, withExtension: nil),
           let data = try? Data(contentsOf: url) {
            return data
        }
        return Synth.render(sound)
    }
}

// MARK: - The synth

/// Oscillators, envelopes and a WAV writer. Deliberately small: everything here
/// is a sum of a couple of waves under an exponential decay.
private enum Synth {

    static let sampleRate: Double = 44_100

    static func render(_ sound: Sound) -> Data {
        switch sound {
        case .plop:
            // Pitch drops fast — the sound of something small hitting batter.
            return wav(0.18) { t in
                let f = 620 * exp(-14 * t) + 190
                return sine(f, t) * decay(t, 16) * 0.7
            }

        case .ding:
            return wav(0.6) { t in
                (sine(1180, t) * 0.7 + sine(2360, t) * 0.25 + sine(3540, t) * 0.08)
                    * decay(t, 5.5)
            }

        case .rattle:
            // Four little knocks, like jars nudging each other.
            return wav(0.42) { t in
                var value: Float = 0
                for i in 0..<4 {
                    let start = Double(i) * 0.055 + Double(i) * Double(i) * 0.004
                    guard t >= start else { continue }
                    let local = t - start
                    value += sine(430 + Double(i) * 90, local) * decay(local, 34) * 0.4
                }
                return value
            }

        case .poof:
            return wav(0.55) { t in
                lowpassNoise(t, cutoff: 0.16) * decay(t, 6) * 0.55
            }

        case .water:
            return wav(1.3) { t in
                let body = lowpassNoise(t, cutoff: 0.32) * 0.4
                let swell = Float(min(1, t * 8)) * Float(min(1, (1.3 - t) * 5))
                return body * swell
            }

        case .pour:
            return wav(1.0) { t in
                let body = lowpassNoise(t, cutoff: 0.22 + 0.1 * Double(decay(t, 2)))
                let glug = sine(150 + 40 * sin(t * 26), t) * 0.18 * decay(t, 2)
                return (body * 0.35 + glug) * Float(min(1, t * 12)) * decay(t, 1.6)
            }

        case .ovenPing:
            // Rises — the one sound in the room that means "finished".
            return wav(0.8) { t in
                let f = 560 + 620 * Double(1 - decay(t, 6))
                return (sine(f, t) * 0.6 + sine(f * 2.01, t) * 0.2) * decay(t, 3.4)
            }

        case .sparkle:
            let notes: [Double] = [1568, 2093, 2637]
            return wav(0.5) { t in
                var value: Float = 0
                for (i, f) in notes.enumerated() {
                    let start = Double(i) * 0.055
                    guard t >= start else { continue }
                    value += triangle(f, t - start) * decay(t - start, 11) * 0.3
                }
                return value
            }

        case .reward:
            // A small major arpeggio. This is the cake-is-ready fanfare.
            let notes: [Double] = [523.25, 659.25, 783.99, 1046.5]
            return wav(1.1) { t in
                var value: Float = 0
                for (i, f) in notes.enumerated() {
                    let start = Double(i) * 0.085
                    guard t >= start else { continue }
                    let local = t - start
                    value += (triangle(f, local) * 0.6 + sine(f * 2, local) * 0.15)
                        * decay(local, 3.2) * 0.32
                }
                return value
            }

        case .whoosh:
            return wav(0.5) { t in
                let shape = Float(sin(min(1, t / 0.5) * Double.pi))
                return lowpassNoise(t, cutoff: 0.1 + 0.5 * t) * shape * 0.35
            }

        case .roll:
            return wav(0.5) { t in
                let rumble = lowpassNoise(t, cutoff: 0.06) * 0.5
                let wobble = Float(0.7 + 0.3 * sin(t * 40))
                return rumble * wobble * Float(min(1, t * 10)) * decay(t, 3)
            }

        case .stirTick:
            return wav(0.07) { t in
                sine(320, t) * decay(t, 45) * 0.35
            }

        case .thud:
            return wav(0.22) { t in
                (sine(96, t) * 0.8 + sine(148, t) * 0.2) * decay(t, 22) * 0.8
            }
        }
    }

    // MARK: Oscillators

    private static func sine(_ frequency: Double, _ t: Double) -> Float {
        Float(sin(2 * Double.pi * frequency * t))
    }

    private static func triangle(_ frequency: Double, _ t: Double) -> Float {
        let phase = (frequency * t).truncatingRemainder(dividingBy: 1)
        return Float(4 * abs(phase - 0.5) - 1)
    }

    private static func decay(_ t: Double, _ rate: Double) -> Float {
        Float(exp(-rate * t))
    }

    /// Deterministic noise through a one-pole lowpass.
    ///
    /// The filter carries state, and `render` walks time strictly forwards, so
    /// a single `nonisolated(unsafe)` pair of vars is enough — and keeps the
    /// synth a pure function of the sound, which is what makes these
    /// reproducible byte-for-byte.
    nonisolated(unsafe) private static var noiseSeed: UInt64 = 0x2545F4914F6CDD1D
    nonisolated(unsafe) private static var filterState: Float = 0

    private static func lowpassNoise(_ t: Double, cutoff: Double) -> Float {
        noiseSeed = noiseSeed &* 6364136223846793005 &+ 1442695040888963407
        let raw = Float(Int32(truncatingIfNeeded: noiseSeed >> 33)) / Float(Int32.max)
        let k = Float(max(0.001, min(1, cutoff)))
        filterState += (raw - filterState) * k
        return filterState
    }

    // MARK: WAV

    /// 16-bit mono PCM with a 44-byte header — the least machinery that
    /// `AVAudioPlayer(data:)` will accept.
    private static func wav(_ duration: Double, _ sample: (Double) -> Float) -> Data {
        filterState = 0
        let frames = Int(duration * sampleRate)
        var samples = Data(capacity: frames * 2 + 44)

        var header = Data()
        header.append(ascii("RIFF"))
        header.append(le32(UInt32(36 + frames * 2)))
        header.append(ascii("WAVE"))
        header.append(ascii("fmt "))
        header.append(le32(16))                         // PCM chunk size
        header.append(le16(1))                          // format: PCM
        header.append(le16(1))                          // channels
        header.append(le32(UInt32(sampleRate)))
        header.append(le32(UInt32(sampleRate) * 2))     // byte rate
        header.append(le16(2))                          // block align
        header.append(le16(16))                         // bits per sample
        header.append(ascii("data"))
        header.append(le32(UInt32(frames * 2)))
        samples.append(header)

        for frame in 0..<frames {
            let t = Double(frame) / sampleRate
            // A short fade at both ends: a waveform cut mid-cycle clicks, and a
            // click on every tap is exactly the kind of cheapness she'd hear.
            let fadeIn = Float(min(1, Double(frame) / 64))
            let fadeOut = Float(min(1, Double(frames - frame) / 256))
            let value = max(-1, min(1, sample(t) * fadeIn * fadeOut))
            samples.append(le16(UInt16(bitPattern: Int16(value * 32000))))
        }
        return samples
    }

    private static func ascii(_ string: String) -> Data {
        Data(string.utf8)
    }

    private static func le16(_ value: UInt16) -> Data {
        Data([UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF)])
    }

    private static func le32(_ value: UInt32) -> Data {
        Data([UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF),
              UInt8((value >> 16) & 0xFF), UInt8((value >> 24) & 0xFF)])
    }
}
