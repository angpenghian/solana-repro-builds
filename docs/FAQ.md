# FAQ

## Can upstream trigger your builds automatically via webhook?
Not directly. Only the upstream repo owners can configure webhooks for their repos.
This project uses scheduled checks (polling) to detect new tags/releases.

## Why not commit binaries into git?
Binaries bloat git history and make review/verification harder.
We publish artifacts as GitHub Release assets instead.

## Which platforms are supported?
Initial focus: Linux x86_64. Other architectures may be added later.

## Are you affiliated with Anza / Solana / Jump?
No.
