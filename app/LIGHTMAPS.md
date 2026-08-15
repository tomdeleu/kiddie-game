# Baking lightmaps in Reality Composer Pro 3

The escape hatch from `POC.md`. The art direction deliberately runs **without**
baked ambient occlusion — this file is how to test whether that was the right
call, by baking it and looking at both.

> **Nothing bakes at runtime.** The debug panel's Lightmap control does not
> bake; it applies a map produced here. Baking is an authoring step on a Mac.

## Why this exists

The clay direction needed AO because smooth rounded surfaces have almost no
normal variation to shade. The faceted direction claims it does not need AO at
all, because the facets do that job. That is a claim, and this is how to falsify
it: bake AO, put it behind a switch, and see whether anyone can tell.

Ship whichever wins. The point of the switch is that the decision gets made by
looking rather than by arguing.

## Prerequisites

- **Reality Composer Pro 3.** As of WWDC26 it is no longer bundled inside Xcode
  — download it from developer.apple.com and launch it from `/Applications`.
- **A room model with UVs.** This is the constraint that matters: lightmaps are
  textures, textures need UV coordinates, and the procedural meshes in
  `FacetedMesh.swift` deliberately carry none. So the lightmap path needs the
  USDZ room, not the procedural one.

## Step 1 — get a room with UVs

Two routes.

**From Blender** (matches `POC.md` Stage A): build the room box flat-shaded,
UV-unwrap it (Smart UV Project is fine — the unwrap only has to be
non-overlapping, not pretty), export USDZ.

**From the procedural room**: there is no exporter in this POC. If you want to
keep the code as the source of truth, add one, or rebuild the same layout in
Blender using `RoomBuilder.swift` as the spec — the dimensions are all there in
metres.

Name it `KitchenRoom.usdz`, drop it in `NinaBakeryPOC/Resources/`.

## Step 2 — bake

1. Open the room in Reality Composer Pro 3.
2. Add a **Lightmapping** component to the scene.
3. Set up the lights to match what you settled on in the debug panel. The point
   is comparing like with like — a bake lit differently is not a comparison.
4. Bake. The light baker produces three kinds of map:
   - **Ambient Occlusion** — visibility of each point to its surroundings. This
     is the one the art direction dropped, and the one to test first.
   - **Indirect** — bounced light, for global illumination.
   - **Beauty** — final colour including direct and indirect. Note this bakes
     the lighting in completely, so the model stops responding to real-time
     lights. Included in the panel for completeness, not as a candidate.
5. Export the maps as `Lightmap_AO.png` and `Lightmap_Beauty.png` into
   `NinaBakeryPOC/Resources/`.

## Step 3 — compare

In the app: set **Room** to USDZ, then flip **Lightmap** between Off and AO
while watching the corners and the undersides of the table and shelves.

What to actually look for:

- **Corners.** AO on will darken where the two walls meet the floor. The
  direction says corners stay light. Does the darkened version look better, or
  just dirtier?
- **Prop bases.** The place AO helps most. Compare against the contact-shadow
  blobs already doing this job dynamically — if the blobs are enough, AO is
  buying nothing that survives a prop moving.
- **The loose props.** Drag one. Its baked AO cannot follow it. That gap is the
  argument against baking, and it is easiest to see rather than describe.
- **Cost.** Note the file sizes and load time. A textureless build is kilobytes.

## If AO wins

It is a supported path, not a defeat — RealityKit takes lightmap textures and
RCP 3 generates them as a tool step rather than per-asset Blender work. But
before switching, weigh what comes back with it: UV unwrapping every asset,
textures in the bundle, re-baking on every art change, and static lighting for
anything that moves.

The middle option, and the one to try before a full bake: **hand-darkened vertex
colours** on the few places that actually read flat. No UVs, no textures, no
bake, and it stays under your control.

Whatever you decide, record it in `references/REFERENCES.md` and
`CONCEPT.md` §9.5 so the next session does not relitigate it.
