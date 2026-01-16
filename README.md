# solana-repro-builds

Automated **reproducible builds** + **verifiable release artifacts** for Solana validator clients:
- **Agave** (anza-xyz/agave)
- **Firedancer / Frankendancer** (firedancer-io/firedancer)

This project monitors upstream tags/releases and publishes build outputs as **GitHub Release assets** (tarballs + checksums).
It does **NOT** commit binaries into git history.

## Why this exists
- As of **Agave v3.0.0**, Anza no longer publishes the `agave-validator` binary; operators must build from source.  
- Firedancer does not provide pre-built binaries; releases are tags and must be built from source.

## What you get
For each supported upstream version, this repo publishes:
- `*.tar.gz` (binaries packaged)
- `SHA256SUMS` (checksums)

Future (roadmap):
- SBOM
- build provenance/attestations
- signatures (cosign)

## How to verify
See: `docs/VERIFYING.md`

## Trust model / disclaimer
This repo provides automated build artifacts for convenience. You should always verify checksums and provenance.
This project is not affiliated with Anza, Solana Foundation, or Jump Crypto.

## License
This repo (scripts/docs) is licensed under Apache-2.0.  
Upstream projects have their own licenses; compiled artifacts remain subject to upstream licensing and notices.
