# Binance USD-M Futures API: implementer spec

Base REST: https://fapi.binance.com (testnet: https://demo-fapi.binance.com)
Base WS: wss://fstream.binance.com (testnet: wss://demo-fstream.binance.com)

## 0. Sources and verification status

- REST: official OpenAPI schema for "Futures (USDS-M) REST API" v1.0.0 (downloaded from the developers.binance.com catalog `rest-api/1.0.0/schema.yaml`). Field names, types, enums, examples and weights are taken from it. Schema-line references are given as "schema:<path>".
- Narrative rules (signing, timing, errors, limits, WebSocket routing, user-data events, listenKey lifetime): official full-text docs `https://developers.binance.com/en/docs/llms-full.txt` (downloaded and grepped locally; USDS-M sections are under "## Document: /products/derivatives-trading-usds-futures/...").
- The `/docs/derivatives/usds-margined-futures/...` HTML pages fetched with WebFetch were mostly landing pages or truncated, and were NOT used as the source for any field.
- Items not confirmed from these sources are marked **UNVERIFIED** and collected in section 10.

## 1. Conventions

- GET: parameters in query string. POST, PUT, DELETE: parameters in query string or body, `application/x-www-form-urlencoded`. Mixing is allowed; if a parameter appears in both, the query string value wins. Parameter order is free.
- All timestamps are milliseconds (int64). Data is returned oldest first.
- Numeric values in responses are JSON strings unless noted (price, qty, balances). Booleans and ints are native JSON types.
- Each endpoint has a security type: NONE, TRADE, USER_DATA (both signed), USER_STREAM (API key only), MARKET_DATA (API key only).
- Non-error responses are a JSON object or array. Errors: see section 3.

## 2. Authentication and signing

- Header on every key-required and signed endpoint: `X-MBX-APIKEY: <apiKey>` (case sensitive).
- SIGNED endpoints (TRADE and USER_DATA) need:
  - `timestamp` (int64, ms, current client time).
  - `recvWindow` (optional, int64, default 5000, max 60000; docs recommend <= 5000).
  - `signature` (string, must be the LAST parameter in the query string or body).
- `totalParams` = query string concatenated with the request body (exact string, as sent, no re-encoding stated in docs).
- `signature` = lowercase hex HMAC-SHA256(key = secretKey, message = totalParams). The docs say the signature is not case sensitive.
- Server acceptance rule: process only if `timestamp < serverTime + 1000` AND `serverTime - timestamp <= recvWindow`; otherwise reject with -1021.
- Worked example from the docs (for test vectors):
  - secretKey: `2b5eb11e18796d12d88f13dc27dbbd02c2cc51ff7059765ed9821957d82bb4d9`
  - apiKey: `dbefbc809e3e83c283a984c3a1459732ea7db1360ca80c5c2c8867408d28cc83`
  - totalParams: `symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=1&price=9000&timeInForce=GTC&recvWindow=5000&timestamp=1591702613943`
  - signature: `3c661234138461fcc7a7d8746c6558c9842d4e10870d2ecbedf7777cad694af9`
- Docs also show an RSA-key variant (not extracted; UNVERIFIED details).

## 3. Errors

Error payload (any endpoint):
```json
{
  "code": -1121,
  "msg": "Invalid symbol."
}
```
HTTP status: 4XX = malformed request (sender side). 403 = WAF limit violated. 408 = backend timeout. 429 = rate limit broken. 418 = IP auto-banned after ignoring 429s (2 min to 3 days). 5XX = Binance side.

HTTP 503 variants:
- "Unknown error, please check your request or try again later." = outcome UNKNOWN, may have succeeded. Do NOT treat as failure; verify before retrying.
- "Service Unavailable." = failure, retry later.
- "Internal error; unable to process your request. Please try again." = failure, safe to resend.
- "Request occur unknown error." (5XX) = retry later.

Error codes (from official error-code page):
| code | name | meaning |
|---|---|---|
| -1008 | Request Throttled | system-level protection; close-position, reduce-only and cancel are exempt. Retry with backoff. |
| -1021 | INVALID_TIMESTAMP | timestamp outside recvWindow (or >1000 ms ahead of server). Resync time / raise recvWindow. |
| -1022 | INVALID_SIGNATURE | signature invalid. |
| -1102 | MANDATORY_PARAM_EMPTY_OR_MALFORMED | mandatory param missing/empty/malformed. |
| -1111 | BAD_PRECISION | precision over the asset maximum. |
| -1115 | INVALID_TIF | invalid timeInForce. |
| -1116 | INVALID_ORDER_TYPE | invalid type. |
| -1117 | INVALID_SIDE | invalid side. |
| -1121 | BAD_SYMBOL | "Invalid symbol." |
| -1130 | INVALID_PARAMETER | data sent for a parameter is not valid. |
| -2010 | NEW_ORDER_REJECTED | generic new-order rejection. |
| -2011 | CANCEL_REJECTED | cancel failed; open order not found ("Unknown order sent"). |
| -2013 | NO_SUCH_ORDER | order does not exist. |
| -2018 | BALANCE_NOT_SUFFICIENT | balance insufficient. |
| -2019 | MARGIN_NOT_SUFFICIENT | margin insufficient. |
| -2020 | UNABLE_TO_FILL | unable to fill. |
| -2021 | ORDER_WOULD_IMMEDIATELY_TRIGGER | order would trigger immediately. |
| -2022 | REDUCE_ONLY_REJECT | "ReduceOnly Order is rejected." |
| -4000 | INVALID_ORDER_STATUS | |
| -4001 | PRICE_LESS_THAN_ZERO | |
| -4003 | QTY_LESS_THAN_ZERO | |
| -4005 | QTY_GREATER_THAN_MAX_QTY | |
| -4014 | PRICE_NOT_INCREASED_BY_TICK_SIZE | price not a multiple of tickSize. |
| -4016 | PRICE_HIGHTER_THAN_MULTIPLIER_UP | (sic) price above mark-price multiplier cap. |
| -4046 | NO_NEED_TO_CHANGE_MARGIN_TYPE | |
| -4061 | POSITION_SIDE_NOT_MATCH | positionSide does not match account mode. |
| -4062 | REDUCE_ONLY_CONFLICT | invalid or improper reduceOnly. |
| -4118 | REDUCE_ONLY_MARGIN_CHECK_FAILED | |
| -4131 | MARKET_ORDER_REJECT | counterparty best price fails PERCENT_PRICE filter. |
| -4164 | MIN_NOTIONAL | "Order's notional must be no smaller than 5.0 (unless you choose reduce only)". Message can show another value (%s). |
| -4400 | TRADING_QUANTITATIVE_RULE | only reduceOnly allowed for now. |
| -5021 | FOK_ORDER_REJECT | FOK could not fill immediately. |
| -5022 | GTX_ORDER_REJECT | "Due to the order could not be executed as maker, the Post Only order will be rejected." (GTX) |

Error responses for batch orders come back per-item (see 5.4).

## 4. Rate limits (summary)

- Request weight is per IP. Responses carry `X-MBX-USED-WEIGHT-1M`-style headers.
- Order limits are per account. Responses carry `X-MBX-ORDER-COUNT-10S` and `X-MBX-ORDER-COUNT-1M`.
- Breaking a limit returns HTTP 429; keep sending and you get 418.
- Current limits are in `GET /fapi/v1/exchangeInfo` `rateLimits`. The schema example shows one entry: `{"interval":"MINUTE","intervalNum":1,"limit":2400,"rateLimitType":"REQUEST_WEIGHT"}`. Other entries (e.g. order limits) are UNVERIFIED.

## 5. REST endpoints

### 5.1 GET /fapi/v1/exchangeInfo
- Security: NONE. Weight: 1. Params: none.
- Response top-level keys (order): `exchangeFilters`, `rateLimits`, `serverTime`, `assets`, `symbols`, `timezone`.
- `serverTime` is documented as "ignore"; use `GET /fapi/v1/time`.
- `assets[]`: `asset` (string), `marginAvailable` (bool), `autoAssetExchange` (string).
- `symbols[]` fields (schema): `symbol`, `pair`, `contractType`, `deliveryDate` (int64), `onboardDate` (int64), `status`, `maintMarginPercent` (ignore), `requiredMarginPercent` (ignore), `baseAsset`, `quoteAsset`, `marginAsset`, `pricePrecision` (int64, DO NOT use as tickSize), `quantityPrecision` (int64, DO NOT use as stepSize), `baseAssetPrecision`, `quotePrecision`, `underlyingType`, `underlyingSubType` (string[]), `settlePlan` (int64), `triggerProtect` (string, threshold for algo orders with priceProtect), `filters` (object[]), `orderTypes` (string[]), `timeInForce` (string[]), `liquidationFee` (string), `marketTakeBound` (string; max deviation from mark price for market orders).
- `filters[]` object fields (schema): `filterType`, `maxPrice`, `minPrice`, `tickSize`, `maxQty`, `minQty`, `stepSize`, `limit` (int64), `notional`, `multiplierUp`, `multiplierDown`, `multiplierDecimal`. Each filter object carries only the fields relevant to its type.
- Example response (schema example values, one symbol, one PRICE_FILTER):
```json
{
  "exchangeFilters": [""],
  "rateLimits": [
    {"interval": "MINUTE", "intervalNum": 1, "limit": 2400, "rateLimitType": "REQUEST_WEIGHT"}
  ],
  "serverTime": 1565613908500,
  "assets": [
    {"asset": "BTC", "marginAvailable": true, "autoAssetExchange": "-0.10"}
  ],
  "symbols": [
    {
      "symbol": "BLZUSDT",
      "pair": "BLZUSDT",
      "contractType": "PERPETUAL",
      "deliveryDate": 4133404800000,
      "onboardDate": 1598252400000,
      "status": "TRADING",
      "maintMarginPercent": "2.5000",
      "requiredMarginPercent": "5.0000",
      "baseAsset": "BLZ",
      "quoteAsset": "USDT",
      "marginAsset": "USDT",
      "pricePrecision": 5,
      "quantityPrecision": 0,
      "baseAssetPrecision": 8,
      "quotePrecision": 8,
      "underlyingType": "COIN",
      "underlyingSubType": ["STORAGE"],
      "settlePlan": 0,
      "triggerProtect": "0.15",
      "filters": [
        {
          "filterType": "PRICE_FILTER",
          "maxPrice": "300",
          "minPrice": "0.0001",
          "tickSize": "0.0001",
          "maxQty": "10000000",
          "minQty": "1",
          "stepSize": "1",
          "limit": 200,
          "notional": "5.0",
          "multiplierUp": "1.1500",
          "multiplierDown": "0.8500",
          "multiplierDecimal": "4"
        }
      ],
      "orderTypes": ["LIMIT"],
      "timeInForce": ["GTC"],
      "liquidationFee": "0.010000",
      "marketTakeBound": "0.30"
    }
  ],
  "timezone": "UTC"
}
```
- Filter usage: tickSize comes from PRICE_FILTER.tickSize; quantity step from LOT_SIZE.stepSize; min notional from MIN_NOTIONAL.notional. The schema example contains only the PRICE_FILTER object (it also carries `stepSize`, `minQty`, `maxQty`, `notional`). The exact `filterType` string values `LOT_SIZE` and `MIN_NOTIONAL` and their example JSON are **UNVERIFIED** (see section 10). The -4164 error message confirms the 5.0 minimum notional.

### 5.2 GET /fapi/v1/depth
- Security: NONE. Weight: 2 (limit 5/10/20/50), 5 (100), 10 (500), 1000 -> 20.
- Params: `symbol` (string, required, e.g. BTCUSDT); `limit` (int64, optional; valid [5, 10, 20, 50, 100, 500, 1000]; default 500; max 1000).
- Response fields: `lastUpdateId` (int64), `E` (int64, message output time), `T` (int64, transaction/matching time), `bids` (array of [price, qty] string pairs), `asks` (same).
- RPI orders are excluded from this endpoint.
- Example (schema):
```json
{
  "lastUpdateId": 1027024,
  "E": 1589436922972,
  "T": 1589436922959,
  "bids": [
    ["4.00000000", "431.00000000"]
  ],
  "asks": [
    ["4.00000200", "12.00000000"]
  ]
}
```

### 5.3 GET /fapi/v1/ticker/bookTicker
- Security: NONE. Weight: 2 (single symbol), 5 (symbol omitted).
- Params: `symbol` (string, optional). Omit to get all symbols (array).
- Response (single object when symbol given; an array of the same objects otherwise):
  `symbol`, `bidPrice`, `bidQty`, `askPrice`, `askQty` (all strings), `time` (int64, transaction time). No `lastUpdateId`.
- Example (schema):
```json
{
  "symbol": "BTCUSDT",
  "bidPrice": "4.00000000",
  "bidQty": "431.00000000",
  "askPrice": "4.00000200",
  "askQty": "9.00000000",
  "time": 1589437530011
}
```
- RPI orders excluded.

### 5.4 GET /fapi/v1/premiumIndex
- Security: NONE. Weight: 1 with symbol, 10 without.
- Params: `symbol` (string, optional, e.g. BTCUSDT).
- Response fields: `symbol`, `markPrice`, `indexPrice`, `estimatedSettlePrice` (only meaningful in the last hour before settlement), `lastFundingRate`, `interestRate` (all strings), `nextFundingTime` (int64), `time` (int64).
- Example (official docs, values as shown on the page; field names match the schema):
```json
{
  "symbol": "BTCUSDT",
  "markPrice": "11793.63104562",
  "indexPrice": "11781.80495970",
  "estimatedSettlePrice": "11781.16138815",
  "lastFundingRate": "0.00038246",
  "interestRate": "0.00010000",
  "nextFundingTime": 1597392000000,
  "time": 1597370495002
}
```

### 5.5 POST /fapi/v1/order (New Order, TRADE)
- Weight: 1 on 10s order limit (`X-MBX-ORDER-COUNT-10S`), 1 on 1m order limit (`X-MBX-ORDER-COUNT-1M`), 0 on IP weight.
- Params:

| name | type | required | values / notes |
|---|---|---|---|
| symbol | string | yes | e.g. BTCUSDT |
| side | string | yes | BUY, SELL |
| positionSide | string | no | BOTH (default, one-way mode), LONG, SHORT (hedge mode). Must be sent in hedge mode. |
| type | string | yes | LIMIT, MARKET, STOP, STOP_MARKET, TAKE_PROFIT, TAKE_PROFIT_MARKET, TRAILING_STOP_MARKET |
| timeInForce | string | conditional | GTC, IOC, FOK, GTX, GTD, RPI. Mandatory for LIMIT. |
| quantity | number | conditional | Mandatory for LIMIT and MARKET. |
| price | number | conditional | Mandatory for LIMIT. |
| reduceOnly | string | no | "true" / "false" (default "false"). Cannot be sent in hedge mode. |
| newClientOrderId | string | no | Unique among open orders; regex `^[\.A-Z\:/a-z0-9_-]{1,36}$`. Auto-generated if omitted. |
| newOrderRespType | string | no | ACK (default), RESULT. |
| priceMatch | string | no | OPPONENT, OPPONENT_5, OPPONENT_10, OPPONENT_20, QUEUE, QUEUE_5, QUEUE_10, QUEUE_20. Only LIMIT/STOP/TAKE_PROFIT. Not with `price`. |
| selfTradePreventionMode | string | no | EXPIRE_TAKER, EXPIRE_BOTH, EXPIRE_MAKER (default EXPIRE_MAKER). Effective only for timeInForce IOC, GTC, GTD. |
| goodTillDate | int64 | conditional | Required when timeInForce=GTD. Must be > now + 600 s and < 253402300799000. Seconds precision only. |
| recvWindow | int64 | no | max 60000 |
| timestamp | int64 | yes | ms |

- Notes from docs: with newOrderRespType=RESULT, MARKET returns the final FILLED result; LIMIT with special TIF returns final FILLED or EXPIRED.
- Example response (schema, first example; a LIMIT GTD order):
```json
{
  "clientOrderId": "testOrder",
  "cumQty": "0",
  "executedQty": "0",
  "orderId": 22542179,
  "origQty": "10",
  "price": "0",
  "reduceOnly": false,
  "side": "SELL",
  "positionSide": "SHORT",
  "status": "NEW",
  "stopPrice": "0",
  "closePosition": false,
  "symbol": "BTCUSDT",
  "timeInForce": "GTD",
  "type": "LIMIT",
  "origType": "LIMIT",
  "updateTime": 1566818724722,
  "workingType": "CONTRACT_PRICE",
  "priceProtect": false,
  "priceMatch": "NONE",
  "selfTradePreventionMode": "EXPIRE_MAKER",
  "goodTillDate": 1693207680000
}
```
- IMPORTANT deviations from the request brief:
  - The 200 response schema has `cumQty`, NOT `cumQuote`, and has NO `avgPrice`. `cumQuote` and `avgPrice` appear in `GET /fapi/v1/openOrders` items (5.9), not in this response.
  - The status enum documented in the schema and the ORDER_TRADE_UPDATE docs is: NEW, PARTIALLY_FILLED, FILLED, CANCELED, EXPIRED, EXPIRED_IN_MATCH. `REJECTED` does not appear in the docs; rejections come back as an error object `{code, msg}` (e.g. -2022, -4164, -5022), not as an order with status REJECTED.
  - The documented `type` and `timeInForce` enums are wider than the brief (see table above; they include STOP*, TAKE_PROFIT*, TRAILING_STOP_MARKET, GTD, RPI).

### 5.6 POST /fapi/v1/batchOrders (Place Multiple Orders, TRADE)
- Weight: 5 on 10s order limit, 1 on 1m order limit, 5 on IP weight.
- Body params: `batchOrders` (array, required, MAX 5 orders), `timestamp` (required), `recvWindow` (max 60000).
- Each element uses the same fields as New Order (5.5): `symbol`, `side`, `positionSide`, `type`, `timeInForce`, `quantity`, `reduceOnly`, `price`, `newClientOrderId`, `newOrderRespType`, `priceMatch`, `selfTradePreventionMode`, `goodTillDate`. Same rules as 5.5.
- Orders are processed concurrently; matching order is not guaranteed. Response array is in the same order as the submitted list.
- The schema's `batchOrders` example is `[]`. Encoding of the array in a form body (JSON array string) is **UNVERIFIED**.
- Example response (schema): array of per-order results, a rejected item looks like:
```json
[
  {
    "clientOrderId": "testOrder",
    "cumQty": "0",
    "executedQty": "0",
    "orderId": 22542179,
    "origQty": "10",
    "price": "0",
    "reduceOnly": false,
    "side": "SELL",
    "positionSide": "SHORT",
    "status": "NEW",
    "stopPrice": "0",
    "closePosition": false,
    "symbol": "BTCUSDT",
    "timeInForce": "GTD",
    "type": "LIMIT",
    "origType": "LIMIT",
    "updateTime": 1566818724722,
    "workingType": "CONTRACT_PRICE",
    "priceProtect": false,
    "priceMatch": "NONE",
    "selfTradePreventionMode": "EXPIRE_MAKER",
    "goodTillDate": 1693207680000
  },
  {
    "code": -2022,
    "msg": "ReduceOnly Order is rejected."
  }
]
```
- Implementer rule: each element is either an order object or `{code, msg}`. Check per element.

### 5.7 DELETE /fapi/v1/order (Cancel Order, TRADE)
- Weight: 1 (IP).
- Params: `symbol` (required). `orderId` (int64) OR `origClientOrderId` (string): at least one is required. `recvWindow`, `timestamp` (required).
- Example response (schema):
```json
{
  "clientOrderId": "myOrder1",
  "cumQty": "0",
  "executedQty": "0",
  "orderId": 283194212,
  "origQty": "11",
  "price": "0",
  "reduceOnly": false,
  "side": "BUY",
  "positionSide": "SHORT",
  "status": "CANCELED",
  "stopPrice": "9300",
  "closePosition": false,
  "symbol": "BTCUSDT",
  "timeInForce": "GTC",
  "origType": "TRAILING_STOP_MARKET",
  "type": "TRAILING_STOP_MARKET",
  "activatePrice": "9020",
  "priceRate": "0.3",
  "updateTime": 1571110484038,
  "workingType": "CONTRACT_PRICE",
  "priceProtect": false,
  "priceMatch": "NONE",
  "selfTradePreventionMode": "EXPIRE_MAKER",
  "goodTillDate": 0
}
```
- `activatePrice` and `priceRate` are returned only for TRAILING_STOP_MARKET. `stopPrice` is ignored for TRAILING_STOP_MARKET.

### 5.8 DELETE /fapi/v1/allOpenOrders (Cancel All Open Orders, TRADE)
- Weight: 1 (IP). Params: `symbol` (required), `recvWindow`, `timestamp` (required).
- Example response (schema):
```json
{
  "code": 200,
  "msg": "The operation of cancel all open order is done."
}
```

### 5.9 GET /fapi/v1/openOrders (Current All Open Orders, USER_DATA)
- Weight: 1 with symbol, 40 when symbol omitted (schema x-weight).
- Params: `symbol` (optional per schema), `recvWindow`, `timestamp` (required). Signed.
- Response: array of order objects. Fields (schema order): `avgPrice`, `clientOrderId`, `cumQuote`, `executedQty`, `orderId`, `origQty`, `origType`, `price`, `reduceOnly`, `side`, `positionSide`, `status`, `stopPrice`, `closePosition`, `symbol`, `time` (int64), `timeInForce`, `type`, `activatePrice`, `priceRate`, `updateTime` (int64), `workingType`, `priceProtect`, `priceMatch`, `selfTradePreventionMode`, `goodTillDate` (int64).
- Example (schema, one element):
```json
[
  {
    "avgPrice": "0.00000",
    "clientOrderId": "abc",
    "cumQuote": "0",
    "executedQty": "0",
    "orderId": 1917641,
    "origQty": "0.40",
    "origType": "TRAILING_STOP_MARKET",
    "price": "0",
    "reduceOnly": false,
    "side": "BUY",
    "positionSide": "SHORT",
    "status": "NEW",
    "stopPrice": "9300",
    "closePosition": false,
    "symbol": "BTCUSDT",
    "time": 1579276756075,
    "timeInForce": "GTC",
    "type": "TRAILING_STOP_MARKET",
    "activatePrice": "9020",
    "priceRate": "0.3",
    "updateTime": 1579276756075,
    "workingType": "CONTRACT_PRICE",
    "priceProtect": false,
    "priceMatch": "NONE",
    "selfTradePreventionMode": "EXPIRE_MAKER",
    "goodTillDate": 0
  }
]
```

### 5.10 GET /fapi/v1/userTrades (Account Trade List, USER_DATA)
- Weight: 5 (schema x-ip-weight). Signed.
- Params: `symbol` (required), `orderId` (int64, optional, must be used with symbol), `startTime`, `endTime` (int64), `fromId` (int64; default most recent), `limit` (int64; default 500, max 1000), `recvWindow` (max 60000), `timestamp` (required).
- Docs notes (from the official page via WebFetch, not cross-checked in the schema): if startTime and endTime are both omitted the last 7 days are returned; the window cannot exceed 7 days; fromId cannot be combined with startTime/endTime; only the last 3 months are queryable.
- Response: array. Fields: `buyer` (bool), `commission` (string), `commissionAsset`, `id` (int64, trade id), `maker` (bool), `orderId` (int64), `price`, `qty`, `quoteQty`, `baseQty`, `marginAsset`, `realizedPnl`, `side`, `positionSide`, `symbol`, `pair`, `time` (int64).
- Example (official page; field names confirmed by the schema for quoteQty/baseQty/realizedPnl/positionSide):
```json
[
  {
    "buyer": false,
    "commission": "0.07819010",
    "commissionAsset": "USDT",
    "id": 698759,
    "maker": false,
    "orderId": 25851813,
    "price": "7819.01",
    "qty": "0.002",
    "quoteQty": "15.63802",
    "baseQty": "0",
    "marginAsset": "USDT",
    "realizedPnl": "-0.91539999",
    "side": "SELL",
    "positionSide": "SHORT",
    "symbol": "BTCUSDT",
    "pair": "BTCUSDT",
    "time": 1569514978020
  }
]
```

### 5.11 GET /fapi/v3/account (Account Information V3, USER_DATA)
- Weight: 5. Signed. Params: `recvWindow`, `timestamp` (required).
- Top-level fields (schema example): `totalWalletBalance`, `totalMarginBalance`, `availableBalance`, `maxWithdrawAmount`, `totalCrossWalletBalance` = "126.72469206" in example; `totalInitialMargin`, `totalMaintMargin`, `totalUnrealizedProfit`, `totalPositionInitialMargin`, `totalOpenOrderInitialMargin`, `totalCrossUnPnl` = "0.00000000". The schema example does not show the full top-level set beyond these; **UNVERIFIED** whether further top-level keys exist.
- `assets[]` (schema, all strings except updateTime): `asset`, `walletBalance`, `unrealizedProfit`, `marginBalance`, `maintMargin`, `initialMargin`, `positionInitialMargin`, `openOrderInitialMargin`, `crossWalletBalance`, `crossUnPnl`, `availableBalance`, `maxWithdrawAmount`, `updateTime` (int64).
- `positions[]` (schema, all strings except updateTime): `symbol`, `positionSide`, `positionAmt`, `unrealizedProfit`, `isolatedMargin`, `notional`, `isolatedWallet`, `initialMargin`, `maintMargin`, `updateTime` (int64). Schema describes positions as "positions of all symbols user had position/open orders are returned".
- **The v3 positions object has NO `entryPrice`, `leverage` or `liquidationPrice`.** Use positionRisk (5.13) for those.
- Example (schema):
```json
{
  "totalWalletBalance": "126.72469206",
  "totalUnrealizedProfit": "0.00000000",
  "totalMarginBalance": "126.72469206",
  "totalPositionInitialMargin": "0.00000000",
  "totalOpenOrderInitialMargin": "0.00000000",
  "totalCrossWalletBalance": "126.72469206",
  "totalCrossUnPnl": "0.00000000",
  "availableBalance": "126.72469206",
  "maxWithdrawAmount": "126.72469206",
  "assets": [
    {
      "asset": "USDT",
      "walletBalance": "23.72469206",
      "unrealizedProfit": "0.00000000",
      "marginBalance": "23.72469206",
      "maintMargin": "0.00000000",
      "initialMargin": "0.00000000",
      "positionInitialMargin": "0.00000000",
      "openOrderInitialMargin": "0.00000000",
      "crossWalletBalance": "23.72469206",
      "crossUnPnl": "0.00000000",
      "availableBalance": "23.72469206",
      "maxWithdrawAmount": "23.72469206",
      "updateTime": 1625474304765
    }
  ],
  "positions": [
    {
      "symbol": "BTCUSDT",
      "positionSide": "BOTH",
      "positionAmt": "1.000",
      "unrealizedProfit": "0.00000000",
      "isolatedMargin": "0.00000000",
      "notional": "0",
      "isolatedWallet": "0",
      "initialMargin": "0",
      "maintMargin": "0",
      "updateTime": 0
    }
  ]
}
```
- Note: the top-level sample values in the schema are `totalWalletBalance`/`totalMarginBalance`/`availableBalance`/`maxWithdrawAmount`/`totalCrossWalletBalance` = "126.72469206" and the others "0.00000000". The example above reflects that.

### 5.12 GET /fapi/v2/account (Account Information V2, USER_DATA) [for leverage/entryPrice]
- Weight: 5. Signed.
- Top-level fields (schema): `feeTier`, `feeBurn`, `canTrade`, `canDeposit`, `canWithdraw`, `updateTime`, `multiAssetsMargin`, `tradeGroupId`, `totalInitialMargin`, `totalMaintMargin`, `totalWalletBalance`, `totalUnrealizedProfit`, `totalMarginBalance`, `totalPositionInitialMargin`, `totalOpenOrderInitialMargin`, `totalCrossWalletBalance`, `totalCrossUnPnl`, `availableBalance`, `maxWithdrawAmount`, `assets[]`, `positions[]`.
- `positions[]` fields (schema): `symbol`, `initialMargin`, `maintMargin`, `unrealizedProfit`, `positionInitialMargin`, `openOrderInitialMargin`, `leverage`, `isolated` (bool), `entryPrice`, `maxNotional`, `bidNotional`, `askNotional`, `positionSide`, `positionAmt`, `updateTime` (int64).
- Example positions element (schema): `{"symbol":"BTCUSDT","initialMargin":"0","maintMargin":"0","unrealizedProfit":"0.00000000","positionInitialMargin":"0","openOrderInitialMargin":"0","leverage":"100","isolated":true,"entryPrice":"0.00000","maxNotional":"250000","bidNotional":"0","askNotional":"0","positionSide":"BOTH","positionAmt":"0","updateTime":0}`
- Full v2 top-level example values are not extracted; **UNVERIFIED** beyond the field list.

### 5.13 GET /fapi/v3/positionRisk (Position Information V3, USER_DATA)
- Weight: 5. Signed. Params: `symbol` (optional), `recvWindow`, `timestamp` (required).
- Response: array. Fields (schema): `symbol`, `positionSide`, `positionAmt` (positive long, negative short), `entryPrice`, `breakEvenPrice`, `markPrice`, `unRealizedProfit`, `liquidationPrice`, `isolatedMargin`, `notional`, `marginAsset`, `isolatedWallet`, `initialMargin`, `maintMargin`, `positionInitialMargin`, `openOrderInitialMargin`, `adl` (int, ADL ranking), `bidNotional` (ignore), `askNotional` (ignore), `updateTime` (int64).
- **v3 positionRisk has NO `leverage` and NO `marginType` field in the schema.** Use v2 (5.14) if leverage is needed.
- Example (schema, one element):
```json
[
  {
    "symbol": "ADAUSDT",
    "positionSide": "BOTH",
    "positionAmt": "30",
    "entryPrice": "0.385",
    "breakEvenPrice": "0.385077",
    "markPrice": "0.41047590",
    "unRealizedProfit": "0.76427700",
    "liquidationPrice": "0",
    "isolatedMargin": "0",
    "notional": "12.31427700",
    "marginAsset": "USDT",
    "isolatedWallet": "0",
    "initialMargin": "0.61571385",
    "maintMargin": "0.08004280",
    "positionInitialMargin": "0.61571385",
    "openOrderInitialMargin": "0",
    "adl": 2,
    "bidNotional": "0",
    "askNotional": "0",
    "updateTime": 1720736417660
  }
]
```

### 5.14 GET /fapi/v2/positionRisk (USER_DATA) [for leverage]
- Params: `symbol` (optional), `recvWindow`, `timestamp`. Signed. Weight: not extracted (UNVERIFIED).
- Response fields (schema): `entryPrice`, `breakEvenPrice`, `marginType`, `isAutoAddMargin`, `isolatedMargin`, `leverage`, `liquidationPrice`, `markPrice`, `maxNotionalValue`, `positionAmt`, `notional`, `isolatedWallet`, `symbol`, `unRealizedProfit`, `positionSide`, `updateTime`.
- Example element (schema):
```json
{
  "entryPrice": "0.00000",
  "breakEvenPrice": "0.0",
  "marginType": "isolated",
  "isAutoAddMargin": "false",
  "isolatedMargin": "0.00000000",
  "leverage": "10",
  "liquidationPrice": "0",
  "markPrice": "6679.50671178",
  "maxNotionalValue": "20000000",
  "positionAmt": "0.000",
  "notional": "0",
  "isolatedWallet": "0",
  "symbol": "BTCUSDT",
  "unRealizedProfit": "0.00000000",
  "positionSide": "BOTH",
  "updateTime": 1625474304765
}
```

### 5.15 POST /fapi/v1/listenKey (Start User Data Stream, USER_STREAM)
- Security: API key header only (no signature). Weight: 1.
- Response: `{"listenKey": "<string>"}`. Example (schema): `{"listenKey": "pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1"}`
- Semantics: the key is valid 60 minutes after creation. If the account already has an active listenKey, POST returns that key and extends its validity by 60 minutes.

### 5.16 PUT /fapi/v1/listenKey (Keepalive, USER_STREAM)
- Security: API key header only. Weight: 1. No other params.
- Extends validity by 60 minutes. Send about every 60 minutes.
- If the response is -1125 ("This listenKey does not exist."), recreate with POST /fapi/v1/listenKey.
- Example (schema): `{"listenKey": "3HBntNTepshgEdjIwSUIBgB9keLyOCg5qv3n6bYAtktG8ejcaW5HXz9Vx1JgIieg"}`

### 5.17 DELETE /fapi/v1/listenKey (Close User Data Stream, USER_STREAM)
- Security: API key header. Weight: 1. Closes the stream and invalidates the key. Response code 200 (schema body not extracted).

## 6. WebSocket market streams (public / market data)

### 6.1 Connection
- Routed endpoints (USD-M only; required path matters):
  - `wss://fstream.binance.com/public`: high-frequency public data, e.g. `@depth`.
  - `wss://fstream.binance.com/market`: regular market data, e.g. `@aggTrade`, `@markPrice`.
  - `wss://fstream.binance.com/private`: user data.
- A connection with NO routed path (`wss://fstream.binance.com/ws/...` or `/stream?...`) receives only Public data. `@depth` works there; `@markPrice`, `@aggTrade` and `@bookTicker` assigned to `/market` will NOT deliver. This fails silently. **Use /public or /market explicitly** (confirmed against the Connect and CaaS market-data docs; per-stream routing for `@bookTicker` is not stated and is UNVERIFIED).
- Two access modes:
  - `ws` mode: `wss://fstream.binance.com/market/ws/<streamName>` (multiple: `/ws/a@x/b@y`).
  - `stream` mode: `wss://fstream.binance.com/market/stream?streams=<streamName1>/<streamName2>`.
  - Examples: `wss://fstream.binance.com/market/ws/bnbusdt@aggTrade`, `wss://fstream.binance.com/public/ws/bnbusdt@depth/ethusdt@depth`, `wss://fstream.binance.com/market/stream?streams=bnbusdt@aggTrade/btcusdt@markPrice`.
- Stream names: symbols are lowercase.
- Combined stream wrapper: `{"stream":"<streamName>","data":<rawPayload>}`.
- Limits: 24 hours max per connection (expect disconnect). Max 1024 streams per connection. Max 10 incoming messages per second per connection; exceeding disconnects (repeated disconnects can lead to a ban).

### 6.2 Ping/pong
- The server sends a ping frame every 3 minutes.
- The client must reply with a pong. If no pong arrives within 10 minutes, the connection is closed.
- Unsolicited pong frames are allowed. Sending one more often than every 15 min keeps the connection alive. (A ping/pong rate limit of 5 per second is documented for the WebSocket API section, not verified for market streams.)

### 6.3 Live subscribe / unsubscribe
Request is JSON sent on the open socket. `id` is an unsigned int used to match replies.
```json
{"method": "SUBSCRIBE", "params": ["btcusdt@aggTrade", "btcusdt@depth"], "id": 1}
```
Response: `{"result": null, "id": 1}`
```json
{"method": "UNSUBSCRIBE", "params": ["btcusdt@depth"], "id": 312}
```
Response: `{"result": null, "id": 312}`
```json
{"method": "LIST_SUBSCRIPTIONS", "id": 3}
```
Response: `{"result": ["btcusdt@aggTrade"], "id": 3}`

Error response examples (official): `{"code": 0, "msg": "Unknown property"}`; `{"code": 1, "msg": "Invalid value type: expected Boolean"}`; `{"code": 2, "msg": "Invalid request: property name must be a string"}`; `{"code": 2, "msg": "Invalid request: request ID must be an unsigned integer"}`; `{"code": 2, "msg": "Invalid request: too many parameters"}`; `{"code": 2, "msg": "Invalid request: missing field `method` at line 1 column 73"}`; `{"code": 3, "msg": "Invalid JSON: expected value at line %s column %s"}`.

### 6.4 Stream names (USD-M)
| stream | name | update speed (docs) |
|---|---|---|
| Diff. depth | `<symbol>@depth` / `<symbol>@depth@100ms` | 100 ms verified (changelog: "Faster diff data with 100ms updates"); 1000 ms default UNVERIFIED |
| Partial depth | `<symbol>@depth<levels>` / `<symbol>@depth<levels>@100ms`; levels 5, 10, 20 | changelog 2020-07-22 |
| Partial depth 500ms | `<symbol>@depth<level>@500ms` | changelog (level set not restated) |
| aggTrade | `<symbol>@aggTrade` | |
| markPrice | `<symbol>@markPrice` / `<symbol>@markPrice@1s` | `@1s` = 1 second updates |
| bookTicker | `<symbol>@bookTicker` | |
| all markPrice | `!markPrice@arr`, `!markPrice@arr@1s` | |
| all bookTicker | `!bookTicker` | |

### 6.5 Payloads
- Diff depth `<symbol>@depth`: field list (changelog and docs mention): `e` ("depthUpdate"), `E`, `T`, `s`, `U` (first update id), `u` (final update id), `pu` (previous final update id), `b` (bids [price, qty][]), `a` (asks). **Full example payload: UNVERIFIED** (the only verified example is the Spot testnet one, which is not USD-M).
- Partial depth `<symbol>@depth<levels>`: fields `lastUpdateId`, `E`, `T`, `bids`, `asks` (per changelog and docs). **Example: UNVERIFIED.**
- aggTrade `<symbol>@aggTrade`: fields `e`, `E`, `s`, `a`, `p`, `q`, `f`, `l`, `T`, `m`, and `nq` (per changelog, effective 2025-12-31). **Example: UNVERIFIED.**
- markPrice: fields `e`, `E`, `s`, `p` (mark), `P` (estimated settle price), `i` (index price, changelog), `r` (funding rate), `T` (next funding time). **Example: UNVERIFIED.**
- bookTicker: fields `e` (changelog: new field), `u`, `E`, `T`, `s`, `b`, `B`, `a`, `A`. **Example: UNVERIFIED.**

### 6.6 Local order book procedure (official)
1. Open `wss://fstream.binance.com/public/stream?streams=<symbol>@depth`.
2. Buffer events. Same price: latest update wins.
3. Get snapshot: `GET https://fapi.binance.com/fapi/v1/depth?symbol=BTCUSDT&limit=1000`.
4. Drop any event with `u < lastUpdateId`.
5. The first processed event must satisfy `U <= lastUpdateId AND u >= lastUpdateId`.
6. Each new event's `pu` must equal the previous event's `u`; otherwise restart from step 3.
7. Quantities are ABSOLUTE for each price level. Quantity 0 means remove the level.
8. Removing a level not in your book can happen and is normal.

## 7. User data stream

### 7.1 Connection
- Base: `wss://fstream.binance.com/private`. Path: `wss://fstream.binance.com/private/ws/<listenKey>`.
- Example: `wss://fstream.binance.com/private/ws/XaEAKTsQSRLZAGH9tuIu37plSRsdjmlAVBoNYPUITlTAko1WI22PgmBMpI1rS8Yh`
- Connection rules: 24 hours max per connection; ping/pong rules as in 6.2.
- The change notice mentions a legacy form `wss://fstream.binance.com/ws/<listenKey>` and says the private endpoint supports listenKey plus events subscriptions (details UNVERIFIED).
- Ordering: messages of the same event type on one connection are strictly ordered by both `T` and `E`. For cross-type ordering use `E` (docs recommend it).
- Prefer WS user-data over REST for order/position state (REST can lag in volatile markets).

### 7.2 Event: ORDER_TRADE_UPDATE
- Envelope: `e` = "ORDER_TRADE_UPDATE", `E` (event time, ms), `T` (transaction time, ms), `o` (object).
- Order object `o` fields (from the official example in the STP FAQ, verbatim field names and value types):
```json
{
  "e": "ORDER_TRADE_UPDATE",
  "E": 1568879465651,
  "T": 1568879465650,
  "o": {
    "s": "BTCUSDT",
    "c": "TEST",
    "S": "SELL",
    "o": "TRAILING_STOP_MARKET",
    "f": "GTC",
    "q": "0.001",
    "p": "0",
    "ap": "0",
    "sp": "7103.04",
    "x": "EXPIRED",
    "X": "EXPIRED_IN_MATCH",
    "i": 8886774,
    "l": "0",
    "z": "0",
    "L": "0",
    "N": "USDT",
    "n": "0",
    "T": 1568879465650,
    "t": 0,
    "b": "0",
    "a": "9.91",
    "m": false,
    "R": false,
    "wt": "CONTRACT_PRICE",
    "ot": "TRAILING_STOP_MARKET",
    "ps": "LONG",
    "cp": false,
    "AP": "7476.89",
    "cr": "5.0",
    "pP": false,
    "si": 0,
    "ss": 0,
    "rp": "0",
    "V": "EXPIRE_MAKER",
    "pm": "QUEUE",
    "gtd": 1768879465650
  }
}
```
- Field meanings (from the docs' comments in that example): `s` symbol; `c` client order id (prefix "autoclose-" = liquidation, "adl_autoclose" = ADL, "settlement_autoclose-" = delist/delivery settlement); `S` side; `o` order type; `f` time in force; `q` original qty; `p` original price; `ap` average price; `sp` stop price (ignore for TRAILING_STOP_MARKET); `x` execution type; `X` order status; `i` order id; `l` last filled qty; `z` cumulative filled qty; `L` last filled price; `N` commission asset (omitted if no commission); `n` commission (omitted if none); `T` order trade time; `t` trade id; `b` bids notional; `a` asks notional; `m` is maker side; `R` reduce only; `wt` stop price working type; `ot` original order type; `ps` position side; `cp` close-all; `AP` activation price (TRAILING_STOP_MARKET); `cr` callback rate (TRAILING_STOP_MARKET); `rp` realized profit of the trade; `V` self-trade prevention mode; `pm` price match mode; `gtd` good till date.
- Execution type `x` values: NEW, CANCELED, CALCULATED (liquidation execution), EXPIRED, TRADE, AMENDMENT.
- Order status `X` values: NEW, PARTIALLY_FILLED, FILLED, CANCELED, EXPIRED, EXPIRED_IN_MATCH.
- Expiry reason field `er` (`0`..`9`, effective 2025-10-23/2025-12-10 changelog) present in ORDER_TRADE_UPDATE.
- Liquidation: `c` = "autoclose-XXX", `X` = "NEW". ADL: `c` = "adl_autoclose", `X` = "NEW".
- The event field list above is taken from the docs' example, not the SchemaEmbed (official schema not retrieved). The field set matches the brief: s, c, S, o, f, q, p, ap, X, x, i, l, z, L, n, N, T, t, rp, m.

### 7.3 Event: ACCOUNT_UPDATE (balance and position update)
- Envelope: `e` = "ACCOUNT_UPDATE", `E`, `T`, `a` (object).
- `a.m` reason enum (docs): DEPOSIT, WITHDRAW, ORDER, FUNDING_FEE, WITHDRAW_REJECT, ADJUSTMENT, INSURANCE_CLEAR, ADMIN_DEPOSIT, ADMIN_WITHDRAW, MARGIN_TRANSFER, MARGIN_TYPE_CHANGE, ASSET_TRANSFER, OPTIONS_PREMIUM_FEE, OPTIONS_SETTLE_PROFIT, AUTO_EXCHANGE, COIN_SWAP_DEPOSIT, COIN_SWAP_WITHDRAW.
- `a.B[]` balance fields: `a` (asset), `wb` (wallet balance), `cw` (cross wallet balance), `bc` (balance change excluding PnL and commission). Verified example (changelog 2023-03-28):
```json
{
  "e": "ACCOUNT_UPDATE",
  "T": 1679974782150,
  "E": 1679974782155,
  "a": {
    "B": [
      {"a": "USDT", "wb": "685.31478079", "cw": "677.17212454", "bc": "0.00258637"}
    ],
    "P": [],
    "m": "ADMIN_DEPOSIT"
  }
}
```
- `a.P[]` positions: only changed symbols are pushed. Field names `pa` (position amount), `ep` (entry price), `cr` (accumulated realized), `up` (unrealized PnL), `mt` (margin type), `iw` (isolated wallet), `ps` (position side) are per the request brief; **their exact names and a full example are UNVERIFIED**. The docs confirm a `P` array exists and `m`/`bc`.
- Not pushed for unfilled/cancelled orders alone (no position change).
- Funding fee events: crossed positions push `B` only (no `P`); isolated positions push `B` plus the affected `P`.

### 7.4 Event: listenKeyExpired
- Event name: `listenKeyExpired`. Fields: `e` ("listenKeyExpired"), `E` (event time, ms), `listenKey` (string). Example (official schema page): `{"e":"listenKeyExpired","E":1736996475556,"listenKey":"WsCMN0a4KHUPTQuX6IUnqEZfB1inxmv1qR4kbf1LuEjur5VdbzqvyxqG9TSjVVxv"}`
- Sent when the listenKey in use expires. Not related to socket disconnect. No more user events arrive until a new valid listenKey is used (create new one with POST, reconnect).

### 7.5 Other user-data events (exist, not detailed here)
MARGIN_CALL, ACCOUNT_CONFIG_UPDATE (ACCOUNT_CONFIG_UPDATE / leverage update), TRADE_LITE, CONDITIONAL_ORDER_TRIGGER_REJECT, STRATEGY_UPDATE, ALGO_UPDATE, GRID_UPDATE (deprecated), CONDITIONAL_ORDER_TRADE_UPDATE.

## 8. Operational checklist
- Sync clock: `GET /fapi/v1/time` (not exchangeInfo.serverTime).
- Sign every TRADE and USER_DATA request; `signature` last.
- Keep a listenKey alive: PUT every ~30 to 60 minutes (documented validity 60 minutes); on -1125 recreate with POST.
- Rotate WebSocket connections before the 24-hour cap.
- Answer ping frames with pong; keep pong within 10 minutes.
- Treat 503 "Unknown error..." as UNKNOWN; reconcile via GET openOrders / userTrades before resending.
- Round price to tickSize and quantity to stepSize; check MIN_NOTIONAL (5.0 per -4164 text) unless reduceOnly.

## 9. Known doc-vs-brief differences
- POST /fapi/v1/order response has `cumQty`, not `cumQuote`; no `avgPrice`. `avgPrice` and `cumQuote` are on GET openOrders items.
- REJECTED is not a documented order status; rejections are `{code, msg}` errors.
- v3 account positions and v3 positionRisk do NOT have leverage/entryPrice on the account side; positionRisk v3 has entryPrice and liquidationPrice but not leverage. Use v2 positionRisk for leverage/marginType.
- Order `type` enum is wider than LIMIT/MARKET; `timeInForce` includes GTD and RPI.
- Orders: `reduceOnly` is the string "true"/"false" in the schema. Cannot be sent in hedge mode.
- The `pricePrecision`/`quantityPrecision` fields are documented as NOT usable as tickSize/stepSize; use filters.

## 10. UNVERIFIED items
1. Full example payloads and field lists for market streams: `<symbol>@depth` (diff), `<symbol>@depth<levels>` partial, `<symbol>@aggTrade`, `<symbol>@markPrice` and `@1s`, `<symbol>@bookTicker`. Only changelog-level field notes were available.
2. ORDER_TRADE_UPDATE: the official SchemaEmbed definition was not retrieved. The field list is from the official STP FAQ example (exact names, not schema-typed).
3. ACCOUNT_UPDATE `a.P[]` position field names (`pa`, `ep`, `cr`, `up`, `mt`, `iw`, `ps`) and a full example. Only `B` example and `m` enum were verified.
4. exchangeInfo: `filterType` values `LOT_SIZE` and `MIN_NOTIONAL` and their example JSON. The schema only shows a PRICE_FILTER example.
5. exchangeInfo `rateLimits`: only one entry is in the schema example; order-rate limit entries not extracted.
6. GET /fapi/v2/positionRisk weight; GET /fapi/v2/account full top-level example values; GET /fapi/v3/account full top-level key set beyond those in the example.
7. GET /fapi/v1/openOrders example values are from the schema (verified), but its weight line is verified only as "1 for a single symbol; 40 when symbol omitted".
8. Encoding of the `batchOrders` array in the request body (JSON string vs repeated form keys): not stated.
9. Partial depth endpoint "limit" values for WS streams (5/10/20 confirmed by changelog; other values not checked).
10. Private stream: multiple listenKeys / event subscription syntax on `/private` (change notice mention, no details).
11. The `-1125` text and `DELETE /fapi/v1/listenKey` response body (schema says only "OK").
12. userTrades usage notes (7-day default, 3-month retention) are from the official page via WebFetch, not cross-checked in the schema.
13. RSA signing variant.
14. Rate-limit numeric values for orders (10s/1m) beyond those in the schema headers.

## Addendum: websocket payloads

### ORDER_TRADE_UPDATE (verified, from the USDⓈ-M STP FAQ in the official full-text docs)
```json
```javascript
{
  "e":"ORDER_TRADE_UPDATE",      // Event Type
  "E":1568879465651,             // Event Time
  "T":1568879465650,             // Transaction Time
  "o":{
    "s":"BTCUSDT",               // Symbol
    "c":"TEST",                  // Client Order Id
      // special client order id:
      // starts with "autoclose-": liquidation order
      // "adl_autoclose": ADL auto close order
      // "settlement_autoclose-": settlement order for delisting or delivery
    "S":"SELL",                  // Side
    "o":"TRAILING_STOP_MARKET",  // Order Type
    "f":"GTC",                   // Time in Force
    "q":"0.001",                 // Original Quantity
    "p":"0",                     // Original Price
    "ap":"0",                    // Average Price
    "sp":"7103.04",              // Stop Price. Please ignore with TRAILING_STOP_MARKET order
    "x":"EXPIRED",               // Execution Type
    "X":"EXPIRED_IN_MATCH",      // Order Status
    "i":8886774,                 // Order Id
    "l":"0",                     // Order Last Filled Quantity
    "z":"0",                     // Order Filled Accumulated Quantity
    "L":"0",                     // Last Filled Price
    "N":"USDT",                  // Commission Asset, will not push if no commission
    "n":"0",                     // Commission, will not push if no commission
    "T":1568879465650,           // Order Trade Time
    "t":0,                       // Trade Id
    "b":"0",                     // Bids Notional
    "a":"9.91",                  // Ask Notional
    "m":false,                   // Is this trade the maker side?
    "R":false,                   // Is this reduce only
    "wt":"CONTRACT_PRICE",       // Stop Price Working Type
    "ot":"TRAILING_STOP_MARKET", // Original Order Type
    "ps":"LONG",                 // Position Side
    "cp":false,                  // If Close-All, pushed with conditional order
    "AP":"7476.89",              // Activation Price, only puhed with TRAILING_STOP_MARKET order
    "cr":"5.0",                  // Callback Rate, only puhed with TRAILING_STOP_MARKET order
    "pP": false,                 // ignore
    "si": 0,                     // ignore
    "ss": 0,                     // ignore
    "rp":"0",                    // Realized Profit of the trade
    "V": "EXPIRE_MAKER",         // selfTradePreventionMode
    "pm":"QUEUE",                // price match type
    "gtd":1768879465650          // good till date
   }
}
```
```

### ACCOUNT_UPDATE (verified, from the USDⓈ-M change log in the official full-text docs)
```json
```javascript
{
  "e": "ACCOUNT_UPDATE",
  "T": 1679974782150,
  "E": 1679974782155,
  "a": {
    "B": [
   {
       "a": "USDT",
       "wb": "685.31478079",
       "cw": "677.17212454",
       "bc": "0.00258637"
      }
 ],
    "P": [],
    "m": "ADMIN_DEPOSIT"
  }
}
```

**Referal Rebate Logic After Release**

- Referral rebates are aggregated every 20 minutes and reflected as a single push in the
  `ACCOUNT_UPDATE` event of the USER-DATA-STREAM, showing the total sum of rebates earned from
  multiple referrals.

---

## 2023-03-08

USDⓈ-M Futures

**RELEASE DATE 2023-03-22**

**Order Logic Before Release:**

- When placing order with `timeInForce` `FOK` or `GTX`(Post-only), user will get order response with
  `status` = “NEW“ and corresponding `order_trade_update` with `x` = “NEW”, `X` = “NEW”. If the
  orders can't meet execution criteria, user will receive another websocket `order_trade_update`
  message `x` = “EXPIRED”, `X` = “EXPIRED”. The order can be found in `GET /fapi/v1/order` or
  `GET /fapi/v1/allOrders`.

```javascript
{
    "code": -5021,
    "msg": "Due to the order could not be filled immediately, the FOK order has been rejected. The order will not be recorded in the order history"
```

### Market streams (FROM MEMORY, not fetched; these shapes have been stable since 2020 and an implementer should spot-check one live message from wss://fstream.binance.com/ws/btcusdt@depth@100ms before relying on a field)

Diff book depth `<symbol>@depth` / `@depth@100ms` / `@depth@500ms`:
```json
{"e":"depthUpdate","E":1571889248277,"T":1571889248276,"s":"BTCUSDT","U":390497796,"u":390497878,"pu":390497794,
 "b":[["7403.89","0.002"],["7403.90","3.906"]],"a":[["7405.96","3.340"],["7405.97","0.000"]]}
```
Local book rule: GET /fapi/v1/depth?limit=1000 gives lastUpdateId; drop events with u < lastUpdateId; the first event must satisfy U <= lastUpdateId AND u >= lastUpdateId; afterwards each event's pu must equal the previous event's u, else resync. Quantity "0" removes the level.

Partial book depth `<symbol>@depth5` / `@depth10` / `@depth20` (and `@100ms`/`@500ms` suffixes): same fields as above with e="depthUpdate", and b/a hold the top N levels in full (snapshot each push, not deltas).

Aggregate trade `<symbol>@aggTrade`:
```json
{"e":"aggTrade","E":123456789,"s":"BTCUSDT","a":5933014,"p":"0.001","q":"100","f":100,"l":105,"T":123456785,"m":true}
```
m = true means the buyer is the maker (i.e. a sell aggressor).

Book ticker `<symbol>@bookTicker`:
```json
{"e":"bookTicker","u":400900217,"E":1568014460893,"T":1568014460891,"s":"BNBUSDT","b":"25.35190000","B":"31.21000000","a":"25.36520000","A":"40.66000000"}
```

Mark price `<symbol>@markPrice` / `@markPrice@1s`:
```json
{"e":"markPriceUpdate","E":1562305380000,"s":"BTCUSDT","p":"11794.15000000","i":"11784.62659091","P":"11784.25641265","r":"0.00038167","T":1562306400000}
```
p mark price, i index price, P estimated settle price, r funding rate, T next funding time.

Combined streams: `wss://fstream.binance.com/stream?streams=btcusdt@depth@100ms/btcusdt@aggTrade`; each message is wrapped as `{"stream":"btcusdt@aggTrade","data":{...}}`. Raw streams: `wss://fstream.binance.com/ws/<streamName>`. Stream names are lowercase. Server sends a ping frame every 3 minutes; reply with pong within 10 minutes. Connections are closed after 24 hours.
