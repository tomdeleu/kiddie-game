# "Pick this one" — four ways

Previews for one decision: **how the game says which object to pick up next.**
There is no text in this game and never will be, so this cue carries the whole
instruction. The first version shipped as a glowing ring on the surface and the
owner did not like it, which these were rendered to settle.

All four: `flux_2` / `pro`, 1k, 1:1, one credit each, generated against the
locked scene reference `64f0893e-073a-4065-b363-f87687ced11d`. Same scene in
every one — a berry beside the mixing bowl — so only the treatment differs.

| # | File | Treatment | Seed | Job ID |
|---|---|---|---|---|
| 1 | `cue-1-ring.png` | Glowing ring on the table around the base | `511575` | `774d2670-cc9e-4157-a398-dad08f85ea13` |
| 2 | `cue-2-aura.png` | The object itself glowing, halo on its silhouette | `9182` | `713c60e0-289a-4ee2-8cb1-4e1fac3f0ad8` |
| 3 | `cue-3-sparkles.png` | Faceted stars floating around it | `382708` | `8116dd98-6329-4f72-92bb-c424f1fc9a5a` |
| 4 | `cue-4-spotlight.png` | A warm beam from above, pooling on the table | `299378` | `038dbf83-6e8d-4a88-9d5f-8d6ef17982a1` |

## What each one costs to build, and what it breaks

**1 — Ring.** What was built, and the render agrees with the complaint: it is a
hard neon hoop lying on a wooden table. It reads as a screen-space UI element
dropped into the room rather than as anything the bakery contains, and it cuts
across the base of the thing it is pointing at. Already implemented; the code
is one file, `Engine/Halo.swift`.

**2 — Aura.** Reads as *special* rather than *selected*, which is the right
feeling. Note what the render is actually doing: the glow is a soft bloom
spilling onto the wall behind, which is a post-process this renderer does not
have. The in-engine version is a slightly larger transparent shell around the
prop with an emissive material — close, but the falloff will be tighter than
this picture.

**3 — Sparkles.** The most on-style of the four, because those stars *are*
geometry — the same faceted bits `Engine/Sparkles.swift` already throws. It is
the cheapest to build and the only one that needs no new material trick. It
marks the air above the object rather than the object, so on its own it is a
slightly weaker "this one".

**4 — Spotlight.** The most legible instruction of the four, and the one that
costs the most: it contradicts the lighting the POC settled on. `POC.md` and
`REFERENCES.md` both say evenly lit, no pooled occlusion, corners stay light —
a beam is dramatic lighting, and the render darkens the whole room to sell it.
It would fight `LightingSettings`' approved values every frame.

## Decided: 2 + 3

**The object glows from within, and two or three sparkles lift off it.** Picked
by the owner from these previews; built in `Engine/Halo.swift`.

What the engine actually does, which differs from picture 2 in one way worth
knowing: there is no bloom in this renderer, so the glow is
`emissiveIntensity` on the prop's own material rather than light spilling onto
the wall behind it. Two consequences, both good:

- **The hue never changes** — only the emissive term moves, so the prop stays
  its own colour. A cue that recoloured things would teach that colour means
  something, and in this game colour means what the cake is going to be.
- **No new geometry.** An outline would need an inverted hull and back-face
  culling; this needs a material swap and the sparkle burst that already exists.

The intensity is stepped into twelve levels rather than moved every frame, so a
material is rebuilt a few times a second instead of sixty.

Two props are deliberately left out of it: **Otto**, where only the first four
surfaces light so a ten-part oven does not become a lamp, and **the doorway**,
which has its own pulse in the same visual language and would otherwise have
two jobs writing to one material.
