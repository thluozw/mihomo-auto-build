#!/bin/sh

# 启动 cron 服务
service cron start

# 更新 Mihomo 函数
update_mihomo() {
    # 获取当前架构
    TARGETARCH=$(uname -m)
    case "$TARGETARCH" in
        x86_64) arch="amd64";;
        aarch64) arch="arm64";;
        i386) arch="386";;
        armv7l) arch="arm7";;
        *) echo "不支持的架构: $TARGETARCH" && exit 1;;
    esac

    # 获取最新版本信息
    latest_version=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | jq -r '.tag_name')
    current_version=$(cat /etc/mihomo/version.txt)

    if [ "$latest_version" != "$current_version" ]; then
        echo "检测到新版本: $latest_version"
        
        # 下载最新版本
        link=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | \
            jq -r --arg arch "$arch" '.assets[] | select(.name | endswith(".gz") and contains("linux") and contains($arch)) | .browser_download_url')
        if [ -z "$link" ]; then
            echo "未找到匹配的下载链接: $arch"
            exit 1
        fi
        
        wget --progress=bar:force "$link" -O /tmp/mihomo.gz
        gunzip -c /tmp/mihomo.gz > /etc/mihomo/mihomo
        chmod +x /etc/mihomo/mihomo
        rm -f /tmp/mihomo.gz
        
        # 更新版本号
        echo "$latest_version" > /etc/mihomo/version.txt
        
        echo "已更新至版本: $latest_version"
    else
        echo "已是最新版本: $current_version"
    fi
}

# 添加定时任务
mkdir -p /etc/cron.d
cat <<EOT > /etc/cron.d/mihomo_update
# 每天凌晨2点检查更新
0 2 * * * root /bin/bash -c "/etc/mihomo/update_mihomo" >> /var/log/mihomo_update.log 2>&1
EOT

# 确保日志目录存在
mkdir -p /var/log

# 第一次运行时立即检查更新
echo "正在检查是否有可用的更新..."
update_mihomo

# 启动 Mihomo
echo "启动 Mihomo..."
exec /etc/mihomo/mihomo -config /etc/mihomo/config.yaml
