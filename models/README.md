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
| `flour-sack.py`, `bosbes.py`, `crate.py`, `klaver.py`, `sink.py`, `cake.py` | The six props. Run one to rebuild and re-export it. |
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
```

Each writes its USDZ and saves its `.blend`. Add `-- --no-save` to export
without touching the `.blend`. Blender 5.2 LTS; the export is deterministic, so
re-running with no edits produces the same geometry.

The `.py` is authoritative on purpose. A `.blend` is a binary a diff cannot
read and a session cannot review, and a prop whose shape only exists inside one
is a prop that can only be changed by the person with Blender open.

## What is here, and why each one earned it

A prop belongs here when the plate asks for something the code cannot say — or,
when what the plate asks for was never built at all. All six were chosen on that
test, not because modelling is nicer.

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
mesh named `…Shade1` / `…Shade2`. `ModelLibrary` reads that suffix and paints
them a step darker per level, out of the palette.

What it finds, at the settings each prop is exported with:

| | Shaded | Where |
|---|---|---|
| Berry | 12 faces one step, 3 two steps, 5 on the crown | the crater ring, and the crown's hull underneath |
| Sack | 21 on the tie, 36 on the collar | the tie's top half under the collar's overhang, and the collar's inner faces |
| Crate | 16 + 16 on the boards, 8 + 12 on the frame | every butt joint, the inside faces, and under the top rail |
| Clover | 4–6 per petal | the hub where four petals crowd together |
| Sink | 3 on the tap, 5 on the handle neck | where the spout leaves the post, and under the handle |
| Cake | 120 on the icing, 22 + 122 on the pearls | under every drip, and between the beads |

**The cake's tiers are never shaded**, only the trimmings — they are repainted
every round from `CakeSpec.tierColours`, and a tier a step darker would read as
a colour she did not choose. That is what `occluders` is for: the tiers cast
into the bake without receiving from it. The first cake bake put 11 of the top
tier's 12 faces in shadow, because a tier sits inside its own icing skirt.

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
- **Its reach is short**: 2.2 mm on the berry and the cake, 2.5 mm on the
  clover, 3 mm on the sink, 4 mm on the crate, 6 mm on the sack — roughly the
  same *proportion* of each prop, and always chosen against the size of the part
  it must stay inside. On the crate the 4 mm is set against a 6 mm board depth,
  so it never reaches out onto the flat of a board.
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
