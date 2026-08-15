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

## The round

One round is `GAMEPLAY.md` §6.3, end to end:

| Step | What she does | What answers |
|---|---|---|
| **vullen** | Drag three ingredients from the basket into the bowl | A plop, a ring of sparkles, the batter rising and changing colour, and Luna naming what that ingredient will do |
| **roeren** | Stir with a finger | The whisk follows her hand, the batter turns and comes up to colour |
| **gieten** | Drag the bowl onto the tin | It tips, pours, and goes back where it lives |
| **inOven** | Drag the tin to Otto | It slides in, the door shuts, Otto is delighted |
| **bakken** | Tap Otto | Four seconds of him puffing and breathing, a rising ping, and the cake comes out in her colours |
| **klaar** | Tap the doorway | The cake goes up on the plank and a fresh basket arrives |

Three turns finishes the stirring — **or twice as much scrubbing**. A
4-year-old who cannot yet draw a circle still has to be able to make batter, so
raw travel counts at half rate. It is the one mechanic in the room that had to
bend to her hands rather than the other way round.

**She cannot fail.** No drop is rejected: a miss floats home with a soft sound
and Luna says something kind. Nothing is disabled, greyed out or refused, and
every tap does something — including a tap on nothing, which sparkles.

### The toys

Six, none of which gate anything: the flour sack (a poof, and flour that
settles on the counter and fades), the tap, the scale, the six shelf jars, the
rolling pin (it actually rolls), and Otto himself, who says something different
every single time he is poked.

### Idle

After ~25 s of nothing, the thing she needs shimmers. After ~45 s Luna says one
short line — alternating with "I'm still here" so she never says the same thing
twice running. Then it goes quiet for a minute.

## Two deliberate deviations from the design

**The doorway is not yet a door.** `GAMEPLAY.md` §7 says the door always works,
even mid-task. Here it cannot: the decorating room does not exist, so there is
nowhere to go. What it does instead is honest rather than fake — mid-round it
whooshes and Luna says what is happening now; once the cake is out it ends the
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
| `Audio/SoundKit.swift` | All thirteen sound effects, synthesised at launch. |
| `Audio/VoiceBank.swift` | Luna and Otto, driven by `script-keuken.json`. |
| `Game/CakeSpec.swift` | Six ingredients → colour, effects, and what Luna says about them. |
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
`elevenlabs` and bundled as mp3s — the app never calls an API. Luna is Gracie;
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
