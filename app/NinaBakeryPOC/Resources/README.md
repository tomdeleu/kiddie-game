# Resources

## Movies — optional

`Movies/intro.mp4` is the eight-second opening film. Remove it and the game
starts straight in the kitchen; `IntroMovie.isAvailable` is the only thing that
checks. Provenance is in `references/REFERENCES.md` §3.

## Voice — required

`Voice/` holds the kitchen's 86 Dutch voice lines plus `script-keuken.json`,
the manifest `VoiceBank` reads at launch to map a line id to its variant files.
Both are committed, so a fresh clone builds and speaks.

If the mp3s ever go missing, `sh ../../audio/fetch-voice.sh` pulls them back
from the Higgsfield CDN and re-copies the manifest. The app degrades to silence
rather than crashing when a file is absent, and logs which one.

The canonical copy of the script is `audio/script-keuken.json`. The copy here is
produced by that script — edit the canonical one.

## Optional — nothing here is required

Three POC-era assets slot in, and the debug panel detects each one and enables
the matching control.

| Drop in | Filename | Enables |
|---|---|---|
| Environment for image-based lighting | `StudioNeutral.skybox` (or `.exr`) | **Image-based light** section |
| Baked AO lightmap | `Lightmap_AO.png` | Lightmap → **AO** |
| Baked beauty lightmap | `Lightmap_Beauty.png` | Lightmap → **Beauty** |

The room is built procedurally in code, so none of these are needed — and the
POC concluded that the AO ones are not wanted. They stay available because
keeping the escape hatch open costs nothing.

See [`../../LIGHTMAPS.md`](../../LIGHTMAPS.md) for how to produce the lightmaps.

## Sound effects — synthesised, not bundled

There are no SFX files. `SoundKit` generates all thirteen at launch, because
`CONCEPT.md` §7.4 records that the connector cannot supply sound effects and no
CC0 pack has been chosen yet. To swap in real ones: drop them in `SFX/` and
return the filename from `Sound.fileName` — the loader prefers a bundled file
over the synth, one sound at a time.
