(** Best bid and offer from [GET /fapi/v1/ticker/bookTicker] (one object with [symbol], an
    array without):
    [{"symbol": "BTCUSDT", "bidPrice": "4.00000000", "bidQty": "431.00000000", "askPrice": "4.00000200", "askQty": "9.00000000", "time": 1589437530011}].
    The websocket counterpart is {!Book_ticker_event}. *)

open! Core

type t =
  { symbol : Symbol.t
  ; bid_price : Price.t
  ; bid_qty : Size.t
  ; ask_price : Price.t
  ; ask_qty : Size.t
  ; time : Timestamp_ms.t (** transaction time *)
  }
[@@deriving sexp, compare, equal, yojson]
