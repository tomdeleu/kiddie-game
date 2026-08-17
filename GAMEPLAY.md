# Gameplay and storyline

The detailed design. [`CONCEPT.md`](CONCEPT.md) says what the game *is*; this
file says what actually happens, minute by minute, and what has to be built to
make it happen.

It exists because `CONCEPT.md` described a **loop**, not a game: four rooms, one
verb each, five minutes, then the identical thing again tomorrow. There was no
reason to stay in a room once its verb was done, and no reason to come back once
the novelty wore off. This file fixes both.

**No timers. No scores. No stars. Nothing counts anything.** The only number in
the entire design is twelve, and she experiences it as a wall with gaps in it.

> **De Keuken is built, and it is the reference implementation.** Everything
> below that describes the kitchen describes what actually shipped, not what was
> once intended. The machinery it established — the halo, the voice contract,
> the step machine, carrying, targets, idle, misses — is written down once in
> [`ROOMS.md`](ROOMS.md), which is what the next room is built against. Read
> that before writing a room; read this for what the room is *for*.

---

## 1. The story

Nina has a bakery. Her name is above the door.

It is not a *magic* bakery yet. Nina says so herself on the first launch: a
bakery becomes a real toverbakkerij when **twelve parties have been held
there**, and every party hangs in a frame on the wall. Right now the wall is
twelve empty frames. Eleven hold the faint grey outline of the friend still
waiting for their turn. **The twelfth is hers.**

So the game is: bake twelve cakes — eleven for friends, and the last one for
herself — and the wall fills up.

That is the whole story, and it is deliberately that thin. A 4-year-old does not
need a plot; she needs to know what she is doing and to see that she is getting
somewhere. The story's job is to make the wall mean something, and then get out
of the way.

**Nina is the baker, she is on screen, and the voice is hers.**

> **REVERSED, 2026-08-15, by the owner.** This section used to read: *"She has
> no avatar; she is the hands. Luna is her friend who lives in the bakery and
> helps."* Both halves are gone. **Nina is the character in
> `references/plates/02-fairy-character.png`** — the little fairy baker in the
> mint hat and apron — she stands behind the table and works while the round
> runs, and every line in the game is hers.
>
> What the old decision was protecting against: "nothing on screen can look
> 'not like her'". That risk is real and now accepted. What it buys is a
> kitchen with somebody in it, which is worth more than a kitchen that is
> technically un-wrong.
>
> The rig is unchanged and still cheap — `CONCEPT.md` §9.7's three parts, built
> in `app/.../BakerCharacter.swift`. Nothing was modelled or sculpted.

> **The twelfth frame is Nina's own — DECIDED, 2026-08-16, by the owner.**
> Removing Luna emptied two slots at once: the twelfth friend, and the gold
> frame that was hers. Rather than invent a twelfth animal to fill them, **the
> gold frame holds Nina**. Eleven friends have their party; the last cake is the
> one she makes for herself, in her own finished bakery, and the photo in the
> gold frame is her standing beside it.
>
> It is the better ending as well as the cheaper one. Eleven times a friend
> thanks her by name; the twelfth time there is nobody to thank her, because the
> bakery is the thing being finished and it is hers. The twelfth wish is
> therefore not a wish at all — see §4.
>
> Luna's name survives nowhere. Any text still describing a fairy who lives in
> the bakery is older than this file.

## 2. The wall is the game

The bakery's back wall holds **twelve frames in a 3×4 grid**, above the counter.
It is the first thing on screen when the game opens and the last thing before it
closes.

Each frame is in one of two states:

| State | Looks like | Tapping it |
|---|---|---|
| **Empty** | A pale grey silhouette of the friend who is waiting | Starts that friend's round |
| **Filled** | A little photo of that friend's party, in colour | Replays that party, ~20 seconds |

**The wall is therefore also the level select** — with no text, no menu, and no
new interface to learn. She points at a grey ghost and that friend's day begins.
She can do them in any order she likes.

The bottom-right frame is **larger and gold, and it is Nina's**. It stays grey
until the other eleven are in colour. It is the only thing in the game that
waits, and it is worth the exception: it gives the wall a shape and gives the
last cake a weight the other eleven cannot have.

### The sign above the door

A second progress display, for the times she is not looking at the wall. The
painted cake-and-star sign above the bakery door starts washed-out grey. Each
filled frame brings a little more colour and a little more glow into it. By
frame twelve it is fully lit and it hums.

No numbers, no bar, no percentage. She will notice it changed without being able
to say how.

### When the twelfth frame fills

Every friend she has met arrives at once. The wall glows, the sign lights fully,
confetti, and the longest piece of music in the game. Nina says the line the
whole thing has been building to — and because the twelfth cake is hers, it is
about the bakery rather than about a guest: *this is a real toverbakkerij now.*

**Then nothing locks.** The bakery stays open forever:

- The twelve frames are permanent. They are a trophy and they never change
  again.
- The **second wall of the room box** becomes the overflow gallery, holding her
  most recent twelve free-play cakes. The oldest quietly retires when a
  thirteenth arrives.
- In free play, a friend still turns up at the door with a wish, drawn at random
  from the eleven.
- Tapping the gold centre frame replays the finale.

The finale must not read as a door closing. She will want to bake again the next
morning, and finding the bakery shut would read as broken, not as finished.

### What opens the app — OPEN

The built app opens **title plate → film → the kitchen** (`app/README.md`, "The
opening"), and this section says the wall is the first thing on screen. Both
cannot be true once the bakery room exists, and the collision is a real one: the
film is fourteen seconds, and fourteen seconds between her and the wall *every
single launch* is fourteen seconds she will learn to skip.

The recommendation, not yet a decision: **title plate → film on first launch
only → the wall**, with the film moved behind the gold frame afterwards so it is
still somewhere rather than gone. `IntroMovie.isAvailable` is already the only
thing that decides whether the film plays, so this is one flag.

## 3. Anatomy of a round

One round — one cake, one friend, one frame — is the unit of play. Target
**11–12 minutes**, of which roughly seven are required and the rest is however
long she chooses to linger.

| Step | Where | Required time | Can stretch to |
|---|---|---|---|
| Pick a grey frame | Bakery | 0:30 | 2:00 |
| The friend arrives and wishes | Bakery door | 0:30 | 1:00 |
| Grow five ingredients | Garden | 3:00 | 8:00 |
| Roll, fill, stir, pour, bake | Kitchen | 3:00 | 7:00 |
| Decorate | Decorating | 3:00 | 12:00 |
| Party | Party | 2:30 | 10:00 |
| Photograph and hang | Bakery | 0:45 | 1:00 |
| **Total** | | **~13 min** | ~40 min |

The required column is what a child who taps straight through experiences. The
stretch column is what happens when she gets absorbed, which is the good
outcome. **The design must permit a forty-minute session without requiring
one** — so required actions stay short and every bit of depth is optional.

At one round a day, twelve rounds is roughly a fortnight to finish the game.

### Two ways into a room — DECIDED, 2026-08-16

The kitchen shipped as an **~11-minute self-contained sitting**: three cakes on
the plank, and only then does the door open. That is not what the table above
describes, and the owner's call is that **both are real**.

| | **A round** | **A visit** |
|---|---|---|
| Entered from | The previous room, mid-round | The wall, or the bakery floor |
| The room is about | One cake, for the friend of the day | The room's own verb, for its own sake |
| It ends when | The room's required action is done | Its own completion rule is met — three cakes, in the kitchen |
| The door leads to | The next room in the round | Back to the bakery |
| What is saved | The round in progress | The room's own state, and anything it produced |

Every room from here on therefore carries **a mode**, and it is one flag, not
two implementations: the required action, the toys, the halo, the voice and the
save are identical in both. What differs is the completion rule and what the
door does — which in the kitchen is already exactly two functions,
`refreshDoorInvitation()` and `endRoom()`. [`ROOMS.md`](ROOMS.md) §9 has the
contract.

The reason to keep the visit rather than delete it once rounds work: a 13-minute
round is a *sitting*, and there will be plenty of afternoons where she wants to
bake and nothing else. The kitchen is already the best room in the game to be
loose in. Taking that away to make the structure tidy would be trading something
she likes for something only the diagram cares about.

### The two verbs, and what each of them means

The entire game is **tap** and **drag-onto-something**. There is no third verb,
in any room, ever. Nothing new to learn after the first five minutes, which is
what makes rooms three and four cost a fraction of room one to build.

**They now mean different things, and that is new.** Until the kitchen shipped,
only one of them meant anything: a drag was the round, and a tap was a wobble
and a sound effect.

> **Drag to play. Tap to find out what a thing is called.**

Every prop in every room says **what it is** when tapped, in Dutch, in Nina's
voice — name first, then one short thing about it. The kitchen has twenty-one
such lines in `script-namen.json`; every room after it brings its own. It is the
cheapest content in the game and it is the only part that teaches her words.

The rules that hold it together are in [`ROOMS.md`](ROOMS.md) §4. The one worth
repeating here because it looks like a mistake: **naming lines have exactly one
variant each**, deliberately, where everything else in the game has three or
four. A character who repeats herself does not sound like a person, but a *name*
is a thing you learn by hearing it the same way twice.

## 4. The friends and their wishes

Before the garden, the friend of the day appears at the bakery door holding a
**wish card**: a single picture — a pink cloud, a glitter star, three candles.
They say what they love. Nina repeats it once in her own words.

The wish card then pins itself to the top corner of the screen and stays there
for the whole round. **Tapping it replays the line.** It is the only persistent
interface element in the game, and it carries no text.

**She cannot get the wish wrong.** If the cake matches, the friend goes
completely over the top at the party — a special move only they do — and says so
by name. If it does not match, they are exactly as delighted, in a different
line. There is no comparison, no "almost", no retry, and no sad face anywhere in
the game.

The wish is not a test. It is an answer to *"what shall I make today?"*, which
is a hard question for a 4-year-old to answer from nothing.

| # | Friend | Wish | Matches when |
|---|---|---|---|
| 1 | **Pip de muis** | heel veel sprinkles | ≥ 8 sprinkles on the cake |
| 2 | **Bella de vlinder** | roze | Cake colour includes pink |
| 3 | **Bas de beer** | geel, als honing | Cake colour includes yellow |
| 4 | **Kiki de kat** | glitter | Star sugar in the cake |
| 5 | **Bram de kikker** | groen | Cake colour includes green |
| 6 | **Bo de vogel** | blauw | Cake colour includes blue |
| 7 | **Wolkje het schaap** | hoog en wolkig | Cloud cream in the cake |
| 8 | **Mo de mol** | kaarsjes, want het is donker | ≥ 3 candles placed |
| 9 | **Roos de egel** | hartjes | ≥ 3 hearts placed |
| 10 | **Tobi de hond** | sterretjes | ≥ 3 stars placed |
| 11 | **Nel de slak** | twee kleuren door elkaar | ≥ 2 different colours |
| 12 | **Nina zelf** | — the gold frame — | Always |

Nel's wish is the shell on her back, and it is the one that teaches the mixing
system by accident.

**The twelfth is not a wish.** Nobody comes to the door on the last round;
there is nobody left to come. The bakery is finished and the cake is for the
bakery, so the wish card is empty and every cake matches, because there is no
brief to miss. Where the other eleven end with somebody thanking her by name,
this one ends with the wall.

All eleven friends are animals. Animals are cheaper than people in this style —
one base faceted body plus a swapped head and colour — and a 4-year-old reads
them instantly.

**Matching is a pure function of the finished `CakeSpec` plus its stickers**, and
it is evaluated once, at the party. Nothing anywhere else in the game looks at
it: not the garden's hint, not the kitchen, not the decorating room. See
[`ROOMS.md`](ROOMS.md) §2 for where the spec lives.

## 5. What makes a cake

Six seeds in the garden, **all available from the first round**. Nothing in this
game unlocks, and nothing is ever missing.

| Seed | Dutch | Gives the cake | Effect |
|---|---|---|---|
| Rainbow strawberry | regenboogaardbei | pink | — |
| Blueberry | toverbosbes | blue | — |
| Sun honey | zonnehoning | yellow | a soft glow |
| Magic clover | toverklaver | green | — |
| Cloud cream | wolkenroom | white | height — a tall fluffy cake |
| Star sugar | sterrensuiker | no colour at all | it sparkles |

### Five, not three — DECIDED, 2026-08-16

The basket holds **five**, and repeats are allowed. Five rainbow strawberries
make a very pink cake indeed.

It was three everywhere in this file, and the kitchen shipped with five because
three drags is not a middle of a round — it was over almost as soon as it began.
Five spreads the fetching across the whole room without adding a rule, since
every one of them is the same verb she already knows. The owner's call is that
five is now canon **everywhere**: the garden grows five, the basket holds five,
the kitchen fetches five from its five places.

Two consequences, both real:

- **The garden bed has five holes**, not three. That does not mean five times
  the watering: **the can waters whatever it passes over**, so one sweep across
  the bed advances every plant under it by a stage. Three sweeps ripens the
  whole bed, exactly as three passes ripened one plant. The rule is unchanged —
  a pass grows a plant a stage — it is only that a pass can cross five plants.
- **Every cake is now a rainbow cake, and that is a real loss.** Not "more
  likely" — *every* one. Five picks out of six ingredients means at least four
  coloured ones in every bowl, so three or more distinct colours is guaranteed
  and `.effen` and `.gemengd` — the one-colour and two-colour cakes in the table
  below — have become unreachable, along with the lines Nina has for each
  colour.

  It went that way for a reason unrelated to the count. The kitchen used to roll
  each slot independently, which gave about a **9%** chance of five different
  ingredients: two toverbosbessen and no toverklaver anywhere was the normal
  round, and the room was routinely sending her to two of its five places for
  the same thing. Dealing off a shuffled deck fixed that and took the cake
  variety with it. The trade was made deliberately — being sent twice for the
  same berry is a thing she notices every round, and which of four cake shapes
  she got is not.

  **It should be undone when the garden lands**, because the garden is what will
  fill the basket, and it can fill it with an interesting *three* rather than an
  exhaustive five. Dealing still guarantees no repeats at three, and one, two and
  three colours all become reachable again. The lever is
  `Layout.ingredientsPerRound`.

  > **The garden has landed, and this is now more pressing rather than less.**
  > It fills the basket for real — `RoomExit.keuken` hands it to the kitchen — and
  > it fills it with **whatever she chose**, repeats included, from eight jars.
  > So the arithmetic above is no longer the game's: five rainbow strawberries
  > are now a reachable, deliberate, very pink cake, and so is a bed of five
  > different things.
  >
  > What has *not* changed is that the bed has five holes because the basket
  > holds five. `GardenLayout.plotCount` follows `Layout.ingredientsPerRound`, so
  > the decision is still exactly one constant, the bed follows it, and
  > `GardenStore.load` already migrates a save whose bed is the wrong length.
  > **Still worth deciding before the friends are built.**

- **Four of the eleven wishes go automatic in the meantime.** Bella's *roze*,
  Bas's *geel*, Bram's *groen* and Bo's *blauw* all match when the cake's colour
  includes theirs, and a rainbow includes nearly everything; Nel's *twee kleuren
  door elkaar* matches too. Nothing breaks — §4 is explicit that a wish cannot
  be got wrong and that the celebration does not differ — but the wish stops
  being an answer to *"what shall I make today?"* if today's cake was going to
  match anyway. That is the strongest argument for putting the count back to
  three when the garden fills the basket, and it is worth deciding **before** the
  friends are built rather than after.

Colour resolves by how many *different* colours went in, whatever the count:

| Distinct colours in the basket | Cake comes out |
|---|---|
| None (e.g. five star sugars) | Cream-coloured, with the effects |
| One | That colour, deep and strong |
| Two | **Swirled**, both colours marbled together |
| Three or more | **Rainbow** |

**Three of those four rows are currently unreachable**, for the dealing reason
above. The rule is right and stays; what is wrong is the basket it is being fed.

Effects stack on top of colour and on each other: sparkle from star sugar, glow
from honey, height from cloud cream. A tall glowing sparkling rainbow cake is
reachable, and with five slots it is reachable *and* three-coloured, which it
was not before.

### The cake is a data structure, and it is already built

`CakeSpec` (`app/.../Game/CakeSpec.swift`) is the shipped contract, and
everything downstream reads it: decorating adds stickers to it, the party reads
it to know what the guests are eating, the frame stores it forever, and the wish
match is computed from it.

Three details in it that are easy to get wrong later:

- **Colours are in the order she added them**, not sorted. Two identical baskets
  stirred in a different order paint their tiers differently, which is what
  makes the cake hers.
- **The batter has its own colour**, a third value alongside the tier colours,
  because a tier colour is seen against a room and batter is seen against the
  inside of a cream bowl by somebody who is four. `app/README.md`, "The batter
  takes the colour", has the argument.
- **Star sugar changing nothing is the point of it.** "No colours" is a real
  outcome and must never be corrected into a default pink.

## 6. The rooms

Every room follows the same shape:

- **One required action**, which takes about two to three minutes and cannot be
  failed.
- **Four to six toys** that are always there, always respond, and gate nothing.
- **A big door**, always available, that leaves for the next room. It gains a
  soft glow once the required action is done, and it works before that too.

The toys are what turn a corridor into a place. They are also individually
trivial — most are one tap, one animation, one sound — so the depth is cheap.

**How a room is built is [`ROOMS.md`](ROOMS.md).** What each room is *for* is
below.

### 6.1 De Bakkerij — the hub

**Required:** tap a grey frame.

**Toys:** the shop bell above the door (ding, and Nina looks up); the cat asleep
on the counter (stretches, then resettles); the little radio (plays a loop,
tap again to stop); the window, which shows the actual time of day; **her own
drawings** pinned beside the wall of frames, which wobble and rustle when
tapped.

Two things make this room harder than it looks, and both are the wall:

- **It is the only room whose contents are saved state rather than props.**
  Twelve frames, each either a grey ghost or a photograph of a cake that no
  longer exists anywhere else. The photograph is a render of a stored
  `CakeSpec` + stickers, not a screenshot — a screenshot ties the wall to the
  resolution it was taken at and to whatever the camera was doing that day.
- **It is the room that has to survive being empty.** On first launch there is
  nothing in it, and a room with nothing in it has to still be worth standing
  in for the thirty seconds before she picks a frame. That is what the toys are
  for here, more than anywhere else.

### 6.2 De Tuin — the garden — **BUILT**

**Required:** plant, water, pick — **five** ingredients into the basket.

> **Built 2026-08-16.** [`app/README.md`](app/README.md), "De Tuin", is the
> record. Everything below is what shipped, with three exceptions recorded
> there: the shelf holds **eight** seeds rather than this section's six, because
> the kitchen deals eight and a garden that could not grow two of them would
> leave a hole; a full basket is the completion rule in **both** modes, because a
> sixth ingredient has nowhere to go; and the way out is the kitchen's door in
> the kitchen's place rather than a garden gate.
>
> The one thing worth reading here that the build sharpened: **the halo lights
> the hole, never a seed jar.** Sowing looks like a journey, and a journey may
> light both ends — but its two ends are not the same kind of thing. The
> destination is a fact; the source is her choice between eight equally right
> answers, and lighting one of them would be a lie. The jars get the shimmer,
> which is where this section already put the wish hint. `ROOMS.md` §3.

Six seed jars on a shelf. Drag a seed to any of **five** holes in the bed. Drag
the watering can across the bed: **each pass grows everything it crosses by one
stage, three passes and a plant is ripe.** Growth is driven by her hand, never
by a clock — there is no waiting in this game. Tap the ripe plant and it hops
into the basket.

She may leave with one ingredient or with five. Fewer is not worse; it is a
plainer cake, and the kitchen adapts — `Layout.ingredientsPerRound` is what
five means, and the kitchen lays its sources out from the basket it is handed.

**Toys:** wave the watering can in the air and it makes a rainbow; the flowers
along the edge chime in a scale when tapped, low to high, which is a quiet
rehearsal for the party pads; a molehill Mo pops out of; a butterfly that
follows her finger; a wide pond lying across the front of the lawn that splashes
when tapped — two puddles until the owner's call of 2026-08-16, and **nothing
else stands in it**; a bee that hums when chased.

**The hint:** when the wish is a colour, the matching seed jar shimmers very
slightly. It never blocks anything and there is no penalty for ignoring it.
Note that this is `Ticker.shimmer`, the *idle* cue — not the halo. The halo
belongs to the required action and the garden's required action is the bed.

### 6.3 De Keuken — the kitchen — **BUILT**

**Required:** roll the base, five ingredients into the bowl, stir, pour, bake,
and carry the cake up onto the plank.

This section is now a summary; [`app/README.md`](app/README.md) is the record.
The round, as shipped, is seven steps:

| Step | She does | It answers with |
|---|---|---|
| `uitrollen` | Rolls the ball of dough flat with the pin | It spreads, puffs flour, drops into the tin as a base |
| `vullen` | Fetches five ingredients, one from each of five places | A plop, sparkles in the ingredient's own colour, the batter changing, and Nina naming what it will do |
| `roeren` | Stirs with a finger | The wooden spoon follows her hand; the batter comes up to colour |
| `gieten` | Drags the bowl onto the tin | It tips, pours, goes back where it lives |
| `inOven` | Drags the tin to Otto | It slides in, the door shuts, Otto is delighted |
| `bakken` | Taps Otto | Four seconds of puffing, a rising ping, the cake in her colours |
| `klaar` | **Carries the cake up onto the plank** | It rises to shelf height, shrinks, lands beside the others — and the round is finished rather than swapped out |

Four things it established that were not in this file before, and that the next
rooms inherit:

- **The ingredients come from five places, not one basket** — the upper shelf,
  the lower shelf, a pot on the counter, the basket on the table, a crate on the
  floor. One basket on one table made the room a work surface; five places make
  her look up, along and down. **The order is a suggestion, never a gate**: the
  one she needs glows, but any of them can be taken at any time and any of them
  counts.
- **The round ends on the object it was about.** She carries the cake to the
  plank herself, rather than tapping something across the room and watching the
  cake fly there. Same verb as every other step.
- **Rolling is a required step**, not a toy. It only counts while the pin is
  actually over the dough, so waving it does nothing and going back and forth
  does everything.
- **Stirring bends to her hands.** Three full turns finishes it — *or twice as
  much scrubbing*, at half rate, because a 4-year-old who cannot yet draw a
  circle still has to be able to make batter.

**Toys:** the flour sack (a poof, and handprints that stay a while); the tap
(running water that fills the basin and drains); the scale (bounces and dings);
the six shelf jars (rattle); the crate; the rolling pin; and Otto, who says
something different every single time he is poked.

**Completion, in visit mode:** three cakes on the plank open the door. It is a
floor, not a quota — a fresh round still starts, and three cakes *open* the
door rather than closing the kitchen. `KitchenRoom.endRoom()` is the one
function the decorating room replaces.

**Deviations from this file, all deliberate and all recorded in
`app/README.md`:** the room box is 0.46 m rather than 0.40 m with the camera 8%
further back, the doorway leads nowhere yet, and the palette gained a blue, an
amber and a lilac the locked thirteen do not contain.

### 6.4 Versieren — decorating — **BUILT**

**Required:** nothing. The door works immediately. This is the room she will
spend the most time in and it must never ask her for anything.

The cake sits on a turntable with a big handle; dragging the handle turns it.
Trays around the edge hold sprinkles, candles, hearts, stars, crowns, fruit and
cream swirls. Drag a sticker anywhere on the cake and it stays where she put it.
No grid, no snapping, no correct answer, no limit on how many.

Two tools that are not stickers:

- **The piping bag** draws a line of cream that follows her finger as she drags.
- **The sprinkle shaker** rains sprinkles wherever she drags it over the cake.

Tapping a placed candle lights it. Tapping a placed sticker makes it wiggle.
Dragging one off the edge of the cake removes it.

**The hint:** when the wish is a decoration, that tray shimmers.

#### What this room needs that does not exist yet

This is the first room that cannot be built out of the kitchen's parts alone.
Four things are genuinely new, and they are the whole cost of it:

- **A drop point on a curved surface.** Everything in the kitchen lands on one
  of four horizontal rectangles (`Layout.surfaceY`), and a cake is a stack of
  cylinders. A sticker has to land *on the cake where she pointed*, which is the
  first ray-versus-solid test in the game. Do it analytically against the tier
  cylinders and the top discs, not with `CollisionComponent` — the same
  reasoning as `CameraRig`'s "why not `targetedToAnyEntity()`": owning the ray
  is what keeps the generosity a number rather than a shape on every entity.
- **Sticker storage in cake-local polar coordinates** — tier, angle, height —
  so that turning the turntable is free, and so the party and the wall can
  re-render the same cake later from the spec alone. `CakeSpec` grows a
  `stickers: [Sticker]` array and nothing else changes. Screen-space or
  world-space positions would tie a permanent trophy to one camera and one
  turntable angle.
- **A stroke primitive** for the piping bag: a drag is a list of points, and
  cream is a ribbon of small faceted segments laid along them. It is the one
  thing in the game where the number of entities is decided by how long she
  drags, so it needs a cap — and the cap has to read as the bag running out
  rather than as the game refusing her.
- **A room whose halo has nothing to point at.** The kitchen's grammar is *one
  lit prop, which is the next thing to do*, and a room with no required action
  breaks it. The answer is not to invent a required action. It is: **the door is
  lit from the moment she arrives**, and the wish tray shimmers. Lighting the
  exit in a room with no task is the honest use of the cue — it says *you may go
  when you like*, which is exactly true here and nowhere else.

#### What it owes

Roughly fifteen naming lines (the trays, the two tools, the turntable, the
cake); eight or so reaction lines (a sticker placed, the first candle lit, the
tenth sprinkle, the cake turned all the way round); the room's own idle nudge —
which must be *"it is lovely, shall we go?"* rather than an instruction, since
there is nothing she is failing to do.

**Completion in round mode** is the door, whenever she likes.

**Visit mode exists — DECIDED, 2026-08-16.** This file's own lean was that it
should not, on the grounds that decorating with no cake in front of her is not a
thing. The owner's call went the other way, and the reasoning is that the
missing cake is a thing to supply rather than a reason to refuse her the room:
entering on a visit **deals a cake** off the same shuffled deck the kitchen
uses. The completion rule is the door, exactly as in a round.

That also made the debug room switcher and visit mode one code path instead of
two, which is the tell that it was the right shape: entering the room with no
cake handed over *is* a visit.

### 6.5 Het Feest — the party

**Required:** nothing, until she decides it is over.

The cake is already on the table when she arrives, and the friend of the day is
already there with everyone she has baked for so far. **Six big pads along the
open front edge**, one per instrument. Whatever she taps, the guests dance to —
the animation clock follows the beat she is actually making, so it is her rhythm
they are dancing to, not a recording.

**She ends the party by tapping the cake.** Nothing else ends it. There is no
timer, no song that finishes, no fairy telling her it is time. When she taps it,
everyone eats with enormous crunching noises, applauds, and the friend of the
day thanks her **by name** — with their special move if the wish matched.

Putting the ending on a tap matters for two reasons. It is the only real
authority she has in the game, and it gives a parent a visible, honest "when you
tap the cake, we're done" — which is what makes *nog één keer* actually work at
bedtime.

**Toys:** the disco ball; a confetti popper; the lanterns; any guest, who jumps
when tapped; a balloon that bobs away and comes back.

#### What this room needs that does not exist yet

- **A beat taken from her hands.** The dancing follows the interval between her
  own taps — a running average, floored and capped so that two taps a second
  apart do not put the guests into slow motion and a burst does not shake them
  apart. It is the party's whole idea and it is about thirty lines: a tap
  timestamp, an interval, and `Ticker` jobs whose period is read from it rather
  than fixed.
- **The first room with more than one character in it.** Up to twelve, on
  `CONCEPT.md` §9.7's three-part rig, which is the rig's real test: it was
  chosen partly because twelve of them have to be affordable. If it is not, the
  fix is fewer guests on screen rather than a better rig.
- **Per-friend voice.** Eleven friends × 6–8 lines is most of the game's
  remaining dialogue, and none of it is written. Four voices at different
  pitches, assigned so no two friends at the same party sound alike — the
  assignment goes in `audio/voices.json` as it is decided.
- **Music that does not exist.** The party is the payoff and it is currently
  silent in every sense: `CONCEPT.md` §7.4 records that the connector cannot
  supply music or SFX, so the six instrument pads and the party loop come from
  GarageBand or a CC0 pack. **This is the one thing in the whole design that is
  blocked on an asset nobody has made yet**, and it is worth starting before the
  room is.

**Completion in round mode** is tapping the cake, which hands over to §6.6. In
visit mode — replaying a filled frame — it is the same tap, and it hands back to
the wall.

### 6.6 Hanging the frame

A flash, and a photo of her cake with the friend beside it slides into their
frame on the wall. The grey ghost is gone. The frame glows for a moment, the
sign above the door brightens a shade, and the curtain closes.

**This is the ending of a session**, and it is deliberately the most complete
moment in the game. `CONCEPT.md` §5 asks for a clear ending; this is it.

The kitchen's plank is the rehearsal for this and it went in already: she
carries the finished cake up onto the shelf herself. Whether the photograph
should also be something she *does* — carry the frame to the wall — or something
that happens to her, is open. The argument for doing it is the plank's own
argument. The argument against is that the round has just ended and she has done
enough.

## 7. Rules that hold in every room

| Rule | How it works |
|---|---|
| **Nothing is driven by a clock** | Growth, baking and the party all advance on her actions. The word "wait" does not appear in the design. |
| **The door always works** | Even mid-task. She can leave the kitchen with an unbaked cake; the cake waits for her. |
| **Idle is nudged, never forced** | After ~25 s of nothing, the object she needs shimmers. After ~45 s, Nina says one short line — alternating with *"I'm still here"* so she never says the same thing twice running. Then it goes quiet for a minute. It never nags. |
| **Every tap does something** | If it is on screen, it responds. A dead tap reads as a broken iPad. A tap on **nothing** puts a sparkle under her finger. |
| **A tap on a prop says its name** | Drag to play, tap to learn the word. §3, and [`ROOMS.md`](ROOMS.md) §4. |
| **A wrong drag is not wrong, and it is not undone** | A prop she drags somewhere that is not a target **settles there and stays**. The rolling pin can live on the floor. No buzzer, no red, no *"nee"*, and no floating home — see below. |
| **Three misses bring the instruction back** | A miss means something narrow: she dragged the prop the current step is about and it did not land. Twice, Nina says something kind. The third time she says the step's own line again, at full priority, and the lit prop squashes while she does. She cannot read a reminder; this is the only way one can reach her. |
| **Interruptions are free** | The round saves after every step. Closing the app in the middle of stirring resumes in the kitchen, mid-stir, with the same batter. |
| **Hints shimmer, never block** | The object she needs **glows from the moment a step begins** — a soft ring of light on the surface around it. "Which one do I pick up" is not a question she should have to be idle long enough to ask. The 25-second shimmer sits on top of that for when she stops entirely. Nothing is ever disabled. |
| **One thing is lit at a time** | Exactly one prop carries the halo, because two is not an instruction. The single exception is a **journey** — a thing to pick up and a place to put it — which lights both ends, and a **room with two right answers**, which the finished kitchen has. Both exceptions are true statements about the room; neither is decoration. |

> **The "floats gently back" rule was reversed by the build, on purpose.** This
> table used to say a wrong drag floats home with a soft sound and Nina
> apologises. That was wrong twice: it undid the one thing she can do with a
> room full of objects, and it treated every stray drag as a failed attempt when
> most of them are a 4-year-old moving a rolling pin because it is a rolling
> pin. Exactly one thing still floats home: a drop into the patch of floor the
> camera cannot see behind the table, which is a place she could put something
> and genuinely not get it back.

## 8. What this costs to build

The gameplay above is mostly reuse. What it genuinely adds over `CONCEPT.md`:

| Thing | Amount | Notes |
|---|---|---|
| Friend characters | 11 | One base faceted body, swapped head and colour. Three-part rig from §9.7 — they only need to dance and jump. |
| Wish cards | 11 | Flat icons. Trivial. |
| Room toys | ~28 | One tap, one animation, one sound each. Individually near-free; collectively this is what makes the game. Seven are built. |
| Seeds and their grown forms | 6 × 3 stages | The garden's only real asset load. The six ingredients themselves are built. |
| Sticker types | 7 trays | Kenney's Food Kit covers most of it. |
| Cake variants | 0 extra | Tint, two particle flags, one scale. All from one mesh. Built. |
| Voice lines | ~260 files | See below. |

### Voice lines

A line costs **0.3 credits**, measured — not the 0.15 the older estimates
assumed. The kitchen is the calibration: 46 line ids across 86 files came to
~26 credits, and its 21 naming lines came to 6.3.

| | Line ids | Rough credits |
|---|---|---|
| De Keuken — **done** | 47 + 21 names | ~32 |
| The opening film — **done** | 3 | ~1 |
| Versieren — **done** | 12 + 15 names | ~11 |
| De Tuin — **done** | 17 + 15 names | ~16 |
| Het Feest | ~10 + ~10 names | ~10 |
| De Bakkerij | ~10 + ~10 names | ~10 |
| Eleven friends × 6–8 | ~80 | ~24 |
| The finale | ~4 | ~2 |
| **Whole game** | | **~105 credits** |

The number that moved is the naming layer — it did not exist when this file was
written and it is now roughly a third of every room's dialogue. It is also the
cheapest third: one variant each, and a room's naming script can be generated in
one batch the day its props are finished.

At that price it is still **cheap enough to write more variants than a recorded
game could afford.** Nina should have four or five ways to say everything she
says often, or she will sound like a lift announcement by round three. The one
place that rule is deliberately broken is the naming lines.

Casting still needed: confirming Otto by ear, and four voices for eleven
friends. Record the assignment in [`audio/voices.json`](audio/voices.json) as it
is decided.

### What has to be saved

The kitchen shipped **one `Codable` struct per room**, in JSON in Application
Support, rather than the single game-wide struct `CONCEPT.md` §10 imagined —
because a room's state is only ever read by that room, and one file per room
means adding a room cannot corrupt another one's save. What the wall needs is
game-wide and gets its own:

- **Per room:** whatever that room is in the middle of. `RoundState` is the
  worked example: the basket, what has gone in the bowl, which slots are used,
  the stir and roll fractions, the step, and the cakes on the plank.
- **Game-wide:** the twelve frames — for each, whether it is filled, and if so
  the `CakeSpec` (ingredients, colour, effects, sticker positions), whether the
  wish matched, and when; the round in progress (which friend, which room);
  whether the finale has played; and the free-play overflow gallery.

**Every saved struct carries a `version` and every field added later is
optional.** `RoundState.used` is the pattern: a save written by the previous
build still loads, and the accessor reconstructs what the old shape meant.
Getting this wrong costs a child her wall.

## 9. What this changes in the build order

`CONCEPT.md` §8 still holds — the POC comes first and this file changes nothing
about it. After that:

1. ~~**Kitchen**~~ — **built**. See [`app/README.md`](app/README.md). The basket
   is five ingredients dealt off a shuffled deck until the garden fills it, the finished cake goes on a
   plank on the back wall instead of into a frame, and the door ends the room
   instead of leading anywhere.
2. **Test the kitchen with Nina.** `POC.md` has the protocol. What it says about
   the snap radius and the target sizes is the thing worth knowing **before**
   another room is built on the same numbers — the room grew 15% and the camera
   pulled back 8%, and every touch radius was scaled to compensate. That
   compensation is a calculation, not an observation, and one afternoon turns it
   into an observation.
3. ~~**Decorating**~~ — **built**, 2026-08-16. `KitchenRoom.endRoom()` was
   indeed the single function that changed, and the kitchen's door now hands its
   finished `CakeSpec` over. What it cost beyond the room itself was the seam:
   one `Room` protocol, the box split out of the kitchen's `Layout`, and a
   debug room switcher behind the existing parent gate. See
   [`app/README.md`](app/README.md).
4. **The party**, so a round has an ending. Start the music search before the
   room — it is the only genuinely blocked dependency in the project.
5. **The wall** — twelve frames, the grey ghosts, the level select, and
   persistence. This moves *up*: it is not a reward system bolted on later, it
   is the thing that makes the game a game, and everything else hangs off it.
6. ~~**The garden**~~ — **built**, 2026-08-16, out of order. See
   [`app/README.md`](app/README.md), "De Tuin". It came before decorating and the
   party because two of its three costs were not the garden at all: **carrying,
   extracted** into `Engine/CarryController.swift` and `Engine/Surfaces.swift`
   where every later room can have it, and **a room switcher**, without which
   checking anything in a room is a five-minute walk through the ones before it.
   Both get cheaper the earlier they happen and neither is any use with one room.
   It also closes the loop it was always going to: the basket it fills is the
   basket the kitchen bakes.
7. **The friends and the wishes** — eleven of them, added one at a time. This is
   content, not engineering, and it can grow after she is already playing.
8. **The toys**, continuously. Add one or two every time you touch a room. This
   is the cheapest quality in the whole project.
9. **Final voice-over**, once the dialogue has settled.

Step 5 moving up is the substantive change. Build it as soon as a round can be
completed, because until the wall exists there is no reason for a second round.

## 10. Still open

- **Otto's voice — one listen away.** He is provisionally Barrett and already
  says all fourteen of his kitchen lines, but the pick was made without an ear
  on it. Five auditions are in [`audio/auditions/`](audio/auditions/); playing
  them takes a minute and re-cutting him costs four credits.
- **The four friend voices.**
- **Music, and the sound effects.** Six instrument pads and a party loop, from
  GarageBand or a CC0 library — `CONCEPT.md` §7.4. The kitchen's effects are
  **synthesised at launch** as a stopgap; a bought or CC0 pack replaces them one
  file at a time, and `SoundKit` already prefers a bundled file over the synth.
- **What opens the app**, now that the film and the wall both claim the first
  screen — §2.
- **Whether the basket goes back to three when the garden fills it** — §5. Five
  dealt from six makes every cake a rainbow and four of the eleven wishes
  automatic. Decide before the friends are built.
- **Whether hanging the frame is something she does or something that happens** —
  §6.6.
- **Whether the eleven friends are the right eleven.** They are cheap to change
  now and expensive once modelled.
- **Whether replaying a filled frame should be a full party or a short clip.**
  Twenty seconds is the guess; watch what she does with it.
