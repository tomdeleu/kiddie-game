# Moodboard — provenance and licence

Page screenshots captured via the Firecrawl connector. Full method and the
things that do not work: [`../FETCHING-ASSETS.md`](../FETCHING-ASSETS.md).

**Read the licence column before using anything.** Only the Kenney kits are
free to put in the game.

| File | Source | Licence | Use |
|---|---|---|---|
| `03-devforum-lowpoly-with-blocks.png` | [devforum 278566](https://devforum.roblox.com/t/how-to-create-a-low-poly-lookvibe-using-roblox-studio-blocks/278566) | © respective posters | **Reference only.** The agreed direction — see below. |
| `04-kenney-food-kit.png` | [kenney.nl](https://kenney.nl/assets/food-kit) | **CC0** | **Use directly.** 200 models. |
| `05-kenney-furniture-kit.png` | [kenney.nl](https://kenney.nl/assets/furniture-kit) | **CC0** | **Use directly.** 140 models. |
| `06-unity-cute-bakery-building.png` | [Unity Asset Store](https://assetstore.unity.com/packages/3d/environments/low-poly-cute-bakery-building-229785) | Unity EULA | **Reference only** — free, but the EULA ties it to Unity projects, and we are on RealityKit. |
| `07-cgtrader-floating-island-house.png` | [CGTrader](https://www.cgtrader.com/free-3d-models/exterior/other/stylized-low-poly-floating-island-with-small-house) | Royalty-free, **no AI** | Model is free to download and use. Do **not** feed it to an image generator. |
| `08-dribbble-isometric-bakery.png` | [Dribbble — Naomi](https://dribbble.com/shots/21332763-3D-Cute-Isometric-Bakery-made-in-Blender) | © the artist | **Reference only.** |

Do not ship or redistribute anything not marked CC0.

## The agreed direction

Two files were dropped after review: an urban, textured, dimly-lit Roblox thread
(wrong register entirely), and a night-time ArtStation floating island — lovely,
but dark, and tagged `#NoAI` by its author.

What survived has a consistent shape, and it is more specific than "low poly":

> **A small, bright diorama sitting on its own floating base**, built from simple
> primitives, in smooth matte plastic and cheerful saturated colour, viewed from
> a fixed three-quarter angle.

That is the look to hold every asset against.

### Why this matters beyond mood

The diorama-on-a-plinth framing is not just a style, it is a **structure that
suits the game**:

- Each room becomes a self-contained object rather than a walled interior, so
  there are no walls to clip the camera or hide props behind.
- The fixed three-quarter angle is already the plan — the reference and the
  interaction model agree.
- Moving between rooms can be a plinth sliding out and the next sliding in,
  which is legible to a 4-year-old in a way a cut or fade is not.
- Each plinth can be modelled and lit independently without matching a
  neighbouring room's geometry.

Worth carrying into `CONCEPT.md` §4 when the hub is built: the bakery is a
cluster of little floating dioramas, not a cutaway house.

## The Kenney kits are not references — they are the assets

**CC0**: public domain, no attribution required, commercial use fine. Low-poly,
flat matte colours, and one artist made all of them, so they are already
mutually consistent — which solves the drift problem for free.

340 models between the two kits, covering most of what a bakery and a party room
need.

- Food Kit — https://kenney.nl/assets/food-kit
- Furniture Kit — https://kenney.nl/assets/furniture-kit
- Everything at once — https://kenney.nl/assets

Reach for a kit model before modelling or generating anything.
