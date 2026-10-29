#!/usr/bin/env python3
"""Download the six Pexels clips and cut silent square takes for the stock edit."""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent
SOURCES = json.loads((ROOT / 'stock-sources.json').read_text())
selected = set(sys.argv[1:])
unknown = selected - {shot['name'] for shot in SOURCES}
if unknown:
    raise SystemExit(f"Unknown shot(s): {', '.join(sorted(unknown))}")
CACHE = ROOT / 'out' / 'stock-originals'
OUTPUT = ROOT / 'public' / 'stock'
CACHE.mkdir(parents=True, exist_ok=True)
OUTPUT.mkdir(parents=True, exist_ok=True)

for shot in SOURCES:
    if selected and shot['name'] not in selected:
        continue
    original = CACHE / f"{shot['name']}.mp4"
    if not original.exists():
        download = original.with_suffix('.part')
        subprocess.run([
            'curl', '--fail', '--location', '--silent', '--show-error',
            '--retry', '2', '--max-time', '180',
            '--output', str(download), shot['download'],
        ], check=True)
        download.replace(original)
    filters = (
        f"setpts=(PTS-STARTPTS)/{shot.get('speed', 1)},"
        'scale=1080:1080:force_original_aspect_ratio=increase,'
        f"crop=1080:1080:(iw-ow)*{shot['crop_x']}:(ih-oh)*{shot['crop_y']},"
        'setsar=1,fps=30,eq=contrast=1.04:saturation=0.9'
    )
    prepared = OUTPUT / f"{shot['name']}.mp4"
    temporary = prepared.with_suffix('.partial.mp4')
    subprocess.run([
        'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
        '-ss', str(shot['start']), '-i', str(original),
        '-t', str(shot['duration']), '-an', '-vf', filters,
        '-c:v', 'libx264', '-preset', 'fast', '-crf', '19',
        '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
        str(temporary),
    ], check=True)
    temporary.replace(prepared)
    print(f"Prepared {shot['name']}: {shot['duration']}s", flush=True)
