# Changelog

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
