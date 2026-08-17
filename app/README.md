# Nina's Toverbakkerij — De Keuken, Versieren, De Tuin en Het Feest

Four rooms now, and between them a whole round: grow it, bake it, decorate it,
eat it at a disco. Gameplay, graphics and Dutch voice, in one RealityKit app that
runs on the iPad.

> **Het Feest is the newest**, landed 2026-08-17. Its section is
> [below](#het-feest--the-party); the short version is that it is a discotheque
> on the owner's call, that the whole room runs on a beat taken from her taps, and
> that its way out is the cake rather than a door. It came from a container, so
> the handover names the risky edits rather than the whole room — see
> [what it owes](#what-it-owes-1).

Most of this file is about **the kitchen**, which is the reference
implementation and the reason everything else is cheap. The decorating room is
[Versieren](#versieren--the-decorating-room) and the garden is
[De Tuin](#de-tuin--the-garden), and both of those sections are deliberately
short: almost all of either room is the kitchen's machinery pointed at a
different verb.

It grew out of the Step 0 proof of concept, whose question — *does the faceted
pastel low-poly direction survive real-time rendering without baked ambient
occlusion?* — is answered and stays answered. [Approved lighting](#approved-lighting)
below is still the record of that.

> **Compiled three times, all on 2026-08-16** — Xcode 26.6, iOS Simulator,
> Debug — after everything up to each point had been written in a Linux
> container with no Swift toolchain. Five errors the first time, all the same
> mistake (`[weak]` on a struct); three the second, all different from each
> other and from the first five; **none the third**, which was the garden's ten
> Blender props and the four call sites that load them, and which is also the
> first build written on a machine that had a compiler on it. See
> [First build](#first-build), which covers all three.
>
> **Everything in this file has now been through a compiler**, including the
> fence, the gate, the potting bench and the reconciliation that merged the
> garden with the decorating room. What has *not* been through anything is the
> iPad: nothing here has been in front of Nina, and `POC.md`'s protocol is still
> the next thing owed.

> **De Keuken is the reference implementation.** What it established that every
> later room inherits — the box and the camera, the step machine, the save
> shape, the halo, the voice contract, targets, carrying, idle, misses, the
> door — is written down once in [`ROOMS.md`](../ROOMS.md). This file stays the
> record of *why the kitchen is the way it is*; that one is the contract. When
> the two disagree, this file is the truth and `ROOMS.md` has drifted.

> **De Tuin is the second room**, and it is the first thing built against that
> contract rather than by writing it. What it cost is [below](#de-tuin--the-garden);
> the short version is that most of it was assembly, and the two things that
> were not — extracting the carry engine and the room switcher — are what the
> next four rooms get for free.

## The rooms

| | | |
|---|---|---|
| **De Tuin** | `GAMEPLAY.md` §6.2 | Plant, water, pick — five ingredients into the basket |
| **De Keuken** | `GAMEPLAY.md` §6.3 | Roll, fill, stir, pour, bake, and carry the cake onto the plank |
| **Versieren** | `GAMEPLAY.md` §6.4 | Turn, pipe, shake, press stickers on, light the candle |
| **Het Feest** | `GAMEPLAY.md` §6.5 | A disco: tap the pads, everyone dances to your beat, tap the cake when you are ready to eat it |

**Switching between them is behind the developer panel**: tap the small grey
wrench in the top-right corner and use the room picker at the top of the strip.
The picker itself is still not on screen until it is asked for, and that is
`CONCEPT.md` §5's parent gate doing the job it was written for — a visible row of
buttons that teleports her out of the room she is playing is the most pressable
thing that could be put on this screen.

**The wrench replaced a triple-tap on an invisible corner** (owner, 2026-08-16).
The gesture cost no pixels and did not work: the hotspot sat *under* the film and
the loading plate in the `ZStack`, so for the whole opening — the one stretch
where a grown-up most wants the room picker — there was nothing there to tap, and
being invisible, no way to tell that from a missed corner. The developer layer is
now the last thing in the stack and the way in is 28 pt of grey glyph you can
see. Small and dull against 72 pt of saturated `FacetButton` for the two controls
that are hers, in the one corner neither of them uses.

**The garden feeds the kitchen, and the kitchen feeds the decorating room.**
Filling the basket and walking out through the gate hands it over as
`RoomExit.keuken`, and the round the kitchen starts next bakes *what she actually
grew* rather than five dealt off a shuffled deck; carrying that cake onto the
plank and walking out through the door hands it on as `RoomExit.versieren`. She
never sees a handover; she sees five familiar things waiting in the kitchen's
five places, and then her own cake on the turntable.

**A room never learns what comes after it.** It says what just happened and hands
back control, which is what keeps `ROOMS.md` §9's door to two functions per room
instead of a routing table.

**One thing was traded away when this replaced `harvest.json`**, and it is worth
knowing: an exit is live and in memory, so a basket picked just before the app is
closed no longer survives to the next launch. Nothing she *grew* is lost —
`tuin.json` still holds the bed and the basket — only the fact that she was on her
way to the kitchen with it. That is the right call only because there is no
bakery hub yet to be interrupted in; reopen it when the hub lands.

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
| 2 | **Inside**, 6.042 s — the camera glides across the kitchen while the spoon turns in the bowl, steam lifts off Otto and the jars wobble | 5.83 s: *"Dit is mijn keuken. Hier bakken we de allerlekkerste tovertaarten. Zullen we samen beginnen?"* |

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

It is bottom-right on purpose: top-right is where the developer panel's wrench
lives.

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
| **roeren** | Stir with a finger | The spoon follows her hand, the batter turns and comes up to colour |
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

Two targets had to be built around a real one. The **spoon** is switched off
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

### Two things that only go wrong under a finger

**Finishing the stir used to fail the pour.** The third turn completes *mid-drag*
— she is still holding the bowl's target when `state.step` becomes `.gieten` —
and the rest of that same gesture then ran down the pouring path. Stirring never
picks the bowl up, so the bowl was still at its home position 70 mm from the tin,
and letting go counted as a failed pour: Nina said "oeps" a second after
congratulating her on the batter, and the miss counter started climbing toward a
reminder she had done nothing to earn. `carried` is the honest test — a drag that
began as a stir never set it, so there is nothing to drop and nothing to fail.

**Carrying something over the bowl used to put it through the side.**
`Layout.surfacePointedAt` knows the room's three flat surfaces, and a bowl
standing on the table is not one of them — so a berry carried over the mixing
bowl rode at table height, 26 mm *below* the bowl's rim. Containers answer for
themselves now, and they have to: unlike the table and the counter they **move**,
so their footprints are a fact about the current state of the room rather than
about its plan. Tallest rim wins, and the carried prop never rides on itself.

It is safe for every drop in the game because **every snap test is XZ-only** —
`dropToken`, `dropBowl` and `dropTin` all measure horizontal distance, so riding
higher cannot make a drop harder to land. It only changes what she sees on the
way there.

### Nobody gets talked over

**A step never opens its mouth while the last line is still going.** `say` at
normal priority interrupts, which is right for a reaction to something happening
*this instant* and was wrong everywhere it was used for the line that opens the
next step: drop the last ingredient in, and 1.1 seconds later stirring began and
said so, straight through the four-second line about the ingredient. Playing
fast cost her the words.

`VoiceBank.sayWhenQuiet` holds the line until Nina stops — including through the
quarter-second gaps *inside* a chain, which a naive `isSpeaking` check reads as
finished. Every step transition waits like this.

**Only one line can ever be waiting, and a newer one replaces it.** That is the
whole reason it is not a queue: three quick drops would otherwise earn a
twelve-second monologue about things that had already happened, which is worse
than the interruption it fixed. What she gets is the line playing now, and then
the most recent thing that is still true. Nothing blocks on any of it — the step
has already changed and the halo has already moved — so the worst case is a
dropped line rather than a stalled game.

#### …and nobody is talked *at*, either

**A chain was the hole in that, and it was a twenty-four second hole**
(owner, 2026-08-16: *"if you happen to immediately put the cake onto the shelf,
the audio keeps on playing long after you finished that"*).

"The line playing now" is one line when Nina is speaking one and **up to four
when a chain is in flight**, and `sayWhenQuiet` only ever replaced the one
*waiting*. The cake coming out of the oven queues Otto, the colour, at most one
effect and *"zet hem op de plank!"* — measured against the real mp3s, **fourteen
seconds** — and the plank becomes reachable on the same frame that chain starts.
Carry the cake straight up, which takes about two seconds, and she heard all
twelve remaining seconds of it, including an instruction to put the cake on the
plank it was already standing on; only then did the twelve seconds about having
put it there begin; and since the rebuild waits on `whenQuiet`, the round did
not start again until roughly **twenty-four seconds after the last thing she
did**.

Two additions, both in `VoiceBank`, and neither ever cuts her off mid-word —
they cut the queue, not the voice:

- **`sayInstead`** — `sayWhenQuiet` plus `dropQueued()`, which throws away the
  rest of an in-flight chain and any held line. **This is now what a step
  transition calls**, in all three rooms; `sayWhenQuiet` is left for a remark
  that is genuinely *additional* (an ingredient named, a sticker praised) and so
  should join rather than replace.
- **`stillTrue`** — an optional premise checked immediately before *every* link
  of a chain, not once at the start. `cakeIsReady` passes `cake != nil`, so the
  out-of-the-oven chain stops wherever it had got to the moment the cake is no
  longer on the table, and the instruction at the end of it can never be said to
  someone who has already obeyed it.

Worst case is now the one sentence already sounding, which is the rule the whole
mechanism exists to protect.

**It was never only the kitchen.** The garden greets her with a three-line chain
and she can have the bed sown before it finishes, and every `endRoom` in the
game queued its handover line behind whatever the room was still saying — with a
room teardown 2.3 s later that stops the voice outright, so the line was not
delayed, it was **lost**. All three rooms now use `sayInstead` at their step
transitions and at their door.

> **Still open, and not fixed here:** that 2.3 s is a fixed timer
> (`endRoom`'s 0.9 s to `onExit`, plus `GameScene.handle`'s 1.4 s) racing a
> variable-length line. `nina.keuken.naarVersieren`'s three variants measure
> 1.75 s, 1.99 s and **3.11 s**, so the longest is still cut mid-word even with
> nothing queued in front of it. The fix is to hand over on the voice rather
> than on a stopwatch, and it changes how rooms cross a doorway — a decision,
> not a patch.

**Sparkles are yellow stars.** They were `creamLight` icospheres, which at
sparkle size is a grey dot — an unlit cream ball two millimetres across against
a room that is mostly cream reads as dust. A star's silhouette survives being
three pixels wide, and warm yellow is the one hue nothing in the room is
painted, so a sparkle is never mistaken for a crumb of the thing it came off.
Callers that pass a colour still get it: an ingredient dropping into the bowl
throws its own colour, which is what says *that* one went in.

**And nothing gets put back** — with one exception. A prop she drags somewhere
that is not a target settles onto whatever is underneath it and stays there.
The rolling pin can live on the floor. The exception is anywhere the camera
cannot see: the camera never moves, so behind each solid thing in the room is a
place she could put something and then genuinely not get it back, with no way to
look round it. Drops there float home.

`KitchenLayout.occluders` lists the three — **the table, the counter and
Otto** — as boxes with a height, and `Surfaces.isOutOfSight` asks whether the
sightline from the eye to the spot the prop is about to *land on* passes through
any of them. It was one flat plate at table height tested only against
floor-level drops, which is why the room shipped with three ways to lose a prop
(owner, 2026-08-16: below the table, behind the oven and below the back counter
you cannot pick it up again). The floor behind Otto was the worst of them and
was in nobody's shadow at all: he is 124 mm of dome standing out in the open to
the right of the table, and swept at 5 mm he alone hides 1024 cells of floor to
the table's 798.

Two things about it are worth keeping:

- **It is derived, never typed in**, so it stays true when the furniture moves —
  the table's patch grew when the table did, which is the derivation working
  rather than a regression.
- **Nina is deliberately not on the list**, though she hides a real 75 × 50 mm
  strip of floor in front of the counter. Adding her also puts a 20 × 15 mm patch
  of *worktop* 13 mm from the sink in her hat's shadow, and every other surface
  in the room keeps what is put on it. She moves, too — a fixed box describes
  furniture and guesses at a person. The sweep that found that also confirmed
  the cost of the three that stayed: every point of both work surfaces, the
  whole near foreground and all thirteen prop home spots come back reachable at
  2.5 mm.

**And the same list says what a carried prop goes _over_.** Fixing the drop
exposed the other half of it the next day (owner, 2026-08-17: the drop floats
back as it should, but dragging into the oven "just clips"). It did: a carried
prop rides on whatever `pointedAt` answers with, that is only ever a *surface*,
and Otto is not one — so a prop dragged across him was carried at the height of
the floor he stands on and went through his dome. `Surfaces.carryOverTop`
returns the tallest occluder top the ray meets, and `CarryController` takes the
higher of that and the surface, so the prop lifts over Otto instead. It cannot
cost a landing: every snap test is XZ-only, so riding higher only changes what
she sees on the way there. Swept over 25,917 drag directions, **a carried prop
is now never inside any of the four boxes**, and never lifted anywhere in the
open foreground.

Two details that are the whole difference between this working and looking
broken:

- **The top of the box, not where the sightline grazes it.** Entry-riding slides
  a prop up Otto's face, which is prettier — and leaves it embedded in the side
  of the table, because a ray that reaches under the table's right overhang
  enters through the *side* face.
- **Otto's chimney is a fourth box.** It makes no difference to what floats home
  — it stands behind the dome, so its shadow lands inside the dome's and the
  swept floor total does not move by one cell. It matters because a prop lifted
  to clear the dome rides at 0.091 and the chimney reaches 0.114.

**The mouth is the exception, and it goes through `pointedExtra`**, which is
asked before the occluders — the tin rides on the mouth floor while Otto is
open, so it slides in at 0.028 against a target of 0.026 instead of sailing over
his head. It and `dropTin` both ask `KitchenLayout.nearOvenMouth`, so what she
sees and what counts cannot drift apart.

### Otto's mouth is a pocket, not a dimple

Owner, 2026-08-17: it should extend back a little more, positioning the tin in
it is difficult. Two things were wrong and only one of them was the depth.

**The depth.** The arch is a ring stuck on the front of an ellipsoid that bulges
into it, so the recess can only be as deep as the gap between the arch's face
and the dome's shell — 14 mm, of which 8 were used. The only way to buy more is
to lengthen the ring forwards, which would push Otto's snout at the table. So
**he moved back by exactly what the mouth gained**: `ovenOrigin.z` −0.112 →
−0.122, `mouthDepth` 0.034 → 0.044. Every visible number stays put — the arch
face at −0.036, `ovenMouth` at −0.038, the front of his occluder box — so none
of the sightline work above needed redoing. What changed is a **23 mm pocket
where there was an 8 mm dimple**, and the tin now lands with its back edge 1 mm
off the dark plug instead of balanced on a lip. The plug still reads dark: it
clears the dome shell by 1.8 mm at the mouth's base and 8.6 mm at the top of the
arch, and the faceted dome chords *inside* the ideal ellipsoid, so the real
clearance is larger than both.

**The pushing.** The drop zone is 81 mm because the drop has to be forgiving —
which meant she could push the tin on through the arch and watch it disappear
inside the dome. `KitchenRoom`'s `carriedClamp` holds it at the lip: only z,
only forwards, so sideways and pulling back out are free. Push harder and it
settles into the pocket instead of vanishing.

**Still tight:** the opening is 48 mm and the tin is 44, which is 2 mm of
daylight each side. Widening it is a change to Otto's *face*, so it is noted in
`mouthArchInner` and left for the owner rather than taken while fixing the
depth.

### A prop is not a point

`clampToPlayArea` bounds the prop's **origin**, and the bounds stop at
z = −0.205 against plaster at −0.218. That is 13 mm of room for a tin 44 mm
across, so pushing it back along the counter buried 9 mm of it in the wall
(owner, 2026-08-17); the rolling pin, 74 mm long, went in by a third of its
length.

It cannot be fixed by pulling the bounds in, and that is worth knowing before
trying: ingredients start on the wall shelf at x = −0.200 and in the counter pot
at z = −0.174, so a bound tight enough for the rolling pin would yank a token
four centimetres sideways the instant she picked it up — the bug
`clampToPlayArea`'s own note is about. So the clearance is **per prop**:
`Surfaces.innerWalls` holds the two walls' inner faces, `CarryController`
measures what it is holding with `visualBounds` once at pick-up, and `place`
keeps that much clear. Measured rather than declared, because a table of prop
radii is a table that goes stale.

Swept: every prop's body now stops exactly on the plaster and never past it, and
no prop's home position moves when she picks it up.

This replaced a rule where a missed drop floated home and
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
- **a ring lands on the floor at the threshold**, centred on the doorframe. It
  was out in the room twice — 46 mm from the wall, then 40 — on the reasoning
  that a ring must not reach into the plaster, and both times it read as *a disc
  of light near a door* rather than as light coming from one. From a camera on
  the +X+Z diagonal it also sits visibly down and to the right of the door it
  belongs to. It is now concentric with the doorway, and **its back half is
  inside the wall on purpose**: the wall is solid from y = 0 up, so the buried
  part is simply occluded, and what shows is a bright crescent hugging the
  threshold. Which is what light through a doorway looks like — the thing that
  was wrong was never the clipping, it was pulling the ring off the door to
  avoid it.

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

**Tapping the door is the ending, and it is a transition now.** The leaf swings
wide, light spills across the threshold, and on the beat it reaches full open
the finished `CakeSpec` goes to the decorating room. Nina says *"nu gaan we hem
versieren!"* — which `ROOMS.md` §9 wrote down as the round-mode line long before
it could be said.

**The old ceremony survives for the case where nothing can be handed over** — a
save from before the decorating room, or a plank cleared by restarting. Then she
hears the careful *"die komt gauw, hoor"* instead, because *never promise a room
that does not exist* does not stop applying once one of them does.

What the door hands over is `state.lastFinished`, not `shelf.last`. They are
nearly the same and differ in a case that will happen: the plank holds four and
drops the oldest off the end, so after a long session the shelf is a window
rather than a history.

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
spoon 1 mm apart, the tin and the cake spot 2 mm. The three toys on the back
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
(spoon and bowl), **bake** (tin, and the cake it comes back as, on Otto's
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

**The shelves are 36 mm deep, not 14.** The plank was narrower than the things
standing on it — a jar is 20 mm across and the honey pot 31 mm with its dipper,
on a 14 mm board whose back edge was already flush with the plaster, so they
overhung the front *and* pushed into the wall. The depth is set by the widest
prop that can stand there rather than by what looks like a shelf in elevation,
and `Layout.shelfX` keeps the back edge on the wall face so it grows forwards.

Two things came out with it. The ingredients had been **hovering 10 mm above the
plank** since the shelves were built — the jars sat at the plank's top and the
ingredients at a hand-typed number that was not it — which is hard to see against
a wall and impossible to miss once you know. And the halo for a shelf ingredient
had been landing **on the floor, 150 mm below the berry it was pointing at**,
because `surfaceY` only knows about the table, the counter and the floor. For two
of the five fetching steps the game's only instruction was pointing at the wrong
place. `Layout.shelfSurfaceY` answers for the shelves, and it is height-gated so
it can only ever match a prop that is actually up there.

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

**And getting it to look like light took four goes.** The colour was sampled
straight off the plate — a `#F6D861` gold washing out to `#FFF6D8` at the core —
and that failed for the same reason the emissive version before it did: *the
core was where the ring was brightest, and the core was almost white*. In a room
whose floor, walls, counter and half the props are cream, a near-white band on a
cream surface is a smudge, and it read as a faint yellow-ish nothing.

The third go made it a saturated amber-to-yellow, and that was **worse** — for a
reason worth writing down because it is counter-intuitive: **saturating a yellow
darkens it.** `#F0AE12` sits at 68% luminance and the kitchen floor is
`blushPink` at 84%, so painting the ring a stronger yellow painted it *darker
than the floor it was lying on*. An unlit transparent material can only ever
blend towards its own colour, so what came out was a dim gold stain — and the
harder it tried, the dimmer it got.

**The fourth is different in kind: the ring emits.** `Palette.lightMaterial` puts
`emissiveIntensity` above 1, which lands the surface *above white* in the HDR
buffer before tonemapping — somewhere no base colour can reach, because a base
colour is by definition a fraction of the light falling on it. That is the whole
difference between a yellow shape and a light, and the first three attempts were
all trying to reach the second using only the tools of the first.

Two things follow. The colours are now **hot and pale** rather than saturated —
`#FFD44A` in the shoulders, `#FFF6C0` at the core, both at or above the floor's
own luminance, so the ring can only ever brighten what it lies on. And the
**emission is scaled by the falloff squared** while opacity is scaled by the
falloff itself, so the band's centre line glows hardest and its edges fade into
the floor rather than stopping at one. If it still reads flat on device, the one
lever is `Halo.emissionPeak`; the geometry and the profile are right.

**Then it had to get smaller, twice.** Emitting, the ring's old proportions read as
heavy: the band was 0.34 of the radius either side — two thirds of the radius
across, 31 mm of glow around a 46 mm ring on the bowl — and the ring itself was
drawn a third wider than the prop it marked. Both numbers were tuned while it was
*dim*, when a faint thing needs area to be found at all. A light does not. The
band is 0.18 now (13 mm on that same bowl) and the ring **0.97** of the prop
rather than 1.35 — under 1, so it passes just *inside* the prop's own footprint
and what shows is a rim of light escaping from under it, rather than a hoop
thrown around it.

**The sparkles took up the slack.** They are the ring's own colour, a third
bigger, three at a time rather than two, and they emit — an unlit star against
the pale floor loses by exactly the arithmetic the ring did. `Sparkles.burst`
grew a `glow` parameter for it, off everywhere else.

The lesson is narrower than "judge it on the device". The plate was right about
the *shape* of the falloff and wrong about the *value*, because it was rendered
on a grey studio backdrop — and a value sampled against grey says nothing about
what it will do against pink. **Read a colour against the surface it will
actually lie on; and if it has to look like a light, make it one.**

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
is a ray that hit the table first and got the table.

**Behind the table, and nothing else** — and the sentence above was read for a
while as though it said props could not be lost, which is how the room shipped
with three places they could be. The argument is exactly as wide as `rects`,
because a *surface* is the only thing this can hand back: Otto is not a surface,
so no ray ever hits Otto and gets Otto. It goes through him and lands on the
floor behind. `isOutOfSight` is not a safety net for the small constant grab
offset a carried prop keeps off the ray — it is the whole answer for everything
in the room that is solid without being standable.

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
filename moved from `luna.*` to `nina.*`. The one thing it left open — the
twelfth gold frame on the wall, which was Luna's — was closed on 2026-08-16:
**it is Nina's own**, and the last cake is the one she makes for her finished
bakery. `GAMEPLAY.md` §1.

### Starting over

A **restart button**, bottom-left, same size and weight as the intro's skip
button and with no text on it either. It puts **the whole kitchen back to the
beginning — plank and all** — and Nina says so out loud.

It used to keep the cakes already on the plank, on the argument that nothing she
has finished should ever be lost. That was right while the plank was only a
trophy shelf, and it stopped being right the moment three cakes on it became the
thing that *finishes the room*: keeping them would make one button mean two
things depending on when it was pressed — on an empty plank, start again; on a
full one, start again but stay finished, with the door still standing open behind
her. **A button that has to be explained is a button a 4-year-old cannot use.**
It now has one meaning, and the room agrees with it: with the shelf empty
`roomComplete` goes false, so the door closes and its halo goes out.

She can press it, and that is fine. If she turns out to press it constantly, the
fix is to move it behind the parent gate — not to add a confirmation, which is
unreadable to her by definition.

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

## De Tuin — the garden

`GAMEPLAY.md` §6.2, built 2026-08-16 against [`ROOMS.md`](../ROOMS.md) rather
than by writing it. Same chair, same floor plan size — the whole game is one
continuous place.

### It has a fence, not walls

**The one place this room breaks the art direction.** It shipped as a room box
with two plaster walls, because `references/REFERENCES.md` §1 gives every room
two walls and a floor. Owner's call on seeing it: *"it's a bit strange that the
garden has a wall around it."* It was — a garden indoors, and the kind of wrong
that only shows once the room is standing.

So the walls came out and a **picket fence** stands where they stood: an L along
the back and left edges, meeting at the far corner, with a **gate** in the left
run. **The rule's purpose survives intact** — the fence is on the two far edges,
the two near sides are still open, and nothing new has entered a sightline. What
changed is only what the boundary is made of.

Three things follow, and two of them came from the plate rather than from a
decision:

- **The grey backdrop shows above it**, and that is right rather than tolerated:
  it is `Palette.backdropGrey`, the same grey every reference plate is shot on,
  so the room now reads as the diorama the plates already look like.
- **The ground went green.** With no walls, the floor is most of the frame.
  `references/garden/roombox-v2.png` — generated to answer only "what does this
  look like without walls" — came back with a pale mint lawn and a cream *path*,
  where the room had a cream floor. It is right: cream ground under a cream
  fence is one colour.
- **The fence casts, where the walls did not.** Architecture was excluded because
  a wall's shadow falls on another wall and reads as a stain. What a fence casts
  onto is the ground, which is the grounding this room's lighting wanted in the
  first place. About forty small casters — worth an eye on device, one line to
  undo.

### The tree was a bush, and the trunk is why

Owner, 2026-08-17: *"the tree at the top corner must be bigger — now it looks
like a bush instead of a tree."* It did. As built it stood **110 mm** against a
70 mm fence and a 125 mm Nina, and its canopy was 70 mm across — no taller than
the bushes beside it were wide, and shorter than the child looking at it. That
is a shrub whatever shape its leaves are.

**The fix is not uniform scale, because what names a tree is the trunk.** The
first pass took the trunk to 98 mm and the tree to 174, and that was still short
— *"the tree needs to still be double the height"*, same day. It stands
**225 mm** now on a **128 mm trunk**: 3.2× the fence, 1.8× Nina, a shade over
the 235 mm walls the other rooms have. **105 mm of bare trunk shows below the
lowest lobe**, which is the silhouette a 4-year-old draws when asked for a tree,
and the canopy is still the wide cluster
`references/garden/garden-tree.png` is emphatic about — 139 mm across.

**225 and not the 348 that doubling asks for**, which is the one deviation in
this change and was the owner's call once the trade was drawn. The camera is
locked game-wide (`ROOMS.md` §0), and above `GardenLayout.treeSpot` the frame
runs out at **238 mm**. At 348 the top 110 mm is off screen — about 60% of the
foliage — leaving a long trunk under a hedge parked on the top edge, which is
not obviously better than the bush it replaced. **Moving the tree does not buy
the headroom back**: pushing it away from the eye raises its base on screen
faster than the extra distance shrinks it, so the far corner is *worse*, and the
useful ceiling is a fact about the fixed camera rather than about where the tree
stands. 225 mm puts the crown at **ndcY ≈ 0.95** — and `fovIsVertical` is true,
so that margin holds on every aspect ratio rather than only on the 4:3 iPad.

**Its neighbours got easier, not harder**, which is worth noting because the
instinct with a bigger prop in a full corner is to brace for a collision. The
canopy went up as well as out: its underside now sits at 105 mm, 15 mm above the
potting bench's backboard and 19 mm above the fence posts, so it passes over
both entirely instead of threading between them. The widest lobe reaches 10 mm
past the room box's back edge and stays over the base slab — a tree leaning out
over a garden fence, which is what `treeSpot` asks for.

**Its tap target rides the canopy.** The naming marker sat at 75 mm, the middle
of the 110 mm tree and now bare trunk; it is at 160 mm, the middle of this one,
and its radius is 50 mm against the 36 every other prop gets — a target a third
of the prop's width inside a prop 139 mm across reads as a dead zone, and
`CONCEPT.md` §5's 120 pt is a floor rather than a ceiling. The bush keeps its
36. Both rivals clear it *as the camera sees them* —
`RoomBox.screenSeparation`, not `distanceXZ`, because the question is whether
she can tell two targets apart: the bush is 169 mm away against 86 mm of
combined radius, and the top-left seed jar, the tighter of the two, is 116 mm
away against 76 mm.

### The gate says it twice, not three times

`ROOMS.md` §9 has the way out saying the same thing three ways: the leaf off the
latch, a ring at the threshold, and **light behind it**. The kitchen's light is a
plate inside the wall opening. A gate in a picket fence has no wall to hold one,
and she can already see straight through it — so the garden's says it twice, on
the owner's call. `Props.Doorway.glow` became optional to say so; a hidden entity
nobody ever assigns to is dead geometry that looks live.

**Nothing stands in for it.** A worn sandy path leading out through the gate did
— one flat cream heptagon on the lawn, emitting nothing, on the argument that
ground somebody has walked on is the one way left to say *there is somewhere to
go*. **Removed on the owner's call, 2026-08-17**, and it is worth recording why
it was ever there: the room-box plate drew a path, and §9's three-cue rule left
a gap, and those two facts together made a prop that nobody looking at the
screen could name. The first question asked about it was "what is this?", which
is the answer. Two cues.

**The gate stands where the door stood**, and `Props.gate` returns the same
`Props.Doorway` struct the door does — so every line of the ajar-swing-ring
behaviour is untouched.

### The jars stand on a potting bench

They hung on two wall shelves. With the walls gone they moved onto a bench:
worktop with a low backboard, four jars on it, four more on a shelf below.

**The lower shelf sticks out in front of the worktop, and that is the whole
design.** This camera looks down at about 34°, so it sees under an overhang by
roughly one and a half times the drop — a jar on a shelf 42 mm below the top,
sitting *under* the top, is cut in half by its own bench.
`references/garden/potting-bench.png` solves it by projecting the shelf forward
so the lower row stands clear of the front edge, and the row is **staggered half
a spacing** as well, so no jar is ever directly under another. It is the
kitchen's mirrored-shelf bug rotated a quarter turn.

The jars became **plant pots** rather than the straight-sided prisms they were —
tapered, with a knobbed lid. Two rooms whose containers differ only in colour
would be one room twice.

### A target's real size is measured on the screen, not on the ground

The thing this change turned up, and it is worth more than the change.

`TouchRouter.hitTest` measures the **perpendicular distance from a target's
centre to the camera ray** — which is screen separation. A row running along X or
Z is tilted about 37° away from the screen, so it keeps only **0.798** of its
spacing. The garden's flowers at 32 mm centres were giving each flower a **55 pt**
band, less than half `CONCEPT.md` §5's ~120 pt, and every "no two touch spheres
overlap" sum in this project up to now had been done in XZ, where it looks fine.

Two corrections came out of it, and one piece of knowledge:

- **The flowers went to 46 mm** — 77 pt, which is what fits in that corner.
- **The butterfly and the bee moved.** A thing 85 mm in the air and 130 mm nearer
  the camera lands on nearly the same screen point as a thing on the ground
  behind it, which is how the butterfly's home came to sit on top of two of the
  bed's five holes. Tapping a ripe plant and getting a butterfly is the required
  action losing to a toy.
- **A row along the X−Z diagonal keeps 1.000 of its spacing**, because that
  direction is exactly screen-horizontal. Free, and worth knowing for the next
  room that needs a long row.

Overlap between **like things in a row** — five holes, eight jars, five flowers —
is intended and stays: `TouchRouter` picks the nearest centre, so each owns an
equal band and an imprecise tap always lands on the nearest one. Overlap between
**unlike** things is the bug, because the wrong kind of answer can win.

**The pond re-ran this check three times and it comes out clean.** Every unlike pair
in the garden was measured again when the two puddles became one pond, and again
when the pond grew across the bottom and pushed three props: the only pairs still
short are `plot2`/`greenery1` (6.6 mm) and `plot3`/`greenery1` (4.2 mm), which
are the bed's holes against the bush behind them and predate all of it. The
toy-to-toy shortfall that used to be here — a puddle 3 mm inside the butterfly —
went out with the puddle. The pond's own worst neighbour is the basket at 113 mm
against the 83 the two radii need.

**Its target is 45 mm, which is far smaller than the prop**, and it hangs on a
marker rather than on the pond itself: a 249 mm pond with a target to match would
swallow the basket and the flower row's near end, and the pond's own origin sits
out under the clipped corner where nobody aims. Same trick as the gate's
`GateTouchSpot`. A target only has to be big enough to hit; what she aims at is
the middle of the water she can see.

The check is one script rather than a habit: it is worth re-running whenever a
prop moves, because every one of these numbers was chosen to *just* fit.

**The measurement is now `RoomBox.screenSeparation(_:_:)`**, so the next room
does not have to rederive it. `RoomBox.distanceXZ` stays where it is and stays
right for snapping — a drop is a question about where a prop lands, not about
what she is pointing at.

**And Versieren does not pass it.** `VersierLayout.assertSpacing` was written
against `distanceXZ`, and the decorating room's seven sticker trays run along the
two ledges at a 64 mm pitch for a 32 mm radius — exactly touching in XZ, and
**47–51 mm apart as the camera sees them**. The two tools and the stool are the
same story, eight overlapping pairs in all. That check now runs a second pass in
perpendicular distance and **prints rather than asserts**: the room is built and
compiled and on device, the fix is either an 85 mm pitch or a 24 mm radius (60 pt,
under `CONCEPT.md` §5's floor), and picking between those is a look decision for
someone who can see the screen — not something a spacing check should take by
crashing every debug launch. It is on the list for the afternoon with Nina: the
trays all answer with a sticker of some kind, so the failure is *the wrong
sticker*, not a dead tap.

### Two naming lines had nothing to play them

Found by tightening the script↔Swift check so that a constant's own declaration
no longer counts as a reference to it. Three real gaps:

- **The five toys said their play-chatter and never their name**, which breaks
  `GAMEPLAY.md` §3 outright — *every prop in every room says what it is when
  tapped*. `sayToy` fixes it with the flour sack's own rule: mostly the name, one
  time in three the joke.
- **A seed she put down on the grass answered nothing at all.** It is created
  mid-drag, so it never went through `registerTargets` — a dead prop, which
  `GAMEPLAY.md` §7 says reads as a broken iPad. Strays now answer a tap and can
  be picked up again.
- **The bench and the bed have no naming target and cannot have one**: both are
  large props entirely covered by smaller ones, and nearest-wins means a marker
  on either loses every tap it is offered. Their words fold into what stands on
  them — an empty hole says *zaaibak* one time in three, a jar says *werkbank*
  one time in four.

One line in the kitchen still has nothing to play it, `nina.keuken.pakGlimmend`
— a generic "take the glowing one" that predates all of this and was never wired
up. Left alone.

| Step | She does | It answers with |
|---|---|---|
| `zaaien` | Drags a seed from one of **eight jars** into one of **five holes** | A plop, sparkles in the seed's colour, a mound of turned earth, and Nina saying it is in the ground |
| `gieten` | Sweeps the watering can across the bed | The can tips, water runs from its rose, and **every plant it passes over grows one stage** |
| `plukken` | Taps a ripe plant | The fruit flies into the basket while the plant folds back into the earth, and Nina names the colour it will give the cake |
| `klaar` | — | The basket is full, the door is ajar and lit, and the harvest is written for the kitchen |

**The step is derived from the bed, not stored independently of it.** Any hole
empty and the basket short → sow; anything planted and unripe → water; anything
ripe → pick; basket full → done. It is saved so the room can be entered at any
step cold, and recomputed after every action so it can never disagree with what
is actually growing. Nothing is gated by it: she can water a half-sown bed, pick
before the bed is full, and leave whenever she likes. It only decides what glows
and what Nina says next.

The one clause in it that is easy to get wrong: *stop asking her to sow once the
basket plus what is in the ground can reach five*. Without it, harvesting the
fourth plant empties a hole and the room turns round and asks for a sixth seed.

### The halo never lights a seed jar

This is the room's one interesting cue decision, and it looks like a mistake
until it does not.

Sowing looks like a **journey** — pick a seed up, put it in a hole — and a
journey is one of `ROOMS.md` §3's two sanctioned reasons to light two things at
once. It is not one, because the two ends are not the same kind of thing. The
destination is a fact: *that hole is empty*. The source is **her choice between
eight equally right answers**. Lighting one jar says that jar is the one, which
is false; lighting all eight is not an instruction.

So the bed carries the whole cue, Nina says where the seeds are, and the **idle
shimmer** picks a jar if she stands still. Which is exactly the split
`GAMEPLAY.md` §6.2 already describes for the wish hint — *"this is
`Ticker.shimmer`, the idle cue, not the halo"* — so when the friends arrive and
a colour wish wants the matching jar to shimmer, the mechanism is already there
and it is one line.

### A pass of the can, and why it needs two radii

`GAMEPLAY.md` §6.2: one sweep across the bed advances every plant under it,
three sweeps and the bed is ripe. The rule is unchanged from a single plant — a
pass grows a plant a stage — it is only that a pass can cross five of them, which
is the whole reason the five holes are a **row along X** rather than a block. A
row is one left-to-right sweep, and a block would ask her to trace a shape.

A hole is marked watered when the can's rose comes within 30 mm and unmarked only
once it has left 46 mm. **The gap between the two is what makes it a pass.** With
one radius, a hand holding still over one plant would pump it to ripe, and a
4-year-old's finger jittering across the boundary would do the same thing more
slowly. It is the rolling pin's rule (`KitchenRoom.roll`) with two thresholds
instead of a travel count.

**It is measured from the rose, not from the can.** They are 45 mm apart, which
is more than the 42 mm between one hole and the next — watering from where the
handle is would water the wrong plant.

### Picking is a tap, and that is the one exception

Everywhere else in the game, **drag to play, tap to learn the word**. Here a
tap on a *ripe* plant picks it, which is `GAMEPLAY.md` §6.2's own instruction:
"tap the ripe plant and it hops into the basket."

The split is stated rather than hidden: **a ripe plant's tap picks it; an unripe
one, or an empty hole, says what it is.** It survives because five taps is a
cheap middle of a round and the room already has eight drags in it — and because
what she hears on picking is `nina.ingredient.*`, the kitchen's own line naming
the colour that ingredient will give the cake. That is exactly what she wants to
know at the moment she picks it, and it means the word she learns in the garden
is the word she hears in the kitchen.

The fruit flies and the plant does not. She picked a strawberry, not a
strawberry plant.

### The toys

Six, none of which gate anything:

- **Five flowers that chime in a scale**, low to high, left to right. It is one
  `SoundKit.ding` at five rates — a **major pentatonic** run, so there is no
  semitone in it and no order she can tap them in that sounds like a mistake.
  Their heights step up down the row, so the scale is visible before it is
  audible. A whole musical toy for one array, and a quiet rehearsal for the
  party's six instrument pads.
- **Mo the mole**, who pops out of his hill fast, looks about, and goes back down
  slowly.
- **A butterfly that follows her finger** — the one thing in the game that
  answers a touch which was not aimed at it. It needed `TouchRouter.onMoved`,
  because a target big enough to catch every drag would eat every other drag in
  the room. It follows *slowly*: a butterfly that arrives is a cursor.
- **A bee** that hums when chased.
- **A pond** that splashes — an irregular pool **filling the near corner of the
  lawn and running off both of its near edges**, 249 mm across the screen and
  151 mm deep, with faceted stones along its inland bank only. It replaced two
  puddles on the owner's call, 2026-08-16, and was rebuilt **twice more the same
  day**, each time from a red line drawn over a screenshot of the running room:
  first *"the pond must be bigger and totally at the bottom"*, then *"it must
  stretch to the side of the plateau at the bottom left right, and the shape must
  be irregular"*.

  **A screenshot is a better brief than a plate, and that is the lesson worth
  keeping.** Both reference plates were right about what a pond *is* — the ring
  of separate boulders, the water stepping down in bands — and neither could
  have said how big it should be or where it should stop, because a plate is
  shot with nothing beside it. Even the room-box plate is a drawing of the room
  rather than the room. Scale is a question only the running game can answer, so
  ask for it in a screenshot and expect two corrections.

  **It is cut by the plateau, deliberately.** The water runs to the mint's edge
  and stops half a millimetre inside it, with the slab's cream border beyond:
  155 mm of the right-hand edge and 191 mm of the left-hand one are pond, and
  the lawn's own corner is under water. Every other prop in the game stands
  inside the box; this is the one the box slices. The clip is **radial** — each
  outline vertex is pulled back along its own ray until it lands on the limit —
  which is what makes the cut come out as one straight edge rather than a stair,
  and what keeps the outline star-shaped so its top faces can still be fanned
  from the centre.

  **Irregular means two fixed harmonics, not noise.** A random outline would
  rebuild differently every time the flat/smooth toggle flips, which is a pond
  that moved while she was looking. Two lobes and seven ripples give a bank that
  wanders **32 mm off the straight line between its two ends** over a 250 mm
  chord — which is the difference between a pond and a ruled arc, and the first
  attempt at this shape got it wrong by being too gentle.

  **The rim only follows the inland bank.** Where the water runs off the plateau
  there is nothing to put a stone on, so the eleven stones stop five samples
  short of each cut and the water meets the lawn's edge bare.

  **Nothing is in the water, and that is now four moves deep.** The basket was
  in the middle of it and took the molehill's ground in front of the bed — where
  a basket wants to be anyway, since a picked plant hops into it from the bed;
  the molehill went out to the lawn in front of the bench; the butterfly hovers
  over the middle of the open floor. The flower row's near end is the only thing
  still close, at 34 mm — a flower at the water's edge rather than a flower in
  it.

  **The water steps down without a hole in the floor.** Sinking it below
  `floorY` cannot work: the floor is a solid box and geometry inside it is
  hidden. So the basin stands on the grass, each of the four bands is a closed
  washer whose top sits 1.4 mm below the one outside it, and the three outer
  ones are clipped in their own right — so the terraces are cut where they meet
  the plateau and the step shows in the cut face.

  **The one prop in the game whose mesh is not a `RoomBuilder.Shape`.** An
  outline that is a wobble clipped by the room is not a primitive and never will
  be, so `GardenProps` builds its two meshes itself — a solid from an outline and
  a washer between two — borrowing the windings that `prism` and `annulus`
  already prove. Adding a case to the shared enum for one room's one prop would
  have been the worse trade.

- **A rainbow**, which is the one worth describing. `GAMEPLAY.md` §6.2 says
  waving the can in the air makes one, and it is discovered rather than
  explained: a long swing of the can that watered nothing is exactly what a
  4-year-old does with a watering can before she works out what it is for, and
  answering that with a rainbow is worth more than answering it with nothing.
  Both conditions matter — without the travel it would fire every time she put
  the can down, and without *watered nothing* it would fire on the sweep that
  ripens the bed, which already has an answer.

  **Its seven bands are the room's own palette in rainbow order**, not spectrum
  colours. A real rainbow in a room of six pastels is the flour-cloud mistake
  again: the one thing on screen that came from somewhere else.

### Deviations from `GAMEPLAY.md`

**Eight seeds, not six.** §5 lists six; the kitchen shipped eight, because
`maanstof` and `veertje` were added to get the cake-colour arithmetic back. A
garden that grows six of the eight the kitchen deals would leave a hole the
moment the basket is wired through — so the shelf is `Ingredient.allCases`, two
shelves of four. Owner's call, 2026-08-16.

**A full basket is the completion rule in both modes.** `GAMEPLAY.md` §3 gives a
visit its own rule, distinct from the round's — three cakes against one, in the
kitchen. The garden has no honest second helping: a sixth ingredient has nowhere
to go, and picking with a full basket is not a thing. So it is one rule, and the
flag only decides what the door *does*.

**The door is the kitchen's door, in the kitchen's place.** Not a gate. The way
out being where it was last time is worth more to a 4-year-old than variety, and
`ROOMS.md` §9's three cues were argued once already.

**Tapping it is a ceremony, not a transition** — the bakery hub does not exist,
so there is nowhere to be taken, and a 4-year-old told she is going somewhere and
then not taken there has been lied to. What it *does* do is real: it writes the
basket. `GardenRoom.endRoom` is the one function the hub replaces, exactly as
`KitchenRoom.endRoom` is the one the decorating room replaces.

### What the second room cost, and what it bought

Two things were built that are not the garden, and they are most of the reason
the third room will be cheaper than this one.

**`Engine/CarryController.swift` and `Engine/Surfaces.swift`.** Dragging a seed
into a hole and sweeping a can across a bed *is* the kitchen's carrying model —
the height easing, the ray that keeps a prop under her fingertip, the container
rims, the settle rules, the one patch of floor a drop is not allowed to stick
in. `ROOMS.md` §6 says inherit it rather than rediscover it, and it was welded
into `Layout` and `KitchenRoom`. It is now two files parameterised by each room's
own rectangles, and **every call site in `KitchenRoom` is spelled exactly as it
was**: `Layout.surfaceY`, `Layout.surfacePointedAt`, `Layout.isOutOfSight` and
the rest are one-line forwards onto `Layout.surfaces`, and `pickUp`, `carry`,
`settle`, `endCarry` and `surfaceUnder` are one-line wrappers. Moving the hardest
code in the project should not also be a rename of twenty call sites.

The two questions it keeps apart — *what is under this point* and *what is her
finger pointing at* — are the thing that cost two failed attempts, and the
garden immediately needed the distinction for a reason the kitchen never had: the
bed is a surface at its **rim** for a carried seed and at its **soil** for the
halo, because the holes are sunk 10 mm below the rim. One exception each, and
they are different exceptions. `CarryController.pointedExtra` and `restingExtra`
are exactly that pair.

**`Game/Room.swift` and the room picker.** `GameScene` used to hold a
`KitchenRoom`; it holds an `any Room` now, and `enter(_:handing:picked:)` is the
one entry point — leave, detach, clear the targets, stop the voice, build, greet.
Stopping the voice is not tidiness: `VoiceBank` holds a pending line and can
have a chain of them in flight, and Nina saying "put the tin in Otto" over a
garden is worse than silence.

`leave()` is the part to be careful with. **A `Ticker` job a torn-down room
still holds keeps animating a detached entity forever, and nothing on screen says
so.** The kitchen already had the complete list — `cancelEverything()`, because
`build` needs it on every rebuild — so leaving is that list plus a save.

### What it owes

Nothing structural. The three things it is short of are content and are cheap:

- **The bed is five holes because the basket is five.** `GAMEPLAY.md` §10 leaves
  "three rather than five" open and wants it decided before the friends are
  built. `GardenLayout.plotCount` follows `Layout.ingredientsPerRound`, so that
  decision is still one constant and the bed follows it. `GardenStore.load`
  already migrates a save whose bed is the wrong length.
- **The wish hint** — a colour wish shimmering its matching jar — is one line
  once the friends exist, because the shimmer is already the jars' cue.
- **`GAMEPLAY.md` §6.2 lists a bee, a butterfly, a mole, water and flowers.**
  All six are in — the water as one pond rather than the two puddles §6.2 used
  to ask for, owner's call 2026-08-16, and §6.2 now says pond. The next one or
  two are free (`ROOMS.md` §8: add one every time you touch a room).

## Deliberate deviations from the design

**There is ambient occlusion on the twenty-two Blender props, and nowhere
else.**
`references/REFERENCES.md` bans it outright — the facets are supposed to do the
shading and corners are supposed to stay light — and that holds everywhere a
facet can answer the question. The modelled props are where it cannot: the berry's crown
stands up off the globe, the sack's collar fans out over its tie, every one of
the crate's boards butts into a corner post, four clover petals crowd into one
hub, and icing hangs over the edge of every cake tier — and in all of those
joins the surfaces face the same way as everything around them, so they come
back the same tone and nothing says the two shapes touch. Owner's call, on
seeing the standing crown, and extended to each prop after it.

It is baked **to the facets, not to a texture** — `bake_ao_facets` in
`models/lowpoly.py` measures the occlusion at model time and splits the faces
in the crevice into their own mesh, which `Palette.occluded` paints a step
darker. So there are still no UVs, no lightmap and no runtime cost, and the
occlusion is still one flat tone on a facet. Its reach runs from 2.2 mm on the
berry to 6 mm on the sack, always sized against the part it has to stay inside:
contact shading where two parts meet, not the all-over darkening the clay
direction was rejected for. **The cake's tiers are exempt entirely** — they are
repainted every round, and a tier a step darker would read as a colour she did
not choose. Everything built by `FacetedMesh`
has none. `models/README.md` has the argument in full and the three rules that
keep the bake honest, and `LIGHTMAPS.md` is still the untaken texture route.

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

**And a lilac**, which is now only used by the portrait's *fallback*. The
photograph has the girl in a lilac t-shirt covered in deeper purple daisies, and
purple is the second hue the locked thirteen do not contain — the plates had no
more purple in frame than they had blue. `Palette.lilac` and `lilacDeep` are
built the same way `berryBlue` was, and it is worth saying again because it is
the rule rather than the exception: **not sampled off a screen, derived to the
register.** They survive the switch to the real photograph because the modelled
girl behind it does.

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

**The honey pot is a third bigger than the other five.** The six ingredients were
built to one rule — roughly 20 mm each, so that no one of them is the big one —
and `zonnehoning` is the one that had to break it. It is the only one whose
subject is a *container*, and a container has to read as having an inside; at
20 mm the pot, its rim, the pool of honey and the dipper across it were four
details inside a thumbnail, and all that carried the object was its silhouette.
The extra third is what makes the honey visible as honey.

### De pollepel

**The thing she stirs with is a wooden spoon now.** It was a whisk — two prisms,
a stick with an upside-down cone on the end — and it read as neither a whisk nor
anything else.

The first spoon was rejected too, and the reason is worth keeping: it was
modelled from a *generated* plate that turned out to be the wrong brief — a
long-handled ladle seen at an angle — and what came out of it was a shallow dish
on a stick. It was rebuilt from a photograph of three real wooden spoons, which
settled three things the plate had backwards:

- **The handle is narrow at the bowl and thick at the far end.** The first
  version tapered the other way, thick at the scoop and drawn to a point, which
  is the silhouette of a trowel. A real spoon is turned the opposite way round: a
  slim neck under the bowl opening out to a chunky end you can get a fist around.
  That single inversion is most of the difference.
- **The bowl is nearly a hemisphere, and its rim is thick** — not a saucer.
- **There is a neck**, a short waisted section between bowl and handle, and it is
  what makes the two read as one turned object rather than two prims stuck
  together.

A spoon is one of the few kitchen objects a 4-year-old can already draw, which is
exactly why it took two goes: she knows when it is wrong.

It is built standing on its scoop with the handle straight up, which is the
convention the whisk used, so nothing in the round had to change: stirring stands
it in the bowl as-is and resting it on the table is the same single rotation.

The plate's hanging hole in the handle is not modelled — there are no booleans in
`FacetedMesh`, and at 4 mm across it would be two pixels of smudge. Same argument
that gave the honey dipper two parts instead of the plate's five rings.

Two voice lines went with it, since both said *garde*: the naming line is now
`nina.dit.lepel`, and the one variant of `nina.keuken.roeren` that named the tool
was regenerated.

### Pouring

**The pour is a pour now.** It used to be a cut — the bowl tilted over 0.45 s,
and on the frame the tilt finished the bowl's batter was removed and the tin's
began to grow. Both *ends* of the action were animated and the action itself was
missing, so the batter teleported between two containers.

There is a stream between them now, built the way the tap's is: a lathe hanging
from y = 0 so growing it down the Y axis is the pour starting, narrow at the rim,
swelling as it falls, pulling in as it lands. It turns while it runs so its six
facets travel.

The part that is easy to forget is that **the bowl has to empty while the tin
fills** — a source that pours forever into a filling destination is the same tell
as water that never gathers in the basin, which is why the tap has a pool. All
three happen over the same 0.7 seconds.

### Ingredient variety, and getting the cake rules back

The five slots each took their own `randomElement()`, which is five independent
rolls of a six-sided die: the odds of all five coming up different were about
**9%**, so a round with two toverbosbessen and no toverklaver anywhere was the
normal outcome rather than bad luck. The room has five places to visit and it was
routinely sending her to two of them for the same thing.

They are dealt from a shuffled deck now, reshuffled only when it runs out — so a
repeat is impossible until every type has been seen once.

**That cost the cake rules, and two new ingredients bought them back.** Five
distinct draws out of six meant at least four coloured ones in every bowl, and
three colours or more is a `regenboogtaart` — so `.effen` and `.gemengd` became
unreachable overnight, and Nina's per-colour lines with them.

`maanstof` and `veertje` are both **colourless**, which changes the arithmetic
rather than working around it. The deck is now five coloured and three
colourless, and five draws from that gives:

| colours drawn | chance | cake |
|---|---|---|
| 2 | 17.9% | `gemengd` — two colours, marbled |
| 3 | 53.6% | `regenboog` |
| 4 | 26.8% | `regenboog` |
| 5 | 1.8% | `regenboog` |

So a two-colour cake is back, about one round in six. **`.effen` is still out of
reach**, and honestly cannot be bought this way: one colour from five draws needs
four colourless ingredients in the hand, which needs at least four in the deck,
which is most of it. The remaining lever is `Layout.ingredientsPerRound` — at
three the colour count is free to be one, two or three and every cake in
`GAMEPLAY.md` §5 comes back. That is the change to make when the garden lands and
starts choosing what goes in the basket, because an interesting three beats an
exhaustive five.

They earn their place beyond the arithmetic. Both carry an effect that until now
only a *coloured* ingredient could give — `maanstof` glows like sun honey,
`veertje` rises like cloud cream — so those two effects stop being welded to
yellow and white and can land on a cake of any colour.

The props follow the set's own rules. **Moon dust is read through its pouch**,
which is the lesson the honey pot taught: a substance with no shape of its own is
read through its container, and dust is that problem in a harder form. It is
deliberately unlike the honey pot — a tall soft bag pinched shut against a wide
rigid jar with a dipper across it — because at thumbnail size two containers have
to differ in silhouette or they are one prop in two colours. **The feather** is a
flat extruded blade facing the camera, like the clover and the star, and what
sells it is the asymmetry: fuller on one side of the shaft than the other, which
a symmetrical leaf shape cannot borrow.

### The portrait

**There is a photograph of Nina on the back wall above Otto**, framed in rose.
Tapping it sparkles and she says who it is. It fills the one large blank surface
left in the room — the back wall's right-hand half, which read as blank.

**It is the actual JPEG, not a reconstruction of it.** This was built the other
way first — the girl rebuilt out of boxes and stars in the room's own faceted
vocabulary — on the argument that a photograph inside a flat-shaded room is the
flour-cloud mistake again, the one thing on screen that came from somewhere
else. The owner overruled it, and the analogy was wrong: the flour cloud was a
*photographic prop pretending to be part of the room*, whereas this is a
photograph **being a photograph**. A framed picture on a wall is supposed to look
like it came from somewhere else — that is what a photograph is for. And a child
who knows the girl in it is not going to be persuaded by an approximation made of
boxes.

So the frame stays the room's, faceted rose rails made of the same stuff as the
door, and what is inside it is the file.

Three things follow from using a real texture, each a constraint the procedural
props never had:

- **The picture is a `MeshResource.generatePlane`, not a `FacetedMesh` box.**
  `FacetedMesh` writes positions and normals and no texture coordinates, so a
  texture on one of its meshes has nothing to map to. `generatePlane` carries
  UVs, and a photograph is flat anyway.
- **The frame is sized from the photo**, not the other way round. The texture's
  pixel dimensions give the aspect and the picture is fitted inside
  `Layout.portraitPictureMax`, so a landscape photo gives a landscape frame and a
  portrait one gives a portrait frame. Replacing the file needs no numbers
  changed.
- **It is lit, not unlit.** A `PhysicallyBasedMaterial` with the photo as its
  base colour dims and brightens with the room's key light the way a real print
  behind glass would. Unlit would be truer to the file and would read as a screen
  hanging on the wall.

**Replacing the file is one edit, and it has one trap.** The filename in
`Contents.json` must match what is on disk exactly, extension included — the
wiring looks the image set up by its folder name, so a mismatch does not error:
it yields an empty image set, the texture load returns `nil`, and the frame
silently falls back to the modelled girl with nothing saying why. It has already
happened once, `.jpeg` against `.jpg`. Everything else adapts on its own.

That fallback is kept for a reason `ModelLibrary` already established: **a
missing asset must never leave a live tap target with nothing behind it.** An
empty frame over a working tap is the "every tap does something" rule broken. So
the app is correct either way — with the file it is her photo, without it a
picture of her.

The frame is a shallow shadow-box 12 mm deep — the same depth the door frame
stands proud of the left wall, and for the same reason: at this camera a casing
with no visible side reads as paint. The print sits 4 mm behind the front of the
rails, which is the rebate a picture sits in, and runs 2 mm oversize under them
on every side, because two coplanar edges at this scale show a hairline of wall
wherever the rasteriser rounds the wrong way and it would look like a crack.

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
| `Engine/Surfaces.swift` | **What is under a point, what her finger is pointing at, and what she cannot see behind.** The first two are different questions; confusing them cost two failed attempts at the drag. The third is `Occluder` — the solid boxes a drop is not allowed to stick behind. Each room declares its own rectangles and its own occluders. |
| `Engine/CarryController.swift` | **Carrying, solved once.** Height easing, the ray that keeps a prop under her fingertip, container rims, and the settle rules. Was `KitchenRoom`'s; the kitchen and the garden both use it, and the decorating room does not — it places stickers on a cake rather than carrying props across surfaces. |
| `Intro/LoadingScreen.swift` | The title plate, and the floor it is held for. |
| `Intro/IntroMovie.swift` | The opening film: a queue of shots, and two ways out of it. |
| `Audio/SoundKit.swift` | All fifteen sound effects, synthesised at launch. |
| `Audio/VoiceBank.swift` | Nina and Otto, driven by every bundled `script-*.json`. Also `sayWhenQuiet`, `sayInstead` and `whenQuiet`, which are why nobody gets talked over — or talked at about a step they have left. |
| `Game/Room.swift` | What a room is, seen from outside: the protocol, the `RoomID` the developer panel switches between, the `RoomMode` flag, and the `RoomExit` a room ends with. |
| `Game/CakeSpec.swift` | Eight ingredients → colour, effects, and what Nina says about them. |
| `Game/CakeGeometry.swift` | The cake as numbers, so the kitchen and the decorating room build the same one. |
| `Game/Sticker.swift` | The seven sticker kinds and what each is worth saying about. |
| `Game/RoundState.swift` | The kitchen's round, and the JSON it is saved to. Bakes the garden's basket when it is handed one, and deals off a shuffled deck when it is not. |
| `RoomBox.swift` | The box every room is in: its size, its shell, and the ray arithmetic the fixed camera makes possible. |
| `Props/Doorway.swift` | The way out. Shared, because `ROOMS.md` §9's three cues are a rule about rooms rather than about one — and the garden's gate is the same function with the light left out. |
| `Kitchen/KitchenProps.swift` | Otto, the bowl, the batter, the tin, the cake, the eight ingredients, the toys, the portrait. |
| `Kitchen/KitchenRoom.swift` | The kitchen: assembly, the state machine, the toys, the nudges. |
| `Versieren/VersierLayout.swift` | Every position in the decorating room, in one table. |
| `Versieren/VersierState.swift` | The turntable's angle, what is on the cake, and the JSON it is saved to. |
| `Versieren/VersierProps.swift` | The turntable, the trays, the piping bag, the shaker, the stickers and the toys. |
| `Versieren/CakeSurface.swift` | Where on the cake her finger landed — the one ray test that is not a flat surface. |
| `Versieren/VersierRoom.swift` | The decorating room: turning, piping, shaking, placing, and the candle. |
| `Garden/GardenLayout.swift` | Every position in the garden, in one table, plus its `Surfaces`. |
| `Garden/GardenState.swift` | Five holes, the basket, and the step derived from them. `tuin.json`. |
| `Garden/GardenRoomBuilder.swift` | The garden shell: ground, the bed, the potting bench, the fence and its gate, the path and the greenery. |
| `Garden/GardenProps.swift` | Seed jars and seeds, the four plant stages, the can, the basket, and the six toys. |
| `Garden/GardenRoom.swift` | The garden: sowing, watering, picking, the halo, the toys, the door. |
| `RoomBuilder.swift` | The kitchen shell and furniture, plus `Layout` — every position in it, in one table. |
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

It compiles, like everything else here, but **nobody has pressed one** — the
sinking, the chamfer inversion and the 2 pt drop are all still design rather than
observation. `references/buttons/render-facetbutton.py` re-draws `FacetPlate`
from the same constants, so the sheet in that folder shows what the code
produces without needing a device.

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

### Props modelled in Blender

**Twenty-two props are not built in code.** Ten in De Keuken: the flour sack,
the toverbosbes, the crate, the toverklaver, the toverveertje, the maanstof
pouch, the sink, the spoon, the cake and the scale. Twelve in De Tuin: the
molehill, the seed bed, the fence, seven of the eight ripe plants, and — added
2026-08-17 — the tree and the harvest basket. All are USDZ files in
`Resources/Models/`, modelled by the scripts in
[`models/`](../models/README.md) and loaded by `ModelLibrary`.

They are a trial of a second authoring route, and each was picked on the same
test — the prop where the `FacetedMesh` vocabulary visibly runs out against its
plate, not the prop that would be fun to model.

- **The sack**: cloth. The gather folds pinching into the tie and the pleated
  crown above them are half of what
  `references/ingredients/flour-sack.png` is, and the code version — four
  stacked lathes and two wedges — reads as a bag with a collar rather than a
  bag that has been gathered and tied.
- **The berry**: a faceted globe with a calyx dished into its top and a crown
  of five sharp spikes standing in it. A lathe gives broad vertical panels, a
  pole at each end, and no way to make a dish and a dome from one profile.
  Without the crown a round berry is a blue marble.
- **The crate**: four corner posts with boards spanning between them and gaps
  you can see through. This one is not a shape the vocabulary was missing, it is
  a shape nobody built — the code version is a four-sided `bowl` with a ring on
  top, which is a tapered tub, and a tub cannot be tuned into joinery. Its plate
  was generated for the job: `references/props/crate-a.png`.

- **The clover**: petals with a real crease down each one. A flat extrusion has
  one front face and one tone, so the code version stands in for the fold by
  painting alternate petals two greens.
- **The sink**: a tap with a square post, a spout mitred down over the basin and
  a chunky handle, against two prisms meeting at a right angle. **Its water is
  still built in code** — it is animated by scaling one axis, it is the one
  transparent surface in the game, and there is no facet the lathe cannot make.
  `models/sink.py` has the full argument, and it is the clearest statement of
  where the modelling route stops.
- **The cake**: the payoff object, and the one with the most to lose. It gains
  icing that drips over each tier, a ring of pearls, and a stem on its cherry —
  while `tierColours`, `isTall` and `glows` all still work, because the tiers
  are separate meshes, the stretch is a Y-scale on the upright wrapper and the
  glow is a material swap.

- **The scale**: a dial that is a fat coin on a neck rather than a disc leaning
  on the base, a pan with a rim, and a plinth. It is the first modelled prop
  with a **moving part** — the pan bounces when tapped — which is what
  `ModelLibrary.pivot` exists for.

- **The feather**: the clover's problem again — a vane rises from its shaft on
  both sides, and a flat extrusion has one front face. It took three goes and
  is the weakest of the ten; what fixed it was proportion, not detail.
- **The maanstof pouch**: cloth, at a quarter of the flour sack's size, and its
  real job is not looking like a small flour sack. Round-bellied and
  narrow-necked against the sack's squat settled shape, with uneven points of
  open cloth where the sack has an even pleated crown.
- **The spoon**: a round scoop with a thin rim instead of a tapered cup, and
  one straight handle off the rim instead of a prism with a butt piece seamed
  on. The real fix is that the code version's handle rises through the middle
  of the cavity, which reads as a goblet. It is the only prop the room poses two
  ways — lying on the table, standing in the bowl to stir — so it is modelled
  lying, as the reference draws it, with the **inverse of the room's tip on its
  root** so both poses still come out right.

**De Tuin's ten went differently, and the difference is worth knowing before the
next room.** The kitchen picked its props one at a time, each because one plate
asked for one thing. The garden's were asked for as a batch, so the useful
question was not *which prop* but what this room kept needing that the last one
did not — and there were three answers, which is now `models/garden.py`: **the
fold** (every garden plate creases its leaves down the midrib, and a bed has
thirty of them), **the bend** (`plant-aardbei.png`'s arched stalk and
`plant-klaver.png`'s two curved stems; there is no bend in `FacetedMesh` at all),
and **a point on the end of things**.

Three of them are worth calling out here:

- **The molehill fixed a bug rather than a shape.** `tapMolehill` lifts Mo to
  y = 0.0135; his head sat at his pivot's origin with a 9.2 mm radius against a
  19.5 mm hill, so at full pop it cleared the earth by 3.2 mm and the **nose
  never came up at all**. The model builds him 11.2 mm up his own pivot, so the
  room's two tween positions — gameplay numbers that have been played against —
  are untouched.
- **The fence is the whole L, in world coordinates, at the origin.** It is the
  room's boundary rather than a thing standing in the room, and it turns
  forty-odd pickets, eleven posts and six rails into three meshes.
- **The bed's holes are wells without a boolean**: the soil sits 3 mm below
  `bedSoilY` and each ring stands 2.2 mm above it, so she looks into a 5 mm well
  made of two convex solids that happen to overlap. A boolean would hand back a
  fan of triangles where there was one facet, in the one prop the room's
  required action happens on.

**`plant-bosbes` is the gap.** It was not in the batch that was asked for, so
one of the five holes in the bed grows a plant built the old way — visible if
you look for it, because its leaves alternate two greens where the other seven
are one.

**The tree and the basket came a day later, one at a time**, and both are the
same argument as the clover's fold: a shape whose reading depends on a crease
the facets cannot answer.

- **The tree**: fourteen lobes in **one mesh**, so the seam where two of them
  push into each other can be measured and shaded. The code has eight separate
  spheres, which cannot be measured against each other at all, and stands in for
  the crease by painting alternate lobes `sage` and `mint` — a tint doing a
  shape's job, and at 139 mm across it reads as a bag of two-coloured balls. The
  modelled canopy is one colour, which is what the plate draws. Its envelope —
  225 mm tall, 128 mm of trunk, canopy from 105 mm, 139 mm across, all of it
  measured against the fence posts and the bench — is asserted by the build
  script rather than trusted.
- **The basket**: a **rose lining**, which `FacetedMesh.bowl` cannot have
  because it is one mesh with one tone; a **rim band with an underside** where
  the code lays a flat `annulus` on top; and one swept handle instead of seven
  overlapping boxes, spanning the diagonal the fixed camera actually looks
  across rather than the world X it sees end-on.

All twenty-two carry the game's only ambient occlusion — see the deviations
above.

What the route costs is a round trip through a file, and what it buys is shapes
that have to be built vertex by vertex. `models/README.md` has the rules a
model has to hold to, and the export settings that are load-bearing.

Three things about it are worth knowing here:

- **The palette still wins.** Whatever material the exporter wrote is thrown
  away on load and replaced with `Palette.material`. `Palette.swift` stays the
  only place a colour is defined.
- **`flat: false` falls back to the code versions.** The exported meshes carry
  one normal per face and nothing re-derives them, so the debug panel's
  flat-shading A/B is a question only the procedural meshes can answer. They
  are still there — `KitchenProps.proceduralFlourSack` and
  `buildProceduralBlueberry` — still built, still correct.
- **So does a missing asset.** `ModelLibrary.load` returns `nil` rather than
  trapping, because a prop she can tap matters more than which prop it is.

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

> **It has now happened three times**, and all three are worth reading, because
> together they are the only evidence this project has about what
> correct-by-construction actually misses.
>
> **Build one** — the commit *Make both rooms compile*. Five errors, every one of
> them `[weak can]` on `GardenProps.WateringCan`, which is a struct; `weak` only
> applies to classes. The closures did not want the struct anyway, they wanted
> the two entities inside it.
>
> **Build two** — the commit *fix build*, after De Tuin, the fence, the gate, the
> bench and the reconciliation. Three errors, no two alike:
>
> 1. **`Props.gate` called `model(...)` six times with no `RoomBuilder.`
>    prefix.** The calls were written inside `KitchenProps`, where a local
>    `model` was in scope, and came across unchanged when the door moved out to
>    `Props/Doorway.swift`. **This is the tax on every file move**, and it is
>    invisible to a reader who knows what the line means.
> 2. **`KitchenLayout.surfaces` passed `floorY:` where it needed
>    `RoomBox.floorY`.** A static property of an enum reaching for another static
>    of the same enum while that enum is still being initialised. It reads
>    correctly and is not.
> 3. **`VersierLayout.assertSpacing()` needed `@MainActor`**, because its new
>    perpendicular-distance pass calls `RoomBox.screenSeparation`, which reads
>    `CameraRig.eye`. Adding one call to a main-actor thing pulled isolation up
>    through a function that had never needed it. Its only caller was already on
>    the main actor, so the fix cost nothing — but nothing in a grep would have
>    found it.
>
> **Build three** — De Tuin's ten Blender props and the four call sites that
> load them. **No errors**, and the reason is not that the work got easier: it
> is the first change written on a machine with a compiler on it, so the edits
> that would have been errors were fixed before anything was committed.
>
> It is not a null result. It came with **five findings of its own, and every
> one of them came from a render rather than from a build** — the honey pot that
> read as a pie from a 34° camera, a strawberry hung so far out it landed on the
> next plant, a feather made as wide as it was tall, a mole with his paws inside
> the hill, and rails buried 3.5 mm inside every picket they passed. A compiler
> would have passed all five. `models/README.md` has them.
>
> **The pattern across all eight compiler errors: none of them was a number, and
> none of them was a prediction.** The five below did not fire on any build.
> Every one of the eight was *scope, isolation, or a type's kind* — which is
> precisely the category a careful reader cannot check and a compiler settles in
> a second. The lesson for the next room written without a toolchain is not
> "check the constants harder"; the constants have been fine three times. It is
> that **a file move and a new call into main-actor code are the two edits that
> most need a build behind them** — and, from build three, that **geometry needs
> an eye rather than a compiler**: ten props built correct-by-construction were
> all compile-clean and five of them were visibly wrong.
>
> The five are kept because they are still the right list for *the SDK moving
> under the project*, which is the other way this breaks.
>
> **What to look at first in the drop-boundaries work**, which was written in
> the container and so reached Xcode without a compiler having seen it. By that
> lesson's own reckoning it is both risky edits at once:
>
> - **New `@MainActor` methods** — `Occluder.hides` and `Occluder.isPointedAt`,
>   which read `CameraRig.eye`. Exactly the shape that caught
>   `assertSpacing`. If isolation propagates somewhere unwanted, mark the caller
>   the way that one had to be.
> - **New stored properties with defaults** — `Surfaces.occluders` and
>   `innerWalls`, which the synthesised memberwise initialiser has to carry in a
>   struct two rooms construct positionally. `innerWalls` is spelled `= nil`
>   explicitly for that reason. If it bites, write the initialiser out by hand
>   and every call site stays as it is.
> - **One new runtime API** — `Entity.visualBounds(relativeTo:)` in
>   `CarryController.pickUp`. If it has moved, the fallback is a radius of zero,
>   which is exactly the behaviour before it existed.
>
> **The geometry is not correct-by-construction**, which is the part a build
> would not have caught either way: every sweep was run in Python against the
> committed camera before being written down. That is how Nina came off the
> occluder list, how "no work surface is shadowed" became a measurement rather
> than a claim, and how the chimney got onto the list at all. What was swept: no
> work surface or home spot shadowed (2 mm grid); a carried prop never inside a
> solid over 26,240 drag directions × four prop sizes; every prop's body stops
> exactly on the plaster; no home position moves when picked up; the tin held at
> Otto's lip stays clear of the dome at every push.

Five places are the most likely to want a fix, and all five are one line:

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
5. **Where the USDZ files land in the bundle.** They sit in
   `Resources/Models/`, and whether a subfolder of a synchronised group
   survives into the built bundle as a directory or is flattened into its root
   is not something worth guessing at, so `ModelLibrary.url(for:)` asks for
   both. If the sack or the berry looks like its old self on device, that
   function is the place to look — the symptom is the code-built prop instead,
   never a crash and never a hole in the floor.

### The developer panel

**Tap the small grey wrench in the top-right corner.** The strip behind it is
hidden on purpose: `CONCEPT.md` §5 asks for a parent gate she will not find, and
a visible gear is a thing she will press.

**At the top of it is the room picker** — Tuin / Keuken / Versieren — which is
how you visit a room without playing the game up to it, in either mode and with
any cake. That was fine to do without while there was one room and is useless
with six: checking a touch radius in the garden should not be a five-minute
walk.

The strip stays off screen until it is asked for, and the picker is exactly the
control that gate was written about: a visible row of buttons that teleports her
out of the room she is playing is the most pressable thing that could be put on
this screen. What opens it is now a small grey wrench rather than three taps on
an invisible corner — the gesture was unreachable under the film and there was no
way to see that it was. `developerButton` in `ContentView.swift` has the whole
argument.

Under it: the room's own two or three lines, which the strip no longer knows how
to compose — it renders `Room.debugRows` and `Room.debugActions`, so the kitchen
prints its step, its bowl and its plank, the garden its step, its bed and its
basket, the decorating room its mode, its turn and what is on the cake, and a
fourth room shows up in here for nothing. Then **which voice line just played**,
which during a session with Nina is the difference between "she ignored it" and
"she never heard it". Plus a new round, a mute, and the whole POC lighting panel
underneath.

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

**Voice is real.** 192 Dutch line variants across 107 ids, generated with
`text2speech_v2` / `elevenlabs` and bundled as mp3s — the app never calls an API.
Nina is Gracie; Otto is provisionally Barrett, and `audio/auditions/README.md`
explains how to swap him for four credits and no code.

The 52 added for the garden — about 16 credits — are `script-tuin.json`'s 27
round lines and 12 toy lines, plus 13 naming lines appended to
`script-namen.json`. **`VoiceBank` loads every bundled `script-*.json` and merges
them**, so the whole garden was a new file and no Swift change beyond the
constants in `Line.Tuin`.

Four things it reuses rather than duplicating, and the reuse is the point:
`nina.oeps` for a drag that did not land, `nina.stil` for the alternating idle
nudge, `nina.ingredient.*` when she picks something — the line that already names
the colour that ingredient will give the cake, which is exactly what she wants to
know at that moment — and `nina.dit.<ingredient>` when she taps a seed jar. **The
word she learns in the garden is the word she hears in the kitchen.**

> **One trap, and it is silent.** `VoiceBank` decodes `lines` with a
> non-optional `{id, character, variants}` model, so a single `{"_section":
> "..."}` marker slipped into that array for readability makes the *whole file*
> fail to decode — and it fails into a room where every naming line is mute, with
> nothing raising. Section notes go in `_why`. It nearly shipped once.

**Sound effects are synthesised.** Fifteen of them now, rendered to PCM at launch
by `SoundKit`. The garden added exactly two — `buzz` and `dig` — because
`ROOMS.md` §10 says reuse the existing cases and add one only for a genuinely new
event. Planting is a `plop`, watering is `water`, ripening is a `sparkle`, and
the five chiming flowers are `ding` at five rates, which buys a whole musical
scale for nothing. `CONCEPT.md` §7.4 records that the connector cannot supply
SFX; a CC0 pack is still the plan, and swapping one in is a filename in
`Sound.fileName`.

**Music is absent**, as agreed. `GAMEPLAY.md` §10 still has it open.

## Versieren — the decorating room

`GAMEPLAY.md` §6.4, built 2026-08-16. The cake stands on a turntable, seven
trays wrap the two open edges of the floor, a piping bag draws cream and a
shaker rains sprinkles. Drag a sticker anywhere on the cake and it stays where
she put it.

**It asks her for nothing**, and that is the whole design rather than a gap in
it. Three things follow:

- **The halo has nothing to point at.** The kitchen's grammar is *one lit prop,
  which is the next thing to do*, and a room with no required action breaks it.
  The answer is not to invent one — the **door is lit from the first frame**,
  which says *you may go when you like*, true here and nowhere else.
- **The miss machinery is not wired.** `noteMiss` means *she dragged the prop
  the step is about and it did not land*, and there is no such prop. A sticker
  dropped off the cake is a removal, not a failure.
- **The idle line is not an instruction.** *"Hij is al zo mooi — zullen we
  gaan?"*, alternating with *"ik ben er nog, hoor"*.

### The seam it forced

The app had one room and no way to hold a second. `GameScene` owned a concrete
`KitchenRoom`, `ContentView` read its state directly, and `Layout` was 680 lines
of kitchen constants under a name the next room would want. Three things
changed, all of them mechanical:

- **`RoomBox`** takes the box every room inherits — the size, the walls, the
  floor, `carryLift`, `distanceXZ`, `pointOnRay`, `within` — plus `shell(flat:)`,
  lifted out of `RoomBuilder.build`. `ROOMS.md` §0 makes "the same box and the
  same eye" a rule rather than a convention, and a rule kept in two files is
  what `KitchenLayout`'s own opening warning is about. The rest is
  **`KitchenLayout`**: 193 references across five files.
- **`protocol Room`** is seven methods and two readouts, derived from what
  actually crossed the boundary rather than from what a room might want.
  `debugRows` and `debugActions` are what let `ContentView` stop reaching into
  `kitchen.state`. `onExit` means a room says *what just finished* and hands
  back control — it never learns what comes next.
- **`RoomStore`** is generic; `RoundStore` is a thin kitchen-named wrapper over
  it and its call sites did not move. One file per room is what stops a new room
  corrupting an old one's save.

### The room switcher

Behind the existing developer hotspot — three taps on the invisible 64 × 64
patch top-right. No new on-screen pixels, so `CONCEPT.md` §5's no-text rule is
untouched and Nina will not find it.

It carries a **cake preset**, because the decorating room has to look right on a
tall glowing sparkling rainbow and on a plain cream one alike, and reaching
those by baking is six minutes each. Entering `versieren` with no cake is a
visit, which deals a random one — so the switcher and visit mode are the same
code path rather than two.

### The four things that did not exist before

**The drop point on a curved surface.** `Versieren/CakeSurface.swift` — a ray
solved analytically against the tier cylinders and the top discs. Not a
`CollisionComponent`, for the reason `CameraRig` already records about
`targetedToAnyEntity()`: a cake with forty stickers on it would be forty
collision shapes each hitting exactly its own mesh, in a game whose entire touch
model is *near enough counts*. Two details worth keeping:

- **The full top disc is tested, not the visible annulus.** Any ray landing
  inside the next tier's footprint was already stopped by that tier, which is
  nearer along the ray — so nearest-hit-wins does the annulus for free, and an
  explicit inner bound would be a special case that only ever agreed with the
  general one.
- **Undersides are not tested**, because the radii strictly decrease upward and
  no tier overhangs the one below it. There is a note in the file saying what to
  add if a cake ever inverts, and that the right answer then is to *reject* the
  hit — a sticker glued under an overhang is one she cannot see.

**Cake-local polar anchors.** Tier, face, angle, and a fraction along that face.
Turning the turntable is free, `isTall` cannot stretch a heart, and the party
and the wall can re-render the same cake from the spec alone. A world-space
position would tie a permanent trophy to one camera and one turntable angle.

**The stroke.** `FacetedMesh.ribbon` sweeps a whole path into **one** geometry,
so a finished stroke is one entity however long she drags. The cap is arc length
per bag-full, and it is **visible before it bites**: cream inside the bag goes
down as she draws, the ribbon thins below 15%, and letting go refills it. A cap
you can watch approaching is not a refusal — the same argument as the door
saying *openable* three ways at once.

**A room whose halo has nothing to point at** — above.

### Deviations, and things worth knowing

- **The cake is presented at 2.5×.** `CakeGeometry` is 52 mm across, which is
  about 82 pt on screen — fine for a prop she carries across a kitchen and
  hopeless as a canvas for forty stickers. It is a scale on the wrapper, not a
  second geometry, so `CakeSpec` stays the single description of the cake.
- **The tier radii moved to `CakeGeometry`.** They existed in
  `KitchenProps.proceduralCake` and again in `models/cake.py`, which was
  survivable while only the code that drew them read them. Every sticker
  position now derives from them, and a third copy is how stickers end up two
  millimetres inside the icing.
- **The sticker layer hangs beside the cake, not under it.** `isTall` is a 1.5×
  Y scale on the cake wrapper and would come out as stretched hearts.
- **Seven trays needed an L.** Two 32 mm touch spheres need 64 mm centres, so
  seven in a row would take 384 mm of a 460 mm room. The box is open on its +X
  and +Z sides, so the trays wrap the near corner in runs of four and three.
  `VersierLayout.assertSpacing` checks every pair against the sum of their radii
  in debug builds — it caught the two tool/tray pairs, which overlapped by 2 mm
  because the tools carry a 34 mm radius rather than 32.
- **The tea towel was cut.** Its plate came back soft on the top faces and reads
  as a folded sheet rather than a faceted prop — cloth is where the
  `FacetedMesh` vocabulary runs out, which `models/flour-sack.py` already
  records. The stool took its place as the fifth toy and cost nothing.
- **`FacetedMesh.extrude` is convex-only**, so the heart is two lobes plus a
  triangle and the crown is a band plus five triangles. A single heart outline
  would fan-triangulate into a fold.
- **No Blender props yet.** Everything is `FacetedMesh` primitives, to be
  swapped for `models/*.usdz` exactly as the kitchen's ten were.

### Two bugs this room found in shipped code

- **`TouchRouter.register` appends**, so re-registering a name leaves both. That
  was survivable while every target was registered once in `build`, and stopped
  being so the moment a room adds one mid-round: the decorating room would have
  accumulated a dead target per grain of sprinkle, each still holding its entity
  and still winning hit tests near where a sticker used to be.
  `remove(prefixed:)` is the fix.
- **`audio/script-keuken.json` had drifted six line ids behind the bundled
  copy.** `nina.plank.*`, `nina.kamer.*` and the two colourless ingredients had
  been added to the bundle without coming back to the canonical file. Nothing
  was audibly broken, which is why it went unnoticed; what was broken is that
  regenerating the kitchen's voice from the canonical script would have silently
  dropped six lines.

## Het Feest — the party

`GAMEPLAY.md` §6.5, built 2026-08-17. **It is a disco** — owner's call: *"the
room must resemble a discoteque with lights and a DJ. And of course cakes and
friends."*

A mirror ball on a cord, throwing eight pools of light that circle the floor. A
6×6 grid of light-up tiles covering four fifths of the floor. Five coloured lamps
on two bars with beams reaching down onto it. A DJ behind a booth with two
turning decks and a glowing front panel. A stack of speakers whose cones push on
the beat. Six friends dancing. Her cake, decorated exactly as she left it, on a
table under a light. And **six big pads along the open front edge**, one per
instrument.

### The room box plate overruled two things the room had already got wrong

Owner's call on `references/feest/roombox.png`, after the room was built:
*"I especially like this one."* Held up against it, two numbers were wrong, and
both were wrong in the same direction — too timid.

**The lit floor was a rug.** It was 4×4 at 137 mm, sitting in the middle of a
460 mm room, on the strength of `references/feest/dansvloer.png` — which had been
asked for a 4×4 grid and had delivered *four slabs*, so it never knew the count
in the first place. In the room box the tiles run from the back corner nearly to
the near edges, and that is what makes the picture read as a disco at all. It is
now 6×6 at 369 mm with a 16–33 mm border of plain floor, which the two end pads
need anyway: at x = 0.228 they would otherwise straddle the last tile's edge, and
a button half on a lit tile looks like a mistake rather than like a button.

**The mirror ball was a tenth of the room and should be a quarter.** 44 mm → 60,
which is still a small prop next to Otto's 124 mm dome. It is the object that
says *disco* before anything has moved.

Two smaller things came out of the same look: the tile colours are indexed
`row * 2 + column` rather than flat, because six colours on a six-wide grid puts
the same colour down every column and that is a barcode; and one tile in four is
lit at a time rather than one in three, because a third of 36 tiles is most of
the floor rather than a pattern travelling across it.

**This is the third time a room box has overruled a studio plate** — the garden
has the other three. The rule that keeps falling out: *a prop plate knows what a
thing is made of; only the room knows how big it should be.*

**The whole room is one number, and the number is hers.** `FeestBeat` turns the
interval between her taps into a period, and the guests, the ball, the tiles, the
lamps, the decks and the speaker cones all read it. Not one of them owns a clock,
which is what makes the room feel like it is following her rather than running
beside her. It is about eighty lines including the clamps, and it is the party.

### The disco is made of light, not of darkness

**The thing that could have wrecked the art direction, and the rule that stopped
it.** `references/REFERENCES.md` §1 asks for soft even lighting, no dark corners
and no occlusion pooling. A disco is the opposite of all three, and the obvious
build — turn the room's lights down, crank a coloured key — throws the whole
style away for one room.

So the lighting rig is **untouched**. What the disco adds is emissive surfaces:
the floor tiles, the lamp lenses, the beams, the booth's front panel and the
mirror ball's facets are `Palette.glowMaterial` and `Palette.lightMaterial` —
above white in the HDR buffer, somewhere a base colour cannot reach. The plaster
stays pale and the corners stay light.

It is the halo's four-attempt lesson (`Engine/Halo.swift`) applied to a whole
room rather than to a ring: **to make something look like a light, make it one —
never take the light away from everything else.** And it kept the palette locked:
the six disco colours are the existing pastels driven up with emission, so
nothing was added to the thirteen.

The same clause did the same work on the plates. Every disco prompt in
`references/feest/` carries *"brightly and evenly lit — a daytime pastel toy
disco, not a dark nightclub"* after the four locked style phrases, and it worked
first time on all ten.

### The guests are teddy bears, and each does a different dance

Two notes from the owner on seeing the room, 2026-08-17: *"in the reference
plates they are cute little bears. looks so much better"*, and *"the dance is too
much of the same. they should be hands in the air and each do a different little
move."* Both were right and both are now in.

**The body.** The first pass built every friend from a box torso, a box head and
prism limbs — technically the three-part rig, and a robot.
`references/feest/beertjes.png` is what it should have been: a plump barrel
widest low down, a big round head nearly as wide as it sitting straight on the
shoulders with **no neck at all**, a pale belly patch covering most of the front,
and arms and legs so short they read as stubs. The head is about **two fifths of
the whole height**, and that ratio is most of what makes it cute — it is the one
number in `GuestCharacter`'s proportions block worth protecting.

**The eleven friends did not change.** They are still `GAMEPLAY.md` §4's mouse,
cat, frog, bird, sheep and the rest, and the plate is what confirms that is
right: five different animals came back on it and every one is the same barrel
with different ears and a different muzzle. `buildFace` is where a friend
differs, which is why eleven friends still cost one builder.

**Round is the silhouette; flat is the surface.** An icosphere at one subdivision
is 80 flat facets and a six-station lathe is a barrel with six visible bands, so
nothing here bends the no-smooth-surfaces rule. The plate needed a prompt clause
saying exactly that or it picked a side at random — `references/feest/README.md`.

**The dance.** Six styles, one per guest, and `DanceStyle.allCases` is exactly
`guestCount` long so every party has all six on screen with no two alike:
*zwaaien* rocks side to side, *pompen* punches one arm with the other down,
*draaien* twists from the waist with arms wide, *springen* jumps clear of the
floor on every beat, *wiebelen* sends the hips one way and the shoulders the
other, *knikken* nods deep.

**Hands in the air is a pose, not an animation**, which is what keeps
`CONCEPT.md` §9.7 intact: each style builds its arms at a fixed angle and then
never touches them again, and what moves them is the body they are welded to. The
angle is written as *how far from straight up* — 0 is vertical, π/2 is out
sideways, π is hanging down — so a style's `raise` reads as how far from
hands-in-the-air it is. Six visibly different dances cost six closures rather
than six rigs.

The per-guest phase offset came **down** at the same time, from a sixth of a beat
to a twentieth. It had been carrying all the variety when every guest had the
same move; on top of six different moves the same offset reads as six guests who
cannot hear the music.

One thing the new bodies cost: at 62 mm wide against the old 30, **the DJ no
longer fitted between his booth and the wall** — his back would have been 9 mm
inside the plaster. The booth came forward 30 mm instead, because he has nowhere
to go and the room needs depth behind him. Their footprints overlap by 10 mm now,
which is a DJ standing *at* his decks rather than behind them.

### Four things the first look on device caught

All owner's calls, 2026-08-17, after the room was running in Xcode. Every one of
them is a case of the same thing: **an emissive surface loses its colour**, or a
number that was checked against the floor plan rather than against the screen.

**The mirror ball was a blob.** It was one 320-face icosphere painted a single
glowing cream, with six 7 mm squares stuck round the equator — at 60 mm across
that is a smooth pale ball with specks on it. `references/feest/discobal.png`
shows what it should be and always did: a **mosaic**, twelve by seven small quads,
each a different pale tone with a faint seam between them. It is built that way
now, one `ModelEntity` per tile, because one mesh can only have one material.

And **the tiles are matte**, which is the part worth keeping. The ball glowing is
exactly what made it featureless: an emissive surface goes above white and loses
its own hue, so twelve different tones came back as one. A mirror ball is not a
lamp — it is a matte thing that *throws* light, and what it throws is `ballSpots`
on the floor. A rotating handful of tiles lights on each beat, which is the
sparkle, and the other eighty are shaded by their facets like everything else.

**The cord ended in mid-air.** It stopped at y = 0.252, which is above the wall
tops and sounds like enough. It is not: at this eye and a 26° vertical FOV a point
over the ball only leaves the top of the frame at **y = 0.308**, so 56 mm of cord
was hanging inside the shot and the ball read as floating. It runs to 0.45 now —
far past what the arithmetic needs, because the frame edge moves with the viewport
aspect and a cord that is *just* out of shot is one iPad away from being back in.

**The dance floor was white.** Same arithmetic as the ball, on the largest surface
in the room: a pale pastel at `glowPeak` (2.34 emissive) is above white by the time
it is tonemapped, so all six colours came back identical. Two changes together fix
it and neither alone would — the intensity comes down to `FeestProps.floorGlow`
(0.85, a third of what the lamps use), and a tile lights in a **deep** colour
rather than a pale one, so there is chroma left to survive the exposure.

It is also **random now** rather than a stepping diagonal. The pattern was
legible, and after two beats you could see the rule — at which point it stopped
being a disco and became a screensaver. Every tile rolls for itself on every beat,
two in five lit. The one moment it is not random is a pad tap, which paints the
whole floor that pad's colour: that is the floor *answering her finger*, and an
answer that looked like noise would not read as an answer.

**There was one speaker, and a disco has two.** The second sits in the far corner
and is deliberately **scenery** — every position in that corner fails the screen
check against the mirror ball by 31–45 mm where two radii need 64, because the
ball hangs over the middle of the floor and the back-left corner is almost exactly
behind it along the view direction. Shrinking the ball's target to fit is the
wrong trade; it is a toy she has to be able to hit. So tapping the right-hand
stack thumps **both**, which is what a pair of speakers does anyway.

### The stutter, and it was two things

Owner, 2026-08-17: *"there is a very visible loop that stutters in everything
visible. the dancing; the rotating mirror ball, the dj etc. its as if the
computer can't keep up."*

It was not the computer. **The word that identified it is *loop*** — a periodic
hitch, not a low frame rate — and once you are looking for a period there are
only two clocks in the room to check.

**The beat was the period, and the cause was allocation.** Every beat the room
rebuilt every material it owns: 36 floor tiles, 84 mirror-ball tiles and 10 lamp
surfaces, so **130 `PhysicallyBasedMaterial`s constructed twice a second**.
Building one is not free and 130 in a single frame is a spike — landing, by
construction, exactly on the beat.

Two changes fix it and the second is the one that matters. Every material the
room can need is **built once at build time** — there are only six lit floor
colours, one lit ball colour and six lamp colours, so a few dozen materials cover
every state the room has. And each surface **remembers what it is wearing**, so a
beat assigns only to what changed: about fourteen floor tiles, twelve ball tiles,
and nothing at all on the lamps unless the colour stepped. The general form, and
it is not about discos: **a thing that changes on a beat should cost the change,
not the count.**

The same pass took the room from **120 near-duplicate meshes to 8**. Every floor
tile is the same box and every mirror-ball tile in a row is the same spherical
quad turned about Y, but `RoomBuilder.model` builds a fresh `MeshResource` per
call — so the obvious loop had handed the renderer 120 things it could not batch.

**The other clock was the game's own, and it is shared by all four rooms.**
`Ticker` ran on a `Timer` at 1/60 s. A timer is not synchronised to the screen
refresh, so its ticks drift against vsync and every second or so a frame gets two
or none — which looks like a regular hitch rather than a slow game. Three rooms
hid it because a kitchen is mostly still; a room where six dancers, a mirror ball,
two decks and thirty-six tiles all move at once did not.

It is a `CADisplayLink` in `.common` mode now. **The reason the timer was there
survives**: `ROOMS.md` §7 chose it so animation keeps running while a finger is
down, and `.common` is what buys that — a display link added the same way has the
same property. That was the requirement; the timer was one way of meeting it.

This is the one change in the room that reaches outside it, and it is worth
saying plainly: **it affects the kitchen, the garden and the decorating room
too.** Nothing about them changes except that their animation is now paced to the
display.

### The DJ has three sounds, and only one of them came from Higgsfield

Owner's call: *"when pressing the dj, it should rotate between dj-esque sounds. a
beat, a scratch, a vocal. but all with a kid theme. render that via higgsfield."*

Two of the three cannot come from Higgsfield, and it is worth writing down
because it was checked rather than assumed. `models_explore` lists `sonilo_music`
and `mirelo_text_to_audio` as **"Game pipeline only"** — they refuse standalone
use, exactly as `CONCEPT.md` §7.4 has said since the start. So a beat and a
scratch are `SoundKit`'s synthesised `trom` and `kras`, and **the vocal is the
part Higgsfield genuinely renders**, because a vocal is speech.

Five Dutch shouts — *"Handjes in de lucht!"*, *"Iedereen dansen!"* — in **Benji**,
the third voice in the game and the first that is neither Nina nor Otto. Young and
male, so a 4-year-old can tell all three apart without looking. Like Otto's
Barrett it was picked without an ear on it; `audio/voices.json` says so and
re-cutting all five costs 1.5 credits.

Tapping rotates beat → scratch → shout rather than picking at random, and that is
the one design decision in it. Three items picked at random means a one-in-three
chance of the same sound twice running, which on the most tapped prop in the room
reads as broken rather than as chance. The five shouts *within* the vocal do get
`VoiceBank`'s never-the-same-twice rule, for free. The beat is four hits of the
drum **at her own tempo**, so even the DJ's own sound is the beat she is making.

### The way out is the cake

**This room has no door**, and it is the only one that does not. §6.5 has always
said *she ends the party by tapping the cake; nothing else ends it*, and a door
standing open beside the cake would be a second ending — which in a room whose
whole point is that she decides when it is over is a contradiction rather than a
convenience.

So the cake carries the cue the door carries everywhere else: **lit from the
moment she arrives**, exactly as the decorating room's door is, because in a room
with no required action *you may finish when you like* is a true statement.
`refreshCakeInvitation` is `refreshDoorInvitation` under another name and is just
as nearly empty, which is the right shape — a room with nothing to gate on should
say so in the function that would have gated it.

Tapping it is the ending: everybody eats in three bites with the cake shrinking
under them, applause, confetti, and the friend of the day thanks her by name.
Then, because there is no bakery to go to, **the room lays out a fresh party
behind the celebration** — a new friend, a new cake — the way the kitchen starts
a fresh round behind its third cake. A room that ends with nowhere to go must not
end with nothing to do.

### The cake arrives decorated, and that is the handover working

The party is the first thing in the game to collect on the promise `Sticker` was
written for: *"the party and the wall can re-render the same cake later from the
spec alone, at their own scale and their own angle."* Every sticker she placed
and every ribbon she piped is rebuilt from polar anchors at **1.8×** instead of
the decorating room's 2.5×, and a candle she lit is still lit.

**Nothing was added to `CakeSpec` to get a cake across this doorway.**
`RoomExit.feest(CakeSpec)` carries the identical struct `.versieren` carries,
which is the tell that the contract was right. What it cost was three lines in
`VersierRoom.endRoom` — *"`endRoom()` is the one function the decorating room
replaces"* (`ROOMS.md` §9), and the party replaced this one in turn.

### Six guests and a DJ, and the screen is why

§6.5 used to ask for up to twelve guests, on the argument that the three-part rig
was chosen partly because twelve had to be affordable. **The rig was never what
stopped it.** Twelve targets that each need `CONCEPT.md` §5's ~120 pt inside a
0.46 m box is arithmetic that does not close whatever the rig costs.

So the room is laid out on the **X−Z diagonal**, which `RoomBox.screenSeparation`
says is the one direction that keeps all of its spacing at this camera: the six
pads on one line, the six guests on two short rows. The counts came out of that
rather than out of a frame-rate measurement, and twelve is still reachable the day
it is wanted — guests behind the front row can be scenery, since nothing on
screen has to be tappable.

The DJ is one of the eleven — whichever friend is *not* at the party today —
rather than a twelfth animal, because inventing one would quietly reopen
`GAMEPLAY.md` §1's decision that the twelfth frame is Nina's.

### `assertSpacing` earned its keep before the room ever ran

**This is the first room whose spacing check asserts on the screen distance
rather than warning about it**, and it caught seven overlaps in a layout that
looked fine on a floor plan.

Six were 0.1–0.7 mm short, all of them from the same wrong assumption:
`screenSeparation` takes its view direction through the **midpoint of the pair**,
not through the room's origin, so a row on the diagonal is exactly
screen-horizontal only where it crosses the middle of the room. At the ends of a
six-pad row it is a degree or so off. The pad pitch went from 64 mm to 65 and the
guest rows opened up a little.

The seventh was not a rounding error. **The speaker stack was 23 mm from a guest**
against the 60 it needed, while sitting 60 mm away from her on the floor — the gap
between them ran almost exactly along the view direction, so the speaker was
standing directly *behind* her on screen. Two more positions on the left wall
failed the same way against a different guest. It is now in the back-right corner
beside the booth.

None of that is visible in a screenshot and all of it would have shown up as taps
going to the wrong thing. `ROOMS.md` §5 — *do not let a new room ship in that
state; it is far cheaper before the props are placed than after* — is the whole
of the argument, and this room is the first to have followed it.

### The pads answer on the way down

Every other target in the game acts on `onTap`, which fires when she lifts her
finger. A pad acts on `onDragBegan`, which fires when she puts it down.

It is a one-word change and it is the only place in the game where the difference
is audible: a drum that sounds when you *stop* hitting it is a drum whose rhythm
is not yours, and this room is entirely about her rhythm. `onTap` is still wired
— it says what a pad is called.

### The six pads were not blocked after all

`CONCEPT.md` §7.4 lists "the dance party soundtrack and the six instrument pads"
as the one thing in the design blocked on an asset nobody has made, and
`GAMEPLAY.md` §9 says to start the music search *before* the room.

That was not done, and it turned out to be the right call rather than a corner
cut: five oscillators later the pads are `SoundKit` cases like every other effect
in the game — `trom`, `toeter`, `klap`, `fluit`, `kras`, plus the sixth borrowed
from the kitchen's `ding`, and `knabbel` and `applaus` for the ending. They are
honest placeholders and `SoundKit` still prefers a bundled file, so a CC0 pack
replaces them one at a time.

**What is still blocked is the party loop, and it is one asset rather than
seven.** The room also works in silence in a way a room waiting for a backing
track would not, because the beat is hers.

### The toys

Six, none of which gate anything: the mirror ball (spins up and throws light),
the confetti popper, the speaker stack (thumps, cones wobble), the DJ (scratches,
and his decks jump), a balloon that bobs away and comes back, and any guest, who
jumps.

**The booth has no target of its own.** It is entirely covered by the DJ standing
behind it, so a target for each would be two targets 30 mm apart needing 64 —
`ROOMS.md` §5's *"some props cannot have a naming target at all"*. Its word is
folded into the DJ's tap at the flour sack's ratio: mostly *the DJ*, one time in
four *the decks*. The **dance floor** is the same problem and gets the same
answer from the other end — sixteen tiles cannot each be a target, so its word
rides on a tap that lands on the empty floor.

### Deviations, and things worth knowing

- **No door**, and the cake instead. Above, and `ROOMS.md` §9.
- **Six guests, not twelve.** Above.
- **The friend of the day is dealt, not handed over**, because there is no hub to
  hand one over — the same answer the decorating room gives to a visit with no
  cake (`CakeSpec.dealt`).
- **The friends' thanks are relayed by Nina** — *"Pip zegt: dankjewel, Nina!"* —
  because eleven friend voices do not exist. `Friend.thanksLineID` is derived off
  the enum case, so casting them is a re-point rather than a rewrite.
- **`BakerCharacter` grew a `home:` argument.** It eased back to a hardcoded
  kitchen spot after a cheer, which is wrong in any room that places Nina by
  writing `root.position` afterwards. The party passes its own; the default is
  unchanged, so nothing else moved. **Versieren and De Tuin still have that latent
  bug** and the fix is one argument each — not made here, because this session's
  room is the party.
- **The mirror ball is a plain faceted sphere, not chrome.** A style with no
  reflections in it cannot have a mirror ball, so the *spots on the floor* do the
  work the mirror would have done. The regenerated finale plate did not carry the
  "no mirrored chrome" clause and came back with a silver ball, which is the one
  thing in that picture off the direction.
- **A beam is as long as its lamp is far away.** It was a constant 175 mm, which
  was right for none of the five: the back lamps are 251–282 mm from the spot they
  aim at and the two on the left wall are 291–294, so every beam stopped 75–120 mm
  above the floor and hung there like a stalactite. `FeestProps.lamp` derives the
  length from `simd_distance(origin, target)` now. What sells a beam is the pool
  at the end of it landing on something.

### What it owes

- **Music.** One loop. See above.
- **Eleven friend voices**, which is most of the game's remaining dialogue.
- **§6.6, the photograph and the wall**, which is what `nina.feest.muurKomt`
  promises *straks* rather than *now* — and which is now the last thing between
  four rooms and a game.

## What these four rooms may not conclude

Whether the *game* is fun. There is no bakery, no friend at the door and no wall
— and with four rooms and no hub, the chain between them is a door tapped at the
end of each one rather than something she chooses. What they can answer is
whether she can drive it: whether the snap radius and the target sizes are right,
whether stirring works with her hand, whether she can sweep a watering can across
five plants, whether a sticker lands where she meant it to, whether she can find
a beat, and whether she taps Otto again.

**Three rooms inherited every one of the kitchen's touch numbers on the argument
that the box and the chair have not moved.** That is a calculation, not an
observation, and it is now riding on four rooms instead of one — so the afternoon
with Nina is worth more than it was, not less.

**The party's three risky edits, named rather than hedged about.** It was written
in a container, and the record says the two kinds of change worth a second look
are a file move and a new call into main-actor code. This room made one of each
and one more: `VersierRoom.endRoom` gained a call into `onExit`,
`BakerCharacter` gained an argument now used from a fourth room, and
`Synth.render` gained seven cases to an exhaustive switch. Everything else is new
files nothing outside the room calls. [First build](#first-build) has what the
earlier ones caught and why those two categories are the ones on the list.

`POC.md` has the testing protocol, and it still applies: her iPad, Guided Access
on, you not helping and not narrating.
