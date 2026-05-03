# ARCHITECTURE_CHECKLIST.md

> 검증 에이전트용 체크리스트. `ARCHITECTURE.md`(코드 생성 가이드)에 정의된 규칙을 검증한다.
> 항목 ID는 안정적(`<주제>-<번호>`). 위반 보고 시 `→ ARCHITECTURE.md §X` 참조.
> 충돌 시 `ARCHITECTURE.md`가 우선.

각 항목 형식:
- **ID** / **Severity** (`MUST`/`SHOULD`/`MAY`/`CONDITIONAL`) / **Scope** / **Check** / **Rationale** / **Reference**

---

## A. 의존성 방향

### A-01. 도메인은 외부 프레임워크에 의존하지 않는다
- **Severity**: MUST
- **Scope**: `**/domain/**/*.java`
- **Check**: `org.springframework.*`, `jakarta.persistence.*`, `com.fasterxml.*`, `lombok.*`, `jakarta.validation.*` import 0건
- **Rationale**: 비즈니스 로직 단위 테스트 속도와 기술 교체 용이성을 보장.
- **Reference**: §2, §4.1

### A-02. 도메인은 다른 레이어를 참조하지 않는다
- **Severity**: MUST
- **Scope**: `**/domain/**/*.java`
- **Check**: 자기 프로젝트의 `application.*`, `controller.*`, `listener.*`, `infrastructure.*` import 0건
- **Rationale**: 의존성 방향(안쪽으로만) 유지.
- **Reference**: §2

### A-03. 컨트롤러는 Repository/JPA Entity/도메인 엔티티를 직접 참조하지 않는다
- **Severity**: MUST
- **Scope**: `**/controller/**/*.java`, `**/listener/**/*.java`
- **Check**: `domain.repository.*`, `*JpaEntity`, `domain.model.*` import 0건 (의존 가능 대상은 ApplicationService 클래스 또는 `application/usecase/**`의 인터페이스)
- **Rationale**: 비즈니스 로직 누수와 레이어 경계 붕괴 방지.
- **Reference**: §4.3

### A-04. application은 인바운드 어댑터를 참조하지 않는다
- **Severity**: MUST
- **Scope**: `**/application/**/*.java`
- **Check**: `controller.*`, `listener.*` import 0건
- **Rationale**: 단방향 의존성.
- **Reference**: §2

---

## B. 도메인 엔티티

### B-01. setter가 없다
- **Severity**: MUST
- **Scope**: `**/domain/model/**/*.java`
- **Check**: `public void set*(` 메서드, `@Setter`/`@Data`/public `@AllArgsConstructor` 0건
- **Rationale**: 의도적 변경(Tell, Don't Ask) 강제.
- **Reference**: §4.1

### B-02. 프레임워크 어노테이션이 없다
- **Severity**: MUST
- **Scope**: `**/domain/**/*.java`
- **Check**: JPA/Spring/Lombok/Jackson/Validation 어노테이션 0건
- **Rationale**: 도메인은 순수 POJO.
- **Reference**: §4.1

### B-03. Snapshot 양방향 패턴
- **Severity**: SHOULD
- **Scope**: `**/domain/model/**/*.java` (Aggregate Root)
- **Check**: Aggregate Root에 `XxxSnapshot` record(같은 패키지)와 `toSnapshot()`/`reconstitute(XxxSnapshot)` 양방향 메서드가 존재. 매퍼·영속성 어댑터가 도메인 내부를 `toSnapshot()`으로만 읽는다 (개별 getter 호출 지양)
- **Rationale**: Lombok 없이 강한 캡슐화를 유지하면서 매퍼 접근을 한 통로로 정리. 영속성 매핑·변경 감지·이벤트 페이로드에 일관되게 재사용 가능.
- **Reference**: §4.1

### B-04. 식별자 값 객체 패턴 (선택)
- **Severity**: MAY
- **Scope**: `**/domain/model/**/*.java`
- **Check**: 식별자를 값 객체 타입(`UserId` 등)으로 표현하는 패턴 — 채택 시 일관성 유지
- **Rationale**: 타입 안전성·도메인 의미 부여. 보일러플레이트 비용이 있어 자유 선택.
- **Reference**: §4.1

### B-05. 정적 팩토리 메서드 패턴 (선택)
- **Severity**: MAY
- **Scope**: `**/domain/model/**/*.java`
- **Check**: 정적 팩토리 메서드(`register`, `create`)로 신규 생성 의도를 분리하는 패턴 — 채택 시 일관성 유지
- **Rationale**: 생성 의도 분리, 불변식 보장. 자유 선택. (영속성 복원은 B-03의 `reconstitute`가 담당)
- **Reference**: §4.1

### B-06. 비즈니스 규칙은 도메인에 위치한다 (Anti-Anemic)
- **Severity**: SHOULD
- **Scope**: `**/application/service/**`, `**/domain/model/**`
- **Check**: 휴리스틱 — ApplicationService에 분기·검증·계산 로직이 누적되고 도메인 엔티티가 단순 데이터 컨테이너이면 위반
- **Rationale**: Anemic Domain Model 안티패턴 회피.
- **Reference**: §4.1, §4.2

---

## C. Aggregate / 도메인 Repository

### C-01. 인터페이스로 정의된다
- **Severity**: MUST
- **Scope**: `**/domain/repository/**/*.java`
- **Check**: 모든 타입이 `interface`
- **Rationale**: 추상에 대한 의존.
- **Reference**: §4.1

### C-02. 시그니처는 도메인 모델만 입출력한다
- **Severity**: MUST
- **Scope**: `**/domain/repository/**/*.java`
- **Check**: `*JpaEntity`, `*Dto`, `*Request`, `*Response` 등장 0건
- **Rationale**: 영속성·도메인 표현 분리.
- **Reference**: §4.1

### C-03. 클래스명은 `XxxRepository`이다
- **Severity**: SHOULD
- **Scope**: `**/domain/repository/**/*.java`
- **Check**: 인터페이스명이 `*Repository`로 종료
- **Rationale**: 일관된 명명.
- **Reference**: §4.1

### C-04. Repository는 Aggregate Root 단위로만 정의된다
- **Severity**: SHOULD
- **Scope**: `**/domain/repository/**/*.java`
- **Check**: Aggregate 내부 엔티티(예: `OrderLine`)에 대한 Repository를 만들지 않는다 — 내부 엔티티는 Aggregate Root를 통해 로드/저장된다
- **Rationale**: Aggregate 경계 안에서만 일관성을 보장. 내부 엔티티를 직접 조회·저장하면 Aggregate 불변식이 깨질 수 있음.
- **Reference**: §2, §4.1

### C-05. ApplicationService는 Aggregate Root Repository만 호출한다
- **Severity**: SHOULD
- **Scope**: `**/application/service/**/*.java`
- **Check**: ApplicationService 내부에서 Aggregate 내부 엔티티를 직접 로드/저장하지 않는다 (Aggregate Root를 통해서만)
- **Rationale**: Aggregate 경계 유지.
- **Reference**: §2, §4.1

---

## D. ApplicationService / 인터페이스 추상화

### D-01. ApplicationService는 동사구 + `Service` 형태이다
- **Severity**: MUST
- **Scope**: `**/application/service/**/*.java`
- **Check**: 클래스명이 동사구로 시작하고 `*Service`로 종료(`RegisterUserService`, `SendMoneyService`), `@Service` 부착
- **Rationale**: 일관된 식별성.
- **Reference**: §4.2

### D-02. 입출력은 Command/Query/Result이다
- **Severity**: MUST
- **Scope**: `**/application/service/**/*.java` 의 public 메서드
- **Check**: 메서드 파라미터는 `*Command`/`*Query`, 반환은 `*Result` 또는 `void`
- **Rationale**: 호출 의도 명확화, 시그니처 안정성.
- **Reference**: §4.2

### D-03. 트랜잭션 경계는 ApplicationService에만 있다
- **Severity**: MUST
- **Scope**: 전체
- **Check**: `@Transactional`이 `application/service/**` 외에 등장 0건
- **Rationale**: 유스케이스 범위 = 트랜잭션 범위.
- **Reference**: §4.2

### D-04. 신규 저장 시 save() 반환값을 사용한다
- **Severity**: SHOULD
- **Scope**: `**/application/service/**/*.java`
- **Check**: `userRepository.save(user)` 호출 후 입력 객체(`user`)를 그대로 사용·반환하지 않고 `save()`의 반환값을 사용
- **Rationale**: id/createdAt 등 DB 발급 필드가 입력 객체에는 없음. 반환값에만 채워져 있다.
- **Reference**: §4.2

### D-05. 인터페이스 추상화 도입은 선택적이며 명명 규칙을 따른다
- **Severity**: CONDITIONAL
- **Scope**: `**/application/usecase/**/*.java`, `**/application/service/**/*.java`
- **Check**:
  - `application/usecase` 패키지가 비어있어도 **위반 아님** (인터페이스 부재 자체는 허용)
  - 인터페이스가 존재하는 경우:
    - 인터페이스명은 **역할을 표현하는 동사구**여야 함 — `*UseCase`, `*Port` 등 의미 없는 접미사 금지 (예: `ProcessPayment` ✓ / `ProcessPaymentUseCase` ✗)
    - 모든 타입이 `interface`
    - 구현체 명명: 다중 구현은 변별 형용사 + 인터페이스명(예: `TossProcessPayment`), 단일 구현은 `DefaultXxx`(예: `DefaultRegisterUser`)
    - 모든 구현체는 인터페이스를 `implements`
    - 가능하면 컨트롤러는 인터페이스에 의존
- **Rationale**: 인터페이스 추상화는 다중 구현·테스트 분리·계약 명시가 필요할 때만 가치가 있다. 인터페이스명에 기술적 접미사(`UseCase`, `Port`)를 붙이는 것은 정보 가치 없는 명명이다.
- **Reference**: §4.2

---

## E. Inbound Adapter

### E-01. 컨트롤러는 ApplicationService 또는 인터페이스에만 의존한다
- **Severity**: MUST
- **Scope**: `**/controller/**/*.java`
- **Check**: 필드 타입은 `*Service`(ApplicationService 클래스) 또는 `application/usecase/**`의 인터페이스만 (Repository/Entity 직접 의존 금지)
- **Rationale**: 인바운드 경계만 통한 비즈니스 호출.
- **Reference**: §4.3

### E-02. Request DTO에 toCommand()/toQuery()가 있다
- **Severity**: MUST
- **Scope**: `**/controller/dto/request/**/*.java`
- **Check**: `toCommand()` 또는 `toQuery()` 인스턴스 메서드 존재, 컨트롤러에서 호출
- **Rationale**: 변환 책임을 DTO로, 컨트롤러는 얇게.
- **Reference**: §5

### E-03. Response DTO에 from(Result) 정적 팩토리가 있다
- **Severity**: MUST
- **Scope**: `**/controller/dto/response/**/*.java`
- **Check**: `public static * from(*Result)` 메서드 존재
- **Rationale**: 도메인 결과 → 외부 표현 변환을 DTO에 위치.
- **Reference**: §5

### E-04. Request DTO를 Command로 그대로 사용하지 않는다
- **Severity**: MUST
- **Scope**: `**/application/usecase/**`, `**/application/service/**`
- **Check**: 메서드 파라미터에 `*Request` 등장 0건
- **Rationale**: 외부 표현과 내부 모델 분리.
- **Reference**: §4.2, §5

### E-05. 컨트롤러가 도메인 엔티티를 직접 반환하지 않는다
- **Severity**: MUST
- **Scope**: `**/controller/**/*.java`
- **Check**: 메서드 반환 타입에 `domain.model.*` 등장 0건
- **Rationale**: 직렬화 노이즈가 도메인을 오염시키지 않게.
- **Reference**: §4.3

---

## F. Outbound Adapter

### F-01. JPA Entity는 `XxxJpaEntity`이다
- **Severity**: MUST
- **Scope**: `**/infrastructure/adapter/persistence/**/*.java`
- **Check**: `@Entity` 클래스명이 `*JpaEntity`로 종료
- **Rationale**: 도메인 엔티티와 명확히 구분.
- **Reference**: §4.4

### F-02. PersistenceAdapter가 도메인 Repository를 구현한다
- **Severity**: MUST
- **Scope**: `**/infrastructure/adapter/persistence/**/*.java`
- **Check**: `*PersistenceAdapter`가 `domain.repository.*Repository`를 `implements`
- **Rationale**: 도메인 계약 충족.
- **Reference**: §4.4

### F-03. 변환은 Mapper에 위임한다
- **Severity**: MUST
- **Scope**: `**/infrastructure/adapter/persistence/**/*.java`
- **Check**: PersistenceAdapter가 `*Mapper`를 의존해 호출 (인라인 `new *JpaEntity(...)` 변환 금지)
- **Rationale**: 변환 책임 집중.
- **Reference**: §4.4

### F-04. MapStruct/ModelMapper를 사용하지 않는다
- **Severity**: MUST
- **Scope**: 전체 (빌드 파일 포함)
- **Check**: `org.mapstruct`, `org.modelmapper` 의존성 0건, `@Mapper`/`ModelMapper` import 0건
- **Rationale**: 1:N/N:1 매핑·필드명 차이가 있어 명시적 매핑이 필요.
- **Reference**: §4.4

### F-05. Mapper는 변환 책임만 가진다
- **Severity**: SHOULD
- **Scope**: `**/infrastructure/adapter/persistence/**Mapper.java`
- **Check**: 분기·검증·계산 로직 없이 단순 필드 매핑만. `applySnapshot` 같은 영속 상태 갱신 로직을 매퍼에 두지 않는다 (JpaEntity의 책임)
- **Rationale**: Mapper는 변환만, 비즈니스 로직과 영속 상태 갱신은 분리.
- **Reference**: §4.4

### F-06. JpaEntity가 applySnapshot 메서드를 제공한다
- **Severity**: SHOULD
- **Scope**: `**/infrastructure/adapter/persistence/**JpaEntity.java`
- **Check**: 영속 상태 갱신은 JpaEntity의 `applySnapshot(XxxSnapshot)` 메서드를 통해 이뤄진다 — 변경 가능 필드만 갱신, id·createdAt 같은 불변 필드는 건드리지 않음
- **Rationale**: 영속 상태 갱신은 JpaEntity의 책임. JPA Dirty Checking이 실제 변경된 컬럼만 UPDATE에 포함.
- **Reference**: §4.4

### F-07. PersistenceAdapter의 save는 id로 신규/기존을 분기한다
- **Severity**: SHOULD
- **Scope**: `**/infrastructure/adapter/persistence/**PersistenceAdapter.java`
- **Check**: `save(domain)` 구현이 Snapshot의 id가 null이면 신규(매퍼로 새 JpaEntity 생성), id가 있으면 기존(`findById` 후 `applySnapshot`). `Persistable`/`isNew()` 미사용. `JpaRepository.save()` 한 번 호출로 INSERT/UPDATE 통합
- **Rationale**: 신규/기존 분기를 어댑터에서 명시적으로 처리. JPA의 Dirty Checking을 활용해 update 흐름을 단순화.
- **Reference**: §4.4

### F-08. 외부 응답 모델은 어댑터를 벗어나지 않는다
- **Severity**: MUST
- **Scope**: `**/infrastructure/adapter/external/**/*.java`
- **Check**: 외부 API 응답 DTO가 `application/**`, `domain/**`에 노출 0건
- **Rationale**: 외부 변경 격리.
- **Reference**: §4.4

---

## G. 테스트

### G-01. 도메인에 단위 테스트가 있다
- **Severity**: MUST
- **Scope**: `**/domain/**/*.java` ↔ `**/test/**/domain/**/*Test.java`
- **Check**: 각 도메인 클래스에 대응하는 `*Test.java` 존재
- **Rationale**: 비즈니스 규칙 보호.
- **Reference**: §7.1

### G-02. ApplicationService에 단위 테스트가 있다
- **Severity**: MUST
- **Scope**: `**/application/service/**` ↔ 대응 테스트
- **Check**: 각 `*Service`에 대응하는 `*ServiceTest.java` 존재
- **Rationale**: 유스케이스 오케스트레이션 검증.
- **Reference**: §7.1

### G-03. 컨트롤러에 MVC 테스트가 있다
- **Severity**: MUST
- **Scope**: `*Controller` ↔ 대응 테스트
- **Check**: `@WebMvcTest` 사용 (`@SpringBootTest` 금지)
- **Rationale**: HTTP 계약 검증, 빠른 슬라이스 유지.
- **Reference**: §7.1

### G-04. 한국어 @DisplayName이 있다
- **Severity**: MUST
- **Scope**: `**/test/**/*Test.java`
- **Check**: 테스트 클래스/`@Test` 메서드/`@Nested` 클래스에 한국어 `@DisplayName` (값에 한글 포함)
- **Rationale**: 살아있는 문서를 위한 도메인 언어.
- **Reference**: §7.2

### G-05. @Nested로 시나리오를 그룹화한다
- **Severity**: SHOULD
- **Scope**: `**/test/**/*Test.java`
- **Check**: 테스트 메서드 2개 이상이면 `@Nested` 그룹화
- **Rationale**: 시나리오 계층 가독성.
- **Reference**: §7.2

### G-06. Given-When-Then 단계 구분
- **Severity**: SHOULD
- **Scope**: `**/test/**/*Test.java`
- **Check**: 각 `@Test` 본문에 `// given`, `// when`, `// then` 주석(또는 동등한 분리)
- **Rationale**: 테스트가 행동 명세서로 읽히도록.
- **Reference**: §7.2

### G-07. 단위 테스트에 @SpringBootTest 금지
- **Severity**: MUST
- **Scope**: `**/test/**/domain/**/*Test.java`, `**/test/**/application/service/**/*Test.java`
- **Check**: `@SpringBootTest` 0건
- **Rationale**: 컨텍스트 로딩이 단위 테스트 속도/격리를 해친다.
- **Reference**: §7.2

### G-08. SUT 메서드명을 그대로 포함하는 테스트명 금지
- **Severity**: SHOULD
- **Scope**: `**/test/**/*Test.java`
- **Check**: 메서드명이 `[Method]_[Scenario]_[Result]` 패턴이거나 SUT 메서드명을 그대로 포함하지 않음
- **Rationale**: 테스트는 코드가 아닌 행동을 검증.
- **Reference**: §7.2

---

## 보고 형식

```
[VIOLATION] B-01 (MUST) — src/main/java/.../User.java:42
  Setter found: public void setEmail(String email)
  Rationale: 의도적 변경(Tell, Don't Ask) 강제.
  Reference: ARCHITECTURE.md §4.1
  Suggestion: 행위 메서드(예: changeEmail(NewEmail))로 대체.
```

MUST → 차단, SHOULD → 경고, MAY → 자유 선택(검증 안 함, 일관성 점검만 권장), CONDITIONAL → 조건이 충족될 때만 적용.
