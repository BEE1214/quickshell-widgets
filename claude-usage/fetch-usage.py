#!/usr/bin/env python3
"""Print Claude subscription usage as normalized JSON for the Quickshell widget.

Reads the OAuth access token Claude Code keeps in ~/.claude/.credentials.json
(never refreshes or rewrites it; Claude Code owns that). Result is cached
briefly so multiple widgets/reloads don't hammer the endpoint.
"""
import json, os, sys, time, urllib.request, urllib.error

CRED = os.path.expanduser("~/.claude/.credentials.json")
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "claude-usage.json")
CACHE_TTL = 60
URL = "https://api.anthropic.com/api/oauth/usage"

LABELS = {
    "five_hour": "Session (5h)",
    "seven_day": "Weekly",
    "seven_day_opus": "Weekly Opus",
    "seven_day_sonnet": "Weekly Sonnet",
}


def out(obj):
    print(json.dumps(obj))
    sys.exit(0)


def fail(msg):
    out({"ok": False, "error": msg, "windows": []})


try:
    if time.time() - os.path.getmtime(CACHE) < CACHE_TTL:
        with open(CACHE) as f:
            out(json.load(f))
except OSError:
    pass

try:
    with open(CRED) as f:
        oauth = json.load(f)["claudeAiOauth"]
except (OSError, KeyError, ValueError):
    fail("No Claude credentials found. Run `claude` and log in.")

if oauth.get("expiresAt", 0) / 1000 < time.time():
    fail("Token expired. Open Claude Code once to refresh it.")

req = urllib.request.Request(URL, headers={
    "Authorization": "Bearer " + oauth["accessToken"],
    "anthropic-beta": "oauth-2025-04-20",
    "User-Agent": "claude-usage-quickshell",
})
try:
    with urllib.request.urlopen(req, timeout=10) as r:
        data = json.load(r)
except urllib.error.HTTPError as e:
    fail(f"HTTP {e.code}")
except (urllib.error.URLError, ValueError, TimeoutError) as e:
    fail(f"Request failed: {e}")

windows = []
for key, label in LABELS.items():
    w = data.get(key)
    if isinstance(w, dict) and w.get("utilization") is not None:
        windows.append({"id": key, "label": label,
                        "utilization": float(w["utilization"]),
                        "resets_at": w.get("resets_at")})

result = {"ok": True, "error": "", "windows": windows}
try:
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE, "w") as f:
        json.dump(result, f)
except OSError:
    pass
out(result)
