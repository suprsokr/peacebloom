# Peacebloom: TrinityCore 3.3.5 + Thorium Modding Platform
# Uses pre-built base image with Ubuntu 24.04 LTS, MySQL 8, and build dependencies
# Supports ARM64 and AMD64
#
# To rebuild base image: see Dockerfile.base

FROM suprsokr/peacebloom-base:24.04

# Create peacebloom user and add to sudoers
USER root
RUN useradd -m -s /bin/bash peacebloom && \
    echo "peacebloom ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create directory structure and symlinks for convenience
USER root
RUN mkdir -p /home/peacebloom/server/etc \
    /home/peacebloom/server/bin && \
    chown -R peacebloom:peacebloom /home/peacebloom/server && \
    ln -s /home/peacebloom/thorium-workspace /mods

USER peacebloom
WORKDIR /home/peacebloom

# Add scripts to PATH for easy access via docker exec
ENV PATH="/home/peacebloom/scripts:${PATH}"

# Download Thorium CLI from GitHub releases
# Detect architecture and download appropriate binary
USER root
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then THORIUM_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then THORIUM_ARCH="arm64"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi && \
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/suprsokr/thorium/releases/latest | grep '"browser_download_url":' | grep "linux-${THORIUM_ARCH}" | grep -o 'https://[^"]*' | head -1) && \
    if [ -z "$DOWNLOAD_URL" ]; then echo "Error: Could not find download URL for linux-${THORIUM_ARCH}" && exit 1; fi && \
    echo "Downloading Thorium from: $DOWNLOAD_URL" && \
    curl -L "$DOWNLOAD_URL" -o /tmp/thorium && \
    if [ ! -f /tmp/thorium ]; then echo "Error: Download failed" && exit 1; fi && \
    chmod +x /tmp/thorium && \
    mv /tmp/thorium /usr/local/bin/thorium && \
    if [ ! -f /usr/local/bin/thorium ]; then echo "Error: Installation failed" && exit 1; fi

USER peacebloom

CMD ["/bin/bash"]
