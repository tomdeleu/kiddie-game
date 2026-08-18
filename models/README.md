# Models — props built in Blender

**A second way to make a prop.** Everything in the kitchen is built in code by
[`FacetedMesh`](../app/NinaBakeryPOC/Sources/FacetedMesh.swift): a profile, a
side count, a mesh. That stays the default — it is quick to tune, it costs
nothing to ship, and a prop whose shape is eight numbers in a Swift file is a
prop anyone can adjust without opening anything.

This folder is for the shapes that vocabulary cannot reach.

| | |
|---|---|
| `lowpoly.py` | The shared rules: flat shading, palette colours, ring/bridge/tube/box builders, the AO bake, and the export. A prop script is then only its shape. |
| `feest-scene.py`, `feest-ao.py` | **The odd pair out: they build no prop.** The first stands the *whole disco* up at the game's own coordinates — shell, tiles, props, guests, camera and the five lights — and the second measures ambient occlusion against it. They are the 2026-08-18 AO investigation; its findings and its verdict are in [`app/AMBIENT-OCCLUSION.md`](../app/AMBIENT-OCCLUSION.md). Neither exports anything. |
| `beertje.py`, `dj-headphones.py` | Het Feest's cast: eleven complete species sharing one teddy-bear construction, plus the separate baked headset worn by whichever friend is DJ today. Both preserve `GuestCharacter`'s head/arm/leg pivots. |
| `garden.py` | **De Tuin's own vocabulary**, on top of `lowpoly.py`: a pointed lathe, a folded leaf, a swept curve, an arbitrary-section column, a chamfered octagon, and the plant anatomy the seven plants share. Nothing outside the garden imports it. |
| `flour-sack.py`, `bosbes.py`, `crate.py`, `klaver.py`, `sink.py`, `cake.py`, `scale.py`, `veertje.py`, `maanstof.py`, `spoon.py` | De Keuken's ten. Run one to rebuild and re-export it. |
| `molehill.py`, `garden-bed.py`, `garden-fence.py`, `plant-*.py` × 7 | De Tuin's first ten. |
| `garden-tree.py`, `harvest-basket.py` | De Tuin's other two, added 2026-08-17. |
| `*.blend` | The same things, openable. **Not the source of truth** — a convenience for looking at and for nudging a number before it goes back into the `.py`. |
| → `app/NinaBakeryPOC/Resources/Models/*.usdz` | What ships. |

## Running it

```
blender --background --python models/flour-sack.py
blender --background --python models/bosbes.py
blender --background --python models/crate.py
blender --background --python models/klaver.py
blender --background --python models/sink.py
blender --background --python models/cake.py
blender --background --python models/scale.py
blender --background --python models/veertje.py
blender --background --python models/maanstof.py
blender --background --python models/spoon.py

blender --background --python models/molehill.py
blender --background --python models/garden-bed.py
blender --background --python models/garden-fence.py
blender --background --python models/plant-aardbei.py
blender --background --python models/plant-honing.py
blender --background --python models/plant-klaver.py
blender --background --python models/plant-maanstof.py
blender --background --python models/plant-sterrensuiker.py
blender --background --python models/plant-veertje.py
blender --background --python models/plant-wolkenroom.py

blender --background --python models/garden-tree.py
blender --background --python models/harvest-basket.py
```

Each writes its USDZ and saves its `.blend`. Add `-- --no-save` to export
without touching the `.blend`. Blender 5.2 LTS; the export is deterministic, so
re-running with no edits produces the same geometry.

**The same geometry, but not the same file.** A USDZ is a zip and a zip carries
timestamps, so rebuilding a prop with no edit at all still changes its hash —
measured on `garden-fence`, twice in a row, 2026-08-18. Two consequences, and
both have already caught someone out: `git status` after a rebuild is **not**
evidence that a prop changed, and a prop rebuilt only to check something should
be put back with `git checkout` rather than committed.

The `.py` is authoritative on purpose. A `.blend` is a binary a diff cannot
read and a session cannot review, and a prop whose shape only exists inside one
is a prop that can only be changed by the person with Blender open.

## What is here, and why each one earned it

A prop belongs here when the plate asks for something the code cannot say — or,
when what the plate asks for was never built at all. All twenty were chosen on
that test, not because modelling is nicer.

**One prop is deliberately half here and half in code**: the sink. Its tap is
modelled; its water is not. `models/sink.py` has the argument, and it is the
clearest statement of where the boundary of this folder is.

### The flour sack

`references/ingredients/flour-sack.png` has two things the code version could
not do, and they are the two things that say *cloth*: **vertical gather folds**
pinching into the tie, and a **pleated crown** of cloth fanning open above it.
The procedural sack is four stacked lathes and two wedges, and it reads as a
bag with a collar rather than as a bag that has been gathered and tied.

The lathe can spin a profile; it cannot make alternating verts ride high and
wide with the ones between tucked low, which is what a pleat is. So the sack
grew a `jitter` that alternates each ring's radius vertex by vertex and grows
towards the neck, and a collar built vertex by vertex rather than revolved.

**The code version is still there**, as `KitchenProps.proceduralFlourSack`, and
still runs in two cases: the USDZ missing from the bundle, and the debug
panel's flat-shading toggle turned off. Both are deliberate — see the doc
comment on `KitchenProps.flourSack`.

### The toverbosbes

`references/ingredients/bosbes.png` asks for three things at once:

- **A faceted globe** — fourteen columns by eight bands, small quads all over.
  The lathe gives broad vertical panels and a pole at each end, which is a
  different object: panels read as a carved bead, a grid reads as a berry.
- **A calyx.** The plate sinks a shallow crater into the top and stands the
  crown in it. One lathe profile cannot make a dish and a dome.
- **A crown of five sharp spikes, standing up.** Not the flat extruded star
  lying on top that the code version has, which reads as printed on the berry.
  That crown is the whole difference between a blueberry and a blue marble.

**The crown took three goes, and the mistake is worth keeping.** The first was
folded down onto the berry; the second stood up but put the peak in the middle,
which is a cone with notches cut in it — the five spikes get absorbed into one
silhouette and it reads as a little hat. The plate does the opposite: **the
centre is the low point**, and each spike runs from that dip up and outward to
a tip at the rim. That is what puts a hard ridge down every spike and a deep V
between each pair, and that is where "pointy" comes from.

Same two fallbacks as the sack: `KitchenProps.buildProceduralBlueberry`.

### The crate

**A different reason from the other two.** The sack and the berry were shapes
the `FacetedMesh` vocabulary could not say. The crate is a shape nobody built:
the code version is a four-sided `bowl` with a lathe ring on top — a tapered
tub with a rim, which reads as a plastic bucket — and no tuning of three
numbers turns a solid tub into something made of boards.

A crate is *joinery*: four corner posts, boards spanning between them, and gaps
you can see through. That is a dozen boxes, and boxes are exactly what
`lowpoly.add_box` makes cheap. Several of them go into one bmesh and still form
a closed mesh, so the whole crate is two objects — `CrateBoards` in cream and
`CratePosts` in sandy wood, which is how `references/props/crate-a.png` paints
it.

**It is built axis-aligned, and the Swift side drops its 45° turn to match.**
The old crate is a 4-sided prism, whose vertices sit on the axes and whose faces
therefore run diagonally, so it had to be spun to put a flat face square to the
room. A box needs no correction: the fixed camera looks down the +X+Z diagonal,
so an axis-aligned crate already shows two sides and the corner post between
them — the plate's own view. Turning it as well would put a flat side to the
camera and lose the inside.

It is bigger than what it replaced — 46 mm across the flats where the tub was
37 — so `KitchenRoom` widens its contact shadow to match. The token that waits
in it is placed by `Layout` at 17 mm and needed no change.

This is also the first plate in `references/props/` that fed a model rather
than code, and it was generated for the job: two variants, one prompt, and they
disagreed only about how many boards. The chunkier one won.

### The toverklaver

`references/ingredients/klaver.png` asks for one thing the code cannot do: **the
fold**. `FacetedMesh.extrude` makes a flat slab — one front face, one tone,
however many sides the outline has — and every petal in the plate is creased
along its midline, so its two halves catch the light differently. That crease is
the difference between leaves and four stickers on a stick.

The code version compensates by painting alternate petals `sage` and `sageDeep`,
which is a tint standing in for a shape. With a real fold the facets do that
job, so the model is **one colour** — which is also what the plate shows.

**Four petals, not the plate's five.** That decision is already recorded on
`KitchenProps.buildClover`: a four-leaf clover is the lucky one, the right note
for the ingredient with *tover* in its name. A plate is the brief for the shape,
not for the count.

One thing it caught: the stem has to sit **behind** the petals. The crease
stands proud towards the viewer and the petal edges sit on zero, so a stem on
the axis draws a stripe down the front of the two lower leaves.

### The sink, and where this folder stops

**The tap is modelled and the water is not**, and that split is the most useful
thing in this file. The tap earned the trip — the plate has a square post, a
spout mitred down over the basin and a chunky handle, against a code version
that is two prisms meeting at a right angle. The water did not:

- It is **animated by scaling one axis** — the stream grows down its own Y, the
  pool rises up its own Y. An imported prop hangs under the exporter's
  Z-up-to-Y-up rotation, so a child's local Y is not the world's, and driving
  those off a model would bury an axis-swap inside an animation.
- It is the **one transparent surface in the game**, and the palette is
  re-applied on load as opaque matte.
- **There is no facet the lathe cannot already make.** A stream's look is its
  material and its motion.

That last one is the test, and it is the test every prop here has to pass.

The tap is also the first modelled prop with a front and a back, which is how
**Blender +Y is the game's −Z** got established: the exporter's rotation maps
(x, y, z) to (x, z, −y), so the first tap came out standing between its own
basin and the camera.

### The cake

The payoff object — what the round is for, what goes on the plank, what ends up
in a frame. The code version is three prisms and a ball. The plate names three
things that turn a stack of discs into a cake, none of them a profile a lathe
can spin: **icing dripping over each tier**, a **ring of pearls** where one tier
stands on the next, and a **cherry with a stem**.

Everything the round varies still varies, which is the constraint the model was
built to: the tiers are separate meshes so `CakeSpec.tierColours` still paints
one, two or three colours; the trimmings are separate so they stay cream
whatever the tiers do; `isTall` is a Y-scale on the upright wrapper; and `glows`
swaps the material function rather than the mesh.

Two shapes took a second go, both for the same reason — **a single deepest
vertex is a point, and neither icing nor a pearl comes to a point**:

- The drip hem was a sawtooth. It is now four segments per scallop on a
  `sin ** 0.6` curve, which fattens the belly of each drip and pinches its neck.
- The pearls were pyramids. They are now squashed and six-sided rather than
  tall and four-sided.

### The scale

The code version is a box, a disc and a tilted prism: three parts standing near
each other rather than one object. The plate says what a scale needs, and none
of it is subtle — a dial that is **a fat coin on a neck** rather than a disc
leaning on the base, nearly as wide as the pan and carrying the whole
silhouette; a **pan with a rim**, deep enough to hold something; and a
**plinth**, which is what stops a box reading as a box.

It is the second prop with a front and a back, so it uses the tap's rule: the
dial goes at positive Y in Blender to stand at the back, and faces −Y to look
out into the room. It is built with no turn applied, because the camera looks
down the +X+Z diagonal and a prop facing +Z is already being seen
three-quarter — the plate's own angle.

**It is also the first modelled prop with a moving part**, and that turned up
two things worth keeping:

- The pan bounces by moving along Y, and everything inside a loaded prop hangs
  under the exporter's up-axis rotation, where local Y is the world's Z. An
  unpivoted pan slides sideways through the base rather than dipping.
  `ModelLibrary.pivot` hangs the part on an upright holder to fix it.
- That pivot has to take the part's **baked-occlusion siblings** with it. The
  bake splits occluded faces into `…ShadeN` meshes, so moving only
  the mesh you asked for bounces the pan and leaves its shading hanging in the
  air where the pan used to be.

### The toverveertje

The clover's gap again, for the clover's reason: **the fold**. A vane rises from
its shaft on both sides, and a flat extrusion has one front face and one tone.

Two decisions here come from the code rather than from the plate, which is
worth stating because it is the general rule: **a plate is a brief, not an
instruction.** The plate came back with barbs notched into the vane — at 20 mm
those are sub-millimetre teeth — and with a near-symmetrical blade, where a
feather's vane is fuller on one side of its shaft. `KitchenProps` already
argued both; the model keeps them.

It took three goes, and the two failures were the same failure: **it kept
reading as a leaf on a stick.** What fixed it was proportion rather than
detail — the vane belongs in the upper two thirds with bare quill below, and
the shaft has to sit *in front of* the crease where you can see it, not inside
the fold where it disappears. It is still the weakest of the ten; a next pass
would give the vane a slight sweep rather than a straight axis.

### The maanstof pouch

Moon dust is read through its pouch, which is the lesson the honey pot taught:
a substance with no shape of its own is read through its container. So the prop
is cloth, and cloth is where the vocabulary stops — the same two things the
flour sack needed, at a quarter of the size.

**Its real job is not looking like the flour sack.** At thumbnail size two
props of one family have to differ in silhouette or they are one prop in two
colours. The sack is squat, settled and wide with corners splayed on the floor;
the pouch is round-bellied and narrow-necked, gathered high rather than low, and
the cloth above its cord stands in **uneven** points where the sack's collar is
an even pleated crown — three lengths cycling rather than two alternating.

### The spoon

A **scoop**, from a photograph the owner supplied of three turned wooden ones,
by way of `references/props/spoon.png` — that shape in the game's look. A deep
round bowl with a thin rim, and one straight handle leaving the rim
horizontally, widening a little to a flat cut end. No waist, no neck, no butt
cap: nothing tapers into anything.

Two things the code cannot do, and one it got wrong:

- **A round scoop.** `FacetedMesh.bowl` is the vocabulary's only double-walled
  primitive and its walls are straight, so the code spoon's bowl is a tapered
  cup where the reference is a round hollow. Its rim is a fat band; this one's
  is a 1.5 mm edge.
- **One continuous handle**, rather than a tapered prism with a separate butt
  piece seamed onto its end.
- **The handle came out of the middle of the bowl.** In the code version the
  neck sits at y = 0.003 and the handle at 0.009, inside a cavity whose floor is
  0.003 and whose rim is 0.012 — the handle rises straight through the bowl, and
  the prop reads as a goblet.

#### The two poses, and why the root is rotated

This is the only prop the room orients two ways, and it is what made the first
attempt hard. `KitchenRoom.refreshLayout` lays the spoon on the table by tipping
it 81.8° about the game's X, and stands it in the bowl to stir with **identity**
— so the pose that gets no rotation is the upright one. That is why the code
version is built standing, and it is why a first pass that simply reshaped the
bowl and hung the handle off its back never looked like the picture: it was
being authored in the pose nobody draws.

The fix is to model it lying, exactly as the reference draws it, and give the
**root minus the room's tip**. The room's rotation cancels it, so the resting
pose is the modelled one and the stirring pose is that same spoon stood on its
handle. Authoring matches the picture and the game keeps both poses.

Two consequences worth knowing before doing this to another prop:

- A turn of θ about the game's X is a turn of **+θ about Blender's X**. Getting
  that sign backwards renders the prop upside down and costs an iteration.
- The room parks the spoon 6 mm clear of the table, which the standing build
  needs because its bowl swings below its own origin when tipped. A prop
  modelled lying is already on zero, so it would hover; the parts are dropped
  6 mm **inside the root**, where the inverse tip puts that offset in the
  resting frame and keeps it vertical.

It is also the one prop where the occlusion bake wanted a *longer* reach than
the rest — 5.5 mm. At 2.5 and 4 it found nothing, which is the honest answer for
a shape this open: the handle leaves the rim along a tangent instead of burying
itself in the bowl, so there is barely a crevice to find.

## De Tuin's twelve

The garden went second, and it went differently: De Keuken picked ten props one
at a time, each because that one plate asked for one thing the vocabulary could
not say. The garden's first ten were asked for as a batch — the molehill, the
bed, the fence and seven of the eight ripe plants — so the useful question was
not *which prop* but **what does this room keep needing that the last one did
not**. There were three answers, and they are `garden.py`. The tree and the
basket came a day later, one at a time again, and are at the end of this
section.

### What the room needed, three times over

- **The fold, thirty times.** Every plate in `references/garden/` creases its
  leaves down the midrib, and `FacetedMesh.extrude` makes a slab with one front
  face and one tone. It is exactly the clover's gap — but a bed grows five
  plants with six leaves each, so the thing that was one prop's problem in the
  kitchen is the whole room's here. `garden.leaf` is the clover's petal
  generalised: two fans meeting on a crease, solidified.

  It settles a colour question at the same time. `GardenProps.plant` paints
  alternate leaves `sage` and `mint` because a slab needed the difference
  painted on; with a real fold the facets do it, so **every leaf in these ten
  models is one colour**, which is what the plates show.

- **The bend.** `plant-aardbei.png` hangs its berry off an arched stalk and
  `plant-klaver.png` grows two curved stems out of one crown. There is no bend
  in the vocabulary at all: the code fakes the first with three rotated boxes
  and does not attempt the second. `garden.sweep` carries a polygon along a
  path, and the arch is the single biggest visual difference between the model
  and the code in the whole batch.

- **A point on the end of things.** A strawberry, a seed pod's teeth, a picket,
  a post cap. `lowpoly.tube` closes a solid out of rings, and a zero-radius ring
  is eight vertices in the same place — eight degenerate triangles the bake
  reads as facing every direction at once. `garden.lathe` collapses an end
  station to a single apex vertex.

### One shape, so five plants are one garden

The seven plants are `garden.plant_base` — mound, rosette, stem — plus whatever
their plate hangs on top, and the numbers are `GardenProps.plant`'s to the
millimetre. That matters twice. **Five grow at once**, and five silhouettes that
share nothing are five different games rather than one garden. And **only the
ripe stage is modelled**: stages 0–2 stay in Swift, so the mound the model
stands on has to be the mound they leave behind, or the last sweep of the
watering can would move the earth.

| | What its plate asked for that the code could not say |
|---|---|
| `plant-aardbei` | The arch. The berry hangs off a bent stalk clear of the rosette, and there is no straight stem at all — in the plate the stalk *is* the stem |
| `plant-honing` | The pot **is** the flower head, ringed by a collar of flat petal chips. A ring of points is a star; a ring of chips is a sunflower |
| `plant-klaver` | **Two** heads on two curved stems out of one crown, which a single straight prism cannot even approximate |
| `plant-maanstof` | The pouch as a seed pod, **split open** into a crown of pointed teeth with the dark inside showing |
| `plant-sterrensuiker` | A ridge running from the centre out to every tip, so each arm is two facets. `FacetedMesh.star` extrudes an outline and its whole front is one tone |
| `plant-veertje` | The clover's fold on a vane that rises from its shaft on both sides |
| `plant-wolkenroom` | Six lobes in **one mesh**, so the seams where they push into each other can be measured. Four separate spheres cannot be measured against each other at all |

**`plant-bosbes` is not here.** It was not in the batch that was asked for. The
plate exists, the anatomy is shared, and it is one short script — until then that
one plant is built the old way and its leaves alternate two greens where the
other seven are one.

### The molehill, and a bug the model had to fix

`GardenRoom.tapMolehill` lifts Mo to y = +0.0135. His head sat at his pivot's own
origin with a radius of 9.2 mm against a hill 19.5 mm high, so **at full pop the
head cleared the earth by 3.2 mm and the nose — which hangs 1.6 mm below the
head's centre — never came up at all.** The toy was a grey sliver.

It is fixed in the model, by building Mo 11.2 mm up his own pivot, and that
choice is the point: the room's two tween positions are gameplay numbers that
have been played against, and what was wrong was the thing they were moving. At
−14 mm he is still completely inside the hill, which is the other half of what
those two numbers have to be true about.

The plate's other two contributions are a **convex** hill — loose earth pushed up
from below flares at the foot and rolls over at the crown, where the code's
tapered prism is a lampshade — and **two paws** resting on it, which are what
turn a ball with a nose into an animal leaning out of a hole. The paws took one
render to place: they have to be *outside* the hill, not merely below the head,
and the hill is 19 mm across at the height they sit at.

### The bed, and a hole without a boolean

Three things off `garden-bed.png`: **two board bands** with a groove between
them rather than one 40 mm slab, **posts standing proud** of the boards rather
than flush with them, and **holes with a wall**.

The last one is the interesting one. A hole through a slab is a boolean, and a
boolean on a flat-shaded low-poly mesh hands back a fan of triangles where there
was one facet — the whole style, gone, in the one prop the room's required
action happens on. So the soil sits 3 mm lower than `GardenLayout.bedSoilY` and
each ring stands 2.2 mm above it: what she looks down into is a 5 mm well with a
lit rim and a floor, made of nothing but **two convex solids that happen to
overlap**. The plant still grows at `bedSoilY`, which puts its mound's foot
inside the ring.

Its one modelling trap is worth stating on its own: **a ring is four bands
bridged in a loop, not a tube capped with a disc at each end.** The capped
version is a solid with its own inside doubled back through it, which the
winding pass cannot recalculate and the bake reads as a face buried in geometry.

### The fence, which is the room's boundary rather than a prop in it

**The whole L, in world coordinates, dropped at the origin** — the only model in
the game that is not a thing standing somewhere. `garden-fence.py` computes the
same post positions, the same 19 mm picket spacing and the same gate gap that
`GardenRoomBuilder.addRun` does, deliberately as a transcription of it, and the
payoff is that forty-odd pickets, eleven posts and six rails stop being
forty-odd entities: three meshes carry the lot.

From the plate: **chamfered pickets**. The code cuts a flat board, which gives a
picket two faces and both of them flat; turned timber with the corners taken off
gives it four. The footprint is unchanged, so the 11 mm gap between pickets —
the thing that makes this a fence and not a low wall — is unchanged too.

Two things in the plate are deliberately not built, and they are opposite kinds
of decision:

- **The grey bolt heads**, two per picket, each under a screen pixel. Fine
  detail fights the style (`references/REFERENCES.md` §1) — the same call the
  door's four panels made when they became two.
- **The rails in front of the pickets.** The plate nails them to the face. In
  the room the inside of the left run is 4 mm from the back of the potting
  bench, and a 10 mm rail on that side goes through it. It is
  `references/garden/README.md`'s own rule pointing the other way for once — *a
  plate cannot answer a question about the room it is not standing in* — and
  this time the room-box plate does not answer it either.

### The tree, and a canopy that can be measured against itself

`references/garden/garden-tree.png` and `GardenProps.tree` already agree about
the shape — a **cluster**, because a single sphere on a stick is a lollipop.
What the model buys is the thing eight separate `ModelEntity` spheres cannot
have: **the seam**. Where two lobes push into each other the crease is invisible
to the facets, since both surfaces face outwards and come back the same tone, so
the code paints alternate lobes `sage` and `mint` — a tint standing in for a
shape, and at 139 mm across it reads as a bag of two-coloured balls. One mesh
can be measured against itself. The canopy is **one colour** here, which is what
the plate draws, and the creases are shaded.

The count follows from the same fact: fourteen lobes rather than eight, because
in one mesh a lobe is not a draw call. The plate asks for a dozen.

**The envelope is asserted, not described.** The tree was sized twice by the
owner on 2026-08-17 and `GardenLayout.treeSpot` clears the fence posts, the
potting bench's backboard and the base slab's back edge by margins measured
against the result — 225 mm tall, 128 mm of trunk, canopy from 105 mm, 139 mm
across. `check_envelope()` fails the build if a lobe breaks any of the three,
because a lobe nudged out by two millimetres is a canopy through a fence post
and nothing in Blender would say so. It fired on the first run.

**One trap, and it is a trap for every prop after this one:
`subdivisions` does not mean the same thing on the two sides.** Blender's
`create_icosphere(subdivisions=1)` is the bare 20-face icosahedron;
`FacetedMesh.icosphere(subdivisions: 1)` has already subdivided once, at 80.
Transcribing the number gave a canopy of spiky 20-face lumps — a visible
regression against the tree already in the game, and the render is what caught
it. The model passes 2.

### The basket, which is a container, and a container has an inside

Four things off `references/garden/harvest-basket.png`, and they are all that
one fact:

- **A lining in its own colour.** `FacetedMesh.bowl` is the vocabulary's one
  double-walled primitive and it is one mesh with one tone, so the code's basket
  is sandy inside and out. The plate lines it in rose, and from a camera looking
  down at 31° the lining is most of what you see.
- **A rim with a thickness.** The code lays a flat `annulus` across the top — a
  plate resting on a tub. The plate draws a band 6.5 mm tall standing 2.1 mm
  proud, which therefore has an **underside**, and that underside is the only
  shadow on this prop that reads from across the room.
- **One handle**, swept and mitred, rather than seven boxes overlapping at their
  corners with every end cut square.
- **The handle spans the diagonal the camera looks across.** The code stands it
  along the world X, which the fixed camera on the +X+Z diagonal sees end-on;
  the plate draws it corner to corner, square to the eye.

The tub is three open shells that together close one surface — outside and
bottom, rim, lining — rather than one solid split afterwards. `flat_obj` leaves
an open shell's winding alone, so each is wound by hand and the assembly is
watertight: 16 outward faces and a floor on the tub, 8 outward and 8 up on the
rim, 16 **inward** and a floor on the lining.

**A 3.4 mm brim hides a basket**, which cost one render. The first build ran the
body up to 19.2 mm under a rim at 22.6, and from the room's own camera the
overhang covered the tub: the render came back as a green tray with a sliver of
basket under it. The plate stands its band on a body that reaches nearly the
same width, so the body is 20.5 mm now — which is `GardenProps.basket`'s own
29 mm corner radius, i.e. the number that was already right.

It is built **axis-aligned and the Swift side drops its `towardsCamera`**, which
is the crate's rule for the crate's reason: the camera looks down the +X+Z
diagonal, so a box square to the world already shows two sides and the corner
between them.

## Ambient occlusion, on these props

It started on the berry. Standing the crown up cost something: the crown and
the globe stopped being one silhouette, and nothing in the renderer said the
two shapes touch. The facets cannot answer it — the crater floor and the
crown's underside face the same way as everything around them, so they come
back the same tone. The same join turns up on every prop here: under the sack's
fanned collar, in every one of the crate's butt joints, at the clover's hub,
inside the basin, and under each ring of icing.

`lowpoly.bake_ao_facets` casts rays over each face's hemisphere against the
whole prop, and moves the faces that are actually in the crevice into their own
mesh named `…ShadeN`. `ModelLibrary` reads that suffix and paints
them a step darker per level, out of the palette.

What it finds, at the settings each prop is exported with:

| | Shaded | Where |
|---|---|---|
| Berry | 12 faces one step, 3 two steps, 5 on the crown | the crater ring, and the crown's hull underneath |
| Sack | 21 on the tie, 36 on the collar | the tie's top half under the collar's overhang, and the collar's inner faces |
| Crate | 16 + 16 on the boards, 8 + 12 on the frame | every butt joint, the inside faces, and under the top rail |
| Clover | 4–6 per petal | the hub where four petals crowd together |
| Sink | 3 on the tap, 5 on the handle neck | where the spout leaves the post, and under the handle |
| Cake | 441 trimming faces across Shade1–6; all 36 tier faces stay plain | under every drip, between the beads and across the trimming bands |
| Scale | 3 on the base, 3 on the dial, 12 on the pan | where the dial meets its neck, under the pan's rim, along the plinth's step |
| Feather | 10 on the vane | the crease, either side of the shaft |
| Pouch | 15 on the bag, 40 on the cord, 6 on the cloth | under the cord, and where the open cloth folds into it |
| Spoon | 3 on the scoop, 3 on the handle | the one shallow join, where the handle leaves the rim |
| Every plant | 6–7 per leaf, every time | the hub, where six leaves and a stem crowd into 4 mm |
| Aardbei | 9 on the berry, 6 on the stalk | under the calyx, and the inside of the arch's curl |
| Klaver | 4–12 per petal | the hub again, four petals to a head and two heads to a plant |
| Wolkenroom | 9 + 21 on the cloud, 5 + 5 on its crown | every seam where two lobes push into each other |
| Maanstof | 10 on the pod, 9 on the opening | the ring where the teeth stand out of the neck |
| Molehill | 6 on the head, 6 on the nose, 13 on the paws | where he comes out of the earth, and under the nose |
| Bed | 12 on the frame, 90 on the holes | the butt joints at each post, and the inside of every well |
| Tree | 150 one step, 405 two on the canopy | every seam where two of the fourteen lobes push into each other — and most of that count is faces already buried inside a neighbour |
| Basket | 8 on the rim, 6 on the handle | the underside of the rim's overhang, and where each foot of the handle stands on the band |
| Fence | **nothing** | see below — and that is the right answer |
| Sterrensuiker | nothing | a ridged star is convex; every crease on it is a ridge |

**The cake's tiers are never shaded**, only the trimmings — they are repainted
every round from `CakeSpec.tierColours`, and a tier a step darker would read as
a colour she did not choose. That is what `occluders` is for: the tiers cast
into the bake without receiving from it. The first cake bake put 11 of the top
tier's 12 faces in shadow, because a tier sits inside its own icing skirt.

### Het Feest's longer ramp

The disco's room-scale study changed the modelled party props on 2026-08-18.
`app/AMBIENT-OCCLUSION.md` found that the largest missing term was not a short
join but **each character and cabinet shading itself**: chin over chest, arm
against side, belly over feet, one speaker section over another. Those gaps are
20–40 mm, so every Het Feest prop finished through `feest.finish` now uses:

- **30 mm reach**;
- **0.80 strength**, quantised to the nearest `0.88ⁿ` palette step;
- **ten Shade levels**, putting fully enclosed facets at `0.88¹⁰ = 0.279`.

The eleven `beertje-*.usdz` assets, the DJ headset, the booth, speaker, mirror
ball, light bar and stage lamp were rebuilt through that path. The shared cake
uses the same arguments directly, so the kitchen and decorating room see the
same cake. The
dance tile remains the honest zero: it has no self-occlusion, and its existing
Shade1/2 names are an authored fallback rather than an AO measurement. The
shipping tile top is a UV plane with the smooth generated rectangular gradient
from `FeestProps`; the USDZ is used only if texture creation fails.

The AO path needed no Swift change: `ModelLibrary` already parses any integer
after `Shade`, and `Palette.occluded` already raises `0.88` to that power.
The simulator passes did lower Het Feest's separate emissive-room dial from 2.6
to 1.1 so the floor and mirror ball keep their colour, and restored the intended
floor-contact-shadow opacity. There are still no UVs, textures or runtime AO.
The shell texture remains the separate, conditional second step in
`app/AMBIENT-OCCLUSION.md`.

The sack's body and corners come back **unshaded**, which is the right answer:
a slumped bag is convex nearly everywhere, and the two faces that did measure
as occluded were too few to read as anything but a blemish.

**This is a deliberate exception to a locked rule.**
`references/REFERENCES.md` bans occlusion outright, and it stays banned
everywhere a facet can do the job. What keeps this within the style rather than
against it:

- **It is baked to facets, not to a texture.** No UVs, no lightmap, no runtime
  cost — the result is still one flat tone per face, which is what the whole
  style is made of. `app/LIGHTMAPS.md` is the texture route, and it is not this.
- **Its reach is short outside Het Feest**: 2.2 mm on the berry, 2.5 mm on the
  clover, 3 mm on the sink and the basket, 4 mm on the crate, 5 mm on a 139 mm
  tree, 6 mm on the sack — roughly the
  same *proportion* of each prop, and always chosen against the size of the part
  it must stay inside. On the crate the 4 mm is set against a 6 mm board depth,
  so it never reaches out onto the flat of a board. Het Feest is the measured
  exception above: 30 mm, spread over ten levels rather than two.
- **It is on the modelled props only.** Nothing built by `FacetedMesh` has any,
  and the rule stands there.

### The three things that make it behave

Each of these came from a bake that looked wrong, and each is a knob on
`bake_ao_facets`:

- **Grazing rays are discarded** (`GRAZING_CUTOFF`). A ray leaving a facet a few
  degrees off tangent tells you nothing about whether that facet is in a
  crevice, and floating point will happily report it as hitting the surface it
  just left. This is not a nicety: with grazing rays in, the sack's body
  measured a mean occlusion of **0.44** and came back almost entirely shaded.
  Without them it measures **0.04**. The ray's start is also lifted clear of its
  facet in proportion to `distance` — a fixed epsilon that works on a 20 mm
  berry is inside the noise of a 56 mm sack.
- **Thin levels are demoted** (`min_faces`, default 3). One facet a step darker
  than everything around it does not read as occlusion, it reads as a blemish.
  The demotion walks down a level at a time rather than over a snapshot of the
  buckets, because a demotion feeds the level below it and that level then has
  to be judged again.
- **A part shaded uniformly is not shaded at all.** Occlusion is contrast
  *within* a part; darkening every face of one is just painting it a different
  colour. The sack's tie sits under the collar's overhang and at 6 mm came back
  uniformly dark — correct as physics, wrong as a tie.

### Two more the garden added

- **The bright note of a prop has to cast without receiving.** The honey plant's
  rim is a 3 mm band and its pool of honey a 1.6 mm disc, both sitting inside a
  ring of eight petals, so nine of every ten of their faces measure as occluded
  and the floor-shifting rule above hands back a pot of dark honey. It is the
  cake's tiers again, and `garden.finish`'s `shade` argument is `occluders`
  turned round the useful way: pass the whole prop to cast, and list what may be
  darkened.
- **Very large facets have nothing to quantise.** The fence's bake finds
  nothing, and raising the distance does not fix that — a rail's front face is a
  single 400 mm polygon, so the strip of it each picket edge would shade is
  averaged across the whole run. Push the distance up and the entire face tips
  over the threshold instead, darkening 400 mm of rail. The spoon reached the
  same place from the other direction: a shape with barely a crevice in it
  measures as having barely a crevice in it, and the honest thing is to record
  the zero rather than tune until a number appears.

  It also caught real geometry: `GardenRoomBuilder` centres the rails 8 mm out
  from the run's line, which buries 3.5 mm of rail inside every picket. That was
  invisible while both were separate entities, and once they were one mesh it
  gave coplanar faces inside solid geometry **and** a bake measuring the join
  from inside it — the rails came back uniformly dark and the pickets untouched.
  Butted flush, both problems go away.

### And one the tree and the basket added

**The distance is chosen against the facet, not against the prop.** The tree's
lobes are 30–47 mm across, five times the cloud's, and the first bake reached
9 mm on that reasoning. It looks identical from outside to the 5 mm it ships
with: every extra face 9 mm found was one already buried inside a neighbouring
lobe. What sets the number is the size of the facet the shading has to sit
inside, and a subdivided icosphere's facet is 11 mm — near enough the cloud's
own, which is why the cloud's own number is nearly right.

The basket is the other half of it, and it is the fence again in a smaller
room: **its lining measures nothing.** The inside of the tub is genuinely the
darkest place on the prop, but each wall is one 20 mm quad, so the crease where
two of them meet is averaged away to nothing. The honest answer is to record the
zero — the four walls face four different ways and the facets shade them, which
is what the style is for — rather than to raise the distance until the whole
inside goes dark, which is a basket lined in brown.

## Rules a model has to hold to

All of these come from [`references/REFERENCES.md`](../references/REFERENCES.md)
and are the same rules the procedural props follow. They are worth stating here
because Blender will happily break every one of them by default.

- **Flat shading, every face.** `use_smooth = False` on every polygon, no
  bevel, no subdivision surface, no auto-smooth. The export authors one normal
  per face and `subdivisionScheme = "none"`.
- **Outward winding.** The normal comes from the winding and RealityKit culls
  back faces, so a face wound the wrong way is not a dark face — it is a hole
  you can see through, and Blender's viewport will not show you it because it
  lights both sides. `flat_obj` recalculates any closed mesh outward for you.
  This is not hypothetical: the blueberry's first crown was inside out, and
  what caught it was the AO bake reporting every one of its faces as fully
  occluded.
- **Ten sides around**, give or take. Enough to read as round at iPad size, few
  enough that each facet is visibly its own tone.
- **No textures, no UVs, no AO bake.** Shading comes from the facet normals.
- **Game scale, in metres, origin on the floor**, centred. A prop is modelled
  at the size it is used at, so `position` alone places it and nothing is
  scaled on load. The sack is 56 mm tall and 48 mm across; the berry is 21 mm
  by 20 mm, which is the size every ingredient token shares so that no one of
  them is the big one.
- **Palette colours only.** They are re-applied in Swift on load anyway — the
  palette in `Palette.swift` is the single source of truth for a colour — but a
  model that is the wrong colour in Blender is a model nobody can review.

## Export settings that matter

`export()` in the script has them, and three are load-bearing:

- `convert_orientation` with `up = Y`. Blender is Z-up, USDZ is Y-up. The
  exporter writes the conversion as a rotation on the root prim rather than
  rotating the geometry, which is why `ModelLibrary.load` hands back an upright
  wrapper rather than the file's own root — `Ticker.squash` scales a prop along
  its own local Y, and on a rotated root that is world Z, so a tap would squash
  the prop sideways.
- `export_normals`. Without it the facets are gone.
- `evaluation_mode = 'RENDER'`, which applies modifiers — the collar's solidify
  is what gives the fanned cloth an edge instead of a paper-thin sheet.

## Adding another one

Copy the shorter of the two scripts, import `lowpoly`, keep the shape in
Python, name the meshes after the prop (`ThingBody`, `ThingLid`), and load it
with
[`ModelLibrary.load`](../app/NinaBakeryPOC/Sources/ModelLibrary.swift), passing
a name → palette colour map. `Resources/` is a synchronised group, so a new
USDZ in `Resources/Models/` needs no Xcode project edit.

Keep a procedural fallback for anything she has to be able to touch. A missing
asset must not leave a dead patch of floor where a tap target was.

**Kenney's kits still come first.** `CLAUDE.md` is unchanged on this: do not
model what the [Food Kit](https://kenney.nl/assets/food-kit) or
[Furniture Kit](https://kenney.nl/assets/furniture-kit) already provides. This
route is for what nothing else has — characters, Otto, and cloth.
