# Art direction reference — cosy isometric clay miniature

Style references for *Nina's Toverbakkerij*. See
[../CONCEPT.md](../CONCEPT.md) section 9 for how this drives the rendering.

> **The anchor reference is `moodboard/08-dribbble-isometric-bakery.png`.**
> Everything else in [`moodboard/`](moodboard/) is secondary — check that folder's
> README for provenance and licence before using any of it.
>
> Kenney's Food Kit and Furniture Kit are still the **geometry** source (CC0, 340
> models). They do not arrive in this style — they are flat-shaded and
> hard-edged — so they need re-materialing and relighting. Still far cheaper
> than modelling from scratch.

---

## 1. The written style spec

**The style is a cosy isometric clay miniature.** The anchor reference is
`moodboard/08-dribbble-isometric-bakery.png` — that is the target.

This is a deliberate move away from the earlier Roblox framing. Roblox is flat,
bright and hard-edged; this is soft, warm and shaded. Where the two conflict,
this wins.

### Geometry

- **Rounded edges on everything.** This is not optional decoration — soft edges
  are what catch the light and make a surface read as clay rather than plastic.
  A sharp-edged box will look wrong no matter how it is coloured.
- Built from simple, chunky, readable shapes: rounded boxes, cylinders, spheres.
- Moderate detail density. Higher than pure primitives, far below realism: a jar
  is a rounded cylinder with a lid, but a shelf may hold six of them.
- **Implied detail, never literal detail.**

### Materials

- **Soft matte clay** — like smooth polymer modelling clay.
- One solid colour per surface. **No textures**: no wood grain, no fabric weave,
  no surface noise.
- No metal, no glass, no transparency, no visible specular hotspots.
- Not *unlit*, though. See lighting — the material must respond to light or the
  whole effect collapses.

### Lighting — the signature

This is what makes the reference look like clay, and it is the part most easily
got wrong.

- **Ambient occlusion is the defining feature.** Soft darkening pooling in every
  corner, under every object, wherever two surfaces meet. Without it the scene
  reads as flat cartoon; with it, it reads as a physical object you could pick
  up.
- **Soft diffuse shadows with no hard edges.** One gentle key light plus a broad
  ambient fill.
- No dramatic contrast, no colour grading, no rim lights.
- Objects must feel **grounded** — a contact shadow under everything.

### Palette

- **Warm and muted**, not bright and saturated: terracotta, salmon pink, cream,
  sage green, warm brown.
- Backgrounds are plain, soft, and cool — a flat soft teal sets off the warm
  scene without competing.
- **Fix a single shared palette of roughly 12 colours and derive every asset
  from it.** The main defence against drift between rooms.

### Composition — the room-box rule

**Every room is an open corner room box**: two walls and a floor, open on the
two near sides, seen from a fixed isometric three-quarter angle.

Not a walled interior — the camera is never inside the room. Not a floating
island either; that was an earlier read, and the room box is what the anchor
reference actually does.

This suits the game as well as the eye:

- No wall ever comes between the camera and a prop.
- The two open sides give a natural place for the back arrow and the music pads.
- Each room can be modelled and lit independently, then slid in and out as a
  single object when moving between rooms — a transition a 4-year-old can read.

### Camera

- Fixed isometric three-quarter angle on the room box.
- One camera position per room, **never** moved by the player.
- In-game framing is landscape; the square plates here show the style, not the
  final crop.

### Characters

- Rounded box torso, rounded head, soft cylindrical arms and legs.
- **Rigid joints.** Nothing bends or deforms.
- Simple dot eyes and a small mouth. Expression changes by swapping the mouth.
- **Fix one proportion rule** (e.g. head ≈ ⅓ of total height) and hold it.

## 2. Real-world references

- **The anchor**: [3D Cute Isometric Bakery — Naomi, on Dribbble](https://dribbble.com/shots/21332763-3D-Cute-Isometric-Bakery-made-in-Blender).
  Reference only; © the artist.
- Search terms that find more of it: *isometric room box*, *cosy 3D miniature*,
  *clay render*, *Blender isometric diorama*, *cute 3D room*.

The earlier Roblox references are retired. They remain in git history if the
direction ever needs revisiting, but they describe a flatter, harder-edged,
brighter look than the one now agreed.

---

## 3. Generated reference plates

All plates use **`flux_2`**, variant `pro`, resolution `1k`. Recording prompt
*and seed* makes each exactly reproducible, which a saved PNG would not be.

### Current set — clay direction

| # | Subject | Aspect | Seed | Job ID |
|---|---|---|---|---|
| 1 | Bakery kitchen room box | 1:1 | `822183` | `9887941f-9d50-409f-ad7a-330e3b43c5d0` |
| 2 | Bakery cottage exterior | 1:1 | `270825` | `5bc6e6db-ffa5-4fff-b378-7661a9060e3a` |
| 3 | Fairy baker character sheet | 3:4 | `409079` | `13e7c536-befa-462f-bf19-c632f74a8e83` |
| 4 | Party room box | 1:1 | `884050` | `6eaffc62-3809-4985-80be-67d78eaf0bf1` |

Direct links, in case the CDN is reachable from where you are reading this:

1. [Kitchen room box](https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ/hf_20260815_074713_9887941f-9d50-409f-ad7a-330e3b43c5d0.png)
2. [Cottage exterior](https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ/hf_20260815_074712_5bc6e6db-ffa5-4fff-b378-7661a9060e3a.png)
3. [Fairy character sheet](https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ/hf_20260815_074713_13e7c536-befa-462f-bf19-c632f74a8e83.png)
4. [Party room box](https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ/hf_20260815_074712_6eaffc62-3809-4985-80be-67d78eaf0bf1.png)

**The plates are not committed to this repo.** The Higgsfield results CDN
(`d8j0ntlcm91z4.cloudfront.net`) is denied by the sandbox egress policy, so a
session cannot save them. Run [`fetch-plates.sh`](fetch-plates.sh) from a machine
that can reach it — or allowlist that host on the environment and re-run it here.

The seeds below matter more than the files: they regenerate the plates exactly,
and unlike a CDN link they do not expire.

### The shared style suffix

Reuse verbatim on any new plate so the set stays coherent:

```
Isometric 3D render of [SUBJECT], built as an open corner room box: two walls
and a floor, open on the two near sides, seen from a fixed isometric
three-quarter angle. Everything modelled in soft matte clay, like smooth
polymer modelling clay, with gently rounded edges on every surface. Strong soft
ambient occlusion pooling in the corners and under every object, soft diffuse
shadows, no hard shadow edges. Warm muted palette: terracotta, salmon pink,
cream, sage green and warm brown, against a plain soft teal background. Cosy
miniature diorama, cute, clean and uncluttered, no photorealism, no text.
```

For a character, swap the room-box clause for: *full body, standing in a neutral
straight pose with arms held away from the body and limbs clearly separated,
plain soft teal background*.

The phrases doing the real work are **"soft matte clay"**, **"gently rounded
edges"** and **"strong soft ambient occlusion"**. Drop any of the three and the
result reverts to generic flat cartoon.

### Locking the style once a plate is approved

`flux_2` accepts `image_references`. Once one plate is agreed as *the* look, pass
its job ID as a reference on every subsequent generation rather than relying on
prompt wording. That is a much stronger consistency guarantee, and it is the step
that stops the set drifting.

**Do not pass the moodboard screenshots as references.** Two of those sources
carry explicit no-AI terms.
