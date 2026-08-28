# mach-crypto

Lightweight cryptographic primitives for Mach.

This repository owns reusable algorithms and their assurance evidence. Protocol
state machines belong in protocol repositories such as `mach-tls`.

## Modules

- `crypto.secret` owns allocated secret storage, bounded views, explicit moves,
  allocating clones, entropy initialization, and deterministic destruction.
- `crypto.hmac` provides one-shot HMAC-SHA-256 and HMAC-SHA-384.
- `crypto.hkdf` provides SHA-256 and SHA-384 extract and expand operations.
- `crypto.aead.aes_gcm` provides AES-128-GCM and AES-256-GCM record protection.
- `crypto.aead.chacha20_poly1305` defines the ChaCha20-Poly1305 contract.
- `crypto.group.p256` and `crypto.group.x25519` cover TLS key agreement.
- `crypto.signature` covers certificate signature algorithms.
- `crypto.encoding.der` and `crypto.encoding.pem` cover cryptographic containers.
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

The native allocator and entropy source keep storage secret-welded across the
OS boundary. Custom allocators follow the same rule. A nonnil allocation result
transfers ownership even when allocation reports failure, allowing partial
storage to be wiped and released deterministically.

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

## Status

The repository combines callable primitives with contracts for algorithms that
are still being built. AES-128-GCM, AES-256-GCM, HMAC-SHA-256, HMAC-SHA-384,
HKDF-Extract, and HKDF-Expand are callable in this revision. Their tests include
NIST, RFC 4231, and RFC 5869 vectors, independent differential vectors, tamper
cases, counter and output limits, invalid inputs, fixed-buffer failures, and
supported overlap.

Mach constant-time support is functional. Its current limitation is assurance,
not expressiveness. The package will use Mach secret types and oblivious code,
official vectors, differential tests, generated-code inspection, leakage tests,
and independent review as distinct evidence layers.

The package-wide assurance level remains `assurance.SCAFFOLD` while the other
algorithm modules are scaffolds. AES-GCM, HMAC, and HKDF have functional and
vector evidence, but package-wide leakage and independent review layers have not
yet advanced.

## Local development

Dependencies are pinned Git tags. Build output uses Mach's default `out/`
directory inside this repository.

```sh
mach dep pull .
mach build .
mach test .
```
