# will-my-claude

Claude Code를 더 잘 활용하기 위한 스킬, 설정 모음입니다.

---

## skills/cmux

[cmux](https://cmux.com) 터미널에서 Claude Code를 사용할 때 자동으로 활용되는 스킬입니다.

스킬을 설치하면 Claude Code가 cmux 환경을 감지하고 패인 분할, 내장 브라우저, 알림, 사이드바 등을 **알아서** 활용합니다.

### 설치

```bash
git clone https://github.com/sdgranger/will-my-claude.git
mkdir -p ~/.claude/skills/cmux/references
cp will-my-claude/skills/cmux/SKILL.md ~/.claude/skills/cmux/
cp will-my-claude/skills/cmux/references/* ~/.claude/skills/cmux/references/
```

Claude Code를 재시작하면 바로 적용됩니다.

### (선택) 사이드바 hooks 설정

사이드바에 알림 링, "Running" 상태 등이 **자동 표시**되길 원하면 hooks를 추가로 설정하세요:

```bash
bash will-my-claude/setup/setup-cmux-hooks.sh
```

스킬만으로도 cmux 활용에는 문제없습니다. hooks는 사이드바 연동만 추가합니다.
자세한 내용은 [setup/cmux-claude-code-guide.md](setup/cmux-claude-code-guide.md)를 참고하세요.

## 요구 사항

- macOS 14.0+
- [cmux](https://cmux.com) v0.63.1+ (`brew install cmux`)
- [Claude Code](https://claude.ai/claude-code) (`npm install -g @anthropic-ai/claude-code`)

## 라이선스

MIT
