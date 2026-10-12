open! Core

type 'a t =
  { stream : Stream_name.t
  ; data : 'a
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
