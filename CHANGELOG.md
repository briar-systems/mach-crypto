# Changelog

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
