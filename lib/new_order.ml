open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Resp_type = struct
  type t =
    | Ack
    | Result
  [@@deriving sexp, compare, equal, hash, enumerate]

  let to_wire = function
    | Ack -> "ACK"
    | Result -> "RESULT"
  ;;

  let of_wire = function
    | "ACK" -> Some Ack
    | "RESULT" -> Some Result
    | _ -> None
  ;;

  let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)
  let t_of_yojson = Json.enum_of_yojson ~name:"New_order.Resp_type" ~of_wire
end

module Request = struct
  type t =
    { symbol : Symbol.t
    ; side : Side.t
    ; position_side : Position_side.t option
         [@key "positionSide"] [@default None] [@yojson_drop_if Option.is_none]
    ; order_type : Order_type.t [@key "type"]
    ; time_in_force : Time_in_force.t option
         [@key "timeInForce"] [@default None] [@yojson_drop_if Option.is_none]
    ; quantity : Size.t option [@default None] [@yojson_drop_if Option.is_none]
    ; price : Price.t option [@default None] [@yojson_drop_if Option.is_none]
    ; reduce_only : Json.Bool_string.t option
         [@key "reduceOnly"] [@default None] [@yojson_drop_if Option.is_none]
    ; new_client_order_id : Client_order_id.t option
         [@key "newClientOrderId"] [@default None] [@yojson_drop_if Option.is_none]
    ; new_order_resp_type : Resp_type.t option
         [@key "newOrderRespType"] [@default None] [@yojson_drop_if Option.is_none]
    ; good_till_date : Json.Int_string.t option
         [@key "goodTillDate"] [@default None] [@yojson_drop_if Option.is_none]
    }
  [@@deriving sexp, compare, equal, yojson]

  let create
    ?time_in_force
    ?reduce_only
    ?client_order_id
    ?resp_type
    ?price
    ?quantity
    symbol
    side
    order_type
    =
    { symbol
    ; side
    ; position_side = None
    ; order_type
    ; time_in_force
    ; quantity
    ; price
    ; reduce_only
    ; new_client_order_id = client_order_id
    ; new_order_resp_type = resp_type
    ; good_till_date = None
    }
  ;;

  let limit
    ?(time_in_force = Time_in_force.Gtc)
    ?reduce_only
    ?client_order_id
    ?resp_type
    symbol
    side
    ~price
    ~quantity
    =
    create
      ~time_in_force
      ?reduce_only
      ?client_order_id
      ?resp_type
      ~price
      ~quantity
      symbol
      side
      Limit
  ;;

  let market ?reduce_only ?client_order_id ?resp_type symbol side ~quantity =
    create ?reduce_only ?client_order_id ?resp_type ~quantity symbol side Market
  ;;

  let of_order_request (r : Exchange_core.Order_request.t) =
    let reduce_only = Option.some_if r.reduce_only true in
    let client_order_id = r.client_order_id in
    match r.order_type with
    | Limit tif ->
      create
        ~time_in_force:(Time_in_force.of_tif tif)
        ?reduce_only
        ?client_order_id
        ?price:r.px
        ~quantity:r.size
        r.symbol
        r.side
        Limit
    | Market _ -> market ?reduce_only ?client_order_id r.symbol r.side ~quantity:r.size
  ;;

  let to_params t =
    let opt key f = Option.map ~f:(fun v -> key, f v) in
    List.filter_opt
      [ Some ("symbol", Symbol.to_string t.symbol)
      ; Some ("side", Side.to_wire t.side)
      ; opt "positionSide" Position_side.to_wire t.position_side
      ; Some ("type", Order_type.to_wire t.order_type)
      ; opt "timeInForce" Time_in_force.to_wire t.time_in_force
      ; opt "quantity" Size.to_string t.quantity
      ; opt "price" Price.to_string t.price
      ; opt "reduceOnly" Bool.to_string t.reduce_only
      ; opt "newClientOrderId" Client_order_id.to_string t.new_client_order_id
      ; opt "newOrderRespType" Resp_type.to_wire t.new_order_resp_type
      ; opt "goodTillDate" Int.to_string t.good_till_date
      ]
  ;;
end

module Response = Order
