# Testing Guide

This document describes how to test the Java Docker images using Container Structure Tests.

## Quick Start

```bash
# Run all tests (both variants)
docker compose -f docker-compose.test.yml run --rm test-all

# Run all tests for one variant
docker compose -f docker-compose.test.yml run --rm test-all-jdk
docker compose -f docker-compose.test.yml run --rm test-all-jre

# Run individual test suites
docker compose -f docker-compose.test.yml up container-test-jdk           # File structure tests (jdk)
docker compose -f docker-compose.test.yml up container-test-command-jdk   # Command execution tests (jdk)
docker compose -f docker-compose.test.yml up container-test-metadata-jdk  # Metadata validation tests (jdk)
docker compose -f docker-compose.test.yml up container-test-jre           # File structure tests (jre)
docker compose -f docker-compose.test.yml up container-test-command-jre   # Command execution tests (jre)
docker compose -f docker-compose.test.yml up container-test-metadata-jre  # Metadata validation tests (jre)
```

## Test Structure

Each image variant has three test files (six in total):

### 1. File Structure Tests (`test/jdk_test.yml`, `test/jre_test.yml`)

Validates:

- Java binaries exist under the variant's `JAVA_HOME`
- The `/usr/bin/java` symlink (created by `java-common`) exists
- **jdk**: the Maven binary (`/opt/maven/bin/mvn`) and the `/usr/bin/mvn` symlink exist; `~/.m2` is pre-created and owned by the java user
- The JVM certificate store and system CA bundle are present
- Working directory `/app` exists and is accessible
- **jre only**: `javac` and `mvn` do NOT exist (runtime-only image)

### 2. Command Execution Tests (`test/jdk_command_test.yml`, `test/jre_command_test.yml`)

Validates:

- `java -version` reports Temurin 21
- **jdk**: `javac`, `jar`, and `jshell` are present and functional; `mvn --version` reports Apache Maven 3 and `MAVEN_HOME` resolves
- **jre**: `javac`, `jar`, `jshell`, and `mvn` are absent; `keytool` is present
- `JAVA_HOME` resolves to a real installation
- Non-root user functionality
- Working directory configuration

### 3. Metadata Tests (`test/jdk_metadata_test.yml`, `test/jre_metadata_test.yml`)

Validates:

- OCI-compliant labels are present and correct
- `JAVA_HOME` and `LANG` environment variables per variant (plus `MAVEN_HOME` in the jdk)
- Container entrypoint (`java`) and default command (`-version`)
- Working directory configuration
- User context (runs as non-root java user)

## Running Tests

### Prerequisites

1. Docker must be installed and running
2. Build both Java images locally before testing

### Important: Always Test Local Builds

**⚠️ Always build and test locally to ensure consistency:**

```bash
# Build both variants locally with test tags
docker buildx build --load --provenance=false --target jdk -t ragedunicorn/java:test-jdk .
docker buildx build --load --provenance=false --target jre -t ragedunicorn/java:test-jre .
```

**Linux/macOS:**

```bash
# Run tests against your local builds
JAVA_JDK_VERSION=test-jdk JAVA_JRE_VERSION=test-jre docker compose -f docker-compose.test.yml run --rm test-all
```

**Windows (PowerShell):**

```powershell
$env:JAVA_JDK_VERSION="test-jdk"; $env:JAVA_JRE_VERSION="test-jre"; docker compose -f docker-compose.test.yml run --rm test-all
```

**Windows (Command Prompt):**

```cmd
set JAVA_JDK_VERSION=test-jdk && set JAVA_JRE_VERSION=test-jre && docker compose -f docker-compose.test.yml run --rm test-all
```

**Why local testing is important:**
- Remote images (Docker Hub, GHCR) may differ from what you changed locally
- Ensures you're testing exactly what you built
- Avoids false positives/negatives from version mismatches
- Guarantees consistent test results

Note: the committed `.env` defaults the image variables to `latest` /
`latest-jre` for everyday compose usage, so the test environment variables
must be set explicitly when running tests.

### Testing Different Versions

When testing different versions, always build locally first:

```bash
docker buildx build --load --provenance=false --target jdk -t ragedunicorn/java:21.0.11-jdk-alpine3.24.1-1 .
```

**Linux/macOS:**

```bash
JAVA_JDK_VERSION=21.0.11-jdk-alpine3.24.1-1 docker compose -f docker-compose.test.yml run --rm test-all-jdk
```

**Windows (PowerShell):**

```powershell
$env:JAVA_JDK_VERSION="21.0.11-jdk-alpine3.24.1-1"; docker compose -f docker-compose.test.yml run --rm test-all-jdk
```

## Troubleshooting Test Failures

### `java -version` Assertions Use `expectedError`

`java -version` writes to **stderr**, so the command tests assert it via
`expectedError`, not `expectedOutput`. The assertions are deliberately loose
(`openjdk version "21`, `Temurin`) so Temurin patch updates do not require
test changes.

### `which` Exit Codes in the JRE Negative Tests

The jre command tests assert that developer tools are absent by expecting
`which javac` (and `jar`, `jshell`, `mvn`) to exit with code 1 — busybox
`which` exits 1 on a miss. No output assertion is needed.

### Java Version / Path Mismatches

The JVM is installed from the Adoptium apk repository under
`/usr/lib/jvm/java-21-temurin` (jdk) and `/usr/lib/jvm/java-21-temurin-jre`
(jre). A Java **major** upgrade changes these paths and requires updating all
six test files — see the migration checklist in
[DEVELOPMENT.md](DEVELOPMENT.md). Temurin **patch** updates need no test
changes.

To find the current Java installation details in the image:

```bash
docker run --rm --entrypoint sh ragedunicorn/java:test-jdk -c \
  "ls /usr/lib/jvm && ls \$JAVA_HOME/bin"
```

### Metadata Test Failures

**Common causes:**

1. **Testing remote images instead of local builds**
   - Always test your local builds with `JAVA_JDK_VERSION=test-jdk` / `JAVA_JRE_VERSION=test-jre`

2. **Label value mismatches**
   - The Alpine version in `org.opencontainers.image.base.name` is renovate-synced with the `FROM` line; if you bumped Alpine manually, the metadata tests drift until Renovate's next run (or update them yourself)

3. **Version-specific labels**
   - The `org.opencontainers.image.version` label changes with each build
   - Build date labels are dynamic (neither is asserted by the tests)

### Permission Errors

If you encounter Docker socket permission errors:

```bash
sudo docker compose -f docker-compose.test.yml run --rm test-all
```

Or ensure your user is in the `docker` group:

```bash
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

## Writing New Tests

To add new tests, follow the Container Structure Test schema. Remember that
each variant has its own files:

1. **File tests**: Add to `test/jdk_test.yml` and/or `test/jre_test.yml`
2. **Command tests**: Add to `test/jdk_command_test.yml` and/or `test/jre_command_test.yml`
3. **Metadata tests**: Add to `test/jdk_metadata_test.yml` and/or `test/jre_metadata_test.yml`

Example of adding a new command test:

```yaml
- name: 'Check keytool version'
  command: 'keytool'
  args: ['-help']
  exitCode: 0
```

## CI/CD Integration

These tests are automatically run in GitHub Actions:

- **On every push** to master branches
- **On every pull request** to master branches
- **Before releases** to ensure quality

The test workflow (`.github/workflows/test.yml`):
1. Builds both Dockerfile targets in a matrix (`jdk`, `jre`)
2. Runs all Container Structure Tests per variant
3. Verifies basic Java functionality (including that `javac` is absent in the jre image)
4. Blocks releases if tests fail

Manual integration example:

```yaml
- name: Run Container Structure Tests
  env:
    JAVA_JDK_VERSION: test-jdk
    JAVA_JRE_VERSION: test-jre
  run: docker compose -f docker-compose.test.yml run --rm test-all
```

The `test-all` services return:
- Exit code 0: All tests passed
- Exit code 1: One or more tests failed

## Test Maintenance

When updating the Docker images:

1. **Temurin patch updates**: No test changes needed (assertions are major-version loose)
2. **Maven minor/patch updates**: No test changes needed (the `mvn --version` assertion is major-version loose, and the pinned install is reached via the version-independent `/opt/maven` symlink)
3. **Java major upgrades**: Update paths and version strings in all six test files (see [DEVELOPMENT.md](DEVELOPMENT.md))
4. **Alpine version updates**: Renovate keeps the `base.name` labels and both metadata tests in sync with the `FROM` version
5. **New functionality**: Add corresponding tests to verify behavior
6. **Label changes**: Update both metadata tests to match new labels

Always run the full test suite before creating a release.
