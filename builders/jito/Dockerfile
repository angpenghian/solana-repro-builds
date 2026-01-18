FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Build deps based on prior Jito playbooks + common Rust build tooling
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    build-essential \
    libssl-dev \
    libudev-dev \
    pkg-config \
    zlib1g-dev \
    llvm \
    clang \
    libclang-dev \
    cmake \
    make \
    libprotobuf-dev \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Install Rust (stable)
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y
ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH="${CARGO_HOME}/bin:${PATH}"
RUN rustup component add rustfmt

WORKDIR /work
