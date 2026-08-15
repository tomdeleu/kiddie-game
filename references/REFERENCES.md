# Art direction reference — Roblox-style low poly

Style references for *Nina's Toverbakkerij*. See
[../CONCEPT.md](../CONCEPT.md) section 9 for how this drives the rendering.

> **Screenshots** are in [`moodboard/`](moodboard/), captured via Firecrawl —
> see that folder's README for provenance and the capture method. They are page
> screenshots with browser chrome, not clean plates, because direct image
> downloads are blocked by the sandbox network policy.
>
> **The most useful thing in there is not a screenshot**: Kenney's Food Kit and
> Furniture Kit are **CC0 low-poly 3D asset packs**, 340 models between them, in
> exactly this style and free to use. Read
> [`moodboard/README.md`](moodboard/README.md) before modelling anything.

---

## 1. The written style spec

This is the part that matters. It is what gets pasted into an image prompt, and
what a model is checked against.

### Geometry

- **Very low polygon count.** Chunky, simple, readable silhouettes.
- Everything is built from **primitives**: boxes, cylinders, spheres. A jar is a
  cylinder with a lid. A tree is a cylinder plus a couple of cones.
- Slight rounding on edges is fine; sharp bevelling and chamfering is not.
- **Implied detail, never literal detail.** If a shape needs more than three
  primitives to read, simplify what it is rather than adding geometry.

### Materials

- **Flat matte.** One solid colour per surface.
- **No textures at all** — no wood grain, no fabric weave, no surface noise.
- No specular highlights, no metal, no glass, no transparency.
- In RealityKit terms: `SimpleMaterial` with roughness ≈ 1.0 and
  `isMetallic: false`; `UnlitMaterial` where a surface must stay perfectly flat.

### Palette

- Bright **pastels**: pink, mint green, cream, sky blue, soft yellow.
- High value, low-to-mid saturation. Nothing muddy, nothing neon.
- **Fix a single shared palette of roughly 12 colours and derive every asset
  from it.** This is the main defence against drift across rooms.

### Lighting

- Soft, even ambient fill plus **one** soft directional light.
- Gentle contact shadows so objects sit on surfaces rather than float.
- No harsh shadows, no dramatic or moody lighting, no colour grading.

### Composition — the diorama rule

**Every room is a small, bright diorama sitting on its own floating base.** Not a
walled interior, not a cutaway room: a self-contained little island of scenery
with clean air around it.

This was the specific thing that landed when reviewing references, and it is
more useful than "low poly" because it decides framing, lighting and geometry
all at once. It also happens to suit the game — see
[`moodboard/README.md`](moodboard/README.md) for why.

### Camera

- Fixed, slightly elevated **three-quarter angle** on the diorama.
- One camera position per room, never moved by the player.

### Characters

- Box torso, box or rounded head, cylinder arms and legs.
- **Rigid joints.** Nothing bends or deforms.
- Faces are simple dot eyes and a small mouth. Expression changes by swapping
  the mouth, not by deforming the face.
- **Fix one proportion rule** (e.g. head ≈ ⅓ of total height) and hold it across
  every character.

---

## 2. Real-world references

The canonical examples of this look, worth opening on a machine that can
actually load them:

- **Adopt Me!** — the closest match to this brief. Pastel, cute, houses and
  pets, kid audience.
- **Brookhaven RP** — modular buildings, flat colours, simple interiors.
- **Tower of Hell** — the most stripped-back version of the style.

Background reading:

- [Why the low-poly graphics style is so common — Roblox Developer Forum](https://devforum.roblox.com/t/why-the-low-poly-graphics-style-is-so-common/511551)
- [How to optimise Roblox art for better performance (low-poly tips)](https://www.vasundhara.io/blogs/how-to-optimize-roblox-art-for-better-performance-low-poly-tips)
- [Stylized low poly — Roblox Developer Forum](https://devforum.roblox.com/t/stylized-low-poly/3780170)
- [Low-poly Roblox models on CGTrader](https://www.cgtrader.com/low-poly-3d-models/roblox)
- [Low-poly Roblox game assets on itch.io](https://itch.io/game-assets/tag-low-poly/tag-roblox)

One useful thing from that reading: in Roblox, low-poly is not only an
aesthetic, it is a **performance requirement**, which is why the whole ecosystem
converged on flat colours and modular construction. The style is the product of
the same constraint we have — one person, limited asset budget.

---

## 3. Generated reference plates

Four plates generated for this briefing. All use **`flux_2`**, variant `pro`,
resolution `1k`. Recording prompt *and seed* makes each plate exactly
reproducible, which a saved PNG would not be.

| # | Subject | Aspect | Seed | Job ID |
|---|---|---|---|---|
| 1 | Bakery cottage exterior (hub) | 16:9 | `7626` | `64f0893e-073a-4065-b363-f87687ced11d` |
| 2 | Kitchen interior | 16:9 | `45937` | `639262f9-2bad-44fa-9c82-5a0db2c4e3a8` |
| 3 | Fairy baker character sheet | 3:4 | `895433` | `d368acec-4085-48e4-83ff-7a57ee8ee789` |
| 4 | Party scene with guests | 16:9 | `572557` | `672ab16f-c1f3-435a-95da-4d9f1b11fec8` |

### The shared style suffix

Every plate ends with the same block. Reuse it verbatim on any new plate so the
set stays coherent:

```
Low-poly 3D video game screenshot in the simple blocky style of Roblox.
[SUBJECT]
Chunky simple geometry, flat matte solid colours with no surface texture or
detail, bright pastel palette of pink, mint green and cream. Soft even ambient
lighting with gentle soft shadows. Simple rounded box shapes, very low polygon
count, clean and uncluttered composition. Children's game aesthetic, no
photorealism, no fine detail, no text.
```

### Per-plate subject lines

1. *A cute magic bakery cottage seen from a fixed three-quarter doll's-house
   angle, with a small garden of simple round trees and flowers in front.*
2. *Interior of a cosy magic bakery kitchen viewed from a fixed three-quarter
   angle: a simple wooden table with a big mixing bowl, a large rounded oven,
   and shelves holding chunky jars.*
3. *A cute little fairy baker character, full body, standing in a neutral
   straight pose with arms held away from the body and limbs clearly separated.
   Built from simple primitive shapes: a box torso, cylindrical arms and legs, a
   chunky rounded head, small simple wings, a tiny apron. Simple dot eyes and a
   small smile. Plain flat neutral grey background, even soft lighting, no
   shadows on the background.*
4. *A cheerful party scene: a table with a decorated pastel birthday cake in the
   centre, and three simple blocky cartoon animal characters standing around it,
   with simple triangular bunting strung overhead.*

### Locking the style once a plate is approved

`flux_2` accepts `image_references`. Once one plate is agreed as *the* look,
pass its job ID as a reference on every subsequent generation instead of relying
on the prompt alone. That is a much stronger consistency guarantee than matching
wording, and it is the step that stops the set drifting.
