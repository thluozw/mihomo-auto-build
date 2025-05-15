#!/bin/bash
set -eo pipefail

# 环境变量配置
REPO="MetaCubeX/mihomo"
BIN_NAME="mihomo"
CACHE_DIR="/app/cache"
API_URL="${GITHUB_MIRROR}/https://api.github.com/repos/${REPO}/releases/latest"

# 系统检测与容错
detect_platform() {
    case $(uname -s) in
        Linux*)   OS="linux" ;;
        Darwin*)  OS="darwin"; echo "⚠️ 警告：Docker容器内运行macOS二进制可能存在兼容性问题" >&2 ;;
        FreeBSD*) OS="freebsd" ;;
        *)        OS="unknown"; echo "❌ 不支持的OS类型: $(uname -s)" >&2; exit 1 ;;
    esac

    case $(uname -m) in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l)  ARCH="armv7" ;;
        i386)    ARCH="386" ;;
        *)       ARCH="unknown"; echo "❌ 不支持的架构: $(uname -m)" >&2; exit 1 ;;
    esac

    echo "${OS}-${ARCH}"
}

# 哈希校验增强
verify_hash() {
    local file="$1"
    local expected_hash=$(curl -sL "${ASSET_URL}.sha256" | cut -d' ' -f1)
    local actual_hash=$(sha256sum "$file" | cut -d' ' -f1)

    if [[ "$expected_hash" != "$actual_hash" ]]; then
        echo "❌ 哈希校验失败 (预期:${expected_hash:0:8} 实际:${actual_hash:0:8})" >&2
        return 1
    fi
}

# 主逻辑
main() {
    PLATFORM=$(detect_platform)
    CACHE_FILE="${CACHE_DIR}/${BIN_NAME}-${PLATFORM}.info"
    BIN_PATH="/app/bin/${BIN_NAME}"
    
    # 自动创建用户目录
    mkdir -p "${MIHOMO_HOME}" "${CACHE_DIR}"
    
    # 获取版本信息
    echo "⌛ 正在检查更新 (镜像源: ${GITHUB_MIRROR})..."
    LATEST_INFO=$(curl -sL "${API_URL}")
    LATEST_VERSION=$(jq -r '.tag_name' <<< "$LATEST_INFO")
    ASSET_NAME="${BIN_NAME}-${PLATFORM}-${LATEST_VERSION}.gz"
    ASSET_URL="${GITHUB_MIRROR}/${REPO}/releases/download/${LATEST_VERSION}/${ASSET_NAME}"

    # 版本比对逻辑
    if [[ -f "$CACHE_FILE" ]]; then
        CACHED_VERSION=$(jq -r .version $CACHE_FILE)
        CACHED_HASH=$(jq -r .hash $CACHE_FILE)
        
        if [[ "$LATEST_VERSION" == "$CACHED_VERSION" ]]; then
            echo "✅ 已是最新版本: $LATEST_VERSION"
            return 0
        fi
    fi

    # 下载与更新
    echo "🔄 发现新版本: $LATEST_VERSION ⇒ 下载中..."
    curl -L -o "/tmp/${ASSET_NAME}" "$ASSET_URL"
    
    # 解压与校验
    gunzip -c "/tmp/${ASSET_NAME}" > "${BIN_PATH}.new"
    chmod +x "${BIN_PATH}.new"
    verify_hash "${BIN_PATH}.new" || exit 1
    
    # 原子替换
    mv "${BIN_PATH}.new" "$BIN_PATH"
    jq -n \
        --arg version "$LATEST_VERSION" \
        --arg hash "$(sha256sum "$BIN_PATH" | cut -d' ' -f1)" \
        '{version: $version, hash: $hash}' > "$CACHE_FILE"

    echo "🎉 更新完成！"
}

# 启动流程
main || exit 1
echo "🚀 启动 Mihomo (配置目录: ${MIHOMO_HOME})..."
exec "$BIN_PATH" run -c "${MIHOMO_HOME}/config.yaml"
