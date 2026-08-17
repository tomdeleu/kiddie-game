# Building a room

What De Keuken established, stated once, so the next room does not have to be
reverse-engineered out of 2,447 lines of `KitchenRoom.swift`.

[`GAMEPLAY.md`](GAMEPLAY.md) says what each room is *for*. This says what a room
*is* — the box it stands in, the machinery it inherits, and the rules it has to
obey to feel like the same game. Everything here is shipped code, not a plan;
where a number appears, it is the number in the file, and the file is named.

**All three rooms have now compiled** — Xcode 26.6, twice on 2026-08-16. That is
worth knowing precisely, because of *what* the two builds caught: eight errors,
not one of which was a number. Every one was scope, actor isolation, or a type
turning out to be a struct. **So the constants in this file have survived two
compilers and the prose around them has not**, and the two edits that most need a
build behind them are moving a function between files and calling into anything
main-actor. `app/README.md`, "First build", has all eight.

What none of it has survived is **a 4-year-old**. Nothing here has been in front
of Nina, so every touch radius and every tolerance below is still a calculation.

> **De Tuin is built, and it is the first room built *against* this file rather
> than out of it.** Where it needed something this contract described as living
> inside `KitchenRoom`, that thing moved: §5's targets and §6's carrying are now
> `Engine/Surfaces.swift` and `Engine/CarryController.swift`, the door is
> `Props/Doorway.swift`, and a room is a `Room` the developer panel can switch
> between. Nothing in the *rules* changed; the addresses did, and they
> are updated below.

---

## 0. The shape of the thing

A room is one `@MainActor` class that owns entities, game state and a save file,
built into a scene the `RoomBuilder` puts up. It is not a scene graph somebody
walks around; it is a **stage seen from one fixed chair**, and almost everything
cheap about this project follows from the camera never moving.

| | |
|---|---|
| Room box | **0.46 m** across (`Layout.roomSize`), two walls and a floor on a slim slab |
| Walls | 0.235 m high, 0.012 m thick |
| Floor | `floorY = 0.004`, slab 0.014 thick |
| Camera | `CameraRig.eye = (0.636, 0.611, 0.636)`, looking at `(0, 0.06, 0)`, **26° vertical** FOV |
| Work surfaces | Horizontal rectangles, declared in `Layout` — the table at y = 0.072, the counter at 0.058 |

**Build the next room at the same box and the same eye.** Not because 0.46 is
sacred — it is 0.40 grown 15% because the kitchen ran out of floor — but because
the whole game is one continuous place, and a room that is a different size or
seen from a different chair is a different game with the same palette. If a room
genuinely needs more floor, move the walls and pull the eye back with them, and
then **rescale every touch radius by the same factor** (§5). That coupling is
the single easiest thing in this project to forget, and forgetting it is a
silent regression against the age rules.

Two walls and a floor is the whole set. There is no ceiling, no fourth wall, and
the open front edge is where her hands come in.

## 1. The step machine

A room's required action is a **sequence of named steps**, and the room is a
pure function of which step it is on. `KitchenStep` is the worked example:

```swift
enum KitchenStep: String, Codable {
    case uitrollen, vullen, roeren, gieten, inOven, bakken, klaar
}
```

Rules that make it work:

- **One `applyStep(animated:)`** rebuilds everything the step implies —
  interactivity, the halo, what Nina says, which props exist. Never let a step
  change be a scatter of edits at each call site; a room that can be entered
  from a save has to be able to arrive at any step cold.
- **The step is spelled in the room's own language.** Dutch case names are not
  decoration: the step is also the key into the voice script and the debug
  panel, and `vullen` is a shorter path to "what is she doing" than
  `fillingTheBowl`.
- **Nothing is gated by the step that does not have to be.** Ingredients could
  once only be taken in order; they now can be taken in any order and the step
  only decides what *glows*. A locked door with a nice sound on it is still a
  locked door.

## 2. The save file

One `Codable` struct per room, JSON in Application Support, written after every
step. `RoundState` / `RoundStore` is the pattern.

- **`var version = 1`, and every field added later is `Optional`.** `RoundState.used`
  is the worked example: the field did not exist in the previous build, so it is
  optional and `usedSlots` reconstructs exactly what the old shape meant. A save
  that fails to decode falls back to `.fresh()`, which loses her round — do not
  let that be the ordinary path.
- **The room is rebuilt from the struct, not restored into.** That is what makes
  it a save rather than a restore mechanism, and it is why interruptions are
  free (`GAMEPLAY.md` §7). If a room can only be resumed by replaying what she
  did, the struct is wrong.
- **The cake is the one thing that crosses rooms.** `CakeSpec` is the contract:
  decorating adds stickers to it, the party reads it, the frame stores it
  forever. Anything a room invents that another room needs belongs in there, not
  in the room's own save.

## 3. The halo — the game's only instruction

There is no text in this game and never will be, so **one lit object carries the
whole instruction.** `Engine/Halo.swift`.

- It is a **soft ring of light on the surface around the prop**, not on the prop.
  The object keeps its own colour entirely.
- It is on **from the moment a step begins**, not after a delay. "Which one do I
  pick up" is not a question she should have to be idle long enough to ask.
- It is a **sibling of the prop, not a child**, repositioned each frame at the
  prop's XZ on whatever surface is beneath it. That is what keeps it on the
  table while the prop is lifted off it, and most of what makes a held thing
  look held.
- **Every surface a prop can stand on must be known to the surface lookup, or
  the instruction points at the wrong place.** `surfaceY` knew about the table,
  the counter and the floor, so for the two ingredients on the wall shelves the
  halo landed on the floor **150 mm below the berry it was pointing at** — the
  game's only instruction, aimed at nothing, for two of the five fetching steps.
  `Layout.shelfSurfaceY` answers for the shelves and is height-gated so it can
  only ever match a prop actually up there. Add a room's surfaces to the lookup
  the moment you add the surface, not the moment something falls through it.
- **Exactly one thing is lit.** Two lit things is not an instruction. There are
  two sanctioned exceptions and both are true statements about the room: a
  **journey**, which lights the thing to pick up and the place it goes; and a
  room with **two right answers**, which the finished kitchen has (carry on
  baking, or leave). Never light two things for emphasis.
- **A journey with an interchangeable source is not a journey.** The garden's
  sowing step looks like one — pick a seed up, put it in a hole — and it gets a
  single halo, on the hole. Its two ends are not the same kind of thing: the
  destination is a fact, and the source is **her choice between eight equally
  right answers**. Lighting one jar says that jar is the one, which is false;
  lighting all eight is not an instruction. The rule generalises: **light the end
  that is a fact, and let the idle shimmer cover the end that is a choice** —
  which is also, exactly, where `GAMEPLAY.md` §6.2 puts the wish hint.
- **When *both* ends are a choice, nothing is lit at all.** The rule above has a
  floor, and `GAMEPLAY.md` §6.1's `kiezen` step is the first thing to reach it:
  she picks one of eleven grey ghosts off the wall, and there is no factual end
  anywhere in the step to put a halo on. So the step carries **no halo**, and the
  remaining ghosts shimmer on a slow rolling wave instead. That is not a hole in
  the contract — it is the contract read honestly. One lit ghost would say *that
  one is the answer*, which is false; eleven lit ghosts are not an instruction.
  **A step with no fact in it has nothing to point at, and pointing anyway is
  worse than not pointing.**
- **It disables nothing.** Every other prop still answers a tap while it is on.

### Do not re-derive the colour

This took four goes and the last one is the only one that works, so inherit it
rather than sampling a new one off a plate:

**The ring emits.** `Palette.lightMaterial` with `emissiveIntensity` above 1
lands the surface *above white* in the HDR buffer, somewhere a base colour
cannot reach — because a base colour is by definition a fraction of the light
falling on it. The colours are hot and pale (`#FFD44A` shoulders, `#FFF6C0`
core), both at or above the floor's own luminance, so the ring can only ever
brighten what it lies on. Emission falls off with the square of the profile
while opacity falls off linearly, so the centre glows and the edges fade into
the floor.

**And once it emitted, it had to get smaller** — which is the part that
generalises. Its proportions were tuned while it was *dim*, and a faint thing
needs area to be found at all: the band was 0.34 of the radius either side and
the ring a third wider than the prop it marked. A light does not need that. Band
down to **0.18**, ring down to **1.10** of the prop, so it sits just proud of
what it points at instead of hooping it. **Any cue that is retuned from dim to
bright wants less of everything, not the same amount brighter.** The sparkles
took up the slack: same colour as the ring, a third bigger, three at a time, and
emitting — `Sparkles.burst`'s `glow` parameter, which is off everywhere else.

The trap it kept falling into: **saturating a yellow darkens it.** A stronger
yellow was painted *darker* than the cream floor it was lying on, and the harder
it tried the dimmer it got. **Read a colour against the surface it will actually
lie on, and if it has to look like a light, make it one.** The one tuning lever
is `Halo.emissionPeak` (4.5); the geometry and the profile are right.

Eighteen concentric bands of geometry at graded opacities, not a texture — a
radial gradient needs `TextureResource`, a hand-built `CGImage`, UVs
`FacetedMesh` does not produce and an assumption about `UnlitMaterial` and alpha.
All four can fail on a first build, into a bright yellow square.

## 4. Voice

`Audio/VoiceBank.swift` plus one or more `script-*.json` files. **Every bundled
`script-*.json` is loaded automatically**, so a new room is a new file rather
than an edit to a shared one. Adding a line is a JSON entry and an mp3; no Swift
change.

### The files a room brings

| File | What is in it |
|---|---|
| `script-<room>.json` | The round: greetings, per-step nudges, reactions, the ending. 3–4 variants each. |
| `script-namen.json` | The naming layer — what each prop *is*. One variant each. |

### The rules

- **Ids are `character.category.thing`** and they are spelled once, in Swift,
  derived from an enum case wherever possible (`Ingredient.nameLineID` is
  `"nina.dit.\(rawValue)"`). A typo in a line id is a silent tap, which is the
  hardest kind of bug to notice in a game with no text.
- **Every id in the script is referenced from Swift; every id in Swift exists in
  the script.** The `_line_ids` block at the top of the script is where that
  contract is written down in prose.
- **Never the same variant twice running.** The previous pick is excluded
  outright rather than trusted to randomness.
- **Two priorities.** `.normal` interrupts — it is a reaction to something
  happening *this instant*. `.low` is dropped outright while anyone is speaking
  — idle nudges, toy chatter, and every naming line. A name can never talk over
  the instruction it would be explaining.
- **A step transition never uses bare `say`.** Nina must not be talked over: the
  line is held until she stops, *including through the quarter-second gaps
  inside a chain*, which a naive `isSpeaking` check reads as finished. Drop the
  last ingredient in, and 1.1 s later the next step used to talk straight
  through the four-second line about the ingredient.
- **Only one line can be waiting, and a newer one replaces it.** It is not a
  queue on purpose: three quick actions would earn a twelve-second monologue
  about things that had already happened. What she gets is the line playing now,
  then the most recent thing that is still true. Nothing blocks on it — the step
  has already changed and the halo has already moved — so the worst case is a
  dropped line, never a stalled game.
- **`sayInstead` for a step transition, `sayWhenQuiet` for an extra remark.**
  This is the distinction, and getting it wrong is the bug below. Both wait for
  the sentence in the air to finish; only `sayInstead` also **drops what was
  queued behind it**. A step transition means the room has moved on, so the
  queue — which is about where she just was — is no longer true. A reaction
  (a toy tapped, an ingredient named) is additional, so it joins.
- **A chain that contains an instruction takes `stillTrue`.** Every link is
  checked against it immediately before playing, not once at the start.
  `KitchenRoom.cakeIsReady` is the case: fourteen seconds of Otto, the colour,
  the effect and *"zet hem op de plank!"*, queued at the moment the plank
  becomes reachable. Its premise is `cake != nil` — a cake standing on the
  table — and putting it on the plank ends the chain wherever it had got to.

**The bug this cost, written down so the next room does not re-earn it**
(owner, 2026-08-16): `sayWhenQuiet` replaces the line *waiting*, and there was
no way at all to replace the ones *queued*. Finish a cake and carry it straight
up onto the plank — two seconds — and Nina worked through all fourteen seconds
of the out-of-the-oven chain, told you to put the cake on the plank it was
already on, and only then started the twelve seconds about having put it there.
The round did not reset until she stopped, some **twenty-four seconds** after
the last thing Nina did. Every symptom of it was in one missing verb: *this
replaces that*.

### Writing the lines

- **First person, always.** *"ik"*, *"we"* — Nina talks to the player the way a
  4-year-old narrates her own game, never as somebody instructing a child from
  outside.
- **Naming lines: name first, then one short thing about it.** *"Dit is de
  deegroller. Daarmee rol je het deeg lekker plat."* Never more than two
  clauses.
- **Write to a measured length.** Gracie reads Dutch at 15–17 characters a
  second, so a line's duration is predictable from its character count to within
  a few tenths. That is how the film's narration was fitted to its shots, and it
  is how any future timed line should be written — `audio/script-intro.json`
  carries the working budget.
- Casting and `voice_id`s live in `audio/voices.json`. **Never re-pick a voice
  casually**: the id is how a character survives across sessions.

Cost is **0.3 credits a line**, measured. Preflight a batch with `get_cost:
true` before generating.

## 5. Touch

`Engine/TouchRouter.swift`. One `DragGesture` with a zero minimum distance; a
press that travels less than **24 pt** (`tapSlop`) is a tap.

- **Targets are spheres, not meshes.** A prop registers a radius far bigger than
  itself, because `CONCEPT.md` §5 asks for ~120 pt hit areas and these props are
  nothing like that on screen. `TouchRouter.radius(points:)` converts, so
  registrations are written in points and the world-space number is derived.
- **Nearest centre wins**, so a big generous target never swallows a small one
  sitting on top of it.
- **A target's real size is measured on the screen, not on the ground**, and this
  is the one every layout in the project got wrong until the garden's second
  pass. `hitTest` measures the **perpendicular distance from a centre to the
  camera ray**, so what matters is separation *across the view*, not in XZ.
  A row running along X or Z is tilted about 37° away from the screen and keeps
  only **0.798** of its spacing; a row along the **X−Z diagonal** is exactly
  screen-horizontal and keeps **1.000** of it. The garden's flowers at 32 mm
  centres were giving each a 55 pt band against `CONCEPT.md` §5's ~120 pt, and
  the sum in XZ had looked fine.
  **And height counts as separation too, in the wrong direction**: a prop 85 mm
  in the air and 130 mm nearer the camera lands on nearly the same screen point
  as one on the ground behind it, which is how the garden's butterfly came to
  sit on top of two of the bed's five holes. Check a layout by perpendicular
  distance, and check the fliers.
  **`RoomBox.screenSeparation(_:_:)` is that measurement**, and it is what a
  spacing check must call. `RoomBox.distanceXZ` is still right for snapping — a
  drop is about where a prop lands — but it is the wrong question for *can she
  tell these two apart*.
  **Versieren was checked against this and does not pass.** Its
  `VersierLayout.assertSpacing` measures XZ, and all seven sticker trays run
  along an axis at a 64 mm pitch, so on screen they are 47–51 mm apart against a
  64 mm requirement; the two tools and the stool are the same story. That check
  now prints the perpendicular overlaps as well as asserting the XZ ones, and it
  **warns rather than asserts** on them deliberately: the room is built and on
  device, the fix is either an 85 mm pitch or a 24 mm radius — 60 pt, under
  `CONCEPT.md` §5's floor — and choosing between those needs someone who can see
  the screen. Do not let a new room ship in that state; it is far cheaper before
  the props are placed than after.
- **Overlap between like things in a row is intended; overlap between unlike
  things is a bug.** Five holes, eight jars, five flowers: nearest-wins gives
  each an equal band and an imprecise tap always lands on the nearest one, which
  is exactly what a generous row should do. What must not overlap is two targets
  that would give *different kinds of answer* — a toy taking the tap meant for a
  required action is the failure that matters.
- **Some props cannot have a naming target at all.** A large prop entirely
  covered by smaller ones — a bench under eight jars, a bed under five holes —
  loses every tap it is ever offered, wherever the marker is put. Fold its word
  into the things standing on it instead, at the flour sack's ratio: mostly the
  thing under her finger, now and then the thing it is standing on.
- **Entity-targeted gestures are deliberately not used.** `targetedToAnyEntity()`
  needs a `CollisionComponent` per prop and hits exactly the mesh; owning the ray
  keeps the generosity a number in one file rather than a shape on every entity.
- **A target can be switched off, and sometimes must be.** Two cases from the
  kitchen, both of which will recur: the spoon is disabled during stirring
  because it stands in the middle of the bowl and would win half the touches
  meant to make batter; the basket is disabled until its ingredient has gone
  because the token sits 12 mm above it, which from a fixed camera is the same
  point on screen.
- **A target can forward its drags to another prop.** The dough does: a grab near
  it picks up the rolling pin — which is what she meant — while a tap on it still
  gets to be a tap on the dough.
- **A tap on nothing sparkles under her finger.** Not optional. A screen that
  eats a tap silently is where she decides the iPad is broken.

**If the camera moves, every radius moves with it.** When the room grew 15% and
the eye pulled back 8%, every value in `registerTargets`, `registerToyTargets`,
`snapRadius` (0.067) and `plankSnapRadius` (0.067) was multiplied by 1.08. They
are world-space spheres satisfying a rule about the *screen*.

## 6. Carrying things

The hardest part of the kitchen, and it is solved — inherit it rather than
rediscovering it. **It is `Engine/CarryController.swift` and
`Engine/Surfaces.swift` now**, parameterised by each room's own rectangles,
because the garden needed every line of it and copying it would have been
copying the two bugs below as well.

A carried prop **rides just above whatever is underneath it** — table, counter,
floor — easing there over about a third of a second rather than snapping. Pick a
berry off the top shelf and it swoops down as she brings it to the bowl.

The whole model is two functions on `Surfaces`, and a room supplies its own:

- **`y(at:)`** — the room's rectangles, tested nearest-camera first. What is
  under a point.
- **`pointedAt(from:)`** — what the ray from her eye through her fingertip
  lands on first. **This is the one that decides the surface during a drag**, and
  it is a pure function of the touch that never looks at the prop.

**A room's one-off exceptions hang off the controller, and there are two hooks
because they are two different questions.** `pointedExtra` answers for a drag
(the kitchen's cake plank, reachable by one prop on one step); `restingExtra`
answers for the halo, which follows a prop rather than a finger. The garden needs
both and they disagree: its bed is a surface at its **rim** for a carried seed,
because the rim is what a seed would clip, and at its **soil** for the halo,
because the holes are sunk 10 mm below the rim and a ring floating over a hole is
a ring pointing at nothing.

That distinction is load-bearing and cost two failed attempts:

1. Re-projecting the drag onto a plane at the prop's *current* height each frame
   is a feedback loop — height depends on XZ, XZ depends on the plane — and at
   this camera moving the plane by Δ slides the intersection ~1.63Δ along the
   view direction. It made the cake impossible to put on the plank: it juddered
   between two surfaces.
2. Freezing the plane at pick-up killed the oscillation and left the prop
   sliding most of a thumb's width off her fingertip as it changed height.

Deciding the surface from the ray alone breaks the loop properly, so the prop's
XZ can be read off that same ray at whatever height it has eased to. **Nothing
in the chain points backwards.** It also makes losing a prop behind the table
impossible by construction: a hidden floor point is exactly one whose sightline
crosses the table top, and that sightline *is* this ray.

Two more rules:

- **Nothing gets put back.** A prop dropped somewhere that is not a target
  settles onto whatever is under it and stays. The rolling pin can live on the
  floor. The single exception is `isOutOfSight` — the patch of floor the fixed
  camera cannot see behind the furniture, derived from the camera and the table
  rather than hardcoded — where a drop floats home, because that is a place she
  could put something and genuinely not get it back.
- **Every tap is also a zero-length drag.** Without a "barely moved" check,
  poking the berry on the top shelf knocks it to the floor, because that is what
  is under a shelf.

## 7. Movement, and why there are no animation assets

`Engine/Ticker.swift` is the one clock. Every animation is a closure ticked from
it, returning `false` when it is finished.

It is used over `entity.move(to:)` because it is **interruptible** — and a
4-year-old interrupts everything — because it composes with game state so
nothing animates itself into a state the round has already left, and because
squash-and-stretch (`CONCEPT.md` §9.7) is three lines of maths rather than a
keyframe asset.

It runs on a run-loop timer in `.common` mode rather than on `SceneEvents.Update`,
which is load-bearing: it keeps ticking while a finger is down.

**`Ticker.Pose` exists because of a real bug and you will hit it again.** A
transform animation that "restores what it found" compounds when it is
retriggered mid-flight: Otto's blink squeezed an eye and restored it to whatever
scale that blink started from, so a second tap took the squeezed scale as the
new rest pose, and half a dozen pokes left his eyes as slits that never opened.
Anything that animates a transform and hands it back must either go through
`Pose` or keep its own rest value and **cancel the running job rather than fight
it frame by frame**.

Characters are `CONCEPT.md` §9.7's three-part rig: one solid body, two legs
pivoting at the hip, squash and stretch on the root. **Arms never articulate.**
A baker who stirs with her shoulders needs inverse kinematics; a baker who leans
her whole body over the bowl needs one rotation and a sine wave, and at this
scale it reads better.

## 8. Toys, idle, misses, restart

**Toys.** Four to six per room, none of which gate anything. One tap, one
animation, one sound each. They are what turn a corridor into a place and they
are individually near-free. Add one or two every time you touch a room.

**Idle** (`startIdleWatch`). After **25 s** the thing she needs shimmers
(`Ticker.shimmer` — distinct from the halo, which is on from the start). After
**45 s** Nina says one short line, alternating with *"I'm still here"* so she
never says the same thing twice running. After **105 s** it resets and may start
over. It never nags and it never blocks.

**Misses** (`noteMiss`). A miss is narrow: she dragged **the prop the current
step is about** and it did not land. Everything else is not a miss — a stray drag
of a rolling pin is a 4-year-old moving a rolling pin. Twice, Nina says something
kind. The **third** time she says the step's own line again at full priority and
the lit prop squashes while she does. Any success clears the counter, and the
counter resets on a step change.

**Restart.** One button, bottom-left, no text, same weight as the intro's skip
button. It puts the room **all the way back**, and Nina says so. **It must have
exactly one meaning.** The kitchen's used to keep the cakes on the plank, which
was right while the plank was a trophy shelf and stopped being right the moment
three cakes became what finishes the room — one button that means two things
depending on when it is pressed is a button a 4-year-old cannot use. A
confirmation dialog is not the fix; it is unreadable to her by definition. If
she presses it constantly, move it behind the parent gate.

## 9. Entering and leaving

`GAMEPLAY.md` §3 decided that a room can be entered two ways, and it is **one
flag, not two implementations**. The required action, the toys, the halo, the
voice and the save are identical. What differs:

| | **In a round** | **On a visit** |
|---|---|---|
| Arrived from | The previous room | The wall, or the bakery |
| Completion | The required action, once | The room's own rule — three cakes, in the kitchen |
| The door | Hands over to the next room | Ends the visit, back to the bakery |
| Nina's closing line | *"Nu gaan we hem versieren!"* | *"…de keuken is klaar — tik maar op de deur"* |

In the kitchen this is exactly two functions: `refreshDoorInvitation()`, which
decides whether the door is inviting, and `endRoom()`, which is what happens
when it is tapped. **`endRoom()` is the one function the decorating room
replaces** — and as of 2026-08-16 it has: the kitchen's swing is now the first
half of a handover, and the finished `CakeSpec` goes to Versieren on the beat
the leaf reaches full open.

The two rooms differ in one instructive way. The kitchen's door waits for three
cakes; **the decorating room's is inviting from the first frame**, because it
has no required action to wait for. `refreshDoorInvitation` still exists there
and is nearly empty, which is the right shape — a room with nothing to gate on
should say so in the function that would have gated it, not by deleting it.

> **And it stays inviting from the first frame even now that the room has a
> required action** (`GAMEPLAY.md` §6.4, decided 2026-08-17). That looks like a
> contradiction and is the whole point of the design: Versieren's steps
> **observe rather than gate**. They read what she has already done so Nina has
> something to answer; they never decide whether the door works. So
> `refreshDoorInvitation` stays nearly empty while `applyStep` grows — which is
> the shape to copy for any room that wants an arc without a gate. A step machine
> and a locked door are separate things, and only one of them is forbidden here.

### The door says it three ways at once

None of them a word or an arrow, because she cannot read one.

> **A room with no wall behind its way out says it twice.** De Tuin's exit is a
> gate in a picket fence: there is nothing behind it to light, and she can see
> straight through it already. It keeps the leaf off the latch and the ring at
> the threshold, and drops the middle one — owner's call, and
> `Props.Doorway.glow` is `Optional` to say so rather than being a hidden entity
> nobody assigns to. What partly stands in for it emits nothing at all: **a worn
> sandy path leading out through the gate**, which is how ground says somebody
> goes this way. Take the third cue as *required wherever it is possible*, not as
> a count.

- **the leaf comes off the latch** and rests ajar at 11° — the smallest angle
  that still shows a slice of the light behind it at this camera. The point is
  not to open the door; it is to say the door is *openable*.
- **the light behind it turns on**, emissive, so that slice is worth seeing.
  Unlit it read as the inside of a cupboard.
- **a ring lands on the floor at the threshold, concentric with the doorway** —
  and **its back half is inside the wall on purpose**. The wall is solid, so the
  buried part is simply occluded and what shows is a bright crescent hugging the
  threshold, which is what light through a doorway looks like. This one was got
  wrong twice in the same direction, 46 mm out and then 40, both times on the
  reasoning that a ring must not reach into the plaster; both times it read as
  *a disc of light near a door* rather than as light coming from one, and on the
  +X+Z diagonal it also sat visibly down and right of the door it belonged to.
  **The clipping was never the problem — pulling the cue off its object to avoid
  the clipping was.** Worth remembering for any cue that belongs to something
  standing against a wall.

**Never promise a room that does not exist**, and note this does not stop
applying once one of them does. The kitchen now says *"nu gaan we hem
versieren!"* — but only when there is a cake to take through; reach a finished
kitchen with an empty plank and it still says the careful thing. Versieren's own
door promises a party that is coming *straks*, because the party is not built.

With nowhere to go, the kitchen's ending was a ceremony — the leaf swings wide, light spills over the threshold, and
Nina says the next room is coming *soon* rather than *now*. A 4-year-old told she
is going somewhere and then not taken there has been lied to.

**Nothing is consumed by leaving.** The plank keeps her cakes and the leaf falls
back to ajar rather than shut, so the room stays finished and stays finishable.

## 10. Sound

`Audio/SoundKit.swift`. Every effect is **synthesised at launch** — a few hundred
lines of oscillators and envelopes rendered to PCM in milliseconds — because the
Higgsfield connector cannot supply SFX (`CONCEPT.md` §7.4) and a silent room is
not a room: the reward *is* the sound.

They are honest placeholders. **`SoundKit` prefers a bundled file over the
synth**, so when a CC0 pack arrives the swap is per-sound, one file at a time,
with no other edit. A new room should reuse the existing `Sound` cases wherever
it can and add cases only for genuinely new events.

## 11. What a new room owes

A checklist, in the order it is worth doing:

0. **Conformance to `Room`** (`Sources/Game/Room.swift`) and a case in `RoomID`,
   so it appears in the developer panel's room picker and can be visited without
   playing the game up to it. A handful of small members, of which only `leave()`
   has a trap: **a `Ticker` job a torn-down room still holds keeps animating a
   detached entity forever, and nothing on screen says so.** Every job id and
   every `Halo.Handle` goes in it — which is the same list a rebuild already
   needs, so write it once and call it from both. `GameScene` detaches the tree
   and clears the touch targets on its own side, so `leave()` owns the jobs, the
   save, and any `TouchRouter` callback the room set beyond its targets
   (`onEmptyTap`, `onAnyTouch`, `onMoved` — the garden's butterfly follows the
   last of those, and a stale one would follow her finger around the kitchen).
   **Ending is `onExit`**, not a jump: the room says what just happened —
   `RoomExit.keuken(basket)`, `.versieren(cake)`, `.bakkerij` — and hands back
   control. A room that knows what comes next is a routing table waiting to
   happen.
1. **A `Layout` block** — every position in one table, plus the room's own
   `Surfaces`. Almost every bug in a room like this is two files disagreeing
   about where the table top is.
2. **A step enum and a `Codable` state struct**, versioned, with `RoundStore`'s
   load/save/reset shape. **The step may be derived** — the garden's is a pure
   function of its bed, stored so the room can be entered cold and recomputed
   after every action so it can never disagree with what is on screen. A step
   that can be computed and is also stored independently is a second place for
   the truth to live.
3. **Props**, in `FacetedMesh` primitives. **Check Kenney's Food Kit and
   Furniture Kit first** — do not model what 340 CC0 models already provide. They
   arrive flat-shaded and hard-edged, which is the target shading model; they
   need a palette swap and nothing else.
4. **Targets** — registered in points, one function for the round's props and one
   for the toys.
5. **The halo**, on exactly one thing per step.
6. **`script-<room>.json`** and the room's slice of `script-namen.json`. Preflight
   the batch cost.
7. **Four to six toys.**
8. **Idle, misses, restart** — copy the kitchen's, tune nothing.
9. **The door**, in both modes.
10. **A line in `app/README.md`** saying what the room does and what it deviates
    from. That file is the record; a room that is not in it did not happen.

### And the traps, all of which have already been paid for once

- **A texture-less mesh has no UVs.** `FacetedMesh` writes none, so anything
  needing a texture is a `generatePlane` or it is geometry.
- **An `.xcassets` image set is looked up by set name, not filename.** A
  mismatched extension inside `Contents.json` compiles the set *empty*, the
  texture load returns nil, and the asset is silently absent. Nothing raises.
- **A missing asset must never leave a live tap target with nothing behind it.**
  `ModelLibrary` establishes the fallback rule; the portrait follows it.
- **Every element of a script's `lines` array must be a real line.** `VoiceBank`
  decodes them with a non-optional `{id, character, variants}` model, so one
  `{"_section": "…"}` marker slipped in for readability makes the **whole file**
  fail to decode — silently, into a room where every line in it is mute. Section
  notes go in `_why`.
- **`scaledToFill()` does not crop.** It reports its overflowed size as its
  layout size. A full-bleed view needs a `GeometryReader`, an explicit `frame`
  and `clipped()`, all three.
- **A cover that fades in is a peep-hole.** Every cover in the opening appears
  instantly and leaves with a fade; a crossfade between two of them showed the
  lit kitchen through the gap.
- **Hang timed audio off the picture, not off a stopwatch.** A line started on a
  timer has to absorb however long the player spent opening a file, and it
  routinely did not fit.
- **No ambient occlusion.** Shading comes from the facet normals and corners stay
  light. The two Blender props are the owner-sanctioned exception and their AO is
  baked to the facets, not to a texture — `models/README.md`.
- **Judge a cue on the device, not on a plate.** Three cues in, all three looked
  fine as renders and two of them failed on the iPad.
- **Size a surface from the widest thing that stands on it**, not from what
  looks right in elevation. The wall shelves were 14 mm deep under a 31 mm honey
  pot, so its contents overhung the front and pushed into the plaster at once.
- **`TouchRouter.register` appends.** Re-registering a name leaves both
  targets, and the second one still holds its entity and still wins hit tests.
  Harmless while every target is registered once in `build`; a leak per frame
  the moment a room registers one mid-round. `remove(prefixed:)` exists for
  exactly that.
- **A number two rooms depend on belongs to neither of them.** The cake's tier
  radii lived in `KitchenProps` and again in `models/cake.py`, which was fine
  until every sticker position in a second room derived from them. They are
  `CakeGeometry` now. The general form: the moment a constant crosses a room
  boundary, it stops being that room's.
- **Check spacing against the sum of the radii, not against a pitch.** Seven
  trays at a 64 mm pitch are correctly spaced from each other and 2 mm too close
  to the tools beside them, because the tools carry a larger radius.
  `VersierLayout.assertSpacing` is the cheap version of noticing.
- **A prop's resting height must be derived, never hand-typed.** The shelf
  ingredients hovered 10 mm above their plank from the day the shelves were
  built, because the jars took the plank's top and the ingredients took a
  number somebody wrote down. Against a wall it is nearly invisible, and
  impossible to unsee afterwards.
