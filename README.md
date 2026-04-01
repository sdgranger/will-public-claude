# will-public-claude

Claude Code를 더 잘 활용하기 위한 스킬, 설정 모음입니다.

---

## skills/cmux

[cmux](https://cmux.com) 터미널에서 Claude Code를 사용할 때 자동으로 활용되는 스킬입니다.

스킬을 설치하면 Claude Code가 cmux 환경을 감지하고 패인 분할, 내장 브라우저, 알림, 사이드바 등을 **알아서** 활용합니다.

### 설치 (플러그인)

Claude Code에서 아래 명령을 실행하세요:

```
/plugin marketplace add sdgranger/will-public-claude
/plugin install will-public-claude
```

GitHub에 업데이트가 올라오면 자동으로 반영됩니다.

### 설치 (수동)

플러그인 대신 파일을 직접 복사할 수도 있습니다 (자동 업데이트 없음):

```bash
git clone https://github.com/sdgranger/will-public-claude.git
mkdir -p ~/.claude/skills/cmux/references
cp will-public-claude/skills/cmux/SKILL.md ~/.claude/skills/cmux/
cp will-public-claude/skills/cmux/references/* ~/.claude/skills/cmux/references/
```

### (선택) 사이드바 hooks 설정

사이드바에 알림 링, "Running" 상태 등이 **자동 표시**되길 원하면 hooks를 추가로 설정하세요:

```bash
bash will-public-claude/setup/setup-cmux-hooks.sh
```

스킬만으로도 cmux 활용에는 문제없습니다. hooks는 사이드바 연동만 추가합니다.
자세한 내용은 [setup/cmux-claude-code-guide.md](setup/cmux-claude-code-guide.md)를 참고하세요.

## skills/skillify

반복적인 작업을 대화 기록에서 분석하여 재사용 가능한 **SKILL.md**로 자동 생성하는 메타스킬입니다.

- **대화 기록 + git + 도구 로그**를 분석하여 컨텍스트 재구성 (세션 메모리 API 불필요)
- **작업 유형 자동 감지**: Spring/Java, Node.js, Python, DevOps, API 자동화, 문서 처리, 범용
- **실시간 기록 모드**: `/skillify-start` → 작업 → `/skillify`로 특정 구간만 캡처
- **4라운드 구조화 인터뷰**로 고품질 스킬 생성

### 사용법

```
# 작업 완료 후 회고 모드
/skillify Spring Batch Job 생성 자동화

# 실시간 기록 모드
/skillify-start
(작업 수행)
/skillify
```

### 수동 설치

```bash
mkdir -p ~/.claude/skills/skillify/references/templates
cp skills/skillify/SKILL.md ~/.claude/skills/skillify/
cp skills/skillify/references/templates/*.md ~/.claude/skills/skillify/references/templates/
```

자세한 내용은 [skills/skillify/README.md](skills/skillify/README.md)를 참고하세요.

---

## 요구 사항

- [Claude Code](https://claude.ai/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- cmux 스킬 사용 시: macOS 14.0+, [cmux](https://cmux.com) v0.63.1+ (`brew install cmux`)

## 라이선스

MIT
