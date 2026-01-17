# solana-repro-builds

Automated, reproducible builds and verifiable release artifacts for Solana validator clients:
- **Agave** (anza-xyz/agave)
- **Firedancer / Frankendancer** (firedancer-io/firedancer) — planned

This project monitors upstream tags/releases and publishes build outputs as GitHub Release assets
(tarballs + checksums). Local builds are stored in `dist/` for verification and comparison.

## Vision
Solana validator clients stopped shipping binaries. This repo exists to provide a clean, repeatable,
supply-chain-friendly build pipeline that anyone can verify.

## Why this is trustworthy
- The checksum (hash) proves the file you downloaded is exactly what was published.
- Reproducible builds mean anyone can rebuild and get the same checksum.
- CI logs and build metadata make the process auditable.

## Current status
- Agave `v3.0.0` build works.
- SHA256 checksum verified.
- Linux smoke test verified.
- Reproducibility is **not** achieved yet (two rebuilds produced different binary hashes).
- GitHub Actions workflow exists to auto-build on a schedule.

## How it works (flowchart)
```
Upstream tags/releases
        |
        v
Scheduled tag check (CI cron)
        |
        v
Build in containerized environment
        |
        v
Package binaries (tar.gz)
        |
        v
Generate SHA256SUMS
        |
        v
Publish GitHub Release assets
```

## File structure
```
.
├─ .github/workflows/
│  └─ agave-auto-build.yml
├─ builders/
│  └─ agave/
│     └─ Dockerfile
├─ scripts/
│  └─ build_agave.sh
├─ dist/
│  └─ agave/
│     └─ <tag>/
│        ├─ agave-<tag>-linux-x86_64.tar.gz
│        ├─ SHA256SUMS
│        └─ bin/
└─ README.md
```

## Prerequisites
- Docker

## Build locally (Agave)
```bash
./scripts/build_agave.sh v3.0.0
```

## Verify artifacts (macOS)
```bash
cd dist/agave/v3.0.0
shasum -a 256 -c SHA256SUMS
```

## Smoke test in Linux container
```bash
docker run --rm -v "$PWD/dist/agave/v3.0.0:/out" ubuntu:24.04 bash -lc '
  apt-get update >/dev/null && apt-get install -y ca-certificates >/dev/null
  mkdir -p /tmp/agave-test
  tar -xzf /out/agave-v3.0.0-linux-x86_64.tar.gz -C /tmp/agave-test
  /tmp/agave-test/bin/solana --version
  /tmp/agave-test/bin/agave-validator --version
'
```

## Reproducibility check (current gap)
Two rebuilds produce different hashes. To compare:
```bash
# Build twice and compare tarball hashes
shasum -a 256 dist/agave/_repro/v3.0.0/run1/agave-v3.0.0-linux-x86_64.tar.gz \
  dist/agave/_repro/v3.0.0/run2/agave-v3.0.0-linux-x86_64.tar.gz

# Compare per-file hashes
diff -u dist/agave/_repro/v3.0.0/run1-files.sha256 \
  dist/agave/_repro/v3.0.0/run2-files.sha256
```

## Automation (GitHub Actions)
Workflow: `.github/workflows/agave-auto-build.yml`
- Scheduled checks (cron) look for the latest upstream release tag.
- If this repo does not already have a release for that tag, it builds and uploads assets.
- You can trigger manually in GitHub → Actions → `agave-auto-build` → Run workflow.

## Roadmap
- Pin toolchains and normalize build environment for determinism.
- Deterministic packaging (stable ordering, fixed timestamps).
- CI schedule to detect new upstream tags and auto-build.
- SBOM generation, provenance/attestations, and artifact signing.
- Add Firedancer/Frankendancer builds.

## Trust model / disclaimer
This repo provides automated build artifacts for convenience. Always verify checksums and provenance.
This project is not affiliated with Anza, Solana Foundation, or Jump Crypto.

## License
This repo (scripts) is licensed under Apache-2.0.  
Upstream projects have their own licenses; compiled artifacts remain subject to upstream licensing
and notices.
