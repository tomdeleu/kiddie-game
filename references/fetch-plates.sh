#!/usr/bin/env sh
# Download the generated reference plates and voice audition into this repo.
#
# These live on the Higgsfield results CDN, which the sandbox egress policy
# currently denies (403 at the gateway). Run this from a machine that can reach
# it, or from a session whose environment allowlists:
#
#     d8j0ntlcm91z4.cloudfront.net
#
# The URLs are CDN links and may expire. If they 403/404, regenerate instead —
# REFERENCES.md §3 records the model, seed and job ID for every plate, and the
# shared style prompt, which reproduces them exactly.

set -eu
cd "$(dirname "$0")"
mkdir -p plates
BASE="https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ"

fetch() {
  printf '%s ... ' "$2"
  code=$(curl -sS -o "plates/$2" -w '%{http_code}' --max-time 60 "$BASE/$1" || echo 000)
  if [ "$code" = "200" ]; then echo "ok"; else echo "FAILED (HTTP $code)"; rm -f "plates/$2"; fi
}

# Faceted pastel low-poly reference plates (flux_2 pro, 1k)
# 01 and 02 are the locked style references — see REFERENCES.md §3.
fetch "hf_20260815_071208_64f0893e-073a-4065-b363-f87687ced11d.png" "01-cottage-exterior.png"
fetch "hf_20260815_071208_d368acec-4085-48e4-83ff-7a57ee8ee789.png" "02-fairy-character.png"
fetch "hf_20260815_094007_37de2697-7cee-423d-ae7b-4a0a8573ac3b.png" "03-kitchen-roombox.png"
fetch "hf_20260815_093851_0bbbe4f2-409d-4957-8491-e3c1eca41e31.png" "04-party-roombox.png"
fetch "hf_20260815_094007_e70b82a3-1c74-4df5-96f4-2028205eda3c.png" "05-garden-roombox.png"

# Gameplay plates — the scenes GAMEPLAY.md added
fetch "hf_20260815_103015_b63007ac-96ff-46c0-9584-91ea8e2421ea.png" "06-wall-of-frames.png"
fetch "hf_20260815_103015_fbb49dea-bbe7-491b-99f1-acf77ed12df7.png" "07-decorating-roombox.png"
fetch "hf_20260815_103016_878dabff-812b-415a-90de-c18c05762961.png" "08-twelve-friends.png"
fetch "hf_20260815_103015_29dc8d73-b2f8-407b-99b5-af5f9fefd841.png" "09-cake-variants.png"
fetch "hf_20260815_103015_571d95c4-a277-40c9-aff7-7c8ba6e4dc9c.png" "10-wish-at-the-door.png"
fetch "hf_20260815_103015_32a2d5e9-8072-47aa-81a9-62b4a43c414b.png" "11-finale.png"

# The chosen fairy voice (Gracie), audition line
fetch "hf_20260815_070820_00ad6499-b5a2-4038-ab6a-277b1a4e8197.mp3" "voice-gracie-audition.mp3"

echo "Done. Files in $(pwd)/plates"
