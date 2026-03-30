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

## 요구 사항

- macOS 14.0+
- [cmux](https://cmux.com) v0.63.1+ (`brew install cmux`)
- [Claude Code](https://claude.ai/claude-code) (`npm install -g @anthropic-ai/claude-code`)

## 라이선스

MIT
