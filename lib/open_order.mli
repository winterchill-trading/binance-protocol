(** An item of [GET /fapi/v1/openOrders]: an {!Order.t} with [avgPrice], [cumQuote] and
    [time] set. *)

open! Core

type t = Order.t [@@deriving sexp, compare, equal, yojson]

(** The venue-neutral view: remaining size as [size], [origQty] as [orig_size], creation
    time (or update time when absent) in nanoseconds. *)
val to_exchange_core : t -> Exchange_core.Open_order.t
