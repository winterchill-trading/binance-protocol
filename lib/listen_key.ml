open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = { listen_key : string [@key "listenKey"] }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
