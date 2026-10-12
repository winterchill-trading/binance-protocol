(** Best bid/offer event ([<symbol>@bookTicker]):
    [{"e": "bookTicker", "u": 400900217, "E": 1568014460893, "T": 1568014460891, "s": "BNBUSDT", "b": "25.35190000", "B": "31.21000000", "a": "25.36520000", "A": "40.66000000"}]. *)

open! Core

type t =
  { update_id : int (** [u] *)
  ; event_time : Timestamp_ms.t (** [E] *)
  ; transaction_time : Timestamp_ms.t (** [T] *)
  ; symbol : Symbol.t (** [s] *)
  ; bid_price : Price.t (** [b] *)
  ; bid_qty : Size.t (** [B] *)
  ; ask_price : Price.t (** [a] *)
  ; ask_qty : Size.t (** [A] *)
  }
[@@deriving sexp, compare, equal, yojson]

val event_type : string
