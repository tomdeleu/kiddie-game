#!/bin/sh
# Re-download the decorating room's voice lines from the Higgsfield results CDN.
#
#     sh audio/fetch-voice-versieren.sh
#
# Same shape and the same warning as `fetch-voice.sh`: these are CDN links and
# they may expire. If they 403 or 404, **regenerate rather than hunt** —
# `script-versieren.json` and `script-namen.json` carry the model, the variant,
# Nina's voice_id and the exact text of every line, which is everything needed
# to make them again. The scripts matter more than the files.
#
#   model    text2speech_v2
#   variant  elevenlabs
#   voice    Gracie, 09878754-f20b-5330-9790-58a8027ab5b2
#   cost     0.15–0.3 credits a line by length; 56 files came to about 11
#
# The copies in `audio/` are canonical. This script writes straight into the
# bundle, and the tail copies the two scripts across — which is what keeps the
# two from drifting. They had drifted once already: on 2026-08-16 the canonical
# `script-keuken.json` was found six line ids behind the bundled copy, so a
# regeneration from it would have silently dropped `nina.plank.*` and
# `nina.kamer.*`. Nothing was audibly broken and that is exactly why it went
# unnoticed.
set -eu

BASE="https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ"
OUT="app/NinaBakeryPOC/Resources/Voice"
mkdir -p "$OUT"

fetch() {
  code=$(curl -sS -o "$OUT/$2" -w "%{http_code}" "$BASE/$1")
  if [ "$code" != "200" ]; then
    echo "FAILED $2 (HTTP $code)" >&2
    rm -f "$OUT/$2"
  fi
}

# --- The room: arriving, and the first sticker -----------------------------
fetch hf_20260816_155533_03798c46-7323-425d-aa85-d03c89975991.mp3 nina-versieren-hallo-1.mp3
fetch hf_20260816_155533_4e69edaa-14fd-4432-8566-b4656bc3c7b1.mp3 nina-versieren-hallo-2.mp3
fetch hf_20260816_155534_2962f060-3f68-4aa0-bca3-682758c9139c.mp3 nina-versieren-hallo-3.mp3
fetch hf_20260816_155533_2fe31ae1-ace7-4674-8afb-11705ee81f24.mp3 nina-versieren-hallo-4.mp3
fetch hf_20260816_155533_877b1cdc-f086-46ba-af8f-d3e794586095.mp3 nina-versieren-eerste-1.mp3
fetch hf_20260816_155534_a8ec74b5-5fd1-42b9-ad73-e2d15ecf341f.mp3 nina-versieren-eerste-2.mp3
fetch hf_20260816_155547_a63e90e5-b5d7-4a48-946f-9960266af808.mp3 nina-versieren-eerste-3.mp3

# `mooi` is the one she hears most, so it has four and is fired about one time
# in five, at low priority. A line for every sticker would be a lift
# announcement — she will place dozens.
fetch hf_20260816_155547_28badb94-ef07-47a1-9f6d-848477452aa2.mp3 nina-versieren-mooi-1.mp3
fetch hf_20260816_155547_086c4ba3-a85e-4b8b-86e4-2c762be51ba8.mp3 nina-versieren-mooi-2.mp3
fetch hf_20260816_155547_8ca4cea0-c269-41fd-8ba2-4628a74b2af8.mp3 nina-versieren-mooi-3.mp3
fetch hf_20260816_155547_5307feb9-b6f2-4710-9845-a44519863985.mp3 nina-versieren-mooi-4.mp3

# --- The three remaining reactions GAMEPLAY.md §6.4 names by name ----------
fetch hf_20260816_155547_98d4f600-d644-427b-90be-ace1a4844153.mp3 nina-versieren-kaarsAan-1.mp3
fetch hf_20260816_155601_341c60b0-4030-4b99-ab72-ffbd42ae960b.mp3 nina-versieren-kaarsAan-2.mp3
fetch hf_20260816_155601_055608de-a599-4911-8172-980cd0246da5.mp3 nina-versieren-kaarsAan-3.mp3
fetch hf_20260816_155602_04c1f0aa-6cc0-4d7b-a4e2-84634fe80d9f.mp3 nina-versieren-veelSprinkels-1.mp3
fetch hf_20260816_155601_4d5d0650-ce5a-4718-89fc-98a4b4b42785.mp3 nina-versieren-veelSprinkels-2.mp3
fetch hf_20260816_155601_8c97e89f-edfb-44eb-85a3-bd51f8af34b3.mp3 nina-versieren-veelSprinkels-3.mp3
fetch hf_20260816_155601_824c60be-e149-4701-8be5-337e99b80245.mp3 nina-versieren-rondje-1.mp3
fetch hf_20260816_155623_124b9d7f-e5d4-4bbf-8f62-333e6d26b1d5.mp3 nina-versieren-rondje-2.mp3
fetch hf_20260816_155623_11bdfde2-296c-470e-a5ea-4dc4d76ea8c7.mp3 nina-versieren-rondje-3.mp3

# --- The piping bag running out, which is a refill and not a refusal -------
fetch hf_20260816_155623_33acffb9-795b-413c-a173-1c31de574fc7.mp3 nina-versieren-spuitzakLeeg-1.mp3
fetch hf_20260816_155623_6efd3078-6231-4c76-80f3-5d1d7326d050.mp3 nina-versieren-spuitzakLeeg-2.mp3
fetch hf_20260816_155623_25ad272e-8d01-451c-87bf-79761e01e261.mp3 nina-versieren-spuitzakLeeg-3.mp3

# --- Restart: everything off the cake, and the cake stays ------------------
fetch hf_20260816_155623_2afd3e08-c8c5-458f-9e5a-32e6e9b03538.mp3 nina-versieren-opnieuw-1.mp3
fetch hf_20260816_160941_9abaeb13-70e2-40d7-ad30-a06857048f5c.mp3 nina-versieren-opnieuw-2.mp3
fetch hf_20260816_160941_93bfb220-14ec-4037-8a2b-a1b7ed15815c.mp3 nina-versieren-opnieuw-3.mp3

# --- Idle. `zullenWeGaan` is NOT an instruction: there is nothing here she
# --- can be failing to do, and a nudge implying otherwise would invent the
# --- required action this whole room exists without.
fetch hf_20260816_160941_6fd3285e-7083-4fdb-ae6f-56fa32eeecb4.mp3 nina-versieren-stil-1.mp3
fetch hf_20260816_160940_fb1fd959-fa95-4a11-b9b7-17c6af00e734.mp3 nina-versieren-stil-2.mp3
fetch hf_20260816_160941_01f51e0c-dea4-4300-bc4f-d8b604eba1db.mp3 nina-versieren-stil-3.mp3
fetch hf_20260816_160941_667360c4-1f5b-4955-ad8a-a4eb4cffbefe.mp3 nina-versieren-zullenWeGaan-1.mp3
fetch hf_20260816_165819_da39e5ad-43c6-4a10-b2fd-58fbba43d637.mp3 nina-versieren-zullenWeGaan-2.mp3
fetch hf_20260816_165819_07a28b8d-d0bf-4e72-8142-01e533f0cd69.mp3 nina-versieren-zullenWeGaan-3.mp3

# --- The door. The party does not exist, so these promise it *straks*. -----
fetch hf_20260816_165819_89f5952d-06b3-42f5-b6b9-15a129f5e607.mp3 nina-versieren-deurRonde-1.mp3
fetch hf_20260816_165819_1f967c9a-0ed2-4e7d-9927-43c225bd23e9.mp3 nina-versieren-deurRonde-2.mp3
fetch hf_20260816_165819_56628764-4eac-4cae-8c99-c9603cf9b706.mp3 nina-versieren-deurRonde-3.mp3
fetch hf_20260816_165819_30965fc0-ea39-4a0f-8765-8a2903cff514.mp3 nina-versieren-deurBezoek-1.mp3
fetch hf_20260816_171827_ef398ba6-005b-41a5-a6c8-4002ffcc1b6c.mp3 nina-versieren-deurBezoek-2.mp3
fetch hf_20260816_171827_a31da4e1-1c90-48f0-be22-8edef23e595c.mp3 nina-versieren-deurBezoek-3.mp3

# --- The KITCHEN's door, now that it leads somewhere. ----------------------
# `nina.kamer.deur` is still there and is still what she hears when there is no
# cake to take through — see ROOMS.md §9 on not promising a room that does not
# exist. This is the line for when there is one.
fetch hf_20260816_171827_0ddda51c-c89f-4c00-bcc4-085a67226f62.mp3 nina-keuken-naarVersieren-1.mp3
fetch hf_20260816_171827_49f7ff68-90ec-47ce-8dcb-4e8c00449d65.mp3 nina-keuken-naarVersieren-2.mp3
fetch hf_20260816_171827_165c29fe-c53a-4972-b71a-3421c1124b5b.mp3 nina-keuken-naarVersieren-3.mp3

# --- The naming layer: one variant each, deliberately. ---------------------
# A name is a thing you learn by hearing it the same way twice, so repetition is
# the feature here and the exception everywhere else.
fetch hf_20260816_171827_1a82774a-13e6-4e4e-9b49-a3d5545a2a47.mp3 nina-dit-draaitafel-1.mp3
fetch hf_20260816_172133_388de649-45d1-4006-9f32-6e19d3c922be.mp3 nina-dit-spuitzak-1.mp3
fetch hf_20260816_172133_460e3e37-cf75-4ac1-b832-90d50537d887.mp3 nina-dit-strooibus-1.mp3
fetch hf_20260816_172133_0af6d95f-21b9-4591-aa39-d0cf6127e468.mp3 nina-dit-sprinkel-1.mp3
fetch hf_20260816_172133_2fa9794c-849c-446e-9bb7-b01ebe0710c0.mp3 nina-dit-kaarsje-1.mp3
fetch hf_20260816_172133_95d4834b-3423-4a09-bcb5-8f6cc08e3bae.mp3 nina-dit-hartje-1.mp3
fetch hf_20260816_172133_cb3e610d-1fb8-46ad-8603-fb7eed005088.mp3 nina-dit-sterretje-1.mp3
fetch hf_20260816_172147_fd6b27a3-d465-47b2-b790-30639eaa5721.mp3 nina-dit-kroontje-1.mp3
fetch hf_20260816_172147_6dbb0ef8-c9dc-455d-ac1a-b50b50e779e0.mp3 nina-dit-fruitje-1.mp3
fetch hf_20260816_172147_8923572b-0e54-41fb-83c1-9c65cb87b462.mp3 nina-dit-roomtoefje-1.mp3
fetch hf_20260816_172147_fca28cab-958c-4c2e-b0c3-012c8a143451.mp3 nina-dit-glitterpot-1.mp3
fetch hf_20260816_172147_5dd858ac-e317-4ef7-8730-33a344a9bfdb.mp3 nina-dit-taartborden-1.mp3
fetch hf_20260816_172147_cdfd5468-63a9-42f4-83d7-c70652872188.mp3 nina-dit-kwastje-1.mp3
fetch hf_20260816_172207_4504e54e-006a-459b-a4f5-4081fe4a2c15.mp3 nina-dit-krukje-1.mp3
fetch hf_20260816_172207_77757054-6998-45e0-ba34-27ad4a918e1b.mp3 nina-dit-sprinkelpotjes-1.mp3

# The canonical scripts, copied into the bundle. VoiceBank globs every bundled
# `script-*.json`, so a new room is a new file and no Swift change.
cp audio/script-versieren.json "$OUT/"
cp audio/script-namen.json "$OUT/"
cp audio/script-keuken.json "$OUT/"

echo "Done. 56 new lines in $OUT"
