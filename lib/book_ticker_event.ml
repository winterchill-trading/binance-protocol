open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(* UNVERIFIED: payload example from memory; the field list matches the changelog. *)
module T = struct
  type t =
    { update_id : int [@key "u"]
    ; event_time : Timestamp_ms.t [@key "E"]
    ; transaction_time : Timestamp_ms.t [@key "T"]
    ; symbol : Symbol.t [@key "s"]
    ; bid_price : Price.t [@key "b"]
    ; bid_qty : Size.t [@key "B"]
    ; ask_price : Price.t [@key "a"]
    ; ask_qty : Size.t [@key "A"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

include T

let event_type = "bookTicker"
let yojson_of_t t = Json.with_tag (T.yojson_of_t t) ~key:"e" ~value:event_type
