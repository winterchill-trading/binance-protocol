(** Mark price and funding event ([<symbol>@markPrice], [@markPrice@1s]):
    [{"e": "markPriceUpdate", "E": 1562305380000, "s": "BTCUSDT", "p": "11794.15000000", "i": "11784.62659091", "P": "11784.25641265", "r": "0.00038167", "T": 1562306400000}]. *)

open! Core

type t =
  { event_time : Timestamp_ms.t (** [E] *)
  ; symbol : Symbol.t (** [s] *)
  ; mark_price : Price.t (** [p] *)
  ; index_price : Price.t option (** [i] *)
  ; estimated_settle_price : Price.t option (** [P] *)
  ; funding_rate : Decimal.t (** [r]; empty string on delivery contracts is not handled *)
  ; next_funding_time : Timestamp_ms.t (** [T] *)
  }
[@@deriving sexp, compare, equal, yojson]

val event_type : string
