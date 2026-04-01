# Spring/Java Domain Guide

## Project Structure Patterns
- `src/main/java/` — application source code
- `src/test/java/` — test code (JUnit 5, Mockito)
- `src/main/resources/` — configuration files
  - `application.yml` / `application.properties` — Spring Boot config
  - `application-{profile}.yml` — profile-specific config (dev, prod, test)
- `build.gradle` / `build.gradle.kts` — Gradle build (Groovy or Kotlin DSL)
- `pom.xml` — Maven build
- `docker-compose.yml` — local development infrastructure

## Build and Test Commands

**Gradle:**
- Build: `./gradlew build`
- Test: `./gradlew test`
- Specific test: `./gradlew test --tests "com.example.MyTest"`
- Clean: `./gradlew clean`
- Boot run: `./gradlew bootRun`

**Maven:**
- Build: `./mvnw package`
- Test: `./mvnw test`
- Specific test: `./mvnw test -Dtest=MyTest`
- Clean: `./mvnw clean`
- Boot run: `./mvnw spring-boot:run`

## Common Step Patterns for Generated Skills

- **Build verification step**: Run build command, check exit code 0
- **Test step**: Run tests separately from build, report failures clearly
- **Config change step**: When modifying application.yml, verify active profile and check for profile-specific overrides
- **Entity/Repository step**: After creating JPA entity, generate repository interface and verify schema migration
- **API endpoint step**: After creating controller, verify with curl/httpie and check response format
- **Batch job step**: Verify job configuration, step definitions, reader/processor/writer chain

## Recommended allowed-tools

```yaml
allowed-tools:
  - Bash(./gradlew:*)    # or Bash(./mvnw:*)
  - Bash(curl:*)         # API testing
  - Read
  - Edit
  - Write
  - Grep
  - Glob
```

## Common Pitfalls

- Spring Boot version differences: Boot 2.x vs 3.x have breaking changes (javax → jakarta namespace)
- `@Configuration` class changes may require context reload for testing
- Circular dependency issues with `@Autowired` — prefer constructor injection
- Profile-specific configs can silently override base config
- Flyway/Liquibase migrations are ordered — never modify existing migration files, always create new ones
- Lombok annotations need annotation processing enabled in IDE and build tool
