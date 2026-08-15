# Otto's audition

Five male preset voices, all `text2speech_v2` / `elevenlabs`, all saying:

> "Hallo Nina! Zet de taart maar in mijn buik, dan bak ik hem lekker warm."

| File | Voice | `voice_id` |
|---|---|---|
| `otto-1-barrett.mp3` ← **currently cast** | Barrett | `d603a8cd-3fe1-55e0-9245-617a2589131e` |
| `otto-2-desmond.mp3` | Desmond | `563f728c-e249-5a85-97ab-8461e8c09da6` |
| `otto-3-grady.mp3` | Grady | `e2a2d2e6-9ed2-59cd-82af-feaa27f8a678` |
| `otto-4-arthur.mp3` | Arthur | `30fc8796-ceb6-4a66-b3a7-4a145ef7f346` |
| `otto-5-gideon.mp3` | Gideon | `1ad38ba4-9cc4-4f2f-9fde-b0fefdf67ae5` |

## The pick is provisional, and here is why

`CONCEPT.md` §7.1 says the preset voices are not language-tagged, so Dutch
quality has to be **auditioned by ear**. The session that generated the kitchen
lines could not do that — it had no ears. Barrett was picked on the brief's own
description ("low and rumbly is the obvious read") and nothing more.

**So play these five.** It takes a minute. If a different one is the oven, the
swap is cheap:

1. Put the winning `voice_id` in `audio/voices.json` and in
   `audio/script-keuken.json` under `characters.otto`.
2. Regenerate Otto's 14 lines from `script-keuken.json` with that id
   — 14 × 0.3 = **4.2 credits**.
3. Overwrite the same filenames in `app/NinaBakeryPOC/Resources/Voice/`.

No code changes. The app looks lines up by filename, and the filenames do not
carry the voice.

Luna's audition lives in `references/plates/voice-gracie-audition.mp3`, and her
casting was settled by ear on 2026-08-15 — see `CONCEPT.md` §7.2. She is not
provisional.
