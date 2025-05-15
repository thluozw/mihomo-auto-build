#!/bin/bash
# entrypoint.sh
set -eo pipefail

REPO="MetaCubeX/mihomo"
BIN_NAME="mihomo"
INSTALL_DIR="/app/bin"
CACHE_DIR="/app/cache"

# 处理镜像源
GITHUB_BASE="${GITHUB_MIRROR:-https://github.com}"
API_URL="${GITHUB_BASE}/repos/${REPO}/releases/latest"

detect_platform() {
    case $(uname -m) in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l)  echo "armv7" ;;
        i386)    echo "386" ;;
        *)       echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
    esac
}

get_latest_version() {
    local retry=3
    while [ $retry -gt 0 ]; do
        response=$(curl -sL -w "%{http_code}" "$API_URL" -o /tmp/response)
        if [ "$response" -eq 200 ]; then
            jq -r '.tag_name' /tmp/response | tr -d 'v'
            return 0
        fi
        retry=$((retry-1))
        sleep 5
    done
    echo "Failed to get version after 3 retries" >&2
    exit 1
}

main() {
    ARCH=$(detect_platform)
    BIN_PATH="${INSTALL_DIR}/${BIN_NAME}"
    CACHE_FILE="${CACHE_DIR}/version-${ARCH}.txt"

    echo "⌛ Checking updates..."
    LATEST_VERSION=$(get_latest_version)
    [ -z "$LATEST_VERSION" ] && exit 1

    if [[ -f "$CACHE_FILE" ]]; then
        CACHED_VERSION=$(cat "$CACHE_FILE")
        if [[ "$LATEST_VERSION" == "$CACHED_VERSION" ]]; then
            echo "✅ Already latest version: v$LATEST_VERSION"
            return 0
        fi
    fi

    echo "🔄 New version found: v$LATEST_VERSION"
    ASSET_URL="${GITHUB_BASE}/${REPO}/releases/download/v${LATEST_VERSION}/mihomo-linux-${ARCH}-v${LATEST_VERSION}.gz"
    
    echo "⏬ Downloading binary..."
    if ! curl -L -f "$ASSET_URL" -o "/tmp/mihomo.gz"; then
        echo "❌ Download failed: $ASSET_URL" >&2
        exit 1
    fi

    echo "📦 Extracting files..."
    gunzip -c "/tmp/mihomo.gz" > "$BIN_PATH"
    chmod +x "$BIN_PATH"
    echo "$LATEST_VERSION" > "$CACHE_FILE"
    echo "🎉 Update completed!"
}

main || exit 1

echo "🚀 Starting Mihomo..."
exec "$BIN_PATH" run -c "${MIHOMO_HOME}/config.yaml"
