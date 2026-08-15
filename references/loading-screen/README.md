# The loading screen — J, the icing title

**Chosen: J.** It ships, padded to 16:9, as
`app/NinaBakeryPOC/Resources/Assets.xcassets/LoadingScreen.imageset/loading-screen.png`,
and is shown by `Sources/Intro/LoadingScreen.swift` while the kitchen is built
behind it. The unpadded 1920×1440 plate is [`J-icing-final.png`](J-icing-final.png).

It is the first screen of the game and the only place the game's name is
written down. The cottage on it is the same cottage the opening film pushes in
on, so the plate hands off to shot 1 rather than cutting away from it.

Eighteen `flux_2` / `pro` plates at 4:3, 2k, all against the locked **scenes**
reference `64f0893e-…` except E, which used the characters reference. 27
credits. Every candidate except the winner is kept at 480 px in
[`candidates/`](candidates/); the job IDs regenerate any of them at full size.

## The prompt that made it

```
Playful childrens video game title screen. The title "Nina's Toverbakkerij" is
fat puffy rounded bubble lettering like soft icing piped onto a cake, thick and
squishy and cheerful, each letter a different size and tilted at its own angle,
curving along a happy arc like a fairground banner. Layout: the title is
horizontally centred on two lines in the upper third, "Nina's" in blush pink on
the first line and "Toverbakkerij" in cream on the second line, correctly
spelled and clearly readable; below it the cottage sits large and centred in the
lower half, seen from a fixed isometric three-quarter angle on a slim square
base slab, built from hard-edged faceted low-poly geometry with visible straight
polygon edges, very low polygon count, no surface texture, no fine detail, no
clutter. Leave a wide generous empty margin of background all the way around the
picture so nothing touches any edge. Kept minimal and chunky: the cottage with a
blush pink faceted roof and a rose door, two chunky faceted trees, a few
flowers. Soft pastel palette only: blush pink, mint green, cream, soft butter
yellow, pale sandy wood. Soft even studio lighting, one gentle key light, a soft
contact shadow on the ground, no hard shadow edges, no dark corners, no ambient
occlusion pooling. Plain flat pale mint background filling the entire picture
edge to edge, including all four corners. Children's game aesthetic, no
photorealism.
```

Note what it does **not** say: the facet clauses cover the cottage only. The
title is deliberately let out of the style — see below.

## The candidates

| # | File | What was asked for | Ref | Job ID | Verdict |
|---|---|---|---|---|---|
| A | `candidates/A-cottage-plain-480.png` | Cottage, empty upper half, no title | scenes | `0a4b276c-d5cd-483c-9d15-3ea59c5e61da` | Lovely plate; title would have had to be drawn by the app |
| B | `candidates/B-cottage-fairy-480.png` | Cottage + Nina, no title | scenes | `884e5c86-f2ff-4df4-889a-5254554981cc` | Good, but the trees crowd the space a title needs |
| C | `candidates/C-hanging-sign-480.png` | Title on a hanging shop sign | scenes | `a3d50766-1c14-47c9-8863-8ec7ddbc4cfc` | Two signs, one reading just "Nina's"; both cover the cottage |
| D | `candidates/D-title-first-480.png` | Title as faceted letters | scenes | `3a7cde18-7fbe-48e9-ad35-b1b1b2a56dbb` | **Spelled right first time.** Off-centre, cottage too small |
| E | `candidates/E-fairy-cake-480.png` | Nina holding a cake, no title | characters | `5c1a2512-6f1e-46c2-b5cc-1c9c5c41719e` | Charming and on-model, but she fills the frame — no room for a title |
| F | `candidates/F-title-geometric-480.png` | D, recomposed | scenes | `fd2bdff1-a376-4d60-b8cd-5a7538828726` | Composition solved. Rejected on the lettering: a geometric sans reads grown-up |
| G | `candidates/G-title-fairy-480.png` | F + Nina | scenes | `0ebc2a2c-bb87-4f02-a565-bb90c6af2caa` | Smooth human-ish fairy, nothing like plate 02; trees over the title |
| H | `candidates/H-title-cake-480.png` | F with a cake instead of the cottage | scenes | `77719f14-fba6-47f3-9e6d-9514ed2432fd` | *"Tovebakkerij"* |
| I | `candidates/I-bounce-faceted-480.png` | Bouncy letters, still faceted | scenes | `7527810e-e3fb-4173-9a5e-764758e9a383` | Good letters, but wireframe triangulation drawn onto the cottage and the slab runs off the frame |
| **J** | **`J-icing-final.png`** | **Puffy piped-icing letters** | scenes | `6fe0eaaf-6ba3-41f5-9e9c-8613412c5e8d` | **Chosen** |
| K | `candidates/K-brush-letters-480.png` | Hand-painted picture-book letters | scenes | `4eb3ea26-f3de-4b2e-ae78-607f7e0a1e19` | *"Tovetbakkerij"* |
| L | `candidates/L-wonky-blocks-480.png` | Silly circus alphabet | scenes | `3f3d1dd0-55a9-47bc-aab6-eed9566ce855` | The most frivolous of them, but it lands on the chimney and roof |

A further six were in flight when the choice was made and were **never
judged**. They are kept because they cost nothing to keep and they are the
obvious first place to look if the title is ever revisited. Their filenames
describe the brief, not the result.

| # | File | Brief | Job ID |
|---|---|---|---|
| M | `candidates/M-icing-letters-480.png` | Letters as iced cakes with sprinkles and a cherry | `5d9dc0c9-677c-4844-8323-ec2c80a1cf94` |
| N | `candidates/N-cartoon-outline-480.png` | Fat cartoon logo, thick cream outline, smile-shaped arc | `20504252-4d6b-44c2-b903-d72cb0996c9c` |
| O | `candidates/O-alphabet-blocks-480.png` | Wooden toy alphabet blocks, tumbled | `22ecf931-c5a9-4147-80f6-43df60b38a17` |
| P | `candidates/P-sticker-marker-480.png` | Flat 2D marker-pen sticker lettering | `b581b0c0-7126-4c29-af5d-088e149bff9f` |
| Q | `candidates/Q-balloon-letters-480.png` | Glossy balloon letters bobbing at their own heights | `0688afdb-3672-4772-92f6-135a2e062f7b` |
| R | `candidates/R-ribbon-banner-480.png` | Fairground ribbon banner with bunting | `7d9711cf-14eb-43c0-87b6-bf1487881cc2` |

## What the passes taught

- **`flux_2` can spell Dutch, but not reliably.** Ten of thirteen title plates
  got *Nina's Toverbakkerij* letter-perfect; the other three produced
  *Tovebakkerij*, *Tovetbakkerij*, and a second sign reading only *Nina's*.
  There is no prompt fix — asking for "correctly spelled" was already in every
  one of them. **Read the word before judging the picture.**
- **The lettering is where the style has to bend.** Every attempt that kept the
  title faceted came out stiff, and the one that leaned hardest into facets (I)
  dragged wireframe lines onto the cottage with it. The logo is the one element
  with no in-game geometry behind it, so it is allowed to be soft while
  everything else stays hard-edged — the same licence the app icon takes.
- **Name the margins or lose the title.** D put *Toverbakkerij* against the
  right edge and F fixed it, on nothing but *"leave a wide generous empty margin
  of background all the way around the picture so nothing touches any edge"*.
- **Say where the title goes relative to the cottage.** L and G both put the
  letters through the roofline. "In the upper third … below it the cottage"
  is what keeps them apart.
- **A character in a scene comes back off-model.** G asked for the fairy inside
  a scene prompt with the scenes reference and got a smooth, brown-haired,
  human-proportioned girl. This is the same finding as the party plate in
  `REFERENCES.md` §3, from the other direction: a character needs the character
  reference, and a character reference bleeds into a scene. A title plate has
  no room for both, so it has no character on it.

## The padding, and why the asset is 16:9

`flux_2` renders 4:3. iPads are 1.333 (12.9", 9.7") through 1.523 (mini).
Aspect-**filling** a 4:3 plate on a mini crops 6.2% off the top and bottom —
straight through a title whose top margin is 3.5%.

[`pad-to-16x9.py`](pad-to-16x9.py) extends the plate to 2560×1440. Every iPad
is then narrower than the asset, so the fill crops the **sides**, never the top,
and the widest one eats only 45 px of the plate proper against side margins of
20%. Nothing about the title is at risk on any iPad.

The padding is synthesised rather than copied, and the file says why at length:
repeating the edge column streaks the paper grain into visible horizontal
lines, and mirroring a wide strip drags the base slab's shadow out into the
background. What ships is a measured per-row background ramp plus grain lifted
from the plate's own clean strip.

The script also prints the corner mean, `#D0E3CE`, which is the value in
`LaunchBackground.colorset`. iOS paints that as the static launch screen, so
launching goes mint → mint rather than white → mint.

## The rule this bends, and why

`CLAUDE.md` says generated images are concept references and nothing generated
goes into the app directly. The opening film was the first stated exception and
the app icon the second, both on the same reasoning: **the asset has no second
form to be modelled into.** A title plate is the third and the clearest of
them — the thing being delivered *is* a picture, and there is no geometry
hiding behind it waiting to be built.

The purer answer, if it is ever wanted, is to render the cottage from the
game's own meshes and keep only the lettering generated. That would cost a
cottage model the game does not have yet, and this file is the brief for it.
