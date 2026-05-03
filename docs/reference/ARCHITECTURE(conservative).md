# ARCHITECTURE.md

> Spring 기반 Java 웹 애플리케이션 · 헥사고날(Ports & Adapters) + 도메인 모델 패턴 · 단일 모듈 · TDD/BDD

## 1. 목적

이 아키텍처의 **궁극적 목적은 가독성과 유지보수성**이다.
- **읽기 쉬운 코드** — 비즈니스 의도가 도메인 코드만 봐도 드러난다.
- **고치기 쉬운 코드** — 프레임워크/DB/외부 API 교체가 도메인을 오염시키지 않는다.
- **살아있는 문서** — 테스트 코드가 시스템의 행동 명세서 역할을 한다.

규칙이 이 목적을 해친다면, 규칙보다 목적을 우선해 판단하고 그 이유를 PR에 명시한다. 코드 생성 후에는 `ARCHITECTURE_CHECKLIST.md`로 self-review를 수행한다.

---

## 2. 핵심 원칙

1. 의존성은 항상 안쪽으로 향한다:
   - `controller`/`listener` → `application` → `domain`
   - `infrastructure/adapter` → `domain` (도메인 인터페이스 구현)
   - `domain`은 어떤 레이어에도 의존하지 않는다 (Spring/JPA/Jackson 의존성 0).
2. **도메인 인터페이스는 도메인 패키지에**, 그 구현체(어댑터)는 인프라스트럭처에 둔다.
3. **유스케이스는 ApplicationService 클래스로 구현**한다. 인터페이스 추상화는 다중 구현 등 필요할 때만 도입.
4. **도메인 모델은 Aggregate 단위로 설계**한다. JPA Entity와는 1:1이 아닐 수 있으며(1:N/N:1 가능), 도메인 Repository는 **Aggregate Root 단위**로만 정의한다.
5. **도메인 엔티티와 영속성 엔티티는 분리**하고, 어댑터에서 **수동 매퍼**로 변환한다 (매퍼가 Aggregate 경계를 흡수).

---

## 3. 패키지 구조

```
com.example.app
├── controller                    # 인바운드 어댑터 (REST)
│   └── dto
│       ├── request               # Request DTO + toCommand()/toQuery()
│       └── response              # Response DTO + from(Result)
├── listener                      # 인바운드 어댑터 (메시지 큐 등)
├── application
│   ├── usecase                   # 유스케이스 인터페이스 (선택적)
│   ├── service                   # ApplicationService — 기본 구현
│   └── dto                       # Command / Query / Result
├── domain                        # 외부 의존성 0
│   ├── model                     # 도메인 엔티티 (POJO) + Snapshot record
│   ├── repository                # 도메인 인터페이스 — Aggregate Root 생명주기
│   └── service                   # 도메인 서비스 (선택)
└── infrastructure
    └── adapter
        ├── persistence           # JPA Entity / Repository / Mapper
        └── external              # HTTP Client / 외부 API
```

> `domain.repository`는 도메인 객체의 **생명주기**를 표현하는 도메인 인터페이스(DDD Repository)이다. 영속성 어댑터에서 이를 구현하면서 내부적으로 Spring Data `JpaRepository`를 사용한다.

---

## 4. 레이어별 규칙

### 4.1 Domain

**Aggregate**
- ✅ 도메인 모델은 **Aggregate 단위로 설계**. Aggregate Root가 외부 접근의 유일한 진입점이며, 내부 엔티티/값 객체는 Root를 통해서만 접근
- ✅ JPA Entity와 도메인 모델은 **1:1이 아닐 수 있다** — 1:N, N:1 모두 가능. 매퍼가 흡수
- ✅ 트랜잭션 일관성은 Aggregate 경계 안에서만 보장

**도메인 엔티티 (POJO)**
- ✅ 순수 POJO. JPA/Spring/Lombok/Jackson/Validation 어노테이션 일체 금지
- ✅ Setter 금지
- ✅ Getter는 **지양** — 외부 표시(컨트롤러 응답 등)에 정말 필요한 것만 노출
- ✅ 비즈니스 규칙은 엔티티 내부에 둔다
- ✅ **영속성 매핑은 Snapshot record 양방향 패턴**:
  - `XxxSnapshot` record — 같은 패키지에 위치
  - `User.toSnapshot()` — 매퍼·영속성 어댑터가 도메인 내부를 읽는 **유일한 통로**
  - `User.reconstitute(UserSnapshot s)` — 영속성에서 도메인 객체 복원
  - 양방향 대칭 덕분에 도메인은 Lombok 없이 강한 캡슐화를 유지하고, 매퍼용 getter를 별도로 노출하지 않아도 된다
- ✅ **Snapshot의 활용 범위** — 영속성 매핑 외에:
  - **도메인 객체 update 흐름**: `findById` → `toDomain` → 도메인 메서드 → 영속 상태 JpaEntity의 `applySnapshot` → JPA Dirty Checking으로 변경 컬럼만 UPDATE
  - **변경 감지(diff)**: 변경 전·후 Snapshot 비교로 어떤 필드가 바뀌었는지 산출
  - **이벤트 페이로드**: 도메인 이벤트 페이로드 역할

**도메인 Repository**
- ✅ `domain.repository`에 인터페이스로, 이름은 `XxxRepository`
- ✅ **Aggregate Root 단위로만 정의** — Aggregate 내부 엔티티에 대한 Repository는 만들지 않는다 (예: `OrderRepository` ✓ / `OrderLineRepository` ✗)
- ✅ 메서드 시그니처는 도메인 모델만 입출력 (JPA Entity/DTO 노출 금지)

### 4.2 Application

**ApplicationService**
- ✅ 클래스명은 동사구 + `Service` (`RegisterUserService`, `SendMoneyService`), `@Service` + 생성자 주입
- ✅ `@Transactional` 경계는 여기에만
- ✅ 입출력은 `XxxCommand`(쓰기) / `XxxQuery`(읽기) / `XxxResult` — 원시 타입 나열 금지
- ✅ 얇은 오케스트레이터: Repository 호출 → 도메인 메서드 호출 → Result 변환
- ✅ 컨트롤러는 ApplicationService 클래스에 직접 의존 (인터페이스 없이도 무방)
- ✅ **신규 저장 시 `save()`의 반환값을 사용한다** — 입력 객체는 id/createdAt이 비어있으므로 그대로 사용 금지
- ❌ 비즈니스 규칙 작성 금지 (도메인으로 이동)

**인터페이스 추상화 (선택적)**
- 인터페이스 도입은 **필수가 아니다**. 주된 도입 시점은 다중 구현이 필요할 때 (결제 게이트웨이, 알림 채널, 정책 분기 등)
- 인터페이스 명명은 **역할을 표현하는 동사구** — `XxxUseCase`, `XxxPort` 같은 의미 없는 접미사를 붙이지 않는다
  - ✓ `ProcessPayment`, `SendNotification`, `RegisterUser`
  - ✗ `ProcessPaymentUseCase`, `RegisterUserPort`
- 구현체 명명:
  - **다중 구현**: 변별 형용사 + 인터페이스명 (예: `TossProcessPayment`, `KakaoProcessPayment`)
  - **단일 구현에서 인터페이스 추출**: 구현체는 `DefaultXxx`로 리네임 (예: `DefaultRegisterUser`)

### 4.3 Inbound Adapter

**Controller**
- ✅ `@RestController` + ApplicationService 클래스(또는 인터페이스가 도입된 경우 해당 인터페이스)에 의존
- ✅ HTTP 매핑, 입력 검증, DTO ↔ Command/Result 변환, 예외 변환만 담당
- ✅ 하나의 유스케이스(또는 긴밀히 묶인 소수)만 담당
- ❌ Repository, JPA Entity, 도메인 엔티티 직접 참조 금지

**Listener** — 컨트롤러와 동일 원칙. 메시지 → Command 변환 후 호출.

### 4.4 Outbound Adapter

**JPA Entity**
- `infrastructure/adapter/persistence`에 위치, 클래스명 `XxxJpaEntity`
- id는 `Long`, JPA `IDENTITY` 자동발급. 도메인의 id는 nullable — 신규 직후 null, save 후 채움
- ✅ **`applySnapshot(XxxSnapshot)` 메서드를 제공**한다 — 영속 상태 객체가 도메인 Snapshot으로 자기 변경 가능 필드만 갱신. id, createdAt 같은 불변 필드는 갱신하지 않음

**Persistence Adapter**
- `XxxPersistenceAdapter`(패키지-프라이빗), 도메인 Repository(Aggregate Root 단위) 구현, 내부적으로 `JpaRepository<XxxJpaEntity, Long>` 의존(여러 개일 수 있음), 변환은 Mapper에 위임
- ✅ **`save` 흐름**: Snapshot의 id가 null이면 신규(매퍼로 새 JpaEntity 생성) / id가 있으면 기존(`findById` 후 `applySnapshot`). `JpaRepository.save()` 한 번 호출로 INSERT/UPDATE 통합. `Persistable`/`isNew()` 미사용

**Mapper (수동, 변환 책임만)**
- ✅ MapStruct/ModelMapper **금지** — 1:N/N:1 매핑·필드명 차이가 있어 명시적 매핑 필요
- ✅ Mapper는 **JPA Entity 묶음 ↔ Aggregate** 변환 — 1:N인 경우 여러 JpaEntity를 모아 하나의 Aggregate로 조립
- ✅ 메서드 시그니처: 단순 1:1이면 `toJpaEntity(domain)` / `toDomain(jpaEntity)`. 1:N인 경우 `toJpaEntities(aggregate)` / `toDomain(rootEntity, childEntities)`
- ❌ 비즈니스 로직 금지. `applySnapshot`도 매퍼에 두지 않는다 (JpaEntity의 책임)

**External Adapter**
- ✅ 외부 응답 DTO는 어댑터를 벗어나지 않는다 — `application/`이나 `domain/`에서 직접 사용 금지

---

## 5. DTO 변환

```
Request DTO → toCommand() → Command → ApplicationService → Result → from(Result) → Response DTO
```

- Request DTO에 `toCommand()` 인스턴스 메서드, Response DTO에 `from(Result)` 정적 팩토리
- 컨트롤러 메서드에 변환 로직을 두지 않는다

```java
public record RegisterUserRequest(@NotBlank String email, @NotBlank String password) {
    public RegisterUserCommand toCommand() {
        return new RegisterUserCommand(email, password);
    }
}

public record UserResponse(Long id, String email, Instant createdAt) {
    public static UserResponse from(RegisterUserResult r) {
        return new UserResponse(r.userId(), r.email(), r.createdAt());
    }
}
```

---

## 6. 코드 예시

### 6.1 도메인 엔티티 — Snapshot 양방향 패턴 (DB 발급 id)

```java
package com.example.app.domain.model;

public final class User {
    private final Long id;        // null = 신규(아직 DB 발급 전), non-null = 영속화됨
    private final String email;
    private String passwordHash;
    private final Instant createdAt;   // null 가능 — DB가 채움

    private User(Long id, String email, String passwordHash, Instant createdAt) {
        this.id = id;   // nullable
        this.email = Objects.requireNonNull(email);
        this.passwordHash = Objects.requireNonNull(passwordHash);
        this.createdAt = createdAt;   // nullable
    }

    /** 신규 가입 — id, createdAt은 DB가 채움 */
    public static User register(String email, String rawPassword, PasswordEncoder encoder) {
        return new User(null, email, encoder.encode(rawPassword), null);
    }

    /** 영속성 복원 (Snapshot → 도메인) */
    public static User reconstitute(UserSnapshot s) {
        return new User(s.id(), s.email(), s.passwordHash(), s.createdAt());
    }

    /** 매퍼·영속성 어댑터용 노출 (도메인 → Snapshot) */
    public UserSnapshot toSnapshot() {
        return new UserSnapshot(id, email, passwordHash, createdAt);
    }

    // 행위 메서드 — Tell, Don't Ask
    public void changePassword(String current, String next, PasswordEncoder encoder) {
        if (!encoder.matches(current, this.passwordHash)) throw new InvalidPasswordException();
        this.passwordHash = encoder.encode(next);
    }

    // 외부 표시(컨트롤러 응답 등)에 정말 필요한 것만 최소 노출
    public Long id() { return id; }
    public String email() { return email; }
    public Instant createdAt() { return createdAt; }
    // passwordHash 같은 민감 필드는 getter 노출하지 않음 — 매퍼는 toSnapshot()으로 접근
}

/** 영속성 복원·노출 통로 — 같은 패키지 */
public record UserSnapshot(Long id, String email, String passwordHash, Instant createdAt) {}
```

### 6.2 ApplicationService — save 반환값 사용

```java
public record RegisterUserCommand(String email, String rawPassword) {}
public record RegisterUserResult(Long userId, String email, Instant createdAt) {
    public static RegisterUserResult from(User u) {
        return new RegisterUserResult(u.id(), u.email(), u.createdAt());
    }
}

@Service
@Transactional
@RequiredArgsConstructor
public class RegisterUserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public RegisterUserResult register(RegisterUserCommand cmd) {
        userRepository.findByEmail(cmd.email()).ifPresent(u -> {
            throw new EmailAlreadyExistsException(cmd.email());
        });
        User user = User.register(cmd.email(), cmd.rawPassword(), passwordEncoder);
        User saved = userRepository.save(user);   // 반환값 사용 — id/createdAt이 채워진 상태
        return RegisterUserResult.from(saved);
    }
}
```

### 6.3 인터페이스 도입 — 두 가지 형태

```java
// (a) 다중 구현 — 변별 형용사로 자연스럽게 갈라짐
public interface ProcessPayment {
    ProcessPaymentResult process(ProcessPaymentCommand command);
}

@Service @Transactional
public class TossProcessPayment implements ProcessPayment { /* ... */ }

@Service @Transactional
public class KakaoProcessPayment implements ProcessPayment { /* ... */ }


// (b) 단일 구현에서 인터페이스 추출 — 구현체는 Default*로 리네임
public interface RegisterUser {
    RegisterUserResult register(RegisterUserCommand command);
}

@Service @Transactional
public class DefaultRegisterUser implements RegisterUser { /* ... */ }
```

### 6.4 JPA Entity + Mapper + PersistenceAdapter (단순 1:1)

```java
@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true) private String email;
    @Column(nullable = false) private String password;
    @Column(nullable = false, updatable = false) private Instant createdAt;

    /** 신규 생성용 — id/createdAt은 JPA가 채움 */
    public UserJpaEntity(String email, String password) {
        this.email = email;
        this.password = password;
    }

    /** 영속 상태에서 호출 — 도메인 Snapshot의 변경 가능 필드만 자기 상태에 반영 */
    public void applySnapshot(UserSnapshot s) {
        this.email = s.email();
        this.password = s.passwordHash();
        // id, createdAt 같은 불변 필드는 변경하지 않음
    }

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = Instant.now();   // @CreatedDate 도입 전 임시 처리
    }
}

@Component
public class UserPersistenceMapper {
    /** 신규 저장용: id 없는 JpaEntity 생성 */
    public UserJpaEntity toJpaEntity(User user) {
        UserSnapshot s = user.toSnapshot();
        return new UserJpaEntity(s.email(), s.passwordHash());
    }

    public User toDomain(UserJpaEntity e) {
        return User.reconstitute(new UserSnapshot(
            e.getId(), e.getEmail(), e.getPassword(), e.getCreatedAt()));
    }
}

@Component
@RequiredArgsConstructor
class UserPersistenceAdapter implements UserRepository {
    private final UserJpaRepository jpaRepository;
    private final UserPersistenceMapper mapper;

    @Override public Optional<User> findByEmail(String email) {
        return jpaRepository.findByEmail(email).map(mapper::toDomain);
    }

    /**
     * 신규/기존 분기는 Snapshot의 id로 판단.
     * - id == null: 새 JpaEntity 생성 → INSERT
     * - id != null: findById로 영속 상태 조회 → applySnapshot → Dirty Checking으로 UPDATE
     * JpaRepository.save() 한 번 호출로 통합 (Persistable/isNew() 미사용)
     */
    @Override public User save(User user) {
        UserSnapshot s = user.toSnapshot();
        UserJpaEntity entity = (s.id() == null)
            ? mapper.toJpaEntity(user)
            : jpaRepository.findById(s.id())
                .map(managed -> { managed.applySnapshot(s); return managed; })
                .orElseThrow(() -> new IllegalStateException("id is given but not found: " + s.id()));
        return mapper.toDomain(jpaRepository.save(entity));
    }

    @Override public void deleteById(Long id) {
        jpaRepository.deleteById(id);
    }
}
```

> `@CreatedDate`(Spring Data JPA Auditing) 도입은 선택. 도입하면 `@PrePersist` 콜백 대신 자동으로 채워진다.

### 6.5 Aggregate 매핑 — JPA Entity와 1:N인 경우

```java
// 도메인: Order Aggregate (Root: Order, 내부: OrderLine)
public final class Order {
    private final Long id;
    private final List<OrderLine> lines;
    // ...
    public static Order reconstitute(OrderSnapshot s) { /* ... */ }
    public OrderSnapshot toSnapshot() { /* Root + Lines를 OrderSnapshot으로 직렬화 */ }
}
public record OrderSnapshot(Long id, List<OrderLineSnapshot> lines, /* ... */) {}
public record OrderLineSnapshot(Long id, String sku, int quantity, long unitPrice) {}

// JPA: 두 개의 JpaEntity로 분리. 각 JpaEntity가 자기 applySnapshot 보유
@Entity public class OrderJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) Long id;
    public void applySnapshot(OrderSnapshot s) { /* 변경 가능 필드만 */ }
}
@Entity public class OrderLineJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) Long id;
    Long orderId;
    public void applySnapshot(OrderLineSnapshot s) { /* ... */ }
}

// 매퍼는 변환만 담당 — applySnapshot은 JpaEntity의 책임
@Component
public class OrderPersistenceMapper {
    public OrderJpaEntities toJpaEntities(Order order) {
        OrderSnapshot s = order.toSnapshot();
        OrderJpaEntity root = new OrderJpaEntity(/* s에서 변환 */);
        List<OrderLineJpaEntity> lines = s.lines().stream()
            .map(l -> new OrderLineJpaEntity(/* ... */)).toList();
        return new OrderJpaEntities(root, lines);
    }

    public Order toDomain(OrderJpaEntity root, List<OrderLineJpaEntity> lines) {
        return Order.reconstitute(new OrderSnapshot(
            root.getId(),
            lines.stream()
                .map(l -> new OrderLineSnapshot(l.getId(), l.getSku(), l.getQty(), l.getPrice()))
                .toList()
            // ...
        ));
    }
}
public record OrderJpaEntities(OrderJpaEntity root, List<OrderLineJpaEntity> lines) {}

// PersistenceAdapter는 Aggregate Root 단위 Repository만 구현
@Component
@RequiredArgsConstructor
class OrderPersistenceAdapter implements OrderRepository {
    private final OrderJpaRepository orderRepo;
    private final OrderLineJpaRepository lineRepo;
    private final OrderPersistenceMapper mapper;

    @Override public Optional<Order> findById(Long id) {
        return orderRepo.findById(id)
            .map(root -> mapper.toDomain(root, lineRepo.findByOrderId(id)));
    }
    // save: Aggregate 분해 → Root + Lines 각각 신규/기존 분기 처리 (트랜잭션 안에서)
}
```

---

## 7. 테스트

### 7.1 필수 vs 옵셔널

| 카테고리 | |
|---|---|
| 도메인 엔티티/도메인 서비스 단위 테스트 | **필수** |
| ApplicationService 단위 테스트 | **필수** |
| 컨트롤러 MVC 테스트 (`@WebMvcTest`) | **필수** |
| 영속성 어댑터 슬라이스 (`@DataJpaTest`) | 옵셔널 |
| 트랜잭션 통합 (`@SpringBootTest`) | 옵셔널 |
| ArchUnit / Fake Adapter | 옵셔널 |

### 7.2 BDD 스타일

- ✅ 모든 테스트 클래스/메서드에 한국어 `@DisplayName`
- ✅ `@Nested` 그룹화 — 외부: 대상/메서드, 내부: 조건/상황
- ✅ Given-When-Then — `// given`, `// when`, `// then` 주석
- ✅ Fixture 클래스 분리 (`UserFixture.aUser()`, `aUserWith(...)`)
- ✅ 테스트명은 사실(평서문) — "회원가입 시 이메일이 중복되면 예외가 발생한다"
- ❌ 단위 테스트에 `@SpringBootTest` 금지
- ❌ `[Method]_[Scenario]_[Result]` 패턴 금지

### 7.3 도메인 단위 테스트

```java
@DisplayName("User 도메인")
class UserTest {

    @Nested
    @DisplayName("changePassword 메서드는")
    class ChangePassword {

        @Test
        @DisplayName("현재 비밀번호가 일치하면 새 비밀번호로 변경된다")
        void changesPasswordWhenCurrentMatches() {
            // given
            PasswordEncoder encoder = new FakePasswordEncoder();
            User user = UserFixture.aUserWith(encoder, "old");
            // when
            user.changePassword("old", "new", encoder);
            // then
            assertThat(user.toSnapshot().passwordHash()).isEqualTo(encoder.encode("new"));
        }

        @Test
        @DisplayName("현재 비밀번호가 일치하지 않으면 예외가 발생한다")
        void throwsWhenCurrentMismatch() {
            User user = UserFixture.aUser();
            assertThatThrownBy(() ->
                user.changePassword("wrong", "new", new FakePasswordEncoder()))
                .isInstanceOf(InvalidPasswordException.class);
        }
    }
}
```

### 7.4 ApplicationService 단위 테스트

```java
@DisplayName("RegisterUserService")
class RegisterUserServiceTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final PasswordEncoder encoder = new FakePasswordEncoder();
    private final RegisterUserService sut = new RegisterUserService(userRepository, encoder);

    @Nested
    @DisplayName("회원가입 시")
    class Register {
        @Test
        @DisplayName("이메일이 중복되면 예외가 발생한다")
        void throwsWhenEmailDuplicated() {
            // given
            given(userRepository.findByEmail(any())).willReturn(Optional.of(UserFixture.aUser()));
            // when & then
            assertThatThrownBy(() -> sut.register(new RegisterUserCommand("a@a.com", "pw")))
                .isInstanceOf(EmailAlreadyExistsException.class);
            verify(userRepository, never()).save(any());
        }

        @Test
        @DisplayName("이메일이 중복되지 않으면 사용자가 저장되고 결과가 반환된다")
        void savesAndReturnsResult() {
            // given
            given(userRepository.findByEmail(any())).willReturn(Optional.empty());
            given(userRepository.save(any())).willAnswer(inv -> {
                User input = inv.getArgument(0);
                return User.reconstitute(new UserSnapshot(
                    1L, input.email(), input.toSnapshot().passwordHash(),
                    Instant.parse("2026-01-01T00:00:00Z")));
            });
            // when
            RegisterUserResult result = sut.register(new RegisterUserCommand("a@a.com", "pw"));
            // then
            assertThat(result.userId()).isEqualTo(1L);
            assertThat(result.email()).isEqualTo("a@a.com");
        }
    }
}
```

### 7.5 컨트롤러 MVC 테스트

```java
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired MockMvc mockMvc;
    @MockBean RegisterUserService registerUserService;
    @Autowired ObjectMapper om;

    @Test
    @DisplayName("POST /api/users — 정상 요청 시 201과 사용자 응답을 반환한다")
    void registerReturns201() throws Exception {
        given(registerUserService.register(any()))
            .willReturn(new RegisterUserResult(1L, "a@a.com",
                                               Instant.parse("2026-01-01T00:00:00Z")));

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(new RegisterUserRequest("a@a.com", "pw"))))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value(1));
    }
}
```

---

*가독성과 유지보수성이 모든 규칙의 최종 판단 기준이다.*
