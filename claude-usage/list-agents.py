#!/usr/bin/env python3
"""Print currently running Claude Code sessions as JSON for the Quickshell widget.

Claude Code writes ~/.claude/sessions/<pid>.json for each process. Files of dead
processes linger, so liveness is checked against /proc/<pid>/stat (start time must
match `procStart`, which also guards against PID reuse). Local files only, no network.
"""
import glob, json, os, sys, time

SESSIONS = os.path.expanduser("~/.claude/sessions/*.json")


def start_ticks(pid):
    try:
        with open(f"/proc/{pid}/stat") as f:
            # comm may contain spaces/parens: split after the last ')'
            return f.read().rsplit(")", 1)[1].split()[19]
    except (OSError, IndexError):
        return None


agents = []
now = time.time() * 1000
for path in glob.glob(SESSIONS):
    try:
        with open(path) as f:
            s = json.load(f)
        pid = s["pid"]
    except (OSError, ValueError, KeyError):
        continue
    if start_ticks(pid) != str(s.get("procStart")):
        continue
    agents.append({
        "pid": pid,
        "name": s.get("name") or os.path.basename(s.get("cwd", "")) or str(pid),
        "status": s.get("status", "unknown"),
        "entrypoint": s.get("entrypoint", ""),
        "cwd": s.get("cwd", ""),
        "uptime_s": int((now - s.get("startedAt", now)) / 1000),
    })

# busy first, then spawned (non-desktop) before desktop, then longest running
agents.sort(key=lambda a: (a["status"] != "busy", a["entrypoint"] == "claude-desktop", -a["uptime_s"]))
print(json.dumps({
    "agents": agents,
    "busy": sum(a["status"] == "busy" for a in agents),
    "total": len(agents),
}))
