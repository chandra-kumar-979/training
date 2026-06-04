# ==========================================
# STAGE 1: Build the Java 21 Spring Boot App
# ==========================================
FROM maven:3.9.6-eclipse-temurin-21 AS builder
WORKDIR /build

# Allow skipping tests via build arg
ARG SKIP_TESTS=true

# Cache project dependencies to speed up future builds
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the production JAR file
COPY src ./src
# Use SKIP_TESTS arg to control whether tests run during the package step
RUN mvn clean package -DskipTests=${SKIP_TESTS} -B

# ==========================================
# STAGE 2: Lightweight Java 21 Runtime
# ==========================================
FROM eclipse-temurin:21-jre-jammy

# Create a non-root system user for security
RUN useradd -ms /bin/bash appuser
WORKDIR /app

# UPDATED: Copy your specific rag-chatbot-app.jar file
COPY --from=builder /build/target/rag-chatbot-app-0.0.1-SNAPSHOT.jar application.jar
RUN chown -R appuser:appuser /app

USER appuser
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "application.jar"]