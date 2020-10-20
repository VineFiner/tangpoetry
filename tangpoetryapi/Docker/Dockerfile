# ================================
# Build image, 构建镜像
# ================================
FROM swift:5.2-focal as build

# Install OS updates and, if needed, sqlite3， 装载系统更新，如果需要，安装 sqlite3
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area， 设置工作目录
WORKDIR /build

# First just resolve dependencies. 首先只解决依赖关系
# This creates a cached layer that can be reused 这将创建一个可重复使用的缓存层
# as long as your Package.swift/Package.resolved 只要解决依赖关系
# files do not change. 文件就不会改变
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container， 复制整个仓库到容器中
COPY . .

# Build everything, with optimizations and test discovery，通过优化和测试发现构建一切
RUN swift build --enable-test-discovery -c release

# Switch to the staging area，切换到暂存区
WORKDIR /staging

# Copy main executable to staging area，将主要可执行文件复制到暂存区
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/Run" ./

# Uncomment the next line if you need to load resources from the `Public` directory.
# Ensure that by default, neither the directory nor any of its contents are writable.
# 如果您需要从“公共”目录中加载资源，请取消注释下一行。
# 确保默认情况下，目录及其任何内容均不可写。
RUN mv /build/Public ./Public && chmod -R a-w ./Public

# ================================
# Run image
# ================================
FROM swift:5.2-focal-slim

# Make sure all system packages are up to date.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt-get -q update && apt-get -q dist-upgrade -y && rm -r /var/lib/apt/lists/*

# Create a vapor user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=vapor:vapor /staging /app

# Ensure all further commands run as the vapor user
USER vapor:vapor

# Let Docker bind to port 8080
EXPOSE 8080

# Start the Vapor service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
