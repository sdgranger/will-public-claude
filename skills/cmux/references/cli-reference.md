# cmux CLI Complete Reference

## Workspace Management

```bash
cmux list-workspaces
cmux current-workspace
cmux new-workspace [--name <title>] [--cwd <path>] [--command <text>]
cmux rename-workspace [--workspace <id|ref>] <title>
cmux select-workspace --workspace <id|ref>
cmux close-workspace --workspace <id|ref>
cmux tree [--all] [--workspace <id|ref|index>]
```

## Window Management

```bash
cmux list-windows
cmux current-window
cmux new-window
cmux focus-window --window <id>
cmux close-window --window <id>
cmux move-workspace-to-window --workspace <id|ref> --window <id|ref>
cmux rename-window [--workspace <id|ref>] <title>
```

## Pane & Surface Management

```bash
# Splits
cmux new-split <left|right|up|down> [--workspace <id|ref>] [--surface <id|ref>]
cmux list-panes [--workspace <id|ref>]
cmux list-pane-surfaces [--workspace <id|ref>] [--pane <id|ref>]
cmux focus-pane --pane <id|ref> [--workspace <id|ref>]

# Resize / Swap
cmux resize-pane --pane <id|ref> [--workspace <id|ref>] (-L|-R|-U|-D) [--amount <n>]
cmux swap-pane --pane <id|ref> --target-pane <id|ref> [--workspace <id|ref>]
cmux break-pane [--workspace <id|ref>] [--pane <id|ref>] [--surface <id|ref>]
cmux join-pane --target-pane <id|ref> [--workspace <id|ref>] [--pane <id|ref>] [--surface <id|ref>]

# Surfaces (tabs within panes)
cmux new-surface [--type <terminal|browser>] [--pane <id|ref>] [--workspace <id|ref>]
cmux close-surface [--surface <id|ref>] [--workspace <id|ref>]
cmux move-surface --surface <id|ref|index> [--pane <id|ref|index>]
cmux reorder-surface --surface <id|ref|index> (--index <n> | --before <id|ref|index> | --after <id|ref|index>)
```

## Terminal I/O

```bash
# Read terminal content
cmux read-screen [--workspace <id|ref>] [--surface <id|ref>] [--scrollback] [--lines <n>]
cmux capture-pane [--workspace <id|ref>] [--surface <id|ref>] [--scrollback] [--lines <n>]

# Send input
cmux send [--workspace <id|ref>] [--surface <id|ref>] <text>
cmux send-key [--workspace <id|ref>] [--surface <id|ref>] <key>

# Panels
cmux list-panels [--workspace <id|ref>]
cmux focus-panel --panel <id|ref> [--workspace <id|ref>]
cmux send-panel --panel <id|ref> [--workspace <id|ref>] <text>
cmux send-key-panel --panel <id|ref> [--workspace <id|ref>] <key>

# Buffer
cmux set-buffer [--name <name>] <text>
cmux list-buffers
cmux paste-buffer [--name <name>] [--workspace <id|ref>] [--surface <id|ref>]

# History
cmux clear-history [--workspace <id|ref>] [--surface <id|ref>]
cmux respawn-pane [--workspace <id|ref>] [--surface <id|ref>] [--command <cmd>]
```

## Notifications

```bash
cmux notify --title <text> [--subtitle <text>] [--body <text>] [--workspace <id|ref>] [--surface <id|ref>]
cmux list-notifications
cmux clear-notifications
cmux trigger-flash [--workspace <id|ref>] [--surface <id|ref>]
```

## Sidebar Metadata

```bash
# Status pills (appear next to workspace name in sidebar)
cmux set-status <key> <value> [--icon <name>] [--color <#hex>] [--url <url>] [--priority <n>] [--format plain|markdown] [--tab <id>]
cmux clear-status <key>

# Progress bar (0.0 to 1.0)
cmux set-progress <0.0-1.0> [--label <text>] [--tab <id>]
cmux clear-progress

# Log entries (appear in sidebar detail)
cmux log [--level info|success|warn|error] [--source <name>] [--tab <id>] "<message>"
```

## Navigation & Search

```bash
cmux find-window [--content] [--select] <query>
cmux next-window | previous-window | last-window
cmux last-pane [--workspace <id|ref>]
cmux reorder-workspace --workspace <id|ref|index> (--index <n> | --before | --after)
```

## Identity & Status

```bash
cmux ping
cmux version
cmux capabilities
cmux identify [--workspace <id|ref|index>] [--surface <id|ref|index>] [--no-caller]
cmux surface-health [--workspace <id|ref>]
```

## Claude Integration

```bash
cmux claude-hook <session-start|active|stop|idle|notification|notify|prompt-submit>
cmux claude-teams [claude-args...]
```

## SSH & Remote

```bash
cmux ssh <destination> [--name <title>] [--port <n>] [--identity <path>]
cmux remote-daemon-status [--os <darwin|linux>] [--arch <arm64|amd64>]
```

## Hooks & Key Bindings

```bash
cmux set-hook [--list] [--unset <event>] | <event> <command>
cmux bind-key | unbind-key | copy-mode
```

## Miscellaneous

```bash
cmux markdown [open] <path>             # formatted markdown viewer
cmux themes [list|set|clear]
cmux display-message [-p|--print] <text>
cmux pipe-pane --command <shell-command> [--workspace <id|ref>] [--surface <id|ref>]
cmux wait-for [-S|--signal] <name> [--timeout <seconds>]
cmux set-app-focus <active|inactive|clear>
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CMUX_WORKSPACE_ID` | Current workspace UUID (auto-set) |
| `CMUX_SURFACE_ID` | Current surface UUID (auto-set) |
| `CMUX_TAB_ID` | Optional tab alias |
| `CMUX_SOCKET_PATH` | Unix socket path |

## Handle Format

All commands accepting `--workspace`, `--pane`, `--surface` support:
- **Short refs**: `workspace:1`, `pane:2`, `surface:3` (1-based index)
- **UUIDs**: full UUID strings
- **Indexes**: numeric index
- Output format controlled by `--id-format uuids|both`
