# Real ambient occlusion, tried in Het Feest and De Keuken

**The question** (owner, 2026-08-18): *is real ambient occlusion in the scenes
possible?* — asked with Blender connected and the plates on disk, and asked of
**the disco**. Later the same day the owner asked for the same work on
**GAMEPLAY §6.3, De Keuken**. The two rooms do not have the same answer.

This is the answer, and it is measurements and renders rather than an opinion.
The disco can be rebuilt from
[`models/feest-scene.py`](../models/feest-scene.py) and
[`models/feest-ao.py`](../models/feest-ao.py); the kitchen from
[`models/keuken-scene.py`](../models/keuken-scene.py) and
[`models/keuken-ao.py`](../models/keuken-ao.py).

**The short verdict:** Het Feest gained its 30 mm ten-level prop ramp. De
Keuken keeps its existing 2–6 mm contact bakes and the shared cake's disco
ramp: a long ramp on the nine other modelled assets reaches the wrong 8% of the
error. **Its measured shell texture now ships instead.** On 2026-08-19 the
owner reported that the original AO did not visibly act in the simulator, which
triggered the conditional second step below: three 512² maps on kitchen-local
UV planes, plus restoration of the contact discs' intended 0.22 opacity.

**Implemented 2026-08-18:** the unconditional first step in §6 now ships in the
model assets: 30 mm per-prop AO, 0.80 strength, quantised to ten `ShadeN`
levels. All eleven friends, the DJ headset, booth, speakers, mirror ball, light
bar, stage lamp and the shared cake were rebuilt. The 0.55/six and 0.65/eight
in-app passes were both too washed out in the simulator, so the deeper ramp is
paired with a lower Het Feest emission peak (2.6 → 1.1). Its floor contact
shadows also compensate for the helper applying opacity twice, restoring the
intended 0.22 final opacity. The shell texture remains the conditional second
step and was not added.
[`11-shipping-ramp.png`](ao-study/11-shipping-ramp.png) is the adjusted ramp
rendered back in the assembled room. It has not yet been checked on iPad; the
draw-call warning below still applies.

**It is not a proposal to reopen the art direction.**
[`references/REFERENCES.md`](../references/REFERENCES.md) §1 bans *pooling* —
"no darkening pooled into corners, no murk where surfaces meet" — and nothing
here asks for any. Measured against the per-pixel reference, real occlusion
touches **24.5% of the lit picture** and darkens what it touches by a mean of
**6.8%**; the deepest twentieth of it reaches 16%. That is contact shading,
which `models/README.md` already argued through once and allowed onto the
modelled props. This is the same argument at room scale.

---

## What was built first

There was nothing to measure against, so the room got assembled.

[`models/feest-scene.py`](../models/feest-scene.py) stands the **whole disco**
up in Blender at the game's own coordinates: the shell from `RoomBox`, the 36
tiles, the pads, the ball, both bars and all five lamps, the booth, both speaker
stacks, the cake on its table, six guests and a DJ — **425 objects, 10,747
faces** — with the camera at `CameraRig.eye` on a 26° vertical FOV and the five
suns `LightingRig` installs at `LightingSettings`' approved defaults.

Where a prop is modelled it is the **shipping geometry**: the script imports
`dance-tile.py`, `discobal.py`, `dj-booth.py`, `light-bar.py`, `speaker.py`,
`stage-lamp.py`, `beertje.py` and `cake.py` and calls their `build()` without
their `main()`, so what is measured is what is in the bundle, baked shades and
all. The dance tile is now the exception: Blender sees its three-band failure
fallback, while the app normally puts `FeestProps`' smooth generated texture on
a UV plane. Where a prop is procedural it is rebuilt from `FeestProps`.

**It also mirrors every `excludeFromShadowCasting()` call in the room**, and
that turned out to matter more than anything else about the scene — §0.

**Caveats worth stating before any picture is believed.** These are Blender's
renders of the app's lighting rig, not the app: the sun energies keep
`LightingSettings`' *ratios* and the exposure is set by eye, so absolute
brightness is not RealityKit's, and the sun's 3° angular size is a guess at how
soft `DirectionalLightComponent.Shadow` is. The room is rendered **between
beats** — no lit tiles, no beams, no lens glow — because those are transient and
emissive and would drown the thing being looked at. Nina is not in it. Nothing
here has been seen on an iPad.

The fast renders are EEVEE and the per-pixel reference is Cycles; on the
un-occluded room the two agree to a **mean absolute 0.004** on a 0–1 scale, so
mixing them costs nothing.

---

## 0. Two things this study got wrong first, both worth keeping

**The scene let every prop cast a shadow, and the room does not.**

| | |
|---|---|
| [`00-what-casts-a-shadow.png`](ao-study/00-what-casts-a-shadow.png) | everything casting │ the app's own caster list |

The first render set had a hard dark band raking across the plaster from the
light bar and the five lamps. It is not AO and it is not the room: `FeestProps`
takes the **bars, the lamps and their beams, the mirror ball, the 36 tiles, the
ball spots, the balloon and the confetti** out of the key light's shadow map,
`RoomBox.shell` takes the walls and floor out, and that is exactly the artefact
`LightingSettings`' history records the owner rejecting twice on device on
2026-08-15. A study that reintroduces it is measuring a room the game does not
have — and it makes every AO comparison harsher than it should be, because the
band buries the thing being measured. `feest-scene.SHADOWLESS` mirrors the Swift
now; 174 of the room's 353 meshes are out of the shadow map.

What still casts, and should: the pads, the booth, both speaker stacks, the cake
and its table, the popper, the six guests and the DJ.

**And the "baseline" quietly had ambient occlusion in it.**
`lowpoly.material` returns a material *by name*, so palette materials survive a
rebuild — and `pixel_ao` rewires Base Color through an occlusion node, which a
later `assemble()` then picked straight back up. One whole render set was
comparing AO against AO. `feest-scene.wipe` purges materials now. The lesson
generalises past this study: **in Blender, clearing the objects is not clearing
the file.**

---

## 1. The plates already have it

`references/feest/roombox.png` has a soft shadow under the DJ booth, a darker
seam where the two walls meet, and a pool under the cake table.
`references/plates/01-cottage-exterior.png` has it under the eaves and around
the door frame. **The locked style references carry contact occlusion**; the
game does not. That gap is the whole of what follows.

---

## 2. What real occlusion in this room actually looks like

`feest-ao.pixel_ao` puts **per-pixel, ray-traced** occlusion into every material
and renders it in Cycles. It ships nowhere — RealityKit has no ray-traced AO —
but it is the ceiling, and every other route is an approximation of it.

| | |
|---|---|
| [`01-as-it-ships.png`](ao-study/01-as-it-ships.png) | the room today |
| [`02-real-ao.png`](ao-study/02-real-ao.png) | the same room, per-pixel AO at 45 mm |
| [`03-where-real-ao-acts.png`](ao-study/03-where-real-ao-acts.png) | the difference, ×6 |

The difference image is the useful one, and it says something that was not the
expected answer. **The largest term is not contact with the floor.** It is:

- **every guest's own body** — under the chin, between an arm and the side,
  between the legs, and the shadow the belly throws on the feet;
- the tiers of the cake, and the seam between the two speaker cabinets;
- the 3 mm gaps between the 36 dance tiles;
- a soft halo where the booth, the stacks and the bars meet plaster;
- the two wall/floor junctions and the wall/wall corner.

The floor-contact term that ambient occlusion is usually wanted for is **already
in the game**: `ContactShadows` attaches a disc under every guest, the DJ, the
booth, the table, the popper, all six pads and both stacks
(`FeestRoom.refreshContactShadows`).

---

## 3. The facet route cannot do the room

The obvious idea is to run `lowpoly.bake_ao_facets` — which already ships — with
the whole room as its occluder set. It does not work, and the reason is
structural rather than a matter of tuning.

**First, a scene bake is not a prop bake with a bigger number.** Run at 45 mm
against everything, the first pass came back with a mean occlusion of **0.57 on
the guests** and 0.54 on the props: nearly every facet in the room two steps
dark, because at that reach a 102 mm bear sees her own belly from her own arm.
That is `models/README.md`'s own rule — *a part shaded uniformly is not shaded
at all* — and `feest-ao.measure` answers it by **skipping every hit on the
facet's own prop**. The prop bake owns the crease at 2–6 mm; this one owns what
stands next to what. Two measurements, two scales, no double counting.

**Second — and this is the finding — the shell has nothing to quantise.**
`RoomBox.shell` builds the floor as one box, so with the self-occlusion
correctly excluded, the measurement is:

| surface | faces | measured AO | what a facet bake can do |
|---|---|---|---|
| floor, top | **1** | **0.426** | past both thresholds → **the whole 460 mm floor two steps dark** |
| back wall, inner | **1** | **0.000** | nothing, though a booth and two stacks lean on it |
| left wall, inner | **1** | **0.000** | nothing |

A facet is the sample *and* the answer. The wall is sampled once, at its centre
117 mm up in mid-air, where nothing is within reach — so it measures zero while
three props touch it. The floor is sampled once and measures 0.43 — so it goes
uniformly dark. It is `models/README.md`'s fence ("very large facets have
nothing to quantise") at room scale, and there is no threshold that fixes it.

**Third, subdividing the shell trades one artefact for another.**
`feest-scene.SUBDIV` cuts each inward face into a grid; at 24 (19 mm cells, about
the width of a guest's foot) the shell goes from 24 faces to 1,749 and the bake
finally has somewhere to put an answer. What it puts there is blocky.

| | |
|---|---|
| [`04-facet-scene-bake.png`](ao-study/04-facet-scene-bake.png) | facet scene bake, 19 mm cells |
| [`05-where-the-facet-bake-acts.png`](ao-study/05-where-the-facet-bake-acts.png) | the difference, ×6 — compare with `03` |

Put `05` next to `03` and the shape of the failure is plain: staircase patches on
the plaster where the real pattern is a soft halo, whole tiles flipping where the
real one has a thin seam, and **white where the real one is strongest** — the
contact under each guest, because she stands on a tile whose top is one large
facet. Coarse where the truth is fine, present where the truth is absent, absent
where the truth is loudest. Finer cells only make it a lightmap built out of
polygons, which is a lightmap with the resolution priced in triangles.

**Facet-quantised scene AO is a dead end.** Recorded so the next session does not
spend the afternoon on it.

---

## 4. What does work, and needs no Swift at all

The largest term in `03` is each character shading **herself**, and that needs no
scene, no room and no texture. It is `lowpoly.bake_ao_facets`' own question
asked at a longer reach: the prop scripts pass 2.2–6 mm because
`models/README.md` fixes the distance against the crease being shaded, and what
actually reads on a guest is her chin against her chest and her arm against her
side — **20 to 40 mm apart**.

| | |
|---|---|
| [`06-props-truth-ramp-ladder.png`](ao-study/06-props-truth-ramp-ladder.png) | per-pixel truth │ 30 mm ramp │ 30 mm on the game's own ladder |

The middle panel is a **6-rung ramp at 0.55 strength** and it is close to the
truth in shape, if about twice as dark in magnitude (§5's table). The right panel is the game's `0.88ⁿ` ladder given four thresholds, and it
is **mottled** — single facets going dark beside light ones, which reads as dirt
rather than as form. That is worth writing down: at this reach the mapping
matters more than the reach. A long bake wants **many small rungs with a floor**,
not two big steps.

Reach barely matters between 30 and 45 mm; 15 mm hugs the silhouette. 30 mm is
the pick.

**The app already accepts this.** `ModelLibrary.occlusion` parses any integer
after `Shade`, and `Palette.occluded` raises `0.88` to any power — so `Shade3`,
`Shade4`, `Shade5` work today with **no Swift change at all**. What changes is
the arguments in each prop script and a rebuild of its `.usdz`.

**What it costs:** the bake is 0.6 s for the whole room. Shipping it turns the
disco's **349 prop meshes into 695** — one extra mesh per part per non-empty
rung, on 168 of the parts. That is the real bill, it is draw calls, and it is the
number to check on an iPad before committing.

---

## 5. And the shell wants a texture — which the app is already wired for

The one thing the facet route cannot reach is exactly the thing a texture is
good at: a soft gradient across a 460 mm quad. `app/LIGHTMAPS.md` describes this
route and has never been run. It has now been.

`feest-ao.bake_texture` UV-unwraps the four shell pieces, bakes Cycles AO into
one 512² image each, and multiplies it into base colour.

| | |
|---|---|
| [`07-walls-ships-texture-truth.png`](ao-study/07-walls-ships-texture-truth.png) | today │ baked texture │ per-pixel truth |
| [`08-floor-ao-map.png`](ao-study/08-floor-ao-map.png) | the floor's map — the tile grid, the table foot, the pads, the wall falloff |

Measured rather than eyeballed. Over every pixel the per-pixel reference
darkens, the routes miss it by this much on average:

| route | mean error vs the reference | darkens by, where it acts |
|---|---|---|
| the per-pixel reference | — | 6.8% |
| shell texture only | **0.049** | 4.7% |
| per-prop facet ramp only | 0.067 | 13.6% |
| **both** | **0.048** | 8.7% |

The bake is **23.6 s** for all four shell pieces, and the four 512² PNGs come to
**178 KB**.

Two things that table says out loud. The **texture route is accurate** — within
five points of a ray-traced reference, for 23 seconds and 178 KB. And the
**facet ramp at 0.55 strength is about twice as dark as it should be**: 13.6%
against the reference's 6.8%. Dropping it to 0.40 or 0.30 barely moves the error
(0.061, 0.063), because `paint` quantises and what is left is *where* the two
differ rather than by how much — the reference has a contact pool under every
guest, and a per-prop bake cannot have one by definition. **Strength is a dial
for the app, not for Blender**; 0.3–0.55 is the measured Blender range, while
the simulator passes ultimately needed 0.80.

**The first texture bake was wrong, and it looked like a bug.** Baked at 150 mm
with 0.65 strength it put a broad hard-edged rectangle on the left wall. Nothing
was broken — the reach and the strength had been picked by eye rather than
against the reference. **Calibrate a bake against the per-pixel render**; it took
one measurement to settle, and it is why there is a table above rather than an
adjective.

**What it costs**, and this is where it stops being free:

- **UVs.** `FacetedMesh` writes positions and normals and nothing else, so the
  shell has no texture coordinates. A box's UVs are six planar rectangles, so
  this is a small addition rather than an unwrapping problem — but it is a
  change to the file every room's geometry comes out of.
- **Per-entity maps.** `LightingRig.applyLightmap` applies **one** texture to
  every model in the scene. Four maps need it keyed by entity.
- **A re-bake whenever the room's furniture moves.** Not whenever a *guest*
  moves — she is on a tile, and `ContactShadows` has her.
- One PNG per shell piece per room, in the bundle.

---

## What ships

| | |
|---|---|
| [`09-both-routes.png`](ao-study/09-both-routes.png) | both routes together |
| [`10-where-both-routes-act.png`](ao-study/10-where-both-routes-act.png) | the difference, ×6 |
| [`11-shipping-ramp.png`](ao-study/11-shipping-ramp.png) | the implemented ten-level 30 mm prop ramp |

1. **The long-reach per-prop facet bake ships.** 30 mm, ten rungs at **0.80**
   strength. `lowpoly.bake_ao_facets` maps `1 - 0.80·ao` to the nearest
   `0.88ⁿ` palette level, capped at `Shade10`; `feest.finish` owns those settings.
   The ramp itself needed no loader Swift, textures or UVs. Eighteen USDZs were
   rebuilt through the Blender MCP; Het Feest separately lowers emission and
   restores its intended contact-shadow opacity. Check the mesh count on device
   first — it roughly doubles.
2. **Then, if the plaster still looks flat, the shell texture.** It is real,
   cheap to bake and accurate; it costs UVs in `FacetedMesh` and a keyed
   `applyLightmap`. It is a separate decision and it can wait.
3. **Do not build facet-quantised scene AO.** §3 has the arithmetic.
4. **Nothing here changes the lighting rig**, and nothing pools into a corner.
   The one lighting thing this study *did* turn up is not about AO at all: the
   harsh band on the plaster in the first render set was cast shadow, and the
   room already suppresses it (§0). If anything on device looks like that band,
   the caster list is the place to look, not the occlusion.

---

## Rebuilding any of it

The shipping assets:

```
blender --background --python models/beertje.py
blender --background --python models/discobal.py
blender --background --python models/dj-booth.py
blender --background --python models/speaker.py
blender --background --python models/light-bar.py
blender --background --python models/stage-lamp.py
blender --background --python models/cake.py
```

`beertje.py` writes all eleven species. `dance-tile.py` is deliberately absent:
one tile has no self-occlusion. Its Shade1/2 bands are the failure fallback for
the smooth generated rectangular gradient that `FeestProps` maps over the
shipping tile top.

The study scene:

```
blender --background --python models/feest-scene.py
```

builds the room. Then, in Blender:

```python
# The filenames have dashes in them, so `import` will not do it.
import importlib.util, sys

def load(stem, name):
    spec = importlib.util.spec_from_file_location(name, "models/%s.py" % stem)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module

scene = load("feest-scene", "feest_scene")
ao = load("feest-ao", "feest_ao")

scene.SUBDIV = 0            # 24 to give the shell something to quantise
groups = scene.assemble()
every = ao.meshes()

# the room, each facet measured against everything that is not its own prop
room = ao.measure(every, every, distance=ao.REACH)
print(ao.report(room, groups))          # faces, rungs and mean occlusion per group

# each prop against itself, at the reach that actually reads
props = ao.measure_per_prop(every, distance=0.030)
ao.paint(props, ladder=False, steps=6, strength=0.55)

ao.pixel_ao()                           # the ceiling — Cycles only
shell = [ob for ob in groups["Schil"] if ob.type == 'MESH']
maps = ao.bake_texture(shell, size=512, samples=24, distance=0.045)
ao.apply_texture(shell, maps, strength=0.55)
```

`ao.strip()` puts every mesh back on its first material slot; `ao.plain()`
takes `pixel_ao` back out. Both leave the scene renderable, so the three routes
can be A/B'd in one session without rebuilding the room.

---

## De Keuken — same work, different answer

**Asked by the owner on 2026-08-18:** repeat the room-scale AO investigation
for `GAMEPLAY.md` §6.3, De Keuken.

**The first pass shipped only the study.** The nine kitchen assets that could
take a longer facet ramp account for too little of the missing image, while the
shell texture accounts for most of it. That texture was initially deferred.

**Implemented after the simulator check on 2026-08-19:** the owner reported that
the AO did not look like it was doing anything. The conditional shell route now
ships as three kitchen-only UV planes in `KitchenAO.swift`; the 0.55-calibrated
maps multiply into diffuse colour because `LightingRig` clears the material AO
slot whenever the global lightmap debug switch is off. The kitchen also applies
the same √opacity compensation as Het Feest, so `ContactShadows`' double alpha
lands at the requested final 0.22 instead of 0.048.

The eleven kitchen renders are in
[`ao-study-keuken/`](ao-study-keuken/). They were made in Cycles at one fixed
seed; Blender 5.2's EEVEE did not reproduce the five-sun rig closely enough to
mix its output into pixel differences, so unlike the disco's original pass no
cross-engine comparison is used here.

### What was assembled

[`models/keuken-scene.py`](../models/keuken-scene.py) rebuilds a valid,
maximally populated visit-mode kitchen:

- the shared shell, table, counter, two shelves and six jars, cake plank,
  portrait fallback and invited door;
- Otto and Nina from their Swift dimensions and pivots;
- dough, basket, bowl, spoon, tin and rolling pin;
- one possible five-ingredient deal across all five sources;
- sink, scale, flour sack and crate;
- three completed cakes on the plank;
- the camera at `CameraRig.eye` and the five approved `LightingSettings` suns.

That is **266 objects, 231 meshes and 4,550 faces**. Where a prop has a Blender
source, the scene calls its shipping `build()` and keeps its existing `ShadeN`
pieces. Procedural things are transcribed from `FacetedMesh` at the same
coordinates and side counts.

The still is deliberately fuller than a round's middle: visit mode starts a
fresh round behind the three cakes that opened the door, so all of it can
genuinely coexist. Water, batter, sparkles, flour prints, halos and the dynamic
contact-shadow discs are transient and absent.

| | |
|---|---|
| [`01-as-it-ships.png`](ao-study-keuken/01-as-it-ships.png) | the assembled kitchen, with the app's caster list |
| [`00-what-casts-a-shadow.png`](ao-study-keuken/00-what-casts-a-shadow.png) | every mesh casting │ the app's own caster list |

**The caster list matters here too.** The shell, counter, shelves, cake plank,
portrait and doorway do not cast in the app; **119 of the scene's 231 meshes**
are therefore out of the key shadow map. Turning them all back on restores the
wall/wall wedge and furniture silhouettes that `LightingSettings` records being
rejected on device. They are cast shadows, not AO, and any future regression
that looks like the left panel belongs in the caster list.

### The per-pixel ceiling

| | |
|---|---|
| [`02-real-ao.png`](ao-study-keuken/02-real-ao.png) | per-pixel Cycles AO at 45 mm and 0.55 strength |
| [`03-where-real-ao-acts.png`](ao-study-keuken/03-where-real-ao-acts.png) | the difference from `01`, ×6 |

With absolute render differences below 0.015 treated as sampling and denoiser
noise, real kitchen AO touches **25.0% of the lit picture**, darkens those
pixels by a mean **7.1%**, and the deepest twentieth reaches **20.1%**. The
near-identical coverage to Het Feest (24.5%) hides a different distribution:

- broad contact under the table legs, flour sack, crate and Otto;
- the bowl and sink interiors, and under their rims;
- Nina's apron, arms and hat against her body;
- Otto's mouth surround, eyes, door and chimney against the dome;
- the shelves, counter, plank, portrait and doorway meeting plaster;
- the wall/floor and wall/wall joins.

The first item overstates what is missing in the app: its loose props have
dynamic `ContactShadows`, and the table, Nina and Otto cast real shadows. The
Blender ceiling intentionally has neither helper disc. The first simulator
capture exposed why the discs appeared absent: `ContactShadows` writes opacity
into both colour alpha and transparent blending, so requested 0.22 arrived as
0.22², about 0.048. De Keuken now compensates locally with √opacity, as Het
Feest already did, restoring the intended final 0.22 without retuning the
garden or decorating room.

### Why the disco's long prop ramp does not transfer

The tempting mechanical answer was to give every modelled kitchen asset Het
Feest's 30 mm ramp. Two candidates were rendered: 0.55 over six visual rungs,
the study setting, and the disco's shipping 0.80 over ten.

| | |
|---|---|
| [`04-props-truth-ramp.png`](ao-study-keuken/04-props-truth-ramp.png) | per-pixel truth │ 0.55/six on modelled kitchen props │ 0.80/ten |

Measured over the lit picture against `02`:

| route | mean error | improvement over no added AO |
|---|---:|---:|
| no added kitchen AO | 0.01596 | — |
| modelled props, 0.55 / six | 0.01482 | **7.2%** |
| modelled props, 0.80 / ten | 0.01467 | **8.1%** |

That is the wrong end of the room. The eligible assets are the blueberry,
clover, moon-dust pouch, feather, spoon, sink, scale, flour sack and crate.
The missing forms that dominate `03` are the procedural **Nina, Otto, table,
counter, bowls and shell**. Rebuilding nine USDZ files cannot touch them.

It is not free either. In this populated still those nine assets currently
occupy **63 meshes** including their short-bake `ShadeN` pieces. Replacing the
short bakes with the measured 30 mm ramp is estimated at **82 meshes** for
0.55, or **93** for 0.80: 19–30 more draw calls to improve the room-scale error
by seven or eight percent. The deeper render also makes the scale's dial edge
and the sack's enclosed folds visibly harsher while leaving the floor and
plaster unchanged.

The shared cake is excluded from that test because it already carries Het
Feest's 30 mm, 0.80, ten-level ramp in every room. Nothing here asks to undo it.

**Verdict: keep the kitchen's existing 2–6 mm bakes.** They answer the joins
they were authored for — crown/calyx, board/post, collar/tie, spout/post — and
do not pretend to answer the room.

### The shell still cannot be painted by facets

The shipping shell gives each visible inward surface one receiving facet. At
45 mm, measured against the whole kitchen while excluding each facet's own
object:

| surface | receiving facets | measured AO | a facet bake's only answer |
|---|---:|---:|---|
| floor top | 1 | **0.000** | no shading anywhere, despite every contact in `03` |
| back wall inner | 1 | **0.234** | the whole 460 × 235 mm wall one step dark |
| left wall inner | 1 | **0.702** | the whole wall two steps dark |

This is the disco failure with different signs. There the floor centre happened
to see enough room to darken the whole floor; here it happens to sit in open
space and sees nothing. The left wall's one sample sits among the shelves and
door and declares the whole wall enclosed. Neither is a picture of where AO
acts.

| | |
|---|---|
| [`09-facet-scene-bake.png`](ao-study-keuken/09-facet-scene-bake.png) | scene AO after cutting each inward shell face into 24 × 24 cells |

At 24 divisions, 19 mm cells, the shell grows from **24 to 1,749 faces** and
the room from 4,550 to **6,275**. It finally has samples near the furniture,
and paints them as stair steps: rectangles behind the shelves, square halos
under the floor props, and a block grid along the wall joins. Finer cells are a
lightmap priced in triangles.

**Facet-quantised scene AO remains a dead end.**

### The texture remains the accurate route

The same 512² Cycles bake used for Het Feest was run on the kitchen's visible
shell. The shipping floor and two wall PNGs total **222 KB** in source and
about **169 KB** after Xcode's resource processing. They include fixed geometry
only — shell, furniture, Otto, sink, scale, sack and crate — so a moved bowl or
ingredient never leaves a baked ghost. Dynamic contact stays with the corrected
contact discs.

| | |
|---|---|
| [`06-shell-ships-texture-truth.png`](ao-study-keuken/06-shell-ships-texture-truth.png) | today │ shell texture │ per-pixel truth |
| [`07-floor-ao-map.png`](ao-study-keuken/07-floor-ao-map.png) | the floor map — feet, legs, sack, crate and Otto |
| [`08-both-routes.png`](ao-study-keuken/08-both-routes.png) | shell texture plus the 0.55 modelled-prop ramp |
| [`10-where-both-routes-act.png`](ao-study-keuken/10-where-both-routes-act.png) | the combined difference from today, ×6 |

| route | mean error vs per-pixel truth | improvement over today |
|---|---:|---:|
| today | 0.01596 | — |
| modelled prop ramp only, 0.55 | 0.01482 | 7.2% |
| shell texture only | **0.01022** | **36.0%** |
| both | **0.00915** | **42.7%** |

So the kitchen strengthens the disco's conclusion: a texture is the right
representation for a soft answer over a 460 mm quad. The implementation avoids
changing shared code: `KitchenAO.shellOverlay()` lays three generated UV planes
0.2 mm over `RoomBox.shell`'s inward faces. The ordinary box remains underneath
for thickness and is the complete fallback if any texture is absent.

The first simulator pass put the maps in
`PhysicallyBasedMaterial.ambientOcclusion`; it looked unchanged. The cause was
not insufficient strength: `LightingRig.applyLightmap(.off)` clears that slot
on every model immediately after room construction. The maps are already
calibrated to `1 - 0.55·AO`, so the shipping material multiplies them into base
colour instead — white leaves the palette unchanged and only the measured
gradients darken. That is also the route the Blender comparison measured.

| | |
|---|---|
| [`11-simulator-iteration.png`](ao-study-keuken/11-simulator-iteration.png) | the same Debug build: `-no-kitchen-ao` │ shipping AO |

The right panel is where the room-scale AO is visibly doing
work: under Otto, the table legs, sack and crate, with softer wall contact
behind the fixed furniture. It keeps live directional shadows and adds three
draw calls. The debug launch flag disables both the shell maps and the opacity
correction, so the A/B includes the complete kitchen pass. Furniture movement
still requires a re-bake.

### What ships from the kitchen pass

1. **Three kitchen shell AO maps.** 512², 0.55 strength, on three kitchen-only
   UV planes built by `KitchenAO.swift`.
2. **The intended 0.22 dynamic contact opacity.** A local √opacity correction
   compensates for the shared helper applying alpha twice.
3. **The nine eligible modelled props keep their short contact bakes.**
   Extending them remains the measured wrong route.
4. **The shared cake keeps its existing long ramp.**
5. **No facet scene bake and no lighting change.**
6. **The reproducible study ships:** the assembled scene, shared measurement
   wrapper and eleven renders, including the simulator iteration.

### Rebuilding the kitchen study

```
blender --background --python models/keuken-scene.py
blender --background --python models/keuken-lightmaps.py
```

The first command assembles the study scene; the second rebuilds the three
shipping maps directly. For interactive measurements:

```python
import importlib.util, sys

def load(stem, name):
    spec = importlib.util.spec_from_file_location(name, "models/%s.py" % stem)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module

scene = load("keuken-scene", "keuken_scene")
ao = load("keuken-ao", "keuken_ao")

scene.SUBDIV = 0
groups = scene.assemble()
every = ao.meshes()

# Room-scale relationships, excluding each facet's own prop.
room = ao.measure(every, every, distance=ao.REACH)
print(ao.report(room, groups))

# Longer self-occlusion, for the candidate prop ramp.
props = ao.measure_per_prop(every, distance=0.030)
ao.paint(props, ladder=False, steps=6, strength=0.55)

# Per-pixel ceiling and the original whole-box study route.
ao.pixel_ao()
shell = [ob for ob in groups["Schil"] if ob.type == "MESH"]
maps = ao.bake_texture(shell, size=512, samples=24, distance=0.045)
ao.apply_texture(shell, maps, strength=0.55)
```

`keuken-ao.py` deliberately re-exports `feest-ao.py`'s room-independent
measurement code. The second room therefore tests a different scene with the
same rays, thresholds and paint functions rather than carrying a forked AO
implementation.
