# Skillify — Claude Code Workflow Capture Skill

반복적인 작업을 대화 기록에서 분석하여 재사용 가능한 **SKILL.md**로 자동 생성하는 Claude Code 전용 메타스킬입니다.

## 왜 Skillify인가?

Claude Code를 사용하다 보면 같은 패턴의 작업을 반복하게 됩니다:
- Spring Batch Job 생성할 때마다 같은 설정 파일 구조를 만들고
- API 연동 자동화를 할 때마다 비슷한 curl + jq 파이프라인을 구성하고
- 문서를 정리할 때마다 같은 포맷으로 변환하고

Skillify는 이런 작업을 한 번 수행한 뒤, 대화 기록을 분석해서 **재현 가능한 스킬**로 캡처합니다. 다음부터는 `/my-skill` 한 줄로 동일한 작업을 수행할 수 있습니다.

## 주요 특징

- **대화 기록 기반 컨텍스트 재구성** — 세션 메모리 API 없이 대화 내역 + git artifact + 도구 로그를 분석
- **작업 유형 자동 감지** — 프로젝트 파일이 아닌 실제 수행된 작업 패턴으로 도메인 판별
- **7개 도메인 템플릿** — Spring/Java, Node.js, Python, DevOps, API 자동화, 문서 처리, 범용
- **실시간 기록 모드** — `/skillify-start`로 기록 시작, `/skillify`로 종료 및 스킬 생성
- **allowed-tools 자동 추천** — 대화 중 사용된 도구를 분석하여 세분화된 권한 제안
- **4라운드 구조화 인터뷰** — 체계적인 질문으로 고품질 스킬 생성
- **Smoke Test** — 생성된 스킬을 테스트 프롬프트로 즉시 검증 (선택)
- **Description Optimization** — skill-creator 연동으로 트리거 정확도 최적화 (선택)

## 빠른 시작

### 설치

```bash
# 스킬 디렉토리 생성 및 파일 복사
mkdir -p ~/.claude/skills/skillify/references/templates
cp SKILL.md ~/.claude/skills/skillify/
cp references/templates/*.md ~/.claude/skills/skillify/references/templates/
```

또는 GitHub에서 직접 클론:

```bash
git clone https://github.com/sdgranger/will-public-claude.git /tmp/will-public-claude
cp -r /tmp/will-public-claude/skills/skillify/SKILL.md /tmp/will-public-claude/skills/skillify/references ~/.claude/skills/skillify/
rm -rf /tmp/will-public-claude
```

### 설치 확인

Claude Code에서 `/skillify`를 입력하면 스킬이 인식되어야 합니다.

### 사용법

**모드 1: 단독 실행 (가장 간단)**

대화 기록이 있으면 주제 지정 없이 바로 캡처합니다.

```
/skillify
```

**모드 2: 회고 모드 (주제 지정)**

작업 완료 후 주제를 명시하여 스킬을 생성합니다.

```
/skillify Spring Batch Job 생성 자동화
```

**모드 3: 실시간 기록 모드**

특정 구간만 정확하게 캡처하고 싶을 때 사용합니다.

```
/skillify-start
(작업 수행)
/skillify
```

## 파일 구조

```
~/.claude/skills/skillify/
├── SKILL.md                          # 핵심 워크플로우 (255라인)
├── README.md                         # 이 문서
├── docs/
│   ├── usage-guide.md                # 상세 사용 가이드
│   └── design-decisions.md           # 설계 배경 및 벤치마킹 분석
└── references/
    └── templates/
        ├── spring-java.md            # Spring/Java 개발
        ├── nodejs.md                 # Node.js 개발
        ├── python.md                 # Python 개발
        ├── devops.md                 # DevOps/인프라/시스템 운영
        ├── api-automation.md         # API 호출 자동화
        ├── document-processing.md    # 문서 분석/처리
        └── general.md               # 범용
```

## 지원 도메인

| 도메인 | 감지 신호 | 활용 예시 |
|--------|-----------|-----------|
| Spring/Java | Java 파일, pom.xml, build.gradle | Batch Job 생성, API 개발, JPA 엔티티 설정 |
| Node.js | .ts/.js, package.json | Express API, React 컴포넌트, CLI 도구 |
| Python | .py, requirements.txt, pyproject.toml | 데이터 처리, 스크립트 자동화 |
| DevOps | Dockerfile, CI/CD 설정, 셸 스크립트 | 배포 파이프라인, 서버 설정, 모니터링 |
| API 자동화 | WebFetch/curl 반복 호출, JSON 처리 | 외부 API 연동, 데이터 수집, 자동 보고 |
| 문서 처리 | 문서 읽기/분석/요약 | PDF 정리, CSV 변환, 보고서 생성 |
| 범용 | 해당 없음 | 위 카테고리에 속하지 않는 모든 작업 |

## 생성되는 스킬 예시

Skillify가 생성하는 SKILL.md의 구조:

```yaml
---
name: spring-batch-job-creator
description: >
  Create a Spring Batch job with scheduling configuration.
  Use when the user wants to create a new batch job, scheduled task,
  or periodic data processing. Examples: 'batch job 만들어줘', 'scheduled task 추가'.
allowed-tools:
  - Bash(./gradlew:*)
  - Read
  - Edit
  - Write
argument-hint: "<job-name> <schedule-cron>"
arguments:
  - job-name
  - schedule-cron
---

# Spring Batch Job Creator

## Steps
### 1. Create Job Configuration
...
**Success criteria**: JobConfig 클래스가 컴파일되고 @Configuration 어노테이션 포함

### 2. Build and Verify
...
**Success criteria**: `./gradlew build` 성공 (exit code 0)
```

## 상세 문서

- **[사용 가이드](docs/usage-guide.md)** — 모드별 상세 사용법, 인터뷰 과정, 고급 기능
- **[설계 배경](docs/design-decisions.md)** — 벤치마킹 분석, 개선점, 아키텍처 결정 이유

## 요구사항

- **Claude Code** CLI (다른 AI 에이전트 플랫폼 미지원)
- 스킬 기능이 활성화된 Claude Code 버전

## 라이선스

MIT
