#!/bin/sh
set -e

# 获取容器内mihomo的版本号
get_current_version() {
    local version=$(mihomo -v 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+')
    echo "$version"
}

# 获取GitHub最新版本号
get_latest_version() {
    local latest_version=$(curl -sSL https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | jq -r .tag_name)
    echo "$latest_version"
}

# 下载并解压二进制文件
download_and_extract() {
    local arch=$1
    local asset_name="mihomo-linux-${arch}.gz"
    local download_url=$(curl -sSL https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .browser_download_url')

    if [ -z "$download_url" ]; then
        echo -e "\033[31m[错误] 未找到对应架构的资产：$asset_name\033[0m"
        exit 1
    fi

    echo -e "\033[32m[调试] 下载并解压 $asset_name 到 /etc/mihomo...\033[0m"
    curl -L -o /tmp/mihomo.gz "$download_url"
    gunzip -f /tmp/mihomo.gz
    mv /tmp/mihomo /etc/mihomo/mihomo
    chmod +x /etc/mihomo/mihomo
}

# 检查是否需要更新
check_update() {
    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)

    if [ -z "$current_version" ]; then
        echo -e "\033[33m[调试] 当前版本未知，强制更新\033[0m"
        return 0
    fi

    if [ "$current_version" != "$latest_version" ]; then
        echo -e "\033[32m[调试] 检测到新版本：$latest_version（当前版本：$current_version）\033[0m"
        return 0
    else
        echo -e "\033[33m[调试] 当前已是最新版本：$current_version\033[0m"
        return 1
    fi
}

# 自动更新逻辑
auto_update() {
    local arch=$1
    if check_update; then
        echo -e "\033[32m[调试] 开始更新 mihomo...\033[0m"
        download_and_extract "$arch"
        echo -e "\033[32m[调试] 更新完成，重启服务...\033[0m"
        # 重启服务（通过重新运行自身脚本实现）
        exec "$0" "$@"
    fi
}

# 主函数
main() {
    local arch=$(uname -m)

    # 根据架构映射到GitHub的平台名称
    case "$arch" in
        x86_64) arch=amd64 ;;
        aarch64) arch=arm64 ;;
        arm) arch=armv7 ;;
        *) echo -e "\033[31m[错误] 不支持的架构：$arch\033[0m"; exit 1 ;;
    esac

    # 自动更新（每周检查一次）
    if [ "$(date +\%u)" = "1" ]; then
        auto_update "$arch"
    else
        echo -e "\033[33m[调试] 本周已更新过，跳过自动更新\033[0m"
    fi

    # 启动mihomo
    echo -e "\033[32m[调试] 启动 mihomo 服务...\033[0m"
    exec /etc/mihomo/mihomo -d /etc/mihomo/configs
}

# 执行主函数
main
