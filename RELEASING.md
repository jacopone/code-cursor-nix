# Release Process

This document describes the release process for code-cursor-nix.

## Versioning

We use semantic versioning aligned with Cursor's version:
- Tag format: `v{cursor-version}` (e.g., `v2.0.34`)
- Releases track Cursor's stable versions

## Automatic Releases

The GitHub Actions workflow automatically:
1. Checks for new Cursor versions twice weekly (Tuesday and Friday)
2. Creates a PR with version updates
3. Auto-merges after successful tests
4. Tags are created manually after significant changes

## Manual Release Process

### 1. Create a Tag

```bash
# Tag the current HEAD
git tag -a v{version} -m "Release v{version} - Cursor {version}"

# Or tag a specific commit
git tag -a v{version} {commit-sha} -m "Release v{version} - Cursor {version}"

# Push the tag
git push origin v{version}
```

### 2. Create GitHub Release

```bash
gh release create v{version} \
  --title "v{version}" \
  --notes "Release notes here" \
  --latest
```

## Release Notes Format

Follow this structure for release notes:

```markdown
## What's Changed

### Features
- Description of new features with commit references

### Updates
- Version updates and dependency changes

### Fixes
- Bug fixes and improvements

## Installation

```nix
# Flake input
inputs.code-cursor-nix.url = "github:jacopone/code-cursor-nix/v{version}";
```

**Full Changelog**: https://github.com/jacopone/code-cursor-nix/compare/{previous}...v{version}
```

## When to Create Releases

Create a new release when:
- Cursor version is updated (automatic via PR)
- Significant features are added (e.g., browser automation support)
- Breaking changes are introduced
- Important bug fixes are merged

## Release Checklist

- [ ] Ensure all tests pass
- [ ] Update README if needed
- [ ] Create and push tag
- [ ] Create GitHub release with clear notes
- [ ] Verify flake input works with new tag

## Downstream Users

Users can pin to specific releases:

```nix
# Latest release
inputs.code-cursor-nix.url = "github:jacopone/code-cursor-nix";

# Specific version
inputs.code-cursor-nix.url = "github:jacopone/code-cursor-nix/v2.0.34";

# Specific commit (for testing)
inputs.code-cursor-nix.url = "github:jacopone/code-cursor-nix/dc3d1f7";
```