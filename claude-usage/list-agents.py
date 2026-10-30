#!/usr/bin/env python3
"""Print active Claude Code subagents as JSON for the Quickshell widget.

Two sources, merged and de-duplicated by pid:
  * Claude Code: live, busy sessions not opened in Claude Desktop (entrypoint other than
    `claude-desktop`), e.g. `claude -p` spawned by Hermes or an SDK script.
  * Hermes kanban: tasks with status `running` whose worker process is alive
    (~/.hermes/kanban.db and ~/.hermes/kanban/boards/*/kanban.db, opened read-only).

Claude Code writes ~/.claude/sessions/<pid>.json for each process. Files of dead
processes linger, so liveness is checked against /proc/<pid>/stat (start time must
match `procStart`, which also guards against PID reuse). Local files only, no network.
"""
import glob, json, os, re, sqlite3, sys, time

SESSIONS = os.path.expanduser("~/.claude/sessions/*.json")
KANBAN_DBS = [os.path.expanduser("~/.hermes/kanban.db")] + sorted(
    glob.glob(os.path.expanduser("~/.hermes/kanban/boards/*/kanban.db")))


def parent_name(pid):
    try:
        with open(f"/proc/{pid}/stat") as f:
            ppid = f.read().rsplit(")", 1)[1].split()[1]
        with open(f"/proc/{ppid}/cmdline", "rb") as f:
            argv = f.read().split(b"\0")
        text = " ".join(a.decode(errors="replace") for a in argv)
        if "hermes" in text.lower():
            return "hermes"
        return os.path.basename(argv[0].decode(errors="replace")) or "?"
    except (OSError, IndexError):
        return "?"


def task_text(session_id, pid):
    """First user prompt of the session; falls back to the `claude -p <prompt>` argument."""
    for path in glob.glob(os.path.expanduser(f"~/.claude/projects/*/{session_id}.jsonl")):
        try:
            with open(path) as f:
                for line in f:
                    m = json.loads(line)
                    if m.get("type") != "user":
                        continue
                    c = m.get("message", {}).get("content", "")
                    if isinstance(c, list):
                        c = " ".join(b.get("text", "") for b in c if isinstance(b, dict))
                    if c.strip():
                        return " ".join(c.split())
        except (OSError, ValueError):
            pass
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            argv = [a.decode(errors="replace") for a in f.read().split(b"\0")]
        for flag in ("-p", "--print"):
            if flag in argv and argv.index(flag) + 1 < len(argv):
                return " ".join(argv[argv.index(flag) + 1].split())
    except OSError:
        pass
    return ""


def brief_name(task):
    """Briefing files ("read X.md and execute it") say more than the generic wording."""
    m = re.search(r"(\S+\.md)\b", task)
    return os.path.splitext(os.path.basename(m.group(1)))[0] if m else ""


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
    if s.get("status") != "busy" or s.get("entrypoint") == "claude-desktop":
        continue
    task = task_text(s.get("sessionId", ""), pid)
    agents.append({
        "pid": pid,
        "name": s.get("name") or os.path.basename(s.get("cwd", "")) or str(pid),
        "status": s.get("status", "unknown"),
        "entrypoint": s.get("entrypoint", ""),
        "parent": parent_name(pid),
        "task": task[:160],
        "brief": brief_name(task),
        "cwd": s.get("cwd", ""),
        "uptime_s": int((now - s.get("startedAt", now)) / 1000),
    })

def kanban_agents(seen):
    out = []
    for db in KANBAN_DBS:
        board = os.path.basename(os.path.dirname(db)) if "/boards/" in db else "main"
        try:
            con = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=1)
            rows = con.execute(
                "SELECT title, assignee, worker_pid, started_at "
                "FROM tasks WHERE status = 'running'").fetchall()
            con.close()
        except sqlite3.Error:
            continue
        for title, assignee, pid, started in rows:
            if not pid or pid in seen or not os.path.isdir(f"/proc/{pid}"):
                continue
            out.append({
                "pid": pid,
                "name": title or f"task on {board}",
                "status": "busy",
                "entrypoint": "hermes-kanban",
                "parent": assignee or "kanban",
                "task": f"kanban · {board}",
                "brief": "",
                "cwd": "",
                "uptime_s": int(now / 1000 - started) if started else 0,
            })
    return out


agents += kanban_agents({a["pid"] for a in agents})

# longest running first
agents.sort(key=lambda a: -a["uptime_s"])
print(json.dumps({
    "agents": agents,
    "busy": len(agents),
    "total": len(agents),
}))
