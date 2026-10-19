[Back to Token Burn](../README.md)

# The advert

A 40-second square parody of a sports-watch advert, in which a developer overreaches on Claude, sets a 3.2-billion-token personal best and detrains on a beach.
Both cuts share one [Remotion](https://www.remotion.dev/) 4 edit, narration, captions,
music, watch close-ups and end card.

| Cut | Composition | Render from the repository root | Finished film |
| --- | --- | --- | --- |
| Original, with generated stills | `TokenBurn` | `make video` | [token-burn.mp4](../docs/media/video/token-burn.mp4) |
| Stock footage | `TokenBurnStock` | `make video/stock` | [token-burn-stock.mp4](../docs/media/video/token-burn-stock.mp4) |

The stock cut replaces six lifestyle stills with real running, typing, finish-line,
recovery, late-night coding and beach footage. The wrist shots retain the original
generated backgrounds and real simulator captures. The stock performers are a
montage, rather than a single continuing character.

## Where things live

| Path | Purpose |
| --- | --- |
| `src/` | Shared timeline, two composition entry points, watch compositing, captions and music ducking |
| `public/` | Committed assets needed to render: stock takes, generated stills, watch screens, voice, source music and fonts |
| `stock-sources.json` | Stock creators, source and download links, trims, playback speed and square crop positions |
| `prepare-stock.py` | Rebuild the six silent, colour-adjusted 1080 × 1080 stock takes from that manifest |
| `make-track.sh`, `check-track.py` | Assemble and check the full 40-second music bed |
| `render.sh` | Render either cut, export its poster and normalise audio to -14 LUFS |
| `../docs/media/video/` | Finished MP4s and posters, for viewing and linking from the repository |
| `out/` | Ignored render intermediates and downloaded stock originals |

Keep the prepared stock takes so a fresh checkout can render without fetching
footage or using an AI service. Raw downloads, intermediate renders,
`public/music/track.wav` and `node_modules/` stay ignored. The private screening
website is a separate Sites project, not part of this repository.

## How it is put together

| Piece | Where it comes from |
| --- | --- |
| Stills | AI images from Codex image generation (`gen-images.sh`), in `public/gen` |
| Stock footage | Six Pexels clips prepared with `prepare-stock.py`, in `public/stock`; sources and edit settings in `stock-sources.json` |
| Watch screens | Token Burn itself, captured in the Connect IQ simulator from the joke snapshots in `data/`, in `public/watch` |
| Voiceover | OpenAI `gpt-audio` (voice onyx) through OpenRouter (`make-voice.py`), in `public/vo`; the committed takes were trimmed of pauses by hand |
| Captions | Word by word from Whisper timestamps snapped to the speech (`align-captions.py`), in `src/captions.ts` |
| Music | A cue from Google Lyria 3 through OpenRouter (`make-music-lyria.py`), cut to the edit by `make-track.sh` |
| Type | Barlow Condensed, in `public/fonts` |

`src/TokenBurn.tsx` holds the shared edit: each scene's background and watch screen, the voice timings, the music ducking under the voice, and the motion, from the slow push-ins to the confetti on the PR.
The three wrist shots were generated with blank screens, and the watch captures are composited onto them at the positions in `SCREENS`.
The stock takes have no source audio. `make-track.sh` crossfades into a quieter
beach bed and brings the music back under the end title, fading out at 40 seconds.
`check-track.py` catches a short music file or a missing beach/title bed before rendering.

## Re-rendering

```sh
make video
# or the stock-footage cut:
make video/stock
```

That needs Node.js, Python 3 and ffmpeg; it installs the pinned packages, cuts and
checks the music, renders, and normalises the loudness to -14 LUFS. No API keys,
paid credits or stock downloads are needed to render the committed assets.
If using an existing Chrome/Chromium installation, set `REMOTION_BROWSER_EXECUTABLE`
to its executable path when running the make target.
`npm run studio` in this folder opens Remotion's preview.

`make video/check` installs the pinned packages, type-checks both cuts, and
assembles and checks the music without rendering the film. It needs no Garmin SDK.
The separate video CI job runs the same check.

## Changing the stock takes

Edit the trim, `speed` (default 1), `crop_x` and `crop_y` values in
`stock-sources.json`, then run:

```sh
make video/stock-assets
# Or prepare just one take:
python3 video/prepare-stock.py finish
```

Crop positions run from 0 (left/top) to 1 (right/bottom). Durations are in seconds
of the prepared output and must match the corresponding scenes in the timeline.
The preparation step also needs curl and downloads missing originals into
`out/stock-originals/`. If changing a source URL, remove that shot's cached original
before preparing it again. Commit the updated take, recipe and credits together;
render the stock cut when the edit is ready.

Regenerating the voice or music needs an OpenRouter key in `OPENROUTER_API_KEY`; the scripts read it from the environment and never write it down.
See [CREDITS.md](CREDITS.md) for where every asset came from.
