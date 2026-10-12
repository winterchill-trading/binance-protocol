(** Order status ([status], [X]). Rejected orders never get a status: the exchange answers
    with an {!Api_error.t} instead. *)

open! Core

type t =
  | New
  | Partially_filled
  | Filled
  | Canceled
  | Expired
  | Expired_in_match
  | Other of string (** a value this library does not know, kept verbatim *)
[@@deriving sexp, compare, equal, hash, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

(** Total: unknown strings become [Other]. *)
val of_wire : string -> t

(** [Filled], [Canceled], [Expired] and [Expired_in_match]: the order no longer rests. *)
val is_final : t -> bool
