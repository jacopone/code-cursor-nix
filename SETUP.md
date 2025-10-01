# cursor-nix Setup Guide

## Quick Start

This repository provides an auto-updating Nix flake for Cursor, inspired by claude-code-nix.

## Step 1: Create GitHub Repository

```bash
# Create a new repository on GitHub named 'cursor-nix'
# Then clone and setup:

git clone https://github.com/jacopone/cursor-nix
cd cursor-nix

# Copy all files from /tmp/cursor-nix to your repository
cp -r /tmp/cursor-nix/* .
cp -r /tmp/cursor-nix/.github .
cp /tmp/cursor-nix/.gitignore .

# Update README.md and replace jacopone with your GitHub username
sed -i 's/jacopone/your-actual-username/g' README.md
sed -i 's/jacopone/your-actual-username/g' flake.nix

# Initialize git and push
git add .
git commit -m "Initial commit: Auto-updating Cursor Nix flake"
git push origin main
```

## Step 2: Enable GitHub Actions

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Actions** → **General**
3. Under "Workflow permissions", select **Read and write permissions**
4. Check **Allow GitHub Actions to create and approve pull requests**
5. Click **Save**

## Step 3: Enable Auto-merge (Optional but Recommended)

1. Go to **Settings** → **General**
2. Scroll to **Pull Requests**
3. Check **Allow auto-merge**
4. Click **Save**

## Step 4: First Run

The workflow runs automatically every hour, but you can trigger it manually:

1. Go to **Actions** tab
2. Click on **Auto-update Cursor** workflow
3. Click **Run workflow** → **Run workflow**

## Step 5: Update Your NixOS Config

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

Then rebuild:

```bash
sudo nixos-rebuild switch --flake .
```

## How the Auto-Update Works

### Version Detection
- Queries Cursor's official API every hour
- API endpoint: `https://api2.cursor.sh/updates/api/download/stable/{platform}/cursor`
- Returns version, download URL, and commit SHA

### Multi-Platform Support
Checks all platforms simultaneously:
- `linux-x64` (x86_64-linux)
- `linux-arm64` (aarch64-linux)
- `darwin-x64` (x86_64-darwin)
- `darwin-arm64` (aarch64-darwin)

### Update Process
1. **Check**: Compares current version in `package.nix` with API response
2. **Download**: Uses `nix-prefetch-url` to download all platforms
3. **Hash**: Calculates SRI hashes with `nix-hash`
4. **Update**: Modifies `package.nix` with new version and hashes
5. **Test**: Builds on Linux x86_64 and runs flake checks
6. **PR**: Creates pull request with all changes
7. **Auto-merge**: Merges automatically if tests pass

### Workflow Schedule
```yaml
schedule:
  - cron: '0 * * * *'  # Every hour at :00
```

## Manual Update

To manually update:

```bash
# Clone the repository
git clone https://github.com/jacopone/cursor-nix
cd cursor-nix

# Run update script
./scripts/update-version.sh

# The script will:
# - Check current version
# - Query API for latest version
# - Download and calculate hashes for all platforms
# - Update package.nix
# - Update flake.lock

# Test the build
nix build .#cursor

# Commit and push
git add .
git commit -m "chore: update cursor to $(grep -oP 'version = "\K[^"]+' package.nix | head -1)"
git push
```

## Testing Locally

```bash
# Test API connectivity
./scripts/test-api.sh

# Test package build
nix build .#cursor --print-build-logs

# Run cursor without installing
nix run .#cursor

# Enter development shell
nix develop
```

## Troubleshooting

### Script fails with "jq: parse error"
- Check internet connectivity
- Verify API is accessible: `curl -s "https://api2.cursor.sh/updates/api/download/stable/linux-x64/cursor" | jq .`

### "Failed to download" error
- Cursor might have changed their URL structure
- Check the download URL manually
- Open an issue on the repository

### GitHub Actions fails
- Check workflow permissions (Step 2)
- Verify the GITHUB_TOKEN has write access
- Check workflow logs for specific errors

### Build fails
- The AppImage might be corrupted
- Run `nix build .#cursor --print-build-logs` for details
- Try clearing nix store: `nix-collect-garbage -d`

## Comparison with Alternatives

| Feature | cursor-nix | nixpkgs | AppImage |
|---------|-----------|---------|----------|
| Update speed | ~30 min | Days/weeks | Immediate |
| Automation | Full | Manual PRs | None |
| Testing | Automated | Manual | None |
| Multi-platform | Yes | Yes | Linux only |
| Nix integration | Perfect | Perfect | Poor |

## Architecture

```
cursor-nix/
├── flake.nix                 # Main Nix flake
├── package.nix               # Cursor package definition
├── scripts/
│   ├── update-version.sh    # Main update script
│   └── test-api.sh          # API testing utility
├── .github/
│   └── workflows/
│       └── update.yml       # GitHub Actions workflow
├── README.md                # User documentation
├── SETUP.md                 # This file
└── LICENSE                  # MIT license
```

## Key Differences from claude-code-nix

### Similarities
- Hourly GitHub Actions workflow
- Automatic PR creation and merging
- SRI hash calculation
- Multi-platform support

### Differences
- **API**: Cursor uses REST API vs npm registry for Claude Code
- **Format**: AppImage/DMG vs npm tarball
- **Platforms**: 4 platforms (including Darwin) vs Linux-focused
- **Version detection**: JSON API vs npm metadata

## Contributing

See [README.md](README.md) for contribution guidelines.

## Support

- **Issues**: https://github.com/jacopone/cursor-nix/issues
- **Discussions**: https://github.com/jacopone/cursor-nix/discussions
- **Cursor Official**: https://cursor.com

## License

MIT - See [LICENSE](LICENSE)
