(** User-data event [ORDER_TRADE_UPDATE]: an order was placed, filled, cancelled, expired
    or amended.
    [{"e": "ORDER_TRADE_UPDATE", "E": 1568879465651, "T": 1568879465650, "o": {"s": "BTCUSDT", "c": "TEST", "S": "SELL", ...}}].

    Liquidation orders have a [client_order_id] starting with ["autoclose-"], ADL orders
    ["adl_autoclose"] (see {!Client_order_id.is_exchange_generated}). *)

open! Core

module Order : sig
  type t =
    { symbol : Symbol.t (** [s] *)
    ; client_order_id : Client_order_id.t (** [c] *)
    ; side : Side.t (** [S] *)
    ; order_type : Order_type.t (** [o] *)
    ; time_in_force : Time_in_force.t (** [f] *)
    ; orig_qty : Size.t (** [q] *)
    ; price : Price.t (** [p] *)
    ; avg_price : Price.t (** [ap] *)
    ; stop_price : Price.t option (** [sp]; ignore for trailing stops *)
    ; execution_type : Execution_type.t (** [x] *)
    ; status : Order_status.t (** [X] *)
    ; order_id : Order_id.t (** [i] *)
    ; last_filled_qty : Size.t (** [l] *)
    ; cum_filled_qty : Size.t (** [z] *)
    ; last_filled_price : Price.t (** [L] *)
    ; commission_asset : string option (** [N]; absent when no commission *)
    ; commission : Decimal.t option (** [n]; absent when no commission *)
    ; trade_time : Timestamp_ms.t (** [T] *)
    ; trade_id : Trade_id.t (** [t]; [0] when the event is not a trade *)
    ; bids_notional : Usd.t option (** [b] *)
    ; asks_notional : Usd.t option (** [a] *)
    ; is_maker : bool (** [m] *)
    ; reduce_only : bool (** [R] *)
    ; working_type : Working_type.t option (** [wt] *)
    ; orig_type : Order_type.t option (** [ot] *)
    ; position_side : Position_side.t option (** [ps] *)
    ; close_position : bool (** [cp] *)
    ; activation_price : Price.t option (** [AP], trailing stops only *)
    ; callback_rate : Decimal.t option (** [cr], trailing stops only *)
    ; price_protect : bool (** [pP] *)
    ; si : int option (** [si], documented as "ignore" *)
    ; ss : int option (** [ss], documented as "ignore" *)
    ; realized_profit : Usd.t (** [rp] *)
    ; self_trade_prevention_mode : string option (** [V] *)
    ; price_match : string option (** [pm] *)
    ; good_till_date : Timestamp_ms.t option (** [gtd] *)
    ; expiry_reason : int option (** [er], from 2025-10 *)
    }
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  { event_time : Timestamp_ms.t (** [E] *)
  ; transaction_time : Timestamp_ms.t (** [T] *)
  ; order : Order.t (** [o] *)
  }
[@@deriving sexp, compare, equal, yojson]

val event_type : string
