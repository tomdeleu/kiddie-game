# Models — props built in Blender

**A second way to make a prop.** Everything in the kitchen is built in code by
[`FacetedMesh`](../app/NinaBakeryPOC/Sources/FacetedMesh.swift): a profile, a
side count, a mesh. That stays the default — it is quick to tune, it costs
nothing to ship, and a prop whose shape is eight numbers in a Swift file is a
prop anyone can adjust without opening anything.

This folder is for the shapes that vocabulary cannot reach.

| | |
|---|---|
| `lowpoly.py` | The shared rules: flat shading, palette colours, ring/bridge/tube builders, and the export. A prop script is then only its shape. |
| `flour-sack.py`, `bosbes.py` | The two props. Run one to rebuild and re-export it. |
| `*.blend` | The same things, openable. **Not the source of truth** — a convenience for looking at and for nudging a number before it goes back into the `.py`. |
| → `app/NinaBakeryPOC/Resources/Models/*.usdz` | What ships. |

## Running it

```
blender --background --python models/flour-sack.py
blender --background --python models/bosbes.py
```

Each writes its USDZ and saves its `.blend`. Add `-- --no-save` to export
without touching the `.blend`. Blender 5.2 LTS; the export is deterministic, so
re-running with no edits produces the same geometry.

The `.py` is authoritative on purpose. A `.blend` is a binary a diff cannot
read and a session cannot review, and a prop whose shape only exists inside one
is a prop that can only be changed by the person with Blender open.

## What is here, and why each one earned it

A prop belongs here when the plate asks for something the code cannot say. Both
of these were chosen on that test, not because modelling is nicer.

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

### And the only ambient occlusion in the game

Standing the crown up cost something: the crown and the globe stopped being one
silhouette, and nothing in the renderer said the two shapes touch. The facets
cannot answer it — the crater floor and the crown's underside face the same way
as everything around them, so they come back the same tone.

`lowpoly.bake_ao_facets` casts rays over each face's hemisphere against the
whole prop, and moves the faces that are actually in the crevice into their own
mesh named `…Shade1` / `…Shade2`. `ModelLibrary` reads that suffix and paints
them a step darker per level, out of the palette.

**This is a deliberate exception to a locked rule.**
`references/REFERENCES.md` bans occlusion outright, and it stays banned
everywhere a facet can do the job. What keeps this within the style rather than
against it:

- **It is baked to facets, not to a texture.** No UVs, no lightmap, no runtime
  cost — the result is still one flat tone per face, which is what the whole
  style is made of. `app/LIGHTMAPS.md` is the texture route, and it is not this.
- **Its reach is 2.2 mm.** Contact shading where two parts meet, not the all-over
  darkening that got the clay direction rejected.
- **It is on one prop**, because one prop needed it.

The knobs are `distance`, `thresholds` and `min_faces`. The last one demotes a
level that catches fewer than three faces: one facet a step darker than
everything around it does not read as occlusion, it reads as a blemish, which
is exactly what the first bake produced.

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
