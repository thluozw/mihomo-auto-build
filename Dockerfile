# 使用多阶段构建优化
FROM debian:bookworm-slim

# 安装核心依赖
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    jq \
    file \
    && rm -rf /var/lib/apt/lists/*

# 创建应用目录并设置权限
RUN mkdir -p /app/bin /app/cache /etc/mihomo \
    && useradd -m -u 1000 mihomo \
    && chown -R mihomo:mihomo /app \
    && chown -R mihomo:mihomo /etc/mihomo

# 设置环境变量（注意空值处理）
ENV MIHOMO_HOME="/etc/mihomo" \
    TZ="Asia/Shanghai" \
    GITHUB_MIRROR=""

WORKDIR /app

# 复制启动脚本并设置权限
COPY --chown=mihomo:mihomo entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

USER mihomo

# 暴露端口
EXPOSE 7890 7891 9090

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -fsS http://localhost:9090 >/dev/null || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
