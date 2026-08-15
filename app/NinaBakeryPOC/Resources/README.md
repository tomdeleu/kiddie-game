# Resources

## Assets.xcassets — required

Three entries.

**`AppIcon`.** Two 1024×1024 PNGs, RGB with no alpha: the light one and a
dark-appearance one that is the same cake on a deep sage backdrop. iOS derives
the tinted variant itself, so none is supplied.

`ASSETCATALOG_COMPILER_APPICON_NAME` was already set to `AppIcon` before the
catalog existed; this folder is a synchronized group, so dropping the catalog in
was enough to wire it up. Provenance, the alternates and the recolour script are
in [`references/app-icon/`](../../../references/app-icon/).

**`LoadingScreen`.** One 2560×1440 PNG, single-scale — the title plate that
`LoadingScreen.swift` shows while the kitchen is built. 16:9 on purpose: the
view fills the screen with it, and no iPad is wider than 16:9, so the crop only
ever takes background off the sides and can never reach the title. Provenance
and the padding script are in
[`references/loading-screen/`](../../../references/loading-screen/).

**`LaunchBackground`.** A single colour, `#D0E3CE`, which is the mean of the
loading plate's four corners. `INFOPLIST_KEY_UILaunchScreen_BackgroundColor`
points at it, so the static launch screen iOS draws before any code runs is the
same mint the plate opens on — launching reads as one field of colour rather
than a white flash.

## Movies — optional

`Movies/intro-1.mp4` and `intro-2.mp4` are the opening film, one shot per file,
played in filename order. Remove them and the game starts straight in the
kitchen; `IntroMovie.isAvailable` is the only thing that checks. Adding
`intro-3.mp4` adds a third shot with no code change. Provenance is in
`references/REFERENCES.md` §3.

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
