#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  echo "Usage: scripts/build_agave.sh <agave_tag>"
  echo "Example: scripts/build_agave.sh v3.0.0"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/dist/agave/${TAG}"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

echo "[+] Building Agave ${TAG} into ${OUT_DIR}"

docker build -t solana-repro-builds-agave -f "${ROOT_DIR}/builders/agave/Dockerfile" "${ROOT_DIR}/builders/agave"

docker run --rm -t \
  -v "${ROOT_DIR}:/repo" \
  -w /repo \
  solana-repro-builds-agave bash -lc "
    set -euo pipefail
    rm -rf /tmp/agave
    git clone --depth 1 --branch '${TAG}' https://github.com/anza-xyz/agave.git /tmp/agave
    cd /tmp/agave

    # Build from source per upstream guidance (Agave stopped shipping binaries from v3.0.0+)
    ./scripts/cargo-install-all.sh .

    mkdir -p '/repo/dist/agave/${TAG}/bin'
    cp -a ./bin/* '/repo/dist/agave/${TAG}/bin/'

    cd '/repo/dist/agave/${TAG}'
    tar -czf 'agave-${TAG}-linux-x86_64.tar.gz' bin
    sha256sum 'agave-${TAG}-linux-x86_64.tar.gz' > SHA256SUMS
  "

echo "[+] Done."
echo "Artifacts:"
ls -lah "${OUT_DIR}"
