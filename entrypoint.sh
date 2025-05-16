#!/bin/bash
set -eo pipefail

REPO="MetaCubeX/mihomo"
BIN_NAME="mihomo"
INSTALL_DIR="/etc/mihomo"
CACHE_DIR="/etc/mihomo/cache"

# 创建缓存目录
mkdir -p "$CACHE_DIR"
chmod 755 "$CACHE_DIR"

# 处理镜像源逻辑
if [[ -n "${GITHUB_MIRROR}" ]]; then
    GITHUB_BASE="${GITHUB_MIRROR%/}/"
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

# 获取最新版本
get_latest_version() {
    local version=""
    for i in {1..2}; do
        API_URL="https://api.github.com/repos/${REPO}/releases/latest"
        response=$(curl -fsSL -H "User-Agent: Docker-Mihomo-Installer" "$API_URL" || true)
        version=$(echo "$response" | jq -r '.tag_name // empty')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
        sleep $i
    done
    echo "$DEFAULT_VERSION"
}

# 主更新逻辑
update_binary() {
    ARCH=$(get_arch)
    CACHE_FILE="${CACHE_DIR}/${BIN_NAME}-${ARCH}.version"
    BIN_PATH="${INSTALL_DIR}/${BIN_NAME}"

    # 获取并验证版本号
    LATEST_VERSION=$(get_latest_version)
    if [[ -z "$LATEST_VERSION" ]]; then
        LATEST_VERSION="$DEFAULT_VERSION"
        echo "⚠️ 无法获取版本，使用默认: $LATEST_VERSION"
    fi

    echo "[INFO] 当前有效版本: $LATEST_VERSION"

    # 版本比对
    if [[ -f "$CACHE_FILE" ]]; then
        CACHED_VERSION=$(cat "$CACHE_FILE")
        if [[ "$LATEST_VERSION" == "$CACHED_VERSION" ]]; then
            echo "[INFO] 已是最新版本"
            return 0
        fi
    fi

    # 动态获取资产名称
    ASSET_NAME=$(echo "$response" | jq -r --arg arch "$ARCH" '.assets[] | select(.name | contains("linux-" + $arch)) | .name')
    ASSET_URL="${GITHUB_BASE}${REPO}/releases/download/${LATEST_VERSION}/${ASSET_NAME}"

    # 下载并替换
    echo "[INFO] 开始更新..."
    echo "[DEBUG] 下载地址: $ASSET_URL"
    curl -L -o "/tmp/mihomo.gz" "$ASSET_URL" || { echo "❌ 下载失败"; exit 1; }
    gunzip -c "/tmp/mihomo.gz" > "$BIN_PATH" || { echo "❌ 解压失败"; exit 1; }
    chmod +x "$BIN_PATH"
    echo "$LATEST_VERSION" > "$CACHE_FILE"
    rm -f "/tmp/mihomo.gz"
    echo "[INFO] 更新完成！"
}

# 启动流程
update_binary

# 网络配置（适用于 macvlan）
# 自动检测 IP 和网关
ETH0_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
ETH0_GATEWAY=$(ip route show default | awk '{print $3}')
ETH0_NETMASK=$(ip -4 addr show eth0 | grep -oP '(?<=prefixlen\s)\d+')

if [[ -n "$ETH0_IP" && -n "$ETH0_GATEWAY" ]]; then
    echo "[INFO] 容器 IP: $ETH0_IP"
    echo "[INFO] 网关: $ETH0_GATEWAY"
    # 设置默认网关
    ip route add default via "$ETH0_GATEWAY"
    # 设置 DNS
    echo "nameserver 223.5.5.5" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi

echo "🚀 启动 Mihomo..."
# 启动 Mihomo
exec "$INSTALL_DIR/$BIN_NAME" run -c "${INSTALL_DIR}/config.yaml" --listen 0.0.0.0
