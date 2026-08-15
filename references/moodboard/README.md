# Moodboard — provenance and licence

Page screenshots captured via the Firecrawl connector. Full method and the
things that do not work: [`../FETCHING-ASSETS.md`](../FETCHING-ASSETS.md).

**Read the licence column before using anything.** Only the Kenney kits are
free to put in the game.

| File | Source | Licence | Use |
|---|---|---|---|
| `03-devforum-lowpoly-with-blocks.png` | [devforum 278566](https://devforum.roblox.com/t/how-to-create-a-low-poly-lookvibe-using-roblox-studio-blocks/278566) | © respective posters | **Reference only.** Kept for construction-from-primitives, not for its look. |
| `04-kenney-food-kit.png` | [kenney.nl](https://kenney.nl/assets/food-kit) | **CC0** | **Use directly.** 200 models. |
| `05-kenney-furniture-kit.png` | [kenney.nl](https://kenney.nl/assets/furniture-kit) | **CC0** | **Use directly.** 140 models. |
| `06-unity-cute-bakery-building.png` | [Unity Asset Store](https://assetstore.unity.com/packages/3d/environments/low-poly-cute-bakery-building-229785) | Unity EULA | **Reference only** — free, but the EULA ties it to Unity projects, and we are on RealityKit. |
| `07-cgtrader-floating-island-house.png` | [CGTrader](https://www.cgtrader.com/free-3d-models/exterior/other/stylized-low-poly-floating-island-with-small-house) | Royalty-free, **no AI** | Model is free to download and use. Do **not** feed it to an image generator. |
| `08-dribbble-isometric-bakery.png` | [Dribbble — Naomi](https://dribbble.com/shots/21332763-3D-Cute-Isometric-Bakery-made-in-Blender) | © the artist | **THE ANCHOR.** Reference only — never a generation input. |

Do not ship or redistribute anything not marked CC0.

## The agreed direction

**`08-dribbble-isometric-bakery.png` is the anchor.** Everything else in this
folder is secondary context.

> A **cosy isometric clay miniature**: an open corner room box (two walls and a
> floor), everything in soft matte clay with gently rounded edges, warm muted
> colour on a soft teal ground, and heavy **ambient occlusion** pooling in the
> corners and under every object.

The ambient occlusion is the thing. It is what makes the reference read as a
physical object you could pick up rather than a flat cartoon, and it is the
single hardest part to reproduce in real time — see `CONCEPT.md` §9.5.

### This supersedes the Roblox direction

Roblox style is flat, bright, hard-edged and essentially unlit. The clay
direction is soft, warm, rounded and shaded. They are not compatible, and where
older notes conflict, the clay spec wins.

The Roblox-era references were dropped: an urban textured thread (wrong register
entirely), a text-only forum thread (no images at all), and a night-time
ArtStation island (beautiful, but dark, and tagged `#NoAI` by its author).
`03` survives only as evidence that chunky primitives can carry a scene.

### Why the room box suits the game

- No wall ever comes between the camera and a prop.
- The two open sides give a natural home for the back arrow and the music pads.
- Rooms can be modelled and lit independently, then slid in and out as single
  objects — a transition a 4-year-old can follow.

## The Kenney kits are not references — they are the assets

**CC0**: public domain, no attribution required, commercial use fine. One artist
made all of them, so they are already mutually consistent — which solves the
drift problem for free.

They are **geometry, not style**: flat-shaded and hard-edged, so they need
re-materialing and baked ambient occlusion to sit in the clay direction. Still
far cheaper than modelling 340 props.

340 models between the two kits, covering most of what a bakery and a party room
need.

- Food Kit — https://kenney.nl/assets/food-kit
- Furniture Kit — https://kenney.nl/assets/furniture-kit
- Everything at once — https://kenney.nl/assets

Reach for a kit model before modelling or generating anything.
