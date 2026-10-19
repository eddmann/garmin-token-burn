#!/usr/bin/env bash
#
# Renders the advert and its poster into docs/media/video, loudness-normalised
# to -14 LUFS for social video.
set -euo pipefail
cd "$(dirname "$0")"
out=../docs/media/video
composition=${1:-TokenBurn}
case "$composition" in
  TokenBurn) name=token-burn; poster=poster; poster_frame=294 ;;
  TokenBurnStock) name=token-burn-stock; poster="poster-stock"; poster_frame=160 ;;
  *) echo "Unknown film composition: $composition" >&2; exit 1 ;;
esac
browser_args=()
if [[ -n "${REMOTION_BROWSER_EXECUTABLE:-}" ]]; then
  browser_args+=(--browser-executable "$REMOTION_BROWSER_EXECUTABLE")
fi
npm ci --no-audit --no-fund --loglevel=error
./make-track.sh
python3 check-track.py
npx remotion render "$composition" "out/$name.mp4" --codec h264 --crf 18 --log=error "${browser_args[@]}"
npx remotion still "$composition" "out/$name-poster.png" --frame "$poster_frame" --log=error "${browser_args[@]}"
mkdir -p "$out"
ffmpeg -loglevel error -y -i "out/$name.mp4" -c:v copy -af "loudnorm=I=-14:TP=-1.5:LRA=11" \
  -ar 48000 -c:a aac -b:a 192k -movflags +faststart "$out/$name.mp4"
cp "out/$name-poster.png" "$out/$poster.png"
echo "wrote $out/$name.mp4 and $out/$poster.png"
