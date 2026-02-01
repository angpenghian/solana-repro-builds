# solana-repro-builds

**Automated CI/CD pipeline for reproducible, verifiable Solana validator binaries**

Addresses supply chain security for Solana validator operations by providing hermetic Docker builds, automated release detection, and checksum verification for three major validator clients:
- **Agave** (anza-xyz/agave) - Official Solana Labs validator  
- **Jito** (jito-foundation/jito-solana) - MEV-optimized validator  
- **Firedancer** (firedancer-io/firedancer) - Jump Crypto's high-performance validator

## The Problem

Validator clients **stopped shipping official binaries**, forcing operators to either:
- Trust third-party pre-built binaries (supply chain risk)
- Build from source manually (error-prone, time-consuming, hard to verify)
- Use inconsistent build environments (non-reproducible)

This creates security, reliability, and auditability gaps in validator operations.

## The Solution

**Automated, reproducible build infrastructure** that:
- Monitors upstream releases every 6 hours via GitHub Actions
- Builds binaries in hermetic Docker containers for consistency
- Publishes verified artifacts (tar.gz + SHA256 checksums) as GitHub Releases
- Enables independent verification through reproducible builds
- Provides audit trails via CI logs and build metadata

## Why This Matters for Validator Operations

**Supply Chain Security**: Hermetic builds reduce attack surface vs downloading untrusted binaries

**Operational Reliability**: Automated CI ensures new releases are available within hours

**Auditability**: Anyone can verify checksums or rebuild independently

**Compliance**: Reproducible builds meet institutional security requirements

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Upstream Repositories                                           │
│ • anza-xyz/agave        • jito-foundation/jito-solana           │
│ • firedancer-io/firedancer                                      │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ Tag/Release Detection (every 6 hours)
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ GitHub Actions CI Workflows                                     │
│ • agave-auto-build.yml          • agave-auto-build-testnet.yml  │
│ • jito-auto-build.yml           • jito-auto-build-testnet.yml   │
│ • frankendancer-auto-build.yml  • frankendancer-auto-build-testnet.yml │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ If new release detected
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Docker Build Environment (Hermetic)                             │
│ • Fixed base images  • Pinned toolchains  • Isolated deps       │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ Compile from source
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Artifact Packaging                                              │
│ • tar.gz archive     • SHA256SUMS      • Build metadata         │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ Publish
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ GitHub Releases (Public)                                        │
│ Downloadable artifacts with checksums for verification          │
└─────────────────────────────────────────────────────────────────┘
```

## Features

### Automated Release Detection
- **Scheduled monitoring**: Checks for new upstream tags every 6 hours
- **Mainnet + Testnet**: Separate workflows for production and test networks
- **Idempotent**: Skips builds if release already exists

### Multi-Client Support
| Client | Mainnet | Testnet | Status |
|--------|---------|---------|--------|
| **Agave** | ✅ | ✅ | CI publishing releases |
| **Jito** | ✅ | ✅ | CI workflows ready |
| **Firedancer** | ✅ | ✅ | CI workflows ready |

### Build Reproducibility
- Docker-based hermetic environments ensure consistency
- Version-pinned toolchains (Rust, GCC, dependencies)
- Isolated build context prevents external interference
- Reproducibility validation workflows (future enhancement)

### Verification Workflows
- SHA256 checksums for integrity verification
- Smoke tests validate binaries execute correctly
- Build metadata for audit trails
- Local rebuild capability for independent verification

## Quick Start

### Prerequisites
- Docker
- macOS or Linux (scripts use bash)

### Build Locally

```bash
# Build Agave
./scripts/build_agave.sh v2.3.6

# Build Jito
./scripts/build_jito.sh v2.3.9-jito

# Build Firedancer (reduce JOBS if hitting OOM)
./scripts/build_frankendancer.sh v0.809.30106
# OR with reduced parallelism:
JOBS=1 ./scripts/build_frankendancer.sh v0.809.30106
```

### Verify Checksums

```bash
# Verify Agave artifacts
cd dist/agave/v2.3.6
shasum -a 256 -c SHA256SUMS

# Verify Jito artifacts
cd dist/jito/v2.3.9-jito
shasum -a 256 -c SHA256SUMS

# Verify Firedancer artifacts
cd dist/frankendancer/v0.809.30106
shasum -a 256 -c SHA256SUMS
```

### Smoke Test Binaries

Run binaries in a Linux container to verify they execute:

```bash
# Test Agave
docker run --rm -v "$PWD/dist/agave/v2.3.6:/out" ubuntu:24.04 bash -lc '
  apt-get update >/dev/null && apt-get install -y ca-certificates >/dev/null
  mkdir -p /tmp/test && tar -xzf /out/agave-v2.3.6-linux-x86_64.tar.gz -C /tmp/test
  /tmp/test/bin/solana --version
  /tmp/test/bin/agave-validator --version
'

# Test Jito
docker run --platform=linux/amd64 --rm -v "$PWD/dist/jito/v2.3.9-jito:/out" ubuntu:24.04 bash -lc '
  apt-get update >/dev/null && apt-get install -y ca-certificates >/dev/null
  mkdir -p /tmp/test && tar -xzf /out/jito-v2.3.9-jito-linux-x86_64.tar.gz -C /tmp/test
  /tmp/test/bin/solana --version
  /tmp/test/bin/agave-validator --version
'

# Test Firedancer
docker run --platform=linux/amd64 --rm -v "$PWD/dist/frankendancer/v0.809.30106:/out" ubuntu:24.04 bash -lc '
  apt-get update >/dev/null && apt-get install -y ca-certificates >/dev/null
  mkdir -p /tmp/test && tar -xzf /out/frankendancer-v0.809.30106-linux-x86_64.tar.gz -C /tmp/test
  /tmp/test/bin/fdctl --version
  /tmp/test/bin/solana --version
'
```

## Repository Structure

```
solana-repro-builds/
├── .github/workflows/          # CI automation
│   ├── agave-auto-build.yml
│   ├── agave-auto-build-testnet.yml
│   ├── jito-auto-build.yml
│   ├── jito-auto-build-testnet.yml
│   ├── frankendancer-auto-build.yml
│   └── frankendancer-auto-build-testnet.yml
├── builders/                   # Docker build environments
│   ├── agave/Dockerfile
│   ├── jito/Dockerfile
│   └── frankendancer/Dockerfile
├── scripts/                    # Build automation
│   ├── build_agave.sh
│   ├── build_jito.sh
│   └── build_frankendancer.sh
└── dist/                       # Build outputs (gitignored)
    ├── agave/<tag>/
    │   ├── agave-<tag>-linux-x86_64.tar.gz
    │   ├── SHA256SUMS
    │   └── bin/
    ├── jito/<tag>/
    │   ├── jito-<tag>-linux-x86_64.tar.gz
    │   ├── SHA256SUMS
    │   └── bin/
    └── frankendancer/<tag>/
        ├── frankendancer-<tag>-linux-x86_64.tar.gz
        ├── SHA256SUMS
        └── bin/
```

## CI/CD Workflows

### How It Works

1. **Scheduled trigger**: Every 6 hours, GitHub Actions runs
2. **Release detection**: Fetches latest upstream release (mainnet or testnet label)
3. **Deduplication**: Checks if this repo already published that release
4. **Build**: If new, triggers Docker build with pinned toolchain
5. **Package**: Creates tar.gz + SHA256SUMS
6. **Publish**: Uploads artifacts as GitHub Release
7. **Audit**: CI logs provide build provenance

### Manual Trigger

Trigger builds manually from GitHub Actions UI:
1. Go to **Actions** tab
2. Select workflow (e.g., `agave-auto-build`)
3. Click **Run workflow**
4. Choose branch and click **Run**

## Advanced: Reproducibility Verification

For institutional validators requiring reproducibility proofs:

```bash
# Build twice and compare
./scripts/build_agave.sh v2.3.6  # First build
mv dist/agave/v2.3.6 dist/agave/_repro/v2.3.6/run1

./scripts/build_agave.sh v2.3.6  # Second build
mv dist/agave/v2.3.6 dist/agave/_repro/v2.3.6/run2

# Compare tarball checksums (should match for reproducibility)
shasum -a 256 \
  dist/agave/_repro/v2.3.6/run1/agave-v2.3.6-linux-x86_64.tar.gz \
  dist/agave/_repro/v2.3.6/run2/agave-v2.3.6-linux-x86_64.tar.gz

# Compare per-file checksums (identifies which files differ)
diff -u \
  dist/agave/_repro/v2.3.6/run1-files.sha256 \
  dist/agave/_repro/v2.3.6/run2-files.sha256
```

## Roadmap

- [ ] Full deterministic packaging (stable ordering, fixed timestamps)
- [ ] Toolchain pinning (Rust version, GCC/Clang versions)
- [ ] Automated reproducibility checks in CI
- [ ] SBOM (Software Bill of Materials) generation
- [ ] Artifact signing and provenance attestations
- [x] Agave mainnet/testnet automation
- [x] Jito mainnet/testnet workflows
- [x] Firedancer mainnet/testnet workflows
- [x] Local verification documentation

## Trust Model

**What this provides**:
- Automated builds from auditable source (GitHub Actions)
- Checksum verification for integrity
- Reproducibility framework for independent validation

**What this doesn't replace**:
- Code audits of upstream validator clients
- Security reviews of build dependencies
- Attestation/signing by trusted entities

**Recommendation**: Always verify checksums. For production validators, consider rebuilding locally to verify reproducibility.

## Security & Compliance

This project is designed for institutional validator operators with security requirements:

- **No binary commits**: Only scripts in git; binaries stay in dist/ (gitignored)
- **Auditable builds**: Every artifact traces to a CI run with public logs
- **Reproducible**: Anyone can rebuild and verify outputs match
- **Open source**: Apache-2.0 licensed, community-auditable

## Limitations

- **Platform**: Linux x86_64 only (most common validator platform)
- **Reproducibility**: Partial (deterministic packaging in progress)
- **Signing**: Checksums only (no GPG/Sigstore yet)
- **SBOM**: Not generated (future enhancement)

## Contributing

Issues and feedback are welcome. Not currently accepting pull requests.

## Disclaimer

This project is not affiliated with Anza, Solana Foundation, Jito Foundation, or Jump Crypto. Compiled binaries are subject to upstream licensing. Always verify artifacts before use in production.

## License

Scripts and automation: **Apache-2.0**  
Upstream validator code: See respective project licenses
