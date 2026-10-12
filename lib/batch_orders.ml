open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Request = struct
  type t = New_order.Request.t list [@@deriving sexp, compare, equal]

  let max_orders = 5

  let create orders =
    let n = List.length orders in
    if n = 0 || n > max_orders
    then Or_error.error_s [%message "Batch_orders: 1 to 5 orders required" (n : int)]
    else Ok orders
  ;;

  let orders = Fn.id

  (* UNVERIFIED: the reference does not state how the batchOrders array is encoded in a
     form body; this sends it as a JSON array string, values as strings. *)
  let to_params t =
    [ "batchOrders", Yojson.Safe.to_string ([%yojson_of: New_order.Request.t list] t) ]
  ;;
end

module Response = struct
  module Item = struct
    type t =
      | Ok of Order.t
      | Error of Api_error.t
    [@@deriving sexp, compare, equal]

    let yojson_of_t = function
      | Ok order -> Order.yojson_of_t order
      | Error error -> Api_error.yojson_of_t error
    ;;

    let t_of_yojson json =
      match Json.member json ~key:"code" with
      | Some _ -> Error (Api_error.t_of_yojson json)
      | None -> Ok (Order.t_of_yojson json)
    ;;
  end

  type t = Item.t list [@@deriving sexp, compare, equal, yojson]
end
