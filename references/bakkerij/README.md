# De Bakkerij — prop plates

Concept plates for the hub (`GAMEPLAY.md` §6.1), generated in the locked faceted
style against the scene reference
[`../plates/01-cottage-exterior.png`](../plates/01-cottage-exterior.png)
(`64f0893e-073a-4065-b363-f87687ced11d`).

They are **modelling references, not assets**. Nothing here goes into the app;
the geometry is built in `FacetedMesh` primitives from what the plate shows.

**This folder exists because the hub had no usable plate at all.** Its only two
were [`../plates/06-wall-of-frames.png`](../plates/06-wall-of-frames.png) and
[`../plates/10-wish-at-the-door.png`](../plates/10-wish-at-the-door.png), both
generated against the **retired clay reference** — smooth, terracotta and teal,
AO pooled in every corner. `../REFERENCES.md` §3 flags them "composition only,
WRONG STYLE" and lists regenerating them as a later job. This is that job, for
the props the room's required action actually needs.

All `flux_2` / variant `pro` / `1k`, **one credit each**, generated 2026-08-17,
eight in total. The style prompt is [`../REFERENCES.md`](../REFERENCES.md) §3;
studio shots swap the room-box clause for the single-object framing
[`../versieren/README.md`](../versieren/README.md) established. Every prompt asks
text out explicitly: no lettering, no numbers, no markings.

## The room

| File | Job ID | Reads as |
|---|---|---|
| `roombox-v2.png` | `8ca27aea-b37c-47ba-9a16-79d202ee11fe` | 16:9. Cream walls, pale sandy wood plank floor and slab. **A long low blush pink counter along the left wall with the frames above it, and the shop door in the right wall** — rose frame, cream leaf, faceted knob |
| `roombox.png` | `d494199a-2f4c-4363-9ea3-c923a903e900` | **FAILED — an empty room.** Kept as evidence; see below |

**Take the layout from `roombox-v2.png` and the frames from
`wall-of-frames.png`.** The room box drew six thick rounded rings where twelve
square frames were asked for, and two of them carry a checkerboard. It is right
about everything that is a *relationship* — the counter runs the length of the
frame wall, the frames sit above it, the door faces them across the floor — and
wrong about the one thing that is a *count*.

## The props the required action needs

`GAMEPLAY.md` §6.1's four steps, one plate each.

| File | Job ID | Step | Reads as |
|---|---|---|---|
| `rolluik.png` | `7c4e00e4-ebd1-423a-8fe7-d6b876da8b0e` | `opendoen` | A roll on a bar with a **chunky faceted end cap each side**, on a bracket, and a straight pull cord ending in an **8-sided butter yellow knob**. The knob is the drag target |
| `wall-of-frames.png` | `10578f03-4480-4b6a-8ff9-4adf79ac136c` | `kiezen` | Twelve chunky square frames in a loose 3×4, most empty, a few holding a small faceted cake, **one larger butter yellow frame in the bottom right** |
| `winkeldeur.png` | `0ec5507b-6662-496b-8fab-637677bf72f4` | `binnenlaten` | A rose leaf in a sandy wood frame, a **solid pale cream inset panel** in the upper half, a ~12-sided faceted knob, two flat strap hinges |
| `bestelhaak.png` | `7b5cf6b6-be2e-47f2-b03d-9eb2de97f982` | `bestellen` | A square backplate with a two-segment hook, and a flat cream card hanging off it carrying **one faceted golden droplet and nothing else** |

### Three notes for whoever models these

- **The door's hinges and knob came back on the same side.** Straps at the top
  and bottom right, knob at the centre right. Mirror the hinges; everything else
  about the leaf is right.
- **The card has rounded corners**, which `../REFERENCES.md` §1 rules out. Square
  them. It is the only bevel in the set and it is on the one prop made of paper.
- **The blind hangs half-down and its cloth is smooth.** Asked rolled *up*, drawn
  part-unrolled. It does not matter here the way it mattered for the tea towel
  (`../versieren/README.md`): a blind is a flat rectangle and a coarse cylinder,
  both of which `FacetedMesh` says easily. The end caps, the bracket and the cord
  knob are the parts worth copying.

## What was learned generating these

Three findings, and the first is new.

### A room box can come back empty, and a trailing prop list is why

`roombox.png` returned **two walls, a floor and nothing else** — no frames, no
counter, no door. Not smooth, not off-palette: simply unfurnished. That is a
third distinct room-box failure mode, alongside the two
[`../versieren/README.md`](../versieren/README.md) records (came back smooth
clay; came back off-palette).

What produced it: five prop groups in a trailing *"Contents, kept minimal and
chunky: …"* clause, followed by *"no fine detail, no clutter"*. What fixed it in
one attempt was **not more prop wording** but moving the props into the subject
sentence and cutting them to three:

> *"…of the inside corner of a small bakery shop, **furnished**: the whole left
> wall is covered with twelve chunky square picture frames, a long low blush pink
> shop counter stands on the floor in front of it, and a rose shop door … is set
> into the right wall. **These three things fill the room and must all be clearly
> visible.**"*

The general form, and it is the same shape as the smooth-clay fix: **when a room
box loses something, say it earlier and say it as the subject.** `[PROPS]` in the
shared prompt is a trailing clause, and a trailing clause is the first thing
flux drops. `../REFERENCES.md` §3's "keep `[PROPS]` short" is right and is not
the whole rule — short *and* early.

### The room-box plate wins on adjacency, not on count

The garden's README ends on *"a studio shot and a room-box shot disagree, and the
room-box shot wins"*, on the argument that half a prop's questions are about what
it is standing next to. That holds here — and this room puts a bound on it.

**flux cannot count in a room box.** Twelve frames came back as six, as rings
rather than frames, patterned. The same model, asked for the same twelve as a
studio shot, delivered twelve square frames in the right arrangement with the
gold one in the right corner. So:

> The room-box plate wins on **what a prop stands next to**. The studio plate
> wins on **what a prop is, and how many there are.**

That is the third data point for a rule already stated twice
(`../REFERENCES.md` §3: never ask for twelve characters in one image; the cast
sheet delivered eight of twelve). It is not a room-box problem or a character
problem. **flux miscounts whenever the count is not the subject of the picture.**

### Two things carried over intact from the retired plates

- **A literal grid still comes back as a warmer irregular cluster**, exactly as
  `plates/06` did in clay, and it still reads instantly as "some filled, some
  empty". `../REFERENCES.md` §3 said to adopt that rather than correct it; two
  styles now agree, so it is the design.
- **The wish card still works with no text.** One golden honey droplet, legible
  at thumbnail size — the finding `plates/10` was kept for, reproduced in the
  locked style on a prop that did not exist when that plate was made.

### And the transparency ban survived a glazed prop

A shop door is glass in every reference a model has ever seen, and
`../REFERENCES.md` §1 rules out transparency outright. Asking for *"a solid pale
cream inset panel … no glass, no transparency, no window opening, no gloss"*
returned a solid panel first time. Worth knowing before the party's lanterns.

**The design consequence is `GAMEPLAY.md` §6.1's**, not this file's: `binnenlaten`
wanted a shape showing through the glass before the friend comes in. There is no
glass, so the cue is the bell and the leaf, not a silhouette.

## The frames' two states, the toys and the sign

The second batch, generated 2026-08-17 when the room was built. The four steps
above had a plate each. These are everything else the room turned out to need.
The state the wall is actually in most of the time, the five toys `GAMEPLAY.md`
§6.1 asks for, and the sign above the door.

This session did not generate more. The files were already on disk.

| File | Job ID | Reads as |
|---|---|---|
| `lijstje-twee-staten.png` | `00e1c187-1957-4a68-8381-12b140ed69f2` | **The plate this batch was for.** One frame twice: left a pale warm-grey panel carrying a darker grey animal silhouette, right the same frame holding a small faceted layered cake behind a **warm glowing inner rim**. Both states, one picture, exactly as asked |
| `poes.png` | `6ec7a53f-5888-4b1c-9c63-56c39b541f3e` | A cat curled asleep, nose to tail, ears folded, eyes two closed curves. Blush pink over a cream chest, and **faceted all the way round** |
| `bel.png` | `30c9b18f-8107-4628-a633-51e5afcff65e` | A butter yellow dome bell with a ball clapper, on a curved arm off a flat wall backplate. The dome's facets read as horizontal bands |
| `radio.png` | `d4aa2070-fac6-4507-85b3-3f7fefcb6973` | A boxy radio: body, carry handle, round grille, **8-sided dial knob**, small buttons. Came back blush pink rather than mint |
| `raam.png` | `467d8c4e-6e20-4f99-8a84-1e6308b8819e` | A cream window frame around a **solid pale blue panel** in four panes. No glass, no reflection, first time |
| `tekeningen.png` | `82603aeb-60d8-4b76-8a4a-74074b0e110c` | Three cream sheets with **square corners**, a heart, a sun and a flower standing proud of the paper, each under a small faceted pin head |
| `uithangbord-twee-staten.png` | `d985b5c5-ec79-4501-bb52-456913dfbddc` | **FAILED its brief, kept for its geometry.** Asked for the sign washed-out grey beside the sign fully lit; both came back fully coloured. The board, the bracket bar, the two hanger rods and the cake-and-star relief are right, and that is what was modelled |
| `vriend-aan-toonbank.png` | `79c24dce-3296-4240-8a1c-c93b0ec38d51` | Staging: a mouse standing at the near end of a long low blush counter, card held out at counter height. **It is wearing Nina's apron and wings** |

**No seeds recorded for either batch**, only job IDs.

### What the second batch taught

- **A two-state plate works when the states differ by content, and fails when
  they differ only by saturation.** The frame pair came back perfect. The sign
  pair came back as the same coloured sign twice. Ask for two states only when
  you can name a different thing in each one.
- **The characters reference dresses whatever it draws in Nina's clothes.** The
  mouse in `vriend-aan-toonbank.png` arrived in the fairy's mint apron and her
  wings. Passing the characters plate to a character who is not Nina still
  borrows her costume.

## Cost

**Sixteen generations, sixteen credits**, across two batches: eight for the
required action (seven keepers and one failed room box) and eight for the frames'
two states, the toys and the sign (seven keepers and one sign that failed its
brief but was modelled from anyway).

The room's voice-over is on top of that. 37 line ids and **53 variants** in
[`../../audio/script-bakkerij.json`](../../audio/script-bakkerij.json).

This session spent **zero** more image credits. The extra plates were already
here.
