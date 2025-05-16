#!/bin/bash

# 根据 TARGETARCH 环境变量设置架构
TARGETARCH=${TARGETARCH:-linux/amd64}
arch="unknown"
case "$TARGETARCH" in
    linux/amd64) arch="amd64";;
    linux/arm64) arch="arm64";;
    linux/386) arch="386";;
    linux/arm/v7) arch="arm7";;
    *) echo "不支持的架构: $TARGETARCH" && exit 1;;
esac

echo "目标架构: $arch"

# 获取最新版本信息
link=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | \
    jq -r --arg arch "$arch" '.assets[] | select(.name | endswith(".gz") and contains("linux") and contains($arch)) | .browser_download_url')
if [ -z "$link" ]; then
    echo "未找到匹配的下载链接: $arch"
    exit 1
fi

wget --progress=bar:force "$link" -O mihomo.gz
gunzip -c mihomo.gz > mihomo
chmod +x mihomo
rm -f mihomo.gz
