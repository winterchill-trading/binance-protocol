(** Execution type of an order update ([x]): what happened in this event. [Calculated] is
    a liquidation execution. *)

open! Core

type t =
  | New
  | Canceled
  | Calculated
  | Expired
  | Trade
  | Amendment
  | Other of string (** a value this library does not know, kept verbatim *)
[@@deriving sexp, compare, equal, hash, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

(** Total: unknown strings become [Other]. *)
val of_wire : string -> t
