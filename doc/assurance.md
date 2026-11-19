# Cryptographic assurance gate

`tools/assurance` turns the repository's tests and generated code into a
reproducible release record. It does not claim independent review. It keeps
algorithm availability, automated evidence, and human review as separate
facts.

## Release command

Run the gate from a clean, committed tree with the release compiler on `PATH`:

```sh
tools/assurance run
```

The gate first resolves the dependencies of the package and of every project it
tests, so it runs from a fresh clone or worktree. Resolution that would rewrite
a lock fails the clean-tree assertion instead. The command fails unless every
required command, manifest, dependency lock, test, target, profile, and
generated artifact is present. It publishes only a
complete run. Partial work remains in a temporary directory and is removed on
exit.

Successful evidence is written to an immutable timestamped directory below
`out/assurance/`. `out/assurance/current` points to the latest complete run.
The gate immediately verifies the published result before returning success.

## Evidence layers

The layers run separately so one kind of evidence cannot stand in for another:

1. Every package and focused test project runs in debug and release mode.
2. Each official-vector test runs alone in both profiles.
3. Each independent or differential test runs alone in both profiles.
4. Each hostile or invalid-input test runs alone in both profiles.
5. Each behavioral zeroization test runs alone in both profiles.
6. Every constant-time algorithm in `assurance/algorithms.tsv` is recorded as
   accepted by mach's secret-flow checker in the verified build of every
   target and profile. That the checker refuses what it must, among it a
   secret-dependent branch and a table read at a secret index, which is the
   shape the fixed-base comb tables must never take (they read every entry
   under a mask), is checked by mach's own test corpus, in `test/refuse/secret/`
   of the mach repository, which every compiler release runs. So are the
   targets on which mach admits a secret multiply as constant-time hardware,
   which decide where `crypto.internal.word` computes secret products in
   hardware: `test/run/secret/hard_admitted.mach` must build on each of them
   and `test/refuse/secret/hard_target.mach` is refused on the others.
7. Every project is built for every target its manifest declares and both
   profiles with emitted IR and emitted assembly (IR verification is mandatory
   in mach 5.0).
8. A second clean matrix build must produce byte-identical artifacts.
9. Every module named by `assurance/zeroization.tsv` must retain explicit
   calls to `std.crypto.ct.zeroize` in generated IR. Security-critical release
   assembly named by that policy must also reference it.

`assurance/tests.tsv` binds each focused test to its category, algorithm, and
vector or contract source. `assurance/algorithms.tsv` is the algorithm and
constant-time coverage inventory; its `hardware_multiply` column is `word`
when the algorithm's secret products go through `crypto.internal.word`
(`word.multiply` and `word.multiply_wide`, the processor's multiply where
`$mach.build.ct_mul` admits it as constant time and the bit-serial masked sum
elsewhere) and `none` when the algorithm performs no secret multiply. GHASH
in AES-GCM is bit-serial and does not use `word`. `assurance/projects.tsv` is
the complete build matrix. These files are release policy, not advisory
documentation.

## Machine-readable output

Each evidence directory contains:

- `metadata.tsv` with the Git commit, clean-tree assertion, exact compiler
  binary SHA-256, compiler version, dependency-lock SHA-256, policy SHA-256,
  targets, profiles, and creation time
- `results.tsv` with one result per independent test, build, leakage check, and
  zeroization inspection
- `artifacts.tsv` with the size and SHA-256 of every generated file from the
  second clean build
- `artifacts-pass-a.tsv` with the first clean build for reproducibility review
- `state.tsv` with functional availability, the automated assurance level, and
  independent review as separate columns
- `logs/` with Mach's NDJSON test output and build diagnostics
- `generated/` with the inspected IR and release assembly
- `evidence.sha256` covering every evidence file

TSV fields never contain tabs or newlines. Test logs retain Mach's native NDJSON
format.

## Freshness and verification

Run:

```sh
tools/assurance verify
```

Verification fails closed when the working tree is dirty, `HEAD` differs, the
compiler binary changes, the committed dependency pins under `dep/` change, policy changes, an evidence file
changes, a required status is not `PASS`, review state is conflated with
availability, or a live generated artifact is missing or has a different size
or hash.

Release automation should preserve the complete evidence directory as a build
artifact and must run `tools/assurance verify` immediately before creating a
tag. Copying only `state.tsv` is insufficient because its integrity and
provenance depend on the rest of the directory.

## Assurance state

The public `crypto.assurance.CURRENT` value is a source-only floor and therefore
remains `SCAFFOLD`. The release report can advance its `automated_level` to
`LEAKAGE_TESTED` only after every automated layer passes. This avoids a stale
source constant claiming evidence that is absent on the verifying machine.

`availability` reports whether implementations are callable. The
`independent_review` field reports only third-party review evidence. A
successful automated run does not change `independent_review` from
`NOT_RECORDED`.

## Performance

No test judges wall-clock time: mach's test policy keeps tests deterministic,
so the release gate carries no performance budget. The measurements below
characterize the implementation, and `test/benchmark/` measures AES-GCM on
demand.

On 2026-08-31, nine isolated warm release-profile NIST P-384 verification runs
took 110 through 113 milliseconds, with a 111-millisecond median, on an AMD
Ryzen 7 5800X3D 8-Core Processor with frequency boost disabled and Mach 4.26.5.
On 2026-09-19, with Mach 5.9.0 on the same machine, RSA-PSS with SHA-256 on
OpenSSL-generated 2048 and 3072-bit keys signed in 13.5 and 42 milliseconds and
verified in 0.32 and 0.66 milliseconds. Signing runs the private exponent
through a masked-scan windowed exponentiation, so its cost is the constant-time
cost of the full exponent width, not a fast path.
