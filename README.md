# mach-crypto

Lightweight cryptographic primitives for Mach.

This repository owns reusable algorithms and their assurance evidence. Protocol
state machines belong in protocol repositories such as `mach-tls`.

## Modules

- `crypto.hmac` and `crypto.hkdf` define keyed hashing and derivation contracts.
- `crypto.aead.aes_gcm` and `crypto.aead.chacha20_poly1305` cover authenticated encryption.
- `crypto.group.p256` and `crypto.group.x25519` cover TLS key agreement.
- `crypto.signature` covers certificate signature algorithms.
- `crypto.encoding.der` and `crypto.encoding.pem` cover cryptographic containers.
- `crypto.vectors` defines a common test vector contract.
- `crypto.assurance` publishes the validation state of this package.

`crypto.lib` re-exports these modules for consumers that prefer one import.

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

Dependencies are local path dependencies. Build output is written to the shared
`.mach-out` directory beside this repository.

```sh
mach dep pull .
mach build .
mach test .
```
