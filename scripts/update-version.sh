#!/usr/bin/env bash
# Auto-update script for cursor-nix
# Based on claude-code-nix update mechanism

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="$SCRIPT_DIR/../package.nix"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check for required tools
for cmd in curl jq nix-prefetch-url nix-hash; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        exit 1
    fi
done

# Platforms mapping
# Only update current system platform (x86_64-linux)
declare -A PLATFORMS=(
    ["x86_64-linux"]="linux-x64"
)

# URL templates based on platform
declare -A URL_TEMPLATES=(
    ["x86_64-linux"]="linux/x64/Cursor-VERSION-x86_64.AppImage"
)

# Get current version from package.nix
get_current_version() {
    grep -oP 'version = "\K[^"]+' "$PACKAGE_FILE" | head -1
}

# Query Cursor API for latest version
get_latest_version() {
    local platform="$1"
    local api_platform="${PLATFORMS[$platform]}"

    log_info "Checking API for platform: $api_platform"

    local url="https://api2.cursor.sh/updates/api/download/stable/$api_platform/cursor"
    local response
    local http_code

    # Use temp file to avoid mixing stdout/stderr
    local temp_file=$(mktemp)
    http_code=$(curl -sS -w "%{http_code}" -o "$temp_file" "$url")
    local curl_status=$?
    response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [ $curl_status -ne 0 ]; then
        log_error "Failed to fetch version info from API (curl exit code: $curl_status)"
        log_error "URL: $url"
        log_error "HTTP code: $http_code"
        return 1
    fi

    if [ "$http_code" != "200" ]; then
        log_error "HTTP error from API (code: $http_code)"
        log_error "URL: $url"
        log_error "Response: ${response:0:500}"
        return 1
    fi

    # Validate JSON
    if ! echo "$response" | jq empty 2>/dev/null; then
        log_error "Invalid JSON response from API"
        log_error "URL: $url"
        log_error "Response (first 500 chars): ${response:0:500}"
        return 1
    fi

    echo "$response"
}

# Extract information from API response
extract_version() {
    local response="$1"
    echo "$response" | jq -r '.version'
}

extract_download_url() {
    local response="$1"
    local platform="$2"

    case "$platform" in
        x86_64-linux|aarch64-linux)
            echo "$response" | jq -r '.downloadUrl'
            ;;
        x86_64-darwin|aarch64-darwin)
            echo "$response" | jq -r '.downloadUrl // empty'
            if [ -z "$(echo "$response" | jq -r '.downloadUrl // empty')" ]; then
                # Construct URL from commit sha and version
                local commitSha=$(echo "$response" | jq -r '.commitSha')
                local version=$(echo "$response" | jq -r '.version')
                local url_template="${URL_TEMPLATES[$platform]}"
                echo "https://downloads.cursor.com/production/$commitSha/${url_template//VERSION/$version}"
            fi
            ;;
    esac
}

# Check if URL is available (returns HTTP 200)
check_url_availability() {
    local url="$1"
    local platform="$2"

    log_info "Checking availability for $platform: $url"

    local http_code
    http_code=$(curl -sS -o /dev/null -w "%{http_code}" -I "$url")
    local curl_status=$?

    if [ $curl_status -ne 0 ]; then
        log_warn "Failed to check URL availability (curl exit code: $curl_status)"
        return 1
    fi

    if [ "$http_code" = "200" ]; then
        log_info "✓ URL is available (HTTP $http_code)"
        return 0
    else
        log_warn "✗ URL not available (HTTP $http_code)"
        return 1
    fi
}

# Calculate hash for a given URL
calculate_hash() {
    local url="$1"
    local platform="$2"

    log_info "Downloading and calculating hash for $platform..."

    local temp_file
    temp_file=$(nix-prefetch-url "$url" 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_error "Failed to download: $url"
        return 1
    fi

    local hash
    hash=$(nix-hash --to-sri --type sha256 "$temp_file")

    log_info "Hash for $platform: $hash"
    echo "$hash"
}

# Update package.nix with new version and hashes
update_package_file() {
    local version="$1"
    shift
    local -n hashes=$1
    shift
    local -n urls=$1

    log_info "Updating package.nix to version $version..."

    # Create backup
    cp "$PACKAGE_FILE" "$PACKAGE_FILE.bak"

    # Update version
    sed -i "s/version = \"[^\"]*\"/version = \"$version\"/" "$PACKAGE_FILE"

    # Update URLs and hashes for each platform
    for platform in "${!PLATFORMS[@]}"; do
        local url="${urls[$platform]}"
        local hash="${hashes[$platform]}"

        # Extract commit sha from URL
        local commitSha=$(echo "$url" | grep -oP 'production/\K[^/]+' | head -1)

        # Update URL (replace commit sha in the URL)
        sed -i "s|production/[^/]*/\(${URL_TEMPLATES[$platform]//VERSION/\$\{version\}}\)|production/$commitSha/\1|g" "$PACKAGE_FILE"

        # Update hash
        sed -i "/${platform} = fetchurl/,/hash = /s|hash = \"[^\"]*\"|hash = \"$hash\"|" "$PACKAGE_FILE"
    done

    log_info "Package file updated successfully"
}

# Main update logic
main() {
    local current_version
    current_version=$(get_current_version)
    log_info "Current version: $current_version"

    # Check version from the first platform
    local first_platform="x86_64-linux"
    local response
    response=$(get_latest_version "$first_platform")

    local latest_version
    latest_version=$(extract_version "$response")
    log_info "Latest version: $latest_version"

    # Check if update is needed
    if [ "$current_version" = "$latest_version" ]; then
        log_info "Already at latest version ($latest_version)"
        exit 0
    fi

    log_info "Update available: $current_version -> $latest_version"

    # Collect version info for all platforms
    declare -A platform_urls
    declare -A platform_hashes
    declare -A platform_versions

    # First pass: Collect URLs and check availability
    log_info "=== Phase 1: Collecting URLs and checking availability ==="
    local all_available=true
    for platform in "${!PLATFORMS[@]}"; do
        log_info "Processing platform: $platform"

        local platform_response
        platform_response=$(get_latest_version "$platform")

        local platform_version
        platform_version=$(extract_version "$platform_response")

        # Verify all platforms have the same version
        if [ "$platform_version" != "$latest_version" ]; then
            log_error "Version mismatch: $platform has version $platform_version, expected $latest_version"
            exit 1
        fi

        platform_versions[$platform]="$platform_version"

        local download_url
        download_url=$(extract_download_url "$platform_response" "$platform")
        platform_urls[$platform]="$download_url"

        log_info "Download URL for $platform: $download_url"

        # Check URL availability
        if ! check_url_availability "$download_url" "$platform"; then
            log_warn "Platform $platform is not yet available for version $latest_version"
            all_available=false
        fi
    done

    # If any platform is unavailable, skip this update
    if [ "$all_available" = false ]; then
        log_warn "Not all platforms are available yet for version $latest_version"
        log_warn "Skipping update. Will retry on next run."
        exit 0
    fi

    # Second pass: Download and calculate hashes
    log_info "=== Phase 2: Downloading and calculating hashes ==="
    for platform in "${!PLATFORMS[@]}"; do
        local download_url="${platform_urls[$platform]}"

        # Calculate hash
        local hash
        hash=$(calculate_hash "$download_url" "$platform")
        platform_hashes[$platform]="$hash"
    done

    # Update package file with all the new information
    update_package_file "$latest_version" platform_hashes platform_urls

    # Update flake.lock
    log_info "Updating flake.lock..."
    nix flake update

    log_info "✓ Update completed successfully!"
    log_info "Version: $current_version -> $latest_version"

    # Clean up backup
    rm -f "$PACKAGE_FILE.bak"
}

# Run main function
main "$@"
