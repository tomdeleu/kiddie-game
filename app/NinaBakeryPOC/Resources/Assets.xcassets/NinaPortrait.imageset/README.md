# The photograph in the frame

**Drop the photo in this folder as `nina-portrait.jpg`.** Nothing else to do —
`Contents.json` already names it, and `KitchenProps.portrait` already looks for
the image set by name.

It hangs in the framed picture on the kitchen's back wall, above Otto.

## Why the file is not in the repository

It is a photograph of a child. The frame, the wiring and the fallback are all
committed; the picture itself is added locally by whoever is building the app.
The session that built this could see the photo in the conversation but had no
file handle to it, so it could not commit it either way.

## What happens without it

The frame falls back to `addModelledSitter` — the girl rebuilt out of boxes and
stars in the room's own faceted style. That is deliberate rather than a
placeholder-shaped apology: the frame answers a tap, and `ModelLibrary` sets the
rule that a missing asset must never leave a live tap target with nothing behind
it. An empty frame over a working tap is the "every tap does something" rule
broken.

So the app is correct either way. With the file it is her photo; without it, it
is a picture of her.

## What the file should be

- **Any aspect ratio.** The frame measures the texture and fits it inside
  `Layout.portraitPictureMax` preserving the aspect, so a landscape photo gives a
  landscape frame and a portrait one gives a portrait frame. No numbers need
  changing when the file changes.
- **Roughly 512–1024 px on the long edge is plenty.** The picture is 76 mm across
  in a 460 mm room, and on an iPad it occupies a couple of hundred points. A
  4000 px photo costs memory and buys nothing.
- **JPEG or PNG.** If you use PNG, change the `filename` in `Contents.json` to
  match.

## If you would rather not use the asset catalog

`photograph()` also tries the name `nina-portrait`, so a loose
`nina-portrait.jpg` added to `Resources/` as a bundle resource works without
touching the catalog.
