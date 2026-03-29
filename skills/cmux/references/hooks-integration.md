# cmux + Claude Code Hooks Integration

cmux provides a native `claude-hook` command that integrates directly with Claude Code hooks. This is the recommended approach — no custom shell scripts needed.

## Quick Setup

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmux claude-hook session-start",
            "async": true
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmux claude-hook stop",
            "async": true
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmux claude-hook notification",
            "async": true
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmux claude-hook prompt-submit",
            "async": true
          }
        ]
      }
    ]
  }
}
```

## Hook Events

| Hook | Claude Code Event | cmux Effect |
|------|------------------|-------------|
| `session-start` | Session starts | Sidebar shows "Active" status |
| `stop` | Claude finishes responding | Sidebar shows **notification ring** — visible from any workspace |
| `notification` | Claude sends a notification | cmux notification panel + macOS desktop alert |
| `prompt-submit` | User sends a prompt | Clears notification ring, shows "Running" status |

## How It Works

`cmux claude-hook` reads JSON from stdin (Claude Code provides hook context) and translates it into cmux sidebar state and notifications. The `async: true` flag ensures hooks don't block Claude Code's response flow.

## Notification Lifecycle

1. **Received**: Notification appears in panel, desktop alert fires
2. **Unread**: Badge/ring shown on workspace tab in sidebar
3. **Read**: Cleared when you switch to that workspace
4. **Cleared**: Removed from panel

Desktop alerts are suppressed when cmux is focused and the workspace is active.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+I` | Open notification panel |
| `Cmd+Shift+U` | Jump to workspace with most recent unread notification |

## Manual Notifications

You can also send notifications directly from scripts or the CLI:

```bash
cmux notify --title "Build Done" --body "All tests passed"
```

## OSC Escape Sequences

For sending notifications from scripts that don't have access to the cmux CLI:

```bash
# OSC 777 (simple)
printf '\e]777;notify;Title;Body\a'
```

## Custom Notification Command

In cmux Settings > App > Notification Command, you can set a custom command. Environment variables available:

| Variable | Description |
|----------|-------------|
| `CMUX_NOTIFICATION_TITLE` | Notification title |
| `CMUX_NOTIFICATION_SUBTITLE` | Subtitle |
| `CMUX_NOTIFICATION_BODY` | Body text |
