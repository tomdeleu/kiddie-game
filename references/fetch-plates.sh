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
# REFERENCES.md §3 records the model, prompt and seed for every plate, which
# reproduces them exactly.

set -eu
cd "$(dirname "$0")"
mkdir -p plates
BASE="https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ"

fetch() {
  printf '%s ... ' "$2"
  code=$(curl -sS -o "plates/$2" -w '%{http_code}' --max-time 60 "$BASE/$1" || echo 000)
  if [ "$code" = "200" ]; then echo "ok"; else echo "FAILED (HTTP $code)"; rm -f "plates/$2"; fi
}

# Clay-direction reference plates (flux_2 pro, 1k)
fetch "hf_20260815_074713_9887941f-9d50-409f-ad7a-330e3b43c5d0.png" "01-kitchen-roombox.png"
fetch "hf_20260815_074712_5bc6e6db-ffa5-4fff-b378-7661a9060e3a.png" "02-cottage-exterior.png"
fetch "hf_20260815_074713_13e7c536-befa-462f-bf19-c632f74a8e83.png" "03-fairy-character.png"
fetch "hf_20260815_074712_6eaffc62-3809-4985-80be-67d78eaf0bf1.png" "04-party-roombox.png"

fetch "hf_20260815_080831_457fa9f0-6bf7-4299-815d-3141e42d8422.png" "05-garden-roombox.png"

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
