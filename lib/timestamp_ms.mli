(** Milliseconds since the Unix epoch, a JSON integer ([E], [T], [time], [updateTime],
    [nextFundingTime], ...). *)

open! Core

type t [@@deriving sexp, compare, equal, hash, yojson]

include Comparable.S with type t := t

val of_int : int -> t
val to_int : t -> int
val of_time_ns : Time_ns.t -> t

(** Exact: every millisecond count is representable in nanoseconds. *)
val to_time_ns : t -> Time_ns.t
