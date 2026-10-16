#!/usr/bin/env bash
#
# Cuts the 63s Lyria cue to the 40s edit: the swell lands on the PR buzz,
# the fading tail sits under "Detraining" and the climax hits the end card.
set -euo pipefail
cd "$(dirname "$0")/public/music"
ffmpeg -loglevel error -y -i lyria.mp3 -filter_complex "\
aevalsrc=0:d=1.4:s=44100:c=stereo[silence];\
[0]atrim=0:27.95,asetpts=PTS-STARTPTS[build];\
[0]atrim=56.5:61.05,asetpts=PTS-STARTPTS[tail];\
[0]atrim=31.8:38.35,asetpts=PTS-STARTPTS,afade=t=out:st=4.9:d=1.6[climax];\
[silence][build]concat=n=2:v=0:a=1[opening];\
[opening][tail]acrossfade=d=0.15[middle];\
[middle][climax]acrossfade=d=0.15[out]" -map "[out]" -ar 48000 -ac 2 track.wav
