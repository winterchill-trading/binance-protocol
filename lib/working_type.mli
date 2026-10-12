(** Price that triggers stop orders ([workingType], [wt]). *)

open! Core

type t =
  | Mark_price
  | Contract_price
[@@deriving sexp, compare, equal, hash, enumerate, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

val of_wire : string -> t option
