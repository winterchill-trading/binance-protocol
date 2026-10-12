(** Error payload returned by any REST endpoint (and per item by [batchOrders]):
    [{"code": -1121, "msg": "Invalid symbol."}]. *)

open! Core

module Code : sig
  type t =
    | Request_throttled (** -1008 *)
    | Invalid_timestamp (** -1021: outside [recvWindow] or ahead of server time *)
    | Invalid_signature (** -1022 *)
    | Mandatory_param_empty_or_malformed (** -1102 *)
    | Bad_precision (** -1111 *)
    | Invalid_tif (** -1115 *)
    | Invalid_order_type (** -1116 *)
    | Invalid_side (** -1117 *)
    | Bad_symbol (** -1121 *)
    | Invalid_listen_key (** -1125 *)
    | Invalid_parameter (** -1130 *)
    | New_order_rejected (** -2010 *)
    | Cancel_rejected (** -2011 *)
    | No_such_order (** -2013 *)
    | Balance_not_sufficient (** -2018 *)
    | Margin_not_sufficient (** -2019 *)
    | Unable_to_fill (** -2020 *)
    | Order_would_immediately_trigger (** -2021 *)
    | Reduce_only_reject (** -2022 *)
    | Invalid_order_status (** -4000 *)
    | Price_less_than_zero (** -4001 *)
    | Qty_less_than_zero (** -4003 *)
    | Qty_greater_than_max_qty (** -4005 *)
    | Price_not_increased_by_tick_size (** -4014 *)
    | Price_higher_than_multiplier_up (** -4016 *)
    | No_need_to_change_margin_type (** -4046 *)
    | Position_side_not_match (** -4061 *)
    | Reduce_only_conflict (** -4062 *)
    | Reduce_only_margin_check_failed (** -4118 *)
    | Market_order_reject (** -4131 *)
    | Min_notional (** -4164 *)
    | Trading_quantitative_rule (** -4400 *)
    | Fok_order_reject (** -5021 *)
    | Gtx_order_reject (** -5022: post-only order would have taken liquidity *)
    | Other of int
  [@@deriving sexp, compare, equal, hash, yojson]

  val of_int : int -> t
  val to_int : t -> int
end

type t =
  { code : Code.t
  ; msg : string
  }
[@@deriving sexp, compare, equal, yojson]

(** Translates the order-entry rejections that have a venue-neutral counterpart. *)
val to_reject_reason : t -> Exchange_core.Reject_reason.t option

(** Decodes [json] as an error when it is an object with an integer [code] and a string
    [msg]. Note that [DELETE /fapi/v1/allOpenOrders] answers success in the same shape
    with [code = 200]. *)
val of_yojson_opt : Yojson.Safe.t -> t option
