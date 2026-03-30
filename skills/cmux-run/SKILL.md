---
name: cmux-run
description: >
  Run a long-running process (server, build, test) in a separate cmux pane with
  automatic pane reuse, process conflict detection, sidebar status, and completion
  notification. Use when you need to start a process in a separate pane and monitor
  it. Requires CMUX_WORKSPACE_ID to be set.
allowed-tools: Bash(cmux *)
---

# cmux-run: 프로세스 실행 & 모니터링

별도 pane에서 서버, 빌드, 테스트 등 장시간 프로세스를 실행하고 모니터링한다.

> **전제 조건**: `CMUX_WORKSPACE_ID`가 설정되어 있어야 한다 (cmux 내부에서 자동 설정).

공통 패턴은 [common-patterns.md](../cmux/references/common-patterns.md) 참조.
CLI 전체 레퍼런스는 [cli-reference.md](../cmux/references/cli-reference.md) 참조.

---

## 핵심 흐름

아래 절차를 순서대로 따른다.

### 1단계: 기존 pane 확인

```bash
cmux list-panes
cmux list-pane-surfaces
```

- Claude 자신의 surface(보통 surface:1)를 제외하고, 재사용 가능한 surface가 있는지 확인한다.
- 자세한 판단 기준은 [common-patterns.md#1-pane-상태-확인](../cmux/references/common-patterns.md) 참조.

### 2단계: 프로세스 충돌 감지

재사용 후보 surface가 있으면:

```bash
cmux read-screen --surface <ref> --lines 30
```

- 셸 프롬프트만 보이면 → 해당 surface 재사용.
- 프로세스가 실행 중이면 → **사용자에게 확인** (재사용 / 종료 후 재실행 / 새 pane).
- 자세한 절차는 [common-patterns.md#2-프로세스-충돌-감지](../cmux/references/common-patterns.md) 참조.

### 3단계: pane 확보

재사용할 surface가 없으면 새로 생성:

```bash
SPLIT_OUT=$(cmux new-split right)
SURFACE=$(echo "$SPLIT_OUT" | grep -o 'surface:[0-9]*')
```

### 4단계: 상태 표시 & 명령 실행

```bash
cmux set-status run "<명령 요약>" --icon play --color "#34c759"
cmux log --level info "프로세스 시작: <명령>"
cmux send --surface $SURFACE "<명령>"
```

### 5단계: 결과 모니터링

```bash
cmux read-screen --surface $SURFACE --lines 30
```

**서버류** (지속 실행 — 예: dev server, database):
- 로그에서 준비 완료 신호를 확인한다: `started`, `listening`, `ready`, `running on port` 등.
- 준비 완료가 확인되면 사용자에게 알리고 다른 작업을 계속한다.

**빌드류** (종료됨 — 예: test, build, compile):
- 프로세스가 종료될 때까지 `read-screen`으로 확인한다.
- 셸 프롬프트가 다시 나타나면 종료된 것으로 판단한다.
- 출력에서 성공/실패 메시지를 확인한다.

### 6단계: 완료 알림

```bash
# 성공 시
cmux log --level success "<결과 메시지>"
cmux notify --title "완료" --body "<결과 요약>"
cmux clear-status run
cmux clear-progress

# 실패 시
cmux log --level error "<에러 메시지>"
cmux notify --title "실패" --body "<에러 요약>"
cmux clear-status run
cmux clear-progress
```

---

## 규칙

- 한 번에 하나의 프로세스만 하나의 pane에서 실행한다.
- **`read-screen` 없이 `send`하지 않는다.**
- **사용자 확인 없이 기존 프로세스를 종료하지 않는다.**
- 서버류와 빌드류를 구분하여 모니터링 방식을 결정한다.
- 장시간 작업은 반드시 `notify`로 완료를 알린다.
