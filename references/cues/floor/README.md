# The step cue, third attempt: on the floor

Six ways of marking the one prop a step is about **without touching the prop's
own colour**. Same strawberry, same tabletop, same camera in all six, so the
only variable is the cue.

**A won.** Owner's pick, 2026-08-15, with one note: *yellow, and as soft as the
render*. It is built in [`Halo.swift`](../../../app/NinaBakeryPOC/Sources/Engine/Halo.swift).

| File | Cue | Job ID |
|---|---|---|
| **`A-ring.png`** | **A ring of light lying on the surface — chosen** | `7dd3e506-d4e4-492d-9a10-7bb9f0583011` |
| `B-pool.png` | A soft pool of glow spilling out from the base | `96d54a95-88a3-4de7-aa8b-d73d21b0c368` |
| `C-star-ring.png` | A ring of small stars floating just above the surface | `241251d1-503e-4fe0-b68a-0a51a1d61d0d` |
| `D-podium.png` | The prop stands on a small glowing faceted disc | `f70033b5-d6fc-40f7-a9de-f065cb3c4e30` |
| `E-arrows.png` | Eight small glowing triangles pointing inward at the base | `25bff834-95a5-44a9-9cfb-a197e960ae09` |
| `F-ring-plus-stars.png` | A ring with stars rising out of it | `11ed82d6-4f6e-40e4-8970-a0bad568fa6f` |

All `flux_2` / `pro` / `1k` / 1:1 against `../../plates/01-cottage-exterior.png`,
one credit each. Every prompt says explicitly that the strawberry itself is
**not** glowing and keeps its own flat colour — without that line, flux lights
the object as well and the comparison is worthless.

## The third attempt, and why the first one failed

This is the same idea as the ring in [`../`](..) that was **rejected** a
session earlier, and the difference is worth being precise about, because
"we already tried that" is the wrong lesson to take from it.

The rejected one was a **hard-edged hoop**: a bright even line of colour with
the wood on both sides of it. It read as a screen-space UI element dropped into
the room, because a hard edge is what UI has and light does not.

A is soft. The band is bright at its core and fades over about a third of its
own radius on each side, so it reads as light falling on wood. Sampling the
plate: the core washes out to `#FDF6D0`, the true colour of the band is
`#F6D861`, and the wood inside the ring is `#DEC3B1` against `#D2C4B8`
elsewhere — barely warmed. So the interior is **not** filled, which is the
other thing the rejected version got wrong.

## What was between them

The cue that shipped in between was **the object itself lit from within**,
picked from the same earlier preview set. It failed on the iPad twice over:
first it was invisible, and then, turned up far enough to see, it was
recolouring an entire prop to say one thing. `Halo.swift` has the full account
of why a pastel object under a bright key cannot be brightened usefully.

Three cues in, the pattern is that this decision cannot be made from a render.
All three looked fine as plates. **Judge the next one on the device.**

## What was built from A

Not a texture. Eighteen concentric bands of geometry at graded opacities, with
a Gaussian profile centred on the ring radius — a radial-gradient texture would
need `TextureResource.generate`, a hand-built `CGImage`, UV coordinates
`FacetedMesh` does not produce, and an assumption about `UnlitMaterial`
respecting a base-colour texture's alpha. Each of those can fail on a first
build, and the failure mode is a bright yellow square.

The ring is a **sibling** of the prop, not a child, and is placed each frame at
the prop's XZ on whatever surface is beneath it. That is what lets it stay on
the table while she lifts the prop off it, and climb onto the plank with the
cake at the end of the round.
