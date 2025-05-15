#!/bin/bash
set -eo pipefail

REPO="MetaCubeX/mihomo"
BIN_NAME="mihomo"
INSTALL_DIR="/app/bin"
CACHE_DIR="/app/cache"

# 处理镜像源逻辑
if [[ -n "${GITHUB_MIRROR}" ]]; then
    GITHUB_BASE="${GITHUB_MIRROR%/}/https://github.com/"
else
    GITHUB_BASE="https://github.com/"
fi

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

# 获取最新版本（带镜像源容错）
get_latest_version() {
    for i in {1..3}; do
        #curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest
        #API_URL="${GITHUB_BASE}repos/${REPO}/releases/latest"
        API_URL="https://api.github.com/repos/${REPO}/releases/latest"
        echo "API_URL：$API_URL \n"
        if version=$(curl -fsSL "$API_URL" | jq -r '.tag_name'); then
            echo "$version"
            return 0
        fi
        echo "⚠️ 镜像源访问失败，尝试备用源 ($i/3)..."
        GITHUB_BASE="https://github.com/"  # 失败后切换官方源
        sleep $i
    done
    echo "$DEFAULT_VERSION"
}

# 主更新逻辑
update_binary() {
    ARCH=$(get_arch)
    CACHE_FILE="${CACHE_DIR}/${BIN_NAME}-${ARCH}.version"
    BIN_PATH="${INSTALL_DIR}/${BIN_NAME}"

    # 获取版本信息
    LATEST_VERSION=$(get_latest_version)
    echo "⌛ 检测到版本: $LATEST_VERSION \n"

    # 版本比对
    if [[ -f "$CACHE_FILE" ]]; then
        CACHED_VERSION=$(cat "$CACHE_FILE")
        if [[ "$LATEST_VERSION" == "$CACHED_VERSION" ]]; then
            echo "✅ 已是最新版本"
            return 0
        fi
    fi

    # 下载并替换
    echo "🔄 开始更新..."
    #https://ghfast.top/https://github.com/MetaCubeX/mihomo/releases/download/v1.19.8/mihomo-linux-arm64-v1.19.8.gz
    ASSET_URL="${GITHUB_BASE}${REPO}/releases/download/${LATEST_VERSION}/mihomo-linux-${ARCH}-${LATEST_VERSION}.gz"
    echo "下载地址：$ASSET_URL \n"
    curl -L -o "/tmp/mihomo.gz" "$ASSET_URL"
    sleep 5
    gunzip -c "/tmp/mihomo.gz" > "$BIN_PATH"
    chmod +x "$BIN_PATH"
    echo "$LATEST_VERSION" > "$CACHE_FILE \n"
    echo "🎉 更新完成！ \n"
}

# 启动流程
update_binary
echo "🚀 启动 Mihomo (镜像源: ${GITHUB_BASE})..."
exec "$INSTALL_DIR/$BIN_NAME" run -c "${MIHOMO_HOME}/config.yaml"
