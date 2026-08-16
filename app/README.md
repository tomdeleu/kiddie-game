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

**It does not hand over to the film with a crossfade, and that is the fix for a
flash.** The plate and the film used to be two branches of one `opening` state,
swapped inside a `withAnimation` — so for half a second neither cover was
opaque and what showed through both of them was the lit kitchen, moments before
a film about walking into it. The plate is on a flag of its own now: the film is
inserted *underneath* it with no animation at all, and the plate lifts only when
the film reports its first real frame. Every cover in the opening appears
instantly and leaves with a fade, which is the general rule — **a cover that
fades in is a peep-hole.** If the first frame never comes, the plate lifts
anyway after three seconds, onto the film's own black.

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

**Both lines are hung off the picture, not off a stopwatch.** Shot 2's always
was — it fires on the cut. Shot 1's used to start on a 0.4 s timer taken from
the moment the view was created, which was 0.14 s of margin that then had to
absorb however long `AVQueuePlayer` spent opening the first file *and* the half
second the title plate spent crossfading over it. It routinely did not fit and
the cut to shot 2 chopped Nina off mid-sentence. `IntroMovie.onStarted` now
fires on the player's own clock passing zero — the first frame actually on
screen — and the line gets the shot's full half-second of tail back on any
device.

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
| **klaar** | **Carry the cake up onto the plank** | It rises to shelf height as it nears the wall, shrinks, lands beside the others — and then the round is actually *finished* rather than swapped out |

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

### Two verbs, and the tap finally has a job

**Drag to bake. Tap to find out what a thing is called.**

The game has only ever had two verbs (`GAMEPLAY.md` §3), and until now only one
of them meant anything: a drag was the round, and a tap was a wobble, a sound
effect and — on an ingredient — a repeat of an instruction she already had. So
**every prop in the room now says what it is when she taps it**, in Dutch, in
Nina's voice. Twenty-one lines, in `script-namen.json`: the six ingredients, the
deegroller, the deeg, the kom, the garde, the bakvorm, the bloem, the kraan, the
weegschaal, the mandje, the kist, the potjes, the taartenplank, the deur, the
taart, and the portrait on the wall. Otto is the exception and keeps his own
five, because he is a character and answering for himself is the joke.

Three rules hold it together:

- **Name first, then one short thing about it.** *"Dit is de deegroller.
  Daarmee rol je het deeg lekker plat."* Never longer than two clauses; the
  longest is 4.9 s and most are near 3.
- **One variant each, deliberately** — the one place in the game that breaks the
  never-the-same-line-twice rule. A character who repeats herself does not sound
  like a person, but a *name* is a thing you learn by hearing it the same way
  twice. Repetition is the feature.
- **All at `.low` priority**, which `VoiceBank` drops outright while anyone is
  speaking. A naming line can never talk over the instruction it would be
  explaining, and a burst of taps gets one name rather than a pile-up.

Two targets had to be built around a real one. The **whisk** is switched off
during stirring, because it stands in the middle of the bowl then and
`TouchRouter` picks the nearest centre rather than the biggest target — it would
have won about half of the touches meant to make batter. The **basket** is
switched off until its ingredient has gone, because the token sits 12 mm above
it and from a fixed camera that is the same point on screen. The **dough** has a
target whose *drags* are forwarded to the rolling pin: it sits 44 mm from the
pin's home, so a target of its own would sometimes swallow the grab that starts
the round's first step, and forwarding means a grab near the dough picks up the
pin — which is what she meant — while a tap on the dough gets to be a tap on the
dough.

### Nobody gets talked over

**A step never opens its mouth while the last line is still going.** `say` at
normal priority interrupts, which is right for a reaction to something happening
*this instant* and was wrong everywhere it was used for the line that opens the
next step: drop the last ingredient in, and 1.1 seconds later stirring began and
said so, straight through the four-second line about the ingredient. Playing
fast cost her the words.

`VoiceBank.sayWhenQuiet` holds the line until Nina stops — including through the
quarter-second gaps *inside* a chain, which a naive `isSpeaking` check reads as
finished. Every step transition goes through it.

**Only one line can ever be waiting, and a newer one replaces it.** That is the
whole reason it is not a queue: three quick drops would otherwise earn a
twelve-second monologue about things that had already happened, which is worse
than the interruption it fixed. What she gets is the line playing now, and then
the most recent thing that is still true. Nothing blocks on any of it — the step
has already changed and the halo has already moved — so the worst case is a
dropped line rather than a stalled game.

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
about 235 × 170 mm between the table and the counter, and it grew when the table
did, which is the derivation working rather than a regression. This replaced a rule where a missed drop floated home and
Nina apologised for it, which was wrong twice: it undid the one thing she can
do with a kitchen full of objects, and it treated every stray drag as a failed
attempt when most of them are a 4-year-old moving a rolling pin because it is
a rolling pin.

### The batter takes the colour

Dropping a toverbosbes in makes the batter **blue** — not slightly-blue cream.

It used to go 35% of the way from cream towards the ingredient's colour when it
landed, with the rest bought by stirring, and the result was an in-between hue
that was neither the thing she picked nor the thing that was there. Half the
time it read as nothing having happened at all. It now goes 82% of the way
immediately, bleeds from the old colour over a third of a second so the change
is something she watches rather than something she can miss by blinking, and
reaches the colour exactly by the end of the stir — the remaining 18% is what
stirring is still visibly for.

The value it goes to is a third one, `CakeColour.batter`, alongside `base` and
`deep`. A cake tier is seen against a room; batter is seen against the inside of
a cream bowl from across the table by someone who is four, and the two existing
values are each wrong for that in one case — yellow's `deep` is `sandyWood`,
which beside cream reads browner rather than yellower, and `base` for pink and
blue is a step or two off the cream it is replacing. So `roze` → `blushPinkDeep`,
`blauw` → `berryBlueDeep`, `geel` → `honeyAmber`, `groen` → `sageDeep`.

White is the honest exception — `wolkenroom` makes a white cake, so its batter
brightens rather than changes hue — and `sterrensuiker` changes nothing at all,
which is the point of it (`GAMEPLAY.md` §5: "no colours" is a real outcome).

### Ending the room

**Three cakes finish the kitchen, and then she taps the door to leave.**

The room had no end. It looped: bake a cake, put it on the plank, bake another,
forever, and the only thing that ever changed was which four cakes were on the
shelf. Three gives the loop a shape — long enough that the third one is an
achievement, short enough to be one sitting at roughly eleven minutes a round,
and one below `cakeShelfCapacity` so finishing never depends on the plank having
dropped an older cake off its own end.

**It is a floor, not a quota.** A fresh round still starts after the third cake,
the dough is still on the table, the halo is still on the rolling pin. Nothing
is forced and nothing is taken away; three cakes simply *open the door*.

When the room is finished, three things happen to the door at once, and they are
three ways of saying the same sentence to somebody who cannot read:

- **the leaf comes off the latch** and rests ajar at 11° — the smallest angle
  that still shows a slice of the light behind it at this camera. The point is
  not to open the door, it is to say the door is *openable*.
- **the light behind it turns on**, emissive, so that slice is worth seeing.
  Unlit it read as the inside of a cupboard.
- **a ring lands on the floor at the threshold** — the same cue as every other
  instruction in the game, on a marker 46 mm out from the wall so a 43 mm ring
  is not half buried in the plaster.

This is **the second time the game lights two things at once**, and the reason is
different from the first. The cake-to-plank halo was a journey with two ends;
this is a room with genuinely **two right answers** — carry on baking, or go
through the door — and a cue that named only one of them would be a lie.

Nina's closing line splits to match. After cakes one and two it is *"zullen we er
nog eentje maken?"*; after the third it becomes *"drie taarten op de plank, de
keuken is klaar — tik maar op de deur"*, and the new round that starts behind it
**says nothing at all**, because following that with "let's mix everything in the
bowl" would be the room arguing with itself. Coming back later to a finished
kitchen is greeted the same way.

**Tapping the door is the ending**, and for now it is a ceremony rather than a
transition, because there is nowhere yet to transition to: the leaf swings wide
and holds, light spills across the threshold, and Nina says — carefully — that
this is where they will carry on. *"Die komt gauw, hoor"* rather than a promise
of a room this build cannot open, because a 4-year-old told she is going
somewhere and then not taken there has been lied to. `KitchenRoom.endRoom` is
**the one function the decorating room replaces**, and the swing is already the
first half of that transition.

Nothing is consumed by it. The plank keeps her cakes, the leaf falls back to
*ajar* rather than shut so the room stays finished and stays finishable, and she
can tap it as often as she likes.

One thing had to be fixed to make the door tappable at all: targets are spheres
centred on an entity's origin, and the doorway's origin is on the **floor**, so
the 54 mm sphere covered the bottom of the door and nothing else. The middle of
the leaf sat 50 mm off that centre and the top of it 100 mm — the top half of the
door has never been tappable. Survivable while it was a toy; not survivable now
that it is how the room ends, and a 4-year-old aims at the middle of a door. The
target now hangs on a marker at the leaf's mid-height.

### Ending a round

**The end of a round used to last three quarters of a second.** The cake landed
on the plank, the room was torn down and rebuilt from the same completion
handler, and eleven minutes of work was swapped out while Nina was still on the
first syllable of saying well done. It read as the game throwing her cake away
rather than putting it up.

It is now the one moment in the round allowed to take its time. The cake climbs
and shrinks onto the plank, Nina says three things — **what they made, that it
is up there with the others, and what happens next** — the plank throws sparkles
between them and she hops in the middle, and **only when Nina has stopped
talking does the room reset**. The rebuild waits on `VoiceBank.whenQuiet` rather
than on a duration, so re-recording a line cannot put the two out of step.

The order is deliberate: she is looking at the cake, so the cake is first; the
plank is what she just did, so it is second; and *"zullen we er nog eentje
maken?"* is last, because it is the only one of the three that is about a
kitchen she has not got to yet.

**Three misses and the instruction comes back.** A miss now means something
narrow — she dragged the prop the current step is about and it did not land —
so it is a real signal rather than noise. Twice, Nina says something kind.
The third time she says the step's own line again, at full priority, and the
lit prop gives a squash while she does. She cannot read a reminder, so this is
the only way one can reach her.

### The size of the room

The room box is **0.46 m across, not the 0.40 m `POC.md` specified**, and the
camera sits 8% further back to suit. Both numbers moved for one reason: the
0.40 m room had run out of floor.

What that looked like. Seven props shared a 0.210 × 0.115 m table top, and
their centres all fell inside a 0.154 × 0.076 m patch of it — the bowl and the
whisk 1 mm apart, the tin and the cake spot 2 mm. The three toys on the back
counter sat at 50 mm centres with 32 mm touch spheres, so **both** neighbouring
pairs overlapped and which one a tap got was settled by the nearest-wins
tie-break rather than by where she put her finger. The table's right edge and
Otto's dome were 33 mm apart. Everything was reachable; nothing had any air
around it.

So the walls went out 15%, and the room spent almost all of it on separation
rather than on new props:

| | Before | After |
|---|---|---|
| Room box | 0.40 m | 0.46 m |
| Table | 0.210 × 0.115 | 0.280 × 0.140 |
| Otto | x = 0.115 | x = 0.152, and 12 mm further back |
| Closest two props on the table | 1 mm | 12 mm |
| Counter toys | 50 mm centres | 70 mm centres |

Otto moving right is what buys the longer table, and he is now as far right as
he goes — his dome reaches x = 0.214 against a floor edge at 0.230. Moving him
back as well takes his footprint out of the table's depth completely, so the
two no longer share any Z at all.

The table's seven props are now in three clusters, left to right, and they are
the round's three jobs: **roll** (dough and pin, basket above them), **mix**
(whisk and bowl), **bake** (tin, and the cake it comes back as, on Otto's
side). Reading the table left to right is reading the recipe.

**The camera had to move, and that cost something.** At the old eye the 0.40 m
box already filled the frame corner to corner — the slab's tips sat at ±0.97 of
half the screen width on a 4:3 iPad — so a wider room simply ran off the sides.
Pulling back 1.08× puts the bigger slab's tips roughly where the smaller one's
were. That is deliberately *less* than the room's 15% growth: matching it would
have shrunk every prop by 15% on screen, and the props are what has to stay
thumb-sized. The residue is that the two wall-tops and the slab tips crop a few
percent more than before, and only on the one 4:3 iPad still in the line-up —
on a 1.43 screen everything is inside the frame.

**Every touch radius was multiplied by that same 1.08**, in `registerTargets`
and `registerToyTargets`, along with `snapRadius` and `plankSnapRadius`. Those
are world-space spheres satisfying a rule about the screen (`CONCEPT.md` §5's
~120 pt targets), so a camera that steps back shrinks all of them for free.
Scaling them back is what keeps the bigger room from being a silent regression
against the age rules: nothing on screen is harder to hit than it was. **If the
camera moves again, they move with it.**

This is the one thing here worth checking with Nina before another room is
built on the same numbers — see `POC.md`, whose snap-radius and target-size
criteria are exactly what this trades against.

### Where things are

The five ingredients live in **five different places**: the upper wall shelf,
the lower wall shelf, a pot on the back counter, the basket on the table, and
a crate on the floor. One basket on one table made the room a work surface;
five places make her look up, along, and down.

**The two shelves are mirrored, because five places were only ever four.** Both
planks were laid out the same way, which put both ingredients at z = 0.044 and
45 mm apart in y — one directly on top of the other. From a camera that never
moves, that is indistinguishable from one place holding two things. The lower
shelf is now built end-for-end reversed: its ingredient stands at the far end and
its three jars fill the near half, so the two are **148 mm apart along the wall**,
one at each end. It costs nothing — same plank, same three jars, read backwards.

**The crate moved out into the near-right foreground.** At (0.132, 0.058) it was
tucked into the corner where the table's right edge and Otto's footprint nearly
meet, with 24 mm of floor around it — no clear ground, which is what makes a
thing read as shoved under the furniture rather than standing on it. At
(0.150, 0.126) it has 42 mm to the table's nearest corner and 190 mm to Otto's
dome, and it becomes the right-hand half of a pair: the flour sack on the
near-left floor, the crate on the near-right, bracketing the open foreground
instead of both crowding the middle.

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
`references/cues/floor/`, with the interior left clear. The object keeps its own
colour entirely. Softness is the whole reason this version survives where the
first ring did not — a hard edge is what UI has and light does not.

**And it is bright yellow, which took a fourth go.** The colour was sampled
straight off the plate — a `#F6D861` gold washing out to `#FFF6D8` at the core —
and that failed for the same reason the emissive version before it did: *the
core was where the ring was brightest, and the core was almost white*. In a room
whose floor, walls, counter and half the props are cream, a near-white band on a
cream surface is a smudge, and it read as a faint yellow-ish nothing. It now
runs from an amber `#F0AE12` in the shoulders *up* to a saturated `#FFE01F` at
the core rather than *down* to white, the peak band is fully opaque, and the
falloff is slightly fatter so more of the ring sits near that peak. Yellow is the
one hue nothing in the kitchen is painted — the same argument that made the
sparkles yellow — so the ring is the only thing on screen that colour.

The lesson, on the fourth attempt, is narrower than "judge it on the device":
the plate was right about the *shape* of the falloff and wrong about the
*value*, because it was rendered on a grey studio backdrop and the value is the
half that has to survive the room it is standing on.

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

**The prop stays under her fingertip, and getting there took two goes.**

The first version re-projected the drag onto a plane at the prop's *current*
height every frame. That is a feedback loop — the height depends on the XZ and
the XZ depends on the plane — and at this camera moving the plane by Δ slides
the intersection about 1.63Δ along the view direction, which can move the prop
straight back out of the region that raised it. It made the cake impossible to
put on the plank: reaching the plank zone lifted it 67 mm, which slid the mapped
point out of the zone, so it dropped to the counter, which slid it back in, and
it juddered between the two.

The second froze the plane at pick-up. That killed the oscillation and left the
prop **sliding up or down the screen away from her finger** as it changed
surface — 68 mm of world height between the table and the floor, which throws
the prop most of a thumb's width off her fingertip. The note that used to sit
here argued that reads better. On the device it does not: it reads as the thing
she is holding jumping somewhere else.

What fixes it for good is deciding the surface from **the ray alone**.
`Layout.surfacePointedAt` asks which surface the line from her eye through her
fingertip lands on first — a pure function of the touch, which never looks at
the prop. With the height unable to feed back into that choice, the prop's XZ
can safely be read off the same ray at whatever height it has eased to, so it is
pinned under her fingertip the whole way down and cannot flip between two
surfaces. Nothing in the chain points backwards.

It is a better rule as well as a stabler one. Pointing at the table means the
table; pointing at the floor in front of it means the floor. And **it makes
losing a prop behind the table impossible by construction**: a floor point is
hidden exactly when the sightline to it crosses the table top inside the table's
footprint, and that sightline *is* this ray — so any route to the hidden strip
is a ray that hit the table first and got the table. `isOutOfSight` and the
float-home in `settle` stay as the safety net for the small constant grab offset
a carried prop keeps off the ray, and should now essentially never fire.

The camera never moving is what makes this cheap: any world point plus the eye
is a complete description of the ray through it, so a touch reported on one
plane can be re-read on any other with no extra plumbing from the gesture.
`tracksEntity` still picks the starting plane up from wherever the prop was left.

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

**Otto's eyes stopped getting stuck shut.** Every tap on him blinks him, and the
blink squeezed an eyeball down its Y axis and restored it to whatever
`eye.scale` happened to be when *that* blink started. He is the most tapped prop
in the room, so a second tap mid-blink took the squeezed scale as the new rest
pose and handed it back flattened; the third flattened that. Half a dozen pokes
and his eyes were slits that never opened again. It is exactly the compounding
`Ticker.Pose` was written to stop for `squash`, and the eyes go through `tween`
directly — so `Oven.eyeRest` is their own copy of the rule, and a new blink
cancels the running one rather than fighting it frame by frame.

**And tapping him during a bake no longer starts another one.** `state.step`
stays `.bakken` for the whole four seconds he performs, so five taps used to
mean five overlapping breathe jobs, five puff schedules and five cakes arriving
on top of each other. He still answers every tap while he bakes; he chats
instead of starting again.

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

**The room is 0.46 m across and the camera moved with it.** `POC.md` asks for a
box "around 0.4 m" and signed off a framing; this is that box grown 15% and that
eye pulled back 8%, because at 0.40 m the props had no space between them. The
full argument, the before-and-after numbers and what the camera move cost are
under [The size of the room](#the-size-of-the-room). It is the deviation most
worth testing with Nina, because what it trades against is target size.

**The door moved 32 mm towards the camera, because it could not open.** At
z = 0.140 its opening ran from z = 0.103 to 0.177 and the table's near edge is at
0.122, so the two overlapped by 19 mm — and the leaf swings *into* the room off
its near jamb, which put its outer half straight through the table top.

The fix is z, not x, and it is bounded on both sides. The whole left wall is
spoken for: the counter takes z ∈ [−0.213, −0.151], the two ingredient shelves
take [−0.120, 0.060], the table takes [−0.018, 0.122]. The only clear run is the
near-left corner and the door is 94 mm wide across its frame. Working the swing
out gives the window — the leaf's worst reach over the table's x-range is 71.8 mm
back from the hinge, and that happens at **14°, not at full open**, because a
nearly-shut door is longer in z than an open one — so the centre has to clear
z = 0.157, and the frame's outer edge has to stay on the floor, which caps it at
0.183. **0.172 sits in the middle**: 15 mm of daylight between the swept leaf and
the table, 11 mm between the frame and the floor's near edge.

**The table did not have to move, and did not.** It is the surface seven props
are laid out on and every one of those positions is absolute, so moving it is
seven more edits and seven more chances to put something over an edge.

**The doorway does not lead anywhere yet — but it does now end the room.**
`GAMEPLAY.md` §7 says the door always works, even mid-task. Here it cannot go
anywhere: the decorating room does not exist. So it has two answers instead.
Before three cakes it is a toy — it opens, shows the light, swings shut, and Nina
says what it is. After three cakes it is the way out, and tapping it plays the
room's ending. **When the decorating room lands, `endRoom()` is the one function
to change**, and the swing is already the first half of that transition. See
[Ending the room](#ending-the-room).

**It is a door now, and it used to be an arch.** A pink arched ring lying flat
on the wall, with a butter-yellow plug filling it that no code ever lit — and
the plug sat 4 mm *behind* the ring, into the wall, so the opening read as
plain wall and the whole thing read as a pink outline painted on. Owner's call
on the 2026-08-15 build: "that doesn't look like a door at all."

It is now modelled from `references/props/door.png`: a rose frame of two jambs
and a lintel, a sandy-wood leaf on a hinge, two raised blush panels and one
round butter-yellow knob — seven boxes and a prism, counting the butter-yellow
plate behind it that is the next room's light. Three things about it are
decisions rather than measurements:

- **The leaf is wood, not the cream the plate came back with.** The left wall
  is `Palette.cream`. A cream leaf in a rose frame reads as a picture frame
  hung on the wall rather than a hole through it — a problem the plate never
  had to solve, having been rendered on a grey backdrop.
- **The hinge is on the near side**, so the leaf swings its face round towards
  the camera. Hinged on the back-wall side it turns edge-on at this camera and
  reads as a stick standing in a hole. One fixed camera (`CONCEPT.md` §9.4)
  means this has a right answer, not a preference.
- **It opens 35°, not wide.** The key light comes over the camera's right
  shoulder, so past about 45° the leaf's own face turns out of it and the door
  goes dark as it opens, which reads as a hole rather than a door. Ajar also
  keeps the frame legible.

The swing replaced a `ticker.squash` on the whole arch — the generic prop
reaction, applied to the one prop in the room that has a hinge. A door bending
is a door made of rubber.

None of that has been compiled either, but it has been checked: the geometry
was rebuilt in a throwaway z-buffered renderer at this room's exact camera
(`CameraRig.eye`, 26° vertical) and key light (42°/135°), which is how the
first hinge side and the first swing sign — the leaf turned into the wall —
were caught.

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

**And a lilac.** The photograph the portrait is built from has the girl in a
lilac t-shirt covered in deeper purple daisies, and purple is the second hue the
locked thirteen do not contain — the plates had no more purple in frame than they
had blue. `Palette.lilac` and `lilacDeep` are built the same way `berryBlue` was,
and it is worth saying again because it is the rule rather than the exception:
**not sampled off a screen, derived to the register.** Same desaturation and the
same lightness as `mint` and `berryBlue`, so the shirt sits beside the mint jars
rather than shouting over them. Two surfaces in the game, both inside the frame.

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

### The portrait

**There is a picture of Nina on the back wall above Otto**, framed in rose, from
a photograph the owner supplied: a small girl grinning, brown hair swept back
into a knot with a loose strand at the front, in a lilac t-shirt printed with
purple daisies that have yellow smiling centres. Tapping it sparkles and she
says who it is. It fills the one large blank surface left in the room — the back
wall's right-hand half, which read as blank.

**It is modelled, not textured, and that is not a shortcut.** Dropping the photo
onto a plane would have been three lines. It would also have put a rendered,
smoothly-shaded, occlusion-heavy image inside a room whose entire argument is
flat facets and no ambient occlusion — which is precisely what
`references/ingredients/flour-cloud.png` produced, where the one photographic
thing in the kitchen was the only thing that looked like it came from somewhere
else, and the owner called it on sight. A reference plate is a brief. This is the
brief carried out in the room's own vocabulary: eighteen boxes, three stars and
three icospheres.

The frame is a shallow shadow-box 12 mm deep — the same depth the door frame
stands proud of the left wall, and for the same reason: at this camera a casing
with no visible side reads as paint. Everything inside it is staged at its own
depth, climbing from the mount at 0.0015 to the eyes at 0.0118, because two
surfaces at the same z flicker against each other and at this size that would
look like the picture was broken rather than like a picture. The face ends up
about 2 mm proud of the rails, which is deliberate: a portrait perfectly flush
with its own frame is a decal, and in a room whose whole subject is faceted
relief it should catch the key light like everything else.

## The plank instead of the wall

`GAMEPLAY.md` §2 says the wall of twelve frames is the game. It lives in the
bakery, which does not exist yet, so the kitchen has **de taartenplank** on the
back wall holding her last four cakes. It does the same job in miniature: it
means the second cake is not the first cake again. It is a stand-in and should
be retired when the wall arrives, not grown.

**It did get longer, though — 0.190 m, up from 0.150** — because putting the
cake on it is the round's last action and the hardest one, performed at arm's
length against the back wall. Length buys two things: the four cake slots go from
37.5 mm to 47.5 mm, so the shrunk 32 mm cakes stand apart instead of shoulder to
shoulder; and the **landing zone gets 40 mm wider**, because `nearPlank` measures
half the plank plus the snap radius. It grew leftwards — the right end stays near
x = 0 because past that it starts crossing Otto's chimney.

## What is in it

| File | What |
|---|---|
| `Engine/CameraRig.swift` | The fixed camera, and screen ↔ world. Every drag in the room is a ray and a plane. |
| `Engine/Ticker.swift` | The one clock. Every animation is an interruptible closure ticked from here. |
| `Engine/TouchRouter.swift` | One finger, two verbs. Targets are generous spheres, not meshes, and each carries the plane its prop is standing on. |
| `Engine/Sparkles.swift` | Faceted yellow stars that fly out and vanish. The whole reward vocabulary. |
| `Engine/Halo.swift` | The bright-yellow ring of light on the surface under the prop a step is about — the game's only instruction. |
| `Intro/LoadingScreen.swift` | The title plate, and the floor it is held for. |
| `Intro/IntroMovie.swift` | The opening film: a queue of shots, and two ways out of it. |
| `Audio/SoundKit.swift` | All thirteen sound effects, synthesised at launch. |
| `Audio/VoiceBank.swift` | Nina and Otto, driven by `script-keuken.json` and `script-namen.json`. Also `sayWhenQuiet` and `whenQuiet`, which are why nobody gets talked over. |
| `Game/CakeSpec.swift` | Six ingredients → colour, effects, and what Nina says about them. |
| `Game/RoundState.swift` | The round, and the JSON it is saved to. |
| `Kitchen/KitchenProps.swift` | Otto, the bowl, the batter, the tin, the cake, the six ingredients, the toys, the door, the portrait. |
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

Four places are the most likely to want a fix, and all four are one line:

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
4. **`Entity.excludeFromShadowCasting()`** in `LightingRig.swift`. Uses iOS 18's
   `DynamicLightShadowComponent(castsShadow:)` to keep the room shell and the
   doorway out of the shadow map. If the initialiser has moved, that one
   function is the only place to fix it — and if it has to come out entirely,
   the room works, just with the wall-on-wall bands back.

### The developer panel

**Triple-tap the top-right corner.** Hidden on purpose: `CONCEPT.md` §5 asks for
a parent gate she will not find, and a visible gear is a thing she will press.

It shows the step, what is in the bowl, the stir percentage, and **which voice
line just played** — during a session with Nina that is the difference between
"she ignored it" and "she never heard it". Plus a new round, a mute, and the
whole POC lighting panel underneath.

## Approved lighting

**Settled on iPad, 2026-08-15; revised twice the same day**, both times from
on-device screenshots on the owner's call.

**Round one:** the cast shadows read as hard dark bands — the back wall raking
across the left wall, the door printing itself onto the plaster. The
cause was structural: everything a shadow fell on dropped to the fill's ~30%
of lit brightness, and the room shell was casting onto itself. Fix: rebalance
the energy (key 2200 → 1400 lx, fill 900 → 700 lx, new 1200 lx ambient dome)
and stop the shell casting.

**Round two:** softer, but the walls still collected smudges — the table,
counter, shelves and Nina throwing their silhouettes onto the left wall, which
is where a 135° azimuth sends every shadow. Fix: key elevation 42° → 62°, so a
shadow reaches about a third of its caster's height and pools *under* the
furniture instead of climbing the plaster — the occlusion-render read, from
lights alone — and the wall-hugging furniture stopped casting like the shell.

Where that leaves the values:

| | |
|---|---|
| Key | 1400 lx (was 2200), 62° elevation (was 42°), 135° azimuth, 6200 K, shadows **on** |
| Fill | 700 lx (was 900), 7800 K, opposite the key at 18° |
| **Ambient dome** | **new** — 1200 lx across three non-casting directionals, 120° apart at 55° elevation, neutral 6500 K |
| IBL | off — no environment bundled, and it is not missed |
| Contact shadows | on, opacity 0.22 (was 0.18, nudged for the weaker key), scale 1.15 |
| Lightmap | off |
| Static casting | **off** for architecture and wall-huggers — walls, floor, slab, the door, counter, both shelves, cake plank (`Entity.excludeFromShadowCasting()`, iOS 18's `DynamicLightShadowComponent`) |

Shadowed areas sit near 60% of lit brightness instead of 30%, so a cast shadow
reads as a soft tone shift. Loose props, Nina and Otto still cast — short
pools at their feet now, which is the grounding this was always for. In the
panel, zeroing the **Ambient dome** slider and dropping elevation back to 42°
brings the old look back for comparison.

This still answers the POC's main question in the affirmative: **the faceted
direction holds with real-time light only, no baked AO** — the revision doubles
down on it by getting the soft-shadow feel from lights rather than reaching for
a bake.

Changing these is an art-direction decision, not a tweak. Lift any new setup
with **Copy settings** before overwriting.

## Audio

**Voice is real.** 134 Dutch lines, generated with `text2speech_v2` /
`elevenlabs` and bundled as mp3s — the app never calls an API. Nina is Gracie;
Otto is provisionally Barrett, and `audio/auditions/README.md` explains how to
swap him for four credits and no code.

The 30 added on 2026-08-16 — 9 credits — are the 21 naming lines in
`script-namen.json`, the 5 that make the end of a round a moment rather than a
cut, and the 4 that finish the room and open the door. `VoiceBank` loads every bundled `script-*.json` and merges them, so a whole
new layer of speech is a new file and no Swift change; the same is true of the
next room.

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
