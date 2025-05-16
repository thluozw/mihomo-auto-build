#!/bin/bash
set -e  # 一旦出错立即退出

# 输出函数，用于统一格式化输出
log_info() {
    echo "ℹ️ ：$1"
}

log_success() {
    echo "✅ ：$1"
}

log_error() {
    echo "❌ ：$1" >&2
    exit 1
}

# 根据 TARGETARCH 环境变量设置架构
TARGETARCH=${TARGETARCH:-linux/amd64}
arch="unknown"
case "$TARGETARCH" in
    linux/amd64) arch="amd64";;
    linux/arm64) arch="arm64";;
    linux/386) arch="386";;
    linux/arm/v7) arch="arm7";;
    *) log_error "不支持的架构: $TARGETARCH";;
esac

log_info "目标架构: $arch"

# 获取最新版本信息
log_info "正在获取 Mihomo 的最新版本信息..."
latest_version=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | jq -r '.tag_name')
if [ -z "$latest_version" ]; then
    log_error "无法获取 Mihomo 的最新版本信息。"
fi
log_success "最新版本: $latest_version"

# 构建精确的下载链接模式
download_pattern="mihomo-linux-${arch}-${latest_version}.gz"
log_info "正在查找匹配的下载链接: $download_pattern"

# 获取下载链接
link=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | \
    jq -r --arg pattern "$download_pattern" '.assets[] | select(.name == $pattern) | .browser_download_url')

if [ -z "$link" ]; then
    log_error "未找到匹配的下载链接: $download_pattern"
fi

log_success "下载链接: $link"

# 使用 curl 下载
log_info " 📥 正在下载 Mihomo..."
curl -L --progress-bar "$link" -o mihomo.gz || log_error "下载失败，请检查网络连接或重试。"

# 解压
log_info " 📦 正在解压缩文件..."
gunzip -c mihomo.gz > mihomo || log_error "解压缩失败，请检查文件完整性。"
chmod +x mihomo
rm -f mihomo.gz

log_success "Mihomo 成功安装！"
