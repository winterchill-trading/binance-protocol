open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Asset = struct
  type t =
    { asset : string
    ; wallet_balance : Usd.t [@key "walletBalance"]
    ; unrealized_profit : Usd.t [@key "unrealizedProfit"]
    ; margin_balance : Usd.t [@key "marginBalance"]
    ; maint_margin : Usd.t option
         [@key "maintMargin"] [@default None] [@yojson_drop_if Option.is_none]
    ; initial_margin : Usd.t option
         [@key "initialMargin"] [@default None] [@yojson_drop_if Option.is_none]
    ; position_initial_margin : Usd.t option
         [@key "positionInitialMargin"] [@default None] [@yojson_drop_if Option.is_none]
    ; open_order_initial_margin : Usd.t option
         [@key "openOrderInitialMargin"] [@default None] [@yojson_drop_if Option.is_none]
    ; cross_wallet_balance : Usd.t option
         [@key "crossWalletBalance"] [@default None] [@yojson_drop_if Option.is_none]
    ; cross_un_pnl : Usd.t option
         [@key "crossUnPnl"] [@default None] [@yojson_drop_if Option.is_none]
    ; available_balance : Usd.t [@key "availableBalance"]
    ; max_withdraw_amount : Usd.t option
         [@key "maxWithdrawAmount"] [@default None] [@yojson_drop_if Option.is_none]
    ; margin_available : bool option
         [@key "marginAvailable"] [@default None] [@yojson_drop_if Option.is_none]
    ; update_time : Timestamp_ms.t [@key "updateTime"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module Position = struct
  type t =
    { symbol : Symbol.t
    ; position_side : Position_side.t [@key "positionSide"]
    ; position_amt : Size.t [@key "positionAmt"]
    ; entry_price : Price.t option
         [@key "entryPrice"] [@default None] [@yojson_drop_if Option.is_none]
    ; unrealized_profit : Usd.t [@key "unrealizedProfit"]
    ; leverage : Json.Int_string.t option [@default None] [@yojson_drop_if Option.is_none]
    ; liquidation_price : Price.t option
         [@key "liquidationPrice"] [@default None] [@yojson_drop_if Option.is_none]
    ; isolated : bool option [@default None] [@yojson_drop_if Option.is_none]
    ; initial_margin : Usd.t option
         [@key "initialMargin"] [@default None] [@yojson_drop_if Option.is_none]
    ; maint_margin : Usd.t option
         [@key "maintMargin"] [@default None] [@yojson_drop_if Option.is_none]
    ; position_initial_margin : Usd.t option
         [@key "positionInitialMargin"] [@default None] [@yojson_drop_if Option.is_none]
    ; open_order_initial_margin : Usd.t option
         [@key "openOrderInitialMargin"] [@default None] [@yojson_drop_if Option.is_none]
    ; isolated_margin : Usd.t option
         [@key "isolatedMargin"] [@default None] [@yojson_drop_if Option.is_none]
    ; isolated_wallet : Usd.t option
         [@key "isolatedWallet"] [@default None] [@yojson_drop_if Option.is_none]
    ; notional : Usd.t option [@default None] [@yojson_drop_if Option.is_none]
    ; max_notional : Usd.t option
         [@key "maxNotional"] [@default None] [@yojson_drop_if Option.is_none]
    ; update_time : Timestamp_ms.t [@key "updateTime"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

type t =
  { total_wallet_balance : Usd.t [@key "totalWalletBalance"]
  ; total_unrealized_profit : Usd.t [@key "totalUnrealizedProfit"]
  ; total_margin_balance : Usd.t [@key "totalMarginBalance"]
  ; total_initial_margin : Usd.t option
       [@key "totalInitialMargin"] [@default None] [@yojson_drop_if Option.is_none]
  ; total_maint_margin : Usd.t option
       [@key "totalMaintMargin"] [@default None] [@yojson_drop_if Option.is_none]
  ; total_position_initial_margin : Usd.t option
       [@key "totalPositionInitialMargin"]
       [@default None]
       [@yojson_drop_if Option.is_none]
  ; total_open_order_initial_margin : Usd.t option
       [@key "totalOpenOrderInitialMargin"]
       [@default None]
       [@yojson_drop_if Option.is_none]
  ; total_cross_wallet_balance : Usd.t option
       [@key "totalCrossWalletBalance"] [@default None] [@yojson_drop_if Option.is_none]
  ; total_cross_un_pnl : Usd.t option
       [@key "totalCrossUnPnl"] [@default None] [@yojson_drop_if Option.is_none]
  ; available_balance : Usd.t [@key "availableBalance"]
  ; max_withdraw_amount : Usd.t option
       [@key "maxWithdrawAmount"] [@default None] [@yojson_drop_if Option.is_none]
  ; can_trade : bool option
       [@key "canTrade"] [@default None] [@yojson_drop_if Option.is_none]
  ; fee_tier : int option
       [@key "feeTier"] [@default None] [@yojson_drop_if Option.is_none]
  ; multi_assets_margin : bool option
       [@key "multiAssetsMargin"] [@default None] [@yojson_drop_if Option.is_none]
  ; update_time : Timestamp_ms.t option
       [@key "updateTime"] [@default None] [@yojson_drop_if Option.is_none]
  ; assets : Asset.t list
  ; positions : Position.t list
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let find_asset t asset =
  List.find t.assets ~f:(fun (a : Asset.t) -> String.equal a.asset asset)
;;

let open_positions t =
  List.filter t.positions ~f:(fun (p : Position.t) -> not (Size.is_zero p.position_amt))
;;
