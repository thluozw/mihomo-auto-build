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

# 创建目录结构
RUN mkdir -p /etc/mihomo/{bin,cache} /etc/mihomo

# 设置环境变量
ENV MIHOMO_HOME="/etc/mihomo" \
    TZ="Asia/Shanghai" \
    GITHUB_MIRROR="" \
    DEFAULT_VERSION="v1.19.8"

WORKDIR /etc/mihomo

# 复制启动脚本
COPY entrypoint.sh /etc/mihomo/
RUN chmod +x /etc/mihomo/entrypoint.sh

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
