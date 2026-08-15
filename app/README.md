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

The view fills the screen the way `object-fit: cover` does, and getting there
takes three things together — a `GeometryReader` to measure, an explicit
`frame` to pin the image to that size, and `clipped()` to throw the overflow
away. **`scaledToFill()` alone does not do it**, which is worth knowing before
writing the next full-bleed screen: it reports its overflowed size as its
layout size, so the enclosing stack grows to the image rather than cropping it.
The plate came out too big, and off-centre with it, because the stack it sits
in is `alignment: .topTrailing` for the developer corner's sake and an
oversized child gets pinned to a corner instead of centred.

### The film

Fourteen seconds, two shots, narrated end to end:

| | Shot | Voice |
|---|---|---|
| 1 | **Outside**, 8.042 s — a slow push-in on the bakery, smoke from the chimney, a little sparkle | 7.50 s: *"Welkom in mijn toverbakkerij! Ik ben Nina, de bakker. Hier maak ik de allermooiste tovertaarten. Kom je mee naar binnen?"* |
| 2 | **Inside**, 6.042 s — the camera glides across the kitchen while the whisk turns in the bowl, steam lifts off Otto and the jars wobble | 5.83 s: *"Dit is mijn keuken. Hier bakken we de allerlekkerste tovertaarten. Zullen we samen beginnen?"* |

**13.33 seconds of narration under 14.08 seconds of film**, each line ending
about two tenths of a second before its own cut. It used to be 10.6, and the
missing three seconds were audible: each shot went quiet a third of the way
from its end and the film sat there looking like it was buffering. Both lines
were rewritten longer and regenerated.

The long pause before the cut is gone with them. It was carrying *"kom je mee
naar binnen?"* as a question the cut answered — which is still true, except the
question is now the last thing in the shot rather than a beat before the end,
which is a better place for it.

The lines are written to the shots by measurement rather than by guess: Gracie
reads Dutch at 15–17 characters a second, so a line's length is predictable to
a few tenths. The films were measured out of their `mvhd` atoms, the lines
sized to fill them, and the delivered mp3s measured back — `script-intro.json`
carries all of it, so re-cutting a shot tells you exactly how much line it can
hold.

**It plays full-screen.** `videoGravity` is `.resizeAspectFill` — the shots are
16:9, the iPad is 4:3, and fitting them left black bars across a third of the
screen so the opening read as a video embedded in an app rather than as the app
starting. Filling crops the sides; both shots are centred, so what is lost is
wall.

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
  no way to guess it, and neither does she. It is a
  [`FacetButton`](#the-button), the game's one control.
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
| **vullen** | Fetch **five ingredients**, one from each of five places, into the bowl | A plop, a ring of sparkles, the batter rising and changing colour, and Nina naming what that ingredient will do |
| **roeren** | Stir with a finger | The whisk follows her hand, the batter turns and comes up to colour |
| **gieten** | Drag the bowl onto the tin | It tips, pours onto the base, and goes back where it lives |
| **inOven** | Drag the tin to Otto | It slides in, the door shuts, Otto is delighted |
| **bakken** | Tap Otto | Four seconds of him puffing and breathing, a rising ping, and the cake comes out in her colours |
| **klaar** | **Carry the cake up onto the plank** | It rises to shelf height as it nears the wall, shrinks, lands beside the others, and a fresh round begins |

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

**She cannot fail.** No drop is rejected, nothing is disabled, greyed out or
refused, and every tap does something — including a tap on nothing, which
sparkles.

**Sparkles are yellow stars.** They were `creamLight` icospheres, which at
sparkle size is a grey dot — an unlit cream ball two millimetres across against
a room that is mostly cream reads as dust. A star's silhouette survives being
three pixels wide, and warm yellow is the one hue nothing in the room is
painted, so a sparkle is never mistaken for a crumb of the thing it came off.
Callers that pass a colour still get it: an ingredient dropping into the bowl
throws its own colour, which is what says *that* one went in.

**And nothing gets put back** — with one exception. A prop she drags somewhere
that is not a target settles onto whatever is underneath it and stays there.
The rolling pin can live on the floor. The exception is the patch of floor
*behind the table*: the camera never moves, so that is a place she could put
something and then genuinely not get it back, with no way to look round the
table. Drops there float home. `Layout.isOutOfSight` derives the patch from the
camera and the table rather than hardcoding it — at the committed camera it is
about 170 × 140 mm between the table and the counter. This replaced a rule where a missed drop floated home and
Nina apologised for it, which was wrong twice: it undid the one thing she can
do with a kitchen full of objects, and it treated every stray drag as a failed
attempt when most of them are a 4-year-old moving a rolling pin because it is
a rolling pin.

**Three misses and the instruction comes back.** A miss now means something
narrow — she dragged the prop the current step is about and it did not land —
so it is a real signal rather than noise. Twice, Nina says something kind.
The third time she says the step's own line again, at full priority, and the
lit prop gives a squash while she does. She cannot read a reminder, so this is
the only way one can reach her.

### Where things are

The five ingredients live in **five different places**: the upper wall shelf,
the lower wall shelf, a pot on the back counter, the basket on the table, and
a crate on the floor. One basket on one table made the room a work surface;
five places make her look up, along, and down.

The two that were added are deliberately the extremes of reach — the top shelf
is the highest thing in the room, the crate is on the ground — because
everything else in the kitchen lives on a work surface within ten centimetres
of the same height. Those two are most of what makes the room feel like it has
a ceiling and a floor.

**The order is a suggestion now, not a rule.** The one she needs glows — the
object itself lit from within, breathing slowly, with sparkles lifting off it —
and Nina names the place as it lights up. But every ingredient can be picked up
whenever she likes, and any of them dropped in the bowl counts; the glow simply
moves on to whatever is left. What used to happen was that out-of-turn props
wobbled and refused to travel, which is a locked door with a nice sound on it.

The first version of that cue was a glowing ring drawn on the table around the
prop, and it was wrong: rendered as a preview it read as a screen-space UI
element dropped into the room. `references/cues/` has the four alternatives it
was judged against and why this one won.

**The cue is a ring of light on the surface, and it took three goes.** It was a
hard-edged ring on the table, rejected from the previews in `references/cues/`
as reading like screen-space UI; then the object itself lit from within, which
failed twice on the iPad — first invisible, then, turned up far enough to see,
recolouring a whole prop to say one thing. Pale pastels under a 2200 lx key are
already returning most of the light they can, so an emissive term below 1 moves
them a few percent, towards white, in a room where everything is nearly white.

It is now a **soft** ring on the surface *around* the prop, picked from
`references/cues/floor/` and built to the sampled colours of that plate: a
`#F6D861` gold washing out to `#FFF6D8` at the core, with the interior left
clear. The object keeps its own colour entirely. Softness is the whole reason
this version survives where the first ring did not — a hard edge is what UI has
and light does not.

It is eighteen concentric bands of geometry at graded opacities on a Gaussian
profile, not a texture. A radial-gradient texture needs `TextureResource`, a
hand-built `CGImage`, UVs `FacetedMesh` does not produce, and an assumption
about `UnlitMaterial` honouring a base-colour alpha channel — four things that
can fail on a first build, into a bright yellow square. The bands need none of
it, and at these sizes each one is about a screen point wide.

The ring is a **sibling** of the prop, not a child, placed each frame at the
prop's XZ on whatever surface is beneath it. That is what keeps it on the table
while the prop is lifted off it — most of what makes a held thing look held —
and what lets it climb onto the plank with the cake.

Three cues in, the lesson is that this decision cannot be made from a render:
all three looked fine as plates. **Judge the next one on the device.**

### Height

**Props have one now**, and it is most of what stopped the room reading as a
painted backdrop. Everything used to be carried at table height whatever it was
over, so a rolling pin dragged off the table hung in mid-air above the floor.

A carried prop now rides just above whatever is underneath it — table, counter,
floor — and eases there over about a third of a second rather than snapping.
Pick a berry off the top shelf and it swoops down as she brings it to the bowl;
carry it back over the table and it lifts again. `Layout.surfaceY` is the whole
model: four rectangles, tested nearest-camera first.

**The drag plane is fixed for the length of a drag**, and that is not laziness.
It was written down every frame at first, so the prop stayed pinned under her
fingertip while it changed height — which is a feedback loop, because the
height depends on the XZ and the XZ depends on the plane. Raising the plane by
Δ slides the ray's intersection about 1.7Δ towards the camera at this camera
angle, which can move the prop straight back out of the region that raised it.
It made the cake impossible to put on the plank: reaching the plank zone lifted
it 67 mm, which slid the mapped point out of the zone, so it dropped back to
the counter, which slid it back in, and it juddered between the two.

With the plane fixed, XZ is a pure function of her finger and cannot oscillate.
The prop drifts up or down *on screen* against her fingertip as it changes
surface, which reads better anyway — vertical movement against a still finger
is the clearest way of saying "this is on the floor now". `tracksEntity` picks
the plane up from wherever the prop ended when she next grabs it.

One case needed guarding: every tap is also a zero-length drag, so without a
"barely moved" check, poking the berry on the top shelf would knock it to the
floor — because that is what is under a shelf.

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

Seven, none of which gate anything: the flour sack, the tap, the scale, the six
shelf jars, the crate, the rolling pin (it actually rolls), and Otto himself,
who says something different every single time he is poked.

Two of them were rebuilt from plates in `references/ingredients/`:

**The flour sack is on the floor, and looks like a sack.** It used to be a
30 mm tapered prism standing on the counter, which read as a paper cup. A sack
of flour is a heavy thing that slumps — wide and settled at the bottom,
swelling to its widest a third of the way up, gathered into a band at the neck
with the cloth above it fanning open, and two corners of cloth splaying where
it meets the ground. That profile only works at a size a worktop cannot spare,
so it moved down to the near-left floor, where it is also the only prop in
front of the table and gives the shot a foreground.

**What comes out of it went to a cloud and came back.** `flour-cloud.png`
showed a cluster of overlapping lit lobes; it was built, and on device it read
as *photographic* — a real puff of real flour in a room made of flat pastel
facets. It was the one thing in the kitchen that looked like it came from
somewhere else, which is what the four style phrases exist to prevent, and the
owner called it on sight. `Sparkles.puff` is back. The plate still earned its
credit: the sack it was generated alongside is the version that shipped, and a
brief can be right about one thing and wrong about another. One thing was kept
from the cloud — the sack billows twice, a fifth of a second apart, the way a
slapped sack does.

**The tap was rebuilt too.** It was a single five-sided prism scaled up the Y
axis, and it read as a blue stick appearing. Four things now overlap: the
stream has a shape (narrow at the spout, swelling where it picks up speed,
pulling in at the bottom); it turns about its own axis at roughly a revolution
a second, so its six big facets travel and the surface reads as running; the
basin *fills*, and drains afterwards, because water that never accumulates is
the tell; and it splashes, with a ripple twice a second and droplets bouncing
back out. The stream and the pool are slightly transparent, which is the one
place in the game that overrules `references/REFERENCES.md`'s no-transparency
rule — opaque water in a pastel palette reads as painted plastic.

### Idle

After ~25 s of nothing, the thing she needs shimmers. After ~45 s Nina says one
short line — alternating with "I'm still here" so she never says the same thing
twice running. Then it goes quiet for a minute.

### The ingredients

All six were remodelled, and each one has a plate in
`references/ingredients/` that is its brief.

They used to be six coloured blobs — two icospheres, a hexagonal prism and a
smaller icosphere, told apart only by tint. That failed the one job an
ingredient has. `CONCEPT.md` §5 forbids text, so the **shape is the label**,
and "a slightly bigger pale sphere" does not say wolkenroom to anybody, least
of all to someone who cannot read the word either.

| | Reads as |
|---|---|
| **regenboogaardbei** | A berry that swells high and comes to a point, under a splayed crown of six flat leaves |
| **toverbosbes** | A round berry with the little five-point crown a real blueberry has |
| **zonnehoning** | A pot with a dipper across it — honey has no shape of its own, so the readable object is the jar |
| **toverklaver** | Four flat hearts on a stem, tips meeting at the hub. Four, not three: the plate came back lucky and it suits the one ingredient with *tover* in its name |
| **wolkenroom** | Four overlapping faceted spheres, the only way a cloud has ever been built in this style |
| **sterrensuiker** | One chunky star with a raised centre ridge, standing on two arms |

All six are ~20 mm in both directions, so none of them is the big one. Most of
them are `FacetedMesh.lathe`, which is new: a profile revolved about Y, with a
radius of zero becoming an apex rather than a degenerate ring. Six profiles are
a great deal less code than six mesh builders, and it holds them all to the
same facet count. `extrude` and `star` are the other two additions — a flat
outline given thickness, and a two-sided pyramid star.

The clover and the star are flat-fronted, so they are turned 45° to face the
camera. The camera never moves (`CONCEPT.md` §9.4), so that is a constant
rather than a billboard.

## Deliberate deviations from the design

**The doorway is not a door, and no longer ends the round either.**
`GAMEPLAY.md` §7 says the door always works, even mid-task. Here it cannot: the
decorating room does not exist, so there is nowhere to go. It is now a prop
that whooshes and says what is happening. **When the decorating room lands,
`tapDoorway()` is still the one function to change.**

What it used to do was end the round, and that was the weakest moment in the
game. Everything else she does is a thing with her hands on the object — roll
it, fill it, stir it, pour it, push it into Otto — and then the cake she had
just made was finished by tapping a different object across the room, which
happened to be an arch, while the cake flew onto the plank by itself.
**She carries it up there now.** Same verb as every other step, ending on the
object the whole round was about, and it makes the plank — the stand-in for
the wall of twelve frames, and therefore for the whole game — somewhere she
reaches rather than somewhere things appear.

That step is the one place two things are lit at once: the cake, because it is
what she picks up, and the plank, because it is where it goes. Every other step
lights exactly one prop. A journey has two ends.

**The palette gained a blue, and then an amber.** The locked thirteen sampled
from the plates have pink, mint, sage, cream, butter and wood, and no blue at
all — the plates simply had none in frame. `GAMEPLAY.md` §5 needs one: the
toverbosbes gives a blue cake and Bo de vogel's entire wish is one.
`Palette.berryBlue` and `berryBlueDeep` are built to sit in the same register
rather than sampled. `honeyAmber` was added the same way and for the same kind
of reason — `butterYellow` beside `creamLight` does not read as a liquid, so
the honey pot swallowed its own honey. It is `butterYellow` carried two steps
towards `sandyWood`, and it appears on exactly one surface in the game. Sample
real ones if a plate with either in it ever gets rendered.

**And then a dark.** With Otto's door standing open for most of the round
(owner's note on the 2026-08-15 build), the inside of his mouth has to read as
a cavity, and the locked thirteen bottom out at `woodBrown` — a surface colour.
`Palette.ovenInside` is `woodBrown` taken darker, used for that one interior
and nothing else. The no-AO rule is about shadow pooled onto surfaces; a mouth
is the one place where dark is the subject.

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
| `Engine/TouchRouter.swift` | One finger, two verbs. Targets are generous spheres, not meshes, and each carries the plane its prop is standing on. |
| `Engine/Sparkles.swift` | Faceted yellow stars that fly out and vanish. The whole reward vocabulary. |
| `Engine/Halo.swift` | The ring of light on the surface under the prop a step is about — the game's only instruction. |
| `Intro/LoadingScreen.swift` | The title plate, and the floor it is held for. |
| `Intro/IntroMovie.swift` | The opening film: a queue of shots, and two ways out of it. |
| `Audio/SoundKit.swift` | All thirteen sound effects, synthesised at launch. |
| `Audio/VoiceBank.swift` | Nina and Otto, driven by `script-keuken.json`. |
| `Game/CakeSpec.swift` | Six ingredients → colour, effects, and what Nina says about them. |
| `Game/RoundState.swift` | The round, and the JSON it is saved to. |
| `Kitchen/KitchenProps.swift` | Otto, the bowl, the batter, the tin, the cake, the six ingredients, the toys. |
| `Kitchen/KitchenRoom.swift` | The room: assembly, the state machine, the toys, the nudges. |
| `RoomBuilder.swift` | The shell and the furniture, plus `Layout` — every position in the room, in one table. |
| `FacetedMesh.swift` | **The core of the look.** Flat-shaded primitive builders — `lathe`, `extrude`, `star` and `annulus` are what the ingredients and the halo are made of — plus the smooth variant for A/B. |
| `Palette.swift` | The locked colours, the four added ones, the glow and water materials, and `shade` for the 2D UI. |
| `UI/FacetButton.swift` | **The button.** One faceted octagon, every control in the game. |
| `LightingRig.swift`, `LightingSettings.swift`, `DebugPanel.swift`, `ContactShadows.swift` | The POC's lighting work, unchanged. |
| `ContentView.swift` | Scene assembly, the gesture, and the hidden developer panel. |

### The button

Every control she touches outside the room is one object: an octagonal cap with
a chamfered cream rim, a flat deep-pastel face and one big white glyph. It comes
from `references/buttons/G-faceon-mint.png` — that folder's README has the nine
candidates and the measurements — and it is drawn, not shipped as an image.

Three things it settles for everything that comes after the kitchen:

- **The rim does the shading.** Eight chamfer facets, each taking its tone from
  its own angle to one 45° key light. It is the room's shading model done in 2D,
  because the SwiftUI overlay has no renderer to do it. No gradients — a
  gradient is a smooth curved surface with extra steps.
- **The face is always a deep palette colour**, and the glyph is always white,
  at 42% of the button's width. White on base mint is a contrast ratio of 1.43;
  the four tones run 1.80 to 2.46. She is four, and a glyph she has to hunt for
  is a button that does not work.
- **Pressing sinks it.** The cap scales down, drops 2 pt, and the whole chamfer
  ring inverts — which is what a cap going down into its socket actually does.
  Small on purpose: the target must not move out from under her finger
  mid-press.

Two sizes: 120 pt for a target in the room, 72 pt for chrome at the edge of the
screen. Two buttons wear it so far, both chrome and both 72 pt: **skip** in sage
at bottom-right, **restart** in rose at bottom-left. Same object, same size,
different colour — the family is what makes them read as the same kind of thing,
and the colour is what lets her tell them apart without reading. The developer
panel keeps its plain iOS controls — nothing in there is for Nina, and it is
deliberately not pretty.

The design is verified but **not compiled**, like everything else here.
`references/buttons/render-facetbutton.py` re-draws `FacetPlate` from the same
constants so the sheet in that folder shows what the code will produce.

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

Three places are the most likely to want a fix, and all three are one line:

1. **`CameraRig.fovIsVertical`.** `init` sets
   `camera.camera.fieldOfViewOrientation = .vertical` so the unprojection maths
   is not a guess. If that property ever fails to resolve, delete the line and
   set the constant to `false` — RealityKit's own default is horizontal, and
   everything else keeps working. If drags feel offset from her finger, this is
   the first thing to check.
2. **`Palette.glowMaterial`.** Uses `emissiveColor` / `emissiveIntensity` on
   `PhysicallyBasedMaterial`, and `waterMaterial` uses
   `.blending = .transparent`. Everything that glows or runs goes through those
   two functions, so if either API has moved they are the only place to fix it.
   The halo uses neither — it is `UnlitMaterial` with transparent blending, the
   same as sparkles and contact shadows. If it looks too strong or too tight on
   device, `Halo.spread`, `Halo.sigma` and the `0.92` in `Halo.profile` are the
   three numbers that shape it.
3. **`FacetButton`'s convenience `init`.** It leans on the synthesised
   memberwise initialiser carrying `@ViewBuilder` across from the stored `label`
   property. If the compiler disagrees, write the designated `init` out by hand
   in the struct body — five assignments, and every call site stays as it is.

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

**Voice is real.** 104 Dutch lines, generated with `text2speech_v2` /
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
