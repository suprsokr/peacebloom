# Peacebloom: TrinityCore 3.3.5 + Thorium Modding Platform
# Ubuntu 24.04 LTS with MySQL 8, supports ARM64 and AMD64

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies and MySQL
RUN apt-get update && \
    apt-get install -y \
    # Build essentials
    git \
    curl \
    clang \
    cmake \
    make \
    gcc \
    g++ \
    # TrinityCore dependencies
    libssl-dev \
    libbz2-dev \
    libreadline-dev \
    libncurses-dev \
    libboost-all-dev \
    # MySQL 8
    mysql-server \
    mysql-client \
    libmysqlclient-dev \
    # For TDB extraction
    p7zip-full \
    # Utilities
    sudo \
    vim \
    less \
    && rm -rf /var/lib/apt/lists/*

# Set clang as default compiler (better for TrinityCore on ARM64)
RUN update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100

# Create trinitycore user with sudo
RUN useradd -m -s /bin/bash trinitycore && \
    echo "trinitycore ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup MySQL directories
RUN mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld

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
