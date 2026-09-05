# Changelog

## [0.8.2] - 2026-09-02

### Added

- GitHub Actions CI: every pull request builds the library, runs the suite in both profiles and every per-algorithm project, verifies IR across all six targets, and produces and verifies the assurance evidence.

## [0.8.1] - 2026-09-01

### Fixed

- `tools/assurance run` resolves the dependencies of every tested project
  before running, so the gate passes from a fresh clone or worktree.

### Security

- Secret and typed-array deallocation callbacks now receive fully zeroed
  storage on every attempt, including cleanup retries.
- Failed callbacks that retain ownership have any callback mutation wiped
  again before control returns to the caller.

## [0.8.0] - 2026-09-01

### Added

- Generic typed secret-array ownership for public, directly secret, and deeply
  secret element shapes.
- Native typed secret allocation with checked geometry, exact alignment,
  zero initialization, and retry-safe destruction.

### Changed

- Pinned `mach-std` to `v0.34.0` for typed secret operating-system storage.

### Security

- Typed owners preserve `*T` across allocation, access, wiping, and release.
  Deeply secret records require no raw pointer cast or declassification.
- Failed allocation cleanup and failed deallocation retain wiped typed
  ownership for deterministic retry.

## [0.7.0] - 2026-08-31

### Added

- Verification-only ECDSA P-384 with SHA-384, strict DER signatures, and
  uncompressed P-384 SPKI public keys.
- A release evidence budget requiring median P-384 verification at or below
  250 milliseconds.

### Changed

- P-384 field arithmetic now keeps coordinates in Montgomery form and evaluates
  both ECDSA point products in one fixed interleaved loop.

### Security

- The dependency-visible P-384 module exposes only complete public-point
  validation and signature-verification operations. Raw points, scalars,
  decoding, arithmetic, and affine conversion remain private.
- Fixed-bound software limb products avoid target-dependent secret multiply
  latency while removing the former multi-second verification exposure.

## [0.6.0] - 2026-08-28

### Changed

- Native secret allocation, entropy, and release now use the portable
  secret-welded operating-system primitives from `mach-std`.
- System entropy failures inherit complete-destination wiping, bounded
  interruption handling, and platform chunking from `mach-std`.

## [0.5.0] - 2026-08-28

### Added

- Strict RSA PKCS#1 v1.5 SHA-256 and SHA-384 certificate signature
  verification with exact RFC 8017 `DigestInfo` encodings.
- NIST CAVP and independent OpenSSL verification vectors plus hostile padding,
  algorithm identifier, digest, and key corpora.
- Fail-closed cryptographic release evidence with independent test layers.
- Reproducible six-target debug and release builds with verified IR, assembly,
  provenance, and machine-readable artifact hashes.
- Compiler secret-flow negative controls and generated zeroization inspection.

### Security

- RSA PKCS#1 verification distinguishes malformed keys from authentication
  failures, preserves caller inputs, and clears recovered message and digest
  intermediates.
- Assurance reports cannot advance from missing, failed, modified, or stale
  evidence. Functional availability and independent review remain separate.

## [0.4.0] - 2026-08-28

### Added

- Ed25519 and RSA-PSS signing and verification with strict key and salt policies.
- Strict DER and PEM codecs with canonical length, value, label, line, and padding rules.
- PKCS#1, PKCS#8, SEC1, and SPKI containers for RSA, P-256, Ed25519, and X25519 keys.
- Incremental SHA-256 and SHA-384 transcript contexts with non-consuming snapshots.
- NIST and RFC vectors, hostile parsing corpora, lifecycle tests, and six-target IR evidence.

### Security

- Private containers retain one move-only secret owner and deterministic cleanup recovery.
- Transcript validation failures preserve state and output, while finalization and destruction zeroize state.
- RSA-PSS, Ed25519, container parsing, and transcript operations clear private intermediate values.

## [0.3.0] - 2026-08-28

### Added

- HMAC-SHA-256, HMAC-SHA-384, and RFC 5869 HKDF extract and expand.
- AES-128-GCM, AES-256-GCM, and ChaCha20-Poly1305 authenticated encryption.
- X25519 public-key derivation and agreement.
- Canonical SEC1 P-256 public-key derivation and ECDH agreement.
- Deterministic RFC 6979 ECDSA P-256 signing with SHA-256 and strict DER.
- Strict point, scalar, signature, tag, capacity, counter, and low-order validation.
- NIST, RFC, hostile-input, failure-preservation, overlap, and generated-code evidence.

### Security

- Authentication completes before plaintext release and clears rejected output.
- Secret-dependent field operations use fixed-position constant-shape arithmetic.
- Key schedules, nonces, tags, scalars, field values, and intermediate state are explicitly zeroized.

## [0.2.0] - 2026-08-28

### Added

- Secret-welded native allocator and operating-system entropy boundaries.
- Explicit zero and entropy initialization for owned secret storage.
- Bounded immutable and mutable secret views.
- Explicit ownership transfer and allocating clone operations.
- Retry-safe destruction that zeroizes once and retains failed cleanup ownership.
- Deterministic native tests for allocation, entropy, capacity, move, clone, and destruction failure paths.

### Changed

- Pinned `mach-std` to `v0.29.0`.

## [0.1.0] - 2026-08-27

### Added

- Initial cryptographic contracts and assurance scaffold.
