(** [POST /fapi/v1/order]. *)

open! Core

module Resp_type : sig
  (** [newOrderRespType]: [ACK] (default) returns the order as accepted; [RESULT] waits
      for the final state of market and IOC/FOK/GTX orders. *)
  type t =
    | Ack
    | Result
  [@@deriving sexp, compare, equal, hash, enumerate, yojson]
end

module Request : sig
  (** Request parameters. JSON encoding (used inside [batchOrders]) has every value as a
      string, like the form encoding. *)
  type t =
    { symbol : Symbol.t
    ; side : Side.t
    ; position_side : Position_side.t option (** must be sent in hedge mode *)
    ; order_type : Order_type.t (** [type] *)
    ; time_in_force : Time_in_force.t option (** mandatory for [LIMIT] *)
    ; quantity : Size.t option
    ; price : Price.t option
    ; reduce_only : bool option (** cannot be sent in hedge mode *)
    ; new_client_order_id : Client_order_id.t option
    ; new_order_resp_type : Resp_type.t option
    ; good_till_date : int option (** milliseconds; required with [GTD] *)
    }
  [@@deriving sexp, compare, equal, yojson]

  val limit
    :  ?time_in_force:Time_in_force.t (** default [Gtc] *)
    -> ?reduce_only:bool
    -> ?client_order_id:Client_order_id.t
    -> ?resp_type:Resp_type.t
    -> Symbol.t
    -> Side.t
    -> price:Price.t
    -> quantity:Size.t
    -> t

  val market
    :  ?reduce_only:bool
    -> ?client_order_id:Client_order_id.t
    -> ?resp_type:Resp_type.t
    -> Symbol.t
    -> Side.t
    -> quantity:Size.t
    -> t

  (** Translates a venue-neutral order. Market orders become Binance [MARKET] orders, so
      [slippage_bps] is ignored. [reduce_only = false] is left out, which keeps the
      request valid in hedge mode. *)
  val of_order_request : Exchange_core.Order_request.t -> t

  (** Form parameters in a fixed order (symbol, side, positionSide, type, timeInForce,
      quantity, price, reduceOnly, newClientOrderId, newOrderRespType, goodTillDate);
      absent options are left out. Signing parameters are added by the caller. *)
  val to_params : t -> (string * string) list
end

module Response : sig
  type t = Order.t [@@deriving sexp, compare, equal, yojson]
end
