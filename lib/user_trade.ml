open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { id : Trade_id.t
  ; order_id : Order_id.t [@key "orderId"]
  ; symbol : Symbol.t
  ; side : Side.t
  ; position_side : Position_side.t option
       [@key "positionSide"] [@default None] [@yojson_drop_if Option.is_none]
  ; price : Price.t
  ; qty : Size.t
  ; quote_qty : Usd.t [@key "quoteQty"]
  ; commission : Decimal.t
  ; commission_asset : string [@key "commissionAsset"]
  ; realized_pnl : Usd.t [@key "realizedPnl"]
  ; margin_asset : string option
       [@key "marginAsset"] [@default None] [@yojson_drop_if Option.is_none]
  ; maker : bool
  ; buyer : bool
  ; time : Timestamp_ms.t
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
