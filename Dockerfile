############################################
# Shared base: Adoptium apk repository
############################################
# renovate: datasource=custom.adoptium-apk depName=temurin-21-jdk versioning=loose
ARG TEMURIN_VERSION=21.0.12.1_p1-r0
# renovate: datasource=maven depName=org.apache.maven:apache-maven
ARG MAVEN_VERSION=3.10.0

FROM alpine:3.24.2 AS base

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
      org.opencontainers.image.base.name="docker.io/library/alpine:3.24.2"

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
ARG MAVEN_VERSION
ARG BUILD_DATE
ARG VERSION

# OCI-compliant labels
LABEL org.opencontainers.image.title="Eclipse Temurin 21 JDK on Alpine Linux" \
      org.opencontainers.image.description="Eclipse Temurin 21 JDK with Apache Maven Docker image built on Alpine Linux" \
      org.opencontainers.image.vendor="ragedunicorn" \
      org.opencontainers.image.authors="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
      org.opencontainers.image.source="https://github.com/ragedunicorn/docker-java" \
      org.opencontainers.image.documentation="https://github.com/ragedunicorn/docker-java/blob/master/README.md" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="docker.io/library/alpine:3.24.2"

# java-common (Alpine community repo, pulled in as a dependency) symlinks the
# JVM binaries into /usr/bin and maintains /usr/lib/jvm/default-jvm.
RUN apk add --no-cache temurin-21-jdk=${TEMURIN_VERSION}

# Maven is installed from the official Apache binary tarball rather than
# Alpine's maven package: the apk depends on the java-jdk virtual (Alpine's
# OpenJDK) and its version is coupled to the Alpine release. The tarball is
# pure Java, so one download serves both amd64 and arm64. archive.apache.org
# retains every version, so an existing pin keeps building after newer
# releases land. The published .sha512 holds only the bare hash, hence the
# assembled sha512sum -c input line. ~/.m2 is pre-created with java ownership
# so a named volume mounted there for the local repository is initialized
# owned by the java user instead of root.
RUN wget -q -O /tmp/maven.tar.gz \
      https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    wget -q -O /tmp/maven.tar.gz.sha512 \
      https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz.sha512 && \
    echo "$(cat /tmp/maven.tar.gz.sha512)  /tmp/maven.tar.gz" | sha512sum -c - && \
    tar -xzf /tmp/maven.tar.gz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven && \
    ln -s /opt/maven/bin/mvn /usr/bin/mvn && \
    rm /tmp/maven.tar.gz /tmp/maven.tar.gz.sha512 && \
    mkdir /home/java/.m2 && \
    chown java:java /home/java/.m2

ENV JAVA_HOME=/usr/lib/jvm/java-21-temurin \
    MAVEN_HOME=/opt/maven \
    PATH=/usr/lib/jvm/java-21-temurin/bin:$PATH \
    LANG=C.UTF-8

USER java

ENTRYPOINT ["java"]

CMD ["-version"]
