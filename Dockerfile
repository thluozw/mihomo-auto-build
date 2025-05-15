FROM debian:bookworm-slim

# 安装所有必需依赖
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gzip \
    jq \
    file \
    && rm -rf /var/lib/apt/lists/*

# 创建目录结构并设置权限
RUN mkdir -p /app/{bin,cache} /etc/mihomo \
    && useradd -m -u 1000 mihomo \
    && chown -R mihomo:mihomo /app /etc/mihomo

# 设置环境变量
ENV MIHOMO_HOME="/etc/mihomo" \
    GITHUB_MIRROR="" \
    TZ="Asia/Shanghai" \
    DEFAULT_VERSION="v1.19.8"  # 硬编码默认版本

WORKDIR /app
USER mihomo

# 复制启动脚本
COPY --chown=mihomo:mihomo entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

EXPOSE 7890 7891 9090

HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -fsS http://localhost:9090 >/dev/null || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
