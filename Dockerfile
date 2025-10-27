# 1단계: 'builder' 스테이지
# Java 17 JDK 이미지를 사용하여 프로젝트를 빌드합니다.
FROM eclipse-temurin:17-jdk-jammy AS builder

# 작업 디렉토리 설정
WORKDIR /app

# Gradle 관련 파일들을 먼저 복사합니다.
# (의존성이 변경되지 않았다면 이 레이어를 캐시에서 재사용)
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle .
COPY settings.gradle .

# (선택적) 의존성만 먼저 다운로드하여 레이어 캐시 활용
# RUN ./gradlew dependencies

# 소스 코드 전체 복사
COPY src ./src

# gradlew에 실행 권한 부여
RUN chmod +x ./gradlew

# CI/CD 파이프라인에서는 테스트를 별도 단계로 빼므로,
# Docker 빌드 시에는 테스트를 스킵하여 빌드 속도를 높입니다.
RUN ./gradlew build -x test

# 2단계: 'runner' 스테이지
# 실제 실행을 위한 JRE(Java Runtime Environment) 이미지를 사용합니다.
# JDK가 아닌 JRE를 사용하여 이미지 크기를 대폭 줄입니다.
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# README에서 8080 포트를 사용하므로 동일하게 설정
EXPOSE 8080

# builder 스테이지에서 빌드된 JAR 파일만 복사
# build/libs/ 안에 있는 .jar 파일을 app.jar 라는 이름으로 복사합니다.
COPY --from=builder /app/build/libs/*.jar app.jar

# 컨테이너가 시작될 때 app.jar 파일을 실행
ENTRYPOINT ["java", "-jar", "app.jar"]
