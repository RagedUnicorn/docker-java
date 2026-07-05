# Examples

Small examples showing how to use the `ragedunicorn/java` images.

## Hello World

Run the example with the JDK image using Java's single-file source launch —
the source file is compiled in memory and executed directly:

```bash
docker run --rm -v "$(pwd):/app" ragedunicorn/java:latest Hello.java
```

Expected output:

```
Hello, World from Docker Java!
Java version: 21.0.11
Java runtime: OpenJDK Runtime Environment
OS: Linux amd64
```

Or via docker compose (from this directory):

```bash
docker compose run --rm hello-world
```

Note: single-file source launch needs the compiler, so it works on the JDK
image only — running the same command against `latest-jre` fails by design.

## Interactive shell (jshell)

```bash
docker compose run --rm jshell
```

## JRE variant

The runtime-only image is meant for running precompiled applications:

```bash
docker run --rm -v "$(pwd):/app" ragedunicorn/java:latest-jre -jar app.jar
```

Without arguments it prints the Java version:

```bash
docker compose run --rm jre
```

## Compile then run

Use the JDK image to compile, then run the class with either variant:

```bash
docker run --rm -v "$(pwd):/app" --entrypoint javac ragedunicorn/java:latest Hello.java
docker run --rm -v "$(pwd):/app" ragedunicorn/java:latest-jre Hello
```

## Building your own image

The JRE variant is the natural base for shipping an application:

```dockerfile
FROM ragedunicorn/java:latest-jre

COPY app.jar /app/app.jar

CMD ["-jar", "/app/app.jar"]
```

The JDK variant is the natural base for build stages or images that need
`javac`, `jar`, or `jshell`.
