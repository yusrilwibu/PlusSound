import yt_dlp
import json

ydl_opts = {
    'format': 'bestaudio[ext=m4a]/bestaudio/best',
    'quiet': True,
    'no_warnings': True,
    'extract_flat': False,
    'extractor_args': {
        'youtube': {
            'player_client': ['android', 'web']
        }
    }
}
url = "https://www.youtube.com/watch?v=YykjpeuMNEk"
with yt_dlp.YoutubeDL(ydl_opts) as ydl:
    try:
        info = ydl.extract_info(url, download=False)
        print("SUCCESS:", info.get('url')[:100])
    except Exception as e:
        print("FAILED:", str(e))
