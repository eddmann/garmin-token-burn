"""Composes the trailer track with Google Lyria 3 via OpenRouter. Needs OPENROUTER_API_KEY.

Usage: python3 make-music-lyria.py <model> <out.mp3|.wav>
"""
import base64, json, os, sys, urllib.error, urllib.request

PROMPT = """Compose a 40-second instrumental epic sports-advert trailer cue, no vocals.
0-6s: sparse, hopeful dawn piano and low strings, soft pulse.
6-15s: tension rises, driving staccato strings and taiko drums, building.
15-17s: a big swell and cymbal riser.
17-21s: triumphant full-orchestra hit and anthem for a personal-best moment.
21-29s: pulls back to a steady, confident pulse with brass.
29-33s: drops almost to silence, a single comedic low note.
33-40s: final epic build into one huge closing hit with a long tail, ending cleanly at 40 seconds."""

model, out = sys.argv[1], sys.argv[2]
body = {"model": model, "modalities": ["text", "audio"], "stream": True, "messages": [{"role": "user", "content": PROMPT}]}
req = urllib.request.Request("https://openrouter.ai/api/v1/chat/completions", data=json.dumps(body).encode(),
    headers={"Authorization": f"Bearer {os.environ['OPENROUTER_API_KEY']}", "Content-Type": "application/json"})
chunks, fmt, usage, text, seen = [], None, None, "", set()
try:
    with urllib.request.urlopen(req, timeout=900) as resp:
        for raw in resp:
            line = raw.decode().strip()
            if not line.startswith("data: ") or line == "data: [DONE]":
                continue
            chunk = json.loads(line[6:])
            usage = chunk.get("usage") or usage
            for choice in chunk.get("choices", []):
                delta = choice.get("delta", {})
                seen.update(delta.keys())
                audio = delta.get("audio") or {}
                if audio.get("data"):
                    chunks.append(audio["data"])
                fmt = audio.get("format") or fmt
                if isinstance(delta.get("content"), str):
                    text += delta["content"]
except urllib.error.HTTPError as e:
    print("HTTP", e.code, e.read().decode()[:600])
    sys.exit(1)
if not chunks:
    print("no audio; delta keys seen:", seen, "text:", text[:300])
    sys.exit(1)
blob = b"".join(base64.b64decode(c) for c in chunks)
open(out, "wb").write(blob)
print("wrote", out, len(blob), "bytes, format:", fmt, "cost:", (usage or {}).get("cost"), "text:", text[:120])
