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

---

## 1. The story

Nina has a bakery. Her name is above the door.

It is not a *magic* bakery yet. The fairy who lives there — **Luna** — explains
it on the first launch: a bakery becomes a real toverbakkerij when **twelve
friends have had their party there**, and every party hangs in a frame on the
wall. Right now the wall is twelve empty frames, and in each empty frame is the
faint grey outline of the friend still waiting for their turn.

So the game is: bake twelve cakes for twelve friends, and the wall fills up.

That is the whole story, and it is deliberately that thin. A 4-year-old does not
need a plot; she needs to know what she is doing and to see that she is getting
somewhere. The story's job is to make the wall mean something, and then get out
of the way.

> **Luna — DECIDED.** She needed a name Nina can say and ask for, that survives
> every language the way *Nina* does. Luna is LOO-nah in Dutch, English, Spanish,
> Italian and German alike, with no vowel that shifts; it is clearly distinct
> from *Nina* in sound, which matters because the two names sit next to each
> other in most of the dialogue; and it collides with no friend below.
>
> It also means *moon*, so the magic association arrives free. Use it lightly —
> a crescent on her wand, a moon motif on the gold frame — and nowhere near the
> story, which stays about the wall.

**Nina is the baker, and she is on screen.**

> **REVERSED, 2026-08-15, by the owner.** This section used to read: *"She has
> no avatar; she is the hands. Luna is her friend who lives in the bakery and
> helps."* Both halves are now gone. **Nina is the character in
> `references/plates/02-fairy-character.png`** — the little fairy baker in the
> mint hat and apron — she stands behind the table and works while the round
> runs, and **the voice is hers**. Luna does not exist.
>
> What the old decision was protecting against: "nothing on screen can look
> 'not like her'". That risk is real and now accepted. What it buys is a
> kitchen with somebody in it, which is worth more than a kitchen that is
> technically un-wrong.
>
> The rig is unchanged and still cheap — `CONCEPT.md` §9.7's three parts, built
> in `app/.../BakerCharacter.swift`. Nothing was modelled or sculpted.
>
> **What this leaves open:** the twelfth frame on the wall was Luna's, and the
> twelfth friend was Luna. That slot now has nobody in it. It needs either a
> new twelfth friend or a reason for the gold frame to be Nina's own — free to
> decide now, expensive once the wall is built.

## 2. The wall is the game

The bakery's back wall holds **twelve frames in a 3×4 grid**, above the counter.
It is the first thing on screen at launch and the last thing before the game
closes.

Each frame is in one of two states:

| State | Looks like | Tapping it |
|---|---|---|
| **Empty** | A pale grey silhouette of the friend who is waiting | Starts that friend's round |
| **Filled** | A little photo of that friend's party, in colour | Replays that party, ~20 seconds |

**The wall is therefore also the level select** — with no text, no menu, and no
new interface to learn. She points at a grey ghost and that friend's day begins.
She can do them in any order she likes.

The bottom-right frame is **larger and gold**. It is Luna's, and it stays grey
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
confetti, and the longest piece of music in the game. Luna says the line the
whole thing has been building to, using her name.

**Then nothing locks.** The bakery stays open forever:

- The twelve frames are permanent. They are a trophy and they never change
  again.
- The **second wall of the room box** becomes the overflow gallery, holding her
  most recent twelve free-play cakes. The oldest quietly retires when a
  thirteenth arrives.
- In free play, a friend still turns up at the door with a wish, drawn at random
  from the twelve.
- Tapping the gold centre frame replays the finale.

The finale must not read as a door closing. She will want to bake again the next
morning, and finding the bakery shut would read as broken, not as finished.

## 3. Anatomy of a round

One round — one cake, one friend, one frame — is the unit of play. Target
**11–12 minutes**, of which roughly seven are required and the rest is however
long she chooses to linger.

| Step | Where | Required time | Can stretch to |
|---|---|---|---|
| Pick a grey frame | Bakery | 0:30 | 2:00 |
| The friend arrives and wishes | Bakery door | 0:30 | 1:00 |
| Grow three ingredients | Garden | 2:30 | 8:00 |
| Mix, pour, bake | Kitchen | 2:30 | 7:00 |
| Decorate | Decorating | 3:00 | 12:00 |
| Party | Party | 2:30 | 10:00 |
| Photograph and hang | Bakery | 0:45 | 1:00 |
| **Total** | | **~12 min** | ~40 min |

The required column is what a child who taps straight through experiences. The
stretch column is what happens when she gets absorbed, which is the good
outcome. **The design must permit a forty-minute session without requiring
one** — so required actions stay short and every bit of depth is optional.

At one round a day, twelve rounds is roughly a fortnight to finish the game.

### The two verbs

The entire game is **tap** and **drag-onto-something**. There is no third verb,
in any room, ever. Nothing new to learn after the first five minutes, which is
what makes rooms three and four cost a fraction of room one to build.

## 4. The friends and their wishes

Before the garden, the friend of the day appears at the bakery door holding a
**wish card**: a single picture — a pink cloud, a glitter star, three candles.
They say what they love. Luna repeats it once in her own words.

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
| 12 | **Luna de fee** | *"maak maar wat jíj het mooiste vindt"* | Always |

Nel's wish is the shell on her back, and it is the one that teaches the mixing
system by accident. Luna asking for nothing is the point of Luna: she is the
only one who trusts Nina completely, and hers is the last cake.

Eleven of the twelve are animals. Animals are cheaper than people in this style
— one base faceted body plus a swapped head and colour — and a 4-year-old reads
them instantly.

## 5. What makes a cake

Six seeds in the garden, **all available from the first round**. Nothing in this
game unlocks, and nothing is ever missing.

| Seed | Dutch | Gives the cake |
|---|---|---|
| Rainbow strawberry | regenboogaardbei | pink |
| Blueberry | toverbosbes | blue |
| Sun honey | zonnehoning | yellow, and a soft glow |
| Magic clover | toverklaver | green |
| Cloud cream | wolkenroom | white, and height — a tall fluffy cake |
| Star sugar | sterrensuiker | no colour, but it sparkles |

The basket holds **three**, and repeats are allowed. Three rainbow strawberries
make a very pink cake indeed.

Colour resolves by how many *different* colours went in:

| Colours in the basket | Cake comes out |
|---|---|
| None (e.g. three star sugars) | Cream-coloured, with the effects |
| All the same | That colour, deep and strong |
| Two different | **Swirled**, both colours marbled together |
| Three different | **Rainbow** |

Three different colours giving a rainbow cake is the best-kept secret in the
game and she will find it within a week. Luna reacts to it every single time.

Effects stack on top of colour and on each other: sparkle from star sugar, glow
from honey, height from cloud cream. A tall glowing sparkling rainbow cake is
reachable — it just takes noticing that she has only three slots.

This is the whole "her cake is genuinely different every time" claim from
`CONCEPT.md` §3.2, made concrete. In code it is a tint, two particle flags, and
a scale on the Y axis.

## 6. The rooms

Every room follows the same shape:

- **One required action**, which takes about two minutes and cannot be failed.
- **Four to six toys** that are always there, always respond, and gate nothing.
- **A big door**, always available, that leaves for the next room. It gains a
  soft glow once the required action is done, and it works before that too.

The toys are what turn a corridor into a place. They are also individually
trivial — most are one tap, one animation, one sound — so the depth is cheap.

### 6.1 De Bakkerij — the hub

**Required:** tap a grey frame.

**Toys:** the shop bell above the door (ding, and Luna pops in); the cat asleep
on the counter (stretches, then resettles); the little radio (plays a loop,
tap again to stop); the window, which shows the actual time of day; **her own
drawings** pinned beside the wall of frames, which wobble and rustle when
tapped.

### 6.2 De Tuin — the garden

**Required:** plant, water, pick — three ingredients into the basket.

Six seed jars on a shelf. Drag a seed to any of three holes in the bed. Drag the
watering can across it: **each pass grows it one stage, three passes and it is
ripe.** Growth is driven by her hand, never by a clock — there is no waiting in
this game. Tap the ripe plant and it hops into the basket.

She may leave with one ingredient or with three. Fewer is not worse; it is a
plainer cake.

**Toys:** wave the watering can in the air and it makes a rainbow; the flowers
along the edge chime in a scale when tapped, low to high, which is a quiet
rehearsal for the party pads; a molehill Mo pops out of; a butterfly that
follows her finger; puddles that splash; a bee that hums when chased.

**The hint:** when the wish is a colour, the matching seed jar shimmers very
slightly. It never blocks anything and there is no penalty for ignoring it.

### 6.3 De Keuken — the kitchen

**Required:** roll the base, three ingredients into the bowl, stir, pour, bake.

> **Built, and wider than this section describes.** Two changes, both made
> while watching how thin the required action looked in the room:
>
> - **The rolling pin earns its place.** The round opens with a ball of dough
>   on the table: roll it flat with the pin — about three passes — and it drops
>   into the tin as a base. It was a toy before, in a room whose one verb was
>   already drag-onto-something.
> - **The three ingredients come from three places, in a fixed order:** the
>   wall shelf, then the back counter, then the basket on the table. One basket
>   made the room a work surface; three places make her look up, along, and
>   down, and it is the difference between a kitchen and a table.
>
> The order is never a puzzle. The one she needs **glows**, the others do not
> travel until their turn, and Nina names the place out loud as each lights up.

Drag each ingredient from the basket into the mixing bowl — generous snapping,
anywhere near it counts. Then **stir with a finger**: the whisk follows her
hand and the batter takes its colour as she goes. About three full turns
finishes it, and **any scrubbing motion also counts, at half rate**, so a child
who cannot yet draw a circle still gets there. Pour into the tin, tin into the
oven, close the door, tap.

The oven has a face and a voice — **Otto** — and he is delighted every time.
Sparkles, a rising ping, and the cake comes out in her colours.

**Toys:** the flour sack (a poof, and handprints that stay for a while); the
tap (running water); the scale (bounces and dings); the shelf jars (rattle);
the rolling pin; Otto himself, who says something different every time he is
tapped.

### 6.4 Versieren — decorating

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

### 6.6 Hanging the frame

A flash, and a photo of her cake with the friend beside it slides into their
frame on the wall. The grey ghost is gone. The frame glows for a moment, the
sign above the door brightens a shade, and the curtain closes.

**This is the ending of a session**, and it is deliberately the most complete
moment in the game. `CONCEPT.md` §5 asks for a clear ending; this is it.

## 7. Rules that hold in every room

| Rule | How it works |
|---|---|
| **Nothing is driven by a clock** | Growth, baking and the party all advance on her actions. The word "wait" does not appear in the design. |
| **The door always works** | Even mid-task. She can leave the kitchen with an unbaked cake; the cake waits for her. |
| **Idle is nudged, never forced** | After ~25 s of nothing, the object she needs sparkles. After ~45 s, Luna says one short line. Then it goes quiet again for a minute. It never repeats twice in a row and never nags. |
| **Every tap does something** | If it is on screen, it responds. A dead tap reads as a broken iPad. |
| **A wrong drag is not wrong** | It floats gently back with a soft sound. No buzzer, no red, no "nee". |
| **Interruptions are free** | The round saves after every step. Closing the app in the middle of stirring resumes in the kitchen, mid-stir, with the same batter. |
| **Hints shimmer, never block** | The object she needs **glows from the moment a step begins** — "which one do I pick up" is not a question she should have to be idle long enough to ask. The 25-second shimmer sits on top of that for when she stops entirely. Nothing is ever disabled. |

## 8. What this costs to build

The gameplay above is mostly reuse. What it genuinely adds over `CONCEPT.md`:

| Thing | Amount | Notes |
|---|---|---|
| Friend characters | 12 | One base faceted body, swapped head and colour. Three-part rig from §9.7 — they only need to dance and jump. |
| Wish cards | 12 | Flat icons. Trivial. |
| Room toys | ~28 | One tap, one animation, one sound each. Individually near-free; collectively this is what makes the game. |
| Seeds and their grown forms | 6 × 3 stages | The garden's only real asset load. |
| Sticker types | 7 trays | Kenney's Food Kit covers most of it. |
| Cake variants | 0 extra | Tint, two particle flags, one scale. All from one mesh. |
| Voice lines | ~200 | See below. |

### Voice lines

Roughly: Luna 90 lines (greetings, per-room nudges, reactions to colours and
combinations, the finale), Otto 15, each friend 6–8 (their wish, their arrival,
matched thanks, unmatched thanks, a couple of idle noises) for about 85.

> **The kitchen's share is done:** 72 Luna lines and 14 Otto lines, in
> [`audio/script-keuken.json`](audio/script-keuken.json). It came to 26 credits,
> because a line costs **0.3**, not the 0.15 assumed below. Scale the estimate
> accordingly — the whole game's dialogue is nearer 60 credits than 30, which
> changes nothing about the argument.

At that price it is still **cheap enough to write more variants than a recorded
game could afford**.
Luna should have four or five ways to say everything she says often, or she will
sound like a lift announcement by round three.

Casting still needed: confirming Otto by ear, and enough distinct voices to
cover twelve friends.
They do not need twelve separate voices — four voices with different pitches,
assigned so that no two friends who appear at the same party sound alike, is
enough. Record the assignment in [`audio/voices.json`](audio/voices.json) as it
is decided.

### What has to be saved

A single `Codable` struct, as `CONCEPT.md` §10 says:

- The twelve frames: for each, whether it is filled, and if so the cake spec
  (ingredients, colour, effects, sticker positions), whether the wish matched,
  and when.
- The round in progress: which friend, which room, and the state of that room.
- Whether the finale has played.
- The free-play overflow gallery, most recent twelve.

## 9. What this changes in the build order

`CONCEPT.md` §8 still holds — the POC comes first and this file changes nothing
about it. After that, the order shifts slightly, because the wall is now the
spine rather than a nice-to-have:

1. **Kitchen + decorating**, hardcoded ingredients. Unchanged; still the best
   first target and still proves the drag-and-snap system.
   **The kitchen is built** — see [`app/README.md`](app/README.md). The basket
   is three random seeds until the garden fills it, the finished cake goes on a
   plank on the back wall instead of into a frame, and the doorway ends the
   round instead of leading anywhere. Decorating is the next thing it should
   lead to, and `tapDoorway()` is the single function that changes.
2. **The party**, so a round has an ending.
3. **The wall** — twelve frames, the grey ghosts, the level select, and
   persistence. This moves *up*: it is not a reward system bolted on later, it
   is the thing that makes the game a game, and everything else hangs off it.
4. **The garden**, which turns the round into a cycle and makes the wish system
   mean something.
5. **The friends and the wishes** — twelve of them, added one at a time. This is
   content, not engineering, and it can grow after she is already playing.
6. **The toys**, continuously. Add one or two every time you touch a room. This
   is the cheapest quality in the whole project.
7. **Final voice-over**, once the dialogue has settled.

Step 3 moving up is the substantive change. Build it as soon as a round can be
completed, because until the wall exists there is no reason for a second round.

## 10. Still open

- **Otto's voice — one listen away.** He is provisionally Barrett and already
  says all fourteen of his kitchen lines, but the pick was made without an ear
  on it. Five auditions are in [`audio/auditions/`](audio/auditions/); playing
  them takes a minute and re-cutting him costs four credits.
- **The four friend voices.**
- **Music, and the sound effects.** Six instrument pads and a party loop, from
  GarageBand or a CC0 library — `CONCEPT.md` §7.4. The party is the payoff and
  it is currently silent. The kitchen's effects are **synthesised at launch** as
  a stopgap; a bought or CC0 pack replaces them one file at a time.
- **Whether the twelve friends are the right twelve.** They are cheap to change
  now and expensive once modelled.
- **Whether replaying a filled frame should be a full party or a short clip.**
  Twenty seconds is the guess; watch what she does with it.
