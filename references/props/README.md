# Prop references

Concept plates for the kitchen props, generated in the locked faceted style
against the scene reference `../plates/01-cottage-exterior.png`. They are
**modelling references** — the geometry in
`app/NinaBakeryPOC/Sources/RoomBuilder.swift` was built from them.

| File | Job ID | Reads as |
|---|---|---|
| `oven.png` | `fd306e12-6e28-4e27-9e24-852af52746f9` | Faceted dome, ~8 sides × 4 rings, plus a block arch |
| `bowl.png` | `1c744ca8-9561-4e9c-85d9-a65a681a4ea1` | Tapered prism, ~12 sides |
| `table.png` | `ea575cad-2979-402c-b618-c8dbd95c8a64` | Four box legs, thick slab top |
| `jar.png` | `4bf27563-db0c-4ec6-b1f3-c2db51516f05` | 8-sided prism with a flat lid |
| `door.png` | `48e60b5b-983a-41ed-93c3-e9d7ab81b72b` | Rose frame, panelled leaf, one round knob — seven boxes and a prism |
| `door-wood.png` | `85ea4c38-3e24-4ad1-9574-2677572a784c` | The same door with a sandy-wood leaf, which is the colour that shipped |
| `crate-a.png` | `02a7fdf5-806d-4945-9d21-7affb52f6e8d` | **Four corner posts, three board bands, an inner floor** — the one that was modelled |
| `crate-b.png` | `158315de-d943-4831-b8ae-cb02d16c8cfa` | The same crate, airier: more rails, thinner boards |
| `sink-tap.png` | `72d1dced-caae-4bb2-8fb1-4c09e7c5f3ea` | **Square post, spout mitred down over the basin, octagonal handle**, and a basin with a real rim |
| `cake.png` | `f0e0d4f7-bf18-450c-94ab-af6e13ed86c3` | **Icing dripping over each tier, a ring of pearls, a cherry with a stem** |
| `scale-a.png` | `53dfc7fa-35be-45b9-a8a9-d47bbac1cf48` | **A fat coin dial on a neck, a pan with a rim, a plinth** — the one that was modelled |
| `scale-b.png` | `5a44cc65-ee11-4471-8ca4-56001c8bdb35` | The same scale, slighter: smaller dial, smaller pan, a longer body |
| `spoon.png` | `44b854e8-bbee-4e06-b523-cb86367c40ea` | **A deep round bowl with a thin rim, one straight handle off the rim widening to a flat cut end** — the owner's photograph, put into the game's look |

All `flux_2` / `pro` / `1k`, prompt and seed on the job record. The style prompt
is in [`../REFERENCES.md`](../REFERENCES.md) §3.

The useful thing about these plates is that they name their own facet counts.
"~8 sides × 4 rings" is directly the arguments to `FacetedMesh.dome`.

## The crate — the first plate that fed a Blender model rather than code

Both variants came back on one prompt, and they differ in exactly one way:
how many boards. `crate-a.png` has three chunky bands and reads instantly;
`crate-b.png` has more, thinner rails and reads as fine detail, which
[`../REFERENCES.md`](../REFERENCES.md) §1 says fights the style at this size.
**A is the model**, and B is kept because the disagreement is the useful part
of generating two.

Unlike every plate above it, this one was not built into `FacetedMesh` code —
it went to `models/crate.py`. The reason is in the plate itself: it names four
corner posts with boards spanning between them and gaps you can see through,
and there is no profile, lathe or tapered prism that says *joinery*. The prop it
replaced was a four-sided `bowl` with a ring on top, which reads as a plastic
tub. See [`../../models/README.md`](../../models/README.md).

## The sink and the cake — plates generated to be modelled

Both were made the same way and for the same reason, and both name their own
parts, which is what a plate is for:

- **`sink-tap.png`** gives the tap a square post, a spout that leaves it and
  turns down over the basin at a hard mitred angle, and a chunky faceted
  handle. It also draws the water — a faceted stream and a pool — but **only
  the tap and basin were modelled**; `KitchenProps.sink` still builds the water
  in code, and `models/sink.py` says why at length.
- **`cake.png`** gives the payoff object its icing, its pearls and a stem on
  its cherry. It came back with two tiers where the game needs three; three is
  what `CakeSpec.tierColours` paints, so the model takes the construction and
  not the count — the same call the door made about its four panels.
- **`scale-a.png`** and **`scale-b.png`** disagree about weight, and A wins for
  being bolder: a dial nearly as wide as the pan, a pan deep enough to hold
  something, and a plinth. B's parts are all a size smaller, which is the same
  fine-detail trap the crate's B variant fell into.

**`spoon.png` is the first plate made from a reference the owner supplied** —
a photograph of three turned wooden scoops. The prompt describes that shape and
the plate puts it in the game's look, so what the model works from is on-style
and on-file rather than a photograph of real beech. The photograph itself is
not in the repo; `models/spoon.py` carries the shape.

**It is the second plate for this prop, and the first was thrown away.** That
one drew the spoon standing on end, handle down and bowl up, because the prompt
asked for it that way — and a prop drawn in a pose the game never shows is a
prop you model by inference. This one asks for the three-quarter view the room
actually sees, with both the hollow and the whole handle visible, and the model
came out of it directly. Only this render is kept; asking for the pose the game
uses is the lesson.

Note what was asked *out* of these prompts as much as what was asked in: no
numbers, no lettering, no dial markings. `CONCEPT.md` §5 forbids text she has
to read, and a plate that comes back with a numbered dial is a plate that
invites a modeller to put text in the room.

## The door — two plates, because the leaf colour is a room decision

Four variants came back on one prompt (3:4, the two others are
`92c33909-5382-4ba5-9b9c-44300e1bb1a9` and
`5eac83fd-7a27-4599-b79c-cc8c864c0909`), and they disagreed on one thing only:
whether the leaf is cream or wood. `door.png` has the cleaner construction —
four panels ringed in rose, a knob that reads round — and `door-wood.png` has
the right colour.

The model takes the construction from one and the colour from the other,
because a plate is rendered on a grey backdrop and the prop is not: the kitchen's
left wall is `Palette.cream`, so a cream leaf in a rose frame reads as a picture
frame hung on the wall rather than a hole through it. **A plate cannot answer a
question about the room it is not standing in** — worth remembering for every
prop after this one.

The modelled door also drops to two panels from the plate's four. At 74 × 140 mm
against this camera, four panels is the fine detail
[`../REFERENCES.md`](../REFERENCES.md) §1 says fights the style; two is the same
idea, bigger.

## `oven.glb` — the image-to-3D experiment, and why it failed

`generate_3d` (`image_to_3d`, **20 credits**) was run once on `oven.png` to test
whether Higgsfield can supply geometry rather than just reference. It cannot,
for this style.

| | Generated `oven.glb` | `FacetedMesh.dome(sides: 8, rings: 4)` |
|---|---|---|
| Faces | 26,780 | 56 |
| Median adjacent-face angle | 5° | large and regular |
| Watertight | no | yes |
| Faces after aggressive decimation | floors at 2,053 | — |

The reconstruction gets the **silhouette** right and then destroys the thing
that defines the look. A 5° median crease is a smooth surface; this style needs
large deliberate facets. Quadric decimation does not rescue it — it bottoms out
around 2,053 faces and the creases that survive are irregular and scattered, so
it reads as a damaged smooth mesh rather than a low-poly one.

**Rule: generate images for reference, model the geometry.** For primitives this
simple, code is faster than a modelling round-trip and gives exactly the facet
counts the style asks for.

`generate_3d` may still earn its 20 credits on something genuinely organic — a
character body, where the rig only splits off the legs — but not on a dome, a
jar or a table.

The GLB is kept as evidence, not as an asset. It is not in the app bundle.
