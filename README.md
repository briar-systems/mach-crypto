# mach-crypto

Lightweight cryptographic primitives for Mach.

This repository owns reusable algorithms and their assurance evidence. Protocol
state machines belong in protocol repositories such as `mach-tls`.

## Modules

- `crypto.secret` owns allocated secret storage, bounded views, explicit moves,
  allocating clones, entropy initialization, and deterministic destruction.
- `crypto.hmac` and `crypto.hkdf` define keyed hashing and derivation contracts.
- `crypto.aead.aes_gcm` and `crypto.aead.chacha20_poly1305` cover authenticated encryption.
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

## Status

This scaffold defines public contracts and algorithm dimensions. Algorithms are
not represented as available until their callable implementation exists.

Mach constant-time support is functional. Its current limitation is assurance,
not expressiveness. The package will use Mach secret types and oblivious code,
official vectors, differential tests, generated-code inspection, leakage tests,
and independent review as distinct evidence layers.

The current assurance level is `assurance.SCAFFOLD`. No production algorithm is
exported by this revision.

## Local development

Dependencies are pinned Git tags. Build output uses Mach's default `out/`
directory inside this repository.

```sh
mach dep pull .
mach build .
mach test .
```
