#!/usr/bin/env bash
# Dice & runes pack (docs/08_prompts/DICE_RUNES_PROMPTS.md), generated 2026-10-14 via Higgsfield Nano Banana 2.1, 2K.
# Downloads the raw 2048px PNGs and ingests them into Assets.xcassets (@1x/@2x/@3x).
# Run from the repo root on the Mac:  bash scripts/fetch_dice_runes.sh
set -euo pipefail
RAW=_audit_tmp/dice_runes_raw; mkdir -p "$RAW"
OUT=Hexbound/Hexbound/Resources/Assets.xcassets
# Resumable: a raw that is already downloaded is not fetched again.
fetch() { [ -s "$1" ] || curl -fsSL -o "$1" "$2"; }

fetch "$RAW/dice-face-attack.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_164600_21069059-e2bf-4019-9c54-392059ae351f.png"
python3 scripts/ingest_generated_sprite.py "$RAW/dice-face-attack.png" dice-face-attack --pt 104 --key FF00FF
fetch "$RAW/dice-face-guard.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165305_dca9152a-eb3d-45a1-8f15-14b9e388c501.png"
python3 scripts/ingest_generated_sprite.py "$RAW/dice-face-guard.png" dice-face-guard --pt 104 --key FF00FF
fetch "$RAW/dice-showcase-attack.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165928_17b8cc75-838a-495a-a068-62335941249f.png"
python3 scripts/ingest_generated_sprite.py "$RAW/dice-showcase-attack.png" dice-showcase-attack --pt 200 --key FF00FF
fetch "$RAW/dice-showcase-guard.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165928_b3108cab-01e5-4931-917f-266f438b85d9.png"
python3 scripts/ingest_generated_sprite.py "$RAW/dice-showcase-guard.png" dice-showcase-guard --pt 200 --key FF00FF
fetch "$RAW/dice-zone-head.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165113_1a9e78c7-c853-407a-bd5e-d4a199828e73.png"
python3 scripts/ingest_generated_sprite.py "$RAW/dice-zone-head.png" dice-zone-head --pt 48 --key FF00FF
fetch "$RAW/dice-zone-body.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165306_7869c146-ab8a-4854-8345-1616ed3fe5fb.png"
python3 scripts/ingest_generated_sprite.py "$RAW/dice-zone-body.png" dice-zone-body --pt 48 --key FF00FF
fetch "$RAW/dice-zone-legs.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165307_eb54e524-6a05-4be3-b04a-3a68a4f1b156.png"
python3 scripts/ingest_generated_sprite.py "$RAW/dice-zone-legs.png" dice-zone-legs --pt 48 --key FF00FF
fetch "$RAW/rune-socket-empty.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165113_8712e8cf-2b98-42c7-a9aa-79e188681d7d.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-socket-empty.png" rune-socket-empty --pt 40 --key FF00FF
fetch "$RAW/rune-socket-locked.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165306_9b2d6070-ba89-459f-9732-2e3223b768d9.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-socket-locked.png" rune-socket-locked --pt 40 --key FF00FF
fetch "$RAW/rune-warrior-wrath.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_164637_fb74e566-f132-4288-80f6-70c27320ee46.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-warrior-wrath.png" rune-warrior-wrath --pt 64 --key FF00FF
fetch "$RAW/rune-warrior-beast.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165736_ae96d9a9-4ca9-4547-a712-1f50045ceb0d.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-warrior-beast.png" rune-warrior-beast --pt 64 --key FF00FF
fetch "$RAW/rune-warrior-blade.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165114_dab22ea5-b8f2-413b-81ef-4c5f16c6b7cf.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-warrior-blade.png" rune-warrior-blade --pt 64 --key FF00FF
fetch "$RAW/rune-warrior-mail.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165114_1240972f-6c4c-4747-9001-1c98e1f0b9ba.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-warrior-mail.png" rune-warrior-mail --pt 64 --key FF00FF
fetch "$RAW/rune-warrior-endurance.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165114_1dc353d6-0609-4315-aaa4-0495ccb08995.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-warrior-endurance.png" rune-warrior-endurance --pt 64 --key FF00FF
fetch "$RAW/rune-rogue-bloodletting.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165115_5da67340-b79b-44c7-ad1f-d2ed81a79b74.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-rogue-bloodletting.png" rune-rogue-bloodletting --pt 64 --key FF00FF
fetch "$RAW/rune-rogue-smoke.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165113_a3b59d61-3b75-4183-b492-66972fecbc5f.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-rogue-smoke.png" rune-rogue-smoke --pt 64 --key FF00FF
fetch "$RAW/rune-warrior-frenzy.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165307_427c4613-6793-4f65-891f-d348d78b464b.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-warrior-frenzy.png" rune-warrior-frenzy --pt 64 --key FF00FF
fetch "$RAW/rune-rogue-evasion.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165306_a0b21c1b-6826-46ba-8cae-9c00769bd00a.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-rogue-evasion.png" rune-rogue-evasion --pt 64 --key FF00FF
fetch "$RAW/rune-rogue-dagger.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165433_0fcecc8c-9a6e-4473-ad1b-d0ca50fd7f50.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-rogue-dagger.png" rune-rogue-dagger --pt 64 --key FF00FF
fetch "$RAW/rune-mage-mana.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165432_a0fc9417-09ca-421a-8c4e-a3196fe43347.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-mage-mana.png" rune-mage-mana --pt 64 --key 00FF00
fetch "$RAW/rune-mage-mirror.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165432_cc5ee620-4d3d-461b-9a33-9983c5276261.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-mage-mirror.png" rune-mage-mirror --pt 64 --key 00FF00
fetch "$RAW/rune-tank-ram.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165432_54c96477-af19-4dde-a8be-921eea0b2afe.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-tank-ram.png" rune-tank-ram --pt 64 --key FF00FF
fetch "$RAW/rune-tank-stone.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165434_9cb5c4b9-b13f-4782-aba5-bcd8163e3d34.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-tank-stone.png" rune-tank-stone --pt 64 --key FF00FF
fetch "$RAW/rune-tank-thorns.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165433_2d257c8a-e116-43be-8cfd-7a51028776ce.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-tank-thorns.png" rune-tank-thorns --pt 64 --key FF00FF
fetch "$RAW/rune-tank-fortify.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165431_9060e3b2-0cae-4d09-af4c-f2fbabc4243d.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-tank-fortify.png" rune-tank-fortify --pt 64 --key FF00FF
fetch "$RAW/rune-mage-spark.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165639_3b41a6ec-9b61-49c9-8482-8e9b80adfc38.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-mage-spark.png" rune-mage-spark --pt 64 --key 00FF00
fetch "$RAW/rune-mage-barrier.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165641_b1228dd4-5340-4654-a572-8e8deda84c17.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-mage-barrier.png" rune-mage-barrier --pt 64 --key 00FF00
fetch "$RAW/rune-warrior-bulwark.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165639_f4f16dbb-d23f-4586-ad0a-01f8053a6c03.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-warrior-bulwark.png" rune-warrior-bulwark --pt 64 --key FF00FF
fetch "$RAW/rune-warrior-headsman.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165640_47211a9d-2ecd-4d54-8510-526c86a36004.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-warrior-headsman.png" rune-warrior-headsman --pt 64 --key FF00FF
fetch "$RAW/rune-rogue-shadowstrike.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165638_9d614bb7-86f3-44d9-9d13-cf7dd5e5bfe5.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-rogue-shadowstrike.png" rune-rogue-shadowstrike --pt 64 --key FF00FF
fetch "$RAW/rune-rogue-riposte.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165640_2b12791d-bd19-45af-84dd-6866ded9b66d.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-rogue-riposte.png" rune-rogue-riposte --pt 64 --key FF00FF
fetch "$RAW/rune-rogue-venom.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165639_a8384978-a0cf-4767-9543-832894aa9cba.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-rogue-venom.png" rune-rogue-venom --pt 64 --key FF00FF
fetch "$RAW/rune-mage-flow.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165736_d38474e4-bea5-42c5-8981-0d4aa4d6a877.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-mage-flow.png" rune-mage-flow --pt 64 --key 00FF00
fetch "$RAW/rune-tank-wall.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165735_3ad17e9d-b3a1-42a5-a45f-2ff897d60b01.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-tank-wall.png" rune-tank-wall --pt 64 --key FF00FF
fetch "$RAW/rune-tank-unbreakable.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165736_f0759bba-eb46-475f-82ef-d0eca88f28cb.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-tank-unbreakable.png" rune-tank-unbreakable --pt 64 --key FF00FF
fetch "$RAW/rune-mage-flame.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165927_9d9e3381-6b93-4e42-8620-c2485d331b56.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-mage-flame.png" rune-mage-flame --pt 64 --key 00FF00
fetch "$RAW/rune-mage-frost.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165928_2c6aab07-bbcb-4b27-8154-060927409293.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-mage-frost.png" rune-mage-frost --pt 64 --key 00FF00
fetch "$RAW/rune-tank-challenge.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_165929_e6ba0bc9-74bb-4a0d-ae31-c5f1be2bd14a.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-tank-challenge.png" rune-tank-challenge --pt 64 --key FF00FF
fetch "$RAW/rune-rogue-vanish.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_170043_9442dc45-6d22-464f-b6af-75b8aeeddc4f.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-rogue-vanish.png" rune-rogue-vanish --pt 64 --key FF00FF
fetch "$RAW/rune-rogue-reaper.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_170042_00e09def-2459-427a-9f05-547903347852.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-rogue-reaper.png" rune-rogue-reaper --pt 64 --key FF00FF
fetch "$RAW/rune-mage-meteor.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_170042_c427fdbf-6878-4c2f-a751-f82d1e9ce04e.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-mage-meteor.png" rune-mage-meteor --pt 64 --key 00FF00
fetch "$RAW/rune-mage-time.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_170042_946b28de-a624-4f9f-a437-1d3f57d6ff62.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-mage-time.png" rune-mage-time --pt 64 --key 00FF00
fetch "$RAW/rune-tank-earthshatter.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_170042_400ebe3c-4244-4211-bb3b-8e95b629360c.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-tank-earthshatter.png" rune-tank-earthshatter --pt 64 --key FF00FF
fetch "$RAW/rune-warrior-oath.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_170124_67cc7918-6987-4e0f-afe6-af0ecbd06f19.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-warrior-oath.png" rune-warrior-oath --pt 64 --key FF00FF
fetch "$RAW/rune-tank-bastion.png" "https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P/hf_20261014_170124_43a86aa8-921c-4427-9bc9-d5ebf4eac184.png"
python3 scripts/ingest_generated_sprite.py "$RAW/rune-tank-bastion.png" rune-tank-bastion --pt 64 --key FF00FF
echo "Done: 45 assets"
