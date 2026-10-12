(** Order or trade side: {!Exchange_core.Side} with Binance's encoding, ["BUY"] or
    ["SELL"]. *)

open! Core

type t = Exchange_core.Side.t =
  | Buy
  | Sell
[@@deriving sexp, compare, equal, hash, enumerate, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

val of_wire : string -> t option
val of_is_buy : bool -> t
val is_buy : t -> bool
val flip : t -> t
