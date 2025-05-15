#!/bin/bash
set -eo pipefail

REPO="MetaCubeX/mihomo"
BIN_NAME="mihomo"
INSTALL_DIR="/app/bin"
CACHE_DIR="/app/cache"

# 获取系统架构
get_arch() {
    case $(uname -m) in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l)  echo "armv7" ;;
        i386)    echo "386" ;;
        *)       echo "unsupported"; exit 1 ;;
    esac
}

# 获取最新版本（带重试机制）
get_latest_version() {
    for i in {1..3}; do
        if version=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name'); then
            echo "$version"
            return 0
        fi
        sleep $i
    done
    echo "$DEFAULT_VERSION"  # 回退到默认版本
}

# 主更新逻辑
update_binary() {
    ARCH=$(get_arch)
    CACHE_FILE="${CACHE_DIR}/${BIN_NAME}-${ARCH}.version"
    BIN_PATH="${INSTALL_DIR}/${BIN_NAME}"

    # 获取版本信息
    LATEST_VERSION=$(get_latest_version)
    echo "⌛ 最新检测版本: $LATEST_VERSION"

    # 检查缓存版本
    if [[ -f "$CACHE_FILE" ]]; then
        CACHED_VERSION=$(cat "$CACHE_FILE")
        if [[ "$LATEST_VERSION" == "$CACHED_VERSION" ]]; then
            echo "✅ 已是最新版本"
            return 0
        fi
    fi

    # 下载并替换二进制
    echo "🔄 开始更新..."
    ASSET_URL="https://github.com/${REPO}/releases/download/${LATEST_VERSION}/mihomo-linux-${ARCH}-${LATEST_VERSION}.gz"
    curl -L -o "/tmp/mihomo.gz" "$ASSET_URL"
    gunzip -c "/tmp/mihomo.gz" > "$BIN_PATH"
    chmod +x "$BIN_PATH"
    echo "$LATEST_VERSION" > "$CACHE_FILE"
    echo "🎉 更新完成！"
}

# 启动流程
update_binary
echo "🚀 启动 Mihomo..."
exec "$INSTALL_DIR/$BIN_NAME" run -c "${MIHOMO_HOME}/config.yaml"
