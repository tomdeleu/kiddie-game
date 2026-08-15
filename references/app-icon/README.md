# App icon — candidates, not yet chosen

Nine `flux_2` / `pro` candidates at 1:1, 1024×1024, generated against the locked
style references. **Nothing here is wired into the app yet** — there is no
`Assets.xcassets` in `app/NinaBakeryPOC` at all, so adding an icon means adding
an asset catalog first. That waits on a decision.

Full-size finalists sit in this folder; every other candidate is kept at 320 px
in [`candidates/`](candidates/), which is enough to judge and keeps the repo
light. The job IDs regenerate any of them at full size.

## The candidates

| # | File | Subject | Ref | Job ID | Verdict |
|---|---|---|---|---|---|
| A | `candidates/A-cake-320.png` | Three-tier cake, mint ground | scenes | `9993d58c-b0ec-4f81-aad8-ae32a79433b0` | Good silhouette, colours too washed out |
| B | `candidates/B-luna-bust-320.png` | Luna, head and shoulders | characters | `32313998-226a-4341-a340-40da63fe96a8` | Cute, but baked-in icon frame and stray yellow shapes |
| C | `candidates/C-cottage-320.png` | The cottage | scenes | `36964b76-6254-4aab-9256-411193ccfcd9` | Too much detail for 60 pt; smoke rendered as a tree-sized blob |
| D | `candidates/D-luna-cake-320.png` | Luna holding a cake | characters | `c696b801-ade2-4f8c-a707-bbbe541b2291` | Strong read, baked-in icon frame |
| E | `candidates/E-cake-mint-320.png` | Two-tier cake, saturated | scenes | `3edd0580-fa0f-4bb4-8cc3-ff8a966c5743` | Best cake shape, baked-in icon frame |
| F | `candidates/F-cake-slice-320.png` | Cake with a cut slice | scenes | `d54770e7-b1b0-4afa-8249-04d82411f672` | Off-palette blue slice, too round, subject too small |
| G | `candidates/G-luna-cake2-320.png` | Luna holding a cake | characters | `d0052eda-b0fb-4c36-abcf-18b09a4d0b7a` | Good, baked-in icon frame |
| **H** | **`H-cake-final.png`** | **Two-tier cake on a plate** | scenes | `1bdb5f82-c525-4bb4-8b37-7ff09b4a5312` | **Recommended** |
| **I** | **`I-luna-final.png`** | **Luna holding a cake** | characters | `adaf5299-d88b-4951-a56d-8d0115316e6e` | **Alternative** |

Nine generations, 9 credits.

## What the passes taught

- **Never put the words "app icon" in the prompt.** Five of the nine came back
  with a rounded-corner mask and white corners painted into the picture. iOS
  applies its own mask, so a baked one gets double-rounded. Describe the framing
  instead — *"very large and centred, filling most of the square picture"* — and
  spell out *"flat backdrop filling the entire square edge to edge, including
  all four corners"*. H and I are the pass that dropped the phrase.
- **The 60 px check decides it**, not the 1024 px one. `candidates/*-60.png`
  are the finalists at home-screen size. The cake survives; Luna turns into a
  small figure holding a pink smudge, because a character puts the detail in a
  face that is only a fifth of the frame.
- The style prompt from `REFERENCES.md` §3 carries over unchanged; only the
  room-box clause is swapped for the single-object framing.
- `no ambient occlusion pooling` still earns its place — dropping it puts a
  shadow ring around the plate.

## Open decision before any of this ships

`CLAUDE.md` says generated images are concept references and nothing generated
goes into the app directly, with the opening film as the single stated
exception. An icon is the same shape of problem as the film: it has no second
form — it *is* a 1024×1024 PNG, and there is nothing to model from it.

So either:

1. **Ship the PNG** as a second documented exception, on the film's reasoning; or
2. **Treat it as a brief** and render the icon from the game's own geometry, so
   the icon is literally the cake the game builds.

(2) is the purer answer and is not expensive once a cake exists as geometry —
but the kitchen's cake has never been compiled, let alone rendered. (1) is
available today.

## If (1) is chosen

Needs `Assets.xcassets` with an `AppIcon` set. Modern Xcode wants **one
1024×1024 PNG, no alpha, square, no rounded corners** — the finalists are
already RGB, no alpha, full-bleed. iOS 18+ also wants dark and tinted variants;
a dark variant here is a straight backdrop swap (mint → deep sage) with the
cake unchanged.
