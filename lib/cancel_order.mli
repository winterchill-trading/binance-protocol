(** [DELETE /fapi/v1/order]. *)

open! Core

module Request : sig
  module Target : sig
    type t =
      | Order_id of Order_id.t (** [orderId] *)
      | Client_order_id of Client_order_id.t (** [origClientOrderId] *)
    [@@deriving sexp, compare, equal]
  end

  type t =
    { symbol : Symbol.t
    ; target : Target.t
    }
  [@@deriving sexp, compare, equal]

  val to_params : t -> (string * string) list
end

module Response : sig
  (** The cancelled order, with [status = CANCELED]. *)
  type t = Order.t [@@deriving sexp, compare, equal, yojson]
end
