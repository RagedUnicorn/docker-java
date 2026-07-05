# Release Process

This document describes how to create a new release for the Docker Java project.

## Quick Start

```bash
# Tag format: v{java_version}-alpine{alpine_version}-{build_number}
git tag -a v21.0.11-alpine3.24.1-1 -m "v21.0.11-alpine3.24.1-1"
git push origin v21.0.11-alpine3.24.1-1
```

This automatically triggers the release process via GitHub Actions. A single
tag builds and publishes **both** image variants (jdk and jre).

## Version Tag Format

See [README.md](README.md#versioning) for the complete versioning documentation.

**Format:** `v{java_version}-alpine{alpine_version}-{build_number}`

Examples:
- `v21.0.11-alpine3.24.1-1` - Initial release
- `v21.0.11-alpine3.24.1-2` - Rebuild with same versions
- `v21.0.11-alpine3.24.2-1` - Alpine update (build resets to 1)
- `v21.0.12-alpine3.24.2-1` - Temurin update (build resets to 1)

The pushed Docker tags insert the variant after the Java version:
`21.0.11-jdk-alpine3.24.1-1` and `21.0.11-jre-alpine3.24.1-1`, plus the
rolling `latest` (jdk) and `latest-jre` (jre) tags.

## Release Workflow

When you push a tag, GitHub Actions automatically:

1. **Builds Docker images** (`.github/workflows/docker_release.yml`)
   - Runs the Container Structure Tests for both variants first
   - Multi-platform: linux/amd64 and linux/arm64
   - Builds the `jdk` and `jre` Dockerfile targets in a matrix
   - Pushes both variants to GitHub Container Registry and Docker Hub

2. **Creates GitHub Release** (`.github/workflows/github_release.yml`)
   - Generates changelog from commit history
   - Adds Docker pull commands for both variants
   - Links to the release

## When to Create a Release

Create a new release when:

1. **Renovate updates dependencies** - After merging Renovate PRs for Alpine or Temurin updates
2. **Bug fixes** - After fixing issues in the Dockerfile or build process
3. **Feature additions** - After adding new functionality
4. **Security patches** - Immediately after security-related updates

### Build Number Guidelines

- **Reset to 1**: When the Alpine or Temurin version changes
- **Increment**: When rebuilding with the same versions (fixes, optimizations)

## Post-Release Tasks

### Update Docker Hub Documentation

After creating a release, manually update the Docker Hub repository description:

1. Go to [Docker Hub](https://hub.docker.com/r/ragedunicorn/java)
2. Click "Manage Repository" → "Description"
3. Copy the contents of `DOCKERHUB.md`
4. Update any version numbers in the examples to match the latest release
5. Save the changes

**Note**: The `DOCKERHUB.md` file is maintained in the repository as the source of truth for Docker Hub documentation.

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

- Ensure tag starts with `v` and follows the format (e.g., `v21.0.11-alpine3.24.1-1`)
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
3. Choose your tag (must follow format: `v21.0.11-alpine3.24.1-1`)
4. Add release notes
5. Include Docker pull commands:
   ```
   docker pull ghcr.io/ragedunicorn/docker-java:21.0.11-jdk-alpine3.24.1-1
   docker pull ghcr.io/ragedunicorn/docker-java:21.0.11-jre-alpine3.24.1-1
   docker pull ragedunicorn/java:21.0.11-jdk-alpine3.24.1-1
   docker pull ragedunicorn/java:21.0.11-jre-alpine3.24.1-1
   ```
