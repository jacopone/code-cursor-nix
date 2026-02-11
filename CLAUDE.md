# cursor-nix

> Nix Package: Auto-updating Nix flake for Cursor AI Code Editor

## Overview

This flake provides a Nix package for Cursor, the AI-powered code editor, enabling reproducible installation on NixOS and other Nix-enabled systems.

## Quick Start

```bash
# Try without installing
nix run github:jacopone/code-cursor-nix

# Install in profile
nix profile install github:jacopone/code-cursor-nix

# Use in flake
{
  inputs.code-cursor-nix.url = "github:jacopone/code-cursor-nix";
  inputs.code-cursor-nix.inputs.nixpkgs.follows = "nixpkgs";
}
```

## Flake Outputs

| Output | Description |
|--------|-------------|
| `packages.x86_64-linux.default` | Main Cursor package |
| `packages.x86_64-linux.cursor` | Explicit cursor package |
| `apps.default` | Run cursor directly |
| `overlays.default` | For NixOS integration |

## Updating

```bash
# Check upstream Cursor release
# https://www.cursor.com/ or AppImage releases

# Update version in package.nix, then:
nix build
# Copy new hash from error message if hash mismatch

# Test
nix run . -- --version
```

## Key Files

| File | Purpose |
|------|---------|
| `flake.nix` | Flake definition with overlay |
| `package.nix` | Package derivation (version, src, hash) |
| `scripts/` | Update automation scripts |
| `RELEASING.md` | Release process documentation |

## NixOS Integration

```nix
# In your flake.nix
{
  inputs.code-cursor-nix.url = "github:jacopone/code-cursor-nix";
}

# In your configuration
{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.code-cursor-nix.overlays.default ];
  environment.systemPackages = [ pkgs.cursor ];
}
```

## Testing

```bash
# Build package
nix build

# Run flake checks
nix flake check

# Test in shell
nix shell . -c cursor --version
```

## Maintenance Notes

- Uses `inputs.nixpkgs.follows` for consistency with consumer's nixpkgs
- Cursor is unfree: `config.allowUnfree = true` required
- Browser automation support included (Chrome/Chromium)

---

## User Memory

<!-- USER_MEMORY_START -->
<!-- USER_MEMORY_END -->
