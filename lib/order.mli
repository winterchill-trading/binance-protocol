(** An order as returned by [POST /fapi/v1/order], [DELETE /fapi/v1/order],
    [POST /fapi/v1/batchOrders] and [GET /fapi/v1/openOrders]. The endpoints return
    slightly different field sets, so fields that some of them omit are options:

    - new/cancel responses carry [cumQty] but no [time]; with [newOrderRespType=RESULT]
      they also carry [avgPrice] and [cumQuote];
    - open orders carry [avgPrice], [cumQuote] and [time] but no [cumQty];
    - [activatePrice] and [priceRate] only appear on [TRAILING_STOP_MARKET] orders.

    Booleans default to [false] when absent. *)

open! Core

type t =
  { order_id : Order_id.t
  ; symbol : Symbol.t
  ; client_order_id : Client_order_id.t
  ; side : Side.t
  ; position_side : Position_side.t option
  ; status : Order_status.t
  ; order_type : Order_type.t (** [type] *)
  ; orig_type : Order_type.t option
  ; time_in_force : Time_in_force.t
  ; price : Price.t (** ["0"] for market orders *)
  ; orig_qty : Size.t
  ; executed_qty : Size.t
  ; cum_qty : Size.t option
  ; cum_quote : Usd.t option
  ; avg_price : Price.t option
  ; stop_price : Price.t option
  ; activate_price : Price.t option
  ; price_rate : Decimal.t option
  ; reduce_only : bool
  ; close_position : bool
  ; price_protect : bool
  ; working_type : Working_type.t option
  ; price_match : string option (** ["NONE"], ["OPPONENT"], ["QUEUE_5"], ... *)
  ; self_trade_prevention_mode : string option
  (** ["EXPIRE_MAKER"], ["EXPIRE_TAKER"], ["EXPIRE_BOTH"], ["NONE"] *)
  ; good_till_date : Timestamp_ms.t option (** [0] unless [timeInForce] is [GTD] *)
  ; time : Timestamp_ms.t option (** creation time, open orders only *)
  ; update_time : Timestamp_ms.t
  }
[@@deriving sexp, compare, equal, yojson]

(** [orig_qty - executed_qty]. *)
val remaining_qty : t -> Size.t
