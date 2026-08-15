# De Toverbakkerij — concept

A magic-bakery game for a 4-year-old, in Dutch, on iPad. Native SwiftUI.

Working title: **De Toverbakkerij** (the magic bakery). Short, Dutch, and a
4-year-old can say it — which matters, because she has to be able to ask for it
by name.

Throughout this document, `«NAAM»` is a placeholder for her first name. It gets
spoken out loud by the characters; see [Personalization](#personalization).

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
store-bought app can never do is **be about her**: her name spoken aloud, her
dad's voice as the narrator, her own drawings hanging on the bakery wall.

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

> "Dankjewel, «NAAM»! Dit was de allerlekkerste taart!"

Then the cake is photographed and hung on the bakery wall in a little frame.

## 4. The hub and the collection

The home screen is the bakery seen in cutaway, doll's-house style: garden,
kitchen, party room. Tap a room to enter, tap the big arrow to come home. That
is the whole navigation model and the only thing she has to learn.

**Every cake she finishes gets framed and hung on the bakery wall.** That is the
progression system. It needs no numbers, no stars, and no reading — she can see
her gallery growing and point at the one she made yesterday. Tapping a frame
replays that cake's little party animation.

## 5. Rules for a four-year-old

These are the difference between "she plays it once" and "she asks for it every
day". They are non-negotiable constraints on every screen.

| Rule | Why |
|---|---|
| **Zero text, anywhere** | She cannot read. Instructions are recorded voice plus an icon. |
| **Tap and drag only** | No swipe precision, no pinch, no double-tap, no long-press — her hands cannot do these reliably yet. |
| **Huge targets, generous snapping** | Minimum ~120pt hit areas. Drop the egg *near* the bowl and it goes in the bowl. |
| **You cannot lose** | No timers, no game over, no buzzer. A wrong drag floats gently back with "hmm, probeer die andere eens!" |
| **Every tap does something** | Tap a background flower, it giggles. Dead zones read as "broken" to her. |
| **Rewards are animation and sound** | Points and stars are meaningless to a pre-reader. A cake that dances is not. |
| **A clear ending** | The party finishes and the curtain closes. This is what makes "one more, then we stop" actually work at bedtime. |
| **A parent gate** | Hold three fingers for three seconds to reach settings. She will not find it. |

## 6. Personalization

In rough order of impact per hour of work:

1. **Her name, spoken.** The fairy greets her by name on launch and thanks her
   by name at the party. Record ~10 lines containing `«NAAM»`.
2. **Dad's voice** as the narrator, the oven, and the guests. Silly voices beat
   good voices at this age.
3. **Her drawings** photographed and hung in the bakery as decoration.
4. **Family faces**, optionally, on the party guests. Nice, but do it last — it
   is fiddly and the game works fine without it.

For prototyping before recording anything, `AVSpeechSynthesizer` with an
`nl-NL` voice is good enough to test the flow. It sounds robotic and she will
notice, so replace it with real recordings before she ever sees it.

## 7. Build order

Ship something playable early and grow it. Suggested order:

1. **Kitchen + decorating**, hardcoded ingredients, no garden, no party. This is
   already a complete little toy and proves the drag-and-snap system.
2. **The party**, so the loop has an ending and a payoff.
3. **The wall of cakes** — persistence, and the first thing that makes her come
   back tomorrow.
4. **The garden**, which turns three screens into a real cycle.
5. **Real voice recordings**, replacing the synthesized placeholder.

Everything after that is new rooms: a dressing room for the fairy, a spell room
where drawing a shape with her finger transforms something.

Rooms 1 and 2 share nearly all their code — drag an object onto a target, snap
it, celebrate — so the second room costs a fraction of the first. That is the
main architectural reason for the hub layout.

## 8. Technical notes

**SwiftUI-first.** The whole game is drag gestures, tinting, and spring
animations, which SwiftUI handles well. Reach for SpriteKit only where it
genuinely wins: `SKEmitterNode` for the fairy sparkles and the oven puff. A
small `SpriteView` embedded in the SwiftUI hierarchy is enough — there is no
need to build the game in SpriteKit.

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

**Art.** This is the real bottleneck, not the code. Options, in order of
pragmatism: buy a children's illustration pack with a consistent style, generate
the assets, or draw them. Decide the art direction before building room 2 —
retrofitting a style across finished screens is miserable.

## 9. Open questions

- Her actual name, for `«NAAM»` and the voice lines.
- Art direction: soft watercolour storybook, or bold flat vector shapes?
- Does the fairy look like her, or is the fairy a separate character she helps?
  (Helping a character is usually the easier sell at this age — being told "this
  is you" can fall flat if the drawing does not match her self-image.)
