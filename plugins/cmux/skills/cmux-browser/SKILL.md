---
name: cmux-browser
description: Open and interact with local web UIs in the cmux embedded browser for verification and testing.
allowed-tools: Bash(cmux *)
---

# cmux-browser: 브라우저 테스트

cmux 내장 브라우저에서 로컬 웹 UI를 열고, 확인하고, 인터랙션한다.

> **전제 조건**: `CMUX_WORKSPACE_ID`가 설정되어 있어야 한다 (cmux 내부에서 자동 설정).

공통 패턴은 [common-patterns.md](../cmux/references/common-patterns.md) 참조.
브라우저 API 전체 레퍼런스는 [browser-api.md](../cmux/references/browser-api.md) 참조.
CLI 전체 레퍼런스는 [cli-reference.md](../cmux/references/cli-reference.md) 참조.

---

## 핵심 흐름

### 1단계: 서버 확인

브라우저를 열기 전에, 대상 URL의 서버가 실행 중인지 확인한다.
- 서버가 떠있지 않으면 → 사용자에게 cmux-run으로 서버를 먼저 실행할 것을 안내한다.
- 서버가 이미 떠있으면 → 다음 단계로 진행한다.

### 2단계: 기존 브라우저 pane 확인

```bash
cmux list-pane-surfaces
```

- 이미 브라우저 타입의 surface가 있으면 → URL을 확인한다:
  ```bash
  cmux browser <existing-surface> url
  ```
  - 같은 URL이면 → 해당 surface 재사용. `reload`로 최신 상태 반영.
  - 다른 URL이면 → `navigate`로 이동하거나 새 브라우저 열기.
- 브라우저 surface가 없으면 → 다음 단계에서 생성.

### 3단계: 브라우저 열기

```bash
BROWSER_OUT=$(cmux browser open-split <url>)
SURFACE=$(echo "$BROWSER_OUT" | grep -o 'surface:[0-9]*')
```

### 4단계: 페이지 로드 대기 & 확인

```bash
cmux browser $SURFACE wait --load-state complete --timeout-ms 15000
cmux browser $SURFACE snapshot --interactive --compact
```

- `snapshot`의 결과로 페이지 구조와 인터랙션 가능한 요소를 파악한다.
- 이미지가 필요한 경우에만 `screenshot`을 사용한다.

### 5단계: 인터랙션 (필요 시)

```bash
# 폼 입력
cmux browser $SURFACE fill "<selector>" --text "<value>"

# 버튼 클릭
cmux browser $SURFACE click "<selector>" --snapshot-after

# 텍스트 대기
cmux browser $SURFACE wait --text "<expected text>"
```

### 6단계: 완료 알림

```bash
cmux notify --title "브라우저 확인 완료" --body "<결과 요약>"
```

---

## 규칙

- **`snapshot` 우선** — `screenshot`보다 `snapshot`을 기본으로 사용한다. 텍스트가 추론에 유리하다.
- 브라우저 pane이 이미 열려있으면 URL 비교 후 재사용 또는 navigate한다.
- 서버가 안 떠있으면 cmux-run을 안내한다 — 직접 서버를 실행하지 않는다.
- surface ID를 반드시 변수에 캡처하여 재사용한다.
- 인터랙션 후 `--snapshot-after` 또는 별도 `snapshot`으로 결과를 확인한다.
