FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies based on prior Frankendancer playbooks
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    diffutils \
    build-essential \
    pkg-config \
    pkgconf \
    cmake \
    libclang-dev \
    libudev-dev \
    protobuf-compiler \
    autoconf \
    automake \
    autopoint \
    bison \
    flex \
    gcc-multilib \
    gettext \
    llvm \
    lcov \
    libgmp-dev \
    libprotobuf-dev \
    libssl-dev \
    perl \
    zlib1g-dev \
    zstd \
    clang \
    make \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Rust is required because Firedancer builds Agave components
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y
ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH="${CARGO_HOME}/bin:${PATH}"

WORKDIR /work
