# solana-repro-builds

Automated, reproducible builds and verifiable release artifacts for Solana validator clients:
- **Agave** (anza-xyz/agave)
- **Firedancer / Frankendancer** (firedancer-io/firedancer)

This project monitors upstream tags/releases and publishes build outputs as GitHub Release assets
(tarballs + checksums). Local builds are stored in `dist/` for verification and comparison.

## Vision
Solana validator clients stopped shipping binaries. This repo exists to provide a clean, repeatable,
supply-chain-friendly build pipeline that anyone can verify.

## Why this is trustworthy
- The checksum (hash) proves the file you downloaded is exactly what was published.
- Reproducible builds mean anyone can rebuild and get the same checksum.
- CI logs and build metadata make the process auditable.

## How it works (flowchart)
```
Upstream tags/releases
        |
        v
Scheduled tag check (CI cron, every 6 hours)
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
│  ├─ agave-auto-build.yml
│  ├─ agave-auto-build-testnet.yml
│  ├─ frankendancer-auto-build.yml
│  └─ frankendancer-auto-build-testnet.yml
├─ builders/
│  ├─ agave/
│  │  └─ Dockerfile
│  └─ frankendancer/
│     └─ Dockerfile
├─ scripts/
│  ├─ build_agave.sh
│  └─ build_frankendancer.sh
├─ dist/
│  └─ agave/
│     └─ <tag>/
│        ├─ agave-<tag>-linux-x86_64.tar.gz
│        ├─ SHA256SUMS
│        └─ bin/
└─ README.md
```
## Local testing (build → verify → smoke test)
These steps are in order. The `dist/` folder exists after cloning, but it’s empty until you build.

## Prerequisites
- Docker

### Build locally (Agave)
```bash
./scripts/build_agave.sh <agave_tag>
# example: ./scripts/build_agave.sh v3.0.0
```

### Verify artifacts (macOS)
```bash
cd dist/agave/<agave_tag>
shasum -a 256 -c SHA256SUMS
```

### Smoke test in Linux container
This runs the Linux binaries inside a temporary Ubuntu container (macOS can’t run them directly).
The command mounts your local `dist/agave/<tag>/` into the container at `/out`, extracts the tarball
to `/tmp/agave-test`, then runs `--version` to confirm the binaries start correctly.

```bash
docker run --rm -v "$PWD/dist/agave/<agave_tag>:/out" ubuntu:24.04 bash -lc '
  apt-get update >/dev/null && apt-get install -y ca-certificates >/dev/null
  mkdir -p /tmp/agave-test
  tar -xzf /out/agave-<agave_tag>-linux-x86_64.tar.gz -C /tmp/agave-test
  /tmp/agave-test/bin/solana --version
  /tmp/agave-test/bin/agave-validator --version
'
```

### Build locally (Frankendancer)
```bash
./scripts/build_frankendancer.sh <fd_tag>
# example: ./scripts/build_frankendancer.sh v0.809.30106

# If you hit OOM or jobserver errors, reduce parallelism:
JOBS=1 ./scripts/build_frankendancer.sh <fd_tag>
```

### Verify artifacts (Frankendancer)
```bash
cd dist/frankendancer/<fd_tag>
shasum -a 256 -c SHA256SUMS
```

### Smoke test in Linux container (Frankendancer)
```bash
docker run --platform=linux/amd64 --rm -v "$PWD/dist/frankendancer/<fd_tag>:/out" ubuntu:24.04 bash -lc '
  apt-get update >/dev/null && apt-get install -y ca-certificates >/dev/null
  mkdir -p /tmp/fd-test
  tar -xzf /out/frankendancer-<fd_tag>-linux-x86_64.tar.gz -C /tmp/fd-test
  /tmp/fd-test/bin/fdctl --version
  /tmp/fd-test/bin/solana --version
'
```

## Reproducibility check (advanced / optional)
This is only for people who want to prove “same input → same output.”
It compares two separate builds of the same tag. If you just want the binaries, you can skip this.

```bash
# After doing two builds of the same tag, compare the tarball hashes
shasum -a 256 dist/agave/_repro/<agave_tag>/run1/agave-<agave_tag>-linux-x86_64.tar.gz \
  dist/agave/_repro/<agave_tag>/run2/agave-<agave_tag>-linux-x86_64.tar.gz

# Compare per-file hashes (shows which files differ)
diff -u dist/agave/_repro/<agave_tag>/run1-files.sha256 \
  dist/agave/_repro/<agave_tag>/run2-files.sha256
```

## Automation (GitHub Actions)
Workflow: `.github/workflows/agave-auto-build.yml`
- Scheduled checks (cron) look for the latest upstream release tag.
- If this repo does not already have a release for that tag, it builds and uploads assets.
- You can trigger manually in GitHub → Actions → `agave-auto-build` → Run workflow.

Testnet workflow: `.github/workflows/agave-auto-build-testnet.yml`
- Builds the latest upstream release marked “testnet”.
- Publishes with a `-testnet` suffix to avoid clashing with mainnet releases.

Workflow: `.github/workflows/frankendancer-auto-build.yml`
- Scheduled checks (cron) look for the latest upstream **mainnet** release.
- Builds and publishes Frankendancer tarball + SHA256SUMS.

Testnet workflow: `.github/workflows/frankendancer-auto-build-testnet.yml`
- Builds the latest upstream **testnet** release.
- Publishes with a `-testnet` suffix to avoid clashing with mainnet releases.

## Roadmap
- Pin toolchains and normalize build environment for determinism.
- Deterministic packaging (stable ordering, fixed timestamps).
- CI schedule to detect new upstream tags and auto-build.
- SBOM generation, provenance/attestations, and artifact signing.
- Expand Frankendancer reproducibility checks.

## Trust model / disclaimer
This repo provides automated build artifacts for convenience. Always verify checksums and provenance.
This project is not affiliated with Anza, Solana Foundation, or Jump Crypto.

## License
This repo (scripts) is licensed under Apache-2.0.  
Upstream projects have their own licenses; compiled artifacts remain subject to upstream licensing
and notices.
