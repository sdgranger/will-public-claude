# cmux 공통 패턴

모든 cmux 고수준 스킬이 참조하는 공통 체크 루틴.

---

## 1. Pane 상태 확인

새 pane을 만들기 전에 반드시 기존 상태를 확인한다.

### 절차

1. 현재 pane 목록 확인:
   ```bash
   cmux list-panes
   ```
2. 각 pane의 surface 목록 확인:
   ```bash
   cmux list-pane-surfaces
   ```
3. **재사용 판단:**
   - Claude가 실행 중인 surface(surface:1)를 제외한 다른 surface가 있으면 재사용 후보
   - 후보 surface의 상태를 `read-screen`으로 확인 후 결정

### 규칙

- `cmux new-split` 전에 **항상** 기존 pane 확인 필수
- surface ID는 명령 반환값에서 파싱하여 이후 명령에 재사용
- Claude 자신이 실행 중인 surface(보통 surface:1)에는 `send`하지 않음

---

## 2. 프로세스 충돌 감지

기존 pane에 명령을 보내기 전에 반드시 현재 상태를 확인한다.

### 절차

1. 대상 surface의 현재 출력 확인:
   ```bash
   cmux read-screen --surface <ref> --lines 30
   ```
2. 출력에서 실행 중인 프로세스 판단:
   - 셸 프롬프트(`$`, `%`, `>`)만 보이면 → **비어있음**, 바로 사용 가능
   - 프로세스 출력이 보이면 → **실행 중**, 사용자 확인 필요
3. 프로세스가 실행 중이면 사용자에게 선택지 제시:
   > "surface:N에서 [프로세스명]이 실행 중입니다. 어떻게 할까요?"
   > 1. 재사용 (현재 프로세스 그대로 두기)
   > 2. 종료 후 새로 실행 (`ctrl+c` → 새 명령)
   > 3. 다른 pane에서 실행

### 규칙

- **사용자 확인 없이 기존 프로세스를 절대 종료하지 않음**
- **`read-screen` 없이 `send`를 절대 하지 않음**
- 종료 시 `cmux send-key --surface <ref> "ctrl+c"`를 사용하고 종료 확인 후 새 명령 실행

---

## 3. Sidebar & Notify 패턴

장시간 작업의 진행 상황을 사용자에게 표시한다.

### 작업 시작 시

```bash
cmux set-status <작업키> "<설명>" --icon <아이콘> --color "<색상>"
cmux log --level info "<작업 시작 메시지>"
```

아이콘 예시: `hammer`(빌드), `play`(서버), `checkmark`(테스트)

### 진행 중 (측정 가능한 경우)

```bash
cmux set-progress <0.0-1.0> --label "<진행 설명>"
```

### 완료/실패 시

```bash
# 성공
cmux log --level success "<결과 메시지>"
cmux notify --title "<작업명> 완료" --body "<결과 요약>"

# 실패
cmux log --level error "<에러 메시지>"
cmux notify --title "<작업명> 실패" --body "<에러 요약>"

# 정리
cmux clear-status <작업키>
cmux clear-progress
```

### 규칙

- 장시간 작업(빌드, 테스트, 서버 시작)은 **반드시** `notify`로 완료 알림
- `set-status`의 키는 작업 종류별로 고유하게 (예: `build`, `test`, `server`)
- 사용자가 다른 워크스페이스에 있을 수 있으므로 notify는 필수

---

## 4. Surface ID 캡처 패턴

`new-split`이나 `browser open-split`의 반환값에서 surface ID를 파싱한다.

### 터미널 split

```bash
SPLIT_OUT=$(cmux new-split right)
# 반환 예시: OK surface=surface:2 pane=pane:2
SURFACE=$(echo "$SPLIT_OUT" | grep -o 'surface:[0-9]*')
# 이후 $SURFACE로 참조
```

### 브라우저 split

```bash
BROWSER_OUT=$(cmux browser open-split http://localhost:3000)
# 반환 예시: OK surface=surface:3 pane=pane:3 placement=split
SURFACE=$(echo "$BROWSER_OUT" | grep -o 'surface:[0-9]*')
```

### 규칙

- 반환된 surface ID를 반드시 변수에 저장하고 이후 명령에 재사용
- 하드코딩된 surface 번호(예: `surface:2`)에 의존하지 않음
