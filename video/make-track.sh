#!/usr/bin/env bash
#
# Cuts the 63s Lyria cue to the 40s edit: the swell lands on the PR buzz,
# the quieter tail sits under "Detraining" and the climax hits the end card.
# Read each section independently: a shared input can truncate the crossfade
# chain before its later sections have been consumed.
set -euo pipefail
cd "$(dirname "$0")/public/music"
ffmpeg -loglevel error -y -i lyria.mp3 -i lyria.mp3 -i lyria.mp3 -filter_complex "\
aevalsrc=0:d=1.4:s=44100:c=stereo[silence];\
[0:a]atrim=start=0:end=28.4,asetpts=PTS-STARTPTS[build];\
[1:a]atrim=start=56.5:end=61.5,asetpts=PTS-STARTPTS[tail];\
[2:a]atrim=start=31.8:end=38.2,asetpts=PTS-STARTPTS,afade=t=out:st=4.8:d=1.6[climax];\
[silence][build]concat=n=2:v=0:a=1[opening];\
[opening][tail]acrossfade=d=0.6:c1=qsin:c2=qsin[middle];\
[middle][climax]acrossfade=d=0.6:c1=qsin:c2=qsin,atrim=duration=40[out]" -map "[out]" -ar 48000 -ac 2 track.wav
