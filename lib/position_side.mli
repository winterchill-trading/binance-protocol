(** Position side ([positionSide], [ps]): [BOTH] in one-way mode, [LONG] or [SHORT] in
    hedge mode. *)

open! Core

type t =
  | Both
  | Long
  | Short
[@@deriving sexp, compare, equal, hash, enumerate, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

val of_wire : string -> t option
