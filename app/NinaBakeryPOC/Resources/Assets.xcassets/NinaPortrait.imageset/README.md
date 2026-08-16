# The photograph in the frame

`nina-portrait.jpeg` — 1402 × 1212 — hangs in the framed picture on the
kitchen's back wall, above Otto.

## If you replace it

**The filename in `Contents.json` has to match the file on disk, exactly,
extension included.** That is the one thing here that fails quietly: the wiring
looks up the *image set* by its folder name (`NinaPortrait`), so a `Contents.json`
pointing at a name nothing on disk has does not error at runtime — it produces an
empty image set, the texture load returns `nil`, and the frame silently falls
back to the modelled girl. The picture is simply not there and nothing says why.

It has already happened once: the file arrived as `.jpeg` and this file said
`.jpg`.

Nothing else needs changing. Any aspect ratio works — `KitchenProps.portrait`
reads the texture's own pixel dimensions and fits the picture inside
`Layout.portraitPictureMax`, so a landscape photo gives a landscape frame and a
portrait one gives a portrait frame, at the same visual weight on the wall.

512–1024 px on the long edge is plenty: the picture is 76 mm across in a 460 mm
room and occupies a couple of hundred points on an iPad. A 4000 px photo costs
memory and buys nothing.

## What happens without it

The frame falls back to `addModelledSitter` — the girl rebuilt out of boxes and
stars in the room's own faceted style. That is deliberate rather than a
placeholder-shaped apology: the frame answers a tap, and `ModelLibrary` sets the
rule that a missing asset must never leave a live tap target with nothing behind
it. An empty frame over a working tap is the "every tap does something" rule
broken.

So the app is correct either way. With the file it is her photo; without it, it
is a picture of her.

## If you would rather not use the asset catalog

`photograph()` also tries the bare name `nina-portrait`, so a loose file added
to `Resources/` as a bundle resource works without touching the catalog at all.
