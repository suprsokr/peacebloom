# Peacebloom: TrinityCore 3.3.5 + Thorium Modding Platform
# Uses pre-built base image with Ubuntu 24.04 LTS, MySQL 8, and build dependencies
# Supports ARM64 and AMD64
#
# To rebuild base image: see Dockerfile.base

FROM suprsokr/peacebloom-base:24.04

# Create trinitycore user with sudo
RUN useradd -m -s /bin/bash trinitycore && \
    echo "trinitycore ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create directory structure
USER trinitycore
RUN mkdir -p /home/trinitycore/server/etc \
    /home/trinitycore/server/bin \
    /home/trinitycore/server/data

WORKDIR /home/trinitycore

# Download Thorium CLI from GitHub releases
# Detect architecture and download appropriate binary
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then THORIUM_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then THORIUM_ARCH="arm64"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi && \
    curl -L "https://github.com/suprsokr/thorium/releases/latest/download/thorium-linux-${THORIUM_ARCH}" -o /tmp/thorium && \
    chmod +x /tmp/thorium && \
    sudo mv /tmp/thorium /usr/local/bin/thorium

CMD ["/bin/bash"]
