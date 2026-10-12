open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module T = struct
  type t = int [@@deriving sexp, compare, equal, hash, yojson]
end

include T
include Comparable.Make (T)

let of_int = Fn.id
let to_int = Fn.id
let of_time_ns time = Int.( / ) (Time_ns.to_int_ns_since_epoch time) 1_000_000
let to_time_ns t = Time_ns.of_int_ns_since_epoch (Int.( * ) t 1_000_000)
