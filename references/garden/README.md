# De Tuin — prop plates

Modelling references for the garden, generated in the locked faceted style
against the scene reference `../plates/01-cottage-exterior.png`
(`64f0893e-073a-4065-b363-f87687ced11d`), and read directly into
[`app/NinaBakeryPOC/Sources/Garden/`](../../app/NinaBakeryPOC/Sources/Garden/).

Same rule as [`../props/README.md`](../props/README.md) and
[`../ingredients/README.md`](../ingredients/README.md): **generate images for
reference, model the geometry.** Nothing here ships.

All `flux_2` / `pro` / `1k`, one credit each, generated 2026-08-16. Every prompt
is the shared style prompt from [`../REFERENCES.md`](../REFERENCES.md) §3 —
style before subject, prop list short — with the room-box clause swapped for
*"one single object, centred, studio shot, three-quarter view, nothing else in
frame, no scenery"* on everything except the room box itself. All of them ask
text out explicitly: no lettering, no numbers, no labels, no markings.

| File | Job ID | What the model took from it |
|---|---|---|
| `roombox.png` | `297cfb02-3c25-4d2f-bd79-f5813189421a` | Two wall shelves of tinted jars, one rose planter with sunken holes, a **mint** can, a wooden basket in the foreground — the room's own layout, 16:9 |
| `seed-jar.png` | `9b2bc752-dc82-4517-91b8-4c3cc8cc09e4` | An 8-sided body with a chunky faceted lid, seeds filling the lower third |
| `garden-bed.png` | `352121b0-bf9f-4112-a14f-fafc5a098742` | **Four corner posts, two board bands, a soil slab inset, and five holes in a row** sunk into it as rings |
| `watering-can.png` | `9019e23e-0469-4005-9849-7b280bb34e8d` | 8-sided body **wider at the bottom**, loop handle over the mouth, D-handle at the back, straight spout leaving low and rising to a faceted rose |
| `harvest-basket.png` | `29153dec-f462-4c3d-83c7-923e4642fd7b` | A **square** tapered tub, sandy body, mint rim band, rose lining, arched handle of straight segments |
| `sprout-early.png` | `7b044259-69ea-4879-9864-d63d3766d1f8` | A faceted **dome** of earth — not a cone — one thin stem, two flat leaves in a V |
| `sprout-half.png` | `0be87650-6b2d-441a-b346-c1534e6ec39e` | A rosette of six lance leaves splayed low, and a **closed pointed bud** of overlapping petal facets |
| `plant-aardbei.png` | `f72e2d0c-e9aa-4f82-ba78-26dd36842a43` | A low rosette plus one **arched stalk** leaning out with the berry hanging off it — the only plate that hangs its fruit |
| `plant-bosbes.png` | `87ad984b-4e2a-4dcc-a4cb-f6a0c253f1d3` | Upright forked stem, lance leaves, berries standing among them |
| `plant-honing.png` | `1c5d648f-e8ea-4f4e-a3d7-0d1186a29aa5` | **The pot is the flower head**, ringed by a collar of flat hexagonal petals, on a straight stem with two leaves |
| `plant-klaver.png` | `18bed09e-1a71-4c14-b1e2-6d2b01d829fe` | Tall curved stems from a low base, each carrying four heart petals meeting at a hub |
| `plant-wolkenroom.png` | `67214e8c-0c74-412a-acca-97dec930e3a5` | Straight stem, four-leaf rosette, the cloud resting where the flower would be |
| `plant-sterrensuiker.png` | `33f2ee33-f6f1-49a6-a139-99a7ea2a856c` | The star standing upright on the stem, ridge forward |
| `plant-maanstof.png` | `6d804e75-440e-4e51-b7df-14c989728c3f` | The pouch as a seed pod, split open at a narrow neck |
| `plant-veertje.png` | `6332d65a-5f8e-49a0-a1a2-f34439ebeb88` | The feather standing upright, vane on both sides of the shaft |
| `garden-fence.png` | `1234c59c-05af-4af6-b355-014ab9748d8d` | Pointed pickets on **two** rails, gaps you can see through |
| `flower-row.png` | `319afd28-4a6f-4ee5-82e2-ec29ea29d69f` | Flowers at three different heights; petals are flat **chips**, not points, round a chunky raised centre |
| `molehill.png` | `920bcb94-a035-446f-b420-2ce4908958ed` | A wide faceted cone of earth, a round grey head, two dot eyes and a **pink nose** — the nose is the whole character |
| `butterfly.png` | `79fbe2fd-f75a-4b95-9a65-046ec706aef2` | A segmented body, two straight antennae, and **four** flat wings — a big upper and a smaller lower each side |
| `bee.png` | `e8efea5d-ba7e-47bb-ba1f-db5ffc6bb161` | Nearly spherical, in **broad bands**, with two small pale wings and knobbed antennae |
| `garden-tree.png` | `5f33d95f-bcd1-4192-984b-481907562f26` | A **cluster** of a dozen overlapping balls on a straight tapered trunk — not one ball |
| `puddle.png` | `692a809d-e733-420f-adea-e3a0a5edfe7d` | An octagonal pool lying flat, with **concentric stepped rings** inside it |

The door is not here. It is the kitchen's, reused unchanged —
`Sources/Props/Doorway.swift`, from `../props/door.png` — because `ROOMS.md` §9's
three cues were argued once and the way out being where it was last time is
worth more to a 4-year-old than a gate would be.

## What they changed

**The plant became one object with four stages, not four objects.** Setting
`sprout-early`, `sprout-half` and the eight ripe plates side by side, the thing
they share is a *rosette on a mound*: the mound never changes, the stem gets
taller, the leaves multiply, and the fruit arrives last. That is one builder with
a `growth` parameter, and it is what makes watering read as growth rather than as
a swap.

**And the ripe stage carries the kitchen's own ingredient.** Every ripe plate
draws the fruit as a thing sitting on a plant, so the plant is a rosette and a
stem and the fruit is `KitchenProps.token` — the same eight objects the kitchen
uses, four of them modelled in Blender. It is the single biggest saving in the
room, and it is also the best thing about it: what she picks off the plant and
what she drops in the bowl are literally the same object.

**The seed jar came back as glass, and that is the one plate overruled.**
`seed-jar.png` shows the seeds through the side of a clear jar, which is a good
drawing of a seed jar and the wrong prop — `../REFERENCES.md` §1 rules out
transparency outright, and the game's only transparent surface is the kitchen's
running water, an explicit exception for a substance with no other read.
`roombox.png` drew the same jars **opaque and tinted**, and that is what ships:
the body takes the ingredient's colour, so eight jars are told apart by hue the
way the kitchen's six shelf jars are.

It sharpens the props README's rule by one notch. *A plate cannot answer a
question about the room it is not standing in* — and the studio plate reached for
glass precisely because it had no room to be legible in. The room-box plate is
the one that had to solve it, and it did.

**The can is mint, for the same reason.** `watering-can.png` is blush pink and
the bed is rose; `roombox.png` put a mint can in a rose garden, which is the
separation a grey backdrop never has to find. Same call the door's leaf made.

**The fence went where the plate did not put it.**
`../plates/05-garden-roombox.png` runs a fence across the **near open edge**,
which is where her hands come in and where nothing may stand between the camera
and a prop (`../REFERENCES.md` §1). It is on the far-right edge instead — the
same boundary, seen nearly end-on, with nothing behind it to hide.

**Two details were left out on purpose.** The fence's grey bolt heads and the
honey plate's glossy dripping icing: the first is under a screen pixel at this
scale, and the second is a smooth curved surface. Both are the fine detail
`../REFERENCES.md` §1 says fights the style, and the same call the door's four
panels made when they became two.

## Two things worth reusing on the next room's plates

- **Ask for the room box a second time, with the room's own contents in it.**
  `../plates/05-garden-roombox.png` is a lovely garden and it is not this one —
  wrong furniture, no shelves, a fence in the way. One credit spent on a plate
  that draws *the props you are about to build* settles the layout, the colour
  separations and the composition in a single image, and it is the plate the
  studio shots got overruled by twice.
- **A studio shot and a room-box shot disagree, and the room-box shot wins.**
  Twice here — the jar's glass and the can's colour — and once before, on the
  kitchen's door leaf. It is not a flaw in the studio plate: it is that half the
  questions a prop has are about what it is standing next to.
