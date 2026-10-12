# binance-protocol

Binance USD-M Futures wire types and JSON codecs

Built with [OxCaml](https://oxcaml.org) and the Jane Street library stack (Base, Core).

The Binance counterpart of [hl-protocol](https://github.com/winterchill-trading/hl-protocol):
types, JSON codecs and request signing only, no I/O. The API reference these types follow
is versioned in [docs/binance-usdm-spec.md](docs/binance-usdm-spec.md).

## Build

```sh
opam switch create 5.2.0+ox --repos ox=git+https://github.com/oxcaml/opam-repository.git,default
opam pin add fixed-decimal https://github.com/winterchill-trading/fixed-decimal.git --no-action
opam pin add exchange-core https://github.com/winterchill-trading/exchange-core.git --no-action
opam install . --deps-only --with-test
dune build && dune test
```

## Modules

All modules live under `Binance_protocol`. Wire types satisfy `Codec.S` (`sexp`, `equal`,
`yojson`), with JSON matching the shapes of the USD-M Futures REST and websocket API.
Response decoders ignore unknown fields.

### Primitives

The venue-neutral primitives come from
[exchange-core](https://github.com/winterchill-trading/exchange-core) and are re-exported
with type equalities (`Binance_protocol.Price.t = Exchange_core.Price.t`, ...).

| Module | Description |
| --- | --- |
| `Price`, `Size`, `Usd` | `Exchange_core.Price`, `Size`, `Usd`, encoded as decimal strings |
| `Decimal` | Funding and interest rates, commissions, filter multipliers (decimal strings) |
| `Symbol` | `Exchange_core.Symbol`, uppercased (`"BTCUSDT"`); `to_stream_prefix` lowercases |
| `Side` | `Exchange_core.Side`: `"BUY"` / `"SELL"` |
| `Order_type` | `LIMIT`, `MARKET`; stop, take-profit and trailing types as `Other` |
| `Time_in_force` | `GTC`, `IOC`, `FOK`, `GTX` (post-only), `GTD`, `RPI`; conversions to and from `Exchange_core.Tif` |
| `Order_status` | `NEW`, `PARTIALLY_FILLED`, `FILLED`, `CANCELED`, `EXPIRED`, `EXPIRED_IN_MATCH`, `Other` |
| `Execution_type` | `NEW`, `CANCELED`, `CALCULATED`, `EXPIRED`, `TRADE`, `AMENDMENT`, `Other` |
| `Position_side` | `BOTH`, `LONG`, `SHORT` |
| `Working_type` | `MARK_PRICE`, `CONTRACT_PRICE` |
| `Timestamp_ms` | Milliseconds since the epoch, a JSON integer |
| `Order_id`, `Trade_id` | `Exchange_core.Order_id`, `Trade_id`, JSON integers |
| `Client_order_id` | `Exchange_core.Client_order_id`; `validate` checks Binance's request format |
| `Json` | Opaque JSON, decoding helpers, `Int_string` / `Bool_string` for string-encoded scalars |
| `Codec` | `module type S` satisfied by every wire type |

### REST

| Module | Endpoint |
| --- | --- |
| `Exchange_info` | `GET /fapi/v1/exchangeInfo`: symbols, filters (`PRICE_FILTER`, `LOT_SIZE`, `MIN_NOTIONAL`, ...), `to_instrument` |
| `Depth`, `Book_level` | `GET /fapi/v1/depth`, `[price, qty]` levels |
| `Book_ticker` | `GET /fapi/v1/ticker/bookTicker` |
| `Premium_index` | `GET /fapi/v1/premiumIndex`: mark and index price, funding |
| `Order` | Order object shared by the order endpoints below |
| `New_order` | `POST /fapi/v1/order`: request (`to_params`, `of_order_request`) and response |
| `Batch_orders` | `POST /fapi/v1/batchOrders`: up to 5 orders; per-item order or error |
| `Cancel_order` | `DELETE /fapi/v1/order` by `orderId` or `origClientOrderId` |
| `Cancel_all` | `DELETE /fapi/v1/allOpenOrders` |
| `Open_order` | `GET /fapi/v1/openOrders` item, `to_exchange_core` |
| `User_trade` | `GET /fapi/v1/userTrades` item |
| `Account` | `GET /fapi/v2/account` (also decodes v3) |
| `Position_risk` | `GET /fapi/v2/positionRisk` (also decodes v3) |
| `Listen_key` | `POST`/`PUT /fapi/v1/listenKey` |
| `Api_error` | `{"code", "msg"}` with known codes as a variant, `to_reject_reason` |
| `Query` | Form encoding of parameters in insertion order |
| `Signature` | HMAC-SHA256 hex signature (`sign`, `signed_query`), via cryptokit |

### WebSocket

| Module | Description |
| --- | --- |
| `Stream_name` | `<symbol>@depth[@100ms]`, `@depth5/10/20`, `@aggTrade`, `@bookTicker`, `@markPrice[@1s]` |
| `Subscribe` | `SUBSCRIBE` / `UNSUBSCRIBE` / `LIST_SUBSCRIPTIONS` requests and responses |
| `Combined` | `{"stream", "data"}` wrapper of `/stream` connections |
| `Depth_update` | `depthUpdate` (diff and partial depth) |
| `Agg_trade` | `aggTrade` |
| `Book_ticker_event` | `bookTicker` |
| `Mark_price_update` | `markPriceUpdate` |
| `Market_event` | Market payload decoded by `e` |
| `Order_trade_update` | `ORDER_TRADE_UPDATE` with the full order object |
| `Account_update` | `ACCOUNT_UPDATE` balances and positions (inner `a` flattened) |
| `Listen_key_expired` | `listenKeyExpired` |
| `User_event` | User-data payload decoded by `e` |

## Unverified shapes

The following were not confirmed by the fetched reference. Each is implemented in its
most common shape, marked `UNVERIFIED` in the source, and should be spot-checked against
a live message:

- Market stream payloads (`depthUpdate`, `aggTrade`, `bookTicker`, `markPriceUpdate`):
  field lists match the changelog, the examples are from memory.
- Partial-depth streams (`@depth5/10/20`) are assumed to send `depthUpdate` events. The
  changelog instead lists `lastUpdateId`, `E`, `T`, `bids`, `asks`; `Market_event` decodes
  that shape as `Depth_snapshot`.
- `ACCOUNT_UPDATE` position fields (`s`, `pa`, `ep`, `bep`, `cr`, `up`, `mt`, `iw`, `ps`).
- `ORDER_TRADE_UPDATE` expiry reason `er`: JSON type unknown, strings and integers are
  accepted.
- `exchangeInfo` filters other than `PRICE_FILTER` (`LOT_SIZE`, `MARKET_LOT_SIZE`,
  `MIN_NOTIONAL`, `MAX_NUM_ORDERS`, `MAX_NUM_ALGO_ORDERS`, `PERCENT_PRICE`).
- `batchOrders` request encoding: sent as a JSON array string with string values.
- The `GET /fapi/v2/account` example in the tests is assembled from the documented field
  list.

## Differences from the Binance API

- Numbers are re-encoded in their shortest form (`"0.00000"` becomes `"0"`), and digits
  past the 8th decimal place are dropped when parsing.
- Only the fields listed in each module are kept; optional or version-specific fields are
  `option`s and are omitted when re-encoding if absent. Booleans default to `false`.
- `Order_type` models only `LIMIT` and `MARKET`; other types round-trip as `Other`.
- Unknown `timeInForce` values in `exchangeInfo` symbols are dropped rather than failing
  the whole response.
- `New_order.Response` and `Cancel_order.Response` are the shared `Order.t`; `cumQuote`,
  `avgPrice` and `time` are options because the new-order response omits them.
- `REJECTED` is not an order status: rejections arrive as `Api_error.t`.
- Only HMAC-SHA256 signing is provided (no RSA or Ed25519 keys). Signing is pure: the caller
  supplies the timestamp.
- Unknown websocket events decode to `Unknown` in `Market_event` and `User_event`.
