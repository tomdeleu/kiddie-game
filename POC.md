# Step 0 — the proof of concept

**This is the first thing to build.** Not game content. Rationale in
[`CONCEPT.md`](CONCEPT.md) §8; this file is the working brief.

It answers two questions the briefing cannot:

1. **Does the clay look survive on the iPad?**
2. **Can Nina drive the controls?**

The risk is lopsided. A failed visual invalidates the art direction before four
rooms get modelled. Awkward controls are tuning. So the visual is answered first,
and as cheaply as possible.

---

## Stage A — USDZ in Quick Look (about an hour, no app)

Model one kitchen room box in Blender, bake its ambient occlusion, export USDZ,
AirDrop to the iPad, open in Quick Look. Same renderer family, real screen, real
size. **If clay does not survive here, no RealityKit code will rescue it.**

Target: [`references/plates/01-kitchen-roombox.png`](references/plates/01-kitchen-roombox.png).

### Geometry

- Open corner room box: **two walls and a floor**, open on the two near sides.
- Contents, minimum: work table, mixing bowl, the domed oven, two wall shelves
  with a few jars. Skip the cake — it is not needed to judge the look.
- **Bevel every hard edge.** This is the single most important instruction. Use a
  Bevel modifier, small width, 2–3 segments, clamp overlap on. Shade smooth with
  smooth-by-angle so the bevels actually catch light. An unbevelled box will read
  as plastic no matter how it is coloured.
- Keep it chunky. Implied detail, never literal detail.

### Scale and orientation

- RealityKit works in **metres**. Build the room box around **0.4 m** across —
  large enough to work with, sane when it reaches the engine.
- **Apply all transforms** (Ctrl+A → All Transforms) so scale is 1.
- Blender is Z-up, USD is Y-up. The exporter converts, but check the result is
  not lying on its side — this is the classic USDZ surprise.

### Materials

Principled BSDF per colour:

| Setting | Value |
|---|---|
| Base Color | from the palette below |
| Roughness | **0.85–0.95** |
| Metallic | 0 |
| Specular | low |

No textures, no normal maps, no transparency. One flat colour per surface.

> **Do not paste the sampled hex values straight into Base Color.** They were
> sampled from a *render*, so they already contain the lighting and AO you are
> about to add. Start a little **lighter and flatter** than the sample, then
> compare against the plate once lit.

### Lighting

One soft key light plus broad ambient fill. A large area light and a soft
world/HDRI ambient is enough. No rim lights, no dramatic contrast.

### The AO bake — the part that matters

The pooled darkening in corners and under objects is what makes it read as clay.

1. Switch to **Cycles**.
2. UV unwrap each object.
3. Bake **Ambient Occlusion** to a texture.
4. **Multiply the AO into the base colour and bake the result down to a single
   diffuse texture per object.**

Step 4 is the important one. Exporting AO as a separate occlusion channel relies
on the viewer honouring it; baking it into base colour guarantees it survives
into USDZ and into RealityKit regardless. For a POC, certainty beats elegance.

### Export

File → Export → Universal Scene Description (`.usdz`), with materials and
textures included. AirDrop to the iPad, open in Quick Look.

### Stage A passes if…

Judged **on the iPad at arm's length**, not on a desktop monitor:

- Rounded edges are visible and catch light.
- Corners and object bases show clear soft AO pooling.
- Surfaces read as **clay** — not plastic, not cardboard, not flat cartoon.
- It still reads at the size a room will actually occupy (roughly 60% of a
  landscape iPad screen).

If it fails, the fix is almost always **more bevel** or **stronger AO** before it
is anything else. Change one at a time.

---

## Stage B — the RealityKit app POC

Only once Stage A passes.

**Visually finished, functionally trivial.** In scope:

- One `RealityView`, the Stage A room box loaded as USDZ.
- Fixed isometric-ish `PerspectiveCamera`. Never moves.
- **Two draggable objects and one bowl** to drop them into.
- Drag via ray-to-plane projection onto the table surface.
- Snap with a generous radius; a miss floats gently back.
- One reward on a successful drop: squash-and-stretch plus a sparkle.
- One reward sound.
- A soft dark contact blob under each draggable, scaled by proximity — the fake
  dynamic AO from `CONCEPT.md` §9.5.

Out of scope: garden, party, persistence, cake-colour logic, voice-over, the hub,
menus, settings.

### Stage B passes if…

- The clay look survives in-engine, not just in Quick Look.
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

Sampled from the locked plate, `references/plates/01-kitchen-roombox.png`.
Remember these are *rendered* pixels — see the warning above.

| Role | Hex | Notes |
|---|---|---|
| Background teal | `#87AFAB` | The ground the diorama sits on |
| Wall cream | `#D9C6B6` | Lit wall face |
| Wall cream, shaded | `#B4A290` | Second wall, turned away |
| Floor terracotta | `#C8957E` | |
| Floor terracotta, deep | `#BA7D64` | |
| Oven pink-terracotta | `#C1866C` | |
| Oven, shaded | `#9C563E` | |
| Wood mid | `#95715E` | Table, shelves |
| Wood dark | `#8F5B48` | |
| Sage, lit | `#909888` | Jars, accents |
| Sage, mid | `#707860` | |
| Sage, shadowed | `#505840` | |
| Deep AO shadow | `#4E2F25` | Where surfaces meet — bake, don't paint |

**Fix this palette and derive everything from it.** It is the main defence
against drift as rooms are added.

---

## Handoff

Continuing locally with the Blender MCP connector, so a session there can drive
Blender directly and work through Stage A.

Everything needed is committed: this brief, the locked plate, the full style spec
in [`references/REFERENCES.md`](references/REFERENCES.md), and the rendering
notes in `CONCEPT.md` §9.

Any new imagery must pass the locked style reference
`image_references: 9887941f-9d50-409f-ad7a-330e3b43c5d0` alongside its prompt.
