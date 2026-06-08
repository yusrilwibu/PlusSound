import urllib.request
import json
import socket

instances = [
    "https://cobalt.qck.dev",
    "https://co.wuk.sh",
    "https://cobalt.kwiatekm.dev",
    "https://api.cobalt.tools",
    "https://cobalt.owo.su",
    "https://api.cobalt.tools"
]

data = json.dumps({"url": "https://www.youtube.com/watch?v=YykjpeuMNEk"}).encode()
headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0"
}

for instance in instances:
    try:
        req = urllib.request.Request(instance, data=data, headers=headers)
        with urllib.request.urlopen(req, timeout=3) as response:
            res = json.loads(response.read().decode())
            print(f"[SUCCESS] {instance}: {str(res)[:150]}")
    except Exception as e:
        print(f"[FAILED] {instance}: {e}")
