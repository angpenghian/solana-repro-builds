#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  echo "Usage: scripts/build_frankendancer.sh <firedancer_tag>"
  echo "Example: scripts/build_frankendancer.sh v0.809.30106"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/dist/frankendancer/${TAG}"
JOBS="${JOBS:-2}"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

echo "[+] Building Frankendancer ${TAG} into ${OUT_DIR}"

docker build --platform=linux/amd64 -t solana-repro-builds-frankendancer \
  -f "${ROOT_DIR}/builders/frankendancer/Dockerfile" "${ROOT_DIR}/builders/frankendancer"

docker run --rm --platform=linux/amd64 \
  -v "${ROOT_DIR}:/repo" \
  -w /repo \
  solana-repro-builds-frankendancer bash -lc "
    set -euo pipefail
    rm -rf /tmp/firedancer
    git clone --recurse-submodules https://github.com/firedancer-io/firedancer.git /tmp/firedancer
    cd /tmp/firedancer
    git fetch --tags
    git checkout "tags/${TAG}"
    git submodule update --init --recursive

    # Install deps and build Frankendancer binaries (mirror proven Ansible flow)
    # Limit Rust build parallelism and avoid jobserver fd errors from build scripts.
    export CARGO_BUILD_JOBS="${JOBS}"
    export CARGO_MAKEFLAGS="-j${JOBS}"
    echo 'y' | ./deps.sh
    make -j "${JOBS}" fdctl solana

    BIN_DIR='build/native/gcc/bin'
    if [[ ! -x \"\${BIN_DIR}/fdctl\" ]]; then
      echo \"[!] fdctl not found at \${BIN_DIR}. Build may have failed.\"
      exit 1
    fi

    mkdir -p '/repo/dist/frankendancer/${TAG}/bin'
    cp -a \"\${BIN_DIR}/fdctl\" '/repo/dist/frankendancer/${TAG}/bin/'
    if [[ -x \"\${BIN_DIR}/solana\" ]]; then
      cp -a \"\${BIN_DIR}/solana\" '/repo/dist/frankendancer/${TAG}/bin/'
    fi

    cd '/repo/dist/frankendancer/${TAG}'
    tar -czf 'frankendancer-${TAG}-linux-x86_64.tar.gz' bin
    sha256sum 'frankendancer-${TAG}-linux-x86_64.tar.gz' > SHA256SUMS
  "

echo "[+] Done."
echo "Artifacts:"
ls -lah "${OUT_DIR}"
