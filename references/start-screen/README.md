# Start screen plates

**Chosen: A–D** for the pictures inside the frames, **F** for the screen
itself. F is a flat sage field and four cream hex windows — no cottage photo.
The hub in `StartScreen.swift` redraws that layout at whatever the iPad's
aspect is, and clips A–D into the hexes. Locked rooms are the same cream
frame with sage showing through.

Generated 2026-08-23, `flux_2` / `pro` / `1k`, against plate 01 plus each room's
existing room-box plate as `image_references`. Five credits. `flux_2` is gone
from the catalogue; this is the same Black Forest Labs line.

| # | File | Job ID | Verdict |
|---|---|---|---|
| **A** | **`A-garden.png`** | `65c68640-79e3-4fdd-913b-c1f6a580a0ae` | **Garden tile.** Picket, potting bench, can, bed. On-model |
| **B** | **`B-kitchen.png`** | `ad071f95-4e2c-48f0-9b82-dbf2c95c12f0` | **Kitchen tile.** Otto with a face, bowl, cake |
| **C** | **`C-decorating.png`** | `c4c2edbb-9819-49f9-aa4e-169a3e4fc3f4` | **Decorating tile.** Cake on a stand, piping bag, sticker trays |
| **D** | **`D-party.png`** | `d489b760-4693-4610-8629-10020bf67cbd` | **Party tile.** Bright floor, mirror ball, speakers. Not a dark disco |
| E | `candidates/E-layout-16x9-480.png` | `3e72fa28-1c7e-4e8f-b8cd-034f4d12e2bf` | First composition sketch. Drew labels, dimmed the party |
| F | `F-layout-16x9.png` | `c436e685-dd21-45f1-898e-d4a3e493e1f3` | **The screen.** Sage field, cream hex frames, no background photo. SwiftUI redraws this rather than displaying the 16:9 PNG, because iPad is closer to 4:3 |

320 px judging copies sit in [`candidates/`](candidates/). Job IDs regenerate
any of them.

## Prompt shape

Style phrases first, then the room as the subject, then three props. One object,
pale mint ground, generous margin, no text. The party prompt adds *still brightly
lit* and *do not dim the room*.
