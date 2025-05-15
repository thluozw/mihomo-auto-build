# 使用 Alpine Linux 作为基础镜像
FROM alpine:latest as builder

# 安装必要工具
RUN apk add --no-cache \
    curl \
    tar \
    jq \
    && rm -rf /var/cache/apk/*

# 自动获取最新release版本
RUN LATEST_VERSION=$(curl -sL https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | jq -r '.tag_name') \
    && echo "最新检测到版本: $LATEST_VERSION" \
    && case $(uname -m) in \
        "x86_64") ARCH=amd64 ;; \
        "aarch64") ARCH=arm64 ;; \
        *) echo "不支持的架构"; exit 1 ;; \
       esac \
    && curl -LO "https://github.com/MetaCubeX/mihomo/releases/download/${LATEST_VERSION}/mihomo-linux-${ARCH}-${LATEST_VERSION}.gz" \
    && gunzip "mihomo-linux-${ARCH}-${LATEST_VERSION}.gz" \
    && mv "mihomo-linux-${ARCH}-${LATEST_VERSION}" /mihomo \
    && chmod +x /mihomo

# 最终镜像
FROM alpine:latest

WORKDIR /etc/mihomo

COPY --from=builder /mihomo /usr/local/bin/mihomo

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    && adduser -D -u 1000 mihomo \
    && mkdir -p /etc/mihomo \
    && chown -R mihomo:mihomo /etc/mihomo

USER mihomo

EXPOSE 7890 7891 9090

HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -fsS http://127.0.0.1:9090 >/dev/null || exit 1

ENTRYPOINT ["mihomo", "run", "-c", "/etc/mihomo/config.yaml"]
