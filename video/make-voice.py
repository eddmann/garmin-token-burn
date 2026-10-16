"""Voices each line with openai/gpt-audio via OpenRouter. Needs OPENROUTER_API_KEY in the environment.

Usage: python3 make-voice.py <voice> <name> [<name> ...]   (names from LINES; writes public/vo/<name>.wav)
"""
import base64, json, os, sys, urllib.request, wave

LINES = {
    "l1": ("Every day, you push your limits.", "slow, weighty, inspirational"),
    "l2": ("Your watch knows when you've gone too far.", "low and knowing"),
    "l3": ("Three refactors before lunch", "low, weighty and knowing, the same narrator as the rest of the advert, said as one continuous phrase with no pause, stress on lunch"),
    "l4": ("Personal best. Three point two billion tokens.", "triumphant, building to the number"),
    "l5": ("Recovery is part of training.", "calm and wise"),
    "l6": ("Burn load: high. A forty-seven-day streak.", "grave and impressed"),
    "l7": ("Detraining.", "deeply disappointed, slow, a heavy sigh in the voice"),
    "l8": ("Token Burn. Feel the Token Burn.", "epic closing tagline, unhurried"),
}

def speak(voice, text, delivery):
    body = {
        "model": "openai/gpt-audio",
        "modalities": ["text", "audio"],
        "audio": {"voice": voice, "format": "pcm16"},
        "stream": True,
        "messages": [
            {"role": "system", "content": "You are a voice actor for a sports-watch TV advert. Speak in a deep, dramatic British male trailer-narrator voice. Say exactly the line you are given and nothing else."},
            {"role": "user", "content": f"Delivery: {delivery}. Line: {text}"},
        ],
    }
    req = urllib.request.Request("https://openrouter.ai/api/v1/chat/completions", data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {os.environ['OPENROUTER_API_KEY']}", "Content-Type": "application/json"})
    pcm, usage, said = bytearray(), None, ""
    with urllib.request.urlopen(req, timeout=120) as resp:
        for raw in resp:
            line = raw.decode().strip()
            if not line.startswith("data: ") or line == "data: [DONE]":
                continue
            chunk = json.loads(line[6:])
            usage = chunk.get("usage") or usage
            for choice in chunk.get("choices", []):
                audio = choice.get("delta", {}).get("audio") or {}
                if audio.get("data"):
                    pcm += base64.b64decode(audio["data"])
                said += audio.get("transcript", "")
    return bytes(pcm), usage, said

voice = sys.argv[1]
for name in sys.argv[2:]:
    text, delivery = LINES[name]
    pcm, usage, said = speak(voice, text, delivery)
    with wave.open(f"public/vo/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(24000); w.writeframes(pcm)
    print(name, f"{len(pcm) / 48000:.2f}s", repr(said.strip()), "cost:", (usage or {}).get("cost"))
