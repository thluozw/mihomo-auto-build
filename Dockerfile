# 使用最小化多阶段构建
FROM debian:bookworm-slim as base

# 安装核心依赖（兼容 Alpine/CentOS/Ubuntu）
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    jq \
    file \
    && rm -rf /var/lib/apt/lists/*

# 创建分层目录结构
RUN mkdir -p /app/{bin,cache,config} \
    && useradd -m -u 1000 mihomo \
    && chown -R mihomo:mihomo /app

# 设置默认环境变量
ENV GITHUB_MIRROR="https://github.com" \
    MIHOMO_HOME="/app/config" \
    TZ="Asia/Shanghai"

WORKDIR /app
USER mihomo

# 复制智能启动脚本
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# 暴露常用端口
EXPOSE 7890 7891 9090

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -fsS http://localhost:9090 >/dev/null || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
