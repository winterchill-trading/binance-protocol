(** The interface shared by every wire type in this library. *)

open! Core

module type S = sig
  type t [@@deriving sexp, equal, yojson]
end
