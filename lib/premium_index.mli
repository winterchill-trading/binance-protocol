(** Mark price and funding from [GET /fapi/v1/premiumIndex] (one object with [symbol], an
    array without):
    [{"symbol": "BTCUSDT", "markPrice": "11793.63104562", "indexPrice": "11781.80495970", "estimatedSettlePrice": "11781.16138815", "lastFundingRate": "0.00038246", "interestRate": "0.00010000", "nextFundingTime": 1597392000000, "time": 1597370495002}]. *)

open! Core

type t =
  { symbol : Symbol.t
  ; mark_price : Price.t
  ; index_price : Price.t
  ; estimated_settle_price : Price.t option
  (** only meaningful in the last hour before settlement *)
  ; last_funding_rate : Decimal.t
  ; interest_rate : Decimal.t option
  ; next_funding_time : Timestamp_ms.t
  ; time : Timestamp_ms.t
  }
[@@deriving sexp, compare, equal, yojson]
