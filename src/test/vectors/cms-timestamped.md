# cms-timestamped.der

A CMS SignedData (RFC 5652) whose one SignerInfo carries an RFC 3161
time-stamp token as its `id-aa-timeStampToken` unsigned attribute, written by
`tools/cms-timestamp-vector` on 2026-10-02.

- signer: a throwaway P-256 key and self-signed certificate, discarded after
  signing, over a fixed 39-byte content with `openssl cms -sign -nosmimecap`
- time stamp: https://freetsa.org/tsr, issued Oct  3 02:42:20 2026 GMT,
  over the SHA-256 of the signature value, with the TSA certificate requested
- checks: `openssl cms -verify` on the vector and `openssl ts -verify` of the
  token against the TSA's published chain (https://freetsa.org/files/cacert.pem)
- tool: OpenSSL 3.6.4 25 Aug 2026 (Library: OpenSSL 3.6.4 25 Aug 2026)
- size: 5463 bytes, token 4634 bytes
- deepest constructed content: level 19, counting the
  outer ContentInfo's content as level 1
- sha-256: cb6e7c2948079036feb7f78acb2c31df83dfe1133b5ec69d2a17a3d0e347dba5
