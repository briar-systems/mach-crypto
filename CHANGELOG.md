# Changelog

## [Unreleased]

### Performance

- RSA runs on 64-bit limbs: `crypto.internal.rsa` is a run-time-sized Montgomery ring of up to 64 limbs whose products are `word.multiply_wide`, so a 2048-bit multiply is 1024 hardware products instead of 4096 32-bit ones, squaring forms its cross products once, and r2 is derived by a handful of squarings from the modulus's top bit instead of 4096 modular doublings. Exponentiation uses fixed 4-bit windows with a masked table scan in place of square-and-multiply on every bit. Instructions per op on x86_64 with mach 5.9.0: RSA-PSS 2048 signing 1238M to 196M (12.5 ms), verification 74.8M to 4.5M (0.28 ms), 3072 signing 3789M to 625M (40 ms), verification 131M to 9.8M (0.60 ms). Key acceptance is unchanged: any four-byte-increment modulus from 256 to 512 bytes, including one that does not fill its top limb (#83).

### Added

- `test/performance` budgets RSA-PSS 2048 and 3072 signing and verification (250 ms and 25 ms, 500 ms and 50 ms medians) on OpenSSL-generated keys, and an OpenSSL 2080-bit PSS vector checks a modulus whose top 64-bit limb is half filled (#83).
- `word.carry_of` and `word.borrow_of` are the limb carry and borrow predicates both Montgomery rings share (#83).

### Performance

- P-256 and P-384 run on 64-bit limbs over `crypto.internal.mont`, the Montgomery ring the Ed25519 scalar ring already used, with the limb count as a comptime argument: four for every 256-bit field and order, six for P-384. The four-limb ring has unrolled multiply, square, reduction, add and subtract in scalar temporaries so the limbs stay in registers, and the loop forms stay as the reference under a differential. P-256 field elements are in Montgomery form inside points, the fixed-base comb table is regenerated in that form as 64-bit limbs (`tools/p256-base-table`), and the Solinas reduction over 32-bit words is gone. Instructions per op on x86_64 with mach 5.9.0: P-256 verification 33.19M to 6.77M (0.76 ms), signing 8.31M to 1.91M (0.22 ms), key derivation 6.56M to 1.35M, ECDH 26.39M to 5.34M, P-384 verification 170.6M to 68.9M (4.4 ms). An x25519 + ECDSA P-256 handshake drops from 35.4M to 9.0M (#83).

### Added

- `crypto.internal.mont` is checked against independent big-integer products, squares and a 768-bit reduction over the P-384 prime and order, and the unrolled four-limb ring against the loop form on a deterministic sweep (#83).

## [0.18.0] - 2026-09-19

### Changed

- Dependencies: requires mach-std 6.0.0, selected by `version = "^6.0"`. The width-named constant-time comparisons are gone from std, so the 33 `ct.eq_u8` and `ct.eq_u64` sites are `ct.eq[u8]` and `ct.eq[u64]`. Each instance lowers to the same `cmp; sete; movzx` the removed functions did, and the release assembly of every module that uses them is unchanged apart from the instance symbol; nothing else in std's migration guide (sort, heap, map, set, buffer accounts) is used here. `mach = "^5.9"` is unchanged (#136).
- `test/performance` pins std by tag itself, because a path dependency carries no pin for a dependency it selects by version and that tree is not committed (#136).

## [0.17.0] - 2026-09-19

### Performance

- X25519 and the Ed25519 field compute each product as 25 limb products on the 64 x 64 widening multiply where mach admits it (`$mach.build.ct_mul(low, 128)`: x86-64 on every OS, aarch64-linux and aarch64-darwin under PSTATE.DIT, riscv64 under Zkt) and keep the 255-step masked sum as `serial_multiply` everywhere else. Squaring forms its 15 products once, the a24 step is 5 products, and the ladder's ten temporaries are allocated and wiped once per ladder instead of per step. `word.multiply_wide` is the primitive, gated like `word.multiply`. Instructions per op on x86_64 with mach 5.9.0: x25519 agreement 54.0M to 1.26M, key derivation 15.1M to 0.75M, Ed25519 verification 218.6M to 10.0M. An x25519 + ECDSA P-256 handshake drops from 102.4M (122.3M under mach 5.5.1) to 35.4M, with the ladder at 3.6% of it and P-256 verification at 94% (#83).
- The Ed25519 scalar ring is four 64-bit limbs on a Montgomery multiply mod l (`crypto.internal.mont`, the 256-bit ring the scalar rings share): a product is 32 limb products and two reductions, and reducing a 64-byte digest is three products, instead of 256 or 512 conditional additions. Ed25519 signing drops from 33.9M to 1.61M instructions on x86_64 (#83).

### Changed

- Dependencies: requires mach 5.9 (`u128` widening) and mach-std 5.8.0, whose start code turns PSTATE.DIT on for aarch64-linux and aarch64-darwin programs that link a secret multiply and refuses to start without the mode (#83).
- Field elements accept limbs below 2^54 and every field operation leaves them below 2^52. `add` and `subtract` carry once; `subtract` adds 4p (#83).
- `assurance/leakage.tsv` admits the ungated multiply control on linux-arm64 and darwin-aarch64, where mach 5.9 admits the product under DIT (#83).

### Added

- A field differential runs the selected x25519 multiply, square and a24 step against the bit-serial reference on edge elements up to the 2^54 bound and a deterministic sweep, on every target. `crypto.internal.mont` is checked against independent big-integer products and a 512-bit reduction mod l, and `word.multiply_wide` against `word.serial_multiply_wide` (#83).

## [0.16.0] - 2026-09-18

### Performance

- Secret word products use the processor's multiply where mach admits it as constant time. `crypto.internal.word.multiply` selects `left * right` when `$mach.build.ct_mul(low, 64)` folds to 1 for the build target and keeps the bit-serial masked sum as `word.serial_multiply` everywhere else. mach 5.5 admits x86-64 on every OS and riscv64 under Zkt, and refuses aarch64 until its DIT mode is guaranteed (mach#3508). P-256, P-384, RSA and Poly1305 go through the primitive, so on x86_64 every 32 x 32 product is one instruction instead of 32 masked steps. Instructions per op on x86_64: P-256 key derivation 23.8M to 6.8M, signing 40.0M to 8.6M (0.64 ms), verification 123.6M to 33.8M (2.6 ms), ECDH 88.3M to 26.8M, ChaCha20-Poly1305 over 1 KiB 720k to 198k. An x25519 + ECDSA P-256 handshake drops from 212M to 122M. X25519 and Ed25519 keep their row-serial field until mach admits the 128-bit product (mach#3511) (#83).

### Added

- A primitive differential test runs `word.multiply` against `word.serial_multiply` on edge words and a deterministic sweep on every target, so the hardware path is checked against the reference on each native CI leg (#83).
- `test/multiply-negative`, a bare secret multiply with no gate, joins the leakage controls. `assurance/leakage.tsv` gained an `admitted` column naming the targets on which mach admits the product in hardware: there the control must compile with `mul.secret` in its IR, and everywhere else it must be refused. The row is the record of where crypto computes secret products in hardware (#83).

## [0.15.0] - 2026-09-18

### Performance

- Every SHA-2 path runs on `std.crypto.hash`. The secret paths (HMAC, and with it HKDF and the RFC 6979 nonce, PSS salt, MGF1, P-384, the SHA-384 transcript, Ed25519's SHA-512) use std's secret-typed states, which share the SHA-NI and ARMv8 SHA2 dispatch of the public entries. `crypto.internal.sha2` is deleted, and `crypto.internal.lift` lifts public input into the secret states block by block and keeps the length bounds. On a SHA-NI host the TLS 1.3 key schedule (three extracts and ten expands) drops from 747k to 160k instructions, HKDF expand from 57k to 12.8k, and ECDSA P-256 signing from 44.4M to 40.0M. The hash share of an x25519 + ECDSA P-256 handshake is now 0.09% (#126).

### Changed

- Dependencies: requires mach-std 5.7.0 (#126). `mach = "^5.5"` is unchanged.
- The zeroization control for SHA-2 inspects `crypto/internal/lift` in place of the deleted `crypto/internal/sha2`. State zeroization lives in std's `destroy_secret*` (#126).

## [0.14.0] - 2026-09-18

### Performance

- The public SHA-256 paths run on `std.crypto.hash.sha256`, which dispatches to SHA-NI on x86_64 and ARMv8 SHA2 on aarch64 at run time: the transcript hash (`hash.Sha256`) and the message hash under ECDSA P-256 and RSA SHA-256 signing and verification. On a SHA-NI host a 4 KiB TLS transcript with seven digests drops from 879k to 26k instructions (55 µs to 4.6 µs). Every secret path (HMAC, HKDF, PSS salt, MGF1) and SHA-384 stay on the constant-time secret-state `internal.sha2`: std's state is public-typed, and a secret cannot cross into it without a declassify (#122).

### Changed

- Dependencies: requires mach-std 5.5.0 and mach 5.5 or later. Every manifest declares `mach = "^5.5"` (#122).
- `hash.Sha256` wraps std's public state. Callers still treat it as opaque, and an empty context is still all zero (#122).

## [0.13.2] - 2026-09-17

### Changed

- Dependencies: requires mach-std 5.3.0 (#112). This is a pin bump, not an API change. It names the std tag mach-tls uses, so a graph with both resolves without a root std override.
- `mach.toml` declares `mach = "^5.3"`, so mach-crypto requires mach 5.3 or later (#112).
- The std bump brings std's cancelled-completion contract change: a cancelled or timed-out io completion now carries the bytes that landed before the cancel. Anyone who links mach-crypto with std gets that behavior. mach-crypto itself consumes no io completion, so nothing in its own surface changes.

## [0.13.1] - 2026-09-17

### Changed

- Dependencies: requires mach-std 5.0.1 (#108), and with it mach 5.2.0 or later (tested with 5.2.1). This is a pin bump, not an API change, and it exists to pick up std's `memory.buffers` crash fix (mach-std#775). mach-crypto does not use `memory.buffers`, so nothing in crypto behaves differently. Naming the current std tag lets a project that takes both mach-crypto and mach-tls resolve without declaring std at its own root.

## [0.13.0] - 2026-09-17

### Changed

- Dependencies: requires mach-std 5.0.0 (#104), and with it mach 5.2.0 or later (tested with 5.2.1). This is a pin bump, not an API change. The mach-crypto API is unchanged, but the std pin crosses a major version, and mach refuses conflicting std pins in one graph, so consumers must move to std 5.0.0 with it. The performance budget test reads the monotonic clock with `time.instant()` and `time.elapsed`, which replaced `time.monotonic()`.
- The project is attributed to Briar Systems LLC (#102).

## [0.12.0] - 2026-09-17

### Performance

- X25519 key derivation computes `[k]B` on edwards25519 with a fixed-base comb and maps it to the Montgomery u-coordinate, where it ran the 255-step ladder. The comb has 64 windows of 15 precomputed multiples in Niels form, selected by a masked scan and added with the complete mixed addition. Ed25519 key derivation, signing and verification multiply the base point the same way. `tools/ed25519-base-table` generates the table, and a test recomputes every entry. Instructions: X25519 key derivation 3.6x fewer, Ed25519 key derivation 4.2x, signing 4.0x, verification 1.24x (#98).
- `x25519.multiply` leaves its product with two carry passes instead of a full canonicalization. Every consumer normalizes or canonicalizes before comparing or encoding. X25519 agreement retires 1.7% fewer instructions (#98).

### Added

- `tools/assurance` runs every leakage control listed in `assurance/leakage.tsv`. The new `test/leakage-index` control, a table read at a secret index, must be refused on every target and profile, next to the secret-branch control (#98).

## [0.11.0] - 2026-09-17

### Changed

- Dependencies: requires mach-std 4.0.1 (#92), and with it mach 5.2.0 or later. The native secret allocator and entropy source call `std.memory.secret`, which replaced `std.system.os.secret_*`. Their callbacks still report any failure as a nonzero status. Consumers now resolve std 4.0.1 or later, which keeps the whole net stack on one std tag.

## [0.10.3] - 2026-09-16

### Performance

- Every secret word multiply goes through one function, `crypto.internal.word.multiply`, which is the single place a target's constant-time hardware multiply will be selected (#88, #83). It shifts its operands by one bit per step. Measured in instructions: RSA verification is 2.1x cheaper, P-384 verification 13.5%, P-256 keygen, ECDH, sign and verify about 11%, and ChaCha20-Poly1305 is unchanged.

## [0.10.2] - 2026-09-16

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
