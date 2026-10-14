# AGENTS.md

## Purpose

Binance USD-M Futures wire types, JSON codecs and HMAC-SHA256 request signing, with no I/O.
A client or simulator uses these types to talk to the Binance REST and websocket API, and
the docs in `docs/` record the API version the types follow.

## Layout

| Path | Holds |
| --- | --- |
| `lib/` | Library `binance_protocol`: primitives, REST request and response types, websocket messages, `Codec`, `Signature` (see `lib/AGENTS.md`) |
| `test/` | Expect and Quickcheck tests, recorded-minute decoding (see `test/AGENTS.md`) |
| `docs/` | `binance-usdm-spec.md`: the versioned API reference the types follow (see `docs/AGENTS.md`) |
| `.github/` | CI workflow (see `.github/AGENTS.md`) |
| `dune-project`, `binance-protocol.opam` | Package metadata; the `.opam` file is generated from `dune-project` |

There are no binaries.

## Build, test, docs

Run from this directory. The workspace root `..` holds the sibling checkouts and the shared
`dune-workspace`.

```sh
opam exec --switch 5.2.0+ox -- dune build --root .. @binance-protocol/all
opam exec --switch 5.2.0+ox -- dune build --root .. @binance-protocol/runtest
DUNE_BUILD_DIR=_build-binance-protocol opam exec --switch 5.2.0+ox -- dune build --root .. @binance-protocol/all
```

The last line is for parallel work: a private build directory avoids the lock shared with
other repositories in the workspace.

Standalone (outside the workspace), pin the siblings from GitHub as the CI workflow does,
then build:

```sh
opam pin add -n -y fixed-decimal https://github.com/winterchill-trading/fixed-decimal.git
opam pin add -n -y exchange-core https://github.com/winterchill-trading/exchange-core.git
opam install . --deps-only --with-test
dune build && dune test
```

## Conventions

- Formatting: `dune build --root .. @binance-protocol/fmt --auto-promote`, run after the tests
  pass. Never `dune fmt` at the workspace root; it reformats every sibling repository.
- Every module has an `.mli`. Use `open! Core`, labelled arguments and `ppx_jane`. Wire types
  derive `Codec.S` (`sexp`, `equal`, `yojson`) through `ppx_yojson_conv`.
- Response decoders ignore unknown fields. Keep it that way so new API fields do not break
  decoding.
- Primitives (`Price`, `Size`, `Symbol`, `Order_id`, ...) are re-exported from
  `exchange-core` with type equalities. Do not define a second copy.
- Mark every unverified payload shape in the source as `UNVERIFIED` and say which shape was
  assumed. The README lists them.
- Document every public value in its `.mli` with odoc comments.

## Dependencies and dependents

- Depends on: `fixed-decimal`, `exchange-core` (and `cryptokit` for HMAC).
- Used by: `binance-sim`, `binance-client`, `market-maker`.
- CI pin order: `fixed-decimal`, `exchange-core`.

## CI

`.github/workflows/ci.yml` runs the `ox-setup` action with the two pins above (its opam
switch is cached between runs), then `dune build` and `dune test`. The `obj-magic` job calls
the shared reusable workflow, which fails on `Obj.magic`, `Obj.repr` or `Obj.obj` in the
sources. To check a run: `gh run list --limit 1`, then at most one
`gh run watch <id> --exit-status`. Do not poll in a loop.

## Pitfalls

- Never name a library module `Error` or `Info`: `open! Core` hides it even inside the
  library. Use a name such as `Api_error`.
- Binance sends the same numeric value as a JSON number in some fields and as a string in
  others. Use the `Int_string` or `Bool_string` helpers in `Json` rather than a plain codec.
- `[@yojson.option]` accepts a missing field but rejects an explicit `null`. For fields the API
  sends as `null`, use `[@default None] [@yojson_drop_if Option.is_none]`.
- Records reject unknown fields unless `[@@yojson.allow_extra_fields]` is set; put it on every
  response type decoded from the API.
- `include Comparable.Make (T)` shadows `<` and `=` for the rest of the file. Put it at the
  end of the module, or write `Int.(n < 0)`.
- Derived variants encode as `["Ctor", ...]`, not as tagged objects. Hand-write codecs for
  variants that the API sends as strings.

## Where to read more

- `README.md` (module table, build, known gaps), `docs/binance-usdm-spec.md`.
- `../specs/repos/binance-protocol.md` for status and dependencies.
- Skills in `../oxcaml-claude-skills/skills/`: `janestreet-ocaml-style`.
- `../oxcaml-claude-skills/AGENTS.md`: the workspace-wide guide.
- `../oxcaml-claude-skills/GOTCHAS.md`: the dated log these pitfalls come from.

## Never do

- Run `opam install`, `opam upgrade` or `opam pin` on the shared `5.2.0+ox` switch without a
  dry run first: `opam install --switch 5.2.0+ox --dry-run <pkg>`. Abort if the plan touches
  `ocaml-variants`, `core`, `base`, `async` or `ppx_jane`.
- Publish, tag or release a version from this repository without the maintainers asking.
- Commit credentials or print secrets. Signing keys come from the environment.
- Poll CI in a loop.
