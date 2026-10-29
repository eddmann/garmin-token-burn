#!/usr/bin/env bash
# Generates the wrist and end-card stills with Codex image generation, then
# converts them to JPEG (run once; outputs in public/gen). Set CODEX if codex
# is not on PATH.
set -u
C="${CODEX:-codex}"
STYLE="Photorealistic, cinematic sports-advert look, square 1024x1024, no text, no logos or brand names anywhere, generic people whose faces are not recognisable."
WATCH="wearing a plain black round sports watch with no logos or text, watch face seen straight-on and filling about 35% of the frame width, its round screen completely pure black (#000000) and blank"
gen() { # name prompt
  [ -f "public/gen/$1.jpg" ] && return
  $C exec --skip-git-repo-check --sandbox workspace-write -C "$PWD" \
    "Use your image generation tool to create one image. $2 $STYLE Save it to public/gen/$1.png and reply with only the saved path." > "public/gen/$1.log" 2>&1
}
gen wrist-dawn "Close-up of a left wrist resting on a laptop keyboard at dawn, $WATCH; warm early-morning light, shallow depth of field." &
gen wrist-finish "Close-up of a sweaty athlete's raised left wrist, $WATCH; blurred stadium lights and a finish line behind." &
gen wrist-beach "Close-up of a relaxed left wrist resting on a sun lounger at a tropical beach, $WATCH; a closed laptop half-buried in sand and a cocktail blurred in the background, bright midday sun." &
gen embers "Abstract dark background of glowing orange embers and sparks drifting upwards on black, soft bokeh, suitable as a title-card background." &
wait
for png in public/gen/*.png; do
  [ -f "$png" ] || continue
  sips -s format jpeg -s formatOptions 90 "$png" --out "${png%.png}.jpg" > /dev/null && rm "$png" "${png%.png}.log"
done
