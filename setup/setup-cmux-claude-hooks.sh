#!/bin/bash
# =============================================================
# cmux + Claude Code 연동 설정 스크립트
#
# 사용법: bash setup-cmux-claude-hooks.sh
# =============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "========================================="
echo "  cmux + Claude Code 연동 설정"
echo "========================================="
echo ""

# --- 1. 사전 조건 확인 ---
echo "[1/5] 사전 조건 확인..."

if ! command -v cmux &>/dev/null; then
  echo -e "${RED}  ✗ cmux CLI를 찾을 수 없습니다.${NC}"
  echo "    cmux 앱 내부 터미널에서 실행하거나, 아래 명령으로 심볼릭 링크를 생성하세요:"
  echo "    ln -s /Applications/cmux.app/Contents/MacOS/cmux ~/.local/bin/cmux"
  exit 1
fi
echo -e "${GREEN}  ✓ cmux CLI: $(cmux version 2>/dev/null || echo 'OK')${NC}"

if ! command -v claude &>/dev/null; then
  echo -e "${YELLOW}  ⚠ Claude Code CLI를 찾을 수 없습니다. npm install -g @anthropic-ai/claude-code 로 설치하세요.${NC}"
else
  echo -e "${GREEN}  ✓ Claude Code: $(claude --version 2>/dev/null)${NC}"
fi

# --- 2. Claude Code hooks 설정 ---
echo ""
echo "[2/5] Claude Code hooks 설정..."

SETTINGS_FILE="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"

HOOKS_JSON='{
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
  }'

if [ -f "$SETTINGS_FILE" ]; then
  # 기존 설정에 hooks가 이미 있는지 확인
  if python3 -c "import json; d=json.load(open('$SETTINGS_FILE')); exit(0 if 'hooks' in d else 1)" 2>/dev/null; then
    echo -e "${YELLOW}  ⚠ hooks가 이미 설정되어 있습니다. 덮어쓰시겠습니까? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "  → hooks 설정을 건너뜁니다."
    else
      python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    d = json.load(f)
d['hooks'] = json.loads('''$HOOKS_JSON''')
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
print('  done')
"
      echo -e "${GREEN}  ✓ hooks 업데이트 완료${NC}"
    fi
  else
    python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    d = json.load(f)
d['hooks'] = json.loads('''$HOOKS_JSON''')
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
"
    echo -e "${GREEN}  ✓ hooks 추가 완료${NC}"
  fi
else
  python3 -c "
import json
d = {'hooks': json.loads('''$HOOKS_JSON''')}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
"
  echo -e "${GREEN}  ✓ settings.json 생성 + hooks 추가 완료${NC}"
fi

# --- 3. cmux.json 커스텀 커맨드 설정 ---
echo ""
echo "[3/5] cmux 커스텀 커맨드 설정..."

CMUX_CONFIG_DIR="$HOME/.config/cmux"
CMUX_CONFIG="$CMUX_CONFIG_DIR/cmux.json"
mkdir -p "$CMUX_CONFIG_DIR"

if [ -f "$CMUX_CONFIG" ]; then
  echo -e "${YELLOW}  ⚠ cmux.json이 이미 존재합니다. 덮어쓰시겠습니까? (y/N)${NC}"
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "  → cmux.json 설정을 건너뜁니다."
  else
    WRITE_CMUX=true
  fi
else
  WRITE_CMUX=true
fi

if [ "${WRITE_CMUX:-}" = "true" ] || [ ! -f "$CMUX_CONFIG" ]; then
  cat > "$CMUX_CONFIG" << 'CMUXEOF'
{
  "commands": [
    {
      "name": "Claude Code (현재 디렉토리)",
      "command": "claude"
    },
    {
      "name": "Claude Code (새 워크스페이스 + 분할)",
      "workspace": {
        "name": "Claude Dev",
        "panes": [
          {
            "split": "right",
            "ratio": 0.5,
            "surfaces": [
              { "command": "claude" },
              { "command": "" }
            ]
          }
        ]
      }
    },
    {
      "name": "Claude Teams (멀티 에이전트)",
      "command": "cmux claude-teams"
    }
  ]
}
CMUXEOF
  echo -e "${GREEN}  ✓ cmux.json 생성 완료${NC}"
fi

# --- 4. cmux 스킬 설치 ---
echo ""
echo "[4/5] Claude Code cmux 스킬 설치..."

SKILL_DIR="$HOME/.claude/skills/cmux"
SKILL_REF_DIR="$SKILL_DIR/references"
mkdir -p "$SKILL_REF_DIR"

WRITE_SKILL=false
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  echo -e "${YELLOW}  ⚠ cmux 스킬이 이미 존재합니다. 덮어쓰시겠습니까? (y/N)${NC}"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    WRITE_SKILL=true
  else
    echo "  → 스킬 설치를 건너뜁니다."
  fi
else
  WRITE_SKILL=true
fi

if [ "$WRITE_SKILL" = "true" ]; then
  # SKILL.md 다운로드 또는 임베드
  cat > "$SKILL_DIR/SKILL.md" << 'SKILLEOF'
---
name: cmux
description: "Use cmux terminal automation whenever you're running inside cmux (CMUX_WORKSPACE_ID env var is set). This skill enables: splitting panes to run builds/tests/servers alongside your work, opening the built-in browser to inspect local web UIs, sending notifications when long tasks finish, reading other pane outputs to check build logs or server status, and managing multiple workspaces for parallel projects. Use this skill any time the user mentions panes, splits, workspaces, browser preview, terminal tabs, notifications, or multi-agent workflows — and also proactively when running builds, starting servers, or completing long tasks, even if the user doesn't explicitly ask for cmux."
allowed-tools: Bash(cmux *)
---

# cmux — Terminal Automation for AI Agents

You are running inside **cmux**, a native macOS terminal multiplexer. You can control workspaces, panes, a built-in browser, and notifications through the `cmux` CLI.

The environment variables `CMUX_WORKSPACE_ID`, `CMUX_SURFACE_ID`, and `CMUX_SOCKET_PATH` are automatically set. If they are absent, you are not inside cmux — do not attempt cmux commands.

## When to Use cmux (Decision Guide)

Think of cmux as your hands beyond the current terminal. Use it proactively in these situations:

### Run a build or test in a separate pane
When you need to run a long-running process (build, test suite, dev server) while continuing to work, split the workspace and run it in the new pane. This lets you keep working and check the results later.

```bash
cmux new-split right
cmux send --surface surface:2 "./gradlew test"
cmux read-screen --surface surface:2 --lines 30
```

### Check a local web UI with the built-in browser
When working on a web app with a local server running, open the embedded browser to inspect the page. Prefer `snapshot` (returns structured text) over `screenshot` (returns an image) — text is easier to reason about.

```bash
cmux browser open http://localhost:8080
cmux browser wait --load-state complete
cmux browser snapshot --interactive
```

To interact with the page:
```bash
cmux browser click "#login-btn"
cmux browser fill "input[name=email]" "test@example.com"
cmux browser press "Enter"
cmux browser wait --text "Dashboard"
```

For full browser command reference, see [references/browser-reference.md](references/browser-reference.md).

### Notify the user when a long task completes
If a task takes more than a few seconds, send a notification so the user knows it's done, especially when they might have switched to another workspace.

```bash
cmux notify --title "Build Complete" --body "All tests passed"
```

### Monitor another pane
If a dev server or build is running in a different pane, read its output before making decisions.

```bash
cmux read-screen --surface surface:2 --lines 20
```

Always read before sending — never send input blindly to a surface without first understanding its current state.

### Manage multiple workspaces
For parallel work on different projects or branches, create separate workspaces.

```bash
cmux new-workspace --name "feature-auth" --cwd ~/projects/api
cmux new-workspace --name "frontend-fix" --cwd ~/projects/web --command "claude"
```

## Command Quick Reference

### Handles
Commands accept workspace/pane/surface references in three forms:
- **Index**: `workspace:1`, `pane:2`, `surface:3` (1-based)
- **UUID**: from environment variables
- **Omitted**: defaults to current workspace/surface

### Workspaces
```bash
cmux list-workspaces
cmux new-workspace --name "Name" --cwd /path [--command "cmd"]
cmux rename-workspace "New Name"
cmux select-workspace --workspace workspace:2
cmux close-workspace --workspace workspace:2
cmux tree
```

### Panes & Splits
```bash
cmux new-split <left|right|up|down>
cmux list-panes
cmux focus-pane --pane pane:2
cmux resize-pane --pane pane:1 -R --amount 20
```

### Terminal I/O
```bash
cmux read-screen [--surface surface:N] [--lines N] [--scrollback]
cmux send [--surface surface:N] "command text"
cmux send-key [--surface surface:N] "ctrl+c"
```

### Notifications
```bash
cmux notify --title "Title" [--subtitle "Sub"] --body "Body"
cmux list-notifications
```

### Browser (key commands)
```bash
cmux browser open [url]
cmux browser goto <url>
cmux browser snapshot [--interactive]
cmux browser screenshot --out /tmp/s.png
cmux browser click|fill|type|press
cmux browser wait --selector|--text|--url-contains|--load-state
cmux browser eval "js expression"
cmux browser get <title|text|url|html|value|attr|count>
```

For complete CLI/browser reference, see references/ directory.

## Important Principles

1. **Read before you send.** Always `read-screen` on a surface before sending input.
2. **Snapshot over screenshot.** Use `cmux browser snapshot --interactive` for page structure.
3. **Notify on completion.** Send a notification when finishing long-running tasks.
4. **Don't over-split.** Only create new panes when you genuinely need parallel processes.
SKILLEOF

  echo -e "${GREEN}  ✓ SKILL.md 설치 완료${NC}"

  # CLI reference
  cat > "$SKILL_REF_DIR/cli-reference.md" << 'CLIEOF'
# cmux CLI Complete Reference

## Workspace Management
```bash
cmux list-workspaces
cmux current-workspace
cmux new-workspace [--name <title>] [--cwd <path>] [--command <text>]
cmux rename-workspace [--workspace <id|ref>] <title>
cmux select-workspace --workspace <id|ref>
cmux close-workspace --workspace <id|ref>
cmux tree [--all]
```

## Pane & Surface Management
```bash
cmux new-split <left|right|up|down> [--workspace <id|ref>] [--surface <id|ref>]
cmux list-panes [--workspace <id|ref>]
cmux focus-pane --pane <id|ref>
cmux resize-pane --pane <id|ref> (-L|-R|-U|-D) [--amount <n>]
cmux swap-pane --pane <id|ref> --target-pane <id|ref>
```

## Terminal I/O
```bash
cmux read-screen [--workspace <id|ref>] [--surface <id|ref>] [--scrollback] [--lines <n>]
cmux send [--workspace <id|ref>] [--surface <id|ref>] <text>
cmux send-key [--workspace <id|ref>] [--surface <id|ref>] <key>
```

## Notifications
```bash
cmux notify --title <text> [--subtitle <text>] [--body <text>]
cmux list-notifications
cmux clear-notifications
```

## Identity & Status
```bash
cmux ping
cmux version
cmux identify
```

## Claude Integration
```bash
cmux claude-hook <session-start|stop|notification|prompt-submit>
cmux claude-teams [claude-args...]
```

## Other
```bash
cmux markdown [open] <path>
cmux find-window [--content] [--select] <query>
```

## Environment Variables
- CMUX_WORKSPACE_ID: current workspace UUID
- CMUX_SURFACE_ID: current surface UUID
- CMUX_SOCKET_PATH: Unix socket path
CLIEOF

  echo -e "${GREEN}  ✓ cli-reference.md 설치 완료${NC}"

  # Browser reference
  cat > "$SKILL_REF_DIR/browser-reference.md" << 'BREOF'
# cmux Browser Automation Reference

## Open & Navigate
```bash
cmux browser open [url]
cmux browser goto|navigate <url> [--snapshot-after]
cmux browser back|forward|reload [--snapshot-after]
cmux browser url|get-url
```

## Inspect
```bash
cmux browser snapshot [--interactive] [--compact] [--selector <css>]
cmux browser screenshot [--out <path>]
cmux browser get <url|title|text|html|value|attr|count|box|styles> [--selector <css>]
```

## Interact
```bash
cmux browser click|dblclick|hover|focus <selector> [--snapshot-after]
cmux browser fill <selector> [text] [--snapshot-after]
cmux browser type <selector> <text> [--snapshot-after]
cmux browser press|keydown|keyup <key> [--snapshot-after]
cmux browser select <selector> <value> [--snapshot-after]
cmux browser check|uncheck <selector> [--snapshot-after]
cmux browser scroll [--selector <css>] [--dx <n>] [--dy <n>]
```

## Wait
```bash
cmux browser wait --selector <css>
cmux browser wait --text <text>
cmux browser wait --url-contains <text>
cmux browser wait --load-state <interactive|complete>
cmux browser wait --function <js>
cmux browser wait --timeout-ms <ms>
```

## JavaScript
```bash
cmux browser eval <script>
```

## Element Discovery
```bash
cmux browser find role|text|label|testid ...
cmux browser is visible|enabled|checked <selector>
cmux browser highlight <selector>
```

## Frames & Dialogs
```bash
cmux browser frame <selector|main>
cmux browser dialog accept|dismiss [text]
```

## Storage & Cookies
```bash
cmux browser cookies get|set|clear [...]
cmux browser storage <local|session> get|set|clear [...]
```

## Tabs
```bash
cmux browser tab new|list|switch|close [...]
```

## Advanced
```bash
cmux browser state save|load <path>
cmux browser addscript|addinitscript|addstyle <content>
cmux browser viewport <width> <height>
cmux browser console|errors list|clear
cmux browser download wait [--path <path>]
```
BREOF

  echo -e "${GREEN}  ✓ browser-reference.md 설치 완료${NC}"
fi

# --- 5. 검증 ---
echo ""
echo "[5/5] 설정 검증..."

if cmux ping &>/dev/null; then
  echo -e "${GREEN}  ✓ cmux 소켓 연결 정상${NC}"
else
  echo -e "${YELLOW}  ⚠ cmux 소켓 연결 실패 — cmux 앱이 실행 중인지 확인하세요${NC}"
fi

if echo '{}' | cmux claude-hook stop &>/dev/null; then
  echo -e "${GREEN}  ✓ claude-hook 명령 정상${NC}"
else
  echo -e "${YELLOW}  ⚠ claude-hook 테스트 실패${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}  설정 완료!${NC}"
echo "========================================="
echo ""
echo "적용된 파일:"
echo "  • $SETTINGS_FILE                           (Claude Code hooks)"
echo "  • $CMUX_CONFIG                             (커스텀 커맨드)"
echo "  • $SKILL_DIR/SKILL.md                      (cmux 스킬)"
echo "  • $SKILL_REF_DIR/cli-reference.md          (CLI 레퍼런스)"
echo "  • $SKILL_REF_DIR/browser-reference.md      (브라우저 레퍼런스)"
echo ""
echo "cmux 스킬이 하는 일:"
echo "  Claude Code가 cmux 환경을 자동 감지하고 다음을 수행합니다:"
echo "  • 빌드/테스트를 별도 패인에서 실행하고 결과 확인"
echo "  • 내장 브라우저로 로컬 웹 UI 검사 및 자동화"
echo "  • 장시간 작업 완료 시 알림 전송"
echo "  • 다른 패인의 출력(서버 로그 등) 읽기"
echo "  • 여러 프로젝트를 별도 워크스페이스에서 병렬 관리"
echo ""
echo "다음 단계:"
echo "  1. Claude Code를 재시작하세요 (/exit 후 claude)"
echo "  2. Cmd+Shift+P로 커맨드 팔레트에서 커스텀 커맨드를 확인하세요"
echo "  3. Claude Code 작업 완료 시 사이드바 알림 링을 확인하세요"
echo "  4. /cmux 로 스킬을 직접 호출하거나, 빌드/브라우저 관련 요청 시 자동 활용됩니다"
echo ""
