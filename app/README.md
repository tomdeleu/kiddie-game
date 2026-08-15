# Nina's Toverbakkerij — De Keuken

The kitchen, whole. Gameplay, graphics and Dutch voice, in one RealityKit app
that runs on the iPad.

It grew out of the Step 0 proof of concept, whose question — *does the faceted
pastel low-poly direction survive real-time rendering without baked ambient
occlusion?* — is answered and stays answered. [Approved lighting](#approved-lighting)
below is still the record of that.

> **Never compiled.** Everything from the kitchen onwards was written in a Linux
> container with no Swift toolchain. The POC before it went through the same
> thing and needed two fixes on first build; expect similar here, and see
> [First build](#first-build) for the two places most likely to want one.

## The opening

Three layers, each uncovering the next: **title plate → film → kitchen.** The
room is built and lit underneath all of them, so whichever way she arrives, it
is simply there.

### The title plate

`Nina's Toverbakkerij`, on the cottage the film is about to push in on. It is
the game's face and the only place its name is written down — and it is the
only text anywhere in the game. `CONCEPT.md` §5 rules out text she has to read;
a name on a cover is not that.

It holds for **1.4 seconds minimum**, or until the kitchen is ready, whichever
is later — and **6 seconds maximum**, ready or not. The floor is there because
building the room on an iPad is quick enough that without one the title would
flash past in three frames and read as a glitch. The cap is there because
"she cannot lose" has to cover a first screen too: the readiness flag is set at
the end of an `async` closure, and if that closure never returned she would be
left holding a picture with no way out. An unlit kitchen she can poke is the
better failure.

A tap ends it early — and a tap anywhere, at any time, puts a sparkle under her
finger, because a screen that eats a tap silently is where she decides the iPad
is broken.

The plate breathes, 1.0 → 1.03 over 2.6 s. A still image with nothing moving on
it looks like an app that has hung.

Provenance, the eighteen candidates and the reason the asset is 16:9 rather
than 4:3 are in
[`references/loading-screen/README.md`](../references/loading-screen/README.md).
The short version: padding to 16:9 means filling the screen crops the sides,
never the top, so no iPad aspect can crop into the title.

### The film

Fourteen seconds, two shots, narrated end to end:

| | Shot | Voice |
|---|---|---|
| 1 | **Outside**, 8.04 s — a slow push-in on the bakery, smoke from the chimney, a little sparkle | 5.17 s: *"Welkom in mijn toverbakkerij! Ik ben Nina, en ik ben de bakker. Kom je mee naar binnen?"* |
| 2 | **Inside**, 6.04 s — the camera glides across the kitchen while the whisk turns in the bowl, steam lifts off Otto and the jars wobble | 5.43 s: *"Dit is de keuken. Hier bakken we de allerlekkerste tovertaarten. Zullen we beginnen?"* |

10.6 seconds of narration under 14.08 seconds of film. The gaps are where they
should be: a beat to start, **2.47 s before the cut** — she asks *"kom je mee
naar binnen?"* and the cut inside is the answer — and half a second at the end.
Wall-to-wall narration would be worse, not better.

The lines are written to the shots by measurement rather than by guess: Gracie
reads Dutch at 15–17 characters a second, so a line's length is predictable to
a few tenths. `script-intro.json` carries the numbers, so re-cutting a shot
tells you exactly how much line it can hold.

One shot per file, cut by an `AVQueuePlayer`. Asking a video model to cut
between two locations is asking it to invent the second one; a queue does it
for free and each shot stays independently re-cuttable. A third shot is
`intro-3.mp4` in the same folder and no code change.

Nina's third line is triggered by the cut itself, not by a timer, so re-cutting
a shot to a different length cannot leave her talking about the wrong picture.

### Skipping

Two ways, both doing the same thing:

- **The skip button**, bottom-right, fading in a second after the film starts.
  The skip-to-end glyph from every music player, no text on it, 72 pt across.
  It exists because tap-anywhere is invisible — a grown-up handed the iPad has
  no way to guess it, and neither does she.
- **A tap anywhere else.** Kept, because it is what she will do.

It is bottom-right on purpose: top-right is where the developer panel's hidden
triple-tap lives.

Skipping does not cost her the greeting — Nina says hello either way. The room
is built and lit behind the film while it plays, so tapping through two seconds
in lands in a kitchen that is already there.

A tap cuts the narration off; the end of the film does not. She skipped because
she wants to bake, so holding her at the door for the rest of a sentence would
be backwards — but letting the last line finish over the first second of the
kitchen is how a film ends. The greeting waits for Nina to stop talking either
way, rather than for a fixed number of seconds.

The film is silent; the voice is Nina's own, for the same reason every other
line is. It was generated with Seedance 2.5 starting from the locked cottage
plate — the provenance, the cost and why a generated asset ships here at all
are in `references/REFERENCES.md` §3.

`intro-1.mp4` and `intro-2.mp4` are optional. Delete them and the title plate
hands straight to the kitchen, with no code change — `IntroMovie.isAvailable` is
still the only thing that checks, and it now also decides which of the two
greeting paths runs.

## The round

One round is `GAMEPLAY.md` §6.3, end to end:

| Step | What she does | What answers |
|---|---|---|
| **uitrollen** | Roll the ball of dough flat with the rolling pin | It spreads under the pin, puffs flour, and hops into the tin as a base |
| **vullen** | Fetch three ingredients — **shelf, then counter, then basket** — into the bowl | A plop, a ring of sparkles, the batter rising and changing colour, and Nina naming what that ingredient will do |
| **roeren** | Stir with a finger | The whisk follows her hand, the batter turns and comes up to colour |
| **gieten** | Drag the bowl onto the tin | It tips, pours onto the base, and goes back where it lives |
| **inOven** | Drag the tin to Otto | It slides in, the door shuts, Otto is delighted |
| **bakken** | Tap Otto | Four seconds of him puffing and breathing, a rising ping, and the cake comes out in her colours |
| **klaar** | Tap the doorway | The cake goes up on the plank and a fresh round begins |

At the top of every round she hears what the whole thing is for — *"meng alle
toverdingetjes in de kom, en zet de taart daarna in de oven"* — and then the
first step. Coming back to a half-finished round skips all that and just says
where she was.

Rolling and stirring are the two mechanics that had to bend to her hands.
**Rolling** only counts while the pin is actually over the dough, so waving it
around does nothing and going back and forth does everything — about three
passes. **Three turns finishes the stirring — or twice as much scrubbing.** A 4-year-old who
cannot yet draw a circle still has to be able to make batter, so raw travel
counts at half rate.

**She cannot fail.** No drop is rejected: a miss floats home with a soft sound
and Nina says something kind. Nothing is disabled, greyed out or refused, and
every tap does something — including a tap on nothing, which sparkles.

### Where things are, and in what order

The three ingredients live in **three different places**, collected in a fixed
order: the wall shelf, the back counter, the basket on the table. One basket on
one table made the room a work surface; three places make her look up, along,
and down.

The order never has to be guessed. **The one she needs glows** — the object
itself lit from within, breathing slowly, with two or three sparkles lifting
off it — the others do not travel until their turn, and Nina names the place as
each one lights up. Out-of-turn taps still answer, with a wobble and a nudge
towards whatever is glowing. Nothing is ever disabled.

The first version of that cue was a glowing ring drawn on the table around the
prop, and it was wrong: rendered as a preview it read as a screen-space UI
element dropped into the room. `references/cues/` has the four alternatives it
was judged against and why this one won.

### Nina

She stands behind the table and works. Built from
`references/plates/02-fairy-character.png` — mint hat with a knob, apron, pink
pocket, faceted wings — on `CONCEPT.md` §9.7's three-part rig: one solid body,
two legs pivoting at the hip, squash and stretch on the root.

She bobs, leans towards whatever the current step is about, shifts her weight,
flutters her wings, and hops when something goes right. Her arms never
articulate and nothing bends — a baker who stirs with her shoulders needs
inverse kinematics; a baker who leans her whole body over the bowl needs one
rotation and a sine wave, and at this scale reads better.

**The voice is hers.** Until 2026-08-15 the speaker was a separate fairy called
Luna and Nina had no avatar at all; the owner reversed both. Ten lines that
named Nina in the second person were regenerated in the first, every id and
filename moved from `luna.*` to `nina.*`, and what that leaves open on the wall
of frames is recorded in `GAMEPLAY.md` §1.

### Starting over

A **restart button**, bottom-left, same size and weight as the intro's skip
button and with no text on it either. It throws away the cake she is holding,
keeps every cake already on the plank, and Nina says so out loud.

She can press it, and that is fine: nothing finished is ever lost. If she turns
out to press it constantly, the fix is to move it behind the parent gate — not
to add a confirmation, which is unreadable to her by definition.

### The toys

Six, none of which gate anything: the flour sack (a poof, and flour that
settles on the counter and fades), the tap, the scale, the six shelf jars, the
rolling pin (it actually rolls), and Otto himself, who says something different
every single time he is poked.

### Idle

After ~25 s of nothing, the thing she needs shimmers. After ~45 s Nina says one
short line — alternating with "I'm still here" so she never says the same thing
twice running. Then it goes quiet for a minute.

## Two deliberate deviations from the design

**The doorway is not yet a door.** `GAMEPLAY.md` §7 says the door always works,
even mid-task. Here it cannot: the decorating room does not exist, so there is
nowhere to go. What it does instead is honest rather than fake — mid-round it
whooshes and Nina says what is happening now; once the cake is out it ends the
round, puts the cake on the plank and brings a fresh basket. **When the
decorating room lands, `tapDoorway()` is the one function to change.**

**The palette gained a blue.** The locked thirteen sampled from the plates have
pink, mint, sage, cream, butter and wood, and no blue at all — the plates
simply had none in frame. `GAMEPLAY.md` §5 needs one: the toverbosbes gives a
blue cake and Bo de vogel's entire wish is one. `Palette.berryBlue` and
`berryBlueDeep` are built to sit in the same register rather than sampled, and
the derivation is written down where they are defined. Sample a real one if a
plate with blue in it ever gets rendered.

## The plank instead of the wall

`GAMEPLAY.md` §2 says the wall of twelve frames is the game. It lives in the
bakery, which does not exist yet, so the kitchen has **de taartenplank** on the
back wall holding her last four cakes. It does the same job in miniature: it
means the second cake is not the first cake again. It is a stand-in and should
be retired when the wall arrives, not grown.

## What is in it

| File | What |
|---|---|
| `Engine/CameraRig.swift` | The fixed camera, and screen ↔ world. Every drag in the room is a ray and a plane. |
| `Engine/Ticker.swift` | The one clock. Every animation is an interruptible closure ticked from here. |
| `Engine/TouchRouter.swift` | One finger, two verbs. Targets are generous spheres, not meshes. |
| `Engine/Sparkles.swift` | Faceted bits that fly out and vanish. The whole reward vocabulary. |
| `Engine/Halo.swift` | The glow on the prop a step is about — the game's only instruction. |
| `Intro/LoadingScreen.swift` | The title plate, and the floor it is held for. |
| `Intro/IntroMovie.swift` | The opening film: a queue of shots, and two ways out of it. |
| `Audio/SoundKit.swift` | All thirteen sound effects, synthesised at launch. |
| `Audio/VoiceBank.swift` | Nina and Otto, driven by `script-keuken.json`. |
| `Game/CakeSpec.swift` | Six ingredients → colour, effects, and what Nina says about them. |
| `Game/RoundState.swift` | The round, and the JSON it is saved to. |
| `Kitchen/KitchenProps.swift` | Otto, the bowl, the batter, the tin, the cake, the toys. |
| `Kitchen/KitchenRoom.swift` | The room: assembly, the state machine, the toys, the nudges. |
| `RoomBuilder.swift` | The shell and the furniture, plus `Layout` — every position in the room, in one table. |
| `FacetedMesh.swift` | **The core of the look.** Flat-shaded primitive builders, plus the smooth variant for A/B. |
| `Palette.swift` | The locked colours, the two added ones, and the glow material. |
| `LightingRig.swift`, `LightingSettings.swift`, `DebugPanel.swift`, `ContactShadows.swift` | The POC's lighting work, unchanged. |
| `ContentView.swift` | Scene assembly, the gesture, and the hidden developer panel. |

### Why the touch handling is hand-rolled

RealityKit offers `DragGesture().targetedToAnyEntity()` with a
`CollisionComponent` per prop. This game wants the opposite of precise: ~120 pt
targets, and a drop that counts when it lands *near* the bowl. Owning the ray
means that generosity is one number in one file instead of a collision shape on
every entity — and it makes "how big is this target, really" answerable.

### The flat-shading trick

`FacetedMesh` exists because RealityKit's built-in primitives are all smooth or
rounded, which is exactly what this style must not be. Every triangle gets its
own three vertices carrying the face normal, so no normal is shared between
adjacent faces. That is what makes an 80-face sphere return ~80 distinct tones
under a single light — and it is the whole argument for not needing AO.

Because the normal comes from the winding, **winding is load-bearing** — a
reversed triangle is both unlit and invisible, and you see the surface behind
it. Every primitive is a closed solid wound outward (the dome's base is the one
deliberate exception; it sits on the floor, and a disc there would z-fight). A
hollow vessel needs a real inner wall — a single-walled cone has no inside,
which is why `bowl` exists and `taperedPrism` is not it.

The **Flat shading** toggle in the debug panel switches to averaged normals.
That is the "before" picture, and it is still the single most informative
control in the app.

## Running it

```
open app/NinaBakeryPOC/NinaBakeryPOC.xcodeproj
```

The project uses Xcode's file-system-synchronized groups, so `Sources/` and
`Resources/` are picked up by folder — new files in `Engine/`, `Audio/`,
`Game/` and `Kitchen/` need no project edit.

**The target is still called `NinaBakeryPOC`.** It builds and runs under that
name; renaming a working project buys nothing.

### The simulator

**RealityKit does not render reliably in the iOS Simulator.** That is a
long-standing limitation, not a setup problem.

| Where | Use it for | Reliability |
|---|---|---|
| **iPad, on device** | The actual verdict, and the only place to test with Nina. | The real answer |
| **My Mac** | Fast iteration on lighting and layout. | Good |
| **iOS Simulator** | Try it; it may work in non-AR mode. | Unreliable — conclude nothing from it |

### First build

Two places are the most likely to want a fix, and both are one line:

1. **`CameraRig.fovIsVertical`.** `init` sets
   `camera.camera.fieldOfViewOrientation = .vertical` so the unprojection maths
   is not a guess. If that property ever fails to resolve, delete the line and
   set the constant to `false` — RealityKit's own default is horizontal, and
   everything else keeps working. If drags feel offset from her finger, this is
   the first thing to check.
2. **`Palette.glowMaterial`.** Uses `emissiveColor` / `emissiveIntensity` on
   `PhysicallyBasedMaterial`. Only three things glow (a honey cake, Otto's door
   while baking, the doorway), so if the API has moved, that one function is the
   only place to fix it.

### The developer panel

**Triple-tap the top-right corner.** Hidden on purpose: `CONCEPT.md` §5 asks for
a parent gate she will not find, and a visible gear is a thing she will press.

It shows the step, what is in the bowl, the stir percentage, and **which voice
line just played** — during a session with Nina that is the difference between
"she ignored it" and "she never heard it". Plus a new round, a mute, and the
whole POC lighting panel underneath.

## Approved lighting

**Settled on iPad, 2026-08-15.** The values in `LightingSettings.swift` are the
approved ones — every slider was judged good where it started, so the committed
defaults *are* the result.

| | |
|---|---|
| Key | 2200 lx, 42° elevation, 135° azimuth, 6200 K, shadows **on** |
| Fill | 900 lx, 7800 K, opposite the key at 18° |
| IBL | off — no environment bundled, and it is not missed |
| Contact shadows | on, opacity 0.18, scale 1.15 |
| Lightmap | off |

This answers the POC's main question in the affirmative: **the faceted direction
holds with real-time light only, no baked AO.** The key light's cast shadow does
the grounding that AO was there for, and it stays correct when a prop moves.

Changing these is an art-direction decision, not a tweak. Lift any new setup
with **Copy settings** before overwriting.

## Audio

**Voice is real.** 86 Dutch lines, generated with `text2speech_v2` /
`elevenlabs` and bundled as mp3s — the app never calls an API. Nina is Gracie;
Otto is provisionally Barrett, and `audio/auditions/README.md` explains how to
swap him for four credits and no code.

**Sound effects are synthesised.** Thirteen of them, rendered to PCM at launch
by `SoundKit`. `CONCEPT.md` §7.4 records that the connector cannot supply SFX;
Freesound or a bought pack is still the plan, and until then these are honest
placeholders. Swapping one in is a filename in `Sound.fileName`.

**Music is absent**, as agreed. `GAMEPLAY.md` §10 still has it open.

## What this room may not conclude

Whether the *game* is fun. There is one room, no friend at the door, no wish, no
party, and no wall. What it can answer is whether she can drive it: whether the
snap radius and the target sizes are right, whether stirring works with her
hand, and whether she taps Otto again.

`POC.md` has the testing protocol, and it still applies: her iPad, Guided Access
on, you not helping and not narrating.
