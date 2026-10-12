open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { symbol : Symbol.t
  ; mark_price : Price.t [@key "markPrice"]
  ; index_price : Price.t [@key "indexPrice"]
  ; estimated_settle_price : Price.t option
       [@key "estimatedSettlePrice"] [@default None] [@yojson_drop_if Option.is_none]
  ; last_funding_rate : Decimal.t [@key "lastFundingRate"]
  ; interest_rate : Decimal.t option
       [@key "interestRate"] [@default None] [@yojson_drop_if Option.is_none]
  ; next_funding_time : Timestamp_ms.t [@key "nextFundingTime"]
  ; time : Timestamp_ms.t
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
