(** Order type ([type], [origType], [o], [ot]). Only [LIMIT] and [MARKET] are modelled;
    stop, take-profit and trailing-stop types ([STOP], [STOP_MARKET], [TAKE_PROFIT],
    [TAKE_PROFIT_MARKET], [TRAILING_STOP_MARKET]) are carried as [Other]. *)

open! Core

type t =
  | Limit
  | Market
  | Other of string (** a value this library does not know, kept verbatim *)
[@@deriving sexp, compare, equal, hash, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

(** Total: unknown strings become [Other]. *)
val of_wire : string -> t
