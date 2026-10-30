# Release Process

This document describes how to create a new release for the Docker Java project.

## Quick Start

```bash
# Tag format: v{java_version}-alpine{alpine_version}-{build_number}
# Take the versions from the Dockerfile (TEMURIN_VERSION without the apk
# suffix, e.g. the X.Y.Z of X.Y.Z_pN-rN, and the FROM line)
TAG=v<java-version>-alpine<alpine-version>-<build>
git tag -a "$TAG" -m "$TAG"
git push origin "$TAG"
```

This automatically triggers the release process via GitHub Actions. A single
tag builds and publishes **both** image variants (jdk and jre).

## Version Tag Format

See [README.md](README.md#versioning) for the complete versioning documentation.

**Format:** `v{java_version}-alpine{alpine_version}-{build_number}`

Examples (`X.Y.Z` is the Temurin version, `A.B.C` the Alpine version):
- `vX.Y.Z-alpineA.B.C-1` - Initial release
- `vX.Y.Z-alpineA.B.C-2` - Rebuild with same versions
- `vX.Y.Z-alpineA.B.D-1` - Alpine update (build resets to 1)
- `vX.Y.Z+1-alpineA.B.D-1` - Temurin update (build resets to 1)

The git tag carries no variant. The pushed Docker tags drop the `v` and insert
the variant after the Java version: git tag `vX.Y.Z-alpineA.B.C-N` becomes
`X.Y.Z-jdk-alpineA.B.C-N` and `X.Y.Z-jre-alpineA.B.C-N`, plus the rolling
`latest` (jdk) and `latest-jre` (jre) tags. There is no bare version tag.

## Release Workflow

When you push a tag, GitHub Actions automatically:

1. **Builds Docker images** (`.github/workflows/docker_release.yml`)
   - Runs the Container Structure Tests for both variants first
   - Multi-platform: linux/amd64 and linux/arm64
   - Builds the `jdk` and `jre` Dockerfile targets in a matrix
   - Pushes both variants to GitHub Container Registry and Docker Hub

2. **Creates GitHub Release** (`create-release` job in `.github/workflows/docker_release.yml`)
   - Runs only after the images were tested and pushed successfully
   - Generates changelog from commit history
   - Adds Docker pull commands for both variants
   - Links to the release

## When to Create a Release

Create a new release when:

1. **Renovate updates dependencies** - After merging Renovate PRs for Alpine, Temurin, or Maven updates
2. **Bug fixes** - After fixing issues in the Dockerfile or build process
3. **Feature additions** - After adding new functionality
4. **Security patches** - Immediately after security-related updates

### Build Number Guidelines

- **Reset to 1**: When the Alpine or Temurin version changes
- **Increment**: When rebuilding with the same versions (fixes, optimizations), including Maven-only updates — the tag encodes only the Java and Alpine versions

## Post-Release Tasks

### Update Docker Hub Documentation

`DOCKERHUB.md` is the source of truth for the Docker Hub repository
description. It deliberately contains no concrete versions (readers find those
in the Tags tab), so a release alone does not require a description update.
Only when `DOCKERHUB.md` changed since the last sync:

1. Go to [Docker Hub](https://hub.docker.com/r/ragedunicorn/java)
2. Click "Manage Repository" → "Description"
3. Copy the contents of `DOCKERHUB.md`
4. Save the changes

**Note**: the sync stays manual on purpose. Docker Hub only offers an
undocumented endpoint for description updates, and it needs a separate
Read/Write/Delete access token.

## Best Practices

### Commit Messages

Use conventional commit format for better changelogs:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `chore:` Maintenance tasks
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `perf:` Performance improvements

Example:
```bash
git commit -m "feat: add jlink-based custom runtime example"
git commit -m "fix: resolve permission issue in container"
git commit -m "docs: update usage examples"
```

### Pre-release Testing

Before creating a release:

1. Test both Docker image variants locally with your version changes
2. Verify Java runs correctly (`java -version`, run a sample program)
3. Check that multi-platform builds work (especially arm64)

## Troubleshooting

### Release didn't trigger

- Ensure tag starts with `v` and follows the format (e.g., `vX.Y.Z-alpineA.B.C-N`)
- Check GitHub Actions tab for workflow runs
- Verify you have push permissions

### Docker build failed

- Check the Docker workflow logs
- Ensure both Dockerfile targets build locally (`--target jdk`, `--target jre`)
- Verify multi-platform compatibility

### Missing permissions

Ensure your repository has:
- GitHub Actions enabled
- Package write permissions for workflows
- Proper secrets configuration (GITHUB_TOKEN is automatic)

### Docker Hub Configuration

To enable Docker Hub deployment, you need to add these secrets to your GitHub repository:

1. Go to Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Your Docker Hub access token (not password)

To create a Docker Hub access token:
1. Log in to Docker Hub
2. Go to Account Settings → Security
3. Click "New Access Token"
4. Give it a descriptive name (e.g., "GitHub Actions")
5. Copy the token and add it as `DOCKERHUB_TOKEN` secret

## Manual Release (if needed)

If automation fails, you can create a release manually:

1. Go to repository's "Releases" page
2. Click "Create a new release"
3. Choose your tag (must follow format: `vX.Y.Z-alpineA.B.C-N`)
4. Add release notes
5. Include Docker pull commands (the variant image tags, see [Version Tag Format](#version-tag-format)):
   ```
   docker pull ghcr.io/ragedunicorn/docker-java:<java-version>-jdk-alpine<alpine-version>-<build>
   docker pull ghcr.io/ragedunicorn/docker-java:<java-version>-jre-alpine<alpine-version>-<build>
   docker pull ragedunicorn/java:<java-version>-jdk-alpine<alpine-version>-<build>
   docker pull ragedunicorn/java:<java-version>-jre-alpine<alpine-version>-<build>
   ```
