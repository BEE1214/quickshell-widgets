# hermes-sessions

Bar chip for the iNiR shell: `N · M` = Hermes sessions · subagents working. The popup
lists sessions (with what each is doing) and the working subagents.

`hermes-status.py` (local files only, databases opened read-only) gathers:

- **sessions** – live Hermes CLI processes (`runtime/active_sessions.json`, pid alive) and
  desktop sessions active in the last 30 min (`state.db`, with Hermes' own
  `last_activity_description`, e.g. `tool running: terminal`).
- **subagents** – merged from
  - delegations: each goal of a `running` row in `async_delegations` (the in-process
    "Subagents · N live" panel),
  - kanban: tasks with status `running` whose worker pid is alive,
  - Claude Code: busy `claude -p` sessions whose parent process is Hermes.

Install like the other iNiR widgets: `HermesSessions.qml` → `services/`,
`HermesSessionsBar.qml` → `modules/bar/`, register both in the `qmldir` files, add a
`hermesSessions` component in `BarContent.qml` and `hermesSessions` to `bar.layout.right`.
The service expects the script at `~/.config/quickshell/hermes-sessions/hermes-status.py`.

Hermes' database schema is internal and may change between versions.
