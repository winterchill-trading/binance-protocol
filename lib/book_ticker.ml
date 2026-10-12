open! Core

type t =
  { symbol : Symbol.t
  ; bid_price : Price.t [@key "bidPrice"]
  ; bid_qty : Size.t [@key "bidQty"]
  ; ask_price : Price.t [@key "askPrice"]
  ; ask_qty : Size.t [@key "askQty"]
  ; time : Timestamp_ms.t
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
