# ARCHITECTURE.md

> Spring Java 웹 애플리케이션 · 헥사고날(Ports & Adapters) + 도메인 모델 패턴 · 단일 모듈 · TDD/BDD

이 아키텍처의 목적은 **가독성과 유지보수성**이다. 규칙이 이 목적을 해친다면 목적을 우선하고 PR에 사유를 명시한다. 코드 생성 후 `ARCHITECTURE_CHECKLIST.md`로 self-review.

---

## 1. 패키지 구조

```
com.example.app
├── controller                    # 인바운드 어댑터 (REST)
│   └── dto
│       ├── request               # toCommand()/toQuery() 메서드 보유
│       └── response              # from(Result) 정적 팩토리 보유
├── listener                      # 인바운드 어댑터 (메시지)
├── application
│   ├── usecase                   # 유스케이스 인터페이스 (선택적, §2.4 참고)
│   ├── service                   # ApplicationService — 기본 구현
│   └── dto                       # Command / Query / Result
├── domain                        # 외부 의존성 0
│   ├── model                     # 도메인 엔티티 (POJO) + Snapshot record
│   ├── repository                # 도메인 인터페이스 (DDD Repository, JPA Repository 아님)
│   └── service
└── infrastructure
    └── adapter
        ├── persistence           # JpaEntity / JpaRepository / PersistenceAdapter / Mapper
        └── external              # HTTP Client 등
```

의존성 방향: `controller`/`listener` → `application` → `domain` ← `infrastructure/adapter`

---

## 2. 규칙 (반드시 따를 것)

### 2.1 도메인은 100% 순수 POJO + Snapshot 양방향 패턴
- 도메인 엔티티에 JPA/Spring/Lombok/Jackson/Validation 어노테이션 **일체 금지**
- **Setter 금지**
- **Getter는 지양** — 무분별한 일괄 노출은 피하고, 외부 표시(컨트롤러 응답 등)에 정말 필요한 것만 노출
- 비즈니스 규칙은 도메인 엔티티 안에 둔다 (ApplicationService에 누적 금지)
- **영속성 매핑은 Snapshot record 양방향 패턴을 사용한다**:
  - `XxxSnapshot` record: 같은 패키지에 위치. 영속성 복원에 필요한 모든 필드를 묶음
  - `User.toSnapshot()` (도메인 → Snapshot): 매퍼·영속성 어댑터가 도메인 내부를 읽는 **유일한 통로**
  - `User.reconstitute(UserSnapshot s)` (Snapshot → 도메인): 영속성에서 도메인 객체 복원
  - 양방향 대칭 덕분에 도메인은 Lombok 없이 강한 캡슐화를 유지하고, 매퍼용 getter를 별도로 노출하지 않아도 된다
- **Snapshot의 활용 범위** — 영속성 매핑 외에도:
  - **도메인 객체 update 흐름**: `findById` → `toDomain` → 도메인 메서드로 상태 변경 → 영속 상태 JpaEntity의 `applySnapshot`으로 전체 반영 → JPA Dirty Checking이 실제 변경된 컬럼만 UPDATE
  - **변경 감지(diff)**: 변경 전·후 Snapshot을 비교해 어떤 필드가 바뀌었는지 산출
  - **이벤트 페이로드**: 도메인 이벤트 발행 시 Snapshot이 그대로 페이로드 역할

### 2.2 도메인 모델은 Aggregate 단위로 설계한다
- **Aggregate Root**가 도메인 모델의 단위. Aggregate 내부의 엔티티/값 객체는 Aggregate Root를 통해서만 외부에 접근된다
- **JPA Entity ↔ 도메인 모델은 1:1이 아닐 수 있다** — 1:N, N:1 모두 가능. 매퍼가 이 차이를 흡수
- **도메인 Repository는 Aggregate Root 단위로만 정의** — 내부 엔티티에 대한 Repository는 만들지 않는다
- 트랜잭션 일관성은 Aggregate 경계 안에서만 보장

### 2.3 도메인 Repository (Aggregate 단위)
- `domain.repository` 패키지의 인터페이스
- **Aggregate Root 단위**로만 정의 (예: `OrderRepository` ✓, `OrderLineRepository` ✗)
- 메서드 시그니처는 **도메인 모델만 입출력** (JpaEntity/DTO 노출 금지)
- 클래스명 `XxxRepository`, JPA Repository와 다른 개념

### 2.4 ApplicationService와 인터페이스 추상화 (선택적)

**기본형 — 인터페이스 없이 ApplicationService 클래스로 시작한다**
- 클래스명은 동사구 + `Service` (예: `RegisterUserService`)
- `@Service` + 생성자 주입
- 입출력은 항상 `XxxCommand`/`XxxQuery`/`XxxResult` (원시 타입 나열 금지)
- `@Transactional`은 ApplicationService에만
- 컨트롤러는 ApplicationService에 직접 의존
- 얇은 오케스트레이터: Repository 호출 → 도메인 메서드 호출 → Result 변환
- **`save()`의 반환값을 항상 사용한다** — 신규 생성 시 도메인의 id/createdAt 등이 DB에서 채워지므로 입력 객체를 그대로 쓰면 안 된다

**인터페이스를 도입할 시점 — 주로 다중 구현이 필요할 때**
- 결제 게이트웨이별 구현, 알림 채널별 구현, 정책 분기 등
- 인터페이스 명명은 **역할을 표현하는 동사구** — `XxxUseCase`, `XxxPort` 같은 의미 없는 접미사를 붙이지 않는다
- 구현체 명명:
  - 다중 구현: 변별 형용사 + 인터페이스명 (예: `TossProcessPayment`, `KakaoProcessPayment`)
  - 단일 구현에서 인터페이스 추출: `DefaultXxx` (예: `DefaultRegisterUser`)
- 컨트롤러는 인터페이스에 의존, Spring이 `@Qualifier`나 조건부 빈 등으로 분기

### 2.5 컨트롤러 DTO 변환 위치
- Request DTO에 `toCommand()`/`toQuery()` 인스턴스 메서드
- Response DTO에 `from(Result)` 정적 팩토리
- 컨트롤러 메서드 본문에 변환 로직을 두지 않는다

### 2.6 영속성 ↔ 도메인 매핑
- JPA Entity 클래스명 `XxxJpaEntity`, `infrastructure/adapter/persistence`에 위치
- id는 `Long`, JPA `IDENTITY` 자동발급. 도메인의 id는 nullable — 신규 직후 null, save 후 채워짐
- `XxxPersistenceAdapter`(패키지-프라이빗)가 도메인 Repository(Aggregate Root 단위)를 구현
- 변환은 **수동 Mapper**에 위임 — **MapStruct/ModelMapper 사용 금지**
- Mapper는 **JPA Entity 묶음 ↔ Aggregate** 변환 — 1:N인 경우 여러 JpaEntity를 모아 하나의 Aggregate로 조립
- Mapper 메서드 시그니처: 단순 1:1이면 `toJpaEntity(domain)` / `toDomain(jpaEntity)`. 1:N인 경우 `toJpaEntities(aggregate)` / `toDomain(rootEntity, childEntities)`
- Mapper에 비즈니스 로직 금지
- **`applySnapshot`은 JpaEntity의 메서드** — 영속 상태 JpaEntity가 자기 상태를 도메인 Snapshot으로 갱신
- **save 흐름**: PersistenceAdapter의 `save`는 Snapshot의 id가 null이면 신규(매퍼로 새 JpaEntity 생성) / id가 있으면 기존(`findById` 후 `applySnapshot`). `JpaRepository.save()` 한 번 호출로 통일. `Persistable`/`isNew()` 미사용
- **외부 응답 DTO는 어댑터를 벗어나지 않는다** — `infrastructure/adapter/external`의 외부 API 응답 DTO를 `application/`이나 `domain/`에서 직접 사용하지 않는다

### 2.7 테스트 (BDD 한국어 스타일)
- **필수**: 도메인 엔티티/도메인 서비스, ApplicationService, 컨트롤러(`@WebMvcTest`)
- **옵셔널**: `@DataJpaTest`, `@SpringBootTest`, ArchUnit, Fake Adapter
- 모든 테스트 클래스/메서드/`@Nested`에 **한국어 `@DisplayName`**
- `@Nested` 그룹화 (외부=대상/메서드, 내부=조건/상황)
- `// given` / `// when` / `// then` 주석으로 단계 구분
- 테스트명은 **사실(평서문) 한국어** ("회원가입 시 이메일이 중복되면 예외가 발생한다") — `[Method]_[Scenario]_[Result]` 패턴 금지
- 단위 테스트에 `@SpringBootTest` 금지
- Fixture 클래스 분리

---

## 3. 핵심 코드 예시

### 3.1 도메인 엔티티 — Snapshot 양방향 패턴 (DB 발급 id)

```java
package com.example.app.domain.model;

public final class User {
    private final Long id;        // null = 신규(아직 DB 발급 전), non-null = 영속화됨
    private final String email;
    private String passwordHash;
    private final Instant createdAt;   // null 가능 — JPA Auditing 도입 시 DB가 채움 (선택)

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
    // passwordHash는 getter 노출하지 않음 — 매퍼는 toSnapshot()으로 접근
}

/** 영속성 복원·노출 통로 — 같은 패키지 */
public record UserSnapshot(Long id, String email, String passwordHash, Instant createdAt) {}
```

### 3.2 ApplicationService — save 반환값 사용

```java
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

// 컨트롤러는 ApplicationService에 직접 의존
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final RegisterUserService registerUserService;

    @PostMapping
    public ResponseEntity<UserResponse> register(@RequestBody @Valid RegisterUserRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(UserResponse.from(registerUserService.register(req.toCommand())));
    }
}
```

### 3.3 인터페이스 도입 — 두 가지 형태

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
// Before: class RegisterUserService { ... }
// After:
public interface RegisterUser {
    RegisterUserResult register(RegisterUserCommand command);
}

@Service @Transactional
public class DefaultRegisterUser implements RegisterUser { /* ... */ }
```

### 3.4 DTO 변환

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

### 3.5 JPA Entity + Mapper + PersistenceAdapter (단순 1:1)

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

    /** 신규 생성용 — id/createdAt은 JPA가 채움 (createdAt은 @PrePersist 또는 @CreatedDate 도입 시) */
    public UserJpaEntity(String email, String password) {
        this.email = email;
        this.password = password;
    }

    /** 영속 상태에서 호출 — 도메인 Snapshot의 변경 가능 필드만 자기 상태에 반영 */
    public void applySnapshot(UserSnapshot s) {
        this.email = s.email();
        this.password = s.passwordHash();
        // id, createdAt은 변경하지 않음
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

    /** 신규/기존 분기는 Snapshot의 id로 판단 — JpaRepository.save() 한 번으로 INSERT/UPDATE 처리 */
    @Override public User save(User user) {
        UserSnapshot s = user.toSnapshot();
        UserJpaEntity entity = (s.id() == null)
            ? mapper.toJpaEntity(user)                    // 신규: 새 JpaEntity → INSERT
            : jpaRepository.findById(s.id())              // 기존: 영속 상태에 applySnapshot → Dirty Checking으로 UPDATE
                .map(managed -> { managed.applySnapshot(s); return managed; })
                .orElseThrow(() -> new IllegalStateException("id is given but not found: " + s.id()));
        return mapper.toDomain(jpaRepository.save(entity));
    }
}
```

> `@CreatedDate`(Spring Data JPA Auditing) 도입은 선택적. 도입하면 `@PrePersist` 콜백 대신 자동으로 채워진다.

### 3.6 Aggregate 매핑 — JPA Entity와 1:N인 경우

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

// 매퍼는 변환만 담당. applySnapshot은 JpaEntity의 책임
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
            lines.stream().map(l -> new OrderLineSnapshot(
                l.getId(), l.getSku(), l.getQty(), l.getPrice())).toList()
        ));
    }
}
public record OrderJpaEntities(OrderJpaEntity root, List<OrderLineJpaEntity> lines) {}

// PersistenceAdapter는 Aggregate Root 단위 Repository만 구현
// 신규/기존 분기 + 자식 엔티티의 신규/기존 처리도 함께
@Component
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

### 3.7 BDD 한국어 테스트

```java
@DisplayName("RegisterUserService")
class RegisterUserServiceTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final RegisterUserService sut = new RegisterUserService(userRepository, /*...*/);

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
    }
}
```

---

*가독성과 유지보수성이 모든 규칙의 최종 판단 기준이다.*
