# Peacebloom: TrinityCore 3.3.5 + Thorium Modding Platform
# Uses pre-built base image with Ubuntu 24.04 LTS, MySQL 8, and build dependencies
# Supports ARM64 and AMD64
#
# To rebuild base image: see Dockerfile.base

FROM suprsokr/peacebloom-base:24.04

# Add peacebloom user to sudoers (user already exists in base image)
USER root
RUN grep -q "peacebloom ALL=(ALL) NOPASSWD:ALL" /etc/sudoers 2>/dev/null || \
    echo "peacebloom ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create directory structure and symlinks for convenience
USER root
RUN mkdir -p /home/peacebloom/server/etc \
    /home/peacebloom/server/bin && \
    chown -R peacebloom:peacebloom /home/peacebloom/server && \
    ln -s /home/peacebloom/mods /mods

USER peacebloom
WORKDIR /home/peacebloom

# Add scripts to PATH for easy access via docker exec
ENV PATH="/home/peacebloom/scripts:${PATH}"

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
