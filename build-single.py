#!/usr/bin/env python3
"""Build dist/BigClock.html — a single self-contained file version of the app.

Inlines the icons as data URIs and removes references to external files
(manifest, service worker) that don't exist when the app is a lone file.
Re-run after editing index.html:  python3 build-single.py
"""
import base64
import json
import pathlib
import re

root = pathlib.Path(__file__).parent
html = (root / "index.html").read_text()

def b64(path):
    return base64.b64encode((root / path).read_bytes()).decode()

icon192 = "data:image/png;base64," + b64("icons/icon-192.png")
icon512 = "data:image/png;base64," + b64("icons/icon-512.png")
touch = "data:image/png;base64," + b64("icons/apple-touch-icon.png")

# Inline manifest (best-effort: lets desktop Chrome offer install when hosted)
manifest = {
    "name": "Clock", "short_name": "Clock",
    "display": "standalone", "background_color": "#000000", "theme_color": "#000000",
    "icons": [
        {"src": icon192, "sizes": "192x192", "type": "image/png"},
        {"src": icon512, "sizes": "512x512", "type": "image/png"},
    ],
}
manifest_uri = "data:application/manifest+json;base64," + base64.b64encode(
    json.dumps(manifest).encode()).decode()

html = html.replace('href="manifest.webmanifest"', f'href="{manifest_uri}"')
html = html.replace('href="icons/apple-touch-icon.png"', f'href="{touch}"')
# Favicon for desktop browser tabs
html = html.replace("</title>", f'</title>\n  <link rel="icon" type="image/png" href="{icon192}">')

# Only try to register the service worker when served over http(s) —
# as a lone file there is no service-worker.js beside it.
html = html.replace(
    "if ('serviceWorker' in navigator) {",
    "if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {",
)

out = root / "dist"
out.mkdir(exist_ok=True)
(out / "BigClock.html").write_text(html)
size = (out / "BigClock.html").stat().st_size
print(f"built dist/BigClock.html ({size/1024:.0f} KB)")

# Sanity: no leftover references to external app files
leftover = re.findall(r'(?:src|href)="(?!data:|https?:)[^"]+"', html)
print("external refs remaining:", leftover or "none")
