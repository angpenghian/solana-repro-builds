#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  echo "Usage: scripts/build_jito.sh <jito_tag>"
  echo "Example: scripts/build_jito.sh v1.18.22-jito"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/dist/jito/${TAG}"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

echo "[+] Building Jito ${TAG} into ${OUT_DIR}"

docker build --platform=linux/amd64 -t solana-repro-builds-jito \
  -f "${ROOT_DIR}/builders/jito/Dockerfile" "${ROOT_DIR}/builders/jito"

docker run --rm --platform=linux/amd64 \
  -v "${ROOT_DIR}:/repo" \
  -w /repo \
  solana-repro-builds-jito bash -lc "
    set -euo pipefail
    rm -rf /tmp/jito-solana
    git clone --recurse-submodules https://github.com/jito-foundation/jito-solana.git /tmp/jito-solana
    cd /tmp/jito-solana
    git fetch --tags
    git checkout "tags/${TAG}"
    git submodule update --init --recursive

    # Build from source per upstream guidance (validator-only install)
    CI_COMMIT=\$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only \
      ~/.local/share/solana/install/releases/${TAG}

    INSTALL_ROOT=\"/root/.local/share/solana/install/releases/${TAG}\"
    BIN_DIR=\"\${INSTALL_ROOT}/bin\"
    if [[ ! -d \"\${BIN_DIR}\" ]]; then
      echo \"[!] Install bin directory not found at \${BIN_DIR}. Build may have failed.\"
      exit 1
    fi

    mkdir -p '/repo/dist/jito/${TAG}/bin'
    cp -a \"\${BIN_DIR}/.\" '/repo/dist/jito/${TAG}/bin/'

    cd '/repo/dist/jito/${TAG}'
    tar -czf 'jito-${TAG}-linux-x86_64.tar.gz' bin
    sha256sum 'jito-${TAG}-linux-x86_64.tar.gz' > SHA256SUMS
  "

echo "[+] Done."
echo "Artifacts:"
ls -lah "${OUT_DIR}"
