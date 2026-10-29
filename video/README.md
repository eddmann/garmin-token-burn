[Back to Token Burn](../README.md)

# The advert

A 40-second square parody of a sports-watch advert, in which a developer overreaches on Claude, sets a 3.2-billion-token personal best and detrains on a beach.
It is built with [Remotion](https://www.remotion.dev/) 4, and `make video` renders it into [`docs/media/video/`](../docs/media/video/README.md).

## How it is put together

| Piece | Where it comes from |
| --- | --- |
| Footage | Six Pexels clips (running, typing, the finish line, recovery, late-night coding and the beach), prepared by `prepare-stock.py` into `public/stock`; sources, trims and crops are in `stock-sources.json` |
| Wrist and end-card stills | AI images from Codex image generation (`gen-images.sh`), in `public/gen` |
| Watch screens | Token Burn itself, captured in the Connect IQ simulator from the joke snapshots in `data/`, in `public/watch` |
| Voiceover | OpenAI `gpt-audio` (voice onyx) through OpenRouter (`make-voice.py`), in `public/vo`; the committed takes were trimmed of pauses by hand |
| Captions | Word by word from Whisper timestamps snapped to the speech (`align-captions.py`), in `src/captions.ts` |
| Music | A cue from Google Lyria 3 through OpenRouter (`make-music-lyria.py`), cut to the edit by `make-track.sh` and checked by `check-track.py` |
| Type | Barlow Condensed, in `public/fonts` |

`src/TokenBurn.tsx` holds the edit: each scene's footage or still and watch screen, the voice timings, the music ducking under the voice, and the motion, from the camera shake on the buzz to the confetti on the PR.
The three wrist shots were generated with blank screens, and the watch captures are composited onto them at the positions in `SCREENS`.
The stock takes are silent; the music crossfades into a quieter bed under the beach and comes back under the end title, fading out at 40 seconds.

## Re-rendering

```sh
make video
```

That needs Node.js, Python 3 and ffmpeg; it installs the pinned packages, cuts and checks the music, renders, and normalises the loudness to -14 LUFS.
Rendering uses only committed assets, so it needs no API keys, credits or downloads.
Set `REMOTION_BROWSER_EXECUTABLE` to use an existing Chrome or Chromium, and run `npm run studio` in this folder for Remotion's preview.

## Changing the footage

Edit a shot's `start`, `duration`, `speed` (default 1), `crop_x` or `crop_y` in `stock-sources.json`, then run:

```sh
make video/assets
```

Crop positions run from 0 (left or top) to 1 (right or bottom), and a duration must match its scene in the timeline.
The script needs curl, downloads any missing original into `out/stock-originals/`, and `python3 video/prepare-stock.py finish` prepares a single shot.
Commit the prepared take and its manifest entry together.

Regenerating the voice or music needs an OpenRouter key in `OPENROUTER_API_KEY`; the scripts read it from the environment and never write it down.
See [CREDITS.md](CREDITS.md) for where every asset came from.
