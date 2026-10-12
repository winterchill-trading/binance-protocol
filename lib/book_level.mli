(** One price level, encoded as a [[price, qty]] pair of decimal strings, e.g.
    [["7403.89", "0.002"]]. In diff-depth events the quantity is absolute; zero removes
    the level. *)

open! Core

type t =
  { price : Price.t
  ; qty : Size.t
  }
[@@deriving sexp, compare, equal, yojson]
