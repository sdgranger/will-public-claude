---
name: cmux
description: >
  Low-level cmux CLI debugging and manual control only. For running processes use
  cmux-run, for parallel tasks use cmux-parallel, for browser testing use cmux-browser.
  Use this skill only for troubleshooting that high-level skills cannot handle, or
  when the user explicitly wants direct cmux CLI control. Not related to tmux.
allowed-tools: Bash(cmux *)
---

# cmux Terminal Automation

> Written for cmux **v0.63.1**. If commands fail on a newer version, check [references/cli-reference.md](references/cli-reference.md) or run `cmux --help`.

You are inside **cmux**, a native macOS terminal. The `cmux` CLI lets you control panes, browser, sidebar, and notifications.

> **Prerequisite**: `CMUX_WORKSPACE_ID` must be set (auto-set inside cmux). If absent, you are not in cmux — do not attempt cmux commands.

## Hierarchy

```
Window → Workspace (sidebar tab) → Pane (split region) → Surface (tab in pane)
```

References use short refs: `surface:1`, `pane:2`, `workspace:3` (1-based). Omit to target the current one.

---

## What You Can Do

### 1. Split panes for builds, tests, or servers

Run long processes in a separate pane so you can keep working. Check results later.

```bash
cmux new-split right
cmux send --surface surface:2 "./gradlew test"
cmux read-screen --surface surface:2 --lines 30
```

### 2. Inspect local web UIs with the built-in browser

Open the embedded browser alongside your terminal. Use `snapshot` (structured text) rather than `screenshot` (image) — it's far easier to reason about.

```bash
BROWSER_OUT=$(cmux browser open-split http://localhost:3000)
SURFACE=$(echo "$BROWSER_OUT" | grep -o 'surface:[0-9]*')

cmux browser $SURFACE wait --load-state complete
cmux browser $SURFACE snapshot --interactive --compact
```

Interact with the page:

```bash
cmux browser $SURFACE fill "#email" --text "user@test.com"
cmux browser $SURFACE click "button[type=submit]" --snapshot-after
cmux browser $SURFACE wait --text "Dashboard"
```

See [references/browser-api.md](references/browser-api.md) for the full browser reference.

### 3. Show progress in the sidebar

Display status pills, progress bars, and log entries next to the workspace name.

```bash
cmux set-status build "compiling" --icon hammer --color "#ff9500"
cmux set-progress 0.75 --label "Testing (75%)..."
cmux log --level success "All 42 tests passed"

cmux clear-status build
cmux clear-progress
```

### 4. Send notifications

Notify the user when a long task finishes — they may be in another workspace.

```bash
cmux notify --title "Build Complete" --body "All tests passed"
```

### 5. Read another pane's output

Check a dev server or build log before making decisions. **Always read before sending** — never send input blindly.

```bash
cmux read-screen --surface surface:2 --lines 20
```

### 6. Manage multiple workspaces

Create separate workspaces for parallel projects.

```bash
cmux new-workspace --name "backend" --cwd ~/projects/api --command "claude"
cmux new-workspace --name "frontend" --cwd ~/projects/web
```

---

## Command Quick Reference

**Workspaces**
```bash
cmux list-workspaces | current-workspace | tree
cmux new-workspace [--name <title>] [--cwd <path>] [--command <cmd>]
cmux select-workspace --workspace <ref>
cmux close-workspace --workspace <ref>
```

**Panes**
```bash
cmux new-split <left|right|up|down>
cmux list-panes | list-pane-surfaces
cmux focus-pane --pane <ref>
cmux resize-pane --pane <ref> -R --amount 20
```

**Terminal I/O**
```bash
cmux read-screen [--surface <ref>] [--lines N] [--scrollback]
cmux send [--surface <ref>] "command"
cmux send-key [--surface <ref>] "ctrl+c"
```

**Sidebar**
```bash
cmux set-status <key> <value> [--icon <name>] [--color <#hex>]
cmux set-progress <0.0-1.0> [--label <text>]
cmux log [--level info|success|warn|error] "<message>"
cmux clear-status <key> | clear-progress
```

**Notifications**
```bash
cmux notify --title "Title" [--subtitle "Sub"] --body "Body"
```

**Browser**
```bash
cmux browser open-split [url]               # returns surface ID
cmux browser <surface> snapshot [--interactive] [--compact]
cmux browser <surface> click|fill|type|press <selector>
cmux browser <surface> wait --text|--selector|--load-state <value>
cmux browser <surface> eval "js"
cmux browser <surface> get <title|text|url|html>
```

**Utility**
```bash
cmux identify    # current workspace/surface IDs
cmux ping        # check connection
```

Full CLI: [references/cli-reference.md](references/cli-reference.md) | Socket API: [references/socket-api.md](references/socket-api.md) | Hooks: [references/hooks-integration.md](references/hooks-integration.md)

---

## Principles

1. **Read before send** — always `read-screen` before sending input to a surface.
2. **Snapshot over screenshot** — text output is easier to reason about than images.
3. **Capture surface IDs** — parse the ID returned by `browser open-split` and reuse it.
4. **Notify on completion** — the user may have switched workspaces.
5. **Don't over-split** — only create panes when you need parallel processes.
