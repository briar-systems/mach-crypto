# mach-crypto

Lightweight cryptographic primitives for Mach.

This repository owns reusable algorithms and their assurance evidence. Protocol
state machines belong in protocol repositories such as `mach-tls`.

## Modules

- `crypto.secret` owns allocated secret storage, bounded views, explicit moves,
  allocating clones, entropy initialization, and deterministic destruction.
- `crypto.hash` provides incremental SHA-256 and SHA-384 transcript hashing.
- `crypto.hmac` provides one-shot HMAC-SHA-256 and HMAC-SHA-384.
- `crypto.hkdf` provides SHA-256 and SHA-384 extract and expand operations.
- `crypto.aead.aes_gcm` provides AES-128-GCM and AES-256-GCM record protection.
- `crypto.aead.chacha20_poly1305` provides ChaCha20-Poly1305 record protection.
- `crypto.group.x25519` provides X25519 key agreement.
- `crypto.group.p256` provides SEC1 P-256 public keys and ECDH.
- `crypto.signature` provides ECDSA P-256 and P-384 verification, Ed25519,
  RSA-PSS, and strict RSA PKCS#1 v1.5 signatures.
- `crypto.encoding.der`, `crypto.encoding.pem`, and `crypto.encoding.keys`
  provide strict TLS key-container parsing and exact serialization.
- `crypto.vectors` defines a common test vector contract.
- `crypto.assurance` publishes the validation state of this package.

`crypto.lib` re-exports these modules for consumers that prefer one import.

## Secret ownership

`crypto.secret.Secret` is move-only by contract. Initialize every owner with
`secret.empty()`, then allocate it with `secret.init` or `secret.init_random`.
Use `secret.move` to transfer the allocation and `secret.clone` when an
independent copy is required. Direct record copies are invalid because they
duplicate ownership.

`secret.bytes` and `secret.buffer` return bounded borrowed views. A view must
not outlive its owner or any move or destroy operation. `secret.destroy` wipes
active storage before release. If a deallocator fails, the owner remains in a
wiped cleanup-pending state and a later destroy retries release without wiping
twice.

`crypto.secret.SecretArray[T]` owns a dynamically sized typed allocation while
preserving every field's secrecy shape. Initialize an owner with
`secret.empty_array[T]`, construct the native allocator with
`secret.system_array_allocator[T]`, and call `secret.init_array[T]` with the
element count. `secret.array_data[T]` returns `*T` only while the owner is
active. No raw pointer or declassification cast is needed for directly secret
values or records with deeply nested secret fields.

Array initialization checks `count * $size_of(T)`, supplies `$align_of(T)` to
the typed allocator, and zero-initializes the complete allocation. A zero-count
array is active with nil data and acquires no allocation. `destroy_array[T]`
wipes active elements before release. A failed release retains the typed
pointer, count, byte size, allocator, and cleanup-pending state for retry.
Custom `ArrayAllocator[T]` callbacks follow the same ownership contract. A
nonnil output transfers the full requested allocation even when allocation
reports failure.

The native allocator and entropy source delegate to `mach-std` secret-welded OS
primitives. Storage remains secret-welded through every native boundary,
allocation begins zeroed, entropy fills are complete or leave a fully wiped
destination, and release wipes before returning storage to the operating
system. Custom allocators follow the same ownership rule. A nonnil allocation
result transfers ownership even when allocation reports failure, allowing
partial storage to be wiped and released deterministically.

## Key containers

`encoding.der` accepts only definite, minimally encoded lengths and rejects
noncanonical BOOLEAN, INTEGER, BIT STRING, NULL, and OBJECT IDENTIFIER values.
Complete-document parsing rejects trailing bytes and validates every nested
constructed value to a maximum depth of 16. Cursor failures are transactional.
The public writer supports overlapping content through move semantics and
validates constructed content before changing output.

`encoding.pem` uses standard base64 with canonical padding and 64-character
lines. Labels are bounded to 64 uppercase ASCII letters, digits, and single
interior spaces. Decoding accepts LF or CRLF and an optional final newline, but
rejects leading or trailing data, mismatched labels, nonfinal short lines,
noncanonical padding bits, URL-safe base64, and embedded whitespace. Exact-base
in-place decoding is supported. Public encoding rejects every overlap. Secret
encoding rejects exact-base overlap, and nonidentical secret views are disjoint
by contract.

`encoding.keys` supports the key containers needed by TLS:

- RFC 8410 Ed25519 and X25519 PKCS#8 private keys and SPKI public keys
- P-256 SEC1 and PKCS#8 private keys and uncompressed SPKI public keys
- P-384 uncompressed SPKI public keys
- PKCS#1 RSA private keys, RSA PKCS#8 private keys, and RSA SPKI public keys

Algorithm identifiers and parameters are exact. P-256 private scalars are
range-checked. An embedded SEC1 public point must be on the curve and match the
private scalar. RSA containers require version zero, a 2048 through 4096-bit
odd modulus, a canonical odd public exponent smaller than the modulus, and all
eight PKCS#1 key integers. Encrypted PKCS#8, version-one OneAsymmetricKey,
multi-prime RSA, compressed P-256 points, and legacy `RSA PUBLIC KEY` PEM are
not accepted.

Initialize every private output with `keys.empty_private`. Successful DER
decoding copies the complete canonical document into one owned secret
allocation. Successful PEM decoding allocates the exact decoded DER size once
and transfers that allocation directly into the key. `keys.private_bytes`
returns a borrowed seed or scalar. `keys.copy_rsa` copies the public modulus and
exponent and a modulus-width private exponent into caller storage. It snapshots
the private exponent first, so private output may overlap the owning key.
Overlapping public RSA outputs are rejected.

Private keys are move-only by contract and must be released with
`keys.destroy_private`. A failed allocation or parse normally leaves the output
empty. If cleanup deallocation fails, the output retains wiped cleanup-pending
storage while the primary error is returned. Call `destroy_private` after that
failure to retry release. Serialization reproduces the exact accepted DER, not
a reconstructed variant. Public SPKI views borrow the caller's DER or PEM
scratch buffer and must not outlive it.

## Transcript hashes

`hash.Sha256` and `hash.Sha384` are separate incremental state records for
public protocol transcripts. Initialize each record with `hash.empty_sha256`
or `hash.empty_sha384`, then activate it with the corresponding `init`
function. Repeated `update` calls accept bounded public fragments, including an
empty fragment. SHA-256 input is bounded to `2^61 - 1` bytes. SHA-384 uses its
full 128-bit encoded length field and accepts totals through `2^64 - 1` bytes.

`snapshot_sha256` and `snapshot_sha384` write the current digest without
changing the source state. The same state remains usable for later updates,
which is the TLS transcript operation used at handshake checkpoints. `final`
writes the digest and consumes the state only after successful output.
Validation, capacity, and length-overflow failures leave both state and output
unchanged.

`destroy_sha256` and `destroy_sha384` zeroize the complete state and are
idempotent. A destroyed state rejects update, snapshot, and final, but can be
activated again with `init`. This supports the TLS HelloRetryRequest transcript
rewrite without exposing `crypto.internal.sha2`. State records are opaque and
must not be copied directly. Snapshot clones, padded blocks, compression
schedules, temporary digests, and destroyed contexts are explicitly zeroized.

## HMAC and HKDF

`hmac.sha256` and `hmac.sha384` accept secret keys, public messages, and
caller-owned public output. The output capacity must be at least the full tag
size. Successful calls write the full tag. The output may overlap the public
message because no output is written until authentication is complete.

`hkdf.extract_sha256` and `hkdf.extract_sha384` accept secret salt and input key
material and write a fixed-size secret pseudorandom key. Empty salt and input
key material follow RFC 5869. Extract output may overlap either input because
the complete pseudorandom key is held locally before it is copied.

`hkdf.expand_sha256` and `hkdf.expand_sha384` treat output capacity as the
requested output length. The pseudorandom key must be exactly the hash output
size. Zero-length output is valid. Output is bounded to 255 hash blocks, which
is 8160 bytes for SHA-256 and 12240 bytes for SHA-384. Expand output may overlap
the pseudorandom key because the key is snapshotted before the first write.

Every validation failure returns `written = 0` without changing output. Public
buffers cannot alias nonempty secret buffers under Mach's secret-welded pointer
types. Internal SHA-2 state, schedules, HMAC pads, intermediate tags,
pseudorandom key snapshots, and expansion blocks are explicitly zeroized.

## AES-GCM

`aead.aes_gcm.seal` accepts a 16-byte or 32-byte secret key, an exact 12-byte
public nonce, public additional authenticated data, secret plaintext, and
caller-owned public output. It writes ciphertext followed by the complete
16-byte tag. Output capacity must cover both. Nonce and additional data may
overlap output because both are fully consumed before the first write.

`aead.aes_gcm.open` accepts ciphertext followed by its complete tag and
authenticates the entire record before decrypting any byte. On authentication
failure it returns `AUTH_FAILED`, writes no plaintext, and zeroizes exactly the
ciphertext-length prefix of secret output. Validation and capacity failures do
not change output. Successful output may overlap the secret key because the
expanded key schedule is complete before plaintext release.

Plaintext is bounded to 68,719,476,704 bytes, or `2^32 - 2` counter blocks.
Additional authenticated data is bounded to `2^61 - 1` bytes so its bit length
is representable in GCM's 64-bit length field. The implementation uses an
algebraic AES S-box and fixed-position GHASH multiplication rather than memory
lookups indexed by secret values. Expanded keys, cipher state, hash products,
authentication tags, and stream blocks are explicitly zeroized.

## ChaCha20-Poly1305

`aead.chacha20_poly1305.seal` accepts an exact 32-byte secret key, an exact
12-byte public nonce, public additional authenticated data, secret plaintext,
and caller-owned public output. It writes ciphertext followed by the complete
16-byte tag. Nonce and additional data may overlap output because both are
consumed before the first output write.

`aead.chacha20_poly1305.open` authenticates the complete ciphertext and tag
before decrypting any byte. Authentication failure returns `AUTH_FAILED` and
zeroizes exactly the ciphertext-length prefix of secret output. Validation and
capacity failures do not change output. Successful output may overlap the
secret key because the ChaCha20 context snapshots it before plaintext release.

Plaintext is bounded to 274,877,906,880 bytes, or `2^32 - 1` payload blocks.
Counter zero is reserved for the Poly1305 one-time key and payload counters run
from one through `0xffffffff`. Additional-data and ciphertext byte lengths are
encoded as the complete 64-bit RFC 8439 length fields. ChaCha20 uses fixed
rotations and positions. Poly1305 uses fixed-position limb arithmetic without
secret-dependent table accesses or hardware multiplication. Keys, stream
state, one-time keys, accumulators, authentication tags, and stream blocks are
explicitly zeroized.

This module protects TLS records and QUIC packet payloads. QUIC header
protection remains a separate primitive contract because it consumes a packet
sample to generate a five-byte mask rather than an AEAD nonce and payload.

## X25519

`group.x25519.derive_public` accepts an exact 32-byte secret private value and
writes its 32-byte RFC 7748 public u-coordinate to caller-owned public output.
`group.x25519.agree` accepts an exact 32-byte secret private value and 32-byte
public peer encoding, then writes the shared value to caller-owned secret
output. Private values are clamped internally. Consumers can create fresh
private values directly with `secret.init_random`.

Peer decoding masks the high bit and accepts non-canonical values by reducing
them modulo `2^255 - 19`, as required by RFC 7748. Any peer encoding that
produces the all-zero shared value is rejected with `INVALID_KEY`. Validation,
capacity, and low-order failures return `written = 0` without changing caller
output. Successful agreement output may overlap the private key because the
complete scalar is snapshotted before output is written.

The implementation performs the same 255-step Montgomery ladder for every
private value. Conditional swaps use masks rather than secret branches. Field
operations use fixed-position radix-`2^51` limbs and fixed 51-step masked
multiplication rather than secret hardware multiplication or division. Scalar,
field, inversion, encoded result, and rejected shared-secret state are
explicitly zeroized.

## P-256, P-384, and ECDSA

`group.p256.derive_public` accepts an exact 32-byte big-endian private scalar
in `1..n-1` and writes the exact 65-byte uncompressed SEC1 public point.
`group.p256.agree` accepts that scalar and an exact uncompressed SEC1 peer
point, validates canonical coordinates and the curve equation, and writes the
32-byte big-endian shared x-coordinate to secret output. Compressed points,
the point at infinity, off-curve points, non-canonical coordinates, and invalid
private scalars are rejected. Successful agreement may overwrite its private
scalar because the complete scalar is snapshotted first.

`signature.sign_ecdsa_p256_sha256` hashes the public message with SHA-256 and
uses RFC 6979 HMAC-SHA-256 nonce generation. It writes a strict minimal DER
signature of at most 72 bytes. `signature.verify_ecdsa_p256_sha256` accepts an
exact uncompressed SEC1 public key and strict DER, rejects zero or out-of-range
`r` and `s`, and accepts both high- and low-`s` mathematical signatures. All
validation and capacity failures return `written = 0` without changing output.
Signing evaluates eight nonce candidates before selecting the first valid one,
which hides the RFC rejection count and bounds all-candidate failure below the
P-256 security level.

`signature.verify_ecdsa_p384_sha384` hashes the public message with SHA-384 and
accepts an exact 97-byte uncompressed secp384r1 public key and strict DER
signature of at most 104 bytes. It validates canonical coordinates, the curve
equation, and scalar ranges. P-384 private signing and ECDH are not exposed.

Field and scalar values use fixed eight-limb storage. Multiplication uses a
fixed 256-step masked shift-and-add operation, inversions use fixed public
exponents, and scalar multiplication uses a fixed 256-step point loop without
secret-indexed tables. Private scalars, nonce state, hashes, field and scalar
temporaries, and projective points are explicitly zeroized.

P-384 verification uses the same ownership and constant-shape contract with
fixed twelve-limb storage. Field coordinates stay in Montgomery form. Each
Montgomery product has fixed 12-by-12 limb bounds, and each 32-bit limb product
uses a fixed 32-step masked operation rather than a variable-latency machine
multiply. Verification evaluates the two ECDSA point products together in one
fixed 384-step loop with masked four-way point selection and no secret-indexed
table. Inversions retain fixed public exponents. Hashes, field and scalar
temporaries, and projective points remain welded until explicitly zeroized.

## Ed25519 and RSA signatures

`signature.derive_ed25519_public` derives an exact 32-byte RFC 8032 public key
from an exact 32-byte private seed. `signature.sign_ed25519` writes an exact
64-byte deterministic pure-Ed25519 signature. Verification requires canonical
point encodings, `S < L`, and non-identity prime-subgroup public and nonce
points. Malformed public keys return `INVALID_KEY`. Malformed or
mathematically invalid signatures return `AUTH_FAILED`.

RSA keys use explicit `RsaPublicKey` and `RsaPrivateKey` records. A modulus is
a canonical big-endian, odd, full-width value from 256 through 512 bytes in
four-byte increments. This admits 2048, 3072, and 4096-bit TLS keys. A public
exponent is canonical big-endian, odd, at least three, and less than the
modulus. A private exponent is secret, left-zero-padded to exactly the modulus
width, and is paired with its public exponent so signing can verify its own
result before release.

`signature.sign_rsa_pss_sha256` requires an exact 32-byte caller-provided
secret salt. `signature.sign_rsa_pss_sha384` requires an exact 48-byte salt.
The caller owns salt generation and should use `secret.init_random` for every
signature. The encoded message uses `emBits = modBits - 1`, MGF1 with the same
hash, an exact hash-length salt, and trailer `0xbc`. Signatures are exactly the
modulus width. Verification enforces the same salt and encoded-message policy.

`signature.verify_rsa_pkcs1_sha256` and
`signature.verify_rsa_pkcs1_sha384` accept certificate signatures encoded by
EMSA-PKCS1-v1_5. Verification requires a signature exactly as wide as the
modulus, at least eight `0xff` padding bytes, the exact RFC 8017 SHA-256 or
SHA-384 `DigestInfo` with explicit NULL parameters, and no leading or trailing
bytes. Malformed encodings and digest mismatches return `AUTH_FAILED` without
changing caller-owned key, message, or signature storage.

Ed25519 and RSA-PSS signing consume the complete message before writing, so
public message and output storage may overlap. Validation, capacity, and key
failures write nothing and return `written = 0`. RSA signing performs a public
exponentiation self-check before any signature byte is released. Secret seeds,
expanded scalars, nonces, salts copied into encoded messages, private
exponentiation state, message hashes, masks, encoded messages, and unreleased
signatures are explicitly zeroized. `signature.algorithm_status` returns
`UNSUPPORTED` for an unknown TLS signature identifier, independently of
`INVALID_KEY` and `AUTH_FAILED` operation results.

## Status

The repository combines callable primitives with contracts for algorithms that
are still being built. AES-128-GCM, AES-256-GCM, ChaCha20-Poly1305, X25519,
P-256 ECDH, ECDSA P-256 with SHA-256, ECDSA P-384 verification with SHA-384,
Ed25519, RSA-PSS and RSA PKCS#1 v1.5 with SHA-256 and SHA-384, HMAC-SHA-256,
HMAC-SHA-384, HKDF-Extract, HKDF-Expand, incremental SHA-256 and SHA-384,
strict DER and PEM, and TLS key containers are callable in this revision. Their
tests include NIST,
RFC 4231, RFC 5869, RFC 6979, RFC 7468, RFC 7748, RFC 8017, RFC 8032, RFC 8410,
RFC 8439, SEC 1, and independent OpenSSL vectors. They cover
strict-encoding and tamper cases, counter and output
limits, invalid inputs, fixed-buffer failures, and supported overlap.

Mach constant-time support is functional. Its current limitation is assurance,
not expressiveness. The package will use Mach secret types and oblivious code,
official vectors, differential tests, generated-code inspection, leakage tests,
and independent review as distinct evidence layers.

`tools/assurance run` is the fail-closed release evidence gate. It runs the
functional, official-vector, differential, invalid-input, leakage, and
zeroization layers independently. It then performs two clean builds of every
project for all six targets in debug and release mode with verified IR and
emitted assembly. The two artifact sets must be byte-for-byte identical.

A successful run publishes an immutable machine-readable evidence directory
under `out/assurance/` and updates `out/assurance/current`. The report records
the exact Git commit, compiler binary hash, compiler version, dependency lock,
target, profile, algorithm, vector source, logs, generated-code samples, and
artifact hashes. `tools/assurance verify` rejects missing, modified, or stale
evidence. See [the assurance guide](doc/assurance.md) for the complete contract.

The source-only floor remains `assurance.SCAFFOLD` because generated evidence
is deliberately not trusted merely because a source constant says it exists.
The gate advances the automated level in `state.tsv` only after every required
artifact passes. Callable algorithm availability and independent review status
are separate fields. Independent review is currently `NOT_RECORDED`.

## Local development

Dependencies are pinned Git tags. Build output uses Mach's default `out/`
directory inside this repository.

```sh
mach dep pull .
mach build .
mach test .
tools/assurance run
tools/assurance verify
```
