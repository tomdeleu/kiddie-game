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
| `08-dribbble-isometric-bakery.png` | [Dribbble — Naomi](https://dribbble.com/shots/21332763-3D-Cute-Isometric-Bakery-made-in-Blender) | © the artist | **Retired anchor** (clay direction). Reference only — never a generation input. |

Do not ship or redistribute anything not marked CC0.

## This folder no longer holds the anchor

> **The agreed direction is now faceted pastel low-poly**, and its anchors are
> the generated plates `../plates/01-cottage-exterior.png` (scenes) and
> `../plates/02-fairy-character.png` (characters). Full spec in
> [`../REFERENCES.md`](../REFERENCES.md).

Everything in this folder predates that decision. It was gathered for two
earlier directions, both retired:

- **The clay direction** — soft matte clay, rounded edges, heavy ambient
  occlusion, terracotta on teal. `08` was its anchor.
- **The Roblox direction** before it — flat, bright, hard-edged, essentially
  unlit. `03` survives from it only as evidence that chunky primitives can carry
  a scene.

The current style is neither: angular and flat-shaded like the Roblox read, but
pastel, evenly lit, and with **no ambient occlusion at all** — the opposite of
what the clay spec called its signature.

Keep the folder for provenance and for the Kenney rows, which are still live.
Prefer the plates for anything about the look.

### Why the room box suits the game

- No wall ever comes between the camera and a prop.
- The two open sides give a natural home for the back arrow and the music pads.
- Rooms can be modelled and lit independently, then slid in and out as single
  objects — a transition a 4-year-old can follow.

## The Kenney kits are not references — they are the assets

**CC0**: public domain, no attribution required, commercial use fine. One artist
made all of them, so they are already mutually consistent — which solves the
drift problem for free.

They arrive **flat-shaded and hard-edged**, which under the clay direction was a
defect needing re-materialing and an AO bake per asset. Under the current
faceted direction it is exactly the target shading model: they need a palette
swap and nothing else.

340 models between the two kits, covering most of what a bakery and a party room
need.

- Food Kit — https://kenney.nl/assets/food-kit
- Furniture Kit — https://kenney.nl/assets/furniture-kit
- Everything at once — https://kenney.nl/assets

Reach for a kit model before modelling or generating anything.
