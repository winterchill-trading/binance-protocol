(** [application/x-www-form-urlencoded] encoding of request parameters, in insertion
    order. Binance signs the exact string sent, so the same {!encode} output must be both
    signed and sent. *)

open! Core

type t = (string * string) list [@@deriving sexp, compare, equal]

(** [k1=v1&k2=v2...]. Keys and values are percent-encoded: everything except
    [A-Z a-z 0-9 - _ . ~] becomes [%XX] (uppercase hex); spaces become [%20]. *)
val encode : t -> string

(** Percent-encodes one component. *)
val percent_encode : string -> string
