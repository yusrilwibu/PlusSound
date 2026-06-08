import urllib.request
import json
import socket

instances = [
    "https://pipedapi.kavin.rocks",
    "https://pipedapi.smnz.de",
    "https://pipedapi.tokhmi.xyz",
    "https://pipedapi.drgns.space",
    "https://pipedapi.syncpundit.io",
    "https://piped-api.garudalinux.org",
    "https://pipedapi.projectsegfau.lt",
    "https://api.piped.privacydev.net",
    "https://piped-api.lunar.icu"
]

video_id = "YykjpeuMNEk"
headers = {"User-Agent": "Mozilla/5.0"}

for instance in instances:
    url = f"{instance}/streams/{video_id}"
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=3) as response:
            data = json.loads(response.read().decode())
            audio_streams = data.get("audioStreams", [])
            if audio_streams:
                print(f"[SUCCESS] {instance}: Found {len(audio_streams)} audio streams")
                # print(audio_streams[0]['url'][:100])
            else:
                print(f"[NO_AUDIO] {instance}: Error or no audio streams")
    except Exception as e:
        print(f"[FAILED] {instance}: {e}")
