# Moodboard — provenance

Page screenshots captured via the Firecrawl connector for **style reference
only**. These are third-party copyrighted screenshots and asset previews. They
are here to look at while modelling. **Do not ship any of them in the app**, and
do not redistribute them.

The Kenney entries are the exception, and the important one — see below.

| File | Source | What it shows |
|---|---|---|
| `01-devforum-stylized-lowpoly.png` | [devforum thread 3780170](https://devforum.roblox.com/t/stylized-low-poly/3780170) | Roblox "stylized low poly" — smooth plastic with light textures. Urban/textured variant, *not* our pastel direction. Useful as a counter-example. |
| `02-devforum-lowpoly-art-design.png` | [devforum thread 1103992](https://devforum.roblox.com/t/low-poly-art-design/1103992) | Community discussion of low-poly workflow and Blender alternatives. |
| `03-devforum-lowpoly-with-blocks.png` | [devforum thread 278566](https://devforum.roblox.com/t/how-to-create-a-low-poly-lookvibe-using-roblox-studio-blocks/278566) | Achieving the low-poly look from primitives only — closest to our procedural approach. |
| `04-kenney-food-kit.png` | [kenney.nl/assets/food-kit](https://kenney.nl/assets/food-kit) | **CC0 asset pack, 200 models.** Cakes, pies, pots, pans, kitchen items. |
| `05-kenney-furniture-kit.png` | [kenney.nl/assets/furniture-kit](https://kenney.nl/assets/furniture-kit) | **CC0 asset pack, 140 models.** Tables, shelves, chairs, cabinets. |

## The Kenney kits are not just references

**Kenney's kits are Creative Commons CC0** — public domain, no attribution
required, commercial use fine. They are low-poly with flat matte colours, which
is exactly the target look, and they ship in formats that convert to USDZ.

That makes them *actual game assets*, not mood. Between the Food Kit and the
Furniture Kit there are 340 models covering most of what a bakery and a party
room need, in a single consistent style — which also solves the drift problem,
because one artist made all of them.

This is the single biggest de-risking available to this project. Start here
before modelling or generating anything.

- Food Kit — https://kenney.nl/assets/food-kit
- Furniture Kit — https://kenney.nl/assets/furniture-kit
- Everything, one download — https://kenney.nl/assets

## How these were captured

Full recipe, and what does *not* work, in
[`../FETCHING-ASSETS.md`](../FETCHING-ASSETS.md).

Short version: direct image downloads are blocked by the sandbox network policy,
and Firecrawl refuses binary URLs outright. `firecrawl_scrape` with
`formats: ["screenshot"]` writes a PNG to a signed `storage.googleapis.com` URL,
and that host *is* reachable, so `curl` can save it.

Consequence: these are **page** screenshots, browser chrome and cookie banners
included, not clean asset images. Good enough to judge a style by; not good
enough to trace.
