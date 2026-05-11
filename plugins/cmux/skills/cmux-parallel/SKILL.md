---
name: cmux-parallel
description: Run 2+ independent processes in parallel across cmux panes with per-task status tracking.
allowed-tools: Bash(cmux *)
---

# cmux-parallel: 병렬 작업 관리

여러 프로세스를 동시에 실행하고, 각각의 상태를 추적하며, 전체 완료 시 알린다.

> **전제 조건**: `CMUX_WORKSPACE_ID`가 설정되어 있어야 한다 (cmux 내부에서 자동 설정).

공통 패턴은 [common-patterns.md](../cmux/references/common-patterns.md) 참조.
CLI 전체 레퍼런스는 [cli-reference.md](../cmux/references/cli-reference.md) 참조.

---

## 핵심 흐름

### 1단계: 작업 분석

요청된 작업들을 파악한다:
- 작업 수
- 각 작업의 종류 (서버류 vs 빌드류)
- 같은 워크스페이스에서 실행할지, 별도 워크스페이스가 필요한지

**판단 기준:**
- 작업 4개 이하 + 같은 프로젝트 → **같은 워크스페이스 내 pane 분할**
- 작업 5개 이상 또는 서로 다른 프로젝트 디렉토리 → **워크스페이스 분리**

### 2단계: 기존 pane 확인

```bash
cmux list-panes
cmux list-pane-surfaces
```

기존 pane 중 재사용 가능한 것이 있는지 확인한다. 각 후보 surface에 대해 프로세스 충돌 감지를 수행한다.
자세한 절차는 [common-patterns.md](../cmux/references/common-patterns.md) 참조.

### 3단계-A: 같은 워크스페이스 내 병렬

필요한 만큼 pane을 확보한다 (기존 재사용 + 부족분 새로 생성):

```bash
# 새 pane이 필요한 경우
SPLIT_OUT=$(cmux new-split right)
SURFACE_1=$(echo "$SPLIT_OUT" | grep -o 'surface:[0-9]*')

SPLIT_OUT=$(cmux new-split down)
SURFACE_2=$(echo "$SPLIT_OUT" | grep -o 'surface:[0-9]*')
```

각 surface에 작업별 상태를 설정하고 명령을 실행:

```bash
# 작업 1
cmux set-status task1 "<작업1 설명>" --icon hammer --color "#ff9500"
cmux send --surface $SURFACE_1 "<명령1>"

# 작업 2
cmux set-status task2 "<작업2 설명>" --icon play --color "#34c759"
cmux send --surface $SURFACE_2 "<명령2>"
```

### 3단계-B: 워크스페이스 분리

```bash
cmux new-workspace --name "<작업1 이름>" --cwd <작업1 디렉토리> --command "<명령1>"
cmux new-workspace --name "<작업2 이름>" --cwd <작업2 디렉토리> --command "<명령2>"
```

### 4단계: 모니터링

각 작업의 상태를 독립적으로 확인:

```bash
cmux read-screen --surface $SURFACE_1 --lines 20
cmux read-screen --surface $SURFACE_2 --lines 20
```

- 하나가 실패해도 나머지는 계속 진행한다.
- 각 작업의 성공/실패를 개별적으로 추적한다.

### 5단계: 종합 결과 알림

모든 작업이 완료되면:

```bash
cmux log --level success "전체 N개 작업 완료: 성공 X, 실패 Y"
cmux notify --title "병렬 작업 완료" --body "성공 X/N — 실패 Y/N"
cmux clear-status task1
cmux clear-status task2
cmux clear-progress
```

---

## 규칙

- pane 분할은 **최대 4개**까지. 그 이상은 워크스페이스 분리를 권장한다.
- 각 작업의 `set-status` 키는 고유하게 설정한다 (예: `task1`, `task2`).
- **하나의 작업 실패가 다른 작업에 영향을 주지 않는다.**
- **각 surface에 `send` 전에 반드시 `read-screen`**으로 상태를 확인한다.
- **사용자 확인 없이 기존 프로세스를 종료하지 않는다.**
