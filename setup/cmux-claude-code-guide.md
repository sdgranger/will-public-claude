# cmux + Claude Code 설정 가이드

> cmux는 여러 AI 코딩 에이전트를 동시에 실행할 때 최적화된 macOS 네이티브 터미널 앱입니다.
> 이 가이드는 cmux에서 Claude Code를 효과적으로 사용하기 위한 설정과 활용법을 정리한 문서입니다.

---

## 1. 설치

### cmux 설치

```bash
# Homebrew
brew install cmux

# 또는 https://github.com/nickthecook/cmux/releases 에서 DMG 다운로드
# 요구사항: macOS 14.0+
```

### CLI 심볼릭 링크 (cmux 외부에서 CLI 사용 시)

```bash
ln -s /Applications/cmux.app/Contents/MacOS/cmux ~/.local/bin/cmux
```

> cmux 터미널 내부에서는 CLI가 자동으로 PATH에 포함되어 있으므로 이 단계는 선택사항입니다.

### Claude Code 설치

```bash
npm install -g @anthropic-ai/claude-code
```

---

## 2. Claude Code Hooks 설정

cmux와 Claude Code를 연동하면 **작업 완료 알림**, **사이드바 상태 표시** 등을 자동으로 받을 수 있습니다.

`~/.claude/settings.json`에 아래 `hooks` 블록을 추가하세요:

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

### 각 Hook의 역할

| Hook | 트리거 시점 | cmux에서의 효과 |
|------|------------|----------------|
| **SessionStart** | Claude Code 세션 시작 | 사이드바에 "Active" 상태 표시 |
| **Stop** | Claude가 응답 완료 (사용자 입력 대기) | 사이드바에 **알림 링** 표시 — 다른 워크스페이스에서도 확인 가능 |
| **Notification** | Claude가 알림 발생 | cmux 알림 패널 + macOS 데스크톱 알림 |
| **UserPromptSubmit** | 사용자가 프롬프트 전송 | 알림 초기화 + "Running" 상태로 전환 |

### 설정 확인 테스트

```bash
# 알림 테스트
cmux notify --title "테스트" --body "알림이 보이면 성공!"

# hook 테스트
echo '{}' | cmux claude-hook stop
```

---

## 3. cmux 커스텀 커맨드 설정

`~/.config/cmux/cmux.json`에 자주 쓰는 워크스페이스 레이아웃을 정의할 수 있습니다.
커맨드 팔레트(`Cmd+Shift+P`)에서 바로 실행됩니다.

```json
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
```

> 프로젝트별로 다른 레이아웃이 필요하면 해당 프로젝트 루트에 `cmux.json`을 만들 수도 있습니다.

---

## 4. cmux 스킬 (Claude Code가 cmux를 자동 활용)

설정 스크립트를 실행하면 `~/.claude/skills/cmux/` 에 스킬이 설치됩니다. 이 스킬이 설치되면 Claude Code가 cmux 환경을 **자동으로 감지**하고 활용합니다.

### 스킬이 하는 일

| 상황 | Claude Code의 동작 |
|------|-------------------|
| 빌드/테스트 실행 요청 | 별도 패인에서 실행하고 `read-screen`으로 결과 확인 |
| 웹 UI 확인 요청 | 내장 브라우저로 페이지를 열고 `snapshot`으로 구조 파악 |
| 장시간 작업 | 완료 시 `cmux notify`로 알림 전송 |
| 다른 패인 상태 확인 | `read-screen`으로 서버 로그/빌드 결과 읽기 |
| 멀티 프로젝트 | `new-workspace`로 프로젝트별 워크스페이스 생성 |

### 동작 방식

1. **자동 감지**: `CMUX_WORKSPACE_ID` 환경변수가 설정되어 있으면 cmux 내부임을 인식
2. **자동 트리거**: 빌드, 서버, 브라우저, 알림 관련 요청 시 스킬이 자동으로 활성화
3. **수동 호출**: `/cmux` 명령으로 직접 호출도 가능
4. **권한 자동 허용**: `allowed-tools: Bash(cmux *)` 설정으로 cmux 명령은 매번 확인 없이 실행

### 스킬 파일 구조

```
~/.claude/skills/cmux/
├── SKILL.md                    # 핵심 행동 가이드 + 커맨드 요약
└── references/
    ├── cli-reference.md        # 전체 CLI 명령어 레퍼런스
    └── browser-reference.md    # 브라우저 자동화 레퍼런스
```

### 스킬 없이 vs 스킬 적용 시 비교 (벤치마크 결과)

| 시나리오 | 스킬 없이 | 스킬 적용 |
|---------|----------|----------|
| 서버 실행 + 브라우저 확인 | curl로 HTML 파싱 (SPA 불가) | 내장 브라우저 + snapshot + fill |
| 테스트 + 완료 알림 | osascript 알림 (cmux 미연동) | cmux notify (사이드바 알림 링) |
| 멀티 워크스페이스 | 잘못된 CLI 문법 사용 | 정확한 new-workspace 명령 |
| **전체 통과율** | **36%** | **100%** |

---

## 5. 필수 단축키

### 워크스페이스 관리

| 동작 | 단축키 |
|------|--------|
| 새 워크스페이스 | `Cmd+T` |
| 이전/다음 워크스페이스 | `Cmd+{` / `Cmd+}` |
| 워크스페이스 번호로 이동 | `Cmd+1` ~ `Cmd+8` |
| 워크스페이스 닫기 | `Cmd+W` |
| 워크스페이스 이름 변경 | `Cmd+Shift+R` |

### 분할 (Split Panes)

| 동작 | 단축키 |
|------|--------|
| 오른쪽 분할 | `Cmd+D` |
| 아래 분할 | `Cmd+Shift+D` |
| 패인 간 이동 | `Cmd+Option+방향키` |

### 알림

| 동작 | 단축키 |
|------|--------|
| 알림 패널 열기 | `Cmd+Shift+I` |
| 최신 알림으로 점프 | `Cmd+Shift+U` |
| 알림 플래시 | `Cmd+Shift+L` |

### 검색 & 기타

| 동작 | 단축키 |
|------|--------|
| 터미널 내 검색 | `Cmd+F` |
| 커맨드 팔레트 | `Cmd+Shift+P` |

---

## 6. 활용 시나리오

### 시나리오 1: 여러 프로젝트 병렬 작업

여러 프로젝트에서 동시에 Claude Code를 실행하고, 어떤 에이전트가 응답을 기다리는지 한눈에 파악합니다.

```
1. Cmd+T로 워크스페이스 생성
2. cd ~/projects/project-a && claude
3. Cmd+T로 또 다른 워크스페이스 생성
4. cd ~/projects/project-b && claude
5. 사이드바에서 알림 링이 뜬 워크스페이스로 이동 (Cmd+Shift+U)
```

### 시나리오 2: 코드 + 터미널 분할 작업

한쪽에서 Claude Code가 코딩하고, 다른쪽에서 빌드/테스트를 실행합니다.

```
1. Cmd+D로 오른쪽 분할
2. 왼쪽 패인: claude
3. 오른쪽 패인: ./gradlew test --continuous (또는 npm run dev 등)
4. Cmd+Option+← / → 로 패인 간 전환
```

### 시나리오 3: 내장 브라우저로 UI 확인

로컬 서버의 UI를 터미널 옆에서 바로 확인합니다.

```bash
# 브라우저 패널 열기
cmux browser open http://localhost:8080

# 스크린샷 캡처 (Claude에게 전달 가능)
cmux browser screenshot --out /tmp/ui.png

# DOM 스냅샷 (접근성 트리)
cmux browser snapshot
```

### 시나리오 4: Claude Teams (멀티 에이전트)

하나의 작업을 여러 에이전트가 분담합니다. Nightly 빌드에서 사용 가능합니다.

```bash
cmux claude-teams
```

- 각 teammate 에이전트가 cmux 네이티브 스플릿으로 생성됨
- 사이드바에서 각 에이전트 상태를 개별 확인 가능

### 시나리오 5: CLI 자동화

스크립트에서 cmux를 제어할 수 있습니다.

```bash
# 새 워크스페이스 생성 + 명령 실행
cmux new-workspace --name "API Server" --cwd ~/projects/api --command "claude"

# 특정 워크스페이스의 터미널 내용 읽기
cmux read-screen --workspace workspace:1

# 특정 워크스페이스에 입력 보내기
cmux send --workspace workspace:1 "git status"

# 알림 보내기
cmux notify --title "빌드 완료" --body "API 서버 빌드 성공"
```

---

## 7. 유용한 cmux CLI 명령어 모음

| 명령어 | 설명 |
|--------|------|
| `cmux list-workspaces` | 현재 열린 워크스페이스 목록 |
| `cmux current-workspace` | 현재 활성 워크스페이스 정보 |
| `cmux new-workspace --name "이름" --cwd ~/path` | 새 워크스페이스 생성 |
| `cmux new-split right` | 현재 워크스페이스에 오른쪽 분할 |
| `cmux read-screen` | 현재 터미널 화면 텍스트 읽기 |
| `cmux read-screen --scrollback` | 스크롤백 포함 읽기 |
| `cmux send "텍스트"` | 현재 서피스에 텍스트 입력 |
| `cmux notify --title "제목" --body "내용"` | 알림 전송 |
| `cmux list-notifications` | 알림 목록 |
| `cmux identify` | 현재 워크스페이스/서피스 ID 확인 |
| `cmux browser open [url]` | 내장 브라우저 열기 |
| `cmux browser screenshot` | 브라우저 스크린샷 |
| `cmux claude-teams` | 멀티 에이전트 모드 시작 |
| `cmux markdown open file.md` | 마크다운 뷰어로 열기 |

---

## 8. 환경 변수

cmux 터미널 내부에서 자동 설정되는 변수입니다. 스크립트/훅에서 활용할 수 있습니다.

| 변수 | 용도 |
|------|------|
| `CMUX_WORKSPACE_ID` | 현재 워크스페이스 UUID |
| `CMUX_SURFACE_ID` | 현재 서피스 UUID |
| `CMUX_SOCKET_PATH` | cmux 소켓 경로 |
| `TERM` | `xterm-ghostty` |
| `TERM_PROGRAM` | `ghostty` |

---

## 9. 트러블슈팅

### cmux CLI가 동작하지 않을 때
```bash
# cmux가 PATH에 있는지 확인
which cmux

# 없으면 심볼릭 링크 생성
ln -s /Applications/cmux.app/Contents/MacOS/cmux ~/.local/bin/cmux
```

### Hook이 동작하지 않을 때
```bash
# 수동으로 hook 테스트
echo '{}' | cmux claude-hook stop

# 소켓 연결 확인
cmux ping
```

### 알림이 안 뜰 때
- cmux Settings에서 Automation Mode가 **cmux-only** 또는 **allowAll**인지 확인
- macOS 시스템 설정 > 알림에서 cmux 알림이 허용되어 있는지 확인

### cmux 스킬이 동작하지 않을 때
```bash
# 스킬 파일이 존재하는지 확인
ls ~/.claude/skills/cmux/SKILL.md

# Claude Code에서 스킬 목록 확인 (/skills 명령 또는 /reload-plugins)
# Claude Code를 재시작하면 스킬이 자동 로드됩니다
```

### Claude Code가 cmux 명령을 사용하지 않을 때
- `CMUX_WORKSPACE_ID` 환경변수가 설정되어 있는지 확인: `echo $CMUX_WORKSPACE_ID`
- cmux 앱 내부 터미널에서 Claude Code를 실행해야 합니다
- `/cmux` 를 직접 입력하면 스킬을 명시적으로 호출할 수 있습니다

---

## 참고

- cmux 공식 사이트: https://cmux.com
- cmux는 Ghostty 터미널 엔진 기반이므로 `~/.config/ghostty/config`로 터미널 테마/폰트 등을 설정할 수 있습니다.
- 이 가이드는 cmux v0.63.1, Claude Code v2.1.87 기준으로 작성되었습니다.
