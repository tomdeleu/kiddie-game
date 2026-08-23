#!/usr/bin/env sh
# Re-download the kitchen voice-over into the app bundle.
#
# The mp3s are committed, so this is not needed for a normal build. It exists
# because the CDN links are the only record of *which generated file* became
# which line, and that mapping is worth keeping runnable — see
# `references/fetch-plates.sh` for the same pattern on the image plates.
#
# These are Higgsfield result URLs and they may expire. If they 404, regenerate
# instead: `script-keuken.json` holds every line's text and the character's
# voice_id, which reproduces the whole set (104 lines, ~32 credits).
#
# Egress note: the sandbox allowlist has to include d8j0ntlcm91z4.cloudfront.net.

set -eu
cd "$(dirname "$0")"
OUT="../app/NinaBakeryPOC/Resources/Voice"
mkdir -p "$OUT"
BASE="https://d8j0ntlcm91z4.cloudfront.net/user_39OtbtGoYAVkmrcBwNT0Vv0BbHJ"

fetch() {
  code=$(curl -sS -o "$OUT/$2" -w '%{http_code}' --max-time 60 "$BASE/$1" || echo 000)
  if [ "$code" = "200" ]; then
    printf '  %s\n' "$2"
  else
    printf '  %s FAILED (HTTP %s)\n' "$2" "$code"; rm -f "$OUT/$2"
  fi
}

# text2speech_v2 / elevenlabs, generated 2026-08-15.
# Nina is Gracie  09878754-f20b-5330-9790-58a8027ab5b2
# Otto is Barrett d603a8cd-3fe1-55e0-9245-617a2589131e  (provisional)

echo "Nina:"
fetch "hf_20260815_175122_6b7a8614-fa9b-430f-8119-ef7217065863.mp3" "nina-keuken-hallo-1.mp3"
fetch "hf_20260815_121908_7974d715-c235-4ef7-bdd8-64a9ca4e60da.mp3" "nina-keuken-hallo-2.mp3"
fetch "hf_20260815_175122_594d7826-eabd-4ea7-9533-cd55a58b1019.mp3" "nina-keuken-hallo-3.mp3"
fetch "hf_20260815_121908_757d34e7-0520-47a6-bf25-0e3fd2332fa8.mp3" "nina-keuken-hallo-4.mp3"
fetch "hf_20260815_121908_36527b9b-ff27-4b33-a169-5febd78a1d4c.mp3" "nina-keuken-doeInKom-1.mp3"
fetch "hf_20260815_121908_4a2a22a7-db85-4773-bb33-0c4d9aae0068.mp3" "nina-keuken-doeInKom-2.mp3"
fetch "hf_20260815_122041_0b07188d-a754-4f44-ae24-58247618a83f.mp3" "nina-keuken-doeInKom-3.mp3"
fetch "hf_20260815_121908_71d7c1e3-5de7-42e9-89b8-8e5800e40060.mp3" "nina-ingredient-aardbei-1.mp3"
fetch "hf_20260815_121908_38b047b4-414d-4e34-ad6d-2cdac9e88991.mp3" "nina-ingredient-aardbei-2.mp3"
fetch "hf_20260815_121908_7e76cb6e-b983-4154-aab2-0c2d426d8d17.mp3" "nina-ingredient-bosbes-1.mp3"
fetch "hf_20260815_121908_0f65a544-5da2-49cc-95cd-84a00c39c638.mp3" "nina-ingredient-bosbes-2.mp3"
fetch "hf_20260815_121908_3cb5d96f-6e0c-46ee-8938-7853a1d212c7.mp3" "nina-ingredient-honing-1.mp3"
fetch "hf_20260815_121919_2398d916-69f9-4d82-9797-00d2c7c2f373.mp3" "nina-ingredient-honing-2.mp3"
fetch "hf_20260815_122041_599dd24b-2811-4f43-b67a-99ab11a3a5be.mp3" "nina-ingredient-klaver-1.mp3"
fetch "hf_20260815_121919_f349298e-6357-496f-915b-374ec6718dce.mp3" "nina-ingredient-klaver-2.mp3"
fetch "hf_20260815_121919_cd4177eb-7a6c-442a-a1f9-a022c4f78745.mp3" "nina-ingredient-wolkenroom-1.mp3"
fetch "hf_20260815_121919_edc051f0-ca4c-46ba-b5a3-4366a08e900f.mp3" "nina-ingredient-wolkenroom-2.mp3"
fetch "hf_20260815_121919_fba8bee2-7468-47d7-8503-678ca79665ea.mp3" "nina-ingredient-sterrensuiker-1.mp3"
fetch "hf_20260815_121919_5454d630-abf3-46e6-bb9f-4c6258c9404c.mp3" "nina-ingredient-sterrensuiker-2.mp3"
fetch "hf_20260815_121919_f61d2a87-3cbe-47c7-8392-e1e8ebd1abd3.mp3" "nina-keuken-roeren-1.mp3"
fetch "hf_20260815_121919_7c75fe1e-a07d-471c-af6f-71ad9b287e6a.mp3" "nina-keuken-roeren-2.mp3"
fetch "hf_20260815_175122_78fa4930-fdf1-451f-8e25-557d555ddf71.mp3" "nina-keuken-roeren-3.mp3"
fetch "hf_20260815_121919_a2770662-a43e-40e3-9ab6-e6151e36d2a5.mp3" "nina-keuken-roerenGoedZo-1.mp3"
fetch "hf_20260815_121919_1f23aa01-4601-48f7-a70e-4c7e0efac6df.mp3" "nina-keuken-roerenGoedZo-2.mp3"
fetch "hf_20260815_121930_08807130-f23e-4bca-8f6d-2f6a7db32d6d.mp3" "nina-keuken-roerenGoedZo-3.mp3"
fetch "hf_20260815_121930_7b8af8cd-faf6-42ed-84de-6afe4f9b4cfa.mp3" "nina-keuken-beslagKlaar-1.mp3"
fetch "hf_20260815_175122_f595f039-0d11-493e-aa2d-f99095307737.mp3" "nina-keuken-beslagKlaar-2.mp3"
fetch "hf_20260815_121930_55d3901f-eb1d-4afe-834d-e66cd913df03.mp3" "nina-keuken-beslagKlaar-3.mp3"
fetch "hf_20260815_121930_0fbbc403-3d87-4829-af84-c84ed5d06b32.mp3" "nina-keuken-gieten-1.mp3"
fetch "hf_20260815_121930_a4144a49-54b0-4379-b686-d66a6f04ffca.mp3" "nina-keuken-gieten-2.mp3"
fetch "hf_20260815_121930_fbbcb758-36dd-4286-805c-774565e24eb0.mp3" "nina-keuken-gieten-3.mp3"
fetch "hf_20260815_121930_ce4eaa5e-253a-49fe-b103-1d6e0618b673.mp3" "nina-keuken-gegoten-1.mp3"
fetch "hf_20260815_122041_bc39c53d-3775-47cd-9201-b4e6cb58102a.mp3" "nina-keuken-gegoten-2.mp3"
fetch "hf_20260815_121930_88d17666-61d1-4df9-93fd-8b33e8798d12.mp3" "nina-keuken-naarOtto-1.mp3"
fetch "hf_20260815_121930_2304b807-8d28-4eb8-b70e-6cf74b805646.mp3" "nina-keuken-naarOtto-2.mp3"
fetch "hf_20260815_121930_c2cebb80-2277-40a7-a4f5-21e1358d3edb.mp3" "nina-keuken-naarOtto-3.mp3"
fetch "hf_20260815_121939_68fc1ee2-f707-4010-b8d7-7d5b95804480.mp3" "nina-keuken-klopOpOtto-1.mp3"
fetch "hf_20260815_121939_e805e453-df1e-495f-ae57-7f422316f65b.mp3" "nina-keuken-klopOpOtto-2.mp3"
fetch "hf_20260815_121939_572edecb-5936-48f0-8338-fb283d2f812b.mp3" "nina-taart-roze-1.mp3"
fetch "hf_20260815_121939_a71ae5c3-c19e-45aa-aea5-3a08bab00a82.mp3" "nina-taart-roze-2.mp3"
fetch "hf_20260815_121939_edc8b1f0-b2ae-4b68-acd3-13522f2106b6.mp3" "nina-taart-blauw-1.mp3"
fetch "hf_20260815_175122_e49802ab-ff3c-447a-b368-ceb1ec2d3a77.mp3" "nina-taart-blauw-2.mp3"
fetch "hf_20260815_121939_2c9a2b70-cb86-493a-ae8a-9a6e9c87eda1.mp3" "nina-taart-geel-1.mp3"
fetch "hf_20260815_121939_85a003bc-7d8d-4dbe-a336-e8406feabddb.mp3" "nina-taart-geel-2.mp3"
fetch "hf_20260815_121939_b9292908-f3a4-4952-a380-e10b277763aa.mp3" "nina-taart-groen-1.mp3"
fetch "hf_20260815_121939_efd414b0-8c09-4681-82c5-7b201725bc27.mp3" "nina-taart-groen-2.mp3"
fetch "hf_20260815_121939_99a4b005-fd02-4e61-8ba0-ca75eb6890ce.mp3" "nina-taart-wit-1.mp3"
fetch "hf_20260815_175122_ed6c8c8f-6800-4fb1-953f-f5f8cf93c2a7.mp3" "nina-taart-wit-2.mp3"
fetch "hf_20260815_121958_c2435bd9-4118-4eeb-97c4-55ae3b0016c3.mp3" "nina-taart-room-1.mp3"
fetch "hf_20260815_121958_7f84ad3d-9402-4f0c-9238-089317605e72.mp3" "nina-taart-room-2.mp3"
fetch "hf_20260815_121958_7285d260-1d7c-4e88-80ce-47e902977ae4.mp3" "nina-taart-gemengd-1.mp3"
fetch "hf_20260815_175122_4253d507-6ddd-4d89-8b6d-423ea1087acf.mp3" "nina-taart-gemengd-2.mp3"
fetch "hf_20260815_121958_1974cd16-c6d6-4824-a125-7c41433b86c4.mp3" "nina-taart-regenboog-1.mp3"
fetch "hf_20260815_121958_2e8eb434-e0b1-4756-b10d-8c82967a54a7.mp3" "nina-taart-regenboog-2.mp3"
fetch "hf_20260815_175122_7c4fd482-d216-45bc-8588-679713fe4258.mp3" "nina-taart-regenboog-3.mp3"
fetch "hf_20260815_121958_6e3163c7-82a2-40e9-bce5-731438382a31.mp3" "nina-effect-fonkelt-1.mp3"
fetch "hf_20260815_121958_60272597-b294-4b51-bc64-94025cdb78d0.mp3" "nina-effect-fonkelt-2.mp3"
fetch "hf_20260815_121958_d581aea5-c639-4b55-a354-246bfe8f508f.mp3" "nina-effect-glimt-1.mp3"
fetch "hf_20260815_121958_c1e7c46b-7be7-4a7a-80ca-0c0207c7ee90.mp3" "nina-effect-glimt-2.mp3"
fetch "hf_20260815_121958_ece05b13-e333-4fb4-96d7-77f5a09d4d17.mp3" "nina-effect-hoog-1.mp3"
fetch "hf_20260815_122014_adb06a3a-4700-4596-b6ac-9cdf0f6ff823.mp3" "nina-effect-hoog-2.mp3"
fetch "hf_20260815_122014_75717568-528b-48e2-98a5-a79fd150091f.mp3" "nina-oeps-1.mp3"
fetch "hf_20260815_122014_c506805b-723b-44d1-a4e8-d9b3e69ec0b4.mp3" "nina-oeps-2.mp3"
fetch "hf_20260815_122014_69099d70-d8be-47d0-b243-b91ed9311788.mp3" "nina-oeps-3.mp3"
fetch "hf_20260815_122014_ee1e1493-f518-4cd8-9ad8-d5baac305906.mp3" "nina-speel-bloem-1.mp3"
fetch "hf_20260815_122014_db9c831f-67d4-454b-b51d-12afec0258a0.mp3" "nina-speel-bloem-2.mp3"
fetch "hf_20260815_122014_37300fe1-55a0-4486-9dd4-0e97d166a50f.mp3" "nina-stil-1.mp3"
fetch "hf_20260815_175122_672fc495-8ab1-40c9-a0a4-ffc371a213c6.mp3" "nina-stil-2.mp3"
fetch "hf_20260815_122014_04350112-b809-419e-9e61-23bc0cba5b04.mp3" "nina-stil-3.mp3"
fetch "hf_20260815_175122_b1cbe03b-000a-4651-9312-96f83f2a87ef.mp3" "nina-klaar-1.mp3"
fetch "hf_20260815_122014_b08247dc-4e8d-4560-ac76-af7c54399a96.mp3" "nina-klaar-2.mp3"
fetch "hf_20260815_122014_90bd7030-d75d-4747-ac00-cb9bafc3fa14.mp3" "nina-klaar-3.mp3"

# One line per shot, each written to that shot's measured length — see the
# _timing block in script-intro.json. Regenerated 2026-08-15: the previous pair
# ran 10.60 s under 14.08 s of film and left the last third of each shot silent.
# These run 13.33 s and end about two tenths before their own cuts.
echo "Nina, opening film:"
fetch "hf_20260815_184714_5052a0ad-feb2-4464-abca-43e855589390.mp3" "nina-intro-buiten-1.mp3"
fetch "hf_20260815_184714_5f10a786-5bd1-47b1-a993-a7dc3b354f58.mp3" "nina-intro-keuken-1.mp3"

# Added when the speaker was recast as Nina: the round's opening instruction,
# the rolling step, the per-source nudges and the restart line.
fetch "hf_20260815_175136_c3660c19-ed26-468b-8be7-8d0e52496f3e.mp3" "nina-keuken-opdracht-1.mp3"
fetch "hf_20260815_175136_4fe525bc-99f1-4463-a7a4-f3102fcc75a4.mp3" "nina-keuken-uitrollen-1.mp3"
fetch "hf_20260815_175136_2e04017d-1185-411d-9240-a1e7b10a3e79.mp3" "nina-keuken-deegKlaar-1.mp3"
fetch "hf_20260815_175136_a28daf0b-07c0-4836-a5e6-aa0960c2441c.mp3" "nina-keuken-pakGlimmend-1.mp3"
fetch "hf_20260815_175136_6f01e091-4bbd-4bb8-8baf-8dd6ab73bad1.mp3" "nina-bron-aanrecht-1.mp3"
fetch "hf_20260815_175144_559353e5-0ff5-48b3-bdab-d5cd2a1a7fcd.mp3" "nina-keuken-opnieuw-1.mp3"

# Added when the round grew from three ingredients to five and the last step
# became carrying the cake up onto the plank. `nina-bron-plank-1.mp3` is gone:
# there are two shelves now, so one line saying "van de plank" cannot say which.
# `nina.bron.mandje` was regenerated too — it used to say "de laatste", and the
# basket is the fourth of five.
fetch "hf_20260815_184714_08f439dc-c01e-4178-8cc1-cc2e51153b4c.mp3" "nina-bron-plankHoog-1.mp3"
fetch "hf_20260815_184714_6712901d-9454-426a-b9b9-5f928dc4c643.mp3" "nina-bron-plankHoog-2.mp3"
fetch "hf_20260815_184714_64768b4a-d431-48b1-b3c7-7bac773559fd.mp3" "nina-bron-plankLaag-1.mp3"
fetch "hf_20260815_184714_06b431ef-2524-4f27-b0d8-485d63e2bed3.mp3" "nina-bron-plankLaag-2.mp3"
fetch "hf_20260815_184714_21f8565a-8a58-46fb-9d24-7fefc80beaff.mp3" "nina-bron-mandje-1.mp3"
fetch "hf_20260815_184714_4e712266-e289-49bf-8c4f-9fac65f661ce.mp3" "nina-bron-mandje-2.mp3"
fetch "hf_20260815_184714_1b8c8473-fdf1-4492-9e18-ebc15622fefd.mp3" "nina-bron-krat-1.mp3"
fetch "hf_20260815_184714_bd77d669-60b4-400b-81e4-076799fce0fa.mp3" "nina-bron-krat-2.mp3"
fetch "hf_20260815_184714_19bf60cc-4e95-4327-a8b6-ccd6010db992.mp3" "nina-keuken-opDePlank-1.mp3"
fetch "hf_20260815_184714_19a8dcf7-0a07-45ce-9c7f-c2191ac9d887.mp3" "nina-keuken-opDePlank-2.mp3"

echo "Otto:"
fetch "hf_20260815_122030_2dec7cd2-aaf3-4f1b-8d55-611737cd89d3.mp3" "otto-tik-1.mp3"
fetch "hf_20260815_122030_56f580f6-2d4c-4108-aeaa-e8aa0f13617e.mp3" "otto-tik-2.mp3"
fetch "hf_20260815_122030_02f4b842-27e8-44e8-b2c6-dd50b28deeb2.mp3" "otto-tik-3.mp3"
fetch "hf_20260815_122030_0aaf216d-eaf6-496c-93d9-0e4edb57997d.mp3" "otto-tik-4.mp3"
fetch "hf_20260815_122030_0f7c02d4-3db7-47e5-979b-2893e45edee5.mp3" "otto-tik-5.mp3"
fetch "hf_20260815_122030_518872a7-71eb-41a8-bdbf-efa422da8b55.mp3" "otto-vormErin-1.mp3"
fetch "hf_20260815_122030_fa5b2ab4-c19a-434e-87f6-0422c5ef8482.mp3" "otto-vormErin-2.mp3"
fetch "hf_20260815_122030_7804a3b8-43c4-461f-a227-3a91393ce7fd.mp3" "otto-bakken-1.mp3"
fetch "hf_20260815_122030_2498da9e-a56e-423f-a067-a1f1bbd977b6.mp3" "otto-bakken-2.mp3"
fetch "hf_20260815_122030_59c3b1f2-90b7-47ee-affb-c14976a4e004.mp3" "otto-klaar-1.mp3"
fetch "hf_20260815_122030_7d9eedb0-09f0-4e72-ab4e-79852d4f1d37.mp3" "otto-klaar-2.mp3"
fetch "hf_20260815_122030_671ebe88-9f64-4662-b7d2-e490d3434a3d.mp3" "otto-klaar-3.mp3"
fetch "hf_20260815_122041_22c8e1e8-b926-46b4-a6d2-4dedd781e7cb.mp3" "otto-wacht-1.mp3"
fetch "hf_20260815_122041_9294bce9-6ec8-4038-9ec5-49ca0ac00737.mp3" "otto-wacht-2.mp3"

# Start screen. text2speech_v2 / elevenlabs, generated 2026-08-23.
fetch "hf_20260823_083026_face77fa-7a39-47b7-992a-01ddd6055bbe.mp3" "nina-hub-eerste-1.mp3"
fetch "hf_20260823_083006_45d418f3-5282-48eb-a931-ebf31cd45692.mp3" "nina-hub-eerste-2.mp3"
fetch "hf_20260823_083006_e8027c5c-a270-45f3-b7f9-a3a25091c261.mp3" "nina-hub-terug-1.mp3"
fetch "hf_20260823_083006_9e1829d9-6cc2-4a54-a70c-ed0d57c6ec94.mp3" "nina-hub-terug-2.mp3"
fetch "hf_20260823_083006_8332bd3e-6622-49fa-8172-07dd3481c407.mp3" "nina-hub-terug-3.mp3"
fetch "hf_20260823_083006_32559eee-43bd-47a7-a3f7-88dd6ff71553.mp3" "nina-hub-terug-4.mp3"

# The scripts themselves are bundled: VoiceBank reads every script-*.json at
# launch to map line id -> variant files. The copies in `audio/` are canonical;
# copying them here is what keeps the two from drifting.
cp script-keuken.json "$OUT/script-keuken.json"
cp script-intro.json "$OUT/script-intro.json"
cp script-hub.json "$OUT/script-hub.json"

echo "Done. 104 lines in $OUT"
