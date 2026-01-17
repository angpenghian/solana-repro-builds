FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Basic deps commonly needed for Rust builds + Solana/Agave build tooling
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    libssl-dev \
    libudev-dev \
    pkg-config \
    zlib1g-dev \
    llvm \
    llvm-dev \
    clang \
    libclang-dev \
    cmake \
    make \
    protobuf-compiler \
    libprotobuf-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust (stable) - Agave builds from source; exact toolchain may change per tag
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y
ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH="${CARGO_HOME}/bin:${PATH}"

WORKDIR /work
