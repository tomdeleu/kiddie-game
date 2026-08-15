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

**Status: design only.** No application code exists yet.

## → Start here: [`POC.md`](POC.md)

**The first task is a proof of concept, not game content.** It answers the two
questions the briefing cannot: does the faceted low-poly look survive on the
iPad, and can Nina drive the controls.

**Stage A** is Blender → USDZ → Quick Look on the iPad. Well under an hour, no
app code, **and no bake step**. **Stage B** is a minimal RealityKit app — one
room, two draggables, one bowl — and only after Stage A passes.

`POC.md` has the geometry and material specs, the depth-without-AO options, the
sampled palette with hex values, and the pass/fail criteria. Rationale is in
`CONCEPT.md` §8.

Stage A is being done locally where a **Blender MCP connector** is available, so
a session there can drive Blender directly.

## Where things are

| Path | What |
|---|---|
| [`POC.md`](POC.md) | **The current task.** Step 0 proof of concept, with the Blender brief and palette. |
| [`GAMEPLAY.md`](GAMEPLAY.md) | **Storyline and gameplay in detail.** The wall, the twelve friends and their wishes, the cake rules, what each room requires versus what is optional, the timing budget. |
| [`app/`](app/) | **The Stage B POC app.** RealityKit, procedural faceted room, lighting debug panel. Written but never compiled — see its README. |
| [`app/LIGHTMAPS.md`](app/LIGHTMAPS.md) | How to bake AO in Reality Composer Pro 3, and how to A/B it against no-AO. |
| [`CONCEPT.md`](CONCEPT.md) | The design. Loop, age rules, audio, rendering, build order. |
| [`references/REFERENCES.md`](references/REFERENCES.md) | Art direction spec and reference plate recipes. |
| [`references/plates/`](references/plates/) | **The locked style references.** Plates 01 and 02 are the look. |
| [`references/props/`](references/props/) | Prop concept plates, and why `generate_3d` is not usable for this style. |
| [`references/moodboard/`](references/moodboard/) | Provenance + licences. Gathered for two retired directions — not the current look. |
| [`references/FETCHING-ASSETS.md`](references/FETCHING-ASSETS.md) | How to get outside material onto disk here, and what fails. |
| [`audio/voices.json`](audio/voices.json) | Voice casting. Read before generating any line. |

## Asset generation: Higgsfield

**All generated assets come from the Higgsfield connector.** Voice-over,
concept art, and image-to-3D for static props.

| Asset | Model | Notes |
|---|---|---|
| Speech | `text2speech_v2`, variant `elevenlabs` | ~0.15 credits/line. Regenerating is cheap — never settle. |
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
- **Voice is generated, not recorded.** The fairy is **Gracie**
  (`09878754-f20b-5330-9790-58a8027ab5b2`).
- **Characters use a three-part rig**: one solid body (head, torso, arms) plus
  two legs pivoting at the hip. Squash-and-stretch on the root does most of the
  animation. Arms never articulate — realism is not the style. `CONCEPT.md` §9.7.
- **Dutch only.**
- **Nina is the baker and has no avatar.** She is the hands. The fairy is a
  separate character who lives in the bakery and helps.
- **The spine is the wall of twelve frames**, which doubles as a textless level
  select. Not chapters, not endless orders. `GAMEPLAY.md` §2.
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

- **No text anywhere.** She cannot read. Spoken voice plus an icon.
- **Tap and drag only.** No pinch, swipe-precision, double-tap, or long-press.
- **She cannot lose.** No timers, no game over, no buzzer.
- **Huge targets, generous snapping.**
- **Every tap does something.** Dead zones read as broken.

## Environment gotchas

- **Network is allowlisted.** Most content hosts return 403 at the egress proxy.
  Diagnose with `curl -sS "$HTTPS_PROXY/__agentproxy/status"`.
- **Firecrawl cannot download binaries** — it retrieves web content, PDFs, and
  documents, and can *find* image URLs, but refuses images and archives. The
  screenshot workaround is in `references/FETCHING-ASSETS.md`.
- **Commit and push to the branch this session was given**, whatever it is —
  the container is ephemeral, so unpushed work is lost.
