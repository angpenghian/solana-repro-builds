### `docs/THREAT_MODEL.md`
```md
# Threat model (high level)

## What we assume
- Users do not blindly trust binaries.
- Users verify checksums (and later: signatures/provenance).

## Risks
- Supply chain compromise (runner, dependencies)
- Malicious actor publishing a fake release
- Non-reproducible builds causing mismatch across environments

## Mitigations (current)
- Publish SHA256SUMS for every release.
- Publish build metadata in release notes (upstream repo + tag/commit).

## Planned mitigations
- Provenance/attestations for builds
- SBOM generation
- Signed artifacts (cosign)
- Reproducible build documentation and pinned toolchains
