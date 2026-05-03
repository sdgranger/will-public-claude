# ARCHITECTURE.md

> Spring 기반 Java 웹 애플리케이션 아키텍처 가이드라인
> 헥사고날(Ports & Adapters) + 도메인 모델 패턴 · 단일 모듈 · TDD/BDD

---

## 1. 목적

이 아키텍처의 **궁극적 목적은 가독성과 유지보수성**이다.

- **읽기 쉬운 코드** — 비즈니스 의도가 도메인 코드만 봐도 드러난다.
- **고치기 쉬운 코드** — 프레임워크/DB/외부 API 교체가 도메인을 오염시키지 않는다.
- **살아있는 문서** — 테스트 코드가 시스템의 행동 명세서 역할을 한다.

규칙이 이 목적을 해친다면, 규칙보다 목적을 우선해 판단하고 그 이유를 PR에 명시한다.

코드 생성 후에는 `ARCHITECTURE_CHECKLIST.md`로 self-review를 수행한다.

---

## 2. 핵심 원칙

1. 의존성은 항상 안쪽으로 향한다:
   - `controller`/`listener` → `application` → `domain`
   - `infrastructure/adapter` → `domain` (도메인 인터페이스 구현)
   - `domain`은 어떤 레이어에도 의존하지 않는다 (Spring/JPA/Jackson 의존성 0).
2. **도메인 인터페이스는 도메인 패키지에**, 그 구현체(어댑터)는 인프라스트럭처에 둔다.
3. **유스케이스는 인터페이스로 추상화**하고 ApplicationService가 구현한다.
4. **도메인 엔티티와 영속성 엔티티는 분리**하고, 어댑터에서 **수동 매퍼**로 변환한다.

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
│   ├── usecase                   # UseCase 인터페이스
│   ├── service                   # ApplicationService (UseCase 구현)
│   └── dto                       # Command / Query / Result
├── domain                        # 외부 의존성 0
│   ├── model                     # 도메인 엔티티 (POJO)
│   ├── repository                # 도메인 인터페이스 — 도메인 객체 생명주기 관리
│   └── service                   # 도메인 서비스 (선택)
└── infrastructure
    └── adapter                   # 도메인 인터페이스 구현체
        ├── persistence           # JPA Entity / Repository / Mapper
        └── external              # HTTP Client / 외부 API 등
```

> `domain.repository`는 도메인 객체의 **생명주기(생성·조회·저장·삭제)** 를 표현하는 도메인 인터페이스이다. JPA Repository가 아니라 DDD의 Repository 개념이며, 영속성 어댑터에서 이를 구현하면서 내부적으로 Spring Data `JpaRepository`를 사용한다.

---

## 4. 레이어별 규칙

### 4.1 Domain

**도메인 엔티티 (POJO)**
- ✅ 순수 POJO. JPA/Spring/Lombok/Jackson/Validation 어노테이션 일체 금지
- ✅ Setter 금지. Getter는 꼭 필요한 것만 노출
- ✅ 비즈니스 규칙은 엔티티 내부에 둔다 (Tell, Don't Ask)
- ✅ 정적 팩토리 메서드 권장 — 신규 생성(`User.register(...)`)과 영속성 복원(`User.reconstitute(...)`) 의도를 분리
- ✅ ID/식별자는 별도 값 객체로 표현 (예: `UserId`)

**Getter 지양 시 대안**
- 행위 메서드: `cart.addItem(item)` (○) vs `cart.getItems().add(item)` (✗)
- 외부 표시용은 도메인이 직접 스냅샷 반환: `user.toSnapshot()`
- 매퍼 전용 접근은 패키지-프라이빗 팩토리/접근자(예: 같은 패키지의 `UserInternals.reconstitute(...)`)

**도메인 Repository**
- ✅ `domain.repository`에 인터페이스로 정의
- ✅ 메서드 시그니처는 도메인 모델만 입출력 (JPA Entity/DTO 노출 금지)
- ✅ 이름은 `XxxRepository`, 메서드명은 도메인 의도에 맞게 (`findByEmail`, `save`, `deleteById`)

### 4.2 Application

**UseCase 인터페이스**
- ✅ 동사구 + `UseCase` (예: `RegisterUserUseCase`)
- ✅ 단일 메서드 권장
- ✅ 입력은 `XxxCommand`(쓰기) 또는 `XxxQuery`(읽기), 출력은 `XxxResult` — 원시 타입 나열 금지

**ApplicationService**
- ✅ `XxxService implements XxxUseCase`, `@Service` + 생성자 주입
- ✅ 트랜잭션 경계는 여기에 (`@Transactional`)
- ✅ 얇은 오케스트레이터: Repository 호출 → 도메인 메서드 호출 → Result 변환
- ❌ 비즈니스 규칙 작성 금지 (도메인으로 이동)

### 4.3 Inbound Adapter

**Controller**
- ✅ `@RestController` + UseCase 인터페이스만 의존
- ✅ HTTP 매핑, 입력 검증(`@Valid`), DTO ↔ Command/Result 변환, HTTP 상태/예외 변환만 담당
- ✅ 하나의 유스케이스(또는 긴밀히 묶인 소수)만 담당 — 작게 쪼갠다
- ❌ Repository, JPA Entity, 도메인 엔티티 직접 참조 금지

**Listener**
- ✅ 컨트롤러와 동일 원칙. 메시지 → Command 변환 후 UseCase 호출
- ✅ 멱등성/재시도 정책은 어댑터 레벨에서

### 4.4 Outbound Adapter

**JPA Entity** — `infrastructure/adapter/persistence`, 클래스명 `XxxJpaEntity`. 영속성 관심사(컬럼, 인덱스, FK)에만 집중.

**Persistence Adapter** — `XxxPersistenceAdapter` (패키지-프라이빗), 도메인 Repository 구현, 내부적으로 Spring Data `JpaRepository<XxxJpaEntity, ?>` 의존, 변환은 Mapper에 위임.

**Mapper (수동)**
- ✅ MapStruct/ModelMapper 금지 — 매핑은 도메인 의도가 들어가는 코드라 명시적이어야 함
- ✅ 메서드 시그니처: `toJpaEntity(domain)` / `toDomain(jpaEntity)`, 컬렉션은 별도 메서드
- ✅ 단방향이 충분하면 단방향만
- ✅ Null 처리: 빈 컬렉션은 `List.of()`로 반환 (null 금지)
- ✅ `@Component` 인스턴스 메서드 기본, 의존성 없으면 정적 메서드도 허용 (프로젝트 내 일관성 유지)
- ❌ 매퍼에 비즈니스 로직 금지

---

## 5. DTO 변환

```
Request DTO → toCommand() → Command → UseCase → Result → from(Result) → Response DTO
```

- Request DTO에 `toCommand()` 인스턴스 메서드
- Response DTO에 `from(Result)` 정적 팩토리 메서드
- 컨트롤러 메서드에는 변환 로직을 두지 않는다 — DTO에 위임

```java
public record RegisterUserRequest(@NotBlank String email, @NotBlank String password) {
    public RegisterUserCommand toCommand() {
        return new RegisterUserCommand(email, password);
    }
}

public record UserResponse(String id, String email, Instant createdAt) {
    public static UserResponse from(RegisterUserResult r) {
        return new UserResponse(r.userId(), r.email(), r.createdAt());
    }
}
```

---

## 6. 코드 예시

### 6.1 도메인 엔티티

```java
package com.example.app.domain.model;

public final class User {
    private final UserId id;
    private final Email email;
    private EncodedPassword password;
    private final Instant createdAt;

    // 영속성 복원용 — 패키지-프라이빗
    User(UserId id, Email email, EncodedPassword password, Instant createdAt) {
        this.id = Objects.requireNonNull(id);
        this.email = Objects.requireNonNull(email);
        this.password = Objects.requireNonNull(password);
        this.createdAt = Objects.requireNonNull(createdAt);
    }

    public static User register(Email email, RawPassword raw, PasswordEncoder encoder, Instant now) {
        return new User(UserId.newOne(), email, encoder.encode(raw), now);
    }

    public void changePassword(RawPassword current, RawPassword next, PasswordEncoder encoder) {
        if (!encoder.matches(current, this.password)) {
            throw new InvalidPasswordException();
        }
        this.password = encoder.encode(next);
    }

    public UserId id() { return id; }
    public Email email() { return email; }
    public Instant createdAt() { return createdAt; }
    // password getter는 노출하지 않는다.
}
```

### 6.2 도메인 Repository

```java
package com.example.app.domain.repository;

public interface UserRepository {
    Optional<User> findByEmail(Email email);
    Optional<User> findById(UserId id);
    User save(User user);
    void deleteById(UserId id);
}
```

### 6.3 UseCase + ApplicationService

```java
public interface RegisterUserUseCase {
    RegisterUserResult register(RegisterUserCommand command);
}

public record RegisterUserCommand(String email, String rawPassword) {}
public record RegisterUserResult(String userId, String email, Instant createdAt) {
    public static RegisterUserResult from(User u) {
        return new RegisterUserResult(u.id().value(), u.email().value(), u.createdAt());
    }
}

@Service
@Transactional
@RequiredArgsConstructor
public class RegisterUserService implements RegisterUserUseCase {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;

    @Override
    public RegisterUserResult register(RegisterUserCommand cmd) {
        Email email = new Email(cmd.email());
        userRepository.findByEmail(email).ifPresent(u -> {
            throw new EmailAlreadyExistsException(email);
        });
        User user = User.register(email, new RawPassword(cmd.rawPassword()),
                                  passwordEncoder, clock.instant());
        return RegisterUserResult.from(userRepository.save(user));
    }
}
```

### 6.4 Controller

```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final RegisterUserUseCase registerUserUseCase;

    @PostMapping
    public ResponseEntity<UserResponse> register(@RequestBody @Valid RegisterUserRequest req) {
        RegisterUserResult result = registerUserUseCase.register(req.toCommand());
        return ResponseEntity.status(HttpStatus.CREATED).body(UserResponse.from(result));
    }
}
```

### 6.5 JPA Entity + Persistence Adapter + Mapper

```java
@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserJpaEntity {
    @Id private String id;
    @Column(nullable = false, unique = true) private String email;
    @Column(nullable = false) private String password;
    @Column(nullable = false) private Instant createdAt;

    public UserJpaEntity(String id, String email, String password, Instant createdAt) {
        this.id = id; this.email = email; this.password = password; this.createdAt = createdAt;
    }
}

@Component
public class UserPersistenceMapper {
    public UserJpaEntity toJpaEntity(User user) {
        return new UserJpaEntity(
            user.id().value(),
            user.email().value(),
            UserInternals.passwordHashOf(user),
            user.createdAt());
    }
    public User toDomain(UserJpaEntity e) {
        return UserInternals.reconstitute(
            new UserId(e.getId()),
            new Email(e.getEmail()),
            new EncodedPassword(e.getPassword()),
            e.getCreatedAt());
    }
}

@Component
@RequiredArgsConstructor
class UserPersistenceAdapter implements UserRepository {
    private final UserJpaRepository jpaRepository;
    private final UserPersistenceMapper mapper;

    @Override public Optional<User> findByEmail(Email email) {
        return jpaRepository.findByEmail(email.value()).map(mapper::toDomain);
    }
    @Override public Optional<User> findById(UserId id) {
        return jpaRepository.findById(id.value()).map(mapper::toDomain);
    }
    @Override public User save(User user) {
        return mapper.toDomain(jpaRepository.save(mapper.toJpaEntity(user)));
    }
    @Override public void deleteById(UserId id) {
        jpaRepository.deleteById(id.value());
    }
}
```

---

## 7. 테스트

### 7.1 필수 vs 옵셔널

| 카테고리 | |
|---|---|
| 도메인 엔티티/도메인 서비스 단위 테스트 | **필수** |
| ApplicationService(UseCase) 단위 테스트 | **필수** |
| 컨트롤러 MVC 테스트 (`@WebMvcTest`) | **필수** |
| 영속성 어댑터 슬라이스 테스트 (`@DataJpaTest`) | 옵셔널 |
| 트랜잭션 통합 테스트 (`@SpringBootTest`) | 옵셔널 |
| ArchUnit 의존성 테스트 | 옵셔널 (권장) |
| Fake Adapter 인수 테스트 | 옵셔널 |

### 7.2 BDD 스타일 작성 규칙

- ✅ 모든 테스트 클래스/메서드에 한국어 `@DisplayName`
- ✅ `@Nested` 그룹화 — 외부: 대상/메서드, 내부: 조건/상황
- ✅ Given-When-Then 구조 — `// given`, `// when`, `// then` 주석으로 단계 구분
- ✅ Fixture 클래스 분리 (`UserFixture.aUser()`, `UserFixture.aUserWith(...)`)
- ✅ 테스트명은 사실(평서문) 형태 — "회원가입 시 이메일이 중복되면 예외가 발생한다"
- ❌ 단위 테스트에 `@SpringBootTest` 사용 금지
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
            User user = UserFixture.aUserWith(encoder, new RawPassword("old"));
            // when
            user.changePassword(new RawPassword("old"), new RawPassword("new"), encoder);
            // then
            assertThat(UserInternals.passwordHashOf(user))
                .isEqualTo(encoder.encode(new RawPassword("new")));
        }

        @Test
        @DisplayName("현재 비밀번호가 일치하지 않으면 예외가 발생한다")
        void throwsWhenCurrentMismatch() {
            User user = UserFixture.aUser();
            assertThatThrownBy(() ->
                user.changePassword(new RawPassword("wrong"), new RawPassword("new"),
                                    new FakePasswordEncoder()))
                .isInstanceOf(InvalidPasswordException.class);
        }
    }
}
```

### 7.4 유스케이스 단위 테스트

```java
@DisplayName("RegisterUserService")
class RegisterUserServiceTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final PasswordEncoder encoder = new FakePasswordEncoder();
    private final Clock clock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
    private final RegisterUserService sut =
        new RegisterUserService(userRepository, encoder, clock);

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
            given(userRepository.save(any())).willAnswer(inv -> inv.getArgument(0));
            // when
            RegisterUserResult result = sut.register(new RegisterUserCommand("a@a.com", "pw"));
            // then
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
    @MockBean RegisterUserUseCase registerUserUseCase;
    @Autowired ObjectMapper om;

    @Test
    @DisplayName("POST /api/users — 정상 요청 시 201과 사용자 응답을 반환한다")
    void registerReturns201() throws Exception {
        given(registerUserUseCase.register(any()))
            .willReturn(new RegisterUserResult("u-1", "a@a.com",
                                               Instant.parse("2026-01-01T00:00:00Z")));

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(new RegisterUserRequest("a@a.com", "pw"))))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value("u-1"))
            .andExpect(jsonPath("$.email").value("a@a.com"));
    }
}
```

### 7.6 Fixture

```java
public final class UserFixture {
    private UserFixture() {}
    public static User aUser() {
        return User.register(new Email("a@a.com"), new RawPassword("pw"),
                             new FakePasswordEncoder(), Instant.parse("2026-01-01T00:00:00Z"));
    }
    public static User aUserWith(PasswordEncoder encoder, RawPassword raw) {
        return User.register(new Email("a@a.com"), raw, encoder,
                             Instant.parse("2026-01-01T00:00:00Z"));
    }
}
```

### 7.7 옵셔널 — Fake Adapter & ArchUnit

**Fake Adapter** — 도메인 Repository의 인메모리 구현(`InMemoryUserRepository`)을 `src/test/java`에 두고, ApplicationService 인수 테스트에서 Mockito 대신 사용.

**ArchUnit**
```java
@AnalyzeClasses(packages = "com.example.app", importOptions = DoNotIncludeTests.class)
class ArchitectureTest {
    @ArchTest static final ArchRule domainHasNoOutwardDependency =
        noClasses().that().resideInAPackage("..domain..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "..application..", "..controller..", "..infrastructure..",
                "org.springframework..", "jakarta.persistence..", "com.fasterxml..");
}
```

---

*가독성과 유지보수성이 모든 규칙의 최종 판단 기준이다.*
