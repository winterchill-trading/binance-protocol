# AGENTS.md (test/)

Expect and Quickcheck tests for the codecs and signing.

- `test_recorded_minute.ml` decodes a recorded minute of mainnet frames under
  `test/fixtures/`. Fixtures are data: do not edit them by hand.
- `test_signature.ml` pins signing against known vectors. A change there needs a reason.
- Promote expect output with `dune promote` only after reading the diff.
- Run: `dune build --root .. @binance-protocol/runtest` from the repository root.
