# Nina's Toverbakkerij — concept

A magic-bakery game for Nina, aged 4, in Dutch, on iPad. Native SwiftUI with
RealityKit, in a cosy isometric clay-miniature 3D look.

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

Four rooms, played in order, roughly 5–8 minutes end to end.

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

The cake is carried to a table. Guests arrive. Music starts.

Six big pads along the bottom, each an instrument. Whatever she taps, the guests
dance to — the animation speed follows the beat she is making. Then everyone
eats the cake with enormous crunching sounds, applause, and the head fairy says:

> "Dankjewel, Nina! Dit was de allerlekkerste taart!"

Then the cake is photographed and hung on the bakery wall in a little frame.

## 4. The hub and the collection

The home screen is the bakery cottage as a single clay miniature, with the
garden beside it. Tap it to go in, tap the big arrow to come home. That is the
whole navigation model and the only thing she has to learn.

Inside, each room is an **open corner room box** — two walls and a floor, seen
from a fixed isometric angle, open on the two near sides. Moving between rooms
slides one box out and the next in, which is a transition she can follow. See
[`references/REFERENCES.md`](references/REFERENCES.md) for why this framing was
chosen.

**Every cake she finishes gets framed and hung on the bakery wall.** That is the
progression system. It needs no numbers, no stars, and no reading — she can see
her gallery growing and point at the one she made yesterday. Tapping a frame
replays that cake's little party animation.

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

### 7.2 The fairy's voice — DECIDED

**Gracie.** Young female preset, `elevenlabs` engine.

```
model      text2speech_v2
variant    elevenlabs
voice_type preset
voice_id   09878754-f20b-5330-9790-58a8027ab5b2
```

Also recorded in [`audio/voices.json`](audio/voices.json), which is the file to
read when generating lines.

Every line the fairy speaks — now and in any room added later — uses this ID, so
she does not change voice mid-project.

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

Still to cast: the oven, and the party guests. Give them clearly different
voices from Gracie so Nina can tell who is talking without looking.

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

For a game where the party is the payoff, this is not a footnote. Sources, in
order of pragmatism:

1. **Freesound.org** — filter to CC0, which needs no attribution. Covers nearly
   all of the effects list above.
2. **A paid kids' SFX pack** — one purchase, consistent character, saves hours
   of auditioning individual files.
3. **GarageBand** for the music loops and the instrument pads. There is already
   a Mac in the picture for Xcode, and the built-in loops are royalty-free.
   Six pads is genuinely an evening's work.

Decide this before building the party room.

## 8. Build order

Ship something playable early and grow it. Suggested order:

1. **Kitchen + decorating**, hardcoded ingredients, no garden, no party. This is
   already a complete little toy and proves the drag-and-snap system.
2. **The party**, so the loop has an ending and a payoff.
3. **The wall of cakes** — persistence, and the first thing that makes her come
   back tomorrow.
4. **The garden**, which turns three screens into a real cycle.
5. **Final voice-over**, once the dialogue has settled.

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

The visual target is a **cosy isometric clay miniature** — soft matte surfaces,
rounded edges, warm muted colour, and heavy ambient occlusion. See
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
  unwrapping, no PBR maps. (Baked ambient-occlusion maps are the one exception —
  see §9.5.)
- The style's whole visual language is *implied* detail. A jar is a cylinder
  with a lid on it. Getting it "right" means getting it simple.

A first-pass character can be assembled procedurally in code with
`MeshResource.generateBox` and `.generateCylinder` plus a `SimpleMaterial`,
with no modelling software involved at all. That is a genuinely different
proposition from generic 3D.

What the clay direction *does* add back is lighting work — see §9.5. That is a
real cost, but it is tuning rather than specialist asset labour, and it is paid
once rather than per asset.

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
  near 1.0 and `isMetallic: false` gives the matte toy-plastic surface.
  `UnlitMaterial` where a surface should stay perfectly flat regardless of
  lighting.
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

### 9.5 Achieving the clay look in RealityKit

The art direction is a **cosy isometric clay miniature**
([`references/REFERENCES.md`](references/REFERENCES.md)), not the flat Roblox
look this section originally assumed. That changes the rendering requirements
materially, and one of the changes is a genuine risk.

**Materials must respond to light.** `UnlitMaterial` and flat colour are now
wrong — they were right for the Roblox look and produce cardboard here. Use
`SimpleMaterial` with roughness near 1.0 and `isMetallic: false`, or
`PhysicallyBasedMaterial` for finer control.

**Geometry needs rounded edges.** Soft edges are what catch the light and read as
clay. Conveniently, RealityKit builds them natively:
`MeshResource.generateBox(size:cornerRadius:)`. Use a non-zero corner radius
everywhere; a sharp box will look wrong regardless of colour.

**Lighting is one soft key plus broad ambient fill.** An `ImageBasedLight` with a
soft neutral environment does most of the work; add a single directional light
for gentle grounding shadows. No rim lights, no dramatic contrast.

#### The hard part: ambient occlusion

The soft darkening pooling in corners and under objects is *the* reason the
reference reads as clay rather than cartoon. It is also the thing real-time
rendering on an iPad gives least willingly — RealityKit does not expose
production-quality screen-space AO.

Two routes, and they should be combined:

1. **Bake AO into the models.** Blender bakes an AO map per asset; RealityKit
   just displays it. Excellent quality, effectively free at runtime, and correct
   for everything static — walls, shelves, the oven.
2. **Fake contact for dynamic objects.** Baked AO cannot know that Nina just
   dragged an egg next to the bowl. Give every draggable a soft dark blob
   underneath, scaled by proximity to the surface. Crude, and completely
   convincing in a stylised scene.

**Prototype this before committing.** Build one room, bake its AO, put it on the
iPad and look at it. If the clay quality does not survive contact with the
device, that is worth knowing in week one rather than after four rooms are
modelled.

#### Consequence for the Kenney kits

They remain the right starting geometry — 340 CC0 models is still the cheapest
art in the project. But they are **flat-shaded and hard-edged**, so they arrive
in the old style, not this one. Expect to re-material them, and to bake AO
per asset. That is a real cost, and it is still far below modelling from
scratch.

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

**Squash and stretch on the root does most of the work.** A clay character that
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

- Casting the oven and the party guests.
- Which reference plate is *the* look, so it can be locked as an image reference
  for everything after it?
- The shared 12-colour palette and the character proportion rule.
- Music and SFX source — CC0 library, paid pack, or GarageBand?
- Does the fairy look like her, or is the fairy a separate character she helps?
  (Helping a character is usually the easier sell at this age — being told "this
  is you" can fall flat if the drawing does not match her self-image.)
