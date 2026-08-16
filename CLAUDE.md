# CLAUDE.md

Entry point for this repo. Read this first, then
[`CONCEPT.md`](CONCEPT.md) for the full design.

## What this is

**Nina's Toverbakkerij** — a magic-bakery game in **Dutch** for **Nina, aged 4**,
on **iPad**. Native **SwiftUI + RealityKit**, in a **faceted pastel low-poly**
3D look.

The loop: a friend turns up with a wish → grow magic ingredients in the garden →
bake a cake whose colour comes from what she chose → decorate it freely → throw
a dance party where everyone eats it and thanks her by name → hang the photo in
a frame on the bakery wall.

**The wall of twelve frames is the game.** Fill them all and the bakery becomes
a real toverbakkerij. That is the only progression — no scores, no stars, no
timers, nothing counted anywhere. A round is ~11–12 minutes.

**Status: two rooms built.** The proof of concept is answered and
[`app/`](app/) holds **De Keuken** — the full kitchen round, seven toys, Nina
herself behind the table — and **Versieren**, the decorating room: a cake on a
turntable, seven sticker trays, a piping bag, a sprinkle shaker and five more
toys. 196 Dutch voice lines between them. The kitchen's door now leads to the
decorating room rather than promising one, and a **debug room switcher** behind
the triple-tap developer corner reaches either room in one tap, in either mode,
with any cake.

## → Start here: [`app/README.md`](app/README.md)

The kitchen is playable end to end: roll the base, fetch five ingredients from
five places, stir, pour, into Otto, tap, cake, carry it up onto the plank,
fresh round. It has never been compiled — it was written in a container with no
Swift toolchain — and its README names the two places most likely to want a fix
on first build.

Deliberate deviations from the design are recorded there. The doorway now does
lead to the decorating room; the palette gained a
blue and an amber the locked thirteen do not contain; the room box is now
0.46 m with the camera pulled back 8%, rather than the 0.4 m and the framing
`POC.md` signed off; and **the ten Blender props carry ambient occlusion**,
which nothing else does — see below. The round is ended by carrying the finished cake
up onto the plank.

**Next**, per [`GAMEPLAY.md`](GAMEPLAY.md) §9: the party, then the wall of
twelve frames — and start the music search before the party, since it is the one
genuinely blocked dependency in the project. And **test the two rooms with Nina
first** — `POC.md`
has the protocol, and what it says about the snap radius and target sizes is
the thing worth knowing before another room is built on the same numbers.

**Before writing a room, read [`ROOMS.md`](ROOMS.md).** It is the contract the
kitchen established — the box and the camera, the step machine, the halo, the
voice rules, targets, carrying, idle, misses, the door — written down once so
the next room does not have to be reverse-engineered out of `KitchenRoom.swift`.

[`POC.md`](POC.md) stays as the record of why the look is what it is, and its
palette and pass criteria are still the standard every new room is held to.

## Where things are

| Path | What |
|---|---|
| [`app/`](app/) | **The app.** De Keuken and Versieren: the round, the toys, Nina, Otto, the cake and everything she puts on it, the room switcher, the lighting panel. Written but never compiled — see its README. |
| [`models/`](models/) | **Props modelled in Blender**, as Python that rebuilds them. Ten so far — the flour sack, the toverbosbes, the crate, the toverklaver, the toverveertje, the maanstof pouch, the sink, the spoon, the cake and the scale, the only props not built in code. Its README has the rules, the export settings, and the test a prop has to pass to belong there. |
| [`GAMEPLAY.md`](GAMEPLAY.md) | **Storyline and gameplay in detail.** The wall, the eleven friends and their wishes, the cake rules, what each room requires versus what is optional, the timing budget. Reconciled with the built kitchen on 2026-08-16. |
| [`ROOMS.md`](ROOMS.md) | **How to build a room.** The contract De Keuken established: the box, the camera, the step machine, the halo, the voice rules, touch, carrying, idle, misses, the door — and the traps that have already been paid for once. Read before writing a room. |
| [`POC.md`](POC.md) | Step 0 proof of concept — answered. Kept for the palette, the geometry specs and the pass criteria. |
| [`audio/`](audio/) | The voice script, the casting, the auditions, and the re-fetch script. |
| [`app/LIGHTMAPS.md`](app/LIGHTMAPS.md) | How to bake AO in Reality Composer Pro 3, and how to A/B it against no-AO. |
| [`CONCEPT.md`](CONCEPT.md) | The design. Loop, age rules, audio, rendering, build order. |
| [`references/REFERENCES.md`](references/REFERENCES.md) | Art direction spec and reference plate recipes. |
| [`references/plates/`](references/plates/) | **The locked style references.** Plates 01 and 02 are the look. |
| [`references/buttons/`](references/buttons/) | **The button.** Every UI control is one faceted octagon — the plate it came from, the nine candidates, and the measurements the SwiftUI implementation is built on. |
| [`references/loading-screen/`](references/loading-screen/) | The title plate that opens the app, its eighteen candidates, and the script that pads it to 16:9. |
| [`references/props/`](references/props/) | Prop concept plates for the kitchen, and why `generate_3d` is not usable for this style. |
| [`references/versieren/`](references/versieren/) | The decorating room's seventeen plates — the turntable, the two tools, the seven sticker shapes and the toys — and what three attempts at its room box taught about making flux name its own facet counts. |
| [`references/ingredients/`](references/ingredients/) | The six ingredients, the flour sack and the flour cloud — the plates the models were built from. |
| [`references/moodboard/`](references/moodboard/) | Provenance + licences. Gathered for two retired directions — not the current look. |
| [`references/FETCHING-ASSETS.md`](references/FETCHING-ASSETS.md) | How to get outside material onto disk here, and what fails. |
| [`audio/voices.json`](audio/voices.json) | Voice casting. Read before generating any line. |

## Asset generation: Higgsfield

**All generated assets come from the Higgsfield connector.** Voice-over,
concept art, and image-to-3D for static props.

| Asset | Model | Notes |
|---|---|---|
| Speech | `text2speech_v2`, variant `elevenlabs` | **0.3 credits/line** — measured, not the 0.15 the older notes assume. The kitchen's 86 lines cost ~26. Regenerating is still cheap; never settle. |
| Images | `flux_2`, variant `pro` | 1 credit each. **Record the seed.** Always pass the locked style reference — see below. |
| Static props → 3D | `generate_3d` | **20 credits, and not usable for this style.** Tested on the oven: 26,780 faces at a 5° median crease against 56 faces procedurally, and decimation floors at 2,053 with irregular creases. It keeps the silhouette and destroys the facets. Evidence in `references/props/README.md`. Possibly still worth it for an organic character body. |

The phrases that carry the look: **"flat-shaded low-poly"**, **"visible straight
polygon edges"**, **"no smooth curved surfaces"**, **"no ambient occlusion
pooling"**. Drop the facet phrases and flux_2 reverts to smooth clay; drop the
last one and it pools shadow into the corners. Put the style *before* the
subject in the prompt, and keep the prop list short.

Rules that keep this from going wrong:

- **Preflight cost** with `get_cost: true` before any batch. These are the
  user's credits.
- **Reuse recorded IDs.** A character's `voice_id` and an approved plate's job
  ID are how consistency survives across sessions. Never re-pick casually.
- **Batch** with `generate_*_batch` + `jobs_wait` + one `show_generation_by_ids`.
- **Generated images are concept references, not shippable assets.** Going 3D
  means they guide modelling; nothing generated goes into the app directly.
  Three exceptions, all because the asset has no second form to be modelled
  into: the opening film (`references/REFERENCES.md` §3), the app icon
  (`references/app-icon/`) and the loading screen
  (`references/loading-screen/`).

**Higgsfield cannot supply music or sound effects.** Its music and SFX models
are restricted to its internal game pipeline and refuse standalone use. Those
come from CC0 libraries or GarageBand — see `CONCEPT.md` §7.4.

## Decisions already made — do not relitigate

These were argued through and settled. Reopen only if the user asks.

- **3D, not 2D.** The chunky stylisation makes it tractable: characters are
  faceted primitives with rigid joints, so there is no sculpting, skinning, or
  texture authoring.
- **RealityKit, not Unity or Godot.** The engines' strengths — physics, level
  design, animation state machines, cross-platform — do not apply to a
  fixed-camera game with ten props per room. `CONCEPT.md` §9.3 has the
  comparison and the triggers for revisiting.
- **Voice is generated, not recorded.** Nina is **Gracie**
  (`09878754-f20b-5330-9790-58a8027ab5b2`). Otto the oven is provisionally
  **Barrett** (`d603a8cd-3fe1-55e0-9245-617a2589131e`) — picked without an ear
  on it, with five auditions in [`audio/auditions/`](audio/auditions/) waiting
  to be listened to. Swapping him costs ~4 credits and no code.
- **Characters use a three-part rig**: one solid body (head, torso, arms) plus
  two legs pivoting at the hip. Squash-and-stretch on the root does most of the
  animation. Arms never articulate — realism is not the style. `CONCEPT.md` §9.7.
- **Dutch only.**
- **Nina is the baker, she is on screen, and she is the one talking.** She is
  the fairy in `references/plates/02-fairy-character.png`, standing behind the
  table and working while the round runs. **This reversed an earlier decision**
  — she used to have no avatar and a separate fairy called Luna did the
  talking — on the owner's call, 2026-08-15. Luna is gone.
- **The spine is the wall of twelve frames**, which doubles as a textless level
  select. Not chapters, not endless orders. `GAMEPLAY.md` §2. **Eleven of them
  are friends and the twelfth, gold one is Nina's own** — owner's call,
  2026-08-16, filling the slot Luna's removal emptied. The last cake is the one
  she makes for her own finished bakery.
- **A room can be played two ways** — as one step inside a round, or as a visit
  on its own with its own completion rule (the kitchen's is three cakes). One
  flag, not two implementations. Owner's call, 2026-08-16. `GAMEPLAY.md` §3.
- **The basket holds five, not three.** Owner's call, 2026-08-16, ratifying what
  the kitchen shipped: the garden grows five, the kitchen fetches five from five
  places. `GAMEPLAY.md` §5.
- **Drag to play, tap to learn the word.** Every prop says what it is when
  tapped, in Dutch, one variant each. It is the only part of the game that
  teaches her language, and every new room brings its own naming lines.
- **Nothing unlocks.** Every seed, sticker and friend is available from the
  first round. Variety comes from her choices and from who is at the door.
- **Every wish can be ignored** with no penalty and no difference in the
  celebration. It answers "what shall I make today?", it is not a test.
- **Use Kenney's CC0 kits.** Not a suggestion — the
  [Food Kit](https://kenney.nl/assets/food-kit) and
  [Furniture Kit](https://kenney.nl/assets/furniture-kit) are the default source
  for props. 340 public-domain models, already mutually consistent. **Do not
  model or generate a prop that a kit already provides.** Model only what they
  genuinely lack (characters, the magic oven).
  Bonus: they arrive **flat-shaded and hard-edged**, which is exactly the target
  shading model. They need a palette swap and nothing else — no softening, no UV
  unwrapping, no AO bake.
- **Art direction: faceted pastel low-poly.** Angular **flat-shaded** geometry
  with **visible facets** — no bevels, no smoothing, no subdivision — in a soft
  pastel palette (blush pink, mint, cream, butter yellow, sage), evenly lit, on a
  plain neutral grey backdrop. **No ambient occlusion anywhere**: shading comes
  from the facet normals, and corners stay light. Every room is an open corner
  room box (two walls + floor) on a slim base slab, at a fixed isometric angle.
  Full spec in `references/REFERENCES.md`.
  **The ten Blender props break the AO rule, on the owner's call, 2026-08-16**:
  a crown standing off a globe, a collar fanning over a tie, a board butting
  into a post, four petals crowding a hub, a spout leaving its post and icing
  hanging over a tier are all joins no facet can shade. It is baked to the
  facets, not to a texture, and reaches 2.2–6 mm. `models/README.md` has the
  argument; the rule holds everywhere else, including everything `FacetedMesh`
  builds.
  **Every image generation must pass the matching locked style reference**
  alongside the prompt — scenes `64f0893e-073a-4065-b363-f87687ced11d`
  (`references/plates/01-cottage-exterior.png`), characters
  `d368acec-4085-48e4-83ff-7a57ee8ee789`
  (`references/plates/02-fairy-character.png`). Pass **one**, matched to the
  subject; passing both bleeds the character into the scene.
  **This supersedes both earlier framings** — the clay direction (soft, rounded,
  occlusion-heavy, terracotta/teal) and the Roblox one before it. Where old text
  describes either, this wins.
- **Check licences before using any reference.** Only CC0 material ships. Two
  moodboard sources carry explicit *no-AI* terms, so they must never be used as
  image-generation references.

## Non-negotiable: she is four

Every screen obeys these. Full table in `CONCEPT.md` §5.

- **No text anywhere.** She cannot read. Spoken voice plus an icon. The one
  exception is the game's own name on the loading screen — a name on a cover is
  not something she is asked to read.
- **Tap and drag only.** No pinch, swipe-precision, double-tap, or long-press.
- **She cannot lose.** No timers, no game over, no buzzer.
- **Huge targets, generous snapping.**
- **Every tap does something.** Dead zones read as broken.

## Environment gotchas

- **Network is allowlisted.** Most content hosts return 403 at the egress proxy.
  Diagnose with `curl -sS "$HTTPS_PROXY/__agentproxy/status"`. The Higgsfield
  results CDN (`d8j0ntlcm91z4.cloudfront.net`) **was** reachable on 2026-08-15,
  which is how the 86 voice files got into the repo — check before assuming it
  is not.
- **Firecrawl cannot download binaries** — it retrieves web content, PDFs, and
  documents, and can *find* image URLs, but refuses images and archives. The
  screenshot workaround is in `references/FETCHING-ASSETS.md`.
- **Commit and push to the branch this session was given**, whatever it is —
  the container is ephemeral, so unpushed work is lost.
