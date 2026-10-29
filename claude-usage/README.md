# claude-usage

Shows Claude subscription limits (5h session, weekly) in Quickshell.

- `fetch-usage.py` – shell-agnostic. Reads the OAuth token Claude Code stores in
  `~/.claude/.credentials.json`, calls Anthropic's usage endpoint and prints
  normalized JSON. Never refreshes or writes the token; if it is expired, run
  `claude` once. Result is cached for 60 s in `~/.cache/claude-usage.json`.
- `list-agents.py` – lists active Claude Code subagents: live, busy sessions not opened in
  Claude Desktop (`entrypoint` ≠ `claude-desktop`, e.g. `claude -p` spawned by Hermes or an
  SDK script), with the parent process name and the task (briefing file name, else the first prompt). Reads `~/.claude/sessions/<pid>.json`; local
  only. A session counts as live when `/proc/<pid>` start time matches `procStart`.
- `standalone/shell.qml` – floating card. Run with `qs -c claude-usage`
  (copy this folder plus `fetch-usage.py` to `~/.config/quickshell/claude-usage/`).
- `inir/` – bar chip + hover popup for the iNiR shell:
  - `ClaudeUsage.qml` → `services/` (register in `services/qmldir`: `singleton ClaudeUsage 1.0 ClaudeUsage.qml`)
  - `ClaudeUsageBar.qml` → `modules/bar/` (register in `modules/bar/qmldir`)
  - add a `claudeUsage` component/entry in `BarContent.qml` (like `weather`) and put
    `claudeUsage` in `bar.layout.right` of the config (with `bar.layout.migrated: true`).

The bar chip also shows a terminal icon with the number of active subagents (polled every
5 s); the popup lists them with parent, task and run time. The standalone card does not show sessions yet.

The QML expects the scripts at `~/.config/quickshell/claude-usage/` (`fetch-usage.py`, `list-agents.py`).

The usage endpoint is undocumented and may change.
