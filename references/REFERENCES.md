# Art direction reference — faceted pastel low-poly

Style spec for *Nina's Toverbakkerij*. See [../CONCEPT.md](../CONCEPT.md) §9 for
how this drives the rendering, and [../POC.md](../POC.md) for the modelling
brief.

> **The anchor references are `plates/01-cottage-exterior.png` (scenes) and
> `plates/02-fairy-character.png` (characters).** Those two are the agreed look.
> Everything else follows from them.

> **This replaces the clay direction entirely.** The earlier spec — soft matte
> clay, rounded edges on everything, heavy baked ambient occlusion, terracotta
> and teal — is gone, not merely de-emphasised. Where any older text still
> describes it, this file wins. The old plates were deleted; git history has them
> if the decision ever needs revisiting.

---

## 1. The written style spec

**The style is faceted pastel low-poly.** Angular, flat-shaded geometry in a
soft pastel palette, lit evenly and photographed against a plain neutral grey
backdrop.

The single most important property: **shading comes from the facets, not from
occlusion.** Every surface is a flat polygon catching the light at its own
angle, so a faceted sphere reads as twenty distinct tones with no texture, no
lightmap and no bake. That is the whole trick, and it is what makes the style
cheap to produce.

### Geometry

- **Hard edges, flat shading, visible facets.** No bevels, no smoothing groups,
  no subdivision. A faceted surface is the point — softening it destroys the
  look exactly as surely as an unbevelled box destroyed the clay look.
- **Very low polygon count.** A bush is a 20-face icosphere. A jar is an
  8-sided prism with a lid. Angular and crisp, not smooth and rounded.
- Built from simple chunky shapes: boxes, prisms, faceted spheres, cylinders
  with few sides.
- **Low detail density.** Fewer, bigger props. The clay direction tolerated a
  shelf of six jars; this one wants three. Fine detail — labels, trim, surface
  ornament — actively fights the style.

### Materials

- **One flat solid colour per surface.** No textures. No wood grain, no fabric,
  no surface noise, no decals, no labels.
- Matte and non-metallic. No gloss, no glass, no transparency, no visible
  specular hotspots.
- **No baked lighting of any kind.** No AO maps, no lightmaps, no shading
  painted into the base colour. The material is the raw base colour; the
  renderer supplies every bit of light and shade.
- Not unlit, though — the material must respond to the light, or the facets all
  come back the same tone and the object flattens into a silhouette.

### Lighting — the signature

- **One gentle key light plus broad even fill.** The facets create the contrast;
  the lighting only needs to be directional enough to differentiate them.
- **A soft contact shadow under each object**, grounding it on the floor or
  slab. This is the one shadow that matters.
- **No ambient occlusion.** No darkening pooled into corners, no murk where
  surfaces meet. Corners stay light. This is a deliberate inversion of the old
  spec, where AO *was* the signature.
- No hard shadow edges, no dramatic contrast, no rim lights, no colour grading.

### Palette

- **Soft pastels**, light and desaturated: blush pink, mint, cream, butter
  yellow, sage, sandy wood. Notably lighter and cooler than the retired
  terracotta-and-teal palette.
- **Plain neutral grey backdrop** on reference plates — not teal. Grey is a
  studio backdrop: it shows the asset without lending the scene a mood the game
  will not have.
- Full values in [section 4](#4-the-palette). **Fix that palette and derive
  every asset from it.**

### Composition — the room-box rule

**Every room is an open corner room box**: two walls and a floor, open on the
two near sides, sitting on a slim square base slab, seen from a fixed isometric
three-quarter angle.

This survives the style change unchanged, because it was never a style
decision — it is a gameplay one:

- No wall ever comes between the camera and a prop.
- The two open sides give a natural home for the back arrow and the music pads.
- Each room is modelled and lit independently, then slid in and out as one
  object when moving between rooms — a transition a 4-year-old can read.

The base slab is new, taken from the cottage plate. It gives every room a
consistent visual footing and a surface for the contact shadow to land on.

### Camera

- Fixed isometric three-quarter angle on the room box.
- One camera position per room, **never** moved by the player.
- Plates are rendered 16:9 to match the landscape iPad framing.

### Characters

- Chunky angular body, faceted head, simple prism arms and legs.
- **Rigid joints.** Nothing bends or deforms.
- Simple dot eyes and a small mouth. Expression changes by swapping the mouth.
- **Fix one proportion rule** (e.g. head ≈ ⅓ of total height) and hold it.
- Per `plates/02-fairy-character.png`: merged arms are fine — the rig only
  splits out the legs. See `CONCEPT.md` §9.7.

---

## 2. Why this style makes the rendering cheap

Worth stating explicitly, because it is the main practical argument for the
change:

| | Clay direction | Faceted low-poly |
|---|---|---|
| Where shading comes from | baked AO map | facet normals, at runtime |
| UV unwrapping | every asset | **none** |
| Textures per asset | 1+ baked diffuse | **none** |
| Re-colouring an asset | re-bake | change one material value |
| Moving props lit correctly | no (bake is static) | **yes** |
| Kenney kit rework | re-material **and** bake AO | re-material only |

The last row is the big one. Kenney's kits arrive **flat-shaded and
hard-edged** — which was a defect to be corrected under the clay direction, and
is exactly the target shading model under this one. They now need a palette
swap and nothing else.

---

## 3. Generated reference plates

All plates use **`flux_2`**, variant `pro`, resolution `1k`.

| # | Subject | File | Aspect | Seed | Job ID |
|---|---|---|---|---|---|
| 1 | **Cottage exterior — THE LOOK (scenes)** | `plates/01-cottage-exterior.png` | 16:9 | `7626` | `64f0893e-073a-4065-b363-f87687ced11d` |
| 2 | **Fairy character — THE LOOK (characters)** | `plates/02-fairy-character.png` | 3:4 | `895433` | `d368acec-4085-48e4-83ff-7a57ee8ee789` |
| 3 | Bakery kitchen room box | `plates/03-kitchen-roombox.png` | 16:9 | `922798` | `37de2697-7cee-423d-ae7b-4a0a8573ac3b` |
| 4 | Party room box | `plates/04-party-roombox.png` | 16:9 | `733201` | `0bbbe4f2-409d-4957-8491-e3c1eca41e31` |
| 5 | Garden room box | `plates/05-garden-roombox.png` | 16:9 | `504123` | `e70b82a3-1c74-4df5-96f4-2028205eda3c` |

Plates 1 and 2 are the originals the direction was chosen from; 3–5 were
generated against them. Refresh the files with
[`fetch-plates.sh`](fetch-plates.sh). The seeds matter more than the files: they
regenerate the plates exactly, and unlike a CDN link they do not expire.

Two notes on how the set was actually produced, because the plates do not all
come from the same recipe:

- **Plates 1 and 2 predate the style prompt below.** They were generated from a
  "blocky style of Roblox" prompt, which is *not* the wording to reuse — it is
  what produced the Minecraft-ish party characters in the same batch. The prompt
  in this file describes what those two plates actually look like, which is the
  thing to reproduce.
- **Plate 4 used the milder first-pass prompt** and the cottage reference only.
  It is kept because its faceted pastel guests came out better than the strict
  prompt's did; that attempt pulled the fairy character in and returned
  cat-eared hybrids. Its exact prompt is on its job record.

### The locked style references — USE THESE

Pass the matching reference as an `image_references` input on **every**
subsequent image generation, alongside the prompt:

```
model  flux_2   variant pro
medias [{ role: "image_references",
          value: "64f0893e-073a-4065-b363-f87687ced11d" }]   # scenes
        [{ role: "image_references",
          value: "d368acec-4085-48e4-83ff-7a57ee8ee789" }]   # characters
```

**Pick one, matched to the subject.** Passing both was tried for the party
plate and the character reference bled into the scene — the party guests came
back as fairy-hybrids with cat ears rather than animals. Use the character
reference only when generating a character.

**Prompt *and* reference, never the reference alone.** The reference alone is
also not enough: the first pass at plates 3–5 passed the cottage reference with
a mild prompt and came back smooth and over-detailed — flux_2's default for
"isometric 3D render" is smooth clay, and it will drift there unless the prompt
fights it. The facet wording below is what pulled it back.

**Do not pass the moodboard screenshots as references.** Two of those sources
carry explicit no-AI terms.

### The shared style prompt

Reuse verbatim on any new plate. The order matters — style first, subject
second:

```
Flat-shaded low-poly 3D render of [SUBJECT]. Hard-edged faceted geometry: every
surface is a flat untextured polygon facet with visible straight polygon edges,
angular and crisp, very low polygon count. No smooth curved surfaces, no rounded
bevels, no subdivision, no surface texture, no fine detail, no clutter. Built as
an open corner room box: two walls and a floor, open on the two near sides,
sitting on a slim square base slab, seen from a fixed isometric three-quarter
angle. Contents, kept minimal and chunky: [PROPS]. Soft pastel palette only:
blush pink, mint green, cream, soft butter yellow, pale sandy wood. Soft even
studio lighting, one gentle key light, a soft contact shadow on the ground, no
hard shadow edges, no dark corners, no ambient occlusion pooling. Plain neutral
light grey background. Children's game aesthetic, no photorealism, no text.
```

For a character, swap the room-box clause for: *full body, standing in a neutral
straight pose with arms held away from the body and limbs clearly separated,
plain neutral grey background*.

The phrases doing the real work are **"flat-shaded low-poly"**, **"visible
straight polygon edges"**, **"no smooth curved surfaces"** and **"no ambient
occlusion pooling"**. Drop the facet phrases and it reverts to smooth clay;
drop the last one and it pools shadow into the corners.

Keep `[PROPS]` short. Every extra prop named is another chance for the model to
add fine detail the style does not want.

---

## 4. The palette

Sampled from the two locked plates and normalised to **base** colours.

> **These are base material colours, not rendered pixels.** Under flat shading a
> lit facet comes back brighter than its base and a turned-away facet darker —
> that variation is the renderer's job, not the palette's. Set these values in
> Base Color and let the light do the rest. If you sample a plate directly,
> take a mid-tone facet, never the brightest one.

| Role | Hex | Used on |
|---|---|---|
| Blush pink | `#FBD0CA` | Character skin/body, soft props |
| Blush pink deep | `#E3B1AE` | Cottage roof, accents |
| Rose | `#EAB5AA` | Doors, trim, raised beds |
| Mint light | `#D6F0DE` | Hat, apron, highlights |
| Mint | `#C2DECF` | Walls, the oven |
| Sage | `#A7C0AC` | Foliage, bushes |
| Sage deep | `#7E9A88` | Foliage variation, window frames |
| Cream light | `#F2E6DC` | Lit walls |
| Cream | `#E4DACA` | Base slab, paths |
| Butter yellow | `#DCC994` | Accent trees, flowers |
| Sandy wood | `#C79C86` | Tables, shelves |
| Wood brown | `#8A7A66` | Trunks, fence, dark accents |
| Backdrop grey | `#CFCECF` | **Reference plates only** — never in-game |

Thirteen colours. **Fix this palette and derive everything from it.** It is the
main defence against drift as rooms are added.

Note there are no `lit` / `shaded` / `deep AO shadow` entries. The old palette
needed them because the shading was painted in; this one does not, and adding
them would defeat the point.

---

## 5. Real-world references

- Search terms that find more of this look: *flat shaded low poly*, *faceted
  low poly pastel*, *low poly isometric diorama*, *Blender flat shading low
  poly*, *pastel low poly game art*.
- [`moodboard/`](moodboard/) holds earlier screenshots. Most were gathered for
  the retired clay and Roblox directions and no longer describe the target —
  check that folder's README for provenance and licence before using any of it,
  and prefer the plates above.

The style is neither of the two earlier framings. It is not Roblox — Roblox is
blocky, bright and hard-edged, and prompting for it produced Minecraft-ish
characters that missed. It is not clay — clay is smooth, rounded and
occlusion-heavy. It is faceted, pastel and evenly lit.
