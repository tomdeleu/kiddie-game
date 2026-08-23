# SFX

Three CC0 files for **Het Feest**. Everything else in `SoundKit` is still
synthesised. Missing files fall back to the synth (`trom`, `kras`) or to
silence (the loop), same as a missing voice line.

| File | Plays as | Source | Licence |
|---|---|---|---|
| `feest-discobits.m4a` | The party loop | [Disco Bits](https://opengameart.org/content/disco-bits) — medicinestorm, OpenGameArt | CC0 |
| `trom-pss170.wav` | Pad 1, the DJ's beat, the speakers | First kick of [disco.wav](https://freesound.org/people/mikemunkie/sounds/66899/) — mikemunkie, Yamaha PSS-170 disco pattern | CC0 |
| `kras-vinyl12.wav` | Pad 6, the DJ's scratch | [Vinyl Scratch #12](https://bigsoundbank.com/vinyl-scratch-12-s2869.html) — Joseph Sardin, BigSoundBank | CC0 |

What was done to them, so a re-fetch can match:

- **Disco Bits** — original 128 s stereo WAV, encoded AAC 160 kbps, 30 ms fade
  in and 60 ms fade out so the join is a dip rather than a click. It runs at
  its own tempo, quiet under her pads (`volume` 0.28).
- **trom** — cropped to the first kick (0.21 s) of the two-second pattern, so
  four hits at her tempo do not smear. 44.1 kHz 16-bit mono.
- **kras** — the 0.67 s original, faded at both ends, peak-matched to the
  drum. 44.1 kHz 16-bit mono.

`Sound.fileName` is how `trom` and `kras` pick these over the synth. The loop
is a different kind of thing — one `AVAudioPlayer`, started in `FeestRoom.build`
and stopped in `cancelEverything`.
