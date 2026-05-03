# ARCHITECTURE_CHECKLIST.md

> 검증 에이전트용 체크리스트. 각 항목 ID는 안정적이며, 위반 보고 시 `→ ARCHITECTURE.md §X` 참조.
> 항목은 자기-완결적. 충돌 시 `ARCHITECTURE.md`가 우선.

각 항목 형식: `ID (Severity) — Scope: Check 내용`
- Severity: `MUST`(차단) / `SHOULD`(경고) / `MAY`(자유 선택, 검증 안 함) / `CONDITIONAL`(조건 충족 시 적용)

---

## A. 의존성 방향 → §1

- **A-01 (MUST)** `domain/**`: `org.springframework.*`, `jakarta.persistence.*`, `com.fasterxml.*`, `lombok.*`, `jakarta.validation.*` import 0건
- **A-02 (MUST)** `domain/**`: 자기 프로젝트의 `application.*`, `controller.*`, `listener.*`, `infrastructure.*` import 0건
- **A-03 (MUST)** `controller/**`, `listener/**`: `domain.repository.*`, `*JpaEntity`, `domain.model.*` 직접 import 0건 (의존 가능 대상은 ApplicationService 클래스 또는 `application/usecase/**`의 인터페이스)
- **A-04 (MUST)** `application/**`: `controller.*`, `listener.*` import 0건

## B. 도메인 엔티티 → §2.1

- **B-01 (MUST)** `domain/model/**`: setter 메서드 0건, `@Setter`/`@Data` 0건
- **B-02 (MUST)** `domain/**`: JPA/Spring/Lombok/Jackson/Validation 어노테이션 0건
- **B-03 (SHOULD)** `domain/model/**`: Aggregate Root에 `XxxSnapshot` record + `toSnapshot()`/`reconstitute(XxxSnapshot)` 양방향 패턴 적용. 매퍼·영속성 어댑터는 도메인 내부를 `toSnapshot()`을 통해서만 읽는다 (개별 getter 호출 지양)
- **B-04 (MAY)** `domain/model/**`: 식별자를 값 객체 타입(`UserId` 등)으로 표현하는 패턴 — 채택 시 일관성 유지
- **B-05 (MAY)** `domain/model/**`: 정적 팩토리 메서드(`register`, `create`)로 신규 생성 의도를 분리하는 패턴 — 채택 시 일관성 유지

## C. Aggregate / 도메인 Repository → §2.2, §2.3

- **C-01 (MUST)** `domain/repository/**`: 모든 타입이 `interface`이며 이름이 `*Repository`
- **C-02 (MUST)** `domain/repository/**`: 메서드 시그니처에 `*JpaEntity`, `*Dto`, `*Request`, `*Response` 등장 0건
- **C-03 (SHOULD)** `domain/repository/**`: Repository는 **Aggregate Root 단위로만** 정의 — Aggregate 내부 엔티티에 대한 Repository는 만들지 않는다
- **C-04 (SHOULD)** `application/service/**`: ApplicationService는 Aggregate Root Repository만 호출. Aggregate 내부 엔티티를 직접 로드/저장하지 않는다

## D. ApplicationService / 인터페이스 추상화 → §2.4

- **D-01 (MUST)** `application/service/**`: 클래스명이 동사구 + `Service` (예: `RegisterUserService`), `@Service` 부착
- **D-02 (MUST)** `application/service/**` 메서드: 파라미터는 `*Command`/`*Query`, 반환은 `*Result` 또는 `void` (원시 타입 나열 금지)
- **D-03 (MUST)** 전체: `@Transactional`은 `application/service/**`에만 위치
- **D-04 (SHOULD)** `application/service/**`: 신규 저장 시 `userRepository.save(user)`의 **반환값**을 사용한다 (입력 객체를 그대로 반환·전달하지 않는다 — id/createdAt이 채워지지 않음)
- **D-05 (CONDITIONAL/MUST)** `application/usecase/**`에 인터페이스가 존재하는 경우:
  - 인터페이스명이 **역할을 표현하는 동사구**여야 함 — `*UseCase`, `*Port` 등 의미 없는 접미사 금지
  - 구현체 명명: 다중 구현은 변별 형용사 + 인터페이스명(예: `TossProcessPayment`), 단일 구현은 `DefaultXxx`(예: `DefaultRegisterUser`)
  - 모든 구현체는 인터페이스를 `implements`
  - 인터페이스 부재 자체는 위반이 아님

## E. Controller / DTO 변환 → §2.5

- **E-01 (MUST)** `controller/**`: 필드 타입은 ApplicationService 클래스(`*Service`) 또는 `application/usecase/**`의 인터페이스만
- **E-02 (MUST)** `controller/dto/request/**`: `toCommand()` 또는 `toQuery()` 인스턴스 메서드 존재, 컨트롤러가 호출
- **E-03 (MUST)** `controller/dto/response/**`: `public static * from(*Result)` 정적 팩토리 존재
- **E-04 (MUST)** `application/usecase/**`, `application/service/**`: 메서드 파라미터에 `*Request` 등장 0건
- **E-05 (MUST)** `controller/**`: 메서드 반환 타입에 `domain.model.*` 등장 0건

## F. Outbound Adapter → §2.6

- **F-01 (MUST)** `infrastructure/adapter/persistence/**`: `@Entity` 클래스명이 `*JpaEntity`로 종료
- **F-02 (MUST)** `infrastructure/adapter/persistence/**`: `*PersistenceAdapter`가 `domain.repository.*Repository`를 `implements`
- **F-03 (MUST)** `infrastructure/adapter/persistence/**`: PersistenceAdapter는 `*Mapper`를 의존해 변환 위임 (직접 `new *JpaEntity(...)` 인라인 변환 금지)
- **F-04 (MUST)** 빌드 파일·소스 전체: `org.mapstruct`, `org.modelmapper` 의존성 및 `@Mapper`/`ModelMapper` 사용 0건
- **F-05 (SHOULD)** `infrastructure/adapter/persistence/**Mapper.java`: 분기/검증/계산 로직 없이 단순 필드 매핑만 (변환 책임만 보유)
- **F-06 (SHOULD)** `infrastructure/adapter/persistence/**JpaEntity.java`: 영속 상태 갱신은 `applySnapshot(XxxSnapshot)` 메서드로 제공한다 (매퍼가 아닌 JpaEntity의 책임)
- **F-07 (SHOULD)** `infrastructure/adapter/persistence/**PersistenceAdapter.java`: `save(domain)` 구현은 Snapshot의 id가 null이면 신규(매퍼로 새 JpaEntity 생성), id가 있으면 기존(`findById` 후 `applySnapshot`). `Persistable`/`isNew()` 미사용. JPA Dirty Checking으로 UPDATE
- **F-08 (MUST)** `infrastructure/adapter/external/**`: 외부 응답 DTO가 `application/**`, `domain/**`에 노출 0건

## G. 테스트 → §2.7

- **G-01 (MUST)** `domain/**`의 각 클래스에 대응하는 `*Test.java` 존재
- **G-02 (MUST)** `application/service/**`의 각 `*Service`에 대응하는 `*ServiceTest.java` 존재
- **G-03 (MUST)** 각 `*Controller`에 대응하는 테스트가 `@WebMvcTest` 사용 (`@SpringBootTest` 금지)
- **G-04 (MUST)** 모든 `*Test.java`: 테스트 클래스/`@Test` 메서드/`@Nested` 클래스에 한국어 `@DisplayName` (값에 한글 포함)
- **G-05 (SHOULD)** `*Test.java`: 테스트 메서드 2개 이상이면 `@Nested` 그룹화
- **G-06 (SHOULD)** `*Test.java`: 각 `@Test` 본문에 `// given`, `// when`, `// then` 주석(또는 동등한 메서드 분리)
- **G-07 (MUST)** `domain/**` 및 `application/service/**` 테스트에 `@SpringBootTest` 0건
- **G-08 (SHOULD)** `*Test.java`: 메서드명이 `[Method]_[Scenario]_[Result]` 패턴이거나 SUT 메서드명을 그대로 포함하지 않음

---

## 보고 형식

```
[VIOLATION] B-01 (MUST) — src/main/java/.../User.java:42
  found: public void setEmail(String)
  → ARCHITECTURE.md §2.1
  fix: 도메인 의도가 드러나는 행위 메서드(예: changeEmail(NewEmail))로 대체
```

MUST → 차단, SHOULD → 경고, MAY → 자유 선택(검증 안 함), CONDITIONAL → 조건이 충족될 때만 적용.
