# 必须从 FROM 指令开始
FROM debian:bookworm-slim

# 安装核心依赖
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    jq \
    gzip \
    iproute2 \
    net-tools \
    procps \
    && rm -rf /var/lib/apt/lists/*


# 设置环境变量
ENV TZ="Asia/Shanghai" \
    GITHUB_MIRROR="" 

# 创建目录结构
RUN mkdir -p /etc/mihomo/{bin,cache} /etc/mihomo


WORKDIR /etc/mihomo

# 下载并解压最新版mihomo
RUN get_arch() { \
    case $(uname -m) in  \
        x86_64)  echo "amd64" ;;  \
        aarch64) echo "arm64" ;;  \
        armv7l)  echo "armv7" ;;  \
        i386)    echo "386" ;;  \
        *)       echo "unsupported"; exit 1 ;;  \
    esac  \
    }  \
    arch=$(get_arch) \
    links=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | grep browser_download_url | cut -d'"' -f4 |grep -E '.gz$' |grep 'linux' |grep ${arch}) \
    wget ${links} -o ./mihomo.gz \
    gunzip -c ./mihomo.gz > /etc/mihomo/mihomo \
    chmod +x /etc/mihomo/mihomo \
    rm -f ./mihomo.gz


# 复制启动脚本
COPY mihomo.service /etc/systemd/system/mihomo.service
COPY entrypoint.sh /etc/mihomo/
RUN chmod +x /etc/mihomo/entrypoint.sh \
    chmod +x /etc/systemd/system/mihomo.service \
    systemctl daemon-reload \
    systemctl enable mihomo \
    systemctl start mihomo

# 添加元数据
LABEL maintainer="yourname@example.com" \
      description="Mihomo Docker Image with macvlan support" \
      version="1.19.8"

# 暴露常用端口（Mihomo 默认使用这些端口）
EXPOSE 7890 7891 9090

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -fsS http://localhost:9090 >/dev/null || exit 1

ENTRYPOINT ["/etc/mihomo/entrypoint.sh"]
