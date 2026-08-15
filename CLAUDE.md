# CLAUDE.md

Entry point for this repo. Read this first, then
[`CONCEPT.md`](CONCEPT.md) for the full design.

## What this is

**Nina's Toverbakkerij** — a magic-bakery game in **Dutch** for **Nina, aged 4**,
on **iPad**. Native **SwiftUI + RealityKit**, in a low-poly **Roblox-style** 3D
look.

The loop: grow magic ingredients in the garden → bake a cake whose colour comes
from what she chose → decorate it freely → throw a dance party where everyone
eats it and thanks her by name.

**Status: design only.** No application code exists yet. First build target is
the kitchen room.

## Where things are

| Path | What |
|---|---|
| [`CONCEPT.md`](CONCEPT.md) | The design. Loop, age rules, audio, rendering, build order. |
| [`references/REFERENCES.md`](references/REFERENCES.md) | Art direction spec and reference plate recipes. |
| [`references/moodboard/`](references/moodboard/) | Style screenshots + provenance. |
| [`references/FETCHING-ASSETS.md`](references/FETCHING-ASSETS.md) | How to get outside material onto disk here, and what fails. |
| [`audio/voices.json`](audio/voices.json) | Voice casting. Read before generating any line. |

## Asset generation: Higgsfield

**All generated assets come from the Higgsfield connector.** Voice-over,
concept art, and image-to-3D for static props.

| Asset | Model | Notes |
|---|---|---|
| Speech | `text2speech_v2`, variant `elevenlabs` | ~0.15 credits/line. Regenerating is cheap — never settle. |
| Images | `flux_2`, variant `pro` | 1 credit each. **Record the seed**; it makes a plate reproducible. |
| Static props → 3D | `generate_3d` | Unrigged GLB. Props only — never characters, which need a joint hierarchy. |

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

- **3D, not 2D.** The Roblox style makes it tractable: characters are primitives
  with rigid joints, so there is no sculpting, skinning, or texture authoring.
- **RealityKit, not Unity or Godot.** The engines' strengths — physics, level
  design, animation state machines, cross-platform — do not apply to a
  fixed-camera game with ten props per room. `CONCEPT.md` §9.3 has the
  comparison and the triggers for revisiting.
- **Voice is generated, not recorded.** The fairy is **Gracie**
  (`09878754-f20b-5330-9790-58a8027ab5b2`).
- **Dutch only.**
- **Kenney's CC0 kits first**, before modelling or generating any prop.
  340 public-domain low-poly models, already mutually consistent.

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
- **Work on branch `claude/kids-game-ipad-idea-o42q3m`.** Commit and push there;
  the container is ephemeral, so unpushed work is lost.
