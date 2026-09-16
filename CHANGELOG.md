# Changelog

## [Unreleased]

### Performance

- P-256 inverts along fixed addition chains: 255 squarings and 12 multiplications in the field, 253 and 39 in the scalar ring, where square-and-multiply took 256 and 128, and 256 and 169. ECDSA signing retires 9% fewer instructions, verification 5%, and keygen and ECDH 4% (#81).
- P-256 multiplies the generator with a fixed-base comb table: 64 windows of 15 precomputed affine multiples, selected in constant time and added with mixed additions, so there are no doublings. `tools/p256-base-table` generates the table, and a test recomputes every entry. Keygen retires 3.4x fewer instructions, ECDSA signing 2.2x and verification 1.5x (#82).

## [0.10.1] - 2026-09-16

### Changed

- Dependencies: mach-std v3.2.0 (#76), which carries std's Windows owner-only file mode security fix.

## [0.10.0] - 2026-09-16

### Changed

- Dependencies: mach-std v3.1.0 (#72). Consumers now resolve std 3.1.0 or later.

## [0.9.2] - 2026-09-15

### Fixed

- The P-384 verification budget no longer runs in the package suite, where it was judged in a debug build with every other test in parallel and failed the gate intermittently on a loaded runner (#65). It lives in `test/performance/`, which the assurance gate reaches alone and in release only.

### Changed

- Dependencies: mach-std v2.1.0.

## [0.9.1] - 2026-09-15

### Performance

- AES-GCM runs bitsliced over four blocks per pass and hashes GHASH in 64-bit words (#56, measured in #59).
- P-256 reduces field products once with the Solinas identity, keeps scalars in Montgomery form, and multiplies points with a fixed 4-bit window (#57, measured in #61).
- curve25519 multiplies field elements in one pass over the multiplier bits, shares the 2^250 - 1 chain between inversion and the Ed25519 square root, and multiplies Ed25519 points with a fixed 4-bit window (#58, measured in #60).

Every table selection is a masked scan over all entries and no new branch, index or multiply depends on secret data.

### Added

- Differential tests against independent implementations: AES-GCM at every record-length boundary for both key sizes, and P-256, Ed25519 and X25519 arithmetic across the full scalar range, including 0, n - 1, n, n + 1 and 2^256 - 1 (#62).

## [0.9.0] - 2026-09-13

### Changed

- Migrated to mach 5.0 and std 2.0.0 (#51): every fallible or absent outcome is a `res`, `opt` or `err` tag, `:^` is the typed `:>T` strip, the manifest is on the 5.0 schema and the dependency pins are the committed gitlinks under `dep/`.
- Every `:^` declassification is now the typed `:>T` strip. The nested per-algorithm test projects take crypto as a path dependency.
- `--verify-ir` dropped from CI and `tools/assurance`, as IR verification is mandatory in 5.0. The debug profile carries no debug info because 5.0 refuses `-g` on windows-x86_64, which the all-targets assurance build covers.
- Assurance evidence records a hash of the committed `dep/` gitlinks in place of `mach.lock`, its IR detector matches the 5.0 spelling of a call, and the release assembly check accepts the inline expansion of `ct.zeroize` that 5.0's cross-module inliner produces, since the wipe survives by the language's zeroizing-write guarantee.


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
