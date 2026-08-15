# ============================================================
# Stage 1: Build
# ============================================================
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /workspace

RUN apk add --no-cache git

# Copy Maven configuration first
COPY .mvn/ .mvn/
COPY mvnw mvnw.cmd pom.xml ./

RUN chmod +x ./mvnw

# Download dependencies first.
# This layer will be cached until pom.xml changes.
RUN ./mvnw dependency:go-offline -DskipTests

# Now copy application source
COPY src/ src/

# Don't use clean during Docker development builds
RUN ./mvnw package -DskipTests


# ============================================================
# Stage 2: Runtime
# ============================================================
FROM eclipse-temurin:21-jre-alpine

RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser

WORKDIR /app

COPY --from=builder /workspace/target/*.jar app.jar

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=30s \
            --retries=3 \
            CMD wget --no-verbose \
                 --tries=1 \
                 --spider \
                 http://localhost:8080/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]