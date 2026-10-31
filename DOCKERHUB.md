# Java (Eclipse Temurin) Alpine Docker Image

![Docker Java](https://raw.githubusercontent.com/ragedunicorn/docker-java/master/docs/docker_java_banner.png)

A minimal Java image on Alpine Linux, shipping Eclipse Temurin 21 (LTS) from the Adoptium apk repository in two variants: a full JDK with Apache Maven and a runtime-only JRE.

## Quick Start

```bash
# Pull the JDK (latest)
docker pull ragedunicorn/java:latest

# Pull the JRE
docker pull ragedunicorn/java:latest-jre

# Or pull a specific version (see the Tags tab for the available versions)
docker pull ragedunicorn/java:<java-version>-jdk-alpine<alpine-version>-<build>

# Print the Java version (default command)
docker run --rm ragedunicorn/java:latest

# Run a Java source file (JDK only)
docker run -v $(pwd):/app ragedunicorn/java:latest Hello.java
```

On Windows, use the PowerShell form - `${PWD}` **with braces** and the colon
inside the quotes (without braces PowerShell parses `$PWD:` as a
scope-qualified variable, as in `$env:PATH`, and rejects the argument):

```powershell
# Run a Java source file (JDK only)
docker run -v "${PWD}:/app" ragedunicorn/java:latest Hello.java
```

## Features

- 🚀 **Small footprint**: compact runtime image built on Alpine Linux
- ☕ **Eclipse Temurin 21 LTS**: pinned Adoptium build, decoupled from Alpine
- 📦 **Apache Maven**: pinned official binary in the JDK variant, decoupled from Alpine
- 🔀 **Two variants**: full JDK (`latest`) and runtime-only JRE (`latest-jre`)
- 🔒 **Security**: non-root user, minimal attack surface
- 🏗️ **Multi-platform**: supports linux/amd64 and linux/arm64
- 🎯 **Customizable**: extend with only what you need

## Usage Examples

### Run a Java source file (single-file source launch, JDK only)
```bash
docker run -v $(pwd):/app ragedunicorn/java:latest Hello.java
```

PowerShell:

```powershell
docker run -v "${PWD}:/app" ragedunicorn/java:latest Hello.java
```

### Run a jar with the JRE
```bash
docker run -v $(pwd):/app ragedunicorn/java:latest-jre -jar app.jar
```

PowerShell:

```powershell
docker run -v "${PWD}:/app" ragedunicorn/java:latest-jre -jar app.jar
```

### Interactive Java shell (JDK only)
```bash
docker run -it --rm --entrypoint jshell ragedunicorn/java:latest
```

### Compile with javac (JDK only)
```bash
docker run -v $(pwd):/app --entrypoint javac ragedunicorn/java:latest Hello.java
```

PowerShell:

```powershell
docker run -v "${PWD}:/app" --entrypoint javac ragedunicorn/java:latest Hello.java
```

### Build with Maven (JDK only)
```bash
# The named volume keeps the local repository (~/.m2) between runs; a fresh
# volume is initialized owned by the java user (the image pre-creates ~/.m2)
docker run -v $(pwd):/app -v m2cache:/home/java/.m2 --entrypoint mvn ragedunicorn/java:latest package
```

PowerShell:

```powershell
docker run -v "${PWD}:/app" -v m2cache:/home/java/.m2 --entrypoint mvn ragedunicorn/java:latest package
```

On Docker Desktop for Windows, overwriting existing files on a bind mount can fail with `Operation not permitted` for the non-root `java` user — if your build writes into the mounted workspace, run with `-u root` and use `-v m2cache-root:/root/.m2` for the cache instead.

### Build a custom image
```dockerfile
FROM ragedunicorn/java:latest-jre

COPY app.jar /app/app.jar

CMD ["-jar", "/app/app.jar"]
```

## Tags

This image uses semantic versioning that includes all component versions:

**Format:** `{java_version}-{jdk|jre}-alpine{alpine_version}-{build_number}`

### Version Examples

`X.Y.Z` is the Temurin version, `A.B.C` the Alpine version:

- `X.Y.Z-jdk-alpineA.B.C-1` - Temurin X.Y.Z JDK on Alpine A.B.C, build 1
- `X.Y.Z-jre-alpineA.B.C-1` - Temurin X.Y.Z JRE on Alpine A.B.C, build 1
- `latest` - Most recent stable JDK release
- `latest-jre` - Most recent stable JRE release

The available versions are listed in the [Tags tab](https://hub.docker.com/r/ragedunicorn/java/tags).

Both variants are published together from a single release. When updates are available through automated dependency management, new releases are created with appropriate version tags.

## Environment Variables

- `JAVA_HOME` - Points at the Temurin installation (`/usr/lib/jvm/java-21-temurin` in the JDK, `/usr/lib/jvm/java-21-temurin-jre` in the JRE)
- `MAVEN_HOME` - Points at the Maven installation (`/opt/maven`, JDK only)
- `LANG=C.UTF-8` - UTF-8 default encoding

## Working Directory

The default working directory is `/app`. Mount your code here:

```bash
docker run -v $(pwd):/app ragedunicorn/java:latest YourProgram.java
```

PowerShell:

```powershell
docker run -v "${PWD}:/app" ragedunicorn/java:latest YourProgram.java
```

## Links

- **GitHub**: [https://github.com/ragedunicorn/docker-java](https://github.com/ragedunicorn/docker-java)
- **Issues**: [https://github.com/ragedunicorn/docker-java/issues](https://github.com/ragedunicorn/docker-java/issues)
- **Releases**: [https://github.com/ragedunicorn/docker-java/releases](https://github.com/ragedunicorn/docker-java/releases)
- **Eclipse Temurin**: [https://adoptium.net/](https://adoptium.net/)

## License

MIT License - See [GitHub repository](https://github.com/ragedunicorn/docker-java) for details.
