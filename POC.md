# Step 0 — the proof of concept

> **Done, and overtaken.** Both questions below are answered, and the app in
> [`app/`](app/) is now the kitchen rather than a proof of concept — one full
> round, six toys, Dutch voice. Read [`app/README.md`](app/README.md) for what
> is actually in there. This file stays as the record of *why* the look is what
> it is, and the palette and criteria below are still the standard every new
> room is held to.

**This is the first thing to build.** Not game content. Rationale in
[`CONCEPT.md`](CONCEPT.md) §8; this file is the working brief.

It answers two questions the briefing cannot:

1. **Does the faceted low-poly look survive on the iPad?**
2. **Can Nina drive the controls?**

The risk is lopsided. A failed visual invalidates the art direction before four
rooms get modelled. Awkward controls are tuning. So the visual is answered first,
and as cheaply as possible.

---

## Stage A — USDZ in Quick Look (well under an hour, no app)

Model one kitchen room box in Blender, export USDZ, AirDrop to the iPad, open in
Quick Look. Same renderer family, real screen, real size. **If the look does not
survive here, no RealityKit code will rescue it.**

Target: [`references/plates/03-kitchen-roombox.png`](references/plates/03-kitchen-roombox.png),
against the locked style reference
[`references/plates/01-cottage-exterior.png`](references/plates/01-cottage-exterior.png).

> **There is no bake step.** The earlier version of this brief spent most of its
> length on UV unwrapping and baking ambient occlusion into base colour. All of
> that is gone — see [Lighting without AO](#lighting-without-ao) below. Stage A
> is now geometry, flat colours, one light, export.

### Geometry

- Open corner room box: **two walls and a floor**, open on the two near sides,
  on a slim square base slab.
- Contents, minimum: work table, mixing bowl, the domed oven, two wall shelves
  with a few chunky jars. Skip the cake — it is not needed to judge the look.
- **Shade flat. No bevel, no smoothing, no subdivision.** This is the single
  most important instruction, and it is the exact inverse of the old brief. In
  Blender: Object → Shade Flat, and make sure Auto Smooth / smooth-by-angle is
  **off**. Every facet must read as its own flat plane.
- **Keep the polygon count genuinely low.** Faceted spheres at 12–20 faces,
  cylinders at 6–8 sides. If a curve looks smooth, it has too many faces.
- Chunky and sparse. Fewer, bigger props. No fine detail, no labels, no trim.

### Scale and orientation

- RealityKit works in **metres**. Build the room box around **0.4 m** across —
  large enough to work with, sane when it reaches the engine.
- **Apply all transforms** (Ctrl+A → All Transforms) so scale is 1.
- Blender is Z-up, USD is Y-up. The exporter converts, but check the result is
  not lying on its side — this is the classic USDZ surprise.

### Materials

Principled BSDF per palette colour, and nothing else:

| Setting | Value |
|---|---|
| Base Color | from [the palette](#palette) — flat, unmodified |
| Roughness | **0.85–0.95** |
| Metallic | 0 |
| Specular | low |

No textures, no normal maps, no AO maps, no transparency, no vertex colours.
One flat colour per surface. A dozen materials should cover the entire room.

### Lighting

One soft key light plus broad ambient fill — a large area light and a soft
world/ambient colour is enough. Enough directionality that adjacent facets come
back visibly different; not so much that the scene gains hard shadows or dark
corners.

Add a soft contact shadow under the props and the slab. That is the only shadow
the style wants.

### Export

File → Export → Universal Scene Description (`.usdz`). Materials included;
there are no textures to include. AirDrop to the iPad, open in Quick Look.

Expect a **small** file — no textures means kilobytes, not megabytes.

### Stage A passes if…

Judged **on the iPad at arm's length**, not on a desktop monitor:

- Facets are clearly visible and each catches the light differently.
- Curved-ish forms (the oven dome, the bowl, any bush) read as faceted, not
  smooth and not sharp-edged noise.
- **Corners stay light.** No pooling, no murk. If it looks dingy, the lighting
  is wrong.
- Objects sit grounded on the floor via their contact shadow.
- The palette reads as soft pastel, not washed out and not candy-bright.
- It still reads at the size a room will actually occupy (roughly 60% of a
  landscape iPad screen).

If it fails, the usual causes in order: **smoothing left on** (facets invisible),
**too many polygons** (curves read smooth), **lighting too flat** (facets all the
same tone), **lighting too strong** (hard shadows appear). Change one at a time.

---

## Lighting without AO

> **Answered, 2026-08-15.** It holds. The approved numbers are the committed
> defaults in `app/NinaBakeryPOC/Sources/LightingSettings.swift`, tabulated in
> [`app/README.md`](app/README.md#approved-lighting). Item 3 below turned out
> not to be needed — a second directional fill light stands in for the IBL, and
> no environment asset is bundled.

The old direction leaned on baked ambient occlusion for its sense of depth. This
one deliberately does not. What replaces it, in the order the depth actually
comes from:

1. **Flat-shaded facets — the primary source, and it is free.** Hard normals mean
   every polygon returns a different value under one directional light. This is
   why the style change and dropping the bake fit together: smooth rounded clay
   has almost no normal variation, so it *needed* occlusion to avoid reading
   flat. Faceted geometry has normal variation everywhere and needs nothing.
   Cost: zero. No UVs, no textures, no bake, no runtime overhead.

2. **A real-time directional shadow.** RealityKit's `DirectionalLightComponent`
   with `DirectionalLightComponent.Shadow` gives the cast shadow that grounds
   objects — the job AO was mostly doing. Unlike a bake it is **dynamic**, so it
   stays correct when Nina drags something across the table, which baked AO
   never could.

3. **Image-based lighting for the soft fill.** `ImageBasedLightComponent` with a
   small neutral studio environment reproduces the even fill of the plates. One
   asset, authored once, reused by every room — and it is what keeps the rooms
   consistent with each other.

4. **Contact shadow blobs under draggables.** A soft dark ellipse under each
   movable object, scaled by proximity to the surface. Crude, cheap, dynamic,
   and completely convincing at this scale. Already planned in `CONCEPT.md` §9.5.

If, after all four, a specific corner still reads too flat, there are two
fallbacks that do **not** reintroduce per-asset Blender bakes:

- **Hand-darkened vertex colours.** Pull down the vertices where two surfaces
  meet. No UVs, no textures, negligible file size. It is authored art, not a
  bake, so it stays under your control.
- **Reality Composer Pro 3's light baker.** It generates ambient occlusion,
  indirect and beauty lightmaps for static scenes as a tool step, and RealityKit
  can attach them. This is the escape hatch if the scene genuinely needs
  occlusion later — it costs a tool run rather than hand-baking every asset in
  Blender, so keeping the option open costs nothing now.

**What is not available:** RealityKit exposes no screen-space AO. Do not plan
around SSAO arriving; Apple's own answer for occlusion is baked lightmaps, which
is precisely what this direction is avoiding.

---

## Stage B — the RealityKit app POC

Only once Stage A passes.

**Visually finished, functionally trivial.** In scope:

- One `RealityView`, the Stage A room box loaded as USDZ.
- Fixed isometric-ish `PerspectiveCamera`. Never moves.
- One directional light with shadows on, plus an image-based light for fill.
- **Two draggable objects and one bowl** to drop them into.
- Drag via ray-to-plane projection onto the table surface.
- Snap with a generous radius; a miss floats gently back.
- One reward on a successful drop: squash-and-stretch plus a sparkle.
- One reward sound.
- A soft dark contact blob under each draggable, scaled by proximity.

Out of scope: garden, party, persistence, cake-colour logic, voice-over, the hub,
menus, settings.

### Stage B passes if…

- The faceted look survives in-engine, not just in Quick Look.
- It holds a steady frame rate with everything on screen.
- **Nina can pick something up and drop it in the bowl without help.**

---

## Testing with Nina

**It is not finished when it works for you.** Your drag is precise and you know
what the app expects. Hers is not and she does not.

Protocol: her iPad, Guided Access on, you not helping and not narrating. Watch,
do not coach.

Three cheap things that make the session informative:

- **Log every drag path and release point.** Turns "she struggled" into "she
  releases 40pt short and low" — a fix rather than a mystery.
- **Keep the reward sound in.** With no audio reward the engagement signal is
  misleading, and repeat attempts are the main measurement.
- **Watch for palm contact.** She will rest her whole hand on the screen.

### What the POC may NOT conclude

**Nothing about whether the game is fun.** There is no game in it — no cake, no
oven payoff, no party, no reason to care yet. If she loses interest after two
drags, that is not a verdict on the concept.

Legitimate conclusions: the art direction holds or it does not; the snap radius
and target sizes need these specific numbers.

---

## Palette

The thirteen base colours, sampled from the locked plates. Full table with roles
in [`references/REFERENCES.md`](references/REFERENCES.md) §4.

| Role | Hex | | Role | Hex |
|---|---|---|---|---|
| Blush pink | `#FBD0CA` | | Cream light | `#F2E6DC` |
| Blush pink deep | `#E3B1AE` | | Cream | `#E4DACA` |
| Rose | `#EAB5AA` | | Butter yellow | `#DCC994` |
| Mint light | `#D6F0DE` | | Sandy wood | `#C79C86` |
| Mint | `#C2DECF` | | Wood brown | `#8A7A66` |
| Sage | `#A7C0AC` | | Backdrop grey | `#CFCECF` |
| Sage deep | `#7E9A88` | | | |

> **Paste these straight into Base Color.** Unlike the old clay palette — which
> was sampled from renders and carried baked lighting — these are base material
> values with no shading in them. The facets and the light supply the variation.

**Fix this palette and derive everything from it.** It is the main defence
against drift as rooms are added.

---

## Handoff

**Stage B is done, and the room after it is built.** [`app/`](app/) holds the
RealityKit project: it builds the room procedurally with flat-shaded
primitives, keeps every lighting control behind a debug panel — including the
Reality Composer Pro 3 lightmap comparison described above — and now runs the
whole kitchen round from `GAMEPLAY.md` §6.3 on top of it. See
[`app/README.md`](app/README.md).

Stage B's three pass criteria stand as written, and the third one —
**Nina can pick something up and drop it in the bowl without help** — is now
testable inside a round that has a reason to care about the bowl.

Note the app builds the room in **code**, not Blender. For primitives this
simple that turned out to be the faster loop, and it sidesteps the asset
pipeline entirely for the one question Stage A asks. Blender is still needed for
the USDZ room the lightmap comparison requires, since lightmaps need UVs.

Continuing locally with the Blender MCP connector, so a session there can drive
Blender directly and work through Stage A.

Everything needed is committed: this brief, the locked plates, the full style
spec in [`references/REFERENCES.md`](references/REFERENCES.md), and the rendering
notes in `CONCEPT.md` §9.

Any new imagery must pass the matching locked style reference — scenes
`64f0893e-073a-4065-b363-f87687ced11d`, characters
`d368acec-4085-48e4-83ff-7a57ee8ee789` — alongside its prompt.
