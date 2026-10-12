open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { order_id : Order_id.t [@key "orderId"]
  ; symbol : Symbol.t
  ; client_order_id : Client_order_id.t [@key "clientOrderId"]
  ; side : Side.t
  ; position_side : Position_side.t option
       [@key "positionSide"] [@default None] [@yojson_drop_if Option.is_none]
  ; status : Order_status.t
  ; order_type : Order_type.t [@key "type"]
  ; orig_type : Order_type.t option
       [@key "origType"] [@default None] [@yojson_drop_if Option.is_none]
  ; time_in_force : Time_in_force.t [@key "timeInForce"]
  ; price : Price.t
  ; orig_qty : Size.t [@key "origQty"]
  ; executed_qty : Size.t [@key "executedQty"]
  ; cum_qty : Size.t option
       [@key "cumQty"] [@default None] [@yojson_drop_if Option.is_none]
  ; cum_quote : Usd.t option
       [@key "cumQuote"] [@default None] [@yojson_drop_if Option.is_none]
  ; avg_price : Price.t option
       [@key "avgPrice"] [@default None] [@yojson_drop_if Option.is_none]
  ; stop_price : Price.t option
       [@key "stopPrice"] [@default None] [@yojson_drop_if Option.is_none]
  ; activate_price : Price.t option
       [@key "activatePrice"] [@default None] [@yojson_drop_if Option.is_none]
  ; price_rate : Decimal.t option
       [@key "priceRate"] [@default None] [@yojson_drop_if Option.is_none]
  ; reduce_only : bool [@key "reduceOnly"] [@default false]
  ; close_position : bool [@key "closePosition"] [@default false]
  ; price_protect : bool [@key "priceProtect"] [@default false]
  ; working_type : Working_type.t option
       [@key "workingType"] [@default None] [@yojson_drop_if Option.is_none]
  ; price_match : string option
       [@key "priceMatch"] [@default None] [@yojson_drop_if Option.is_none]
  ; self_trade_prevention_mode : string option
       [@key "selfTradePreventionMode"] [@default None] [@yojson_drop_if Option.is_none]
  ; good_till_date : Timestamp_ms.t option
       [@key "goodTillDate"] [@default None] [@yojson_drop_if Option.is_none]
  ; time : Timestamp_ms.t option [@default None] [@yojson_drop_if Option.is_none]
  ; update_time : Timestamp_ms.t [@key "updateTime"]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let remaining_qty t = Size.(t.orig_qty - t.executed_qty)
