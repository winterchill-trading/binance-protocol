open! Core

module type S = sig
  type t [@@deriving sexp, equal, yojson]
end
