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

**Status: five rooms built.** The proof of concept is answered and
[`app/`](app/) holds **De Bakkerij** — the hub and the wall of twelve frames —
**De Tuin**, the garden: eight seed jars on a potting bench, five holes, a
watering can that grows whatever it sweeps over, six more toys, and a picket
fence with a gate in it where its walls used to be — **De Keuken** — the full
kitchen round, seven toys, Nina herself behind the table — **Versieren**, the
decorating room: a cake on a turntable, seven sticker trays, a piping bag, a
sprinkle shaker and five more toys — and **Het Feest**, the party, which is
**a disco**: a mirror ball, a light rig, a light-up dance floor, a DJ at a booth
with two decks, six teddy-bear friends each dancing a different little move, and
six pads whose beat is the one she is tapping. Dutch line variants now include
the bakery's 53 as well as the earlier rooms'. The round is the five of them.

## → Start here: [`app/README.md`](app/README.md)

All five rooms are playable end to end. De Bakkerij: pull the blind up, pick a
grey frame, let the friend in, hang their wish. The garden: sow five seeds, sweep
the can across the bed three times, tap the ripe plants into the basket. The
kitchen: roll the base, fetch five ingredients from five places, stir, pour,
into Otto, tap, cake, carry it up onto the plank. Versieren: turn the cake,
pipe, shake, press stickers on, light the candle. Het Feest: tap the pads,
everyone dances to you, and tap the cake when you are ready to eat it. Then hang
the photograph on the wall.

**The five of them are one round.** The bakery's friend is who the round is for.
The garden's basket is what the kitchen bakes, the kitchen's cake is what
Versieren decorates, Versieren's decorated cake is what stands on the party
table and gets eaten, and the party's result is the photograph the bakery hangs.
Every handover goes through `RoomExit`, which is a room saying *what just
happened* and handing back control. No room knows what comes after it.

**The app opens on the wall.** Title plate, then the film on first launch only,
then De Bakkerij. A round already in progress resumes into the room she left.

**Switch rooms by tapping the small grey wrench in the top-right corner** and
using the picker at the top of the developer strip — any room, in either mode,
with any cake, in one tap. The strip itself stays off screen until asked for — a
visible teleport button is the most pressable thing that could be on that
screen — but the way *in* is now visible, because the triple tap it replaced sat
under the opening film and could not be tapped at all. The triple tap still
works for anyone with the muscle memory.

**The first three rooms compiled clean on 2026-08-16** — Xcode 26.6, iOS Simulator,
Debug, three times: once when the kitchen and the decorating room landed, again
after De Tuin, the fence, the gate, the potting bench and the reconciliation that
merged the two branches, and a third time after the garden's ten Blender props.
All three builds' findings are in `app/README.md`, and they are worth the two
minutes: **between them they caught eight errors and none of them was among the
five the project had been predicting.**

The third build found none, because it was the first change written on a machine
that had a compiler on it. It found **five geometry mistakes in a renderer
instead**, which is the more useful half of that story: ten props built
correct-by-construction all compiled and five of them were visibly wrong. If the
next session is back in a container with no toolchain, assume both halves.

**The owner builds in Xcode, regularly**, so "this code is unbuilt" is never the
right thing for a container session to write down — it is not true for long, and
it was written into `app/README.md` once and had to be taken back out. The real
gap is narrower: **an agent's last look at its own work is never a compiler's**.
Write as if correct-by-construction, and hand over saying plainly which edits are
the risky kind — a file move and a new call into main-actor code are the two the
record actually indicts. `app/README.md` keeps that list.

**De Bakkerij was handed over to that same rule.** The room came from a
container, so: `ContentView.handle` now routes five `RoomExit` cases;
`GardenRoom` and `VersierRoom` gained a `friend:` argument now used from
`GameScene.makeRoom`; `FeestRoom.tapCake` calls `onExit` with a `FeestResult`
instead of starting a fresh party; `KitchenRoom.roomComplete` now reads `mode`.
`BakerCharacter`'s `home:` argument is used from a fifth room. Everything under
`Sources/Bakkerij/` is new files that the synchronized Sources group picks up.

**And one edit reaches every room, which is worth its own line**:
`Engine/Ticker.swift` runs on a `CADisplayLink` rather than a `Timer` as of
2026-08-17, because a timer drifts against vsync and the party is the first room
busy enough to show it as a regular hitch. Nothing about any room changes except
that animation is paced to the display — but it is the game's one clock, so if
*anything* anywhere stops moving, look there first. `ROOMS.md` §7 has the
argument.

Deliberate deviations from the design are recorded there. The kitchen's: the
palette gained a blue, an amber and a lilac the locked thirteen do not contain;
the room box is 0.46 m with the camera pulled back 8%, rather than the 0.4 m and
the framing `POC.md` signed off; and **the modelled props carry facet-baked
ambient occlusion** — short contact shading in the first three rooms, plus the
disco's measured long-reach ramp — see below. A full room-scale kitchen rerun
on 2026-08-18 kept those short bakes: extending the ramp to its nine eligible
models improved the per-pixel-reference error by only 7–8%, because the missing
term lives mainly on the procedural shell, furniture, Nina and Otto. After the
owner reported on 2026-08-19 that the AO did not visibly act in the simulator,
the measured second route shipped: three 512² shell maps on kitchen-only UV
planes, plus the intended 0.22 contact-shadow opacity. The round is ended by
carrying
the finished cake up onto the plank, and its doorway now genuinely leads to the
decorating room rather than promising one. The garden's: **eight seeds rather
than `GAMEPLAY.md` §5's six**, because the kitchen deals eight; a full basket
completes it in both modes; **it has a fence instead of the two walls
`references/REFERENCES.md` §1 locks**, standing exactly where the plaster stood;
and its gate says `ROOMS.md` §9's three things twice, because a picket fence has
nothing behind it to light. The party's: **it has no door at all** — the cake is
the way out, because §6.5 says nothing else ends the party and two endings in one
room is a contradiction; **six guests plus a DJ rather than the twelve
`GAMEPLAY.md` §6.5 used to ask for**, and the reason is the screen-separation
arithmetic in `ROOMS.md` §5 rather than the rig; a visit still **deals** a
friend when none is handed over; and
the guests' thanks are **relayed by Nina** until the eleven friends have voices.
The bakery hands the friend of the day through `RoomExit.tuin(Friend)` rather
than dealing one at the party.

**One room is designed but not built, decided by the owner on 2026-08-17.**
[`GAMEPLAY.md`](GAMEPLAY.md) §6.4 gives **Versieren** a required spine —
`insmeren`, `rondom`, `kaarsje`, `klaar` — which **reverses that section's own
"required: nothing"** and is the largest remaining gap between the design and
`app/`. The reversal keeps the promise underneath the heading: the steps
*observe rather than gate*, the door stays lit from the first frame, and
nothing is ever disabled. Prop plates are in
[`references/versieren/`](references/versieren/). De Bakkerij's §6.1 is built.

**Het Feest is built, so §6.5 is no longer open** — the party landed on
2026-08-17 and `app/` has five rooms including the hub. Note what that does to
§6.4's new spine: the decorating room's door now *hands its cake to the party*,
so the room that is about to grow a required action is also the room with a live
handover on the other side of it. Read `VersierRoom.endRoom` before adding steps
in front of it.

**Next**, per [`GAMEPLAY.md`](GAMEPLAY.md) §9 and §10: **test all five rooms with
Nina first** — `POC.md` has the protocol, and what it says about the snap radius
and target sizes is the thing worth knowing before another pass on the same
numbers. Every room after the kitchen inherited its touch radii on the argument
that the box and the chair have not moved, which is a calculation rather than an
observation and now rides on five rooms instead of one. The music search is still
open but it is **one asset rather than seven**: the party's six pads turned out
to be six more synthesised `SoundKit` voices, so only the party *loop* is
blocked. Versieren's §6.4 spine is the remaining design-to-code gap.

**Before writing a room, read [`ROOMS.md`](ROOMS.md).** It is the contract the
kitchen established and the garden was the first to be built against — the box
and the camera, the step machine, the halo, the voice rules, targets, carrying,
idle, misses, the door — written down once so the next room does not have to be
reverse-engineered out of `KitchenRoom.swift`.

[`POC.md`](POC.md) stays as the record of why the look is what it is, and its
palette and pass criteria are still the standard every new room is held to.

## Where things are

| Path | What |
|---|---|
| [`app/`](app/) | **The app.** De Bakkerij, De Tuin, De Keuken, Versieren and Het Feest: the rounds, the wall, the toys, Nina, Otto, the friends, the cake and everything she puts on it, the room switcher, the lighting panel. The first three rooms compiled at the 2026-08-16 builds — see its README for what those caught, and for which later edits are the risky kind. |
| [`models/`](models/) | **Props modelled in Blender**, as Python that rebuilds them. Twenty-two so far — De Keuken's ten (the flour sack, the toverbosbes, the crate, the toverklaver, the toverveertje, the maanstof pouch, the sink, the spoon, the cake and the scale) and De Tuin's twelve (the molehill, the seed bed, the fence, seven of the eight ripe plants, the tree and the harvest basket). Its README has the rules, the export settings, and the test a prop has to pass to belong there. |
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
| [`references/garden/`](references/garden/) | **De Tuin's twenty-five plates** — the bed, the can, the basket, four plant stages, eight ripe plants, six toys, and the fence, gate and potting bench that replaced its walls. Its README has the job IDs and the three studio plates the room box overruled. |
| [`references/bakkerij/`](references/bakkerij/) | **De Bakkerij's plates** — the room box, the wall of twelve frames, the blind, the shop door and the order hook, plus the frames' two states, the toys and the sign. They replace plates 06 and 10, which were drawn in the retired clay style. Its README has the empty-room-box failure and what fixed it. |
| [`references/feest/`](references/feest/) | **Het Feest's fifteen plates** — the disco room box, the DJ booth, the mirror ball, the light bar, the dance floor, the six pads, the speakers, the cake table, two toys, the DJ, and two passes at the guests. Its README has the seeds, the fifth prompt phrase that keeps a disco from going dark, the sixth that lets a shape be round and faceted at once, and why asking for six animals gets five three times running. |
| [`references/ingredients/`](references/ingredients/) | The eight ingredients, the flour sack and the flour cloud — the plates the models were built from. |
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
- **Het Feest is a discotheque.** Owner's call, 2026-08-17: *"the room must
  resemble a discoteque with lights and a DJ. And of course cakes and friends."*
  A mirror ball, a light rig, a light-up dance floor, a speaker stack and a DJ
  behind a booth with two decks. Nothing about what the room *does* changed — the
  guests still dance to the beat she taps and she still ends it by tapping the
  cake — which is the tell that the birthday-party theme was a skin over the
  mechanic rather than the mechanic. `GAMEPLAY.md` §6.5.
  **And the disco is made of light, not of darkness**: emissive tiles, lenses,
  beams and facets, on a room lit exactly like every other one. Dimming a room to
  sell a disco would have thrown the direction away for one room.
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
 **The modelled props break the AO rule, on the owner's calls of 2026-08-16 and
 2026-08-18**:
  a crown standing off a globe, a collar fanning over a tie, a board butting
  into a post, four petals crowding a hub, a spout leaving its post and icing
 hanging over a tier are all joins no facet can shade. The kitchen and garden
 bakes reach 2.2–6 mm. Het Feest's measured exception reaches **30 mm over ten
 Shade levels** on the friends and modelled disco props; the shared cake
 uses it in every room. It is still baked to facets, not a texture.
 `app/AMBIENT-OCCLUSION.md` has the measurements and `models/README.md` has the
 implementation; the rule holds everywhere else, including everything
 `FacetedMesh` builds.
 **There are two texture exceptions.** Het Feest's dance-floor top uses one
 because the room-box plate requires a genuinely smooth rectangular light
 falloff; three
 `ShadeN` bands were visibly bands. `FeestProps` generates one 128² greyscale
 texture in memory and reuses it on all 36 UV planes. The bundled modelled tile
 remains its no-texture failure fallback. De Keuken's inward shell faces use
 three 512² AO maps, calibrated at 0.55 strength and mapped onto kitchen-only UV
 planes; the textureless shared shell remains underneath as the failure
 fallback. Both exceptions were measured against renders and checked in the
 simulator rather than introduced as general material vocabulary.
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

## Always ask which room

**Before changing anything, ask which room it is for — if not already
provided.** Every request to change
behaviour, geometry, voice, timing or look applies to **one named room** unless
the user has explicitly said otherwise. Never apply a change across several
rooms — or to shared code that several rooms use — without asking for
confirmation first and getting it. If the room is not already provided, ask; do
not infer it from what is open, from what was changed last, or from what seems
consistent.

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
