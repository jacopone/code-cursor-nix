#!/usr/bin/env bash
# Quick test of the Cursor API

set -euo pipefail

echo "Testing Cursor API endpoints..."
echo

for platform in "linux-x64" "linux-arm64" "darwin-x64" "darwin-arm64"; do
    echo "Platform: $platform"
    response=$(curl -sS "https://api2.cursor.sh/updates/api/download/stable/$platform/cursor")

    version=$(echo "$response" | jq -r '.version')
    url=$(echo "$response" | jq -r '.downloadUrl')

    echo "  Version: $version"
    echo "  URL: $url"
    echo
done
