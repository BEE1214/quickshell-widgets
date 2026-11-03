#!/usr/bin/env python3
"""Print Hermes sessions and the subagents currently working, as JSON for Quickshell.

Local files only, all databases opened read-only. Output:
  sessions  – live Hermes CLI processes and recently active desktop sessions
  agents    – subagents doing work right now, merged from:
      * delegations: each goal of a `running` row in async_delegations
        (the "Subagents · N live" panel; they run inside the Hermes process)
      * kanban: tasks with status `running` whose worker process is alive
      * Claude Code: busy `claude -p` sessions that have a Hermes process as an ancestor
  working   – number of agents
"""
import glob, json, os, sqlite3, sys, time

HOME = os.path.expanduser("~")
HERMES = f"{HOME}/.hermes"
ACTIVE_WINDOW_S = 1800  # desktop sessions count as live if active within 30 min
now = time.time()


def ro(path):
    return sqlite3.connect(f"file:{path}?mode=ro", uri=True, timeout=1)


def alive(pid):
    return bool(pid) and os.path.isdir(f"/proc/{pid}")


def profile_of(path):
    return os.path.basename(os.path.dirname(path)) if "/profiles/" in path else "main"


def state_dbs():
    return [f"{HERMES}/state.db"] + sorted(glob.glob(f"{HERMES}/profiles/*/state.db"))


def cwd_name(pid):
    try:
        return os.path.basename(os.readlink(f"/proc/{pid}/cwd"))
    except OSError:
        return ""


# ---------------------------------------------------------------- sessions
def cli_sessions():
    out = []
    for f in [f"{HERMES}/runtime/active_sessions.json"] + sorted(
            glob.glob(f"{HERMES}/profiles/*/runtime/active_sessions.json")):
        prof = os.path.basename(os.path.dirname(os.path.dirname(f))) if "/profiles/" in f else "main"
        try:
            with open(f) as fh:
                entries = json.load(fh).get("entries", [])
        except (OSError, ValueError):
            continue
        for e in entries:
            if e.get("surface") != "cli" or not alive(e.get("pid")):
                continue
            out.append({
                "kind": "cli",
                "profile": prof,
                "title": cwd_name(e["pid"]) or "cli",
                "activity": "",
                "idle_s": None,
                "age_s": int(now - e.get("started_at", now)),
            })
    return out


def desktop_sessions():
    out = []
    for db in state_dbs():
        try:
            con = ro(db)
            rows = con.execute(
                "SELECT title, last_activity_at, last_activity_description, started_at "
                "FROM sessions WHERE ended_at IS NULL AND parent_session_id IS NULL "
                "AND source IN ('local', 'desktop') AND last_activity_at > ?",
                (now - ACTIVE_WINDOW_S,)).fetchall()
            con.close()
        except sqlite3.Error:
            continue
        for title, last, desc, started in rows:
            out.append({
                "kind": "desktop",
                "profile": profile_of(db),
                "title": " ".join((title or "untitled").split())[:80],
                "activity": " ".join((desc or "").split())[:70],
                "idle_s": int(now - last),
                "age_s": int(now - started) if started else 0,
            })
    return out


# ------------------------------------------------------------------ agents
def delegation_agents():
    out = []
    for db in state_dbs():
        try:
            con = ro(db)
            rows = con.execute(
                "SELECT owner_pid, dispatched_at, task_json FROM async_delegations "
                "WHERE state = 'running' AND completed_at IS NULL").fetchall()
            con.close()
        except sqlite3.Error:
            continue
        for pid, dispatched, task_json in rows:
            if not alive(pid):
                continue
            try:
                t = json.loads(task_json or "{}")
            except ValueError:
                continue
            goals = t.get("goals") or ([t["goal"]] if t.get("goal") else [])
            for g in goals:
                if isinstance(g, dict):
                    g = g.get("goal", "")
                out.append({
                    "name": " ".join(str(g).split())[:120] or "delegated task",
                    "source": "delegation",
                    "detail": f"{profile_of(db)} · {t.get('model', '')}".rstrip(" ·"),
                    "age_s": int(now - dispatched) if dispatched else 0,
                })
    return out


def kanban_agents():
    out = []
    dbs = [f"{HERMES}/kanban.db"] + sorted(glob.glob(f"{HERMES}/kanban/boards/*/kanban.db"))
    for db in dbs:
        board = os.path.basename(os.path.dirname(db)) if "/boards/" in db else "main"
        try:
            con = ro(db)
            rows = con.execute(
                "SELECT title, assignee, worker_pid, started_at FROM tasks "
                "WHERE status = 'running'").fetchall()
            con.close()
        except sqlite3.Error:
            continue
        for title, assignee, pid, started in rows:
            if alive(pid):
                out.append({
                    "name": title or f"task on {board}",
                    "source": "kanban",
                    "detail": f"{assignee or 'kanban'} · {board}",
                    "age_s": int(now - started) if started else 0,
                })
    return out


def hermes_ancestor(pid):
    """True if a Hermes process is anywhere above `pid` (agents are often started via
    wrapper scripts, so the direct parent is not necessarily Hermes)."""
    for _ in range(12):
        try:
            with open(f"/proc/{pid}/stat") as f:
                pid = int(f.read().rsplit(")", 1)[1].split()[1])
            if pid <= 1:
                return False
            with open(f"/proc/{pid}/comm") as f:
                if "hermes" in f.read().lower():
                    return True
        except (OSError, ValueError, IndexError):
            return False
    return False


def claude_agents():
    out = []
    for path in glob.glob(f"{HOME}/.claude/sessions/*.json"):
        try:
            with open(path) as f:
                s = json.load(f)
            pid = s["pid"]
            with open(f"/proc/{pid}/stat") as f:
                ticks = f.read().rsplit(")", 1)[1].split()[19]
        except (OSError, ValueError, KeyError, IndexError):
            continue
        if ticks != str(s.get("procStart")) or s.get("status") != "busy":
            continue
        if s.get("entrypoint") == "claude-desktop" or not hermes_ancestor(pid):
            continue
        out.append({
            "name": s.get("name") or os.path.basename(s.get("cwd", "")) or str(pid),
            "source": "claude",
            "detail": "claude code",
            "age_s": int(now - s.get("startedAt", now * 1000) / 1000),
        })
    return out


sessions = cli_sessions() + desktop_sessions()
# most recently active desktop sessions first, then CLIs
sessions.sort(key=lambda x: (x["kind"] != "desktop", x["idle_s"] if x["idle_s"] is not None else 1 << 30))
agents = delegation_agents() + kanban_agents() + claude_agents()
agents.sort(key=lambda a: -a["age_s"])
print(json.dumps({
    "sessions": sessions,
    "agents": agents,
    "working": len(agents),
    "total": len(sessions),
}))
