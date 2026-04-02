# Skillify 설계 배경 및 벤치마킹 분석

## 목차

1. [벤치마킹 대상](#벤치마킹-대상)
2. [핵심 설계 결정](#핵심-설계-결정)
3. [기존 구현 대비 개선점](#기존-구현-대비-개선점)
4. [아키텍처 결정 이유](#아키텍처-결정-이유)
5. [향후 개선 방향](#향후-개선-방향)

---

## 벤치마킹 대상

### 1. Anthropic 번들 skillify.ts

**소스**: Claude Code 내부 번들 스킬 (`skills/bundled/skillify.ts`)

**핵심 구조**:
- `getSessionMemoryContent()` API를 통해 세션 메모리에 직접 접근
- `extractUserMessages()` 함수로 사용자 메시지만 필터링
- 4라운드 인터뷰 (고수준 확인 → 구조 → 스텝 상세 → 트리거)
- `registerBundledSkill()` API로 등록, `USER_TYPE === 'ant'` 조건 (Anthropic 내부 전용)

**제한사항**:
- 세션 메모리 API는 Anthropic 내부 전용으로 외부에서 사용 불가
- 어시스턴트 메시지 (실행된 도구, 명령어)는 분석하지 않음
- 도메인별 특화 없이 범용 프로세스만 지원
- 실시간 기록 모드 없음

### 2. kk-r/skillify-skill (v1.0.0)

**소스**: https://github.com/kk-r/skillify-skill

**핵심 구조**:
- 대화 기록 + git artifact (diff, commit)로 컨텍스트 재구성
- 프로젝트 도구 자동 감지 (Node, Python, Go, Rust, Ruby, Make)
- 셸 스크립트 기반 멀티플랫폼 설치 (Claude Code, VS Code, Gemini CLI)
- agentskills.io 표준 준수

**특징**:
- 세션 메모리 없이 동작하는 최초의 오픈소스 skillify
- 멀티플랫폼 호환 (30+ 에이전트 플랫폼)
- 2-tier SKILL.md 구조 (루트 엔트리 + 상세 정의)
- 40 stars, 6 forks (2026-03-31 기준)

**제한사항**:
- 프로젝트 파일 기반 감지 (비개발 작업 미지원)
- 도메인별 템플릿 없음 (감지만 하고 활용하지 않음)
- 실시간 기록 모드 없음
- 멀티플랫폼 지원을 위해 Claude Code 특화 최적화 부족

---

## 핵심 설계 결정

### 결정 1: 세션 메모리 대신 3중 컨텍스트 재구성

**문제**: 번들 skillify.ts의 `getSessionMemoryContent()`는 외부에서 사용 불가

**결정**: 대화 기록 + git artifact + 도구 로그 3가지 소스를 결합

**이유**:
- 대화 기록만으로는 실제 실행된 명령어의 세부사항을 놓칠 수 있음
- git artifact는 코드 변경의 결과를 객관적으로 보여줌
- 도구 로그는 `allowed-tools` 자동 추천에 직접 활용 가능
- 3가지 소스가 서로 보완하여 세션 메모리에 준하는 컨텍스트 제공

### 결정 2: 프로젝트 파일이 아닌 작업 유형 기반 감지

**문제**: kk-r 버전은 프로젝트 파일(pom.xml 등)로 도메인을 감지하여 비개발 작업 미지원

**결정**: 실제 수행된 작업 패턴(사용된 도구, 처리한 파일 유형, 호출한 API)으로 감지

**이유**:
- Java 프로젝트에서 Python 스크립트를 작성할 수 있음 → 작업의 본질에 집중
- API 자동화, 문서 처리 등은 프로젝트 파일이 없을 수 있음
- git 저장소가 없는 환경에서도 정확한 도메인 감지 가능

### 결정 3: 도메인별 참조 템플릿 (Progressive Disclosure)

**문제**: 번들/kk-r 모두 도메인 특화 지식 없이 범용 스킬만 생성

**결정**: 7개 도메인 템플릿을 `references/templates/`에 분리, 감지된 것만 로드

**이유**:
- SKILL.md를 500라인 이내로 유지 (skill-creator 가이드 권장)
- 불필요한 템플릿을 컨텍스트에 로드하지 않아 토큰 절약
- 새 도메인 추가 시 파일 하나만 작성하면 됨
- 생성되는 스킬은 템플릿에 의존하지 않음 (독립적)

### 결정 4: 실시간 기록 모드 추가

**문제**: 기존 구현들은 전체 대화를 분석하여 관련 없는 내용이 섞임

**결정**: `/skillify-start` 마커 기반 실시간 기록 모드 추가

**이유**:
- 긴 대화에서 특정 작업만 캡처하는 명확한 방법 필요
- 마커는 대화 내 텍스트이므로 별도 상태 관리 불필요
- 기존 회고 모드와 자연스럽게 공존

### 결정 5: Claude Code 전용

**문제**: kk-r 버전은 30+ 플랫폼을 지원하느라 각 플랫폼 최적화 부족

**결정**: Claude Code에만 집중

**이유**:
- 사내 환경에서 Claude Code만 사용
- AskUserQuestion, Agent, Bash 등 Claude Code 전용 도구 활용 가능
- 멀티플랫폼 설치 스크립트 등 불필요한 복잡도 제거
- 필요 시 생성되는 SKILL.md는 agentskills.io 표준이므로 다른 플랫폼에서도 사용 가능

### 결정 6: 4라운드 표준 인터뷰

**문제**: 인터뷰 깊이를 어떻게 설정할 것인가

**결정**: 번들 skillify.ts와 동일한 4라운드 구조 채택

**이유**:
- 검증된 구조 — Anthropic 내부에서 사용 중
- 4라운드가 과도하지 않으면서 충분한 정보를 수집
- 각 라운드의 목적이 명확하여 사용자 혼란 최소화
- 단순 작업은 각 라운드의 질문이 적어 자연스럽게 빠르게 진행

---

## 기존 구현 대비 개선점

### 번들 skillify.ts 대비

| 항목 | 번들 skillify.ts | Skillify (본 구현) |
|------|-----------------|-------------------|
| 컨텍스트 소스 | 세션 메모리 API (내부 전용) | 대화 기록 + git + 도구 로그 |
| 도메인 지원 | 범용만 | 7개 도메인 템플릿 |
| 비개발 작업 | 미지원 | API 자동화, 문서 처리 지원 |
| 기록 모드 | 없음 | `/skillify-start` 실시간 기록 |
| allowed-tools | 수동 설정 | 대화 분석 자동 추천 |
| 사용 범위 | Anthropic 내부 전용 | 누구나 사용 가능 |

### kk-r/skillify-skill 대비

| 항목 | kk-r/skillify-skill | Skillify (본 구현) |
|------|---------------------|-------------------|
| 플랫폼 | 30+ 멀티플랫폼 | Claude Code 전용 (최적화) |
| 도메인 감지 | 프로젝트 파일 기반 | 작업 패턴 기반 |
| 템플릿 | 없음 (감지만) | 7개 도메인별 참조 템플릿 |
| 비개발 작업 | 미지원 | API 자동화, 문서 처리 지원 |
| 기록 모드 | 없음 | `/skillify-start` 실시간 기록 |
| 컨텍스트 깊이 | 대화 + git | 대화 + git + 도구 로그 |
| 설치 | 셸 스크립트 | 단순 파일 복사 |
| 파일 구조 | 2-tier SKILL.md | SKILL.md + references/ (Progressive Disclosure) |

---

## 아키텍처 결정 이유

### Progressive Disclosure 패턴

```
SKILL.md (401라인, 항상 로드)
    ↓ 필요 시에만 Read
references/templates/*.md (도메인별 60~100라인)
```

**왜 이 구조인가?**

Claude Code의 스킬 시스템은 SKILL.md 본문을 스킬 트리거 시 항상 컨텍스트에 로드합니다. 7개 템플릿을 모두 SKILL.md에 포함하면 700라인 이상이 되어:
1. 컨텍스트 윈도우를 불필요하게 소비
2. 500라인 권장 한도 초과
3. 관련 없는 도메인 정보가 스킬 생성 품질을 저하

대신 SKILL.md에는 핵심 워크플로우만 담고, Phase 0에서 감지된 도메인의 템플릿만 `Read` 도구로 로드합니다.

### 교정 이벤트 → Rules 변환

대화 중 사용자가 방향을 수정한 지점은 해당 작업의 **암묵적 규칙**을 드러냅니다:

```
사용자: "아니, JdbcCursorItemReader 말고 JpaPagingItemReader를 써줘"
         ↓ 교정 이벤트 감지
생성된 스킬 Rules: "Reader는 JpaPagingItemReader를 사용할 것"
```

이 패턴은 번들 skillify.ts에서도 강조하지만, 실제 Rules로 변환하는 메커니즘은 명시하지 않았습니다. 본 구현에서는 Phase 0에서 교정 이벤트를 태깅하고, Phase 2에서 Rules 섹션으로 변환하는 흐름을 명시합니다.

### 마커 기반 기록 모드

실시간 기록 모드는 `/skillify-start`라는 **별도 스킬**로 분리합니다 (`skills/skillify-start/SKILL.md`):
- Claude Code에서 한 SKILL.md의 `name` 프론트매터는 하나의 커맨드만 등록하므로, 같은 파일 안에서 `/skillify-start`와 `/skillify`를 구분할 방법이 없음
- `/skillify-start`의 역할은 `[SKILLIFY RECORDING STARTED]` 마커를 대화에 삽입하는 것뿐 — 공유해야 할 상태가 없으므로 두 스킬 간 결합도 없음
- 마커는 대화 내 텍스트이므로 `/skillify` 호출 시 대화 스캔으로 자연스럽게 감지됨

### skill-creator 융합: Smoke Test + Description Optimization

**결정**: Phase 4a (Smoke Test)와 Phase 4b (Description Optimization)를 선택적 후속 단계로 추가

**Smoke Test (Phase 4a) — skill-creator 불필요:**
- 생성된 스킬이 실제로 의도대로 동작하는지 2-3개 테스트 프롬프트로 검증
- 서브에이전트로 실행하여 각 스텝의 성공 기준 충족 여부 확인
- 문제 발견 시 SKILL.md 수정 → 재테스트 반복
- 별도 플러그인 없이 Claude Code의 Agent 도구만으로 동작

**Description Optimization (Phase 4b) — skill-creator 필요:**
- skill-creator의 `run_loop.py` 스크립트를 직접 호출
- 20개 트리거 쿼리 (should-trigger 10 + should-not-trigger 10) 생성
- train/test 분리로 과적합 방지, `claude -p`로 실제 트리거 확률 측정
- extended thinking으로 실패 원인 분석 → 개선안 생성 → 최대 5회 반복
- skill-creator 미설치 시: 수동 설치 안내 + `/skill-creator`로 나중에 최적화하는 방법 안내

**이유:**
- Smoke test는 스킬 품질의 기본 검증 → 모든 사용자에게 유용, 의존성 없음
- Description optimization은 트리거 정확도 개선 → 검증된 도구(skill-creator)를 재사용
- 두 단계 모두 선택적 → 빠르게 끝내고 싶은 사용자는 Skip 가능
- skill-creator의 전체 eval 루프(HTML 뷰어, 벤치마크, blind comparison)는 과도하여 제외

---

## 향후 개선 방향

### 단기

1. **적응형 인터뷰**: 단순 작업은 1-2라운드, 복잡 작업은 4라운드 자동 조절
2. **스킬 버전 관리**: 같은 이름의 스킬을 업데이트할 때 이전 버전 백업

### 중기

3. **도메인 템플릿 확장**: Kotlin, Rust, Go, Terraform 등 도메인 추가
4. **팀 스킬 공유**: GitHub 레포에서 스킬을 pull/push하는 워크플로우
5. **스킬 조합**: 기존 스킬들을 결합하여 복합 워크플로우 생성

### 장기

6. **스킬 사용 분석**: 어떤 스킬이 얼마나 사용되는지 추적
7. **멀티플랫폼 확장**: 필요 시 agentskills.io 표준 기반으로 다른 플랫폼 지원
