# Ingredient and toy plates

Modelling references for the six ingredients, the flour sack and the flour
cloud. Generated in the locked faceted style against the scene reference
`../plates/01-cottage-exterior.png`, and read directly into
[`app/NinaBakeryPOC/Sources/Kitchen/KitchenProps.swift`](../../app/NinaBakeryPOC/Sources/Kitchen/KitchenProps.swift).

Same rule as [`../props/README.md`](../props/README.md): **generate images for
reference, model the geometry.** Nothing here ships.

| File | Job ID | What the model took from it |
|---|---|---|
| `aardbei.png` | `b1a81043-8175-4e83-ba36-8ea26e3e3365` | Berry swelling high and coming to a point at the bottom, under six flat pointed leaves splayed out and tipped up |
| `bosbes.png` | `30cc1f22-02f5-4ad0-b827-96821f77a6b4` | Round berry, ~10 sides × 5 rings, with a small five-point crown lying flat on top |
| `honing.png` | `04e14a00-3702-474f-9c8d-e4cb4f48591d` | An 8-sided pot with a wide flat rim, a pool of amber inside, a dipper lying across it |
| `klaver.png` | `0cb4ed0a-bef4-4a94-8a4d-360183be6a0c` | **Four** flat heart leaves, tips meeting at a hub, on a short square stem |
| `wolkenroom.png` | `6f866d0c-79a3-4e13-9480-086d002bb665` | One larger sphere up and back, three smaller around the base |
| `sterrensuiker.png` | `a263ffa0-157f-402c-b40d-6d843415aec7` | Five-point star with a raised centre ridge — two shallow pyramids, not an extrusion |
| `flour-sack.png` | `6ab4baec-55e5-4e2d-ac42-dcf661e6fe7a` | Widest a third of the way up, gathered into a band, cloth fanning open above it, two corners splayed on the floor |
| `flour-cloud.png` | `7c14918b-701f-4408-bd6f-912d2ae764f0` | A cluster of big overlapping lobes ringed by small satellites — not a spray |

All `flux_2` / `pro` / `1k` / 1:1, one credit each, generated 2026-08-15. The
prompt on every one of them is the four style phrases from `CLAUDE.md` — flat
shaded low-poly, visible straight polygon edges, no smooth curved surfaces, no
ambient occlusion pooling — plus the palette, the grey backdrop, and then one
short sentence naming the subject. Style before subject, prop list short, as
`../REFERENCES.md` §3 has it.

## What they changed

**Two of them came back better than the brief.** The clover was asked for three
leaves and returned four, which is the lucky one and the right note for the
ingredient with *tover* in its name; it was kept. The star was asked for a
raised centre ridge and made it the whole structure of the object rather than a
detail on it, which is why `FacetedMesh.star` is a bipyramid rather than an
extruded outline.

**The honey plate settled an argument the game did not know it had.** Honey has
no shape, so the previous model was a yellow hexagonal prism standing in for
it. The plate's answer — put it in a pot and let the pot be the object — is
obvious in hindsight and is why that ingredient is now the most legible of the
six.

**The flour cloud plate is the reason `Sparkles.cloud` exists.** What it shows
is a *cluster* with satellites, not a burst: big lobes that overlap and hold
together while smaller ones drift off the edges. `Sparkles.puff` was throwing
twelve equal spheres on a ballistic arc, which reads as a firework however the
colours are set, and no amount of tuning speed and gravity was going to get
from one to the other.

## Three primitives came out of this

`FacetedMesh` gained `lathe`, `extrude` and `star` to build these. `lathe` is
the one that mattered: a `(radius, y)` profile revolved about Y, with a radius
of zero becoming a single apex vertex rather than a degenerate ring. Four of
the six ingredients, the flour sack's body, its tie and its collar, the crate's
rim and the tap's stream are all profiles now. Six mesh builders would have
been six chances to get the winding wrong.
