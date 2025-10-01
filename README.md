# cursor-nix

> Auto-updating Nix Flake for [Cursor](https://cursor.com) - The AI Code Editor

[![Update Cursor](https://github.com/jacopone/cursor-nix/actions/workflows/update.yml/badge.svg)](https://github.com/jacopone/cursor-nix/actions/workflows/update.yml)

## Features

- 🚀 **Auto-updating**: Checks for new Cursor releases every hour via GitHub Actions
- 📦 **Multi-platform**: Supports Linux (x86_64, aarch64) and macOS (x86_64, aarch64)
- ⚡ **Fast**: New versions available within 30 minutes of official release
- 🔐 **Reliable**: Automatic hash verification and build testing
- 🤖 **Automated PRs**: Creates and auto-merges PRs when tests pass

## Installation

### NixOS (Flakes)

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cursor-nix.url = "github:jacopone/cursor-nix";
  };

  outputs = { self, nixpkgs, cursor-nix, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          environment.systemPackages = [
            cursor-nix.packages.x86_64-linux.cursor
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
    cursor-nix.url = "github:jacopone/cursor-nix";
  };

  outputs = { self, nixpkgs, home-manager, cursor-nix, ... }: {
    homeConfigurations.your-user = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        {
          home.packages = [
            cursor-nix.packages.x86_64-linux.cursor
          ];
        }
      ];
    };
  };
}
```

### Try without installing

```bash
nix run github:jacopone/cursor-nix
```

## Usage

After installation, launch Cursor from your application menu or run:

```bash
cursor
```

## Version Management

This flake automatically tracks the latest stable version of Cursor. To manually update:

```bash
# Update the flake lock
nix flake update cursor-nix

# Rebuild your system
sudo nixos-rebuild switch --flake .
```

## How It Works

1. **Hourly checks**: GitHub Actions runs every hour to check for new Cursor versions
2. **Version detection**: Queries Cursor's official API: `https://api2.cursor.sh/updates/api/download/stable/{platform}/cursor`
3. **Multi-platform support**: Downloads and verifies hashes for all supported platforms
4. **Automated testing**: Builds the package on Linux x86_64 and runs flake checks
5. **Pull requests**: Creates a PR with the update, which auto-merges if all tests pass
6. **Fast delivery**: New versions typically available within 30 minutes of official release

## Manual Updates

To manually trigger an update:

```bash
# Clone the repository
git clone https://github.com/jacopone/cursor-nix
cd cursor-nix

# Run the update script
./scripts/update-version.sh

# Test the build
nix build .#cursor
```

## Comparison with Other Approaches

| Method | Update Speed | Reliability | Platforms |
|--------|-------------|-------------|-----------|
| **cursor-nix** | ~30 minutes | Automated testing | Linux, macOS |
| nixpkgs (code-cursor) | Days to weeks | Manual review | Linux, macOS |
| omarcresp/cursor-flake | Manual updates | Community-driven | Linux, macOS |
| Direct AppImage | Immediate | Manual | Linux only |

## Inspired By

This project is inspired by [sadjow/claude-code-nix](https://github.com/sadjow/claude-code-nix), which provides similar auto-updating functionality for Claude Code.

## Contributing

Contributions are welcome! Feel free to:

- Report issues
- Submit pull requests
- Improve documentation
- Add platform support

## License

MIT License - see [LICENSE](LICENSE) for details.

Cursor itself is proprietary software. This repository only provides a Nix packaging wrapper.

## Maintainers

- [@jacopone](https://github.com/jacopone)

## See Also

- [Cursor Official Site](https://cursor.com)
- [Cursor Changelog](https://www.cursor.com/changelog)
- [claude-code-nix](https://github.com/sadjow/claude-code-nix) - Similar auto-updating flake for Claude Code
