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

# The chosen fairy voice (Gracie), audition line
fetch "hf_20260815_070820_00ad6499-b5a2-4038-ab6a-277b1a4e8197.mp3" "voice-gracie-audition.mp3"

echo "Done. Files in $(pwd)/plates"
