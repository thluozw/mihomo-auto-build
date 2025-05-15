#!/bin/bash
set -eo pipefail

# 配置参数
REPO="MetaCubeX/mihomo"
BIN_NAME="mihomo"
INSTALL_DIR="/app/bin"
CACHE_DIR="/app/cache"

# 处理镜像源逻辑
if [[ -z "${GITHUB_MIRROR}" ]]; then
    GITHUB_BASE="https://github.com"
else
    GITHUB_BASE="${GITHUB_MIRROR%/}"  # 移除尾部斜杠
fi

API_URL="${GITHUB_BASE}/repos/${REPO}/releases/latest"

# 获取系统架构
detect_platform() {
    case $(uname -s) in
        Linux*)   OS="linux" ;;
        Darwin*)  OS="darwin"; echo "⚠️ macOS 二进制在容器内可能受限" >&2 ;;
        FreeBSD*) OS="freebsd" ;;
        *)        echo "❌ 不支持的OS: $(uname -s)" >&2; exit 1 ;;
    esac

    case $(uname -m) in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l)  ARCH="armv7" ;;
        i386)    ARCH="386" ;;
        *)       echo "❌ 不支持的架构: $(uname -m)" >&2; exit 1 ;;
    esac

    echo "${OS}-${ARCH}"
}

# 主逻辑
main() {
    PLATFORM=$(detect_platform)
    BIN_PATH="${INSTALL_DIR}/${BIN_NAME}"
    
    # 获取最新版本
    echo "⌛ 检查更新..."
    LATEST_INFO=$(curl -sL "${API_URL}")
    LATEST_VERSION=$(jq -r '.tag_name' <<< "$LATEST_INFO")
    ASSET_NAME="${BIN_NAME}-${PLATFORM}-${LATEST_VERSION}.gz"
    ASSET_URL="${GITHUB_BASE}/${REPO}/releases/download/${LATEST_VERSION}/${ASSET_NAME}"

    # 版本比对
    CACHE_FILE="${CACHE_DIR}/${BIN_NAME}-${PLATFORM}.info"
    if [[ -f "$CACHE_FILE" ]]; then
        CACHED_VERSION=$(jq -r .version $CACHE_FILE)
        if [[ "$LATEST_VERSION" == "$CACHED_VERSION" ]]; then
            echo "✅ 已是最新版本: $LATEST_VERSION"
            return 0
        fi
    fi

    # 下载更新
    echo "🔄 发现新版本: $LATEST_VERSION"
    curl -L -o "/tmp/${ASSET_NAME}" "$ASSET_URL"
    
    # 解压校验
    gunzip -c "/tmp/${ASSET_NAME}" > "${BIN_PATH}.new"
    chmod +x "${BIN_PATH}.new"
    sha256sum -c <(curl -sL "${ASSET_URL}.sha256") || exit 1
    
    # 应用更新
    mv "${BIN_PATH}.new" "$BIN_PATH"
    jq -n --arg v "$LATEST_VERSION" '{version: $v}' > "$CACHE_FILE"
    echo "🎉 更新完成！"
}

# 启动流程
main || exit 1
echo "🚀 启动 Mihomo (配置目录: ${MIHOMO_HOME})..."
exec "$BIN_PATH" run -c "${MIHOMO_HOME}/config.yaml"
