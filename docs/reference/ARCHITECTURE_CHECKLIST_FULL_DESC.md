# ARCHITECTURE_CHECKLIST.md

> **검증 에이전트용 체크리스트**
> 본 문서는 `ARCHITECTURE.md`(코드 생성 가이드)에 정의된 규칙을 검증하기 위한 체크 항목 모음이다.
> 각 항목은 자기-완결적이며, 위반 시 사용자에게 제시할 근거 섹션을 `→ ARCHITECTURE.md §X` 형태로 참조한다.
> 항목 ID는 `<주제>-<번호>` 형태이며 안정적이다 (외부 도구가 ID로 참조).

---

## 사용 방법

- 검증 에이전트는 PR/diff 또는 변경된 파일 단위로 적용 가능한 항목을 선택해 검사한다.
- 각 항목은 다음 필드를 갖는다:
  - **ID** — 안정적 식별자
  - **Severity** — `MUST`(위반 시 차단) / `SHOULD`(경고) / `MAY`(정보성)
  - **Scope** — 검사 대상 패키지/파일 글롭
  - **Check** — 무엇을 확인하는지
  - **How to detect** — 정적 분석/grep/AST 힌트
  - **Rationale** — 왜 이 규칙이 존재하는지 (위반 보고 시 사용자에게 노출)
  - **Reference** — `ARCHITECTURE.md` 근거 섹션
- 본 체크리스트는 **단일 진실 원천이 아니다** — 충돌 시 `ARCHITECTURE.md`를 우선한다.

---

## A. 의존성 방향 (Dependency Direction)

### A-01. 도메인은 외부 프레임워크에 의존하지 않는다
- **Severity**: MUST
- **Scope**: `**/domain/**/*.java`
- **Check**: `domain` 패키지의 어떤 파일도 `org.springframework.*`, `jakarta.persistence.*`, `com.fasterxml.*`, `lombok.*`, `jakarta.validation.*` 패키지를 import 하지 않는다.
- **How to detect**: import 문 정적 분석. `grep -rE "^import (org\.springframework|jakarta\.persistence|com\.fasterxml|lombok|jakarta\.validation)" src/main/java/**/domain/`
- **Rationale**: 도메인이 프레임워크에 결합되면 비즈니스 로직 단위 테스트가 느려지고 기술 교체가 어려워진다.
- **Reference**: ARCHITECTURE.md §2, §4.1

### A-02. 도메인은 application/controller/infrastructure를 참조하지 않는다
- **Severity**: MUST
- **Scope**: `**/domain/**/*.java`
- **Check**: `domain` 패키지의 import 문에 자기 프로젝트의 `application.*`, `controller.*`, `listener.*`, `infrastructure.*` 패키지가 등장하지 않는다.
- **How to detect**: import 정적 분석. ArchUnit `noClasses().that().resideInAPackage("..domain..").should().dependOnClassesThat().resideInAnyPackage(...)` 룰과 등가.
- **Rationale**: 의존성은 안쪽으로만 향한다. 도메인이 바깥을 알면 헥사고날이 깨진다.
- **Reference**: ARCHITECTURE.md §2

### A-03. 컨트롤러는 Repository/JPA Entity/도메인 엔티티를 직접 참조하지 않는다
- **Severity**: MUST
- **Scope**: `**/controller/**/*.java`, `**/listener/**/*.java`
- **Check**: 인바운드 어댑터의 클래스는 `domain.repository.*`, `*.JpaEntity`, `domain.model.*`을 import 하지 않는다 (의존은 UseCase 인터페이스만 허용).
- **How to detect**: import 정적 분석.
- **Rationale**: 컨트롤러가 도메인/영속성을 직접 알면 레이어 경계가 무너지고, 비즈니스 로직이 컨트롤러에 새어든다.
- **Reference**: ARCHITECTURE.md §4.3

### A-04. 어플리케이션 레이어는 인바운드 어댑터를 참조하지 않는다
- **Severity**: MUST
- **Scope**: `**/application/**/*.java`
- **Check**: `application` 패키지가 `controller.*` 또는 `listener.*`를 import 하지 않는다.
- **How to detect**: import 정적 분석.
- **Rationale**: 단방향 의존성 유지.
- **Reference**: ARCHITECTURE.md §2

---

## B. 도메인 엔티티 (Domain Entity)

### B-01. 도메인 엔티티에 setter가 없다
- **Severity**: MUST
- **Scope**: `**/domain/model/**/*.java`
- **Check**: `public void set*(`로 시작하는 메서드, `@Setter`/`@Data` 어노테이션, Lombok `@AllArgsConstructor`(public)이 없다.
- **How to detect**: AST 또는 regex `public\s+void\s+set[A-Z]`, 어노테이션 검사.
- **Rationale**: 무분별한 상태 변경을 막고 도메인 메서드를 통한 의도적 변경만 허용 (Tell, Don't Ask).
- **Reference**: ARCHITECTURE.md §4.1

### B-02. 도메인 엔티티에 JPA/Spring/Lombok/Jackson/Validation 어노테이션이 없다
- **Severity**: MUST
- **Scope**: `**/domain/model/**/*.java`, `**/domain/repository/**/*.java`, `**/domain/service/**/*.java`
- **Check**: `@Entity`, `@Table`, `@Column`, `@Id`, `@Component`, `@Service`, `@Autowired`, `@Data`, `@Setter`, `@Getter`, `@JsonProperty`, `@NotNull`, `@Valid` 등이 등장하지 않는다.
- **How to detect**: 어노테이션 정적 검사.
- **Rationale**: 도메인은 순수 POJO. 프레임워크 어노테이션은 도메인을 오염시킨다.
- **Reference**: ARCHITECTURE.md §4.1

### B-03. ID/식별자는 별도 값 객체로 표현한다
- **Severity**: SHOULD
- **Scope**: `**/domain/model/**/*.java`
- **Check**: 도메인 엔티티의 식별자 필드가 `Long`/`String`/`UUID` 같은 원시·범용 타입이 아닌 도메인 값 객체(`UserId`, `OrderId` 등) 타입이다.
- **How to detect**: 엔티티 클래스의 `id` 필드 타입 검사.
- **Rationale**: 식별자에 도메인 의미를 부여하고 타입 안전성을 확보.
- **Reference**: ARCHITECTURE.md §4.1

### B-04. 정적 팩토리 메서드를 통한 생성을 권장한다
- **Severity**: SHOULD
- **Scope**: `**/domain/model/**/*.java`
- **Check**: 도메인 엔티티가 `public` 생성자 대신 의도가 드러나는 정적 팩토리(`register`, `create`, `reconstitute` 등)를 제공한다.
- **How to detect**: 클래스의 public 생성자 vs `public static` 팩토리 메서드 존재 여부.
- **Rationale**: 신규 생성과 영속성 복원 의도를 분리하고, 생성 시점의 불변식을 보장.
- **Reference**: ARCHITECTURE.md §4.1

### B-05. 비즈니스 규칙은 도메인 엔티티 내부에 위치한다 (Anti-Anemic)
- **Severity**: SHOULD
- **Scope**: `**/application/service/**/*.java`, `**/domain/model/**/*.java`
- **Check**: ApplicationService에 분기·검증·계산 로직이 누적되어 있고 도메인 엔티티가 단순 데이터 컨테이너라면 위반.
- **How to detect**: 휴리스틱 — ApplicationService 메서드의 cyclomatic complexity가 높고 도메인 엔티티에 행위 메서드가 없으면 경고.
- **Rationale**: Anemic Domain Model은 객체지향의 의도를 거스른다. 비즈니스 규칙은 데이터 옆에 있어야 한다.
- **Reference**: ARCHITECTURE.md §4.1, §4.2

---

## C. 도메인 Repository

### C-01. 도메인 Repository는 인터페이스로 정의된다
- **Severity**: MUST
- **Scope**: `**/domain/repository/**/*.java`
- **Check**: `domain.repository` 패키지의 모든 타입이 `interface`이다.
- **How to detect**: AST에서 type kind 검사.
- **Rationale**: 도메인은 구현이 아닌 추상에 의존해야 한다.
- **Reference**: ARCHITECTURE.md §4.1

### C-02. Repository 메서드 시그니처는 도메인 모델만 입출력한다
- **Severity**: MUST
- **Scope**: `**/domain/repository/**/*.java`
- **Check**: 메서드 파라미터/반환 타입에 `*JpaEntity`, `*Dto`, `*Request`, `*Response` 가 등장하지 않는다.
- **How to detect**: 메서드 시그니처 타입 검사.
- **Rationale**: 영속성 표현과 도메인 표현의 결합을 막는다.
- **Reference**: ARCHITECTURE.md §4.1

### C-03. Repository 클래스명은 `XxxRepository` 형태이다
- **Severity**: SHOULD
- **Scope**: `**/domain/repository/**/*.java`
- **Check**: 인터페이스명이 `*Repository`로 끝난다.
- **How to detect**: 파일명/클래스명 패턴.
- **Rationale**: 일관된 명명으로 도메인 객체의 생명주기 인터페이스임을 드러낸다.
- **Reference**: ARCHITECTURE.md §4.1

---

## D. UseCase / ApplicationService

### D-01. 모든 UseCase는 인터페이스로 추상화되어 있다
- **Severity**: MUST
- **Scope**: `**/application/usecase/**/*.java`
- **Check**: `application.usecase` 패키지의 타입이 모두 `interface`이며 이름이 `*UseCase`로 끝난다.
- **How to detect**: AST + 파일명 검사.
- **Rationale**: 인바운드 포트 추상화로 컨트롤러와 구현의 결합을 끊는다.
- **Reference**: ARCHITECTURE.md §4.2

### D-02. ApplicationService가 UseCase 인터페이스를 구현한다
- **Severity**: MUST
- **Scope**: `**/application/service/**/*.java`
- **Check**: 클래스명이 `*Service`이고 `implements *UseCase`를 갖는다.
- **How to detect**: AST에서 implements 절 검사.
- **Rationale**: 유스케이스 단위로 구현체를 식별 가능하게 한다.
- **Reference**: ARCHITECTURE.md §4.2

### D-03. UseCase 입출력은 Command/Query/Result이다
- **Severity**: MUST
- **Scope**: `**/application/usecase/**/*.java`
- **Check**: UseCase 인터페이스 메서드의 파라미터는 `*Command`/`*Query`이고 반환 타입은 `*Result` 또는 `void`이다 (원시 타입 나열 금지).
- **How to detect**: 메서드 시그니처 검사.
- **Rationale**: 호출 의도 명확화, 향후 필드 추가 시 시그니처 안정성 확보.
- **Reference**: ARCHITECTURE.md §4.2

### D-04. 트랜잭션 경계는 ApplicationService에만 있다
- **Severity**: MUST
- **Scope**: 전체
- **Check**: `@Transactional`이 `application.service` 외 패키지(controller, infrastructure, domain)에 등장하지 않는다.
- **How to detect**: `@Transactional` 어노테이션 위치 grep.
- **Rationale**: 유스케이스 범위가 트랜잭션 경계와 일치해야 한다.
- **Reference**: ARCHITECTURE.md §4.2

### D-05. ApplicationService는 생성자 주입을 사용한다 (필드 주입 금지)
- **Severity**: MUST
- **Scope**: `**/application/service/**/*.java`, `**/controller/**/*.java`, `**/infrastructure/**/*.java`
- **Check**: `@Autowired` 필드 주입이 없다. 생성자가 1개이며 `final` 필드를 통한 주입.
- **How to detect**: 필드의 `@Autowired` 검색, 생성자 개수 검사.
- **Rationale**: 불변성, 테스트 용이성, 순환 의존 조기 발견.
- **Reference**: ARCHITECTURE.md §4.2

---

## E. Inbound Adapter (Controller / Listener)

### E-01. 컨트롤러는 UseCase 인터페이스만 의존한다
- **Severity**: MUST
- **Scope**: `**/controller/**/*.java`
- **Check**: 컨트롤러 필드는 `*UseCase` 타입만 가진다 (Repository, ApplicationService 구현체, JPA Entity 직접 의존 금지).
- **How to detect**: 필드 타입 검사.
- **Rationale**: 인바운드 포트만 통해 비즈니스 호출.
- **Reference**: ARCHITECTURE.md §4.3

### E-02. Request DTO에 toCommand()/toQuery()가 있다
- **Severity**: MUST
- **Scope**: `**/controller/dto/request/**/*.java`
- **Check**: Request DTO에 `toCommand()` 또는 `toQuery()` 인스턴스 메서드가 있고, 컨트롤러 메서드가 이 변환 메서드를 호출한다.
- **How to detect**: AST에서 DTO 메서드 + 컨트롤러 호출 흐름 검사.
- **Rationale**: 변환 로직을 컨트롤러에서 분리해 컨트롤러를 얇게 유지.
- **Reference**: ARCHITECTURE.md §5

### E-03. Response DTO에 from(Result) 정적 팩토리가 있다
- **Severity**: MUST
- **Scope**: `**/controller/dto/response/**/*.java`
- **Check**: Response DTO에 `public static * from(*Result)` 시그니처의 메서드가 있다.
- **How to detect**: AST 검사.
- **Rationale**: 도메인 결과 → 외부 표현 변환 책임을 DTO에 위치.
- **Reference**: ARCHITECTURE.md §5

### E-04. Request DTO를 Command로 그대로 사용하지 않는다
- **Severity**: MUST
- **Scope**: `**/application/usecase/**/*.java`, `**/application/service/**/*.java`
- **Check**: UseCase의 파라미터 타입이 `*Request`가 아니다.
- **How to detect**: 메서드 시그니처 검사.
- **Rationale**: 외부 표현(Request)과 내부 모델(Command)을 분리.
- **Reference**: ARCHITECTURE.md §4.2, §5

### E-05. 컨트롤러가 도메인 엔티티를 직접 반환하지 않는다
- **Severity**: MUST
- **Scope**: `**/controller/**/*.java`
- **Check**: 컨트롤러 메서드의 반환 타입에 `domain.model.*`가 등장하지 않는다 (`ResponseEntity<User>` 등 금지).
- **How to detect**: 반환 타입 검사.
- **Rationale**: 직렬화가 도메인 모델을 오염시키는 것을 방지.
- **Reference**: ARCHITECTURE.md §4.3

---

## F. Outbound Adapter (Persistence / External)

### F-01. JPA Entity 클래스명은 `XxxJpaEntity`이다
- **Severity**: MUST
- **Scope**: `**/infrastructure/adapter/persistence/**/*.java`
- **Check**: `@Entity`가 붙은 클래스명이 `*JpaEntity`로 끝난다.
- **How to detect**: 어노테이션 + 클래스명 패턴.
- **Rationale**: 도메인 엔티티와 명확히 구분.
- **Reference**: ARCHITECTURE.md §4.4

### F-02. Persistence Adapter가 도메인 Repository를 구현한다
- **Severity**: MUST
- **Scope**: `**/infrastructure/adapter/persistence/**/*.java`
- **Check**: `*PersistenceAdapter` 클래스가 `domain.repository.*Repository` 인터페이스를 구현한다.
- **How to detect**: implements 절 검사.
- **Rationale**: 도메인이 정의한 생명주기 계약을 인프라가 충족한다.
- **Reference**: ARCHITECTURE.md §4.4

### F-03. Persistence Adapter는 Mapper에 변환을 위임한다
- **Severity**: MUST
- **Scope**: `**/infrastructure/adapter/persistence/**/*.java`
- **Check**: `*PersistenceAdapter`가 직접 `new *JpaEntity(...)` 또는 인라인 변환을 수행하지 않고 `*Mapper`를 의존해 호출한다.
- **How to detect**: AST에서 어댑터 내부의 직접 생성자 호출 패턴 vs 매퍼 호출 패턴.
- **Rationale**: 변환 책임을 한 곳에 모아 가독성·재사용성 확보.
- **Reference**: ARCHITECTURE.md §4.4

### F-04. MapStruct/ModelMapper를 사용하지 않는다
- **Severity**: MUST
- **Scope**: 전체 (`pom.xml` / `build.gradle` 포함)
- **Check**: 의존성에 `org.mapstruct`, `org.modelmapper`가 없고, 코드에 `@Mapper`(MapStruct), `ModelMapper` import가 없다.
- **How to detect**: 빌드 파일 + import 검사.
- **Rationale**: 매핑은 도메인 의도가 들어가는 코드라 명시적이어야 한다 (1:1 매핑이 아닐 수 있음).
- **Reference**: ARCHITECTURE.md §4.4

### F-05. Mapper에 비즈니스 로직이 없다
- **Severity**: SHOULD
- **Scope**: `**/infrastructure/adapter/persistence/**/*Mapper.java`
- **Check**: Mapper 메서드 내부에 분기/검증/계산 로직이 없고 단순 필드 매핑만 한다.
- **How to detect**: 휴리스틱 — Mapper 메서드의 cyclomatic complexity가 임계치를 넘으면 경고.
- **Rationale**: Mapper는 변환만, 비즈니스 규칙은 도메인에.
- **Reference**: ARCHITECTURE.md §4.4

### F-06. Mapper의 컬렉션 반환은 null이 아닌 빈 컬렉션이다
- **Severity**: SHOULD
- **Scope**: `**/infrastructure/adapter/persistence/**/*Mapper.java`
- **Check**: 컬렉션 반환 메서드에 `return null` 이 없다.
- **How to detect**: AST `return null` 검색.
- **Rationale**: 호출 측 NPE 방지.
- **Reference**: ARCHITECTURE.md §4.4

### F-07. 외부 응답 모델은 어댑터를 벗어나지 않는다
- **Severity**: MUST
- **Scope**: `**/infrastructure/adapter/external/**/*.java`
- **Check**: 외부 API 응답 DTO가 `application` 또는 `domain` 패키지에 노출되지 않는다.
- **How to detect**: 외부 어댑터의 응답 DTO 클래스 가시성(`package-private` 권장) + import 흐름.
- **Rationale**: 외부 API 변경이 내부 레이어로 전파되지 않게 격리.
- **Reference**: ARCHITECTURE.md §4.4

---

## G. 테스트 (Test)

### G-01. 도메인 엔티티/도메인 서비스에 단위 테스트가 있다
- **Severity**: MUST
- **Scope**: `**/domain/**/*.java` ↔ `**/test/**/domain/**/*Test.java`
- **Check**: `domain.model`과 `domain.service`의 각 클래스에 대응하는 `*Test.java`가 존재한다.
- **How to detect**: 파일 매핑 검사.
- **Rationale**: 비즈니스 규칙은 단위 테스트로 보호되어야 한다.
- **Reference**: ARCHITECTURE.md §7.1

### G-02. ApplicationService에 단위 테스트가 있다
- **Severity**: MUST
- **Scope**: `**/application/service/**/*.java` ↔ `**/test/**/application/service/**/*Test.java`
- **Check**: 각 `*Service` 클래스에 대응하는 `*ServiceTest.java`가 존재한다.
- **How to detect**: 파일 매핑.
- **Rationale**: 유스케이스 오케스트레이션 검증.
- **Reference**: ARCHITECTURE.md §7.1

### G-03. 컨트롤러에 MVC 테스트가 있다
- **Severity**: MUST
- **Scope**: `**/controller/**/*Controller.java` ↔ 대응 테스트
- **Check**: 대응 테스트가 `@WebMvcTest`를 사용한다 (`@SpringBootTest` 아님).
- **How to detect**: 어노테이션 검사.
- **Rationale**: HTTP 계약과 직렬화/검증 검증, 빠른 슬라이스 테스트 유지.
- **Reference**: ARCHITECTURE.md §7.1

### G-04. 모든 테스트 클래스/메서드에 한국어 @DisplayName이 있다
- **Severity**: MUST
- **Scope**: `**/test/**/*Test.java`
- **Check**: 테스트 클래스와 `@Test` 메서드, `@Nested` 클래스에 `@DisplayName`이 있고 값이 한국어를 포함한다.
- **How to detect**: 어노테이션 존재 + 값에 한글(유니코드 범위) 포함 검사.
- **Rationale**: 테스트가 살아있는 문서로 기능하려면 도메인 언어로 읽혀야 한다.
- **Reference**: ARCHITECTURE.md §7.2

### G-05. @Nested로 시나리오를 그룹화한다
- **Severity**: SHOULD
- **Scope**: `**/test/**/*Test.java`
- **Check**: 테스트 메서드가 2개 이상이면 `@Nested` 클래스로 그룹화되어 있다 (외부=대상/메서드, 내부=조건/상황).
- **How to detect**: AST에서 `@Test` 개수와 `@Nested` 클래스 존재 검사.
- **Rationale**: 시나리오의 계층 구조가 IDE/리포트에서 가독성 있게 드러난다.
- **Reference**: ARCHITECTURE.md §7.2

### G-06. Given-When-Then 단계 구분이 있다
- **Severity**: SHOULD
- **Scope**: `**/test/**/*Test.java`
- **Check**: 각 `@Test` 메서드 본문에 `// given`, `// when`, `// then` 주석(혹은 동등한 메서드 분리)이 있다.
- **How to detect**: 메서드 본문의 주석 패턴.
- **Rationale**: 테스트 의도가 단계별로 드러나 행동 명세서 역할을 한다.
- **Reference**: ARCHITECTURE.md §7.2

### G-07. 단위 테스트에 @SpringBootTest를 사용하지 않는다
- **Severity**: MUST
- **Scope**: `**/test/**/domain/**/*Test.java`, `**/test/**/application/service/**/*Test.java`
- **Check**: 도메인/유스케이스 단위 테스트에 `@SpringBootTest`가 없다.
- **How to detect**: 어노테이션 검사.
- **Rationale**: 컨텍스트 로딩이 단위 테스트의 속도와 격리를 해친다.
- **Reference**: ARCHITECTURE.md §7.2

### G-08. 테스트명에 SUT 메서드명을 그대로 포함하는 패턴을 쓰지 않는다
- **Severity**: SHOULD
- **Scope**: `**/test/**/*Test.java`
- **Check**: 테스트 메서드명이 `[Method]_[Scenario]_[Result]` 형태이거나 SUT 메서드명을 그대로 포함하는 패턴이 아니다 (예: `register_whenEmailDuplicated_throwsException` 지양).
- **How to detect**: 메서드명 패턴 휴리스틱.
- **Rationale**: 테스트는 코드가 아닌 행동을 검증하며, 이름은 도메인 언어여야 한다.
- **Reference**: ARCHITECTURE.md §7.2

### G-09. Fixture 클래스가 분리되어 있다
- **Severity**: SHOULD
- **Scope**: `**/test/**/*Fixture.java` 와 `**/test/**/*Test.java`
- **Check**: 테스트에서 도메인 객체 생성이 반복될 때 `*Fixture` 클래스의 정적 팩토리(`aUser()`, `aUserWith(...)`)를 사용한다 (테스트 본문에 `User.register(...)` 직접 호출 반복 회피).
- **How to detect**: 휴리스틱 — 같은 도메인 생성자 호출이 N개 이상 테스트에서 반복되면 Fixture 추출 권장.
- **Rationale**: 테스트 의도에 집중하고 setup 노이즈를 줄인다.
- **Reference**: ARCHITECTURE.md §7.2

---

## H. 명명 규칙 (Naming) — 보조 검증

### H-01. 클래스명 컨벤션 준수
- **Severity**: SHOULD
- **Scope**: 전체
- **Check**:
  - 도메인 Repository → `*Repository` (interface, in `domain.repository`)
  - UseCase → `*UseCase` (interface, in `application.usecase`)
  - ApplicationService → `*Service` (in `application.service`)
  - Controller → `*Controller`
  - Request/Response → `*Request`/`*Response`
  - Command/Query/Result → `*Command`/`*Query`/`*Result`
  - JPA Entity → `*JpaEntity`
  - Persistence Adapter → `*PersistenceAdapter`
  - Mapper → `*Mapper` 또는 `*PersistenceMapper`
  - Test → `*Test`, Fixture → `*Fixture`
- **How to detect**: 패키지+클래스명 패턴 검사.
- **Rationale**: 일관된 명명은 코드베이스 전반의 인지 부하를 줄인다.
- **Reference**: ARCHITECTURE.md §4 전반, §6 코드 예시

---

## 검증 결과 보고 형식 (권장)

검증 에이전트가 결과를 보고할 때 다음 형식을 권장한다:

```
[VIOLATION] B-01 (MUST) — src/main/java/com/example/app/domain/model/User.java:42
  Setter found: public void setEmail(String email)
  Rationale: 무분별한 상태 변경을 막고 도메인 메서드를 통한 의도적 변경만 허용 (Tell, Don't Ask).
  Reference: ARCHITECTURE.md §4.1
  Suggestion: 도메인 의도가 드러나는 행위 메서드(예: changeEmail(NewEmail))로 대체.
```

- 위반 항목은 ID로 식별하고, severity, 파일/라인, 사용자 친화 설명, 근거 섹션, 수정 제안을 포함한다.
- MUST 위반은 빌드 차단 후보, SHOULD는 경고, MAY는 정보성으로 분류한다.

---

*본 체크리스트는 `ARCHITECTURE.md`의 종속 산출물이다. 두 문서가 충돌하면 `ARCHITECTURE.md`가 우선한다.*
