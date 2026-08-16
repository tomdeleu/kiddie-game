# Versieren — prop references

Concept plates for the decorating room (`GAMEPLAY.md` §6.4), generated in the
locked faceted style against the scene reference
[`../plates/01-cottage-exterior.png`](../plates/01-cottage-exterior.png).

They are **modelling references**, not assets. Nothing here goes into the app;
the geometry is built in `FacetedMesh` primitives from what the plate shows.

All `flux_2` / variant `pro` / `1k` / 1:1, one credit each, generated
2026-08-16. The style prompt is [`../REFERENCES.md`](../REFERENCES.md) §3 with
the room-box clause swapped for the single-object framing:

> One single object, studio shot, no scenery, nothing else in frame, very large
> and centred, filling most of the square picture, with a wide generous empty
> margin of background all the way around so nothing touches any edge.

Plus, on every prompt, **no numbers, no lettering, no markings** — `CONCEPT.md`
§5 forbids text she has to read.

## The room

| File | Job ID | Reads as |
|---|---|---|
| [`../plates/07-decorating-roombox-v2.png`](../plates/07-decorating-roombox-v2.png) | `3bac243f-067b-43ae-ba50-655ffc325f41` | 16:9. Cream walls, blush pink floor, sandy wood slab. Faceted turntable on a pedestal in the middle carrying a big chunky three-tier cake; four shallow trays in a row along one open floor edge |

It replaces `07-decorating-roombox.png`, which was generated against the
**retired clay reference** — smooth, terracotta and teal, AO in every corner.
The old file is kept as the record of what it replaced; read it for staging
only, and not even for that now this one exists.

**Two things this plate settles**, and both go straight into `VersierLayout`:

- **The cake is the subject and it is big** — roughly a quarter of the room's
  width. The kitchen's cake is 52 mm across, which is about 82 pt on screen and
  hopeless as a canvas for forty stickers. The decorating room presents it
  scaled up.
- **The trays sit on the floor along an open edge**, not on a table. That is
  what makes room for seven of them.

## Tools and furniture

| File | Job ID | Reads as |
|---|---|---|
| `draaitafel.png` | `2dea2f43-15a4-470f-ac52-f04347a31171` | **~14-sided plate with a visible rim band, on a ~10-sided tapered pedestal, one square-section handle off the rim.** The handle is the drag target |
| `spuitzak.png` | `a4461d67-6286-433d-a3ab-b4435c5063a3` | **A ~10-sided tapered cone, a gathered collar with a tie, a fanned crown above it, an octagonal nozzle collar and a cone tip.** The crown is the flour-sack problem again — cloth is where the `FacetedMesh` vocabulary runs out; simplify it rather than chase it |
| `strooibus.png` | `bf8f3c57-a530-4240-bbcb-12964d8f44ec` | **~10-sided barrel body, two-part mint cap: a collar ring and a perforated dome.** The perforations are a detail the code skips |
| `bakje.png` | `8161e3b2-879e-42ee-833a-c50fbdd90ff1` | A shallow open box with a low rim and a flat inside floor. Five boxes. This one mesh is reused seven times |

## The seven sticker shapes

At token size the facet count *is* the design, so each one got its own plate.

| File | Job ID | Reads as | Built from |
|---|---|---|---|
| `hartje.png` | `8fe4abc1-1916-49de-abf8-d66104a6a42a` | A **solid** faceted heart, not a flat plate — two lobes and a wedge point | Three convex `extrude`s. **`extrude` is convex-only** (`FacetedMesh.swift:429`) — one heart outline would fan-triangulate wrong |
| `sterretje.png` | `7de7d8bf-cf95-4250-9171-7892c6a38b93` | A puffed five-point star with a ridge down every arm | `FacetedMesh.star` exactly, which already builds the ridge. Free |
| `kroontje.png` | `5eb63ee1-bddc-4f5f-8629-3350d703a2c0` | A ~10-sided band with five sharp triangular points rising off it | `prism(sides: 10)` + five triangle `extrude`s, each convex |
| `kaarsje.png` | `57e2a83d-dc47-40a3-bf17-ac1aeaf995ef` | A hexagonal-prism candle with a faceted teardrop flame on a short wick | `prism(sides: 6)` + a small `lathe` flame. **No stripes** — asked out, and it obeyed |
| `fruitje.png` | `80be85a3-83ee-4ca2-a884-c5bbf83a20a6` | A faceted ball with a bent stalk leaning off the top | `icosphere(subdivisions: 1)` — the documented sweet spot at 80 faces — plus a two-segment stalk |
| `roomtoefje.png` | `4a271b74-f293-41a6-bd6a-42d0d22da653` | **Three stacked rings tapering to a point**, each ~10-sided | One `lathe` profile. The plate is a ready-made profile table |
| `sprinkel.png` | `7ffc1674-4b7e-4564-a2e9-29b35ac44835` | Short hexagonal rods with mitred ends, scattered loose | `prism(sides: 6)`, ~4 mm long. The shaker emits **one entity per grain** — Pip's wish is ≥ 8 sprinkles, so they have to be countable |

## Toys

| File | Job ID | Reads as | Verdict |
|---|---|---|---|
| `glitterpot.png` | `6b562249-5aba-4bb6-91d5-e34b5f60d53e` | ~10-sided tapered pot with a rim, a matching ~10-sided lid lying beside it, filled with faceted nuggets | **In** |
| `taartborden.png` | `709053c7-6300-4c77-9ed2-687cbad696bc` | A stack of ~10-sided discs at graded diameters | **In** |
| `wandplank-potjes.png` | `e1b293dc-476e-4adb-b1be-f60c4bd9b57b` | A plank on two triangular brackets with three 8-sided lidded jars | **In.** The kitchen's shelf geometry with different contents |
| `krukje.png` | `87966d90-07ff-4c67-8ca3-da105c716f0e` | A ~14-sided disc seat on three straight tapered legs | **In.** Promoted from set dressing to the fifth toy |
| `kwastje.png` | `2222191c-e0cf-4bc4-9ad9-17a9daa71aae` | A tapered flat handle, a ferrule block, and a bristle block with cut slots | **In**, but the slots are fine detail — build the bristles as one block |
| `theedoek.png` | `729343ea-0984-4b7c-988e-f8d1fd9dd1e8` | A folded cloth with faceted rolled edges and soft flat top faces | **CUT** — see below |

### Why the tea towel was cut

It is the one plate here that is not on style, and it failed the way the plan
predicted it might: the rolled edges are faceted but the top faces are smooth,
so it reads as a folded sheet rather than as a faceted prop. That is the same
wall `models/flour-sack.py` records — **cloth is where the `FacetedMesh`
vocabulary runs out**, and a gather or a fold is exactly what it cannot say.

It is kept on disk because the plate is the evidence, and because a Blender
pass could have it later if the room ever wants a sixth toy. The stool takes
its place, which cost nothing: it was already generated as set dressing and a
stool that wobbles when tapped is as good a toy as a cloth that flaps.

## What was learned generating these

- **The room box took three attempts and the first two failed differently.**
  The first came back smooth clay — the failure `../REFERENCES.md` §3 warns
  about — despite carrying all four facet phrases. The fix was not more facet
  wording in general but **naming the objects that were coming back smooth**:
  *"EVERY object, including the cake and the round turntable"* and *"round
  shapes are coarse polygons with about ten straight sides, never smooth"*.
  Single-prop plates never needed this; only the room box did, because in a
  room box every prop is small in frame and the model spends its polygons on
  the walls.
- **The second attempt fixed the facets and lost the palette** — walls went
  pale blue-grey and the floor lilac, neither of which is in the thirteen.
  Naming the surfaces by colour (*"two cream walls and a blush pink floor…on a
  pale sandy wood slab"*) and adding an explicit **"no blue, no lilac, no
  grey-blue, no cold colours anywhere in the room"** fixed it in one go. The
  general lesson: *the palette list alone does not bind; naming the large
  surfaces does.*
- **Eleven requests in one batch is rate-limited.** `generate_image_batch`
  accepts up to 12, but flux_2's backend returned 429 for all eleven. Three at
  a time, waited with `jobs_wait`, went through every time.
- **Asking for a coarse side count works and is worth doing.** *"about ten
  straight sides, never smooth"* is what took the cake boards and the stool
  seat from smooth discs to countable facets — and a countable facet is
  directly the argument to `prism`.

## Cost

Twenty generations, twenty credits: seventeen keepers, two discarded room-box
attempts, and one plate cut. Balance is checked with `balance` before and after;
note that **other sessions on the same account spend from the same balance**, so
a drop larger than the number of images here is not necessarily this work.
