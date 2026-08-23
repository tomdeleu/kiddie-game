#!/bin/sh
# Re-fetch De Bakkerij's voice-over (room 6.1, the hub) into the app bundle.
#
#   provider  higgsfield
#   model     text2speech_v2, variant elevenlabs
#   voice     Nina = Gracie, 09878754-f20b-5330-9790-58a8027ab5b2
#   cost      0.15 credits a line preflighted; 53 files came to about 9
#   made      2026-08-17
#
# The mapping below is the whole point of this file: Higgsfield names a result
# hf_<date>_<time>_<job-uuid>.mp3 and the game wants nina-bakkerij-<thing>-<n>.mp3.
# Nothing else records which job became which line.
#
# **If these 404, regenerate rather than hunt.** The CDN link is not a permanent
# archive; script-bakkerij.json carries the text, the voice id, the model and the
# variant, which is everything needed to make them again.
#
# Two notes worth keeping, both learned the expensive way on earlier rooms:
#
#  - `audio/script-*.json` is canonical and `Resources/Voice/` is the bundle, and
#    they drift. On 2026-08-16 the canonical script-keuken.json was found six ids
#    behind the bundled copy; nothing was audibly broken, which is exactly why it
#    went unnoticed. This script copies the canonical file into the bundle at the
#    end so the two cannot part company on this room's account.
#  - This room's naming lines (nina.dit.*) live in script-bakkerij.json rather
#    than in script-namen.json, following Het Feest. script-namen.json's canonical
#    copy is behind its bundled one, so editing it would have deleted the garden's
#    fifteen naming lines from the bundle on the next copy.

set -e

BASE="https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ"
OUT="$(dirname "$0")/../app/NinaBakeryPOC/Resources/Voice"
mkdir -p "$OUT"

fetch() {
  code=$(curl -sS -o "$OUT/$2" -w '%{http_code}' "$BASE/$1")
  if [ "$code" = "200" ]; then echo "  ok   $2"; else echo "  FAIL $2 (HTTP $code)"; rm -f "$OUT/$2"; fi
}

echo "De Bakkerij — 53 lines"

# The four-step spine, the return leg, and the three ways in
fetch hf_20260817_204123_ed549bff-ed10-4eaf-b80b-92c698b53c69.mp3 nina-bakkerij-hallo-1.mp3
fetch hf_20260817_204123_c638bc33-a0f8-4408-9c49-7ad602938292.mp3 nina-bakkerij-hallo-2.mp3
fetch hf_20260817_204123_1061fb27-4285-4241-b53e-ea14cbd086cb.mp3 nina-bakkerij-hallo-3.mp3
fetch hf_20260817_204123_8dd999ed-d5b4-46de-8abf-65d8f204253d.mp3 nina-bakkerij-halloopen-1.mp3
fetch hf_20260817_204123_b0d666cc-1621-4f35-b96c-13a9a6752bd0.mp3 nina-bakkerij-halloopen-2.mp3
fetch hf_20260817_204123_b922a703-2e41-4550-bbb6-c76677915341.mp3 nina-bakkerij-hallovrij-1.mp3
fetch hf_20260817_204123_8857fc4b-a25b-4031-a205-51c416663ea3.mp3 nina-bakkerij-hallovrij-2.mp3
fetch hf_20260817_204123_afd02207-1586-4ee0-a699-1163b803659a.mp3 nina-bakkerij-opendoen-1.mp3
fetch hf_20260817_204123_e5ba0213-0c3b-4742-812e-0331ad67e72b.mp3 nina-bakkerij-opendoen-2.mp3
fetch hf_20260817_204123_370a0823-00d8-49d9-a04f-802989851191.mp3 nina-bakkerij-opengedaan-1.mp3
fetch hf_20260817_204123_cc300eaf-a7f9-49b8-8bb8-06ceea98d71b.mp3 nina-bakkerij-opengedaan-2.mp3
fetch hf_20260817_204123_8e632e2e-8a16-4309-b702-bcf84b8e6e84.mp3 nina-bakkerij-kiezen-1.mp3
fetch hf_20260817_204236_fa6c3743-4960-4d5d-b231-84236d0481d8.mp3 nina-bakkerij-kiezen-2.mp3
fetch hf_20260817_204236_877407bf-e95d-4be0-965d-c2d5b31fc90a.mp3 nina-bakkerij-kiezen-3.mp3
fetch hf_20260817_204236_0bb35833-3be0-4459-8ef3-b1de3346977d.mp3 nina-bakkerij-gekozen-1.mp3
fetch hf_20260817_204236_d81ee983-8592-4139-b587-f30b0a52635e.mp3 nina-bakkerij-gekozen-2.mp3
fetch hf_20260817_204236_dba45b5a-cb44-494a-ab78-0ce4fec141b6.mp3 nina-bakkerij-bel-1.mp3
fetch hf_20260817_204236_cfd03514-0615-41fb-9ff7-7f4b3a9c065e.mp3 nina-bakkerij-bel-2.mp3
fetch hf_20260817_204236_3ac7134b-fd3b-4d7e-9d30-927461bb44a2.mp3 nina-bakkerij-binnen-1.mp3
fetch hf_20260817_204236_9de33be6-ae7b-476f-97a9-9470b42138dd.mp3 nina-bakkerij-binnen-2.mp3
fetch hf_20260817_204236_ed7434da-f958-4ca9-8084-8bf28ffcb5af.mp3 nina-bakkerij-bestellen-1.mp3
fetch hf_20260817_204236_28a49b2d-1571-4e81-98d5-79e94d18f497.mp3 nina-bakkerij-bestellen-2.mp3
fetch hf_20260817_204236_599c0631-83e5-44e6-afd3-1db47c110ef1.mp3 nina-bakkerij-naartuin-1.mp3
fetch hf_20260817_204236_4a9e0e2c-11fd-4668-b1df-a23cab4e9fe9.mp3 nina-bakkerij-naartuin-2.mp3
fetch hf_20260817_205114_756a2c30-41cb-4582-b618-bc5563f644cd.mp3 nina-bakkerij-ophangen-1.mp3
fetch hf_20260817_205114_d3f77b85-3f92-4ec6-8d6f-e36904ee3479.mp3 nina-bakkerij-ophangen-2.mp3
fetch hf_20260817_205114_1754ae5e-ba77-4413-a457-7a7c7602d283.mp3 nina-bakkerij-klaar-1.mp3
fetch hf_20260817_205114_493543c8-884a-4928-926c-c41df636e116.mp3 nina-bakkerij-klaar-2.mp3
fetch hf_20260817_205114_fa5b640e-535d-4844-b009-659572fbecd7.mp3 nina-bakkerij-wacht-1.mp3
fetch hf_20260817_205114_82cf03a7-5035-4c83-adbe-83c8c0e715d3.mp3 nina-bakkerij-wacht-2.mp3
fetch hf_20260817_205114_6a109b2d-2fff-49d2-80b2-12033164382e.mp3 nina-bakkerij-opnieuw-1.mp3
fetch hf_20260817_210529_af0b246c-24f2-4983-b802-a1f3b7ba2956.mp3 nina-bakkerij-allelijstjes-1.mp3

# The eleven wishes, relayed by Nina. One variant each, on purpose — this is also
# what the persistent wish card replays when tapped.
fetch hf_20260817_205115_fffa97c9-bc21-450d-b575-f36f69459466.mp3 nina-bakkerij-wens-pip-1.mp3
fetch hf_20260817_205114_3df37068-920c-4b59-8803-a15e2128388d.mp3 nina-bakkerij-wens-bella-1.mp3
fetch hf_20260817_205114_359a5793-4800-4416-a61c-a7717145a001.mp3 nina-bakkerij-wens-bas-1.mp3
fetch hf_20260817_205114_7ac7fe93-0c6b-4095-ba30-5068b2f90061.mp3 nina-bakkerij-wens-kiki-1.mp3
fetch hf_20260817_205320_a1ba9ca0-8666-4165-b372-6abcaa2e46aa.mp3 nina-bakkerij-wens-bram-1.mp3
fetch hf_20260817_205320_8bf7aec3-f409-4558-84d5-fd4b8a64d7bd.mp3 nina-bakkerij-wens-bo-1.mp3
fetch hf_20260817_205321_ad879efb-db0b-4127-bdaf-10732f1c1eb8.mp3 nina-bakkerij-wens-wolkje-1.mp3
fetch hf_20260817_205320_effacb45-136b-40fc-b256-023c1d69a4a5.mp3 nina-bakkerij-wens-mo-1.mp3
fetch hf_20260817_205320_3eb27101-da43-4b9f-8beb-9b838cf9b59d.mp3 nina-bakkerij-wens-roos-1.mp3
fetch hf_20260817_210528_fc2ddec0-5697-42aa-96a9-e2cf6a702916.mp3 nina-bakkerij-wens-tobi-1.mp3
fetch hf_20260817_205320_5b1ab6de-b5fa-4f61-aeb5-5630425ddbb1.mp3 nina-bakkerij-wens-nel-1.mp3

# The naming layer — tap a prop, hear what it is called.
fetch hf_20260817_205321_7636a17b-5917-4a5d-bd41-f67cd6e38304.mp3 nina-dit-rolluik-1.mp3
fetch hf_20260817_205320_d8f673fe-e755-4f79-b8cd-e6c612c6a2af.mp3 nina-dit-lijstje-1.mp3
fetch hf_20260817_205320_f9f995d3-4498-4f3a-843c-1c9da88ee460.mp3 nina-dit-bel-1.mp3
fetch hf_20260817_205320_16586343-911e-415b-9398-7e64cee2aae8.mp3 nina-dit-poes-1.mp3
fetch hf_20260817_205320_b4fe7787-3390-48c0-b20d-59b4c97e45df.mp3 nina-dit-radio-1.mp3
fetch hf_20260817_210514_84e68d14-bd39-490e-bb96-afc405bfd3f1.mp3 nina-dit-raam-1.mp3
fetch hf_20260817_210514_99791adb-2a37-4fb5-a628-5d73e11f0722.mp3 nina-dit-tekening-1.mp3
fetch hf_20260817_210514_18bd6fb9-b155-4b79-a076-683771916a6e.mp3 nina-dit-haak-1.mp3
fetch hf_20260817_210514_e27bb1f8-17d3-4f4a-9dd5-13d307bd3eee.mp3 nina-dit-winkeldeur-1.mp3
fetch hf_20260817_210514_65af5f16-9771-48a7-8690-7f201dc53f9e.mp3 nina-dit-uithangbord-1.mp3

# Canonical -> bundle, so the two copies cannot drift on this room's account.
cp "$(dirname "$0")/script-bakkerij.json" "$OUT/script-bakkerij.json"
echo "  ok   script-bakkerij.json"
