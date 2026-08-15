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

All voice-over is **generated**, not recorded — see [Audio](#7-audio). That
changes the shape of this list but not its importance.

In rough order of impact per hour of work:

1. **Her name, spoken.** The fairy greets her by name on launch and thanks her
   by name at the party. Roughly 10 lines contain `«NAAM»`.
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
- **Her name may be mispronounced** by a multilingual model. The fix is a
  phonetic respelling in the prompt text rather than the correct spelling.
  Budget one round of trial and error on this specific line; it is the most
  important second of audio in the entire game.

There *are* four native Dutch voices in the catalogue (Erik, Katrien, Lennart,
Lore) on the `inworld_text_to_speech` model — but that model is restricted to
Higgsfield's internal game-generation pipeline and cannot be used to generate
standalone assets. Noting it so nobody rediscovers it and wastes an afternoon.

Because generation is cheap and repeatable, dialogue stops being a fixed cost.
New rooms can have new lines without a recording session, and lines can be
rewritten after watching her play. Design accordingly: write more dialogue
variants than a recorded game would, so the fairy does not repeat herself.

### 7.2 Music and sound effects — NOT available

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

## 9. Technical notes

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

**Art.** This is the real bottleneck, not the code. The same Higgsfield
connector that generates the voices also generates images, so the art and the
audio can run through one pipeline. The hard part is not producing images, it is
producing a hundred images that look like they belong in the same world — so
lock the art direction with a small style reference before generating anything
in bulk, and reuse it as a reference on every subsequent generation. Decide this
before building room 2; retrofitting a style across finished screens is
miserable.

## 10. Open questions

- Her actual name, for `«NAAM»` and the voice lines.
- Voice audition: which preset voice sounds best speaking Dutch, and does it say
  her name correctly?
- Art direction: soft watercolour storybook, or bold flat vector shapes?
- Music and SFX source — CC0 library, paid pack, or GarageBand?
- Does the fairy look like her, or is the fairy a separate character she helps?
  (Helping a character is usually the easier sell at this age — being told "this
  is you" can fall flat if the drawing does not match her self-image.)
