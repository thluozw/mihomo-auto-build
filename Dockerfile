# 使用最小化Alpine基础镜像（约5MB）
FROM alpine:latest as base

# 安装必要依赖并打印调试信息
RUN echo -e "\033[32m[调试] 正在安装依赖...\033[0m" && \
    apk add --no-cache curl jq gzip && \
    echo -e "\033[32m[调试] 依赖安装完成：curl, jq, gzip\033[0m"

# 创建mihomo运行所需目录结构
RUN echo -e "\033[32m[调试] 正在创建目录结构...\033[0m" && \
    mkdir -p /etc/mihomo /etc/mihomo/configs && \
    echo -e "\033[32m[调试] 目录结构已创建：/etc/mihomo\033[0m"

# 设置工作目录并暴露端口
WORKDIR /etc/mihomo
EXPOSE 53 7890 7891 7892 9090 443 80 8080 4443

# 复制mihomo到指定目录
COPY mihomo /etc/mihomo/mihomo
RUN echo -e "\033[32m[调试] 设置mihomo执行权限...\033[0m" && \
    chmod +x /etc/mihomo/mihomo

# 复制entrypoint.sh脚本到指定目录
COPY entrypoint.sh /etc/mihomo/entrypoint.sh
RUN echo -e "\033[32m[调试] 设置entrypoint.sh执行权限...\033[0m" && \
    chmod +x /etc/mihomo/entrypoint.sh

# 设置启动入口
ENTRYPOINT ["/etc/mihomo/entrypoint.sh"]
