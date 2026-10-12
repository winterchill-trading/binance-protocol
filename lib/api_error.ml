open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Code = struct
  type t =
    | Request_throttled
    | Invalid_timestamp
    | Invalid_signature
    | Mandatory_param_empty_or_malformed
    | Bad_precision
    | Invalid_tif
    | Invalid_order_type
    | Invalid_side
    | Bad_symbol
    | Invalid_listen_key
    | Invalid_parameter
    | New_order_rejected
    | Cancel_rejected
    | No_such_order
    | Balance_not_sufficient
    | Margin_not_sufficient
    | Unable_to_fill
    | Order_would_immediately_trigger
    | Reduce_only_reject
    | Invalid_order_status
    | Price_less_than_zero
    | Qty_less_than_zero
    | Qty_greater_than_max_qty
    | Price_not_increased_by_tick_size
    | Price_higher_than_multiplier_up
    | No_need_to_change_margin_type
    | Position_side_not_match
    | Reduce_only_conflict
    | Reduce_only_margin_check_failed
    | Market_order_reject
    | Min_notional
    | Trading_quantitative_rule
    | Fok_order_reject
    | Gtx_order_reject
    | Other of int
  [@@deriving sexp, compare, equal, hash]

  let known =
    [ Request_throttled, -1008
    ; Invalid_timestamp, -1021
    ; Invalid_signature, -1022
    ; Mandatory_param_empty_or_malformed, -1102
    ; Bad_precision, -1111
    ; Invalid_tif, -1115
    ; Invalid_order_type, -1116
    ; Invalid_side, -1117
    ; Bad_symbol, -1121
    ; Invalid_listen_key, -1125
    ; Invalid_parameter, -1130
    ; New_order_rejected, -2010
    ; Cancel_rejected, -2011
    ; No_such_order, -2013
    ; Balance_not_sufficient, -2018
    ; Margin_not_sufficient, -2019
    ; Unable_to_fill, -2020
    ; Order_would_immediately_trigger, -2021
    ; Reduce_only_reject, -2022
    ; Invalid_order_status, -4000
    ; Price_less_than_zero, -4001
    ; Qty_less_than_zero, -4003
    ; Qty_greater_than_max_qty, -4005
    ; Price_not_increased_by_tick_size, -4014
    ; Price_higher_than_multiplier_up, -4016
    ; No_need_to_change_margin_type, -4046
    ; Position_side_not_match, -4061
    ; Reduce_only_conflict, -4062
    ; Reduce_only_margin_check_failed, -4118
    ; Market_order_reject, -4131
    ; Min_notional, -4164
    ; Trading_quantitative_rule, -4400
    ; Fok_order_reject, -5021
    ; Gtx_order_reject, -5022
    ]
  ;;

  let to_int = function
    | Other n -> n
    | t -> List.Assoc.find_exn known t ~equal
  ;;

  let of_int n =
    match List.find known ~f:(fun (_, code) -> Int.equal code n) with
    | Some (t, _) -> t
    | None -> Other n
  ;;

  let yojson_of_t t : Yojson.Safe.t = `Int (to_int t)

  let t_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `Int n -> of_int n
    | _ -> Json.error "Api_error.Code: integer expected" json
  ;;
end

type t =
  { code : Code.t
  ; msg : string
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

(* -4164: "Order's notional must be no smaller than 5.0 (unless you choose reduce only)" *)
let min_notional_of_msg msg =
  match String.substr_index msg ~pattern:"than " with
  | None -> None
  | Some i ->
    String.drop_prefix msg (i + 5)
    |> String.take_while ~f:(fun c -> Char.is_digit c || Char.equal c '.')
    |> Usd.of_string_opt
;;

let to_reject_reason t : Exchange_core.Reject_reason.t option =
  match t.code with
  | Bad_symbol -> Some Unknown_symbol
  | Bad_precision | Qty_less_than_zero | Qty_greater_than_max_qty -> Some Invalid_size
  | Price_less_than_zero | Price_not_increased_by_tick_size -> Some Invalid_price
  | Margin_not_sufficient | Balance_not_sufficient -> Some Insufficient_margin
  | Reduce_only_reject -> Some Reduce_only_would_increase
  | Gtx_order_reject -> Some (Post_only_would_cross { best_bid = None; best_ask = None })
  | Fok_order_reject | Unable_to_fill -> Some No_liquidity
  | Min_notional ->
    let min = Option.value (min_notional_of_msg t.msg) ~default:(Usd.of_int 5) in
    Some (Below_min_value { min })
  | No_such_order | Cancel_rejected -> Some Order_not_found
  | _ -> None
;;

let of_yojson_opt (json : Yojson.Safe.t) =
  match Json.member json ~key:"code", Json.member json ~key:"msg" with
  | Some (`Int _), Some (`String _) -> Some (t_of_yojson json)
  | _ -> None
;;
