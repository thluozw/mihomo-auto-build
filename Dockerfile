# 安装核心依赖
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gzip \
    jq \
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

EXPOSE 7890 7891 9090

HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -fsS http://localhost:9090 >/dev/null || exit 1

ENTRYPOINT ["/etc/mihomo/entrypoint.sh"]
