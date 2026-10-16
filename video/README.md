[Back to Token Burn](../README.md)

# The advert

A 40-second square parody of a sports-watch advert, in which a developer overreaches on Claude, sets a 3.2-billion-token personal best and detrains on a beach.
It is built with [Remotion](https://www.remotion.dev/) 4, and `make video` renders it into [`docs/media/video/`](../docs/media/video/README.md).

## How it is put together

| Piece | Where it comes from |
| --- | --- |
| Stills | AI images from Codex image generation (`gen-images.sh`), in `public/gen` |
| Watch screens | Token Burn itself, captured in the Connect IQ simulator from the joke snapshots in `data/`, in `public/watch` |
| Voiceover | OpenAI `gpt-audio` (voice onyx) through OpenRouter (`make-voice.py`), in `public/vo`; the committed takes were trimmed of pauses by hand |
| Captions | Word by word from Whisper timestamps snapped to the speech (`align-captions.py`), in `src/captions.ts` |
| Music | A cue from Google Lyria 3 through OpenRouter (`make-music-lyria.py`), cut to the edit by `make-track.sh` |
| Type | Barlow Condensed, in `public/fonts` |

`src/TokenBurn.tsx` holds the edit: each scene's still and watch screen, the voice timings, the music ducking under the voice, and the motion, from the slow push-ins to the confetti on the PR.
The three wrist shots were generated with blank screens, and the watch captures are composited onto them at the positions in `SCREENS`.

## Re-rendering

```sh
make video
```

That needs Node.js and ffmpeg; it installs the packages, cuts the music, renders, and normalises the loudness to -14 LUFS.
`npm run studio` in this folder opens Remotion's preview.

Regenerating the voice or music needs an OpenRouter key in `OPENROUTER_API_KEY`; the scripts read it from the environment and never write it down.
See [CREDITS.md](CREDITS.md) for where every asset came from.
