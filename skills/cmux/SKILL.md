---
name: cmux
description: >
  Use this skill to control the cmux terminal app from Claude Code. Trigger on
  "cmux", "open browser pane", "split pane", "browser split", "open in browser",
  "cmux browser", "cmux notify", "cmux split", "새 pane 열어", "브라우저 열어",
  "알림 보내", "사이드바", "workspace 만들어", "pane 분할", "browser automation",
  "cmux에서", "cmux로", "cmux 사용해서". Also trigger proactively when running
  builds or tests (split a pane), starting dev servers (split + monitor), checking
  local web UIs (open browser), completing long tasks (send notification), or
  managing parallel projects (create workspaces) — even if the user doesn't
  explicitly mention cmux. Do NOT trigger for general tmux commands — cmux is a
  different app.
allowed-tools: Bash(cmux *)
---

# cmux — Terminal Automation for AI Agents

cmux is a native macOS terminal app built on Ghostty. It provides vertical tabs, split panes, an embedded browser, sidebar metadata, notifications, and a socket API — all controllable via the `cmux` CLI.

## Detection

Before using any cmux command, verify cmux is available. If not detected, tell the user and stop — do not fall back to tmux.

```bash
# Check env var (set automatically inside cmux terminals)
[ -n "$CMUX_WORKSPACE_ID" ] && echo "cmux detected"

# Or check CLI + socket
command -v cmux &>/dev/null && cmux ping
```

| Variable | Description |
|----------|-------------|
| `CMUX_WORKSPACE_ID` | Current workspace UUID |
| `CMUX_SURFACE_ID` | Current surface UUID |
| `CMUX_SOCKET_PATH` | Socket path (`~/Library/Application Support/cmux/cmux.sock`) |

## Core Concepts

cmux uses a four-level hierarchy:

```
Window → Workspace (sidebar tab) → Pane (split region) → Surface (tab within pane)
```

- **Workspace**: A sidebar entry. Created with `Cmd+T` or `cmux new-workspace`.
- **Pane**: A split region. Created with `Cmd+D` (right) or `cmux new-split right`.
- **Surface**: A tab within a pane. Each has a `CMUX_SURFACE_ID`. Holds a terminal or browser.

Handles use short refs: `workspace:1`, `pane:2`, `surface:3` (1-based), UUIDs, or omit to use current.

## When to Use cmux (Decision Guide)

### Run a build or test in a separate pane

Split the workspace so the long-running process doesn't block your work. Read the pane's output later to check results.

```bash
cmux new-split right
cmux send --surface surface:2 "./gradlew test"
# Later, check the results
cmux read-screen --surface surface:2 --lines 30
```

### Check a local web UI with the built-in browser

Open the embedded browser alongside your terminal. Prefer `snapshot --interactive` (structured text) over `screenshot` (image) — text is much easier to reason about.

```bash
# Open browser as a split pane — capture the surface ID
BROWSER_OUT=$(cmux browser open-split http://localhost:8080)
SURFACE=$(echo "$BROWSER_OUT" | grep -o 'surface:[0-9]*')

# Wait for load, then inspect
cmux browser $SURFACE wait --load-state complete
cmux browser $SURFACE snapshot --interactive --compact
```

To interact with the page:

```bash
cmux browser $SURFACE fill "#email" --text "admin@test.com"
cmux browser $SURFACE fill "#password" --text "secret"
cmux browser $SURFACE click "button[type='submit']" --snapshot-after
cmux browser $SURFACE wait --text "Dashboard"
```

For the full browser reference, see [references/browser-api.md](references/browser-api.md).

### Show build progress in the sidebar

cmux can display status, progress bars, and log entries in the workspace sidebar tab. Use this for long-running builds or CI pipelines.

```bash
# Status pills (appear next to the workspace name)
cmux set-status build "compiling" --icon hammer --color "#ff9500"
cmux clear-status build

# Progress bar (0.0 to 1.0)
cmux set-progress 0.75 --label "Testing (75%)..."
cmux clear-progress

# Log entries (appear in sidebar detail)
cmux log "Build started"
cmux log --level success "All 42 tests passed"
cmux log --level error --source build "Compilation failed"
```

### Notify the user when a long task completes

If a task takes more than a few seconds, send a notification — the user may be in another workspace. The notification appears in the sidebar as an alert ring and as a macOS desktop notification.

```bash
cmux notify --title "Build Complete" --body "All tests passed"
```

### Monitor another pane

Read output from a dev server or build pane before making decisions. **Always read before sending** — never send input blindly.

```bash
cmux read-screen --surface surface:2 --lines 20
```

### Manage multiple workspaces

For parallel projects, create separate workspaces with their own panes and context.

```bash
cmux new-workspace --name "backend-api" --cwd ~/projects/api --command "claude"
cmux new-workspace --name "frontend-web" --cwd ~/projects/web --command "claude"
cmux list-workspaces
```

## Command Quick Reference

### Workspaces

```bash
cmux list-workspaces
cmux current-workspace
cmux new-workspace [--name <title>] [--cwd <path>] [--command <cmd>]
cmux rename-workspace "New Name"
cmux select-workspace --workspace workspace:2
cmux close-workspace --workspace workspace:2
cmux tree
```

### Panes & Splits

```bash
cmux new-split <left|right|up|down>
cmux list-panes
cmux list-pane-surfaces [--pane pane:N]
cmux focus-pane --pane pane:2
cmux resize-pane --pane pane:1 -R --amount 20
cmux swap-pane --pane pane:1 --target-pane pane:2
```

### Terminal I/O

```bash
cmux read-screen [--surface surface:N] [--lines N] [--scrollback]
cmux send [--surface surface:N] "command text"
cmux send-key [--surface surface:N] "ctrl+c"
```

### Sidebar Metadata

```bash
cmux set-status <key> <value> [--icon <name>] [--color <#hex>]
cmux clear-status <key>
cmux set-progress <0.0-1.0> [--label <text>]
cmux clear-progress
cmux log [--level info|success|warn|error] [--source <name>] "<message>"
```

### Notifications

```bash
cmux notify --title "Title" [--subtitle "Sub"] --body "Body"
cmux list-notifications
cmux clear-notifications
```

### Browser (key commands)

```bash
cmux browser open-split [url]                        # open as split, returns surface ID
cmux browser <surface> navigate <url>
cmux browser <surface> snapshot [--interactive] [--compact]
cmux browser <surface> screenshot --out /tmp/s.png
cmux browser <surface> click|fill|type|press <selector>
cmux browser <surface> wait --selector|--text|--url-contains|--load-state
cmux browser <surface> eval "js expression"
cmux browser <surface> get <title|text|url|html|value|attr|count>
```

### Other

```bash
cmux identify                  # current workspace/surface IDs
cmux ping                      # check socket connection
cmux markdown open ./file.md   # formatted markdown viewer
cmux claude-teams              # multi-agent mode
```

For the complete CLI reference, see [references/cli-reference.md](references/cli-reference.md).
For the socket API reference, see [references/socket-api.md](references/socket-api.md).
For hooks integration, see [references/hooks-integration.md](references/hooks-integration.md).

## Important Principles

1. **Read before you send.** Always `read-screen` on a surface before sending input — you need to know its current state.
2. **Snapshot over screenshot.** Use `cmux browser snapshot --interactive` for page structure. Text is easier to reason about than images.
3. **Capture the surface ID.** When opening a browser split, parse the returned surface ID and use it for all subsequent browser commands.
4. **Notify on completion.** When finishing a long-running task, send a notification — the user may be in another workspace.
5. **Use sidebar metadata.** For builds, show progress with `set-progress` and log results with `log`.
6. **Don't over-split.** Only create new panes when you genuinely need parallel processes.

## Error Handling

| Problem | Solution |
|---------|----------|
| `cmux: command not found` | Run inside cmux terminal, or symlink: `ln -s /Applications/cmux.app/Contents/Resources/bin/cmux ~/.local/bin/cmux` |
| Socket not found | cmux app may not be running, or socket disabled in Settings |
| `surface not found` | Run `cmux list-pane-surfaces` to get valid surface IDs |
| Browser command fails | Ensure target surface is a browser panel, not a terminal |
| Permission denied | Socket mode may be "Off" — check Settings or set `CMUX_SOCKET_MODE=allowAll` |
