# hermes-sessions

Bar chip for the iNiR shell: `N · M` = active Hermes sessions · subagents working. The popup
lists sessions (with what each is doing) and the working subagents.

`hermes-status.py` (local files only, databases opened read-only) gathers:

- **sessions** – active ones only, idle sessions are hidden:
  - CLI sessions (`runtime/active_sessions.json`, pid alive) count as active while they use
    CPU or have child processes. Hermes keeps no activity record for CLI sessions, so the
    script samples CPU for 1 s per run (≥ 3 clock ticks; idle ones burn ~0.5).
  - Desktop sessions (`state.db`) count as active with Hermes activity in the last 2 min
    (shown with `last_activity_description`, e.g. `tool running: terminal`).
- **subagents** – merged from
  - delegations: each goal of a `running` row in `async_delegations` (the in-process
    "Subagents · N live" panel),
  - kanban: tasks with status `running` whose worker pid is alive,
  - Claude Code: busy `claude -p` sessions with a Hermes process as an ancestor (often started via a wrapper script).

Install like the other iNiR widgets: `HermesSessions.qml` → `services/`,
`HermesSessionsBar.qml` → `modules/bar/`, register both in the `qmldir` files, add a
`hermesSessions` component in `BarContent.qml` and `hermesSessions` to `bar.layout.right`.
The service expects the script at `~/.config/quickshell/hermes-sessions/hermes-status.py`.

Hermes' database schema is internal and may change between versions.
