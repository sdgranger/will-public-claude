# cmux-browser

  cmux 내장 브라우저에서 로컬 웹 UI를 열고, 확인하고, 인터랙션합니다.

  > **전제 조건**: cmux 터미널 내부에서 실행해야 합니다 (`CMUX_WORKSPACE_ID` 자동 설정).

  ## 주요 기능

  - 로컬 URL 열기 및 페이지 스냅샷 확인
  - 폼 입력 및 버튼 클릭 인터랙션
  - 브라우저 패인 자동 재사용 (중복 열림 방지)

  ## 설치

  `will-public-claude-cmux` 플러그인에 포함되어 있습니다:

  /plugin marketplace add sdgranger/will-public-claude
  /plugin install will-public-claude-cmux

  수동 설치:

  ```bash
  git clone https://github.com/sdgranger/will-public-claude.git /tmp/wpc
  cp /tmp/wpc/skills/cmux-browser/SKILL.md ~/.claude/skills/cmux-browser/
  rm -rf /tmp/wpc

  레퍼런스

  - ../cmux/references/browser-api.md
  - ../cmux/references/common-patterns.md
  - ../cmux/references/cli-reference.md
