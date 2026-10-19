#!/usr/bin/env python3
"""Catch a truncated music edit before spending time rendering the film."""
import array
import math
import pathlib
import wave

track = pathlib.Path(__file__).resolve().parent / 'public/music/track.wav'
with wave.open(str(track), 'rb') as audio:
    duration = audio.getnframes() / audio.getframerate()
    if abs(duration - 40) > 1 / audio.getframerate():
        raise SystemExit(f'Music must cover the 40-second film; got {duration:.3f}s')
    if audio.getsampwidth() != 2:
        raise SystemExit('Expected 16-bit PCM music')
    # Check the beach transition and title bed, excluding the final fade to zero.
    for second in range(29, 39):
        audio.setpos(second * audio.getframerate())
        samples = array.array('h', audio.readframes(audio.getframerate()))
        rms = math.sqrt(sum(sample * sample for sample in samples) / len(samples))
        if rms < 32768 * 10 ** (-50 / 20):
            raise SystemExit(f'Music is silent or too quiet at {second}–{second + 1}s')
print('ok: music covers 40 seconds, including the beach transition and end title')
