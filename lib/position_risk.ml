open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { symbol : Symbol.t
  ; position_side : Position_side.t [@key "positionSide"]
  ; position_amt : Size.t [@key "positionAmt"]
  ; entry_price : Price.t [@key "entryPrice"]
  ; break_even_price : Price.t option
       [@key "breakEvenPrice"] [@default None] [@yojson_drop_if Option.is_none]
  ; mark_price : Price.t [@key "markPrice"]
  ; unrealized_profit : Usd.t [@key "unRealizedProfit"]
  ; liquidation_price : Price.t [@key "liquidationPrice"]
  ; isolated_margin : Usd.t option
       [@key "isolatedMargin"] [@default None] [@yojson_drop_if Option.is_none]
  ; notional : Usd.t option [@default None] [@yojson_drop_if Option.is_none]
  ; isolated_wallet : Usd.t option
       [@key "isolatedWallet"] [@default None] [@yojson_drop_if Option.is_none]
  ; margin_asset : string option
       [@key "marginAsset"] [@default None] [@yojson_drop_if Option.is_none]
  ; leverage : Json.Int_string.t option [@default None] [@yojson_drop_if Option.is_none]
  ; margin_type : string option
       [@key "marginType"] [@default None] [@yojson_drop_if Option.is_none]
  ; is_auto_add_margin : Json.Bool_string.t option
       [@key "isAutoAddMargin"] [@default None] [@yojson_drop_if Option.is_none]
  ; max_notional_value : Usd.t option
       [@key "maxNotionalValue"] [@default None] [@yojson_drop_if Option.is_none]
  ; initial_margin : Usd.t option
       [@key "initialMargin"] [@default None] [@yojson_drop_if Option.is_none]
  ; maint_margin : Usd.t option
       [@key "maintMargin"] [@default None] [@yojson_drop_if Option.is_none]
  ; position_initial_margin : Usd.t option
       [@key "positionInitialMargin"] [@default None] [@yojson_drop_if Option.is_none]
  ; open_order_initial_margin : Usd.t option
       [@key "openOrderInitialMargin"] [@default None] [@yojson_drop_if Option.is_none]
  ; adl : int option [@default None] [@yojson_drop_if Option.is_none]
  ; update_time : Timestamp_ms.t [@key "updateTime"]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
