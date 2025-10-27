# Build stage
FROM gradle:8.5.0-jdk17 AS builder
WORKDIR /home/gradle/src

# 의존성 캐시를 위해 먼저 복사
COPY --chown=gradle:gradle build.gradle settings.gradle ./
COPY --chown=gradle:gradle gradle ./gradle
RUN gradle dependencies --no-daemon

# 소스 복사 및 빌드
COPY --chown=gradle:gradle src ./src
RUN gradle bootJar --no-daemon

# Runtime stage
FROM eclipse-temurin:17-jre-jammy
ENV TZ=Asia/Seoul
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 비root 사용자
RUN groupadd -r spring && useradd -r -g spring spring
WORKDIR /app
USER spring:spring

COPY --from=builder --chown=spring:spring /home/gradle/src/build/libs/*.jar app.jar

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
