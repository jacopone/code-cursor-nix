# code-cursor-nix

Auto-updating Nix Flake for Cursor AI editor -- AppImage extraction, FHS environment, browser automation included.

[![Update Cursor](https://github.com/jacopone/code-cursor-nix/actions/workflows/update.yml/badge.svg)](https://github.com/jacopone/code-cursor-nix/actions/workflows/update.yml)

## What This Provides

- **FHS environment** wrapping the upstream AppImage with all required libraries
- **Automated updates** via GitHub Actions (3x/week), with hash verification and build testing
- **Multi-platform** support for x86_64-linux, aarch64-linux, x86_64-darwin, and aarch64-darwin
- **Browser automation** on Linux -- bundles Chrome with `CHROME_BIN`/`CHROME_PATH` set for Playwright, Puppeteer, and Selenium

## Quick Start

```bash
nix run github:jacopone/code-cursor-nix
```

## Installation

### NixOS Configuration

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    code-cursor-nix.url = "github:jacopone/code-cursor-nix";
  };

  outputs = { self, nixpkgs, code-cursor-nix, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          environment.systemPackages = [
            code-cursor-nix.packages.x86_64-linux.cursor
          ];
        }
      ];
    };
  };
}
```

### Home Manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    code-cursor-nix.url = "github:jacopone/code-cursor-nix";
  };

  outputs = { self, nixpkgs, home-manager, code-cursor-nix, ... }: {
    homeConfigurations.your-user = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        {
          home.packages = [
            code-cursor-nix.packages.x86_64-linux.cursor
          ];
        }
      ];
    };
  };
}
```

## Version Pinning

```nix
# Follow latest (recommended)
inputs.code-cursor-nix.url = "github:jacopone/code-cursor-nix";

# Pin to a specific release
inputs.code-cursor-nix.url = "github:jacopone/code-cursor-nix/v2.0.34";
```

Update to the latest version:

```bash
nix flake update code-cursor-nix
```

All releases: https://github.com/jacopone/code-cursor-nix/releases

## Requirements

- Nix with flakes enabled
- `allowUnfree = true` (Cursor is proprietary software)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test with `nix build .#cursor` and `nix flake check`
4. Submit a pull request

## License

MIT License -- see [LICENSE](LICENSE) for details.

Cursor is proprietary software by Anysphere Inc. This is an unofficial package, not affiliated with or endorsed by Anysphere.
