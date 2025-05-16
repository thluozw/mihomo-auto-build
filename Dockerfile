# 使用多阶段构建
FROM --platform=$TARGET_PLATFORM debian:bookworm-slim as builder

# 接收构建参数
ARG TARGET_PLATFORM

# 将构建参数设置为环境变量
ENV DOCKER_TARGETPLATFORM=${TARGETPLATFORM}

# 输出环境变量用于调试
RUN echo "ℹ️ 当前平台信息: $DOCKER_TARGETPLATFORM"

# 安装核心依赖
RUN apt-get update && \
    apt-get install -y \
        curl \
        ca-certificates \
        jq \
        gzip \
        iproute2 \
        net-tools \
        procps \
        cron \
        tzdata && \
    rm -rf /var/lib/apt/lists/*

# 设置环境变量
ENV TZ="Asia/Shanghai" \
    GITHUB_MIRROR="" 

# 创建目录结构
RUN mkdir -p /etc/mihomo/{bin,cache} /etc/mihomo

WORKDIR /etc/mihomo

# 复制并执行安装脚本
COPY install_mihomo.sh /etc/mihomo/
RUN chmod +x /etc/mihomo/install_mihomo.sh && \
    bash -c "set -o errexit -o nounset && DOCKER_TARGETPLATFORM=$DOCKER_TARGETPLATFORM /etc/mihomo/install_mihomo.sh"

# 获取 Mihomo 版本信息并写入 version.txt
RUN ./mihomo -v | grep -oP 'v\d+\.\d+\.\d+' | head -n 1 > /etc/mihomo/version.txt

# 复制启动脚本
COPY entrypoint.sh /etc/mihomo/
RUN chmod +x /etc/mihomo/entrypoint.sh

# 添加元数据
LABEL maintainer="yourname@example.com" \
      description="Mihomo Docker Image with macvlan support and auto-update feature" \
      version="1.19.8"

# 暴露常用端口
EXPOSE 7890 7891 9090

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -fsS http://localhost:9090 >/dev/null || exit 1

# 入口点
ENTRYPOINT ["/etc/mihomo/entrypoint.sh"]
