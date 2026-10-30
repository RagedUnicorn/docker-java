# Development Guide

This document provides information for developers working on the Java Docker image.

## Development Environment

### Prerequisites

- Docker installed and running
- Docker Compose installed
- Git for version control
- Text editor or IDE

### Project Structure

```
docker-java/
├── Dockerfile              # Multi-stage image definition (base → jre → jdk)
├── docker-compose.yml      # Basic usage configuration (jdk + jre services)
├── docker-compose.dev.yml  # Development environment
├── docker-compose.test.yml # Test orchestration for both variants
├── .env                    # Default environment variables
├── examples/               # Example Docker Compose configurations
│   ├── Hello.java          # Hello world example
│   └── docker-compose.yml  # Example services
├── test/                   # Container Structure Tests
│   ├── jdk_test.yml
│   ├── jdk_command_test.yml
│   ├── jdk_metadata_test.yml
│   ├── jre_test.yml
│   ├── jre_command_test.yml
│   └── jre_metadata_test.yml
└── docs/                   # Documentation assets
```

The single Dockerfile defines three stages: a shared `base` stage that wires up
the Adoptium apk repository and the non-root user, and one final stage per
variant (`jre` and `jdk`). The `jdk` stage is last, so a bare `docker build .`
produces the JDK image.

## Development Workflow

### 1. Local Development Mode

The `docker-compose.dev.yml` file provides an interactive development environment (builds the jdk target and opens a shell):

```bash
# Build the image locally
docker compose -f docker-compose.dev.yml build

# Run in development mode (interactive shell)
docker compose -f docker-compose.dev.yml run --rm java-dev

# Inside the container, you can run Java and Maven manually
java -version
javac -version
mvn --version
```

The development mode:

- Mounts the current directory to `/app` for testing files
- Uses interactive mode with STDIN open and TTY allocated
- Overrides the entrypoint with a shell

### 2. Building the Images

```bash
# Build the JDK variant
docker buildx build --load --provenance=false --target jdk -t ragedunicorn/java:test-jdk .

# Build the JRE variant
docker buildx build --load --provenance=false --target jre -t ragedunicorn/java:test-jre .

# Build with version metadata (Temurin, Maven and Alpine come from the Dockerfile)
docker build \
  --target jdk \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VERSION=dev \
  -t ragedunicorn/java:dev .

# Multi-platform build (requires buildx)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --target jre .
```

The Temurin and Maven versions are the `TEMURIN_VERSION` and `MAVEN_VERSION`
defaults in the `Dockerfile` and the Alpine version is its `FROM` line.
Renovate keeps them current, so the docs do not repeat them.

### 3. Testing Your Changes

After making changes, always build and test both variants locally:

```bash
docker buildx build --load --provenance=false --target jdk -t ragedunicorn/java:test-jdk .
docker buildx build --load --provenance=false --target jre -t ragedunicorn/java:test-jre .
```

#### Running Tests (Cross-Platform)

**Linux/macOS:**

```bash
# Run all tests against your local builds
JAVA_JDK_TEST_VERSION=test-jdk JAVA_JRE_TEST_VERSION=test-jre docker compose -f docker-compose.test.yml run --rm test-all

# Run per-variant or single suites during development
JAVA_JDK_TEST_VERSION=test-jdk docker compose -f docker-compose.test.yml run --rm test-all-jdk
JAVA_JRE_TEST_VERSION=test-jre docker compose -f docker-compose.test.yml up container-test-command-jre
```

**Windows Command Prompt:**

```cmd
set JAVA_JDK_TEST_VERSION=test-jdk && set JAVA_JRE_TEST_VERSION=test-jre && docker compose -f docker-compose.test.yml run --rm test-all
```

**Windows PowerShell:**

```powershell
$env:JAVA_JDK_TEST_VERSION="test-jdk"; $env:JAVA_JRE_TEST_VERSION="test-jre"; docker compose -f docker-compose.test.yml run --rm test-all
```

**Important:** Never test against remote images - they may have different labels or configurations. Local builds (`test-jdk` / `test-jre`) are the only images the tests are written against.

See [TEST.md](TEST.md) for detailed testing information.

## Making Changes

### Version Updates

This project uses [Renovate](https://docs.renovatebot.com/) to automatically manage dependency updates:

- **Alpine Linux**: Renovate monitors Docker Hub and creates PRs for new Alpine versions. Every Alpine reference is kept in sync from a single grouped PR — the `FROM` line (Renovate's built-in dockerfile manager), the `org.opencontainers.image.base.name` OCI labels in both variant stages, and the Alpine version asserted in `test/jdk_metadata_test.yml` and `test/jre_metadata_test.yml` (via regex `customManagers` in `renovate.json`).
- **Eclipse Temurin**: The Temurin version is pinned via the single `TEMURIN_VERSION` build arg, which covers both variants (jdk and jre releases are in lockstep). Renovate discovers new versions through a custom HTML datasource that reads the Adoptium apk repository listing (`https://packages.adoptium.net/artifactory/apk/alpine/main/x86_64/`) and filters for `temurin-21-jdk-*.apk`. Because the Adoptium index retains all historical versions, an existing pin keeps building even after newer patches land.
- **Apache Maven** (jdk variant only): The Maven version is pinned via the `MAVEN_VERSION` build arg. Renovate discovers new versions through the standard `maven` datasource (Maven Central, `org.apache.maven:apache-maven`), while the Dockerfile downloads the matching official binary tarball from `https://archive.apache.org/dist/maven/maven-3/` with SHA-512 verification. The archive retains every release, so an existing pin keeps building. Renovate is constrained to `<4.0.0` — a Maven **major** upgrade is a deliberate manual migration because the `maven-3` segment of the download URL and the `allowedVersions` guard in `renovate.json` must change together.

When Renovate creates a PR:

1. Review the changes in the PR
2. Check the CI/CD pipeline passes all tests
3. Test the build locally if it's a major version update
4. Merge the PR if everything looks good

If the Renovate datasource ever breaks (e.g. the Artifactory listing format changes), bump the pin manually against the same URL — Temurin patch releases follow the quarterly Java CPU cadence (January/April/July/October):

```dockerfile
# renovate: datasource=custom.adoptium-apk depName=temurin-21-jdk versioning=loose
ARG TEMURIN_VERSION=<java-version>_p<build>-r<release>
```

### Java Major Version Upgrades

Moving to a new Java major (e.g. Temurin 25) is a deliberate manual migration — Renovate is intentionally scoped to the current major and will never propose it. The major is embedded in several places that must change together:

1. The apk package names in the Dockerfile (`temurin-21-jdk`, `temurin-21-jre`)
2. The `depName` and the `extractVersion` regex in `renovate.json`
3. Both `JAVA_HOME` paths (`/usr/lib/jvm/java-21-temurin`, `/usr/lib/jvm/java-21-temurin-jre`) and the matching `PATH` prefixes
4. The JAVA_HOME assertions in both metadata tests and the path/version assertions in all six test files
5. Version references in README.md, DOCKERHUB.md, and the OCI title/description labels
6. The leading number of the release tag scheme

When manually updating the Alpine version, update only the `FROM alpine:X.X.X` line — Renovate keeps the `base.name` labels and metadata tests aligned on its next run.

## Code Style and Best Practices

### Dockerfile Best Practices

1. **Minimal installation**: Only the Temurin runtime/JDK, CA certificates, and (jdk only) Apache Maven
2. **Shared base stage**: Common setup lives once in the `base` stage
3. **Cache efficiency**: Order commands from least to most frequently changed
4. **Security**: Run as non-root user
5. **Labels**: Follow OCI naming conventions; per-variant title/description

### Documentation

1. **README.md**: Keep focused on user-facing information
2. **Comments**: Add comments in Dockerfile for complex operations
3. **Examples**: Provide working examples for new features
4. **Commit messages**: Use conventional format (feat:, fix:, docs:, etc.)

### Testing

1. **Test everything**: New features must include tests
2. **Test both variants**: jdk and jre have separate test files
3. **Test edge cases**: Include negative tests (e.g. `javac` absent in jre)
4. **Keep tests fast**: Avoid long-running operations in tests

## Debugging

### Common Issues

**Build failures:**

```bash
# Verbose build output
docker build --progress=plain --no-cache --target jdk -t ragedunicorn/java:debug .

# Inspect the installed JVM
docker run --rm --entrypoint sh ragedunicorn/java:debug -c "ls /usr/lib/jvm && ls \$JAVA_HOME/bin"
```

**Java not working:**

```bash
# Check Java installation
docker run --rm --entrypoint sh ragedunicorn/java:test-jdk -c "which java && java -version"

# Show effective JVM settings
docker run --rm ragedunicorn/java:test-jdk -XshowSettings:properties -version
```

**Adoptium repository issues:**

```bash
# Verify the repository key and listing are reachable
docker run --rm --entrypoint sh ragedunicorn/java:test-jdk -c "cat /etc/apk/repositories"
```

## Contributing

### Before Submitting Changes

1. Run the full test suite (both variants)
2. Update documentation if needed
3. Add tests for new features
4. Ensure your code follows the existing style
5. Write clear commit messages

### Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes using conventional commits
4. Push to your fork
5. Open a Pull Request with a clear description

### Release Process

See [RELEASE.md](RELEASE.md) for information about creating releases.
