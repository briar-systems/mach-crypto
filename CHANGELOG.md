# Changelog

## Unreleased

### Added

- Canonical SEC1 P-256 public-key derivation and ECDH agreement.
- Deterministic RFC 6979 ECDSA P-256 signing with SHA-256 and strict DER.
- Strict P-256 point, scalar, and ECDSA signature validation.
- NIST CAVP, RFC 6979, hostile-input, failure-preservation, and overlap tests.

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
