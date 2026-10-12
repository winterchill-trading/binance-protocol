(** An item of [GET /fapi/v1/userTrades]:
    [{"buyer": false, "commission": "0.07819010", "commissionAsset": "USDT", "id": 698759, "maker": false, "orderId": 25851813, "price": "7819.01", "qty": "0.002", "quoteQty": "15.63802", "realizedPnl": "-0.91539999", "side": "SELL", "positionSide": "SHORT", "symbol": "BTCUSDT", "time": 1569514978020, ...}]. *)

open! Core

type t =
  { id : Trade_id.t
  ; order_id : Order_id.t
  ; symbol : Symbol.t
  ; side : Side.t
  ; position_side : Position_side.t option
  ; price : Price.t
  ; qty : Size.t
  ; quote_qty : Usd.t
  ; commission : Decimal.t (** in [commission_asset], positive when paid *)
  ; commission_asset : string
  ; realized_pnl : Usd.t
  ; margin_asset : string option
  ; maker : bool
  ; buyer : bool
  ; time : Timestamp_ms.t
  }
[@@deriving sexp, compare, equal, yojson]
