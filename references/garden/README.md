# De Tuin — prop plates

Modelling references for the garden, generated in the locked faceted style
against the scene reference `../plates/01-cottage-exterior.png`
(`64f0893e-073a-4065-b363-f87687ced11d`), and read directly into
[`app/NinaBakeryPOC/Sources/Garden/`](../../app/NinaBakeryPOC/Sources/Garden/).

Same rule as [`../props/README.md`](../props/README.md) and
[`../ingredients/README.md`](../ingredients/README.md): **generate images for
reference, model the geometry.** Nothing here ships.

**Ten of these plates now feed Blender rather than Swift.** `molehill.png`,
`garden-bed.png`, `garden-fence.png` and seven of the eight `plant-*.png` were
rebuilt as models on 2026-08-16 — [`models/`](../../models/README.md) has what
each one asked for that `FacetedMesh` could not say, and the three things the
garden kept needing that the kitchen did not. `plant-bosbes.png` is the one ripe
plant still built in code.

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
| `puddle.png` | `692a809d-e733-420f-adea-e3a0a5edfe7d` | An octagonal pool lying flat, with **concentric stepped rings** inside it — the two puddles this built were replaced by the pond below on 2026-08-16 |

### The three that replaced the walls

The garden shipped with two plaster walls, because `../REFERENCES.md` §1 gives
every room a room box. Owner's call afterwards: *"it's a bit strange that the
garden has a wall around it."* It was — a garden indoors. These are the plates
for what replaced them.

| File | Job ID | What the model took from it |
|---|---|---|
| `fence-gate.png` | `1b2d0355-ad41-4e02-b927-5bcce35f18f6` | A run of picket fence broken by **two taller square posts with flat pyramid caps**, and a gate leaf of five pickets on two rails with **one diagonal cross-brace**, two strap hinges and a latch |
| `potting-bench.png` | `e7bb0f4d-d791-400e-93a5-2847d7c6e863` | Four square legs, a worktop with a **low backboard**, and a lower shelf that **projects forward of the worktop** so both rows of pots are visible from above |
| `roombox-v2.png` | `c595699f-574c-4f65-bc9a-8f369ee12e98` | The whole garden with no walls: the fence as an **L on the two far edges**, the gate in the left run, the bench against it, a **mint lawn** and a **sandy path at the gate** |

**The brace is the plate's real contribution.** Five vertical boards and two
horizontals are a piece of fence; a diagonal across them is a thing that opens.
It is the one detail that makes the gate read as a gate at 80 mm wide, and it
cost one rotated box.

**The bench's projecting shelf is the other.** The obvious build is a shelf
directly under the worktop, and it does not work: this camera looks down at
about 34°, so it can see under an overhang by roughly one and a half times the
drop, and a pot on a shelf 42 mm below the top would be cut in half by its own
bench. The plate pushes the shelf forward so the lower row stands clear of the
front edge. It is the kitchen's mirrored-shelf problem rotated a quarter turn.

## The room-box plate overruled the studio plates. Again.

**Four times now** in this one room, which makes it a rule rather than an
anecdote.

- **The seed jar** came back as glass; `roombox.png` drew it opaque and tinted.
- **The watering can** came back blush; `roombox.png` put a mint one in a rose
  garden.
- **The ground and the fence** are the third and the biggest.
  `roombox-v2.png` — asked only for "a garden with a fence instead of walls" —
  came back with a **pale mint lawn**, a **cream fence** and a **sandy path**,
  where the room had a cream floor and a rose fence. It is right on the first
  two: with the walls gone the ground became most of the frame, and cream ground
  under a cream fence is one colour. **The path it was wrong about, and the room
  built it anyway** — it went in as the thing that gave the gate somewhere to
  lead now that it has no lit doorway behind it, and came out again on the
  owner's call, 2026-08-17, because on screen it was an unnameable pale blob on
  the lawn rather than ground. Which sharpens the rule this list is about: a
  plate is evidence about **colour and material**, where it has been right four
  times, and not about **what objects the room contains**.

- **The pond's stones** are the fourth, and the quickest to settle: sandy
  boulders on grey in `pond.png`, near-white ones on a mint lawn in
  `roombox-v3-pond.png`. See below.

Every one of those is a question about **what a prop is standing next to**, which
a studio shot on a grey backdrop cannot be asked. So: *ask for the room box a
second time, with the room's own contents in it, and let it win.*


### The pond, and the fourth time the room box overruled a studio shot

Owner's call, 2026-08-16: *"in the garden I would like to see a small pond at
the bottom instead of 2 puddles… make sure there are no other items IN the
pond."* Two plates, one credit each, both against the scene reference.

| File | Job ID | What the model took from it |
|---|---|---|
| `pond.png` | `82db921b-6d49-4a2a-9346-6e6796c7af3d` | **A ring of separate boulders**, not a moulded kerb, round water that **steps down** in three octagonal bands from pale at the rim to deep in the middle |
| `roombox-v3-pond.png` | `1f2e2ba1-7d37-4a22-9885-00f22e49a983` | Where it goes and what colour it is: **front-centre of the lawn**, the can on one side and the basket on the other, **near-white stones** on the mint grass |

**The stones came back sandy in the studio and pale in the room, and the room
won.** That is now the fourth time in this one garden — the jar's glass, the
can's colour, the fence and the ground, and these stones — and the reason is the
same every time: a grey backdrop cannot be asked what the prop stands next to.
Sandy stones beside a sandy bench, a brown soil bed and a cream path would have
been a third brown; `creamLight` on a mint lawn is a rim you can see.

**The room-box plate also settled the placement without being asked.** The
prompt said "at the very front of the lawn"; the plate put the pond dead centre
between the watering can and the basket, which is exactly the pair of props that
already bracket the room's open foreground. That is where it is built.

**What the studio plate contributed that the room box could not** is the
descent: bands stepping *down*. The room-box pond is one flat sheet of water,
which at that size in frame is all it can be, and a flat sheet is what the
puddle already was.

**And then a screenshot beat both plates, twice.** Built from these two, the
pond came out as a 122 mm circle in the middle of the near floor; the owner drew
over a screenshot of the running room in red — *"the pond must be bigger and
totally at the bottom"* — and it became a 196 mm oval along the front edge; a
second red line — *"it must stretch to the side of the plateau at the bottom
left right, and the shape must be irregular"* — made it the 249 mm irregular
pool that runs off both near edges of the lawn.
Neither plate could have said either of those, and the reason is the same one
the room-box plate keeps proving one step further on: **a plate cannot be asked
how big a prop should be, or where it should stop, in a room it has never been
photographed in**. The room box gets
the placement and the colour right because it draws the neighbours; only the
room itself, running, can be asked about scale. Worth remembering as the party
and the wall get built: *the last plate is a screenshot*.

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
