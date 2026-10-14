# AGENTS.md (lib/)

Library `binance_protocol`: types and codecs only, no I/O.

- Each wire type satisfies `Codec.S`. Keep REST types (`New_order`, `Account`, ...) and
  websocket types (`Depth_update`, `Market_event`, ...) in their own modules.
- `Signature` is HMAC-SHA256 over the query string in the form the client sends. The signing
  string must match what `Uri` actually sends.
- `Json` holds the helpers for string-encoded scalars; prefer them to new ad hoc codecs.
- A new module needs its `.mli` in the same commit.
- Build: `dune build --root .. @binance-protocol/all` from the repository root.
