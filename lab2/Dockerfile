FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /build

COPY pom.xml .
RUN mvn --batch-mode dependency:go-offline

COPY src ./src
RUN mvn --batch-mode --no-transfer-progress clean package -DskipTests

FROM eclipse-temurin:21.0.8_9-jre-alpine

ENV APP_PORT=8080 \
    JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/urandom"

WORKDIR /app

RUN addgroup -S app && adduser -S app -G app
COPY --from=builder --chown=app:app /build/target/health-service-1.0.0.jar /app/app.jar

USER app
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD wget --quiet --output-document=/dev/null "http://127.0.0.1:${APP_PORT}/health" || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -Dserver.port=$APP_PORT -jar /app/app.jar"]
