(** Aggregate trade event ([<symbol>@aggTrade]):
    [{"e": "aggTrade", "E": 123456789, "s": "BTCUSDT", "a": 5933014, "p": "0.001", "q": "100", "f": 100, "l": 105, "T": 123456785, "m": true}]. *)

open! Core

type t =
  { event_time : Timestamp_ms.t (** [E] *)
  ; symbol : Symbol.t (** [s] *)
  ; agg_trade_id : int (** [a] *)
  ; price : Price.t (** [p] *)
  ; qty : Size.t (** [q] *)
  ; normal_qty : Size.t option
  (** [nq]: quantity excluding retail-price-improvement fills (from 2025-12) *)
  ; first_trade_id : Trade_id.t (** [f] *)
  ; last_trade_id : Trade_id.t (** [l] *)
  ; trade_time : Timestamp_ms.t (** [T] *)
  ; buyer_is_maker : bool (** [m]: true when the aggressor sold *)
  }
[@@deriving sexp, compare, equal, yojson]

val event_type : string

(** The aggressor's side: [Sell] when the buyer is the maker. *)
val taker_side : t -> Side.t
