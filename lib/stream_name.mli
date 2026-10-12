(** Market stream names, e.g. ["btcusdt@depth@100ms"]. Symbols are lowercase in stream
    names; {!to_string} lowercases and {!of_string} uppercases them back. *)

open! Core

module Speed : sig
  (** Update interval suffix: [@100ms], [@250ms], [@500ms]. *)
  type t =
    | Ms_100
    | Ms_250
    | Ms_500
  [@@deriving sexp, compare, equal, hash, enumerate]
end

type t =
  | Diff_depth of
      { symbol : Symbol.t
      ; speed : Speed.t option (** [None]: the default interval *)
      } (** [<symbol>@depth], [<symbol>@depth@100ms]: {!Depth_update} events *)
  | Partial_depth of
      { symbol : Symbol.t
      ; levels : int (** 5, 10 or 20 *)
      ; speed : Speed.t option
      } (** [<symbol>@depth5], [<symbol>@depth20@100ms]: top-N snapshots *)
  | Agg_trade of Symbol.t (** [<symbol>@aggTrade] *)
  | Book_ticker of Symbol.t (** [<symbol>@bookTicker] *)
  | Mark_price of
      { symbol : Symbol.t
      ; every_second : bool (** [@1s] instead of every 3 seconds *)
      } (** [<symbol>@markPrice], [<symbol>@markPrice@1s] *)
  | Other of string (** any other stream, kept verbatim *)
[@@deriving sexp, compare, equal, hash, yojson]

val to_string : t -> string

(** Total: unrecognised names become [Other]. *)
val of_string : string -> t

(** Errors unless [levels] is 5, 10 or 20. *)
val partial_depth : ?speed:Speed.t -> Symbol.t -> levels:int -> t Or_error.t
