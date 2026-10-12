(** Contract symbol, e.g. ["BTCUSDT"]. The same type as {!Exchange_core.Symbol}, always
    uppercase: [of_string], [t_of_sexp] and the JSON decoder normalise case. Websocket
    stream names use the lowercase form, see {!to_stream_prefix}. *)

open! Core

type t = Exchange_core.Symbol.t [@@deriving sexp, compare, equal, hash, yojson]

include
  Comparable.S
  with type t := t
   and type comparator_witness = Exchange_core.Symbol.comparator_witness

include Hashable.S with type t := t

(** Uppercases. *)
val of_string : string -> t

val to_string : t -> string

(** Lowercase symbol as used in stream names, e.g. ["btcusdt"]. *)
val to_stream_prefix : t -> string
