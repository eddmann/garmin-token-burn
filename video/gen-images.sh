#!/usr/bin/env bash
# Generates the stills with Codex image generation, then converts them to JPEG
# (run once; outputs in public/gen). Set CODEX if codex is not on PATH.
set -u
C="${CODEX:-codex}"
STYLE="Photorealistic, cinematic sports-advert look, square 1024x1024, no text, no logos or brand names anywhere, generic people whose faces are not recognisable."
gen() { # name prompt
  [ -f "public/gen/$1.jpg" ] && return
  $C exec --skip-git-repo-check --sandbox workspace-write -C "$PWD" \
    "Use your image generation tool to create one image. $2 $STYLE Save it to public/gen/$1.png and reply with only the saved path." > "public/gen/$1.log" 2>&1
}
gen runner-dawn "A runner crouched lacing up running shoes on a city pavement at dawn, low angle, golden backlight, breath visible in cold air, face out of frame." &
gen typing "Extreme close-up of hands typing furiously on a laptop keyboard in a dark room, the screen's glow lighting the hands in cool blue, motion blur on the fingers, a coffee mug and scattered sticky notes; the screen itself is out of frame." &
gen finish-line "A distance runner breaking the finish-line tape in a stadium, arms raised, shot from behind and slightly to the side so the face is not visible, slow-motion feel, confetti and stadium lights bokeh." &
wait
gen wrist-finish "Close-up of a sweaty athlete's raised left wrist wearing a plain black round sports watch with no logos or text, watch face seen straight-on and filling about 35% of the frame width, its round screen completely pure black (#000000) and blank; blurred stadium lights and a finish line behind." &
gen sofa "A software developer asleep on a sofa in a dim living room in the evening, a closed laptop resting on their chest, one arm hanging off the sofa, cosy lamp light, face turned away from the camera." &
gen coach "An older athletics coach in a tracksuit standing at the edge of a running track, holding a stopwatch and a clipboard, nodding gravely, overcast light, shallow depth of field, face partly in shadow and not a real person." &
wait
gen wrist-beach "Close-up of a relaxed left wrist resting on a sun lounger at a tropical beach, wearing a plain black round sports watch with no logos or text, watch face seen straight-on and filling about 35% of the frame width, its round screen completely pure black (#000000) and blank; a closed laptop half-buried in sand and a cocktail blurred in the background, bright midday sun." &
gen beach "A closed laptop lying abandoned on a beach towel beside a cocktail with an umbrella, turquoise sea and palm trees behind, bright holiday sunshine, wide shot." &
gen embers "Abstract dark background of glowing orange embers and sparks drifting upwards on black, soft bokeh, suitable as a title-card background." &
wait
for png in public/gen/*.png; do
  sips -s format jpeg -s formatOptions 90 "$png" --out "${png%.png}.jpg" > /dev/null && rm "$png" "${png%.png}.log"
done
