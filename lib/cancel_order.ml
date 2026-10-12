open! Core

module Request = struct
  module Target = struct
    type t =
      | Order_id of Order_id.t
      | Client_order_id of Client_order_id.t
    [@@deriving sexp, compare, equal]
  end

  type t =
    { symbol : Symbol.t
    ; target : Target.t
    }
  [@@deriving sexp, compare, equal]

  let to_params { symbol; target } =
    [ "symbol", Symbol.to_string symbol
    ; (match target with
       | Order_id id -> "orderId", Order_id.to_string id
       | Client_order_id id -> "origClientOrderId", Client_order_id.to_string id)
    ]
  ;;
end

module Response = Order
