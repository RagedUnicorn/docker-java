############################################
# Shared base: Adoptium apk repository
############################################
# renovate: datasource=custom.adoptium-apk depName=temurin-21-jdk versioning=loose
ARG TEMURIN_VERSION=21.0.11_p10-r0

FROM alpine:3.24.1 AS base

# Base stage labels
LABEL org.opencontainers.image.authors="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
      org.opencontainers.image.source="https://github.com/ragedunicorn/docker-java" \
      org.opencontainers.image.licenses="MIT"

# ca-certificates: TLS trust store (family convention; java-cacerts wires the
# JVM keystore against it). The Adoptium repository key must be stored under
# the exact filename referenced by the repository's APKINDEX signature:
# adoptium.rsa.pub. busybox wget ships in the base image and can fetch it.
RUN apk add --no-cache ca-certificates && \
    wget -q -O /etc/apk/keys/adoptium.rsa.pub \
      https://packages.adoptium.net/artifactory/api/security/keypair/public/repositories/apk && \
    echo "https://packages.adoptium.net/artifactory/apk/alpine/main" >> /etc/apk/repositories

# Create non-root user for running Java. A home directory is created
# deliberately (no -H): the JVM wants a writable ~/.java preferences
# directory and warns without one.
RUN adduser -D -s /sbin/nologin java

WORKDIR /app

RUN chown -R java:java /app

############################################
# JRE variant
############################################
FROM base AS jre

ARG TEMURIN_VERSION
ARG BUILD_DATE
ARG VERSION

# OCI-compliant labels
LABEL org.opencontainers.image.title="Eclipse Temurin 21 JRE on Alpine Linux" \
      org.opencontainers.image.description="Minimal Eclipse Temurin 21 JRE Docker image built on Alpine Linux" \
      org.opencontainers.image.vendor="ragedunicorn" \
      org.opencontainers.image.authors="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
      org.opencontainers.image.source="https://github.com/ragedunicorn/docker-java" \
      org.opencontainers.image.documentation="https://github.com/ragedunicorn/docker-java/blob/master/README.md" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="docker.io/library/alpine:3.24.1"

# java-common (Alpine community repo, pulled in as a dependency) symlinks the
# JVM binaries into /usr/bin and maintains /usr/lib/jvm/default-jvm.
RUN apk add --no-cache temurin-21-jre=${TEMURIN_VERSION}

ENV JAVA_HOME=/usr/lib/jvm/java-21-temurin-jre \
    PATH=/usr/lib/jvm/java-21-temurin-jre/bin:$PATH \
    LANG=C.UTF-8

USER java

ENTRYPOINT ["java"]

CMD ["-version"]

############################################
# JDK variant (default target)
############################################
FROM base AS jdk

ARG TEMURIN_VERSION
ARG BUILD_DATE
ARG VERSION

# OCI-compliant labels
LABEL org.opencontainers.image.title="Eclipse Temurin 21 JDK on Alpine Linux" \
      org.opencontainers.image.description="Minimal Eclipse Temurin 21 JDK Docker image built on Alpine Linux" \
      org.opencontainers.image.vendor="ragedunicorn" \
      org.opencontainers.image.authors="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
      org.opencontainers.image.source="https://github.com/ragedunicorn/docker-java" \
      org.opencontainers.image.documentation="https://github.com/ragedunicorn/docker-java/blob/master/README.md" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="docker.io/library/alpine:3.24.1"

# java-common (Alpine community repo, pulled in as a dependency) symlinks the
# JVM binaries into /usr/bin and maintains /usr/lib/jvm/default-jvm.
RUN apk add --no-cache temurin-21-jdk=${TEMURIN_VERSION}

ENV JAVA_HOME=/usr/lib/jvm/java-21-temurin \
    PATH=/usr/lib/jvm/java-21-temurin/bin:$PATH \
    LANG=C.UTF-8

USER java

ENTRYPOINT ["java"]

CMD ["-version"]
