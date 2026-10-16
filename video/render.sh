#!/usr/bin/env bash
#
# Renders the advert and its poster into docs/media/video, loudness-normalised
# to -14 LUFS for social video.
set -euo pipefail
cd "$(dirname "$0")"
out=../docs/media/video
npm ci --no-audit --no-fund --loglevel=error
./make-track.sh
npx remotion render TokenBurn out/token-burn.mp4 --codec h264 --crf 18 --log=error
npx remotion still TokenBurn out/poster.png --frame 294 --log=error
mkdir -p "$out"
ffmpeg -loglevel error -y -i out/token-burn.mp4 -c:v copy -af "loudnorm=I=-14:TP=-1.5:LRA=11" \
  -ar 48000 -c:a aac -b:a 192k -movflags +faststart "$out/token-burn.mp4"
cp out/poster.png "$out/poster.png"
echo "wrote $out/token-burn.mp4 and $out/poster.png"
