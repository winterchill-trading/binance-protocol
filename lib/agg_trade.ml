open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(* UNVERIFIED: payload example from memory; the field list matches the changelog. *)
module T = struct
  type t =
    { event_time : Timestamp_ms.t [@key "E"]
    ; symbol : Symbol.t [@key "s"]
    ; agg_trade_id : int [@key "a"]
    ; price : Price.t [@key "p"]
    ; qty : Size.t [@key "q"]
    ; normal_qty : Size.t option
         [@key "nq"] [@default None] [@yojson_drop_if Option.is_none]
    ; first_trade_id : Trade_id.t [@key "f"]
    ; last_trade_id : Trade_id.t [@key "l"]
    ; trade_time : Timestamp_ms.t [@key "T"]
    ; buyer_is_maker : bool [@key "m"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

include T

let event_type = "aggTrade"
let yojson_of_t t = Json.with_tag (T.yojson_of_t t) ~key:"e" ~value:event_type
let taker_side t = if t.buyer_is_maker then Side.Sell else Side.Buy
