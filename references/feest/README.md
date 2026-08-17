# Het Feest — the disco

Concept plates for `GAMEPLAY.md` §6.5, generated 2026-08-17 for the room the
owner asked for: **a discotheque, with lights and a DJ, and of course cakes and
friends.**

Thirteen plates, `flux_2` / `pro`, 1k, one credit each. Twelve of them are this
room; the thirteenth is
[`../plates/11-finale.png`](../plates/11-finale.png), regenerated because the
finale is the party and the party is now a disco.

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
| **The guests** | `gasten.png` | 16:9 | `196279` | `17ef0f76-f670-4ffd-9a17-bd5608f7b960` | **characters** |
| The finale | `../plates/11-finale.png` | 1:1 | `9333` | `f6429693-912d-4988-829f-970ceed3cd34` | scenes |

Full prompts are on the job records. All thirteen carry `CLAUDE.md`'s four style
phrases, and the ten disco ones carry a fifth clause — see below.

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
  built version uses `woodBrown`.
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
- **`dansvloer.png`** — thick tiles, narrow gaps, a few glowing brighter, and
  that is *all* it settled. It was asked for a 4×4 grid and delivered **four
  slabs**, which is the same behaviour as `gasten.png` losing an animal: flux is
  unreliable about counts and reliable about materials. **The room box overruled
  it**, and the built floor is 6×6 running nearly wall to wall — see below.
- **`knoppen.png`** — six round pads, domed glowing tops, one colour each. **A
  row of six survived**, where `buttons/README.md`'s row lost every glyph — the
  difference is that these carry no symbol. The rule is narrower than it looked:
  *flux cannot assemble a compound glyph*, not *flux cannot draw a row*.
- **`gasten.png`** — the best plate in the set, and it settled the friends. Five
  faceted animals in five distinct pastels, each told apart by **ears and muzzle
  alone** on one shared blocky body. That is `CONCEPT.md` §9.7's three-part rig
  with a head swap, drawn: `FeestProps.guest` builds one body and changes the
  ears, the muzzle and the colour, and eleven friends cost one builder.

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
