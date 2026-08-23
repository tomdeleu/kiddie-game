# Het Feest — the disco

Concept plates for `GAMEPLAY.md` §6.5, generated 2026-08-17 for the room the
owner asked for: **a discotheque, with lights and a DJ, and of course cakes and
friends.**

Seventeen keepers, `flux_2` / `pro`, 1k, plus one discarded lettered variant of
the VIP rope. Fifteen of the keepers are this room's original set — three of
those a **second pass at the guests**, see `beertjes.png` below — the sixteenth
is [`../plates/11-finale.png`](../plates/11-finale.png), regenerated because the
finale is the party and the party is now a disco, and the seventeenth is the
VIP rope that became the way out on 2026-08-21.

**Read these for shape and for what a thing is made of.** They are the brief for
`FeestProps.swift`, not assets — nothing here goes into the app
(`CLAUDE.md`'s three exceptions are the film, the icon and the loading screen,
and none of them is a prop).

## The plates

| Plate | File | Aspect | Seed | Job ID | Reference |
|---|---|---|---|---|---|
| The room box | `roombox.png` | 16:9 | `144028` | `35b22631-d997-46c4-bbcf-fab80d98e02e` | scenes |
| The DJ booth | `dj-booth.png` | 1:1 | `431532` | `7f12c414-81f2-4615-a7cd-5c03ce2a16f9` | scenes |
| The mirror ball | `discobal.png` | 1:1 | `365319` | `f3aa09eb-7596-4678-b67d-6a064ae610c0` | scenes |
| The light bar | `lichtrek.png` | 1:1 | `658178` | `c82c9dfc-069b-4ee1-ae9e-ecd767cfd69a` | scenes |
| The dance floor | `dansvloer.png` | 1:1 | `914251` | `9410c2d0-5808-4b9e-b71c-1372371bae2f` | scenes |
| The six pads | `knoppen.png` | 1:1 | `282400` | `659ab77d-1898-4755-898d-be7bb370fbbd` | scenes |
| The speaker stack | `boxen.png` | 1:1 | `631947` | `b9aa0a56-7bc2-4a72-bfb3-721172286f18` | scenes |
| The cake table | `taarttafel.png` | 1:1 | `909546` | `9c78cb1c-1094-4690-8eff-b0c8282e041d` | scenes |
| The confetti popper | `knaller.png` | 1:1 | `282546` | `6c9aee60-1c5f-4ebe-8ebc-5881fe852a1c` | scenes |
| The balloon | `ballon.png` | 1:1 | `636893` | `8edc1d76-625f-4836-9cf4-76f8ec6e13c6` | scenes |
| **The DJ** | `dj.png` | 3:4 | `215924` | `5a975394-aa91-4496-aca7-30a1baf8bdc0` | **characters** |
| **The guests** — superseded | `gasten.png` | 16:9 | `196279` | `17ef0f76-f670-4ffd-9a17-bd5608f7b960` | **characters** |
| **The guests, rebuilt** | `beertjes.png` | 16:9 | `314116` | `10e00dce-fcb5-4686-8c76-cf3491035a1f` | **characters** |
| The dance poses | `beertjes-dansen.png` | 16:9 | `971082` | `562e7144-fefb-4481-a4f9-d6b6b8849c24` | **characters** |
| One bear, large | `beertje-solo.png` | 3:4 | `753928` | `e32fc1a8-b7e0-4bbb-925b-5ae247050dac` | **characters** |
| The finale | `../plates/11-finale.png` | 1:1 | `9333` | `f6429693-912d-4988-829f-970ceed3cd34` | scenes |
| **The VIP rope** | `vip-touw.png` | 1:1 | — | `75f0ae9a-cf81-4220-adfb-f9918ac08178` | scenes |
| **The VIP rope** — discarded, letters | `vip-touw-letters.png` | 1:1 | — | `04474192-f583-4572-945d-b1d241b2eb02` | scenes |

The VIP rope is the disco's way out as of 2026-08-21 (owner: tapping the cake
should not end the room; the door must not be the kitchen's). Two variants in
one `flux_2` / `pro` / `1k` / 1:1 job against the scenes reference, generated
once the connector was reauthenticated the same day. The seed did not come
back on the job record or in the PNG; the job IDs did.

**`vip-touw.png` is the keeper for the posts and the rope.** Two butter-yellow
octagonal stanchions with faceted ball tops, a gold collar at each neck, a
thick blush rope hanging in a U with metal end caps. No letters. That is what
`Props.vipRope` builds: tapered eight-sided posts, a collar ring rather than a
mid-post hook, metal caps on the ribbon, a deeper sag, and a slim butter-yellow
frame.

**The hole in that plate is cream light, and the room overrules it.** Owner's
call, 2026-08-23: it is evening outside. The plate in the opening is matte
`Palette.eveningSky` — a dusty dusk rectangle in the cream wall — the same
kind of exception as the kitchen's wood leaf against a cream plate. The disco
around it stays bright; dark is the subject of the hole, not a lighting change.
Higgsfield's session had expired again when this was decided, so there is no
evening keeper yet. Re-render when the connector is back, same recipe as
above, with the opening named as dark dusk evening sky rather than a cream
glow, and keep the fifth disco phrase on the *posts and the wall* so flux
does not dim the whole shot.

**`vip-touw-letters.png` is the discard.** Same idea, but flux wrote **VIP**
across the lintel even though the prompt named letters, a VIP sign and words as
things not to draw. The game has no text anywhere (`CONCEPT.md` §5), so a plate
with three letters on it cannot be the brief. Kept on disk the way `gasten.png`
is, so the next disco prompt that thinks "no text" is enough still has the
counter-example.

Full prompts are on the job records. All seventeen keepers carry `CLAUDE.md`'s
four style phrases; the eleven disco ones carry a fifth clause and the three
bear plates carry a sixth — both are below.

## The fifth phrase: *not a dark nightclub*

**The thing this room could have got wrong, and the one line of prompt that
stopped it.**

`references/REFERENCES.md` §1 asks for soft even lighting, no dark corners and no
occlusion pooling. A disco is the opposite of all three, and asking flux for one
gets exactly what you would expect: darkness, moody club lighting, volumetric
haze, lens flare. That is not a plate that is slightly off-style — it is a plate
from a different game.

Every disco prompt therefore carries, after the four locked phrases:

> *Brightly and evenly lit — this is a daytime pastel toy disco, not a dark
> nightclub: no darkness, no moody club lighting, no lens flare, no haze, no
> beams of smoke. The disco reads only from the pale glowing faceted objects
> themselves.*

It worked first time on all ten, which is worth knowing because it did not need
to: the room box came back with a mirror ball, a lit floor and a DJ deck in a
**cream** room under a **grey** studio backdrop, which is the direction intact
with a disco in it rather than a compromise between the two.

**And that is the same decision the built room makes.** The floor tiles, the lamp
lenses, the beams and the booth's front panel are `Palette.lightMaterial` —
emissive, above white in the HDR buffer — while the plaster and the props keep
the lighting every other room has. The style survives because the disco is made
of *added light* rather than of *removed light*, which is the halo's lesson
(`ROOMS.md` §3) applied to a whole room. `GAMEPLAY.md` §6.5 has the argument.

## The sixth phrase: *a faceted sphere, never a smooth one*

The three bear plates carry one more clause, and without it they are unbuildable.

"Chubby, round, cute, teddy-bear proportions" and "no smooth curved surfaces, no
rounded bevels, no subdivision" are, read literally, a contradiction — and flux
resolves a contradiction by picking a side at random. Half the time you get a
crisply faceted robot; the other half you get exactly the soft clay the whole
direction was chosen to avoid.

The clause that resolves it names the *thing* rather than restating both rules:

> *Adorable and soft-looking in silhouette, but the whole shape is built from
> flat untextured polygon facets with visible straight polygon edges — a faceted
> low-poly sphere, never a smooth one.*

**Round is the silhouette; flat is the surface.** That is also exactly what
`GuestCharacter` builds: an icosphere at one subdivision is 80 flat facets, and a
lathe with six stations is a barrel with six visible bands. The same sentence
describes the plate and the mesh, which is the sign it is the right sentence.

## What each plate settled

- **`roombox.png`** — the composition, and it overruled two guesses. The mirror
  ball hangs on a **plain straight cord that leaves the top of the frame**, which
  is right and is what the built room does: the room box has no ceiling
  (`REFERENCES.md` §1), and inventing a truss to hang the ball from would put a
  surface between the camera and the room. And the **floor tiles are the room's
  colour**, not a black-and-white chequer — a lit floor in pastels, with three or
  four tiles brighter than the rest at any moment. That is the whole disco, in
  one prop, for sixteen boxes.
- **`dj-booth.png`** — a low console, two flat round platters, a small mixer
  between them, and **one glowing panel across the front**. The panel is what
  makes it a booth rather than a sideboard, and it is the cheapest emissive
  surface in the room. Its knobs came back charcoal, which is off-palette; the
  built version uses `woodBrown`. The plate now wins on the cabinet colour too:
  `berryBlue` with `berryBlueDeep` feet, under the pink lip.

  **Image-to-3D was tried and rejected on 2026-08-18.** Higgsfield/Meshy job
  `e0df1452-5afc-47b3-9f29-5bf930f07597` cost 20 credits and returned one
  untextured 2,640-triangle shell. It caught the broad silhouette, but fused the
  rail, platters, mixer and cabinet into spiky triangulated bridges. Decimation
  cannot separate forms that were generated as one surface. The clean rebuild
  is 380 polygons across named parts, keeps the two platter pivots, and adds the
  plate's dark rail stops, eight knobs, four channel faders and corner buttons.
- **`roombox.png`, again, and it is the plate that overruled two of the others.**
  Owner's call on seeing it, 2026-08-17: *"I especially like this one."* Two
  things in it are load-bearing and neither is in any studio plate. **The lit
  floor runs nearly wall to wall** — the room was built with a 137 mm 4×4 rug in
  the middle of a 460 mm floor, which reads as a rug, and it is now 6×6 at
  369 mm with a border. And **the mirror ball is nearer a quarter of the room's
  width than a tenth**; it went from 44 mm to 60 mm across, because it is the
  object that says *disco* before anything has moved.
  This is the third time in the project a room box has overruled a studio plate
  (`references/garden/README.md` has the other three). The rule that keeps
  falling out: **a prop plate knows what a thing is made of; only the room knows
  how big it is and how much of the frame it should take.**
- **`discobal.png`** — small square facets, each a slightly different pale tone.
  Asking for "no mirrored chrome, no metal reflections" is what keeps it in the
  palette; the finale plate, which did not carry that clause, came back with a
  proper silver mirror ball and it is the one thing in that picture that is off
  the direction.
  **And it was read too quickly the first time.** The room built the ball as one
  icosphere in a single glowing cream, which is a *faceted sphere* — but the plate
  is not showing facets, it is showing **tiles**: a twelve-by-seven grid of small
  quads with a seam between them, each its own tone. Those are different objects
  and only one of them needs a mesh per tile. Owner's call on seeing the built
  one, 2026-08-17: *"that mirror ball looks like shit."* It was rebuilt as the
  mosaic the plate had drawn all along.
  The lesson is about reading a plate rather than about this ball: **count the
  things.** "Faceted sphere" and "sphere covered in facets" are the same phrase
  and not the same prop, and the difference is visible in the picture.
- **`dansvloer.png`** — thick tiles, narrow gaps, a few glowing brighter, and
  that is *all* it settled. It was asked for a 4×4 grid and delivered **four
  slabs**, which is the same behaviour as `gasten.png` losing an animal: flux is
  unreliable about counts and reliable about materials. **The room box overruled
  it**, and the built floor is 6×6 running nearly wall to wall — see below.
- **`knoppen.png`** — six round pads, domed glowing tops, one colour each. **A
  row of six survived**, where `buttons/README.md`'s row lost every glyph — the
  difference is that these carry no symbol. The rule is narrower than it looked:
  *flux cannot assemble a compound glyph*, not *flux cannot draw a row*.
- **`boxen.png`** — two tall monochrome cabinets, each with fully chamfered
  edges, a small tweeter and a woofer that is a recessed funnel rather than a
  disc. The rebuilt asset contains the complete lilac-over-peach stack, not one
  cabinet loaded twice. At 42 × 56 × 30 mm per cabinet the stack stands 114 mm,
  just above a guest as the plate does.
  The cone throat sits **0.54 × its radius** behind a real 14-sided boolean hole
  in the baffle. Before that cut, the intact cabinet face covered every deeper
  cone. The cap is now a separate 80-face sphere; cabinets and caps cast but do
  not receive AO, while cone walls use a 30 mm, 0.35-strength four-rung ramp.
- **`gasten.png`** — settled that a friend is *one body with a swapped head*, and
  was then **overruled on the body itself**. Five faceted animals in five
  distinct pastels, each told apart by ears and muzzle alone, which is
  `CONCEPT.md` §9.7's three-part rig with a head swap, drawn. What it got wrong
  was the proportions: box torso, box head, prism limbs with separated fingers —
  a robot. Owner's call on seeing it in the room, 2026-08-17: *"in the reference
  plates they are cute little bears. looks so much better."* Superseded by
  `beertjes.png`; kept, because the head-swap idea is still the reason eleven
  friends cost one builder.

- **`beertjes.png`** — **the plate the guests are actually built from.** A
  teddy-bear body: a plump barrel widest low down, a big round head nearly as
  wide as it sitting straight on the shoulders with no neck at all, a pale belly
  patch covering most of the front, and arms and legs so short they read as
  stubs. The head is about **two fifths of the whole height**, which is most of
  what makes it cute and is the one number in `GuestCharacter` worth protecting.
  Five animals again out of the six asked for — no mouse — which is the third
  time in this folder, so the rule below has now paid for itself three times.

  It is also the answer to *round versus faceted*: the silhouette is soft and
  every surface on it is flat. The prompt has to say so explicitly — *"a faceted
  low-poly sphere, never a smooth one"* — or "chubby and round" and "no smooth
  curved surfaces" fight each other and one of them wins at random.

  **The 2026-08-18 Blender rebuild reads this plate literally.** Head width is
  now 52 mm against the 56 mm barrel; the cream front is a bounded oval rather
  than most of the visible torso; paws have inset pads; feet project forward;
  the frog and bird no longer inherit the furry belly or skull; and the cat,
  dog and bird carry the stripes, blaze and two-part bill that identify them in
  this lineup. The 62 mm room footprint and the existing animation pivots did
  not move.

- **`beertjes-dansen.png`** — asked for six bears each in a different dance pose
  with their arms in the air, and **it is the weakest plate in the set.** The
  poses came back broadly the same (arms out, not up), it lost an animal, and it
  put a fairy in a mint apron in the middle of the row — Nina, who was not asked
  for and who is a character plate away in the same reference. Useful for one
  thing only, and that thing was worth a credit: it confirms **what a raised arm
  needs to look like** — a stubby limb with an open paw on the end, angled out
  from the shoulder rather than straight up beside the head.

  The generalisable half: **flux will give you a pose, and it will not give you
  six different poses.** The six dance styles in `GuestCharacter.DanceStyle` were
  written from the note rather than from the plate.

- **`beertje-solo.png`** — one bear, large, arms up, for reading the construction
  off. The reference every measurement in `GuestCharacter`'s proportions block
  came from.

- **`dj.png`** — the headset, not a twelfth body. The room's DJ is still one of
  the eleven friends; `models/dj-headphones.py` contributes the bent arch, deep
  cups, dark cushions and pale outer panels around that friend's head pivot.

## Two findings that generalise

- **Asking for six characters got five.** Mouse, bear, cat, frog and dog came
  back; the bird did not. `REFERENCES.md` §3 already says never to ask for twelve
  — plate 8 was asked for twelve and delivered eight — and this is the same
  behaviour at a smaller number, so the rule is not a threshold at twelve. **Ask
  for what you need plus one, and expect to lose one.** The missing bird cost
  nothing here because the plate is a brief for a builder rather than a cast
  sheet.
- **A scene with characters in it drifts back towards clay.** The room box, the
  props and the pads came back properly faceted against the scenes reference. The
  finale — same reference, same four phrases, but a room *full of animals* — came
  back with soft rounded characters in a crisply faceted room. It is the same
  pull `REFERENCES.md` §3 records for passing both references at once, and it
  shows up from the subject alone. **Judge a crowd plate for staging and get the
  characters from a character plate**, which is what `gasten.png` is for.
