# will-my-claude

Claude Code를 더 잘 활용하기 위한 플러그인, 스킬, 설정 모음입니다.

## 포함 내용

### skills/cmux

[cmux](https://cmux.com) 터미널에서 Claude Code를 사용할 때 자동으로 활용되는 스킬입니다.

- 빌드/테스트를 별도 패인에서 실행하고 결과 확인
- 내장 브라우저로 로컬 웹 UI 검사 및 자동화 (snapshot, fill, click)
- 사이드바에 빌드 상태/프로그레스 표시
- 장시간 작업 완료 시 알림 전송
- 여러 프로젝트를 별도 워크스페이스에서 병렬 관리

### setup/

cmux + Claude Code 연동을 한 번에 설정하는 스크립트와 가이드입니다.

| 파일 | 설명 |
|------|------|
| `setup-cmux-claude-hooks.sh` | 원클릭 설정 스크립트 (hooks + cmux.json + 스킬 설치) |
| `cmux-claude-code-guide.md` | 설정 방법, 단축키, 활용 시나리오, 트러블슈팅 가이드 |

## 설치

### cmux 스킬만 설치

```bash
mkdir -p ~/.claude/skills/cmux/references
cp skills/cmux/SKILL.md ~/.claude/skills/cmux/
cp skills/cmux/references/* ~/.claude/skills/cmux/references/
```

### 전체 설정 (hooks + cmux.json + 스킬)

cmux 터미널 내부에서 실행:

```bash
bash setup/setup-cmux-claude-hooks.sh
```

## 벤치마크

스킬 적용 전후 비교 (3개 시나리오, 14개 assertion):

| 지표 | 스킬 없이 | 스킬 적용 |
|------|----------|----------|
| assertion 통과율 | 36% (5/14) | **100% (14/14)** |
| 평균 토큰 | 10,243 | 13,371 |
| 평균 소요시간 | 39.0s | 37.6s |

스킬 없이는 잘못된 CLI 문법 사용, curl로 웹 UI 확인 시도, cmux 알림 대신 osascript 사용 등의 문제가 발생합니다.

## 요구 사항

- macOS 14.0+
- [cmux](https://cmux.com) (brew install cmux)
- [Claude Code](https://claude.ai/claude-code) (npm install -g @anthropic-ai/claude-code)

## 라이선스

MIT
