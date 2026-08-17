# Nina's Toverbakkerij — concept

A magic-bakery game for Nina, aged 4, in Dutch, on iPad. Native SwiftUI with
RealityKit, in a faceted pastel low-poly 3D look.

Working title: **Nina's Toverbakkerij** (Nina's magic bakery). Short, Dutch, and
a 4-year-old can say it — which matters, because she has to be able to ask for
it by name. Putting her name in the title is also the cheapest personalization
in the whole project: it is the first thing she sees on the home screen, every
single time.

---

## 1. The pitch

She is a little fairy baker. She grows magic ingredients in the garden, bakes a
cake with them in the kitchen, decorates it however she likes, and throws a
dance party where everyone eats it and thanks her by name.

That single loop covers all three things she is into right now — baking, magic,
and music — and it ends with a party, which gives the session a natural finish
line.

## 2. Why build this instead of buying Toca Boca

We will not out-polish a studio, and we should not try. The one thing a
store-bought app can never do is **be about her**: her name spoken aloud by the
characters, her own drawings hanging on the bakery wall, a bakery that carries
her name above the door.

That is the entire competitive advantage, so the design leans on it hard rather
than treating it as a garnish.

## 3. The core loop

Four rooms, played in order, roughly 11–12 minutes end to end — longer if she
lingers, which she will.

> **The detailed design lives in [`GAMEPLAY.md`](GAMEPLAY.md):** the twelve
> friends and their wishes, the ingredient-to-cake rules, what is required in
> each room versus what is optional, and the timing budget. This section is the
> summary. Where the two disagree, `GAMEPLAY.md` is newer and wins.

### 3.1 De Tuin — the garden

Plant a glittering seed, drag the watering can over it, and it grows in three
stages into a magic ingredient: a rainbow strawberry, star sugar, cloud cream.
Pick it and it flies into the basket.

- Teaches: cause and effect, a tiny bit of patience.
- She picks **which** ingredients to grow. This choice matters later, which is
  the point.

### 3.2 De Keuken — the kitchen

Drag ingredients from the basket into the mixing bowl. Stir by moving a finger
in circles — the whisk follows her finger, and the batter changes colour based
on what she actually put in.

Rainbow strawberry makes it pink. Star sugar makes it sparkle. Both make it
pink *and* sparkly. **Her cake is genuinely different every time, because of
choices she made.** This is the magic of the game, and it is cheap to build: it
is just a tint and a particle flag.

Pour the batter in the tin, slide it in the oven, close the door, and tap.
Sparkles, a rising "ping", and the cake comes out in her colours.

### 3.3 Versieren — decorating

Free placement of stickers on the cake: sprinkles, candles, little crowns,
hearts, stars. No target, no correct answer, no timer.

This is the part she will spend the most time on. Every open-ended kids' game
finds the same thing. Give it plenty of stickers and let her cover the whole
cake if she wants.

### 3.4 Het Feest — the party

**It is a disco** — owner's call, 2026-08-17. A mirror ball, a rig of coloured
lights, a light-up dance floor, a stack of speakers and **a DJ behind a booth
with two decks**. `GAMEPLAY.md` §6.5 is the detail and
`references/feest/` is the look.

The cake is carried to a table. The friends arrive. The DJ starts.

Six big pads along the bottom, each an instrument. Whatever she taps, the room
dances to — the guests, the ball, the floor and the lights are all on the beat
she is making. Then everyone eats the cake with enormous crunching sounds,
applause, and the friend of the day says:

> "Dankjewel, Nina! Dit was de allerlekkerste taart!"

Then the cake is photographed and hung on the bakery wall in a little frame.

> **The line above used to be the head fairy's.** Luna is gone — Nina is the
> baker and the voice (`GAMEPLAY.md` §1), so the thanks belong to a guest. Until
> the friends have voices of their own, Nina relays it: *"Pip zegt: dankjewel,
> Nina!"*

## 4. The hub and the collection

The home screen is the bakery cottage as a single low-poly miniature, with the
garden beside it. Tap it to go in, tap the big arrow to come home. That is the
whole navigation model and the only thing she has to learn.

Inside, each room is an **open corner room box** — two walls and a floor, seen
from a fixed isometric angle, open on the two near sides. Moving between rooms
slides one box out and the next in, which is a transition she can follow. See
[`references/REFERENCES.md`](references/REFERENCES.md) for why this framing was
chosen.

**The bakery wall holds twelve frames, and filling them all is the game.** Each
frame starts as the grey silhouette of a friend waiting for their party; a
finished cake turns it into a photo. It needs no numbers, no stars, and no
reading — she can see the gaps shrinking and point at the one she made
yesterday.

The wall is also the **level select**: tapping a grey frame starts that friend's
round, tapping a filled one replays that party. No menu, no text, nothing new to
learn. Filling the twelfth frame triggers the finale, after which nothing locks
and the bakery stays open. See [`GAMEPLAY.md`](GAMEPLAY.md) §2.

## 5. Rules for a four-year-old

These are the difference between "she plays it once" and "she asks for it every
day". They are non-negotiable constraints on every screen.

| Rule | Why |
|---|---|
| **Zero text, anywhere** | She cannot read. Instructions are spoken voice plus an icon. |
| **Tap and drag only** | No swipe precision, no pinch, no double-tap, no long-press — her hands cannot do these reliably yet. |
| **Huge targets, generous snapping** | Minimum ~120pt hit areas. Drop the egg *near* the bowl and it goes in the bowl. |
| **You cannot lose** | No timers, no game over, no buzzer. A wrong drag floats gently back with "hmm, probeer die andere eens!" |
| **Every tap does something** | Tap a background flower, it giggles. Dead zones read as "broken" to her. |
| **Rewards are animation and sound** | Points and stars are meaningless to a pre-reader. A cake that dances is not. |
| **A clear ending** | The party finishes and the curtain closes. This is what makes "one more, then we stop" actually work at bedtime. |
| **A parent gate** | Hold three fingers for three seconds to reach settings. She will not find it. |

## 6. Personalization

All voice-over is **generated**, not recorded — see [Audio](#7-audio). That
changes the shape of this list but not its importance.

In rough order of impact per hour of work:

1. **Her name, spoken.** The fairy greets her by name on launch and thanks her
   by name at the party. Roughly 10 lines contain her name.
2. **A distinct voice per character.** The fairy, the oven, and each party guest
   get their own voice. This is something a single person recording themselves
   could never pull off convincingly, so generation is a genuine upgrade here
   rather than a compromise.
3. **Her drawings** photographed and hung in the bakery as decoration.
4. **Family faces**, optionally, on the party guests. Nice, but do it last — it
   is fiddly and the game works fine without it.

## 7. Audio

Voice-over is generated through the Higgsfield connector. Everything below was
checked against the connector's actual model catalogue, not assumed.

### 7.1 Speech — available

Use `text2speech_v2` with the **`elevenlabs`** variant. It is the strongest
multilingual engine on offer and the best bet for natural Dutch. `seed_audio`
(ByteDance) is the connector default and the fallback if ElevenLabs disappoints.

Two caveats worth knowing before committing:

- **The preset voices are not language-tagged.** The catalogue lists them by
  name and gender only, so Dutch quality has to be *auditioned* — generate the
  same line across a handful of voices and listen. Do this before writing any
  dialogue, because it determines who the characters are.
- **Name pronunciation** is the usual risk with a multilingual model, and the
  fix is a phonetic respelling in the prompt rather than the correct spelling.
  "Nina" is a soft case: it is pronounced near-identically in Dutch and English
  (*NEE-nah*), so this is unlikely to bite. Still verify it by ear — it is the
  most important second of audio in the entire game.

There *are* four native Dutch voices in the catalogue (Erik, Katrien, Lennart,
Lore) on the `inworld_text_to_speech` model — but that model is restricted to
Higgsfield's internal game-generation pipeline and cannot be used to generate
standalone assets. Noting it so nobody rediscovers it and wastes an afternoon.

Cost is ~0.15 credits per line, so auditioning and regenerating is effectively
free. There is no reason to settle for a voice that is merely acceptable.

### 7.2 Nina's voice — DECIDED

**Gracie.** Young female preset, `elevenlabs` engine.

```
model      text2speech_v2
variant    elevenlabs
voice_type preset
voice_id   09878754-f20b-5330-9790-58a8027ab5b2
```

Also recorded in [`audio/voices.json`](audio/voices.json), which is the file to
read when generating lines.

Every line Nina speaks — now and in any room added later — uses this ID, so she
does not change voice mid-project. It was cast for a fairy helper called Luna
who no longer exists; the voice was cast *young*, so it survived the change to
Nina unaltered. §11 has the reversal.

**Audition shortlist** it was chosen from, all generated with the line
*"Hallo Nina! Kom je mij helpen met taart bakken?"*:

| Voice | Age | `voice_id` | Audition |
|---|---|---|---|
| Faye | old | `d198dc0b-c4e5-5198-aa1d-ecf5ca0927c4` | [listen](https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ/hf_20260815_070820_30813a6f-3050-412f-8b42-9c3435afae7b.mp3) |
| Willow | middle-aged | `f878bf3f-115b-5842-8934-c789c7947733` | [listen](https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ/hf_20260815_070820_6fe61e50-a43a-42cf-a442-e381467025aa.mp3) |
| Daisy | young | `032386ec-491b-5bdc-81ac-49e9a6a2c89d` | [listen](https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ/hf_20260815_070820_4cf05532-23b6-404b-a216-9681ba6303e4.mp3) |
| Evie | young | `7a6845a2-5865-5669-a0ca-8fc8d8e96528` | [listen](https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ/hf_20260815_070820_721bb993-b1b7-4746-a691-d5ae3e00d225.mp3) |
| **Gracie** ✅ | young | `09878754-f20b-5330-9790-58a8027ab5b2` | [listen](https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ/hf_20260815_070820_00ad6499-b5a2-4038-ab6a-277b1a4e8197.mp3) |

Those audition URLs are Higgsfield CDN links and may expire; the `voice_id`
column is the durable record.

A young voice makes the fairy read as a **playmate** rather than a
grandmother-figure. Worth keeping in mind when writing her lines — she should
sound like she is having fun alongside Nina, not instructing her.

Still to cast: the party guests. Give them clearly different voices from Gracie
so Nina can tell who is talking without looking.

**The oven is provisionally Barrett** (`d603a8cd-3fe1-55e0-9245-617a2589131e`),
and already speaks his fourteen kitchen lines. The pick was made from the
brief's own description rather than by ear, which is exactly what §7.1 warns
against — five auditions are in [`audio/auditions/`](audio/auditions/) and
confirming or replacing him is a minute of listening and four credits.

All five are `voice_type: preset` and support the `elevenlabs`, `minimax`, and
`seed_speech` engines, so a chosen voice can be re-run through a different
engine if the Dutch accent disappoints.

### 7.3 What the voice IDs are for

A `voice_id` is a handle into Higgsfield's voice catalogue. It selects *who
speaks* when generating a line, paired with `voice_type` (`preset` for a
built-in voice, `element` for a custom one).

The important thing is **when** it gets used: at *asset production* time, never
at runtime.

1. Pick a voice by ear from the audition.
2. Generate every line in the script with that `voice_id`.
3. Download the resulting MP3s and add them to the Xcode project as bundled
   resources.
4. The app plays local files with `AVAudioPlayer`.

**The shipped app never calls the API.** No network, no API key on the iPad, no
per-launch cost, and it works on a plane. Text-to-speech is a build step, like
compiling — not a dependency.

That is also why the IDs are worth writing down. Six months from now, adding a
new room means generating new lines with the *same* `voice_id` so they match the
ones already in the game. Lose the ID and the fairy changes voice mid-project.

Keep a `voices.json` in the repo mapping character → engine + `voice_id`, and a
plain-text script file of every line. Together those regenerate the entire
voice-over from scratch at any time, which is a much better guarantee than a
folder of MP3s nobody knows how to reproduce.

Because generation is cheap and repeatable, dialogue stops being a fixed cost.
New rooms can have new lines without a recording session, and lines can be
rewritten after watching her play. Design accordingly: write more dialogue
variants than a recorded game would, so the fairy does not repeat herself.

### 7.4 Music and sound effects — NOT available

This is the real gap. The connector's music model (`sonilo_music`) and sound
effect model (`mirelo_text_to_audio`) are both **game-pipeline only** and
explicitly refuse standalone use. So it cannot supply:

- the dance party soundtrack and the six instrument pads,
- the cake crunches, sparkle chimes, oven ping, watering can, whisk.

> **Half of this turned out not to be a gap, and the party is what proved it.**
> Every effect in the four built rooms — including **the party's six instrument
> pads and the cake crunch** — is synthesised at launch by `Audio/SoundKit.swift`:
> a few hundred lines of oscillators and envelopes rendered to PCM in
> milliseconds. They are honest placeholders, and `SoundKit` prefers a bundled
> file over the synth, so a CC0 pack still replaces them one file at a time with
> no other edit.
>
> What the synth cannot honestly stand in for is a **tune**. So the gap is now
> exactly one asset — the party loop — rather than a list, and the pads were
> never the blocker they were written down as. `GAMEPLAY.md` §9.

For a game where the party is the payoff, this is not a footnote. Sources, in
order of pragmatism:

1. **Freesound.org** — filter to CC0, which needs no attribution. Covers nearly
   all of the effects list above.
2. **A paid kids' SFX pack** — one purchase, consistent character, saves hours
   of auditioning individual files.
3. **GarageBand** for the music loops and the instrument pads. There is already
   a Mac in the picture for Xcode, and the built-in loops are royalty-free.
   Six pads is genuinely an evening's work.

Decide this before building the party room. **The party room was built without
it** (2026-08-17) and that was survivable for one reason worth keeping: the
party's rhythm is *hers* — the guests dance to the beat she taps, not to a
recording — so the room is complete in silence in a way a room waiting for a
backing track would not be. A loop, when it exists, is a layer on top rather than
the thing that makes it work.

## 8. Build order

### Step 0 — the proof of concept

**Before any game content, prove the two things that are still unknown.**
Everything else in this document is understood work; these two are claims.

1. **Does the faceted low-poly look survive on the device?**
2. **Can Nina actually drive the controls?**

The risk is lopsided. A failed visual invalidates the art direction and weeks of
asset work, so it must be answered while changing course is still cheap. Awkward
controls are tuning.

So the POC is **visually finished and functionally trivial**: one kitchen room
box with correct materials and lighting; two draggable objects; one bowl to drop
them in; one reward animation. No garden, no party, no persistence, no
cake-colour logic, no voice-over.

**Step 0a costs well under an hour and needs no app.** Model the room box in
Blender with flat shading and flat colours, export **USDZ**, and open it in
**Quick Look** on the iPad. There is no bake step. Same renderer family, real
screen, real size. If the look does not survive there, no amount of RealityKit
code will rescue it — and an hour was spent rather than a weekend. Only build
the app POC once this passes.

**Step 0b is the app.** One `RealityView`, a fixed camera, and the drag
projection from [§9.6](#96-the-honest-cost-of-going-3d).

#### It is not finished when it works for you

Your drag is precise and you know what the app expects. Hers is not and she does
not. The test is Nina's hands, on her iPad, without help.

Three cheap things that make the test worth running:

- **Log every drag path and release point.** That turns "she struggled" into
  "she releases 40pt short and low", which is a fix rather than a mystery.
- **Include one reward sound.** Not for polish — with no audio reward the
  engagement signal is misleading, and repeat attempts are the main measurement.
- **Watch for palm contact.** She will rest her whole hand on the screen. Far
  better to learn that now than in room three.

What the POC is allowed to conclude: the art direction holds or it does not; the
snap radius and target sizes need specific numbers. Nothing about whether the
game is fun — there is no game in it yet.

### Then the game

Ship something playable early and grow it. Suggested order:

1. **Kitchen + decorating**, hardcoded ingredients, no garden, no party. This is
   already a complete little toy and proves the drag-and-snap system.
2. **The party**, so the loop has an ending and a payoff.
3. **The wall of twelve frames** — persistence, level select, and the reason a
   second round exists at all. Build it as soon as one round can be completed.
4. **The garden**, which turns three screens into a real cycle.
5. **The twelve friends and their wishes** — content rather than engineering,
   and it can grow while she is already playing.
6. **The room toys**, continuously. A couple more every time a room is touched.
7. **Final voice-over**, once the dialogue has settled.

[`GAMEPLAY.md`](GAMEPLAY.md) §9 has the reasoning, and in particular why the
wall moved up the list.

Use `AVSpeechSynthesizer` with an `nl-NL` voice as the placeholder while
building steps 1–4. It sounds robotic and she would notice, but it costs
nothing and lets the script change freely. Generate the real lines only once
the dialogue has stopped moving.

Everything after that is new rooms: a dressing room for the fairy, a spell room
where drawing a shape with her finger transforms something.

Rooms 1 and 2 share nearly all their code — drag an object onto a target, snap
it, celebrate — so the second room costs a fraction of the first. That is the
main architectural reason for the hub layout.

## 9. Rendering

### 9.1 What Apple offers

**3D.** Yes, there is a 3D engine — **RealityKit** is Apple's current one,
actively developed, with a SwiftUI `RealityView`, an entity-component
architecture, PBR materials, and a USDZ asset pipeline. **SceneKit**, the older
high-level 3D API, was deprecated by Apple in 2025 and should not be chosen for
anything new. Below both sits Metal, which is not a sensible place to write a
children's game.

**2D.** SwiftUI itself (layered views, shapes, images, spring animations),
SwiftUI `Canvas` for immediate-mode drawing, and **SpriteKit**, Apple's 2D game
engine with a scene graph, physics, and particle emitters.

### 9.2 The decision: 3D in RealityKit

**RealityKit renders the world; SwiftUI wraps it** via `RealityView` and owns
the flat UI on top (the back arrow, the parent gate).

The visual target is **faceted pastel low-poly** — angular flat-shaded surfaces,
soft pastel colour, even lighting, and no ambient occlusion. See
[references/REFERENCES.md](references/REFERENCES.md) for the full specification
and §9.5 below for what it costs to render.

A simple, chunky aesthetic is what makes 3D tractable for one person, and it is
worth being precise about why. The usual objection to 3D is the art pipeline:
modelling, UV-unwrapping, texturing, rigging, and skinning every character is
specialist work measured in weeks. **Chunky stylisation removes most of it:**

- A character is 8–12 **primitives** — a box torso, a box head, cylinder limbs.
  There is nothing to sculpt.
- Joints are **rigid**. Nothing bends or deforms, so there is no skinning and no
  weight painting — the single hardest part of 3D character work simply does not
  exist here.
- Materials are **single matte colours**. No textures to author, no UV
  unwrapping, no PBR maps, and — since the art direction dropped baked ambient
  occlusion — no bakes either. See §9.5.
- The style's whole visual language is *implied* detail. A jar is a cylinder
  with a lid on it. Getting it "right" means getting it simple.

A first-pass character can be assembled procedurally in code with
`MeshResource.generateBox` and `.generateCylinder` plus a `SimpleMaterial`,
with no modelling software involved at all. That is a genuinely different
proposition from generic 3D.

The art direction adds back a little lighting work — see §9.5. That is a real
cost, but it is tuning rather than specialist asset labour, and it is paid once
for the whole project rather than per asset.

### 9.3 Why not Unity or Godot

Both are real options and the question deserves a straight answer rather than a
reflexive "stay native".

| | **RealityKit** | **Unity** | **Godot** |
|---|---|---|---|
| Language | Swift | C# | GDScript / C# |
| It is a… | 3D framework | full game engine | full game engine |
| Visual editor | Reality Composer Pro | mature | good |
| Asset ecosystem | none | **huge** (Asset Store) | small |
| Animation tooling | build it yourself | state machines, timeline | AnimationPlayer, tree |
| Physics | basic | mature | mature |
| iOS export | it *is* iOS | solid, well-trodden | works, fiddlier |
| App size added | ~0 | tens of MB | ~15–30 MB |
| Cost | free | free under $200k revenue | free, MIT |
| SwiftUI interop | native | awkward | awkward |

**Unity's real advantage is not code, it is the Asset Store.** Stylized
low-poly packs (the Synty POLYGON series and similar) would supply hundreds of
matching props for the price of a takeaway. Since art is this project's genuine
bottleneck, that is a serious argument — and the only one that would justify
switching.

It is weaker than it first appears, though, because **Kenney's CC0 kits are
engine-agnostic** (see [section 10](#10-technical-notes)). The asset advantage
turns out not to be Unity-exclusive, which removes most of its edge here.

**Godot** is the weakest fit. Its advantages over Unity are licensing and
openness — but Unity is already free at this scale, so the comparison that
matters is against RealityKit, and there Godot adds an export toolchain and a
second language while giving up native integration. It would be the right call
for a cross-platform indie game. This is not that.

**Recommendation: stay with RealityKit.** The engines' strengths are physics,
level design, animation state machines, and cross-platform export. This game
needs none of them: a fixed camera, roughly ten props per room, rigid transform
animation, no physics, one target device. What it *does* need is tight SwiftUI
integration for the flat UI, and that is precisely where an embedded engine is
worst.

**Switch to Unity if** either of these becomes true: the art bottleneck starts
killing the project despite the CC0 kits, or the game should eventually run
somewhere other than an iPad. Neither is true today.

### 9.4 RealityKit specifics

- **Scene.** One `RealityView` per room. Entities in a parent/child hierarchy.
  `ModelEntity(mesh:materials:)` for everything.
- **Materials.** `SimpleMaterial(color:roughness:isMetallic:)` with roughness
  near 1.0 and `isMetallic: false` gives the matte surface. Flat base colour and
  nothing else — no textures anywhere in the project. Avoid `UnlitMaterial`: a
  surface that ignores lighting loses its facet shading and collapses into a
  silhouette.
- **Camera.** A fixed `PerspectiveCamera` per room at a slightly elevated
  three-quarter angle — the doll's-house framing. **She never controls the
  camera.** A 4-year-old cannot orbit a viewport, and a camera that moves
  unexpectedly is how you lose her.
- **Gestures.** Entities need both a `CollisionComponent` and an
  `InputTargetComponent` before they can be hit. Then
  `DragGesture().targetedToEntity(...)` and
  `SpatialTapGesture().targetedToAnyEntity()`.
- **Animation.** `entity.move(to:relativeTo:duration:timingFunction:)` for
  discrete moves; subscribe to `SceneEvents.Update` to drive the dance clock
  per frame.
- **Scene assembly.** Reality Composer Pro ships with Xcode and is the sane
  place to lay out a room and author materials once there is more than a
  handful of entities.

### 9.5 Achieving the faceted look in RealityKit

The art direction is **faceted pastel low-poly**
([`references/REFERENCES.md`](references/REFERENCES.md)) — angular flat-shaded
geometry, soft pastels, even lighting, and **no ambient occlusion at all**. This
replaces the clay direction that this section previously described, and it makes
the rendering markedly simpler rather than harder.

**Shading comes from the facets.** Hard normals mean each polygon returns its own
value under one directional light, so a faceted sphere reads as twenty tones with
no texture and no bake. This is the whole rendering strategy, and it costs
nothing at runtime.

**Geometry must keep its hard edges.** No bevels, no smoothing, no subdivision —
the inverse of the clay requirement. Note that
`MeshResource.generateBox(size:cornerRadius:)` is now the wrong call: use a zero
corner radius, or the facets soften and the look goes.

**Lighting is one gentle key plus broad even fill.** An
`ImageBasedLightComponent` with a soft neutral environment supplies the fill; a
single `DirectionalLightComponent` with `DirectionalLightComponent.Shadow`
supplies direction and the grounding shadow. No rim lights, no dramatic
contrast, and deliberately **no dark corners**.

#### Depth without ambient occlusion

The old plan baked AO into every asset in Blender. That is dropped. Depth now
comes from four sources, none of which is a bake:

1. **Flat-shaded facets** — the primary source, and free. Smooth clay needed
   occlusion because it had almost no normal variation to shade; faceted
   geometry has variation everywhere.
2. **A real-time directional shadow** — grounds objects, and unlike a bake it
   stays correct when Nina drags something across the table.
3. **Image-based lighting** — the soft even fill, authored once and reused by
   every room, which is also what keeps rooms consistent with each other.
4. **Contact shadow blobs under draggables** — a soft dark ellipse scaled by
   proximity to the surface. Crude, cheap, dynamic, convincing at this scale.

Fallbacks if some corner still reads flat, neither of which reintroduces
per-asset Blender bakes: **hand-darkened vertex colours** (authored art, no UVs,
no textures), or **Reality Composer Pro 3's light baker**, which generates AO and
indirect lightmaps for static scenes as a tool step. Keeping that escape hatch
open costs nothing now.

RealityKit exposes no screen-space AO, so do not plan around SSAO arriving.
`POC.md` has the full breakdown.

#### Consequence for the Kenney kits

They remain the right starting geometry — 340 CC0 models is still the cheapest
art in the project — and the style change turns their main defect into an
advantage. They arrive **flat-shaded and hard-edged**, which was wrong for clay
and is exactly right here. They now need a palette swap and nothing else: no
re-materialing for softness, no UV unwrapping, no AO bake per asset.

This is the single largest cost saving in the change of direction.

### 9.6 The honest cost of going 3D

Two things genuinely get harder than they were in 2D, and they are worth
knowing before starting:

1. **Drag becomes a projection problem.** A finger moves in 2D; the object moves
   in 3D. Every drag needs the touch ray projected onto a chosen plane — the
   table surface, the counter height. This is the main new complexity, it is
   perhaps thirty lines, and it has to be right or the generous snapping in
   [section 5](#5-rules-for-a-four-year-old) will feel wrong.
2. **Lighting and framing need deliberate setup.** In 2D the image *is* the
   look. In 3D the look emerges from lights and camera, so it has to be tuned
   per room and kept consistent between them.

Expect the first room to take meaningfully longer than its 2D equivalent. Rooms
two onward should not, because both problems are solved once and reused.

### 9.7 How things move: the three-part rig

Movement is deliberately **not** anatomical. Realism is not the style, so the rig
is cut down to the smallest thing that still reads as alive:

| Part | Contents | Motion |
|---|---|---|
| **Root** | everything | squash and stretch, bob, lean, hop |
| **Body** | head, torso, arms — one solid piece | inherits the root; optional slight tilt |
| **Legs** | two separate entities | rotate at the hip, alternating |

Three moving parts, not ten. Arms never articulate, and nothing bends.

**Squash and stretch on the root does most of the work.** A character that
compresses on the beat and stretches coming off it reads as dancing far more
convincingly at this scale than articulated limbs would — and it is a single
non-uniform scale on one entity. This is the animation to build first; the legs
are a refinement on top.

The character plate makes this cheap: **the apron covers the hips**, so the seam
where the legs meet the body is hidden and the two parts never need to match
cleanly.

- Party guests dance to whatever beat she taps, because the scale and rotation
  are driven by a live clock rather than baked into fixed clips.
- New dance moves are numbers in a file, not new art.
- The same approach covers the whisk following her finger and the oven door
  swinging.

Set each leg's pivot **at the hip, not at its centre** — rotating about the
centre is the classic error and makes the legs look detached.

## 10. Technical notes

**Audio.** Overlapping sounds are guaranteed (she will hammer the music pads),
so pool `AVAudioPlayer` instances rather than creating one per hit. Set the
audio session to `.playback` so it works with the mute switch on — a silent
game reads as a broken game.

**Persistence.** A single `Codable` struct written to JSON in Application
Support. The saved state is small: the list of finished cakes with their
ingredients, sticker positions, and colours. SwiftData is more machinery than
this needs.

**iPad setup.** Lock to landscape, disable the idle timer during play, and put
the iPad in **Guided Access** so she cannot leave the app by accident. Guided
Access is doing a lot of the work that would otherwise be app-level lockdown.

**Art.** Going 3D changes what generated images are *for*. They are no longer
shippable assets — they are **concept references** that guide modelling. Nothing
generated goes into the app directly. See
[references/REFERENCES.md](references/REFERENCES.md).

Four routes to actual geometry, in order of how much they should be leaned on:

1. **Kenney's CC0 kits.** The [Food Kit](https://kenney.nl/assets/food-kit)
   (200 models) and [Furniture Kit](https://kenney.nl/assets/furniture-kit)
   (140 models) are public-domain low-poly models in exactly this style,
   covering most of what a bakery and a party room need — and being one
   artist's work, they are already mutually consistent. **Start here.** This is
   the single biggest de-risking available to the project.
2. **Primitives in code.** Boxes and cylinders with flat materials. Free,
   instant, version-controlled as source. The right choice for characters,
   which the kits do not cover.
3. **Blender → USDZ** for the few props with real character that no kit
   supplies — the magic oven, the cottage shell. Worth the detour only where a
   box will not do.
4. **`generate_3d`** (image → GLB) via the connector. Viable for *static props*,
   since it produces an unrigged mesh. Not viable for characters, which need a
   joint hierarchy. Meshes will likely need decimating to fit the low-poly look.

The consistency problem does not disappear, it moves. In 2D the risk was a
hundred images that do not match; in 3D it is a hundred models with drifting
proportions and palette. Fix it the same way: fix a **shared palette and a
proportion rule** (see the style spec) before building room 2, and derive
everything from it.

## 11. Open questions

- Casting Otto the oven, and the four voices covering the eleven friends.
- Music and SFX source — CC0 library, paid pack, or GarageBand? The party is the
  payoff and it is currently silent.
- The character proportion rule. (The palette is settled — see
  [`POC.md`](POC.md).)

> **Superseded, 2026-08-15 and 2026-08-16.** This block used to resolve two
> things that have both since been reversed by the owner, and it is kept only so
> that the reversal is legible.
>
> It said the fairy was called **Luna**, and that **Nina had no avatar** — she
> was the hands, and Luna was a separate character who lived in the bakery and
> helped, which avoided the "this is you" reaction falling flat and meant there
> was no player character to model or rig.
>
> **Both are gone.** Nina is the baker, she is on screen behind the table, and
> every line in the game is hers. Luna does not exist, and the twelfth gold
> frame that was hers is now Nina's own. The risk the old decision was
> protecting against is real and has been accepted; what it buys is a kitchen
> with somebody in it. `GAMEPLAY.md` §1 is the current text.
