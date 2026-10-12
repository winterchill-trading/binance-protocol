open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(* UNVERIFIED: payload example from memory; the field list matches the changelog. *)
module T = struct
  type t =
    { event_time : Timestamp_ms.t [@key "E"]
    ; symbol : Symbol.t [@key "s"]
    ; mark_price : Price.t [@key "p"]
    ; index_price : Price.t option
         [@key "i"] [@default None] [@yojson_drop_if Option.is_none]
    ; estimated_settle_price : Price.t option
         [@key "P"] [@default None] [@yojson_drop_if Option.is_none]
    ; funding_rate : Decimal.t [@key "r"]
    ; next_funding_time : Timestamp_ms.t [@key "T"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

include T

let event_type = "markPriceUpdate"
let yojson_of_t t = Json.with_tag (T.yojson_of_t t) ~key:"e" ~value:event_type
